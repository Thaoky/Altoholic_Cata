local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local L = AddonFactory:GetLocale(addonName)
local enum = DataStore.Enum.ContainerIDs

local THIS_ACCOUNT = "Default"

addon.Search = {}

local ns = addon.Search		-- ns = namespace

local updateHandler

-- *** Reporting what the item cache did not have ***
-- A loot table entry the client has never seen resolves to nothing, so it is filtered out
-- and missing from the results. Filtering it is itself the request for it, so the data does
-- turn up a few seconds later, and running the search again then returns more.
--
-- Doing that automatically was tried and taken back out: one pass walks the bundled table
-- plus the three LibPeriodicTable sets, tens of thousands of entries, and blocks the game
-- for seconds. Doing it twice doubles that, and floods the client with requests for items
-- it does not know, which appears to push things it did know back out of the cache.
-- So the count is reported instead, and repeating the search is left to the user.
-- Must run *after* ns:Update(), which writes its own "n results found" line and would
-- otherwise wipe this one. When nothing was missing, Update's text is the right text and
-- is left alone.
local function ReportSearchStatus()
	local numUnnamed = addon.Loots:GetNumItemsUnnamed()
	if not numUnnamed or numUnnamed == 0 then return end

	AltoholicTabSearch.Status:SetText(format(L["SEARCH_RESULTS_INCOMPLETE"], ns:GetNumResults(), numUnnamed))
end

-- *** Filling in the names that arrive after the search ***
-- Asking for an uncached item is what requests it, so by the time a row is drawn as
-- "Unknown #id" the answer is already on its way - it lands on GET_ITEM_INFO_RECEIVED a moment
-- later. Nothing listened for it, so the row kept the placeholder until the whole search was
-- run again, and running it again re-requests everything, which is how a row could stay
-- unknown through any number of clicks on Search.
--
-- Only the rows actually on screen are watched, and the listener stops as soon as they are all
-- named or the tab is left. Same approach as the recipes panel, see WaitForItemNames there.
local isNameMissing				-- a row of the last drawn page had no name yet
local isWaitingForItemNames

function ns:WaitForItemNames(isWaiting)
	if isWaiting == isWaitingForItemNames then return end		-- already in the right state ?

	isWaitingForItemNames = isWaiting

	-- tag it, the scope is the whole add-on, and this event is of interest to others
	if not isWaiting then
		addon:StopListeningTo("GET_ITEM_INFO_RECEIVED", "Search")
		return
	end

	addon:ListenTo("GET_ITEM_INFO_RECEIVED", function()
		if not AltoholicFrameSearch or not AltoholicFrameSearch:IsVisible() then
			ns:WaitForItemNames(nil)
			return
		end

		ns:Update()
	end, "Search")
end

-- The loot scans hand back a frame between batches, which is the only moment anything can
-- be drawn: this is where the progress the user was missing gets written.
local function ReportScanProgress(done, total)
	if not total or total == 0 then return end

	AltoholicTabSearch.Status:SetText(format(L["SEARCH_IN_PROGRESS"], floor(done / total * 100)))
end

function ns:Update()
	ns[updateHandler](ns)
end

function ns:SetUpdateHandler(h)
	updateHandler = h
end

local PLAYER_ITEM_LINE = 1
local GUILD_ITEM_LINE = 2
local PLAYER_CRAFT_LINE = 3
local GUILD_CRAFT_LINE = 4

local function Realm_UpdateEx(self, offset, desc)
	local line, LineDesc
	
	local frame = AltoholicFrameSearch
	local itemButton
	local rowFrame

	for rowIndex = 1, desc.NumLines do
		rowFrame = frame["Entry"..rowIndex]
		
		rowFrame.Name:SetWidth(240)
		rowFrame.Stat1:SetWidth(240)		-- holds the joined list of sources
		rowFrame.Stat1:SetPoint("LEFT", rowFrame.Name, "RIGHT", 5, 0)
		rowFrame.Stat2:SetWidth(70)
		rowFrame.Stat2:SetPoint("LEFT", rowFrame.Stat1, "RIGHT", 5, 0)
		
		for j=3, 6 do
			rowFrame["Stat"..j ]:Hide()
		end
		rowFrame.ILvl:Hide()
		rowFrame:SetScript("OnEnter", nil)
		rowFrame:SetScript("OnLeave", nil)
		
		line = rowIndex + offset
		local result = ns:GetResult(line)
		if result then
			LineDesc = desc.Lines[result.linetype]
			
			local owner, color = LineDesc:GetCharacter(result)
			rowFrame.Stat1:SetText(color .. owner)
			
			local realm, account, faction = LineDesc:GetRealm(result)
			local location = format("%s%s", colors[faction], realm)
			if account ~= THIS_ACCOUNT then
				location = location .. "\n" ..colors.white .. L["Account"] .. ": " ..colors.green.. account
			end
			rowFrame.Stat2:SetText(location)
			
			local hex = colors.white
			itemButton = rowFrame.Item
			itemButton.IconBorder:Hide()
			
			local item = result.link or result.id
			
			if item then
				local _, _, itemRarity = C_Item.GetItemInfo(item)
				if itemRarity then
					local r, g, b
					r, g, b, hex = C_Item.GetItemQualityColor(itemRarity)
					if itemRarity >= 2 then
						itemButton.IconBorder:SetVertexColor(r, g, b, 0.5)
						itemButton.IconBorder:Show()
					end
					hex = "|c" .. hex
				end
			end
			
			local name, source, sourceID = LineDesc:GetItemData(result, line)

			if name then
				rowFrame.Name:SetText(hex .. name)
				rowFrame.Source.Text:SetText(source)
				rowFrame.Source:SetID(sourceID)
			end
			
			itemButton:SetInfo(LineDesc:GetItemInfo(result))
			itemButton:SetIcon(LineDesc:GetItemTexture(result))			
			itemButton:SetCount(result.count)
			
			rowFrame:SetID(line)
			rowFrame:Show()
		end
	end

	local numResults = desc:GetSize()
	if (offset+desc.NumLines) <= numResults then
		AltoholicTabSearch.Status:SetText(numResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. (offset+desc.NumLines) .. ")")
	else
		AltoholicTabSearch.Status:SetText(numResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. numResults .. ")")
	end
	
	if not AltoholicFrameSearch:IsVisible() then
		AltoholicFrameSearch:Show()
	end
end

-- The principle behind ScrollFrame description is the following:
-- FauxScrollframes follow a roughly similar pattern, and are usually displaying different types of lines
-- so the idea is to standardize data collection from the raw tables that are used to populate the scrollframe
-- that way, a function called GetXXX can be used to display this info regardless of the line type, but can also be reused by sort functions

local RealmScrollFrame_Desc = {
	NumLines = 7,
	Frame = "AltoholicFrameSearch",
	GetSize = function() return ns:GetNumResults() end,
	Update = Realm_UpdateEx,
	Lines = {
		[PLAYER_ITEM_LINE] = {
			GetItemData = function(self, result)		-- GetItemData..just to avoid calling it GetItemInfo
					-- The link is worth asking about first, it carries what the bare id cannot.
					-- Either way this goes through the item memory rather than straight to the
					-- client: an item sitting in an offline alt's bags may well be one this
					-- session has never had a reason to look up, and the bare call answered
					-- nothing at all - an empty name that no amount of waiting would fill in,
					-- and no "unknown" marker either, so the row just looked broken.
					local name = addon:GetItemInfo(result.link or result.id)
						or format("%s%d", UNKNOWN .. " #", result.id)

					-- return name, source, sourceID
					return name, colors.teal .. result.location, 0
				end,
			GetItemTexture = function(self, result)
					return (result.id) and C_Item.GetItemIconByID(result.id) or "Interface\\Icons\\Trade_Engraving"
				end,
			GetCharacter = function(self, result)
					local character = result.source
					return DataStore:GetCharacterName(character), DataStore:GetCharacterClassColor(character)
				end,
			GetRealm = function(self, result)
					local character = result.source
					local account, realm = strsplit(".", character)
					return realm, account, DataStore:GetCharacterFaction(character)
				end,
			GetItemInfo = function(self, result)
					return result.id, result.link
				end,
		},
		[GUILD_ITEM_LINE] = {
			GetItemData = function(self, result)		-- GetItemData..just to avoid calling it GetItemInfo
					local name = C_Item.GetItemInfo(result.id)
			
					-- return name, source, sourceID
					return name, colors.teal .. result.location, 0 
				end,
			GetItemTexture = function(self, result)
					return (result.id) and C_Item.GetItemIconByID(result.id) or "Interface\\Icons\\Trade_Engraving"
				end,
			GetCharacter = function(self, result)
					local _, _, guildName = strsplit(".", result.source)
					return guildName, colors.green
				end,
			GetRealm = function(self, result)
					local account, realm, name = strsplit(".", result.source)
					local guild = DataStore:GetGuild(name, realm, account)
					
					return realm, account, DataStore:GetGuildBankFaction(guild)
				end,
			GetItemInfo = function(self, result)
					return result.id, result.link
				end,
		},
		[PLAYER_CRAFT_LINE] = {
			GetItemData = function(self, result, line)
					
					-- return GetSpellInfo(result.spellID), source, line
					
					local isEnchanting = (result.professionName == GetSpellInfo(7411))
					
					if isEnchanting then
						local source = addon:GetRecipeLink(result.spellID, result.professionName)
						
						return GetSpellInfo(result.spellID), source, line
					else
						return C_Item.GetItemInfo(result.spellID), result.professionName, line
					end
				end,
			GetItemTexture = function(self, result)
					-- local itemID = DataStore:GetCraftResultItem(result.spellID)
					
					local isEnchanting = (result.professionName == GetSpellInfo(7411))
					
					if isEnchanting then
						return "Interface\\Icons\\Trade_Engraving"
					else
						local itemID = result.spellID
						return (itemID) and C_Item.GetItemIconByID(itemID) or "Interface\\Icons\\Trade_Engraving"
					end
				end,
			GetCharacter = function(self, result)
					local character = result.char
					local _, _, name = strsplit(".", character)
					
					-- name, color
					return name, DataStore:GetCharacterClassColor(character)
				end,
			GetRealm = function(self, result)
					local character = result.char
					local account, realm, name = strsplit(".", character)
		
					return realm, account, DataStore:GetCharacterFaction(character)
				end,
			GetItemInfo = function(self, result)
					-- return the itemID
					-- local itemID = DataStore:GetCraftResultItem(result.spellID)
					-- do not make a direct return of the result					
					-- return itemID
					
					local isEnchanting = (result.professionName == GetSpellInfo(7411))
					if not isEnchanting then
						return result.spellID
					end
				end,
		},
		[GUILD_CRAFT_LINE] = {
			GetItemData = function(self, result, line)
					-- return name, source, sourceID
					local profession = LTL:GetSkillName(result.skillID)
					local source = addon:GetRecipeLink(result.spellID, profession)
					
					return GetSpellInfo(result.spellID), source, line
				end,
			GetItemTexture = function(self, result)
					local itemID = DataStore:GetCraftResultItem(result.spellID)
					if itemID then		-- if the craft is known, return its icon, else return the profession icon
						return C_Item.GetItemIconByID(itemID)	
					end
			
					local profession = LTL:GetSkillName(result.skillID)
					return addon:GetSpellIcon(addon.ProfessionSpellID[profession])
				end,
			GetCharacter = function(self, result)
					local _, _, _, _, _, _, _, _, _, _, englishClass = DataStore:GetGuildMemberInfo(result.char)
					return result.char, DataStore:GetClassColor(englishClass)
				end,
			GetRealm = function(self, result)
					return GetRealmName(), THIS_ACCOUNT, UnitFactionGroup("player")
				end,
			GetItemInfo = function(self, result)
					local itemID = DataStore:GetCraftResultItem(result.spellID)
					-- do not make a direct return of the result					
					return itemID
				end,
		},
	}
}

local function ScrollFrameUpdate(desc)
	-- copy of the function in Altoholic.lua, made local here temporarily to avoid messing up with other consumers of the function
	
	assert(type(desc) == "table")		-- desc is the table that contains a standardized description of the scrollframe
	
	local frame = _G[desc.Frame]
	local scrollFrame = frame.ScrollFrame
	local numRows = scrollFrame.numRows
	local rowFrame

	-- hide all lines and set their id to 0, the update function is responsible for showing and setting id's of valid lines	
	for rowIndex = 1, numRows do
		rowFrame = frame["Entry"..rowIndex]
		rowFrame:SetID(0)
		rowFrame:Hide()
	end
	
	local offset = scrollFrame:GetOffset()
	-- call the update handler
	desc:Update(offset, desc)
	
	local last = (desc:GetSize() < numRows) and numRows or desc:GetSize()
	scrollFrame:Update(last)
end

function ns:Realm_Update()
	ScrollFrameUpdate(RealmScrollFrame_Desc)
end

function ns:Loots_Update()

	local frame = AltoholicFrameSearch
	local scrollFrame = frame.ScrollFrame
	local numRows = scrollFrame.numRows
	local numResults = ns:GetNumResults()

	isNameMissing = nil		-- recomputed over the rows drawn below

	if numResults == 0 then
		-- Hides all entries of the scrollframe, and updates it accordingly
		for rowIndex = 1, numRows do
			frame["Entry"..rowIndex]:Hide()
		end
		scrollFrame:Update(numRows)
		ns:WaitForItemNames(nil)		-- nothing on screen, nothing left to wait for
		return
	end

	local offset = scrollFrame:GetOffset()

	local itemButton
	local rowFrame
	
	for rowIndex = 1, numRows do
		rowFrame = frame["Entry"..rowIndex]
		rowFrame.Name:SetWidth(240)
		rowFrame.Stat1:SetWidth(240)		-- holds the joined list of sources
		rowFrame.Stat1:SetPoint("LEFT", rowFrame.Name, "RIGHT", 5, 0)
		rowFrame.Stat2:SetWidth(70)
		rowFrame.Stat2:SetPoint("LEFT", rowFrame.Stat1, "RIGHT", 5, 0)
		
		for j=3, 6 do
			rowFrame["Stat"..j ]:Hide()
		end
		rowFrame.ILvl:Hide()
		
		rowFrame:SetScript("OnEnter", nil)
		rowFrame:SetScript("OnLeave", nil)
		
		local line = rowIndex + offset
		local result = ns:GetResult(line)
		if result then
			local itemID = result.id
			
			itemButton = rowFrame.Item
			itemButton.IconBorder:Hide()
			
			-- a result can be drawn long after it was found, and the client may still not
			-- resolve the item: this falls back on what was seen before, and on what the
			-- search itself recorded, rather than feeding nil to the colour and text calls
			local itemName, itemRarity, itemLevel = addon:GetItemInfo(itemID)
			local r, g, b, hex = C_Item.GetItemQualityColor(itemRarity or 1)

			if not itemName then
				itemName = format("%s%d", UNKNOWN .. " #", itemID)
				isNameMissing = true		-- the answer is on its way, see WaitForItemNames
			end

			itemLevel = itemLevel or result.iLvl or ""
			result.iLvl = result.iLvl or tonumber(itemLevel)		-- heals the row for sorting

			if itemRarity and itemRarity >= 2 then
				itemButton.IconBorder:SetVertexColor(r, g, b, 0.5)
				itemButton.IconBorder:Show()
			end

			itemButton.Icon:SetTexture(C_Item.GetItemIconByID(itemID));

			rowFrame.Stat2:SetText(colors.yellow .. itemLevel)
			rowFrame.Name:SetText("|c" .. hex .. itemName)
			rowFrame.Source.Text:SetText(colors.teal .. result.dropLocation)
			rowFrame.Source:SetID(0)
			
			-- browsing, this is the bosses of the instance named on the left; on an upgrade
			-- list it is the other places that item can be had, and an item reachable one
			-- way only leaves it empty
			rowFrame.Stat1:SetText(colors.green .. (result.bossName or ""))

			itemButton:SetInfo(itemID)
			itemButton:SetCount(result.count)
			rowFrame:Show()
		else
			rowFrame:Hide()
		end
	end

	if (offset+numRows) <= numResults then
		AltoholicTabSearch.Status:SetText(numResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. (offset+numRows) .. ")")
	else
		AltoholicTabSearch.Status:SetText(numResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. numResults .. ")")
	end
	
	if numResults < numRows then
		scrollFrame:Update(numRows)
	else
		scrollFrame:Update(numResults)
	end
	
	if not AltoholicFrameSearch:IsVisible() then
		AltoholicFrameSearch:Show()
	end

	ns:WaitForItemNames(isNameMissing)
end

function ns:Upgrade_Update()
	local frame = AltoholicFrameSearch
	local scrollFrame = frame.ScrollFrame
	local numRows = scrollFrame.numRows
	local numResults = ns:GetNumResults()

	isNameMissing = nil		-- recomputed over the rows drawn below

	if numResults == 0 then
		-- Hides all entries of the scrollframe, and updates it accordingly
		for rowIndex = 1, numRows do
			frame["Entry"..rowIndex]:Hide()
		end
		scrollFrame:Update(numRows)
		ns:WaitForItemNames(nil)		-- nothing on screen, nothing left to wait for
		return
	end

	local offset = scrollFrame:GetOffset()

	local itemButton
	local rowFrame
	local stat
	
	for rowIndex = 1, numRows do
		rowFrame = frame["Entry"..rowIndex]

		rowFrame.Name:SetWidth(190)
		rowFrame.Stat1:SetWidth(50)
		rowFrame.Stat1:SetPoint("LEFT", rowFrame.Name, "RIGHT", 0, 0)
		rowFrame.Stat2:SetWidth(50)
		rowFrame.Stat2:SetPoint("LEFT", rowFrame.Stat1, "RIGHT", 0, 0)
		-- TooltipStats lives on addon.Tabs.Search, not on addon.Search which ns points at here
		rowFrame:SetScript("OnEnter", function(self) addon.Tabs.Search:TooltipStats(self) end)
		rowFrame:SetScript("OnLeave", function(self) AltoTooltip:Hide() end)
		
		local line = rowIndex + offset
		local result = ns:GetResult(line)
		if result then
			local itemID = result.id
			
			itemButton = rowFrame.Item
			itemButton.IconBorder:Hide()
			
			-- same as the loot list: the item may still be unresolved when the row is drawn
			local itemName, itemRarity, itemLevel = addon:GetItemInfo(itemID)
			local r, g, b, hex = C_Item.GetItemQualityColor(itemRarity or 1)

			if not itemName then
				itemName = format("%s%d", UNKNOWN .. " #", itemID)
				isNameMissing = true		-- the answer is on its way, see WaitForItemNames
			end

			itemLevel = itemLevel or result.iLvl or ""
			result.iLvl = result.iLvl or tonumber(itemLevel)		-- heals the row for sorting

			if itemRarity and itemRarity >= 2 then
				itemButton.IconBorder:SetVertexColor(r, g, b, 0.5)
				itemButton.IconBorder:Show()
			end

			itemButton.Icon:SetTexture(C_Item.GetItemIconByID(itemID));

			rowFrame.Name:SetText("|c" .. hex .. itemName)

			-- The same item is often reachable several ways, and this layout has one line for
			-- all of it : it spells out the first way and says how many others there are.
			local location = result.dropLocation

			if result.firstBoss then
				location = format("%s, %s%s", location, colors.green, result.firstBoss)
			end

			if result.numSources and result.numSources > 1 then
				location = format("%s %s(+%d)", location, colors.white, result.numSources - 1)
			end

			rowFrame.Source.Text:SetText(colors.teal .. location)
			rowFrame.Source:SetID(0)

			for j=1, 6 do
				stat = rowFrame["Stat"..j]
				
				if result["stat"..j] ~= nil then
					local statValue, diff = strsplit("|", result["stat"..j])
					local color
					diff = tonumber(diff)
					
					if diff < 0 then
						color = colors.red
					elseif diff > 0 then 
						color = colors.green
					else
						color = colors.white
					end
					
					stat:SetText(color .. statValue)
					stat:Show()
				else
					stat:Hide()
				end
			end

			rowFrame.ILvl:SetText(colors.yellow .. itemLevel)
			rowFrame.ILvl:Show()
			
			itemButton:SetInfo(itemID)
			itemButton:SetCount(result.count)
			rowFrame:SetID(line)
			rowFrame:Show()
		else
			rowFrame:Hide()
		end
	end

	if (offset+numRows) <= numResults then
		AltoholicTabSearch.Status:SetText(numResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. (offset+numRows) .. ")")
	else
		AltoholicTabSearch.Status:SetText(numResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. numResults .. ")")
	end
	
	if numResults < numRows then
		scrollFrame:Update(numRows)
	else
		scrollFrame:Update(numResults)
	end
	
	if not AltoholicFrameSearch:IsVisible() then
		AltoholicFrameSearch:Show()
	end

	ns:WaitForItemNames(isNameMissing)
end

-- ** Sort functions **
local function SortByItemName(a, b, ascending)
	-- only the loot & upgrade searches sort on this field, their results always come from a loot table,
	-- so they always have an item id. An uncached item has no name yet, sort it as if it were empty.
	local nameA = a.id and C_Item.GetItemInfo(a.id) or ""
	local nameB = b.id and C_Item.GetItemInfo(b.id) or ""

	if ascending then
		return nameA < nameB
	else
		return nameA > nameB
	end
end

local function SortByName(a, b, ascending)
	local desc = RealmScrollFrame_Desc			-- get the line description for the 2 items
	local LineDescA = desc.Lines[a.linetype]
	local LineDescB = desc.Lines[b.linetype]

	-- retrieve the name .. an uncached item has none yet, sort it as if it were empty
	local nameA = LineDescA:GetItemData(a) or ""
	local nameB = LineDescB:GetItemData(b) or ""
	
	if ascending then
		return nameA < nameB
	else
		return nameA > nameB
	end
end

local function SortByChar(a, b, ascending)
	local desc = RealmScrollFrame_Desc			-- get the line description for the 2 items
	local LineDescA = desc.Lines[a.linetype]
	local LineDescB = desc.Lines[b.linetype]

	local nameA = LineDescA:GetCharacter(a)			-- retrieve the name ..
	local nameB = LineDescB:GetCharacter(b)

	if nameA == nameB then								-- if it's the same character name ..
		return SortByName(a, b, ascending)			-- .. then sort by item name
	elseif ascending then
		return nameA < nameB
	else
		return nameA > nameB
	end
end

local function SortByRealm(a, b, ascending)
	local desc = RealmScrollFrame_Desc			-- get the line description for the 2 items
	local LineDescA = desc.Lines[a.linetype]
	local LineDescB = desc.Lines[b.linetype]

	local nameA = LineDescA:GetRealm(a)					-- retrieve the name ..
	local nameB = LineDescB:GetRealm(b)	
	
	if nameA == nameB then								-- if it's the same realm ..
		return SortByChar(a, b, ascending)	-- .. then sort by character name
	elseif ascending then
		return nameA < nameB
	else
		return nameA > nameB
	end
end

local function SortByStat(a, b, field, ascending)
	-- the reference row and any row whose stats could not be read carry nothing here
	local statA = a[field] and strsplit("|", a[field])
	local statB = b[field] and strsplit("|", b[field])

	statA = tonumber(statA) or 0
	statB = tonumber(statB) or 0

	if ascending then
		return statA < statB
	else
		return statA > statB
	end
end

local function SortByField(a, b, field, ascending)
	local valueA, valueB = a[field], b[field]

	-- A row can legitimately be missing the field it is being sorted on: an item the client
	-- has not cached has no item level to record. Those go last either way, rather than
	-- taking the whole sort down with them.
	if valueA == nil or valueB == nil then
		if valueA == valueB then return false end
		return valueB == nil
	end

	if ascending then
		return valueA < valueB
	else
		return valueA > valueB
	end
end

-- ** Results **
local results

function ns:ClearResults()
	results = results or {}
	wipe(results)
end

function ns:AddResult(t)

	table.insert(results, t)
end

function ns:GetNumResults()
	return #results or 0
end

function ns:GetResult(n)
	if n then
		return results[n]
	end
end

function ns:SortResults(frame, field)
	if ns:GetNumResults() == 0 then return end

	local id = frame:GetID()
	local ascending = Altoholic_SearchTab_Options.SortAscending
		
	-- The item level was written when the row was found, and at that point the client may
	-- not have known it. It very often does by now - the rows on screen already show it,
	-- because drawing them resolves it again - so bring the stored value up to date before
	-- sorting on it, rather than sorting on the nil it was found with.
	if field == "iLvl" then
		for _, result in ipairs(results) do
			if not result.iLvl and result.id then
				result.iLvl = select(3, addon:GetRememberedItemInfo(result.id))
			end
		end
	end

	if field == "name" then
		table.sort(results, function(a, b) return SortByName(a, b, ascending) end)
	elseif field == "item" then
		table.sort(results, function(a, b) return SortByItemName(a, b, ascending) end)
	elseif field == "char" then
		table.sort(results, function(a, b) return SortByChar(a, b, ascending) end)
	elseif field == "realm" then
		table.sort(results, function(a, b) return SortByRealm(a, b, ascending) end)
	elseif field == "stat" then
		table.sort(results, function(a, b) return SortByStat(a, b, "stat" .. id-1, ascending) end)
	else
		table.sort(results, function(a, b) return SortByField(a, b, field, ascending) end)
	end
	
	ns:Update()
end

local SEARCH_THISCHAR = 1
local SEARCH_THISREALM_THISFACTION = 2
local SEARCH_THISREALM_BOTHFACTIONS = 3
local SEARCH_ALLREALMS = 4
local SEARCH_ALLACCOUNTS = 5
local SEARCH_LOOTS = 6

local filters = addon.ItemFilters

-- ** Search attributes **
local currentValue				-- the value being searched (entered in the edit box)

local currentResultType			-- type of result currently being searched (eg: PLAYER_ITEM_LINE or GUILD_ITEM_LINE)
local currentResultKey			-- key defining who is being searched (eg: a datastore character or guild key)
local currentResultLocation	-- what is actually being searched (bags, bank, equipment, mail, etc..)

local MYTHIC_KEYSTONE = 138019

local function VerifyItem(location, item, itemLink, itemCount)
	if type(item) == "string" then		-- convert a link to its item id, only data saved
	
		if item:match("|Hkeystone:") then
			item = MYTHIC_KEYSTONE			-- mythic keystones are actually all using the same item id
		else
			item = tonumber(item:match("item:(%d+)"))
		end	
	end
	
	if type(itemLink) ~= "string" then              -- a link is not a link - delete it
		itemLink = nil
	end
	
	filters:SetSearchedItem(item, (item ~= MYTHIC_KEYSTONE) and itemLink or nil)
	
	-- All conditions ok ? save it
	if filters:ItemPassesFilters() then
		ns:AddResult( {
			linetype = currentResultType,			-- PLAYER_ITEM_LINE or GUILD_ITEM_LINE 
			id = item,
			link = itemLink,
			source = currentResultKey,				-- character or guild key in DataStore
			count = itemCount,
			location = location,
		} )
	end
end

local function CraftMatchFound(spellID, value, isEnchanting)
	local name
	
	if spellID then
		if isEnchanting then
			name = GetSpellInfo(spellID)
		else
			name = GetItemInfo(spellID)
		end
	end
	
	if name and string.find(strlower(name), value, 1, true) then
		return true
	end
end

local function BrowseCharacter(character)

	currentResultType = PLAYER_ITEM_LINE	
	currentResultKey = character
	
	-- Bags / Bank
	DataStore:IterateContainerSlots(character, function(containerID, itemID, itemLink, itemCount, isBattlePet) 
		local location

		if containerID <= 4 then
			location = L["Bags"]
		else
			location = L["Bank"]
		end
	
		VerifyItem(location, itemID, itemLink, itemCount, character, isBattlePet)
	end)
	
	-- Player Bank (main slots)
	DataStore:IteratePlayerBankSlots(character, function(itemID, itemLink, itemCount, isBattlePet) 
		VerifyItem(L["Bank"], itemID, itemLink, itemCount, character, isBattlePet)
	end)
	
	-- Equipment
	DataStore:IterateInventory(character, function(item) 
		VerifyItem(L["Equipped"], item, item, 1, character)
	end)
	
	-- Mails
	if Altoholic_SearchTab_Options["IncludeMailboxItems"] then			
		
		DataStore:IterateMails(character, function(icon, count, itemLink) 
			if itemLink then
				VerifyItem(L["Mail"], itemLink, itemLink, count, character)
			end
		end)
	end
	
	-- Check known recipes ?
	if not Altoholic_SearchTab_Options["IncludeKnownRecipes"] then return end	
		
	local professions = DataStore:GetProfessions(character)
	if professions then
		for professionName, profession in pairs(professions) do
		
			local isEnchanting = (professionName == GetSpellInfo(7411))
		
			DataStore:IterateRecipes(profession, 0, 0, function(recipeData)
				-- 2024/06/23 : this need double checking
				local _, spellID, isLearned = DataStore:GetRecipeInfo_NonRetail(recipeData)
				
				if isLearned and CraftMatchFound(spellID, currentValue, isEnchanting) then
					ns:AddResult(	{
						linetype = PLAYER_CRAFT_LINE,
						char = currentResultKey,
						professionName = professionName,
						profession = profession,
						spellID = spellID
					} )
				end
			end)
		end
	end
	
	currentResultType = nil
	currentResultKey = nil
end

local function BrowseRealm(realm, account, bothFactions)
	local playerFaction = UnitFactionGroup("player")

	for characterName, character in pairs(DataStore:GetCharacters(realm, account)) do
		if bothFactions or DataStore:GetCharacterFaction(character) == playerFaction then
			BrowseCharacter(character)
		end
	end
	
	if Altoholic_SearchTab_Options.IncludeGuildBankItems then	-- Check guild bank(s) ?
		currentResultType = GUILD_ITEM_LINE

		for guildName, guild in pairs(DataStore:GetGuilds(realm, account)) do
			if bothFactions or DataStore:GetGuildBankFaction(guild) == playerFaction then
				currentResultKey = format("%s.%s.%s", account, realm, guildName)
				
				for tabID = 1, 8 do
					local tab = DataStore:GetGuildBankTab(guild, tabID)
					if tab.name then
						for slotID = 1, 98 do
							currentResultLocation = format("%s, %s - col %d/row %d)", GUILD_BANK, tab.name, floor((slotID-1)/7)+1, ((slotID-1)%7)+1)
							local id, link, count = DataStore:GetSlotInfo(tab, slotID)
							if id then
								link = link or id
								VerifyItem(link, count, link)
							end
						end
					end
				end
				
				currentResultKey = nil
			end
		end	-- end guild
		currentResultType = nil
		currentResultLocation = nil
	end
end

local ongoingSearch

function ns:FindItem(searchType, searchSubType)
	-- The search button passes nothing: fall back on whatever the category tree is
	-- highlighting, otherwise pressing it drops the category while it still looks selected
	if not searchType and not searchSubType then
		searchType, searchSubType = addon.Tabs.Search:GetSelectedCategory()
	end

	-- A loot scan now spans several seconds, so clicking another category while one runs is
	-- the user replacing the search, not something to drop. Dropping it left the previous
	-- results on screen and looked like the category filter returning the wrong things.
	if ongoingSearch then
		addon.Loots:CancelScan()
		ongoingSearch = nil
	end

	ongoingSearch = true
	
	-- Set Filters
	local value = AltoholicFrame_SearchEditBox:GetText() or ""
	
	currentValue = strlower(value)

	filters:EnableFilter("Existence")	-- should be first in the list !
	
	if value ~= "" then
		filters:SetFilterValue("itemName", currentValue)
		filters:EnableFilter("Name")
	end
	
	if searchType then
		filters:SetFilterValue("itemType", searchType)
		filters:EnableFilter("Type")
	end

	if searchSubType then
		filters:SetFilterValue("itemSubType", searchSubType)
		filters:EnableFilter("SubType")
	end
		
	local itemMinLevel = AltoholicTabSearch.MinLevel:GetNumber()
	filters:SetFilterValue("itemMinLevel", itemMinLevel)
	filters:EnableFilter("MinLevel")
	
	local itemMaxLevel = AltoholicTabSearch.MaxLevel:GetNumber()	
	if itemMaxLevel ~= 0 then			-- enable the filter only if a max level has been set
		filters:SetFilterValue("itemMaxLevel", itemMaxLevel)
		filters:EnableFilter("Maxlevel")
	end	
	
	local itemSlot = UIDropDownMenu_GetSelectedValue(AltoholicTabSearch.SelectSlot)
	if itemSlot ~= 0 then	-- don't apply filter if = 0, it means we take them all
		filters:EnableFilter("EquipmentSlot")
		filters:SetFilterValue("itemSlot", itemSlot)
	end	
	
	filters:SetFilterValue("itemRarity", UIDropDownMenu_GetSelectedValue(AltoholicTabSearch.SelectRarity))
	filters:EnableFilter("Rarity")
	
	-- Start the search
	local searchLocation = UIDropDownMenu_GetSelectedValue(AltoholicTabSearch.SelectLocation)
	
	ns:ClearResults()
	
	local SearchLoots
	if searchLocation == SEARCH_THISCHAR then
		BrowseCharacter(DataStore:GetCharacter())
	elseif searchLocation == SEARCH_THISREALM_THISFACTION or	searchLocation == SEARCH_THISREALM_BOTHFACTIONS then
		BrowseRealm(GetRealmName(), THIS_ACCOUNT, (searchLocation == SEARCH_THISREALM_BOTHFACTIONS))
	elseif searchLocation == SEARCH_ALLREALMS then
		for realm in pairs(DataStore:GetRealms()) do
			BrowseRealm(realm, THIS_ACCOUNT, true)
		end
	elseif searchLocation == SEARCH_ALLACCOUNTS then
		-- this account first ..
		for realm in pairs(DataStore:GetRealms()) do
			BrowseRealm(realm, THIS_ACCOUNT, true)
		end
		
		-- .. then all other accounts
		for account in pairs(DataStore:GetAccounts()) do
			if account ~= THIS_ACCOUNT then
				for realm in pairs(DataStore:GetRealms(account)) do
					BrowseRealm(realm, account, true)
				end
			end
		end
	else	-- search loot tables
		SearchLoots = true -- this value will be tested in ns:Update() to resize columns properly
	end

	-- everything below has to wait for the results, and the loot scan only produces them
	-- several frames from now, so it is packed up here and run either way
	local function Finish()
		filters:ClearFilters()

		if not AltoholicTabSearch:IsVisible() then
			addon.Tabs:OnClick("Search")
		end

		ongoingSearch = nil 	-- search done

		addon.Tabs.Search:SetMode(SearchLoots and "loots" or "realm")

		ns:Update()

		-- all of this has to come after Update, which writes a status line of its own -
		-- "0 results found (Showing 1-0)" being the least helpful of them
		if ns:GetNumResults() == 0 then
			if currentValue == "" then
				AltoholicTabSearch.Status:SetText(L["No match found!"])
			else
				AltoholicTabSearch.Status:SetText(value .. L[" not found!"])
			end
		elseif SearchLoots then
			ReportSearchStatus()
		end

		collectgarbage()
	end

	if not SearchLoots then
		Finish()
		return
	end

	-- show the tab now so that the progress written between batches is actually on screen
	if not AltoholicTabSearch:IsVisible() then
		addon.Tabs:OnClick("Search")
	end
	addon.Tabs.Search:SetMode("loots")
	ns:Update()

	addon.Loots:Find(ReportScanProgress, Finish)
end

local currentClass				-- the current character class
local upgradeStatFormat		-- the stat layout the displayed upgrade list was built with
local currentItemID				-- itemID of the item for which we're searching for an upgrade

function ns:SetClass(class)
	currentClass = class
end

function ns:SetUpgradeStatFormat(format)
	upgradeStatFormat = format
end

function ns:GetUpgradeStatFormat()
	return upgradeStatFormat
end

function ns:GetClass()
	return currentClass
end

function ns:SetCurrentItem(itemID)
	currentItemID = itemID
end

function ns:GetRealmsLineDesc(line)
	return RealmScrollFrame_Desc.Lines[line]
end

function ns:FindEquipmentUpgrade(upgradeType)
	-- called as a drop down callback, where self is the button carrying the value
	upgradeType = upgradeType or self.value
	local upgradeItemID = currentItemID		-- cleared once the search actually runs

	-- Resolve the reference item before touching anything else. Without it there is nothing
	-- to be better than: every filter value would be nil, which means "no constraint", and
	-- the search would return the entire loot table as an upgrade.
	local _, itemLink, _, itemLevel, _, itemType, itemSubType, _, itemEquipLoc = C_Item.GetItemInfo(upgradeItemID)

	if not itemLevel then
		currentItemID = nil
		addon:Print(L["Unknown link, please relog this character"])		-- the search tab may not even be up yet
		return		-- deliberately before ClearResults: do not wipe what is on screen
	end

	-- Walking the loot tables blocks the game for seconds, and nothing is drawn while Lua
	-- runs, so the tab has to be shown and the message set now, and the search itself put
	-- off to the next frame. Otherwise the user stares at a frozen client with no clue.
	if not AltoholicTabSearch:IsVisible() then
		addon.Tabs:OnClick("Search")
	end

	-- The category tree on the left holds whatever was picked the last time this tab was used
	-- by hand. It has no bearing on an upgrade search, which is driven by the reference item,
	-- so leaving it lit claims a filter that is not being applied.
	addon.Tabs.Search:ClearCategorySelection()

	-- SetMode("upgrade") builds the stat columns from FormatStats[GetClass()], and those
	-- keys are the role strings ("WarriorTank"), not the bare class the grid stored here
	if upgradeType ~= -1 then
		ns:SetClass(upgradeType)
		ns:SetUpgradeStatFormat(addon.Equipment.FormatStats[upgradeType])
	end

	addon.Tabs.Search:SetMode(upgradeType ~= -1 and "upgrade" or "loots")
	ns:ClearResults()
	ns:Update()
	AltoholicTabSearch.Status:SetText(format(L["SEARCHING_UPGRADES"], itemLink))
	AltoTooltip:Hide()

	C_Timer.After(0, function()
		ns:RunUpgradeSearch(upgradeItemID, upgradeType, itemLevel, itemType, itemSubType, itemEquipLoc)
	end)
end

function ns:RunUpgradeSearch(upgradeItemID, upgradeType, itemLevel, itemType, itemSubType, itemEquipLoc)
	local itemSlot = addon.Equipment:GetInventoryTypeIndex(itemEquipLoc)

	filters:SetFilterValue("itemLevel", itemLevel)
	filters:SetFilterValue("itemType", itemType)
	filters:SetFilterValue("itemSubType", itemSubType)

	filters:EnableFilter("Existence")
	filters:EnableFilter("ItemLevel")
	filters:EnableFilter("Type")
	filters:EnableFilter("SubType")
	
	if itemSlot ~= 0 then	-- don't apply filter if = 0, it means we take them all
		filters:SetFilterValue("itemSlot", itemSlot)
		filters:EnableFilter("EquipmentSlot")
	end
	
	local function Finish()
		filters:ClearFilters()
		currentItemID = nil

		AltoTooltip:Hide();	-- mandatory hide after processing

		ns:Update()
		ReportSearchStatus()		-- after Update, which writes a status line of its own
	end

	-- Start the search
	if upgradeType ~= -1 then	-- not an item level upgrade
		addon.Loots:FindUpgradeByStats(upgradeItemID, upgradeType, ReportScanProgress, Finish)

	else	-- simple search, point to simple VerifyUpgrade method
		addon.Loots:FindUpgrade(ReportScanProgress, function()
			AltoholicSearchOptionsLootInfo:SetText( colors.green .. Altoholic_UI_Options.TotalLoots .. "|r " .. L["Loots"] .. " / "
					.. colors.green .. Altoholic_UI_Options.UnknownLoots .. "|r " .. L["Unknown"])
			Finish()
		end)
	end

	-- if Altoholic_SearchTab_Options.SortDescending then 		-- descending sort ?
		-- AltoholicTabSearch.SortButtons.Sort8.ascendingSort = true		-- say it's ascending now, it will be toggled
		-- ns:SortResults(AltoholicTabSearch.SortButtons.Sort8, "iLvl")
	-- else
		-- AltoholicTabSearch.SortButtons.Sort8.ascendingSort = nil
		-- ns:SortResults(AltoholicTabSearch.SortButtons.Sort8, "iLvl")
	-- end
end

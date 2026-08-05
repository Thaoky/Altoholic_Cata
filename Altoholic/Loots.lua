local addonName = ...
local addon = _G[addonName]
local colors = addon.Colors

local L = AddonFactory:GetLocale(addonName)
local BB = LibStub("LibBabble-Boss-3.0"):GetLookupTable()
local LCI = LibStub("LibCraftInfo-1.0")
local LCL = LibStub("LibCraftLevels-1.0")
local TS = addon.TradeSkills.Names

-- *** The loot table ***
-- It used to be spelled out here: a few thousand ids covering world events, world drops and
-- PVP sets, and no instance loot at all - that came from three LibPeriodicTable sets buried
-- in DataStore_Inventory's library folder. Both are gone. See Altoholic/LootTable.lua, which
-- is generated from AtlasLoot Classic by tools/GenerateLootTable.lua.


local DataProviders

addon.Loots = {}

local ns = addon.Loots		-- ns = namespace

function ns:GetSource(searchedID)
	if InCombatLockdown() then	return nil end		-- exit if combat lockdown restrictions are active

	DataProviders = DataProviders or {			-- list of sources that have a :GetSource() method
		DataStore_Reputations,
		-- DataStore_Crafts,
		DataStore_Inventory,
	}

	local domain, subDomain
	for _, provider in pairs(DataProviders) do
		domain, subDomain = provider:GetSource(searchedID)
		if domain and subDomain then
			if type(subDomain == "boolean") and subDomain == true then	-- some items have no subDomain (ex: archeology)
				subDomain = nil
			end
			return domain, subDomain
		end
	end
	
	-- extremely fast: takes from 0.3 to 3 ms max, depends on the location of the item in the table (obviously longer if the item is at the end)
	for Instance, BossList in pairs(addon.LootTable) do
		for Boss, LootList in pairs(BossList) do
			for itemID, _ in pairs(LootList) do
				if LootList[itemID] == searchedID then
					return Instance, Boss
				end
			end
		end
	end
	
	local name, spellID = LCI:GetItemSource(searchedID)
	
	if name and spellID then
		return name, LCL:GetCraftLearnedAtLevel(spellID)
	end	
	
	return nil
end

local filters = addon.ItemFilters

-- *** Scanning without freezing the game ***
-- A scan walks the whole loot table, thousands of entries, each one a run through the
-- filters. Done in one go it blocks the client for seconds, and WoW draws nothing while Lua
-- runs, so there is no window in which to show progress - the game simply stops.
--
-- The scan therefore runs inside a coroutine that gives a frame back to the game every so
-- many items. It takes slightly longer in wall clock time, and in exchange the client
-- stays alive and can say how far along it is.

local itemsPerStep			-- items handled before yielding, set per scan
local itemsThisStep
local scanTotal, scanDone
local currentScan				-- the running coroutine, only one scan at a time
local currentTicker

local function Step()
	scanDone = scanDone + 1
	itemsThisStep = itemsThisStep + 1

	if itemsThisStep >= itemsPerStep then
		itemsThisStep = 0
		coroutine.yield()
	end
end

local function CountAllSources()
	local count = 0

	for _, bossList in pairs(addon.LootTable) do
		for _, lootList in pairs(bossList) do
			count = count + #lootList
		end
	end

	return count
end

function ns:CancelScan()
	if not currentTicker then return end

	currentTicker:Cancel()
	currentTicker = nil
	currentScan = nil
end

-- *** Banking the answers that arrive after the scan asked for them ***
-- Filtering an item is what requests it, and on a cold cache the client answers a moment later,
-- long after that item was judged. The judging is where the level is needed, so an item level
-- filter drops it, and the answer that would have kept it lands on an event nobody was reading.
--
-- That is why the candidate pool grew a little on each search instead of arriving whole: only
-- the items the client happened to answer for on the spot were written down. Reading the event
-- while a scan is in flight banks the rest of them, so the search after it sees the lot.
--
-- Altoholic:GetItemInfo writes to the memory itself when the client answers in full, so there
-- is nothing to do here but ask.
local ITEM_INFO_TAG = "LootScanMemory"
local stopBankingTimer

local function OnItemInfoReceived(event, itemID, success)
	if success then Altoholic:GetItemInfo(itemID) end
end

local function StartBankingItemInfo()
	if stopBankingTimer then
		stopBankingTimer:Cancel()
		stopBankingTimer = nil
	end

	addon:ListenTo("GET_ITEM_INFO_RECEIVED", OnItemInfoReceived, ITEM_INFO_TAG)
end

local function StopBankingItemInfo()
	-- the answers to the last batch are still on their way, so keep reading for a while
	if stopBankingTimer then stopBankingTimer:Cancel() end

	stopBankingTimer = C_Timer.NewTimer(15, function()
		stopBankingTimer = nil
		addon:StopListeningTo("GET_ITEM_INFO_RECEIVED", ITEM_INFO_TAG)
	end)
end

local function RunScan(work, batchSize, onProgress, onDone)
	-- A scan takes seconds, so a second search landing in the middle of one is the user
	-- asking to replace it. Dropping it instead left the previous results on screen, which
	-- reads as "the category filter returned the wrong things".
	ns:CancelScan()

	itemsPerStep = batchSize
	itemsThisStep = 0
	scanDone = 0

	StartBankingItemInfo()
	currentScan = coroutine.create(work)

	local ticker
	ticker = C_Timer.NewTicker(0, function()		-- 0 = once per frame
		if ticker ~= currentTicker then return end		-- superseded by a newer scan
		local ok, err = coroutine.resume(currentScan)

		if not ok then			-- an error inside the coroutine would otherwise be swallowed
			ticker:Cancel()
			currentTicker = nil
			currentScan = nil
			StopBankingItemInfo()
			geterrorhandler()(err)
			return
		end

		if coroutine.status(currentScan) == "dead" then
			ticker:Cancel()
			currentTicker = nil
			currentScan = nil
			StopBankingItemInfo()
			if onDone then onDone() end
		elseif onProgress then
			onProgress(scanDone, scanTotal)
		end
	end)

	currentTicker = ticker
end

function ns:IsScanning()
	return currentScan and true
end

-- *** Learning the whole table once ***
--
-- An item level filter needs a level, and a level only exists once the client has been asked
-- about that item. Asking is what a search does, one item at a time, and the answers land after
-- the search has already judged them - so the pool an upgrade search sees grows a little on
-- each run, and every fresh install starts from nothing. On a client where nothing had been
-- asked yet, a search for a pair of pants offered 44 candidates where the table holds 239.
--
-- Waiting for the game to find them a search at a time is the wrong way round. Ask for all of
-- them, once, and keep what comes back: the memory is a saved variable, so this is paid once
-- per install rather than once per session. Ids already in the memory are skipped, which makes
-- a second run cheap and turns it into the way to mop up whatever did not answer the first time.
--
-- Paced on purpose. The whole table is thousands of items, and asking for all of them at once
-- is what used to push the answers the client already had back out of its own cache.
local LEARN_BATCH = 10			-- items asked for per tick ..
local LEARN_INTERVAL = 0.05	-- .. every 20th of a second, so 200 a second
local LEARN_GRACE = 15			-- the last answers are still on their way when the asking stops

local learnTicker

function ns:IsLearning()
	return learnTicker and true
end

function ns:StopLearning()
	if learnTicker then
		learnTicker:Cancel()
		learnTicker = nil
	end

	StopBankingItemInfo()
end

-- Returns how many items it is going to ask about, so the caller can say so before it starts.
function ns:LearnItems(onProgress, onDone)
	ns:StopLearning()

	local seen = {}
	local todo = {}

	for _, bossList in pairs(addon.LootTable) do
		for _, lootList in pairs(bossList) do
			for _, itemID in pairs(lootList) do
				if not seen[itemID] then
					seen[itemID] = true

					-- an id this build does not have will never answer, and one the memory
					-- already holds has nothing left to say
					if C_Item.GetItemInfoInstant(itemID) and not Altoholic:GetRememberedItemInfo(itemID) then
						todo[#todo + 1] = itemID
					end
				end
			end
		end
	end

	local total = #todo
	local index = 0

	if total == 0 then
		if onDone then onDone(0) end
		return 0
	end

	StartBankingItemInfo()

	learnTicker = C_Timer.NewTicker(LEARN_INTERVAL, function()
		for _ = 1, LEARN_BATCH do
			index = index + 1

			if index > total then
				ns:StopLearning()		-- the banking listener keeps reading through its grace
				if onDone then onDone(total) end
				return
			end

			-- asking is the request; Altoholic:GetItemInfo writes down whatever comes back,
			-- now or on the event
			Altoholic:GetItemInfo(todo[index])
		end

		if onProgress then onProgress(index, total) end
	end)

	return total
end

-- How much of the table the memory can already answer for, which is what the caller reports
-- once the last answers have had their grace period.
function ns:CountItemsLearned()
	local seen = {}
	local known, total = 0, 0

	for _, bossList in pairs(addon.LootTable) do
		for _, lootList in pairs(bossList) do
			for _, itemID in pairs(lootList) do
				if not seen[itemID] and C_Item.GetItemInfoInstant(itemID) then
					seen[itemID] = true
					total = total + 1
					if Altoholic:GetRememberedItemInfo(itemID) then known = known + 1 end
				end
			end
		end
	end

	return known, total
end

local function ParseAltoholicLoots(OnMatch)
	assert(type(OnMatch) == "function")
	local count = 0
	
	for Instance, BossList in pairs(addon.LootTable) do
		for Boss, LootList in pairs(BossList) do
			for _, itemID in pairs(LootList) do
				count = count + 1
				Step()
				filters:SetSearchedItem(itemID)
				
				if filters:ItemPassesFilters() then
					OnMatch(Instance, Boss)
				end
			end
		end
	end
	
	filters:ClearSearchedItem()
	return count
end

local unknownCount

-- *** Items the client has never seen ***
-- The loot tables are lists of item id's. Resolving one the client does not know returns
-- nothing - no name, no rarity, no item level - so the Existence filter drops it and the
-- row never appears in the results.
--
-- Asking the server for it is what fixes that, and it has already happened by the time we
-- get here: SetSearchedItem() calls C_Item.GetItemInfo() on every entry while filtering,
-- and that call is itself the request for what is not cached. The answer arrives a moment
-- later on GET_ITEM_INFO_RECEIVED. So there is nothing to query, only a search to redo,
-- which is what the search module does with the flag below.
-- Items that exist in this build but whose name the client has not sent yet: they are
-- listed with their source, and only their name and level are blank. Counting them tells
-- the user the list is right but not fully labelled - which is a different thing from the
-- old count, which was "entries thrown away", most of them content this game does not have.
local numItemsUnnamed

function ns:GetNumItemsUnnamed()
	return numItemsUnnamed
end

-- The same item turns up more than once for several honest reasons: an encounter with several
-- faces (the Karazhan opera event) lists its loot under each of them, a boss drops the same
-- piece on normal and on heroic, and a reward is often both a drop and a reputation purchase.
--
-- Every search keeps one row per item and puts all of it on that row. Rows used to be kept per
-- item and instance while browsing, on the reading that where an item comes from is the
-- question there and each place deserves its own line. In practice the extra lines were not
-- places: a tier piece was listed once under the raid that drops it and again under the set
-- page, which says the same thing with a different label. 16% of the table is listed in more
-- than one section, and a search for cloth leg armour came back with 239 rows for 179 items.
--
-- The columns keep the meaning their headers give them: the left one is the place, the right
-- one is what drops it there. A source from somewhere other than the place named on the left
-- says where it is.
local SOURCE_SEP = " / "

local resultsByKey = {}		-- key -> index of the row already added for it

local function AddLootResult(domain, subdomain, fields)
	local itemID = filters:GetSearchedItemInfo("itemID")

	local key = itemID
	local index = resultsByKey[key]

	if index then
		local result = Altoholic.Search:GetResult(index)

		-- A row covers every place at once, so a source from somewhere other than the one named
		-- on the left has to say where it is, or the right hand column would list bosses of
		-- places the row does not mention. It also keeps two bosses of the same name, in two
		-- different instances, from being taken for one.
		local source = subdomain or domain

		if result and domain ~= result.dropLocation then
			source = subdomain and format("%s, %s%s", domain, colors.green, subdomain) or domain
		end

		-- a set rather than a substring test: one boss name can contain another
		if result and source and result.sources and not result.sources[source] then
			result.sources[source] = true
			result.numSources = (result.numSources or 1) + 1
			result.bossName = result.bossName and (result.bossName .. SOURCE_SEP .. source) or source

			-- the column runs out of room after three or four of them, so the list is kept
			-- whole and spelled out one to a line by the row's tooltip. Every entry names its
			-- own place, which the column only does for the ones that are not the row's own.
			local list = result.sourceList
			list[#list + 1] = format("%s, %s%s", domain, colors.green, subdomain or "")
		end
		return
	end

	local result = fields or {}

	result.id = itemID
	result.iLvl = filters:GetSearchedItemInfo("itemLevel")
	result.dropLocation = domain
	result.bossName = subdomain

	-- the stat comparison layout has no second column, it writes "place, boss" on one line and
	-- has no room for the rest, so the first source is kept on its own
	result.firstBoss = subdomain

	result.sources = subdomain and { [subdomain] = true } or nil
	result.numSources = 1
	result.sourceList = { format("%s, %s%s", domain, colors.green, subdomain or "") }

	local name = filters:GetSearchedItemInfo("itemName")

	if name then
		-- the filters have just resolved this item, so remember it without asking again
		Altoholic:RememberItem(itemID, name,
			filters:GetSearchedItemInfo("itemRarity"), filters:GetSearchedItemInfo("itemLevel"))
	else
		numItemsUnnamed = (numItemsUnnamed or 0) + 1
	end

	Altoholic.Search:AddResult(result)
	resultsByKey[key] = Altoholic.Search:GetNumResults()
end

local function OnMatch(domain, subdomain)
	AddLootResult(domain, subdomain)
end

-- The three searches below no longer return with the results ready: they hand the work to
-- RunScan and call onDone when the last item has been through the filters.

function ns:Find(onProgress, onDone)
	numItemsUnnamed = 0
	scanTotal = CountAllSources()
	wipe(resultsByKey)

	RunScan(function()
		local count = ParseAltoholicLoots(OnMatch)

		Altoholic_UI_Options.TotalLoots = count
		Altoholic_UI_Options.UnknownLoots = numItemsUnnamed
	end, 400, onProgress, onDone)
end

-- An item level upgrade search walks the same table with the caller's filters already set, and
-- draws in the same layout. What differs is what a row means. Browsing, the question is where
-- an item comes from, so one row per item and instance is right. Looking for an upgrade the
-- question is what to go and get, and the answer is one line per item however many places list
-- it - tier gear sits under its raid and again under the set page, and 684 of the Era table's
-- 4607 items are in more than one section, which is a lot of the list spent saying things twice.
function ns:FindUpgrade(onProgress, onDone)
	numItemsUnnamed = 0
	scanTotal = CountAllSources()
	wipe(resultsByKey)

	RunScan(function()
		local count = ParseAltoholicLoots(OnMatch)

		Altoholic_UI_Options.TotalLoots = count
		Altoholic_UI_Options.UnknownLoots = numItemsUnnamed
	end, 400, onProgress, onDone)
end

-- A tooltip of our own, for reading item stats. AltoTooltip cannot serve here any more:
-- the scan spans many frames now, so whatever it is showing is on screen while the search
-- runs - a stray item tooltip parked in the corner, which is what the user sees. This one
-- is owned by UIParent with no anchor and is never shown, only read.
local scanTooltip = CreateFrame("GameTooltip", "AltoholicScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local tooltipLines			-- cache containing the text lines of the tooltip "+15 stamina, etc.."
local rawItemStats			-- contains the raw stats of the item currently being searched, placed here to avoid creating/deleting the table during the search
local currentItemStats		-- contains the stats of the item for which we'll try to find upgrades

local classExcludedStats
local classBaseStats

local function AddCurrentlyEquippedItem(itemID, class)

	scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	local _, itemLink, _, itemLevel = C_Item.GetItemInfo(itemID)

	-- The reference item is worn by the character whose grid line was right-clicked, so it is
	-- normally in the cache. Normally is not always - an alt's gear comes from the saved
	-- variables, not from anything this session has looked at - and a nil link here takes the
	-- whole search down before the first candidate is even read.
	if not itemLink then
		if not itemLevel then _, _, itemLevel = Altoholic:GetRememberedItemInfo(itemID) end
		itemLink = "item:" .. itemID
	end

	scanTooltip:SetHyperlink(itemLink)
	
	local statLine = addon.Equipment.FormatStats[class]
	local numLines = scanTooltip:NumLines()
	
	local j=1
	for _, BaseStat in pairs(classBaseStats) do
		for i = 4, numLines do
			local tooltipText = _G[ "AltoholicScanTooltipTextLeft" .. i]:GetText()
			if tooltipText then
				if string.find(tooltipText, BaseStat) ~= nil then
					currentItemStats[BaseStat] = tonumber(string.sub(tooltipText, string.find(tooltipText, "%d+")))
					statLine = string.gsub(statLine, "-s", colors.white .. currentItemStats[BaseStat], 1)
					
					rawItemStats[j] = currentItemStats[BaseStat] .. "|0"
					break
				end
			end
		end
		if not currentItemStats[BaseStat] then
			rawItemStats[j] = "0|0"
		
			currentItemStats[BaseStat] = 0 -- Set the current stat to zero if it was not found on the item
			statLine = string.gsub(statLine, "-s", colors.white .. "0", 1)
		end
		j = j + 1
	end
	scanTooltip:ClearLines();
	
	-- Save currently equipped item to the results table
	addon.Search:AddResult( {
		id = itemID,
		iLvl = itemLevel,
		dropLocation = "Currently equipped",
		stat1 = rawItemStats[1],
		stat2 = rawItemStats[2],
		stat3 = rawItemStats[3],
		stat4 = rawItemStats[4],
		stat5 = rawItemStats[5],
		stat6 = rawItemStats[6]
	} )
end

-- Compares the item the filters are currently pointed at against the equipped one. The
-- caller has already run it through the filters, so this only does the stat reading.
local function CompareStats()
	if not classBaseStats or not classExcludedStats then return end

	-- The item memory carries a name, a rarity and a level for items the client has not seen
	-- this session, which is enough to get through the filters but not enough to build a
	-- tooltip: there is no link for an item that is not in the cache, and SetHyperlink()
	-- refuses a nil one.
	--
	-- Nothing is lost by leaving it out of this run: SetSearchedItem() has already called
	-- GetItemInfo() on it, which is itself the request to the server, so the next search will
	-- have the tooltip. It is counted with the others whose name is not known yet, so the
	-- status line says the list is not complete.
	local itemLink = filters:GetSearchedItemInfo("itemLink")
	if not itemLink then
		numItemsUnnamed = (numItemsUnnamed or 0) + 1
		return
	end

	scanTooltip:ClearLines();
	scanTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	scanTooltip:SetHyperlink(itemLink)
	
	-- save some time by trying to find out if the item could be excluded
	wipe(tooltipLines)
	for i = 4, scanTooltip:NumLines() do	-- parse all tooltip lines, one by one, start at 4 since 1= item name, 2 = binds on.., 3 = type/slot/unique ..etc
		-- in this first pass, save the lines into a cache, reused below
		local tooltipLine = _G[ "AltoholicScanTooltipTextLeft" .. i]:GetText()
		if tooltipLine then
			if string.find(tooltipLine, L["Socket"]) == nil then
				for _, v in pairs(classExcludedStats) do
					--if string.find(tooltipLine, v, 1, true) ~= nil then return end
					if string.find(tooltipLine, v) ~= nil then return end
				end
				tooltipLines[i] = tooltipLine
			end
		end
	end
	
	local statFound
	local j=1
	for _, BaseStat in pairs(classBaseStats) do

		statFound = nil
		for i, tooltipText in pairs(tooltipLines) do
			--if string.find(tooltipText, BaseStat, 1, true) ~= nil then
			if string.find(tooltipText, BaseStat) ~= nil then
				--local stat = tonumber(string.sub(tooltipText, string.find(tooltipText, "%d+")))
				local stat = tonumber(string.match(tooltipText, "%d+"))
				
				rawItemStats[j] = stat .. "|" .. (stat - currentItemStats[BaseStat])
				table.remove(tooltipLines, i)	-- remove the current entry, so it won't be parsed in the next loop cycle
				statFound = true
				break
			end
		end
		
		if not statFound then
			rawItemStats[j] = "0|" .. (0 - currentItemStats[BaseStat])
		end
		j = j + 1
	end
	
	-- All conditions ok ? save it
	return true, filters:GetSearchedItemInfo("itemLevel")
end

-- modify this one after 3.2, to use GetItemStats
function ns:FindUpgradeByStats(currentID, class, onProgress, onDone)
	numItemsUnnamed = 0
	scanTotal = CountAllSources()
	wipe(resultsByKey)

	classExcludedStats = addon.Equipment.ExcludeStats[class]
	classBaseStats = addon.Equipment.BaseStats[class]

	rawItemStats = {}
	currentItemStats = {}
	tooltipLines = {}

	AddCurrentlyEquippedItem(currentID, class)

	local function OnStatMatch(domain, subdomain)
		-- reading a tooltip is the expensive part, so check for a row we already have first
		local itemID = filters:GetSearchedItemInfo("itemID")

		-- already listed: note the extra source and stop, reading the tooltip again is the
		-- expensive part and it would yield the same stats for the same item
		if resultsByKey[ResultKey(itemID, domain)] then
			AddLootResult(domain, subdomain)
			return
		end

		local matches = CompareStats()
		if not matches then return end

		AddLootResult(domain, subdomain, {
			stat1 = rawItemStats[1],
			stat2 = rawItemStats[2],
			stat3 = rawItemStats[3],
			stat4 = rawItemStats[4],
			stat5 = rawItemStats[5],
			stat6 = rawItemStats[6]
		})
	end

	-- This used to walk the bundled table alone, which holds no instance loot at all - world
	-- events, world drops and PVP sets. So a search for a tanking upgrade came back with the
	-- item already worn and nothing else, and looked broken rather than empty. The same four
	-- sources as the other searches are used now.
	--
	-- A much smaller batch than those, though: every candidate here is compared by reading
	-- the lines of its tooltip, which costs far more than a filter check.
	RunScan(function()
		ParseAltoholicLoots(OnStatMatch)

		classExcludedStats = nil
		classBaseStats = nil
		currentItemStats = nil
		tooltipLines = nil
		rawItemStats = nil
	end, 60, onProgress, onDone)
end

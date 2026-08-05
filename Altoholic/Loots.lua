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

local function RunScan(work, batchSize, onProgress, onDone)
	-- A scan takes seconds, so a second search landing in the middle of one is the user
	-- asking to replace it. Dropping it instead left the previous results on screen, which
	-- reads as "the category filter returned the wrong things".
	ns:CancelScan()

	itemsPerStep = batchSize
	itemsThisStep = 0
	scanDone = 0

	currentScan = coroutine.create(work)

	local ticker
	ticker = C_Timer.NewTicker(0, function()		-- 0 = once per frame
		if ticker ~= currentTicker then return end		-- superseded by a newer scan
		local ok, err = coroutine.resume(currentScan)

		if not ok then			-- an error inside the coroutine would otherwise be swallowed
			ticker:Cancel()
			currentTicker = nil
			currentScan = nil
			geterrorhandler()(err)
			return
		end

		if coroutine.status(currentScan) == "dead" then
			ticker:Cancel()
			currentTicker = nil
			currentScan = nil
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
-- Browsing the loot tables, where an item comes from is the question, so the sources are
-- collected onto a single row per item and instance. Looking for an upgrade it is not the
-- question: one row per item is the answer, however many ways there are to get it.
local SOURCE_SEP = " / "

local resultsByKey = {}		-- key -> index of the row already added for it
local mergeSources

local function ResultKey(itemID, domain)
	return mergeSources and format("%s|%s", itemID, domain or "") or tostring(itemID)
end

local function AddLootResult(domain, subdomain, fields)
	local itemID = filters:GetSearchedItemInfo("itemID")

	-- Browsing keeps one row per item and instance and grows the boss column; an upgrade
	-- search keeps one row per item, whatever instance it came from, and grows the location
	-- column instead - there is no boss column in that layout.
	local key = ResultKey(itemID, domain)
	local field = mergeSources and "bossName" or "dropLocation"
	local source = mergeSources and subdomain
		or (subdomain and format("%s, %s%s", domain, colors.green, subdomain) or domain)

	local index = resultsByKey[key]

	if index then
		local result = Altoholic.Search:GetResult(index)

		-- a set rather than a substring test: one boss name can contain another
		if result and source and result.sources and not result.sources[source] then
			result.sources[source] = true
			result.numSources = (result.numSources or 1) + 1

			-- only the browse layout has the room to spell them all out; the upgrade one
			-- has a 210px line already holding "instance, boss", so it just gets a count
			if mergeSources then
				result[field] = result[field] .. SOURCE_SEP .. source
			end
		end
		return
	end

	local result = fields or {}

	result.id = itemID
	result.iLvl = filters:GetSearchedItemInfo("itemLevel")
	result.dropLocation = mergeSources and domain or source
	result.bossName = mergeSources and subdomain or nil
	result.sources = source and { [source] = true } or nil
	result.numSources = 1

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
	mergeSources = true		-- browsing: collect every source onto one row per instance

	RunScan(function()
		local count = ParseAltoholicLoots(OnMatch)

		Altoholic_UI_Options.TotalLoots = count
		Altoholic_UI_Options.UnknownLoots = numItemsUnnamed
	end, 400, onProgress, onDone)
end

-- An item level upgrade search is the browse search with the caller's filters already set :
-- RunUpgradeSearch narrows on type, sub type, slot and item level, then walks the same table,
-- and the results are drawn in the same layout, boss column included. It used to add its rows
-- itself, bypassing AddLootResult, so it was the one search that never merged anything: an item
-- reachable three ways inside one instance came back as three rows.
function ns:FindUpgrade(onProgress, onDone)
	return ns:Find(onProgress, onDone)
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
	mergeSources = nil		-- one row per item, however many ways there are to get it

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

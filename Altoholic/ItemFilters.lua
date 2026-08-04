local addonName = ...
local addon = _G[addonName]

local filters = {}
local searchedItem = {}

-- item filtering functions
-- "Does this item exist in the game we are running", not "is it in the item cache".
--
-- It used to mean the latter, which threw away every entry the client had simply never
-- seen - most of the loot tables on a fresh login, since that cache is rebuilt from
-- nothing every session. A search for idols returned the two the client happened to know.
--
-- The client's own database answers the real question without a cache and without asking
-- the server, and it also answers no for the content of expansions this build does not
-- have, which is most of what the loot data carries.
local function FilterExistence()
	return searchedItem["existsInClient"] and true
end

local function FilterType()
	local itemType = filters["itemType"]
	if not itemType or searchedItem["itemType"] == itemType then
		return true		-- no filter, or searched item is the same type as filter, keep it
	end
end

local function FilterSubType()
	local subType = filters["itemSubType"]
	if not subType or searchedItem["itemSubType"] == subType then
		return true		-- no filter, or searched item is the same sub type as filter, keep it
	end
end

-- The two nil cases below are not the same thing, and both happen:
--   a nil filter value means no constraint was asked for, so everything passes it
--   a nil value on the searched item means the client cannot resolve that item, so there
--   is nothing to compare and it cannot be kept.
-- The Existence filter is meant to catch the second case before any other filter runs, but
-- it only does so if it happens to be first in the list, so every filter guards itself.

-- These two are enabled on every search whatever the user picked, so "Poor" and an empty
-- level box have to mean "no constraint" rather than "a constraint I cannot evaluate".
-- Treating them as constraints rejected every item the client has not cached, which is what
-- kept a category search down to the handful of items already known.
local function FilterRarity()
	local rarity = filters["itemRarity"]
	if not rarity or rarity == 0 then return true end		-- Poor: everything qualifies

	local itemRarity = searchedItem["itemRarity"]
	return itemRarity and itemRarity >= rarity
end

local function FilterItemLevel()
	local filterLevel = filters["itemLevel"]
	if not filterLevel then return true end		-- no filter

	local itemLevel = searchedItem["itemLevel"]
	return itemLevel and itemLevel > filterLevel		-- strictly superior, fully intentional
end

local function FilterEquipmentSlot()
	local equipLoc = searchedItem["itemEquipLoc"]
	if not equipLoc then return end

	return addon.Equipment:GetInventoryTypeIndex(equipLoc) == filters["itemSlot"]
end

local function FilterName()
	local name = filters["itemName"]
	if not name then return true end		-- no filter

	local itemName = searchedItem["itemName"]
	return itemName and string.find(strlower(itemName), name, 1, true) and true
end

local function FilterMinimumLevel()
	local filterLevel = filters["itemMinLevel"]
	local minLevel = searchedItem["itemMinLevel"]

	if not minLevel then		-- the client has not cached this item
		return not filterLevel or filterLevel == 0		-- keep it unless a level was asked for
	end

	if minLevel == 0 then
		-- the option belongs to Altoholic_Search, which is load on demand
		return Altoholic_SearchTab_Options and Altoholic_SearchTab_Options.IncludeNoMinLevel
	end

	return not filterLevel or minLevel >= filterLevel
end

local function FilterMaximumLevel()
	local filterLevel = filters["itemMaxLevel"]
	if not filterLevel or filterLevel == 0 then return true end

	local minLevel = searchedItem["itemMinLevel"]
	return minLevel and minLevel <= filterLevel
end

local filterFunctions = {
	["Existence"] = FilterExistence,
	["Type"] = FilterType,
	["SubType"] = FilterSubType,
	["Rarity"] = FilterRarity,
	["ItemLevel"] = FilterItemLevel,
	["EquipmentSlot"] = FilterEquipmentSlot,
	["Name"] = FilterName,
	["MinLevel"] = FilterMinimumLevel,
	["Maxlevel"] = FilterMaximumLevel,
}

addon.ItemFilters = {}

local ns = addon.ItemFilters		-- ns = namespace

function ns:SetFilterValue(field, value)
	filters[field] = value
end

function ns:GetFilterValue(field)
	return filters[field]
end

local NAMES = {}

-- The filters that read nothing but the client's static item data, which is there for every
-- item in the build and costs nothing to ask for. Running these before the call that may go
-- to the server is what keeps a scan of the loot tables cheap: most of what they hold is the
-- content of later expansions, and of what is left, a category search throws away all but one
-- sub type. See SetSearchedItem below.
local INSTANT_FILTERS = {
	["Existence"] = true,
	["Type"] = true,
	["SubType"] = true,
	["EquipmentSlot"] = true,
}

function ns:EnableFilter(filter)
	if filterFunctions[filter] then
		filters.list = filters.list or {}
		table.insert(filters.list, filterFunctions[filter])
		table.insert(NAMES, filter)

		if INSTANT_FILTERS[filter] then
			filters.instantList = filters.instantList or {}
			table.insert(filters.instantList, filterFunctions[filter])
		end
	end
end

function ns:ItemPassesFilters(verbose)
	-- verbose: for debug purposes only

	-- Exclusive approach:
	-- 	by default, it is considered that no item is filtered out unless a specific filter is enabled.
	-- 	ex: if a user wants to filter items based on their level in the UI, it means he doesn't want to see items outside of the specifies boundaries, so the filter "Level" is enabled, and items are filtered out.

	if filters.list then		-- there might not be any filter
		-- ipairs, not pairs: the list is an array and the order matters, Existence is
		-- enabled first on purpose so that unresolved items are dropped before any
		-- filter tries to compare their values
		for name, func in ipairs(filters.list) do
			if verbose then
				print("Testing filter : " .. NAMES[name])
			end
		
			if not func() then		-- if any of the filters returns false/nil, exit
				if verbose then
					print("exiting on " .. NAMES[name])
					print(searchedItem["itemName"])
					print(filters["itemName"])
				end
				return
			end
		end
	end
	return true			-- return true if all filters have returned true
end

function ns:ClearFilters()
	wipe(filters)
	wipe(NAMES)		-- kept in step with filters.list, it is indexed by the same position
end

function ns:TryFilter(filter)
	if filterFunctions[filter] then
		return filterFunctions[filter]()
	end
end

-- currently searched item
-- *** Order matters here, and it is about cost ***
-- GetItemInfo() is the expensive one: on an item the client has not cached, the call itself is
-- the request to the server, and a scan of the loot tables makes tens of thousands of them.
-- That flood is what made a search sluggish and what appeared to push the alts' own equipment
-- out of the cache.
--
-- GetItemInfoInstant() reads the client's static database instead. No cache, no server, and it
-- answers for every item in the build - which also means it answers nothing for the items of
-- expansions this build does not have, most of what the loot tables carry.
--
-- So the cheap call comes first, and the expensive one is only made for items that have
-- survived the filters that the cheap one can already decide. Searching for idols, that is
-- three or four hundred calls instead of seventeen thousand.
function ns:SetSearchedItem(itemID, itemLink, isBattlePet)
	local s = searchedItem
	local _

	s.itemID = itemID

	local instantID, instantType, instantSubType, instantEquipLoc = C_Item.GetItemInfoInstant(itemID)

	s.existsInClient = instantID and true or nil
	s.itemType = instantType
	s.itemSubType = instantSubType
	s.itemEquipLoc = instantEquipLoc
	s.itemName, s.itemLink, s.itemRarity, s.itemLevel, s.itemMinLevel = nil, nil, nil, nil, nil

	-- A caller holding a link already has the item in hand - a bag, a bank, a mail - so there
	-- is nothing to save and the fields below have to be filled whatever the filters say.
	if not itemLink then
		if not instantID then return end		-- not an item of this build

		if filters.instantList then
			for _, func in ipairs(filters.instantList) do
				if not func() then return end		-- decided already, without asking the server
			end
		end
	end

	s.itemName, s.itemLink, s.itemRarity, s.itemLevel,	s.itemMinLevel, s.itemType, s.itemSubType, _, s.itemEquipLoc = C_Item.GetItemInfo(itemLink or itemID)

	if s.itemName then return end		-- fully cached, nothing to fill in

	-- not cached: keep what the static data gave, it is better than nothing
	s.itemType = instantType
	s.itemSubType = instantSubType
	s.itemEquipLoc = instantEquipLoc

	-- name, rarity and level are not in the client's static data, but they may be in ours
	s.itemName, s.itemRarity, s.itemLevel = Altoholic:GetRememberedItemInfo(itemID)
end

function ns:GetSearchedItemInfo(field)
	return searchedItem[field]
end

function ns:ClearSearchedItem()
	wipe(searchedItem)
end

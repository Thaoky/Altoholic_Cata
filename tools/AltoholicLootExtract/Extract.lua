--[[
	Altoholic loot extractor - a development tool, not part of the addon.

	Altoholic's loot data comes from two places today: a small table bundled in Loots.lua that
	holds no instance loot at all, and three LibPeriodicTable sets that ship inside
	DataStore_Inventory. Neither is maintained, and both have holes - Idol of the Claw drops
	from Pandemonius in Mana-Tombs and is in none of them, while the four items either side of
	it in the same loot table are.

	AtlasLoot Classic does not have those holes and is kept up to date for exactly the clients
	this fork runs on, so it is used as the source. Not as a dependency: this addon is run once
	per client, writes what it finds to a saved variable, and the result is turned into a Lua
	file that Altoholic ships itself. Players never need AtlasLoot, and this tool is never
	distributed with the addon.

	Usage:
		- drop this folder into Interface\AddOns of a client that has AtlasLoot Classic
		- log in, run /altoextract
		- /reload or log out, so the saved variable is written to disk
		- the dump is in WTF\Account\<account>\SavedVariables\AltoholicLootExtract.lua

	Do that once on Era and once on TBC. The two dumps are merged offline.

	*** On duplicates ***
	Nothing is merged or dropped here. The same item id turns up legitimately in more than one
	place - a boss with several faces lists its loot under each, an item is both a drop and a
	token purchase, and an item that exists in both Era and TBC may well come from different
	sources in the two. Deciding what is really the same entry needs every attribute, so every
	occurrence is written out with its full provenance and with the source row serialized whole,
	including the vendor price, the faction variants and anything else AtlasLoot put on it.
	The comparison happens offline, where a wrong call can be seen and corrected.
]]

local ADDON_NAME = ...

local DB_VERSION = 1

-- Colour escapes are in the raw names too: nameFormat is applied by GetName() whether or not
-- the raw flag is set, and several instances use it to prefix their wing ("Auch:|r %s").
-- The prefix is worth keeping, the escapes are not.
local function StripEscapes(text)
	if type(text) ~= "string" then return text end

	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	text = text:gsub("|T.-|t", "")
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Sorts numbers before strings so that a row always serializes the same way, whatever order
-- pairs() happens to walk it in. Two occurrences can then be compared as plain text.
local function CompareKeys(a, b)
	local ta, tb = type(a), type(b)

	if ta == tb then return a < b end
	return ta == "number"
end

local function SerializeValue(value, depth)
	local valueType = type(value)

	if valueType == "table" then
		if depth > 4 then return "{...}" end		-- no data nests this deep, but do not hang on a cycle

		local keys = {}
		for key in pairs(value) do
			if type(key) == "number" or type(key) == "string" then
				keys[#keys + 1] = key
			end
		end
		table.sort(keys, CompareKeys)

		local parts = {}
		for _, key in ipairs(keys) do
			parts[#parts + 1] = tostring(key) .. "=" .. SerializeValue(value[key], depth + 1)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end

	if valueType == "string" then return StripEscapes(value) end
	return tostring(value)
end

-- "1=3,2=25940" for a plain drop, "1=7,2=30637,902=30622" for one with an Alliance variant,
-- "1=1,2=22539,101=money:60000" for one bought rather than dropped. The numbers above 100 are
-- AtlasLoot's own constants, kept as they are: what they mean is decided offline, and losing
-- them here would be losing the very attributes that tell two entries apart.
local function SerializeRow(row, tableKind)
	if type(row) ~= "table" then return SerializeValue(row, 0) end

	local keys = {}
	for key in pairs(row) do
		if type(key) == "number" or type(key) == "string" then
			keys[#keys + 1] = key
		end
	end
	table.sort(keys, CompareKeys)

	local parts = {}
	for _, key in ipairs(keys) do
		parts[#parts + 1] = tostring(key) .. "=" .. SerializeValue(row[key], 1)
	end

	-- *** Professions name a spell, not an item ***
	-- A crafting row carries the id of the spell that makes the thing, so taken at face value
	-- the whole Crafting module is unusable: it would put spell ids in a table of items. That
	-- is why it was left out at first, and leaving it out meant every craftable in the game
	-- was missing from a search that is supposed to answer where an item comes from.
	--
	-- AtlasLoot has the mapping - it is what its own buttons use to draw the crafted item - so
	-- the spell is resolved here, while the library is loaded, rather than guessed at later.
	-- The recipe that teaches it is worth having too: it is an item in its own right, and one
	-- that people look for.
	if tableKind == "Profession" then
		local spellID = tonumber(row[2])
		local Profession = AtlasLoot.Data and AtlasLoot.Data.Profession

		if spellID and Profession and Profession.IsProfessionSpell(spellID) then
			local crafted = Profession.GetCreatedItemID(spellID)

			if crafted then
				parts[#parts + 1] = "crafted=" .. crafted

				local recipe = Profession.GetRecipeForCreatedItem(crafted)
				if recipe then parts[#parts + 1] = "recipe=" .. recipe end
			end
		end
	end

	-- *** Set pages name a set, not its pieces ***
	-- Same shape of problem, and skipping them was a real loss rather than a harmless one.
	-- Tier 1 and Tier 2 are safe to skip, because every piece drops from a boss and is listed
	-- there anyway - but Tier 0.5 is the reward of a quest chain and Tier 3 is handed over for
	-- a token, so no boss lists them and the set page is the only place they appear. All 72
	-- pieces of Tier 0.5 and 32 of the 36 Tier 3 pieces were missing because of this.
	if tableKind == "Set" then
		local setID = tonumber(row[2])
		local ItemSet = AtlasLoot.Data and AtlasLoot.Data.ItemSet

		if setID and ItemSet and ItemSet.GetSetItems then
			local items = ItemSet.GetSetItems(setID)

			if type(items) == "table" then
				local ids = {}
				for _, itemID in ipairs(items) do
					if type(itemID) == "number" then ids[#ids + 1] = tostring(itemID) end
				end
				if #ids > 0 then parts[#parts + 1] = "setitems=" .. table.concat(ids, "+") end
			end
		end
	end

	return table.concat(parts, ",")
end

local function JoinNumbers(value)
	if type(value) == "number" then return tostring(value) end
	if type(value) ~= "table" then return nil end

	local parts = {}
	for _, v in ipairs(value) do
		if type(v) == "number" then parts[#parts + 1] = tostring(v) end
	end
	return #parts > 0 and table.concat(parts, ",") or nil
end

-- *** The walk ***
-- AtlasLoot's own accessors are used throughout rather than reading the data files from the
-- outside. Instance and boss names are locale keys resolved at load time, difficulties are
-- registered per module, and a boss table can be an alias for another difficulty or a link
-- into a different module entirely. Asking the library means all of that is already resolved
-- and stays right when AtlasLoot changes.

local function ExtractBossDifficulty(out, itemDB, storage, addonName, contentName, content, bossIndex, boss, diff)
	local itemTable, tableType, diffData = itemDB:GetItemTable(addonName, contentName, bossIndex, diff)

	-- GetItemTable answers a string plus a reason when it had to go and load another module.
	-- That module is loaded by then, so the caller retries; it is not an item table.
	if type(itemTable) ~= "table" then return "deferred" end

	local instanceName, bossName, diffName = itemDB:GetNameData_UNSAFE(addonName, contentName, bossIndex, diff)

	local source = {
		module = addonName,
		content = contentName,			-- AtlasLoot's own key, stable across locales
		bossIndex = bossIndex,
		diffIndex = diff,

		instance = StripEscapes(instanceName),
		boss = StripEscapes(bossName),
		difficulty = StripEscapes(diffName) or (diffData and StripEscapes(diffData.name)),

		-- everything below is only here so that the offline merge can tell a real duplicate
		-- from two entries that merely share an item id
		npcID = JoinNumbers(itemDB:GetNpcID_UNSAFE(addonName, contentName, bossIndex)),
		instanceID = content.InstanceID,
		mapID = content.MapID,
		levelRange = JoinNumbers(content.LevelRange),
		contentType = content.ContentType,
		tableType = tableType and tableType[1] or nil,		-- "Item", "Set", "Profession"...

		-- AtlasLoot's own flags for tables that are shown but are not where an item comes
		-- from: the key ring of an instance, its tier set overview. Kept rather than acted
		-- on, so that the decision to skip them is visible in the generator and not buried
		-- in a dump that no longer says why something is missing.
		ignoreAsSource = (content.IgnoreAsSource or boss.IgnoreAsSource or itemTable.IgnoreAsSource) and true or nil,
		extraList = (content.ExtraList or boss.ExtraList or itemTable.ExtraList) and true or nil,
	}

	local rows = {}
	for i = 1, #itemTable do
		rows[#rows + 1] = SerializeRow(itemTable[i], source.tableType)
	end

	if #rows == 0 then return "empty" end

	source.rows = rows
	out[#out + 1] = source

	return "ok", #rows
end

local function Extract()
	local atlas = _G.AtlasLoot
	if not atlas or not atlas.ItemDB then
		return nil, "AtlasLoot Classic is not loaded."
	end

	local itemDB = atlas.ItemDB
	local storageList = itemDB.Storage
	if not storageList then
		return nil, "AtlasLoot is loaded but its item database is not reachable."
	end

	local out = {}
	local stats = { sources = 0, rows = 0, modules = 0, errors = 0, deferred = 0 }
	local problems = {}

	for addonName in pairs(storageList) do
		local storage = storageList[addonName]
		local ok, moduleList = pcall(itemDB.GetModuleList, itemDB, addonName)

		if ok and type(moduleList) == "table" then
			stats.modules = stats.modules + 1

			for _, contentName in ipairs(moduleList) do
				local content = storage[contentName]

				if type(content) == "table" and type(content.items) == "table" then
					for bossIndex = 1, #content.items do
						local boss = content.items[bossIndex]

						if type(boss) == "table" then
							-- Only the difficulties the boss actually declares. Asking for one
							-- it does not have makes GetItemTable fall back to another, which
							-- would write the same loot out twice under two names.
							for diff = 1, 20 do
								if boss[diff] ~= nil then
									local success, result, count = pcall(ExtractBossDifficulty,
										out, itemDB, storage, addonName, contentName, content, bossIndex, boss, diff)

									if not success then
										stats.errors = stats.errors + 1
										if #problems < 20 then
											problems[#problems + 1] = format("%s / %s / boss %d / diff %d: %s",
												addonName, contentName, bossIndex, diff, tostring(result))
										end
									elseif result == "ok" then
										stats.sources = stats.sources + 1
										stats.rows = stats.rows + (count or 0)
									elseif result == "deferred" then
										stats.deferred = stats.deferred + 1
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return out, nil, stats, problems
end

local function Run()
	local atlas = _G.AtlasLoot
	if not atlas then
		print("|cFFFF4444AltoholicLootExtract|r: AtlasLoot Classic was not found in this client.")
		return
	end

	-- Most of the loot lives in modules that are load on demand, and an unloaded one simply
	-- is not in the item database - the dump would come out quietly short rather than fail.
	if atlas.Loader and atlas.Loader.LoadAllModules then
		pcall(atlas.Loader.LoadAllModules, atlas.Loader, true)
	end

	local data, err, stats, problems = Extract()
	if not data then
		print("|cFFFF4444AltoholicLootExtract|r: " .. err)
		return
	end

	-- A first pass can leave entries deferred, because reading a boss whose table lives in
	-- another module is what triggers that module to load. The second pass finds them loaded.
	if stats.deferred > 0 then
		local second, secondErr, secondStats, secondProblems = Extract()
		if second then
			data, stats, problems = second, secondStats, secondProblems
		end
	end

	AltoholicLootExtractDB = {
		version = DB_VERSION,
		extractedOn = date("%Y-%m-%d %H:%M:%S"),
		tocVersion = select(4, GetBuildInfo()),
		build = GetBuildInfo(),
		locale = GetLocale(),
		atlasLootVersion = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)("AtlasLootClassic", "Version"),
		stats = stats,
		problems = problems,
		sources = data,
	}

	print(format("|cFF00FF00AltoholicLootExtract|r: %d loot tables, %d rows, from %d modules.",
		stats.sources, stats.rows, stats.modules))

	if stats.errors > 0 then
		print(format("|cFFFFFF00AltoholicLootExtract|r: %d tables could not be read, see 'problems' in the dump.", stats.errors))
	end

	print("|cFF00FF00AltoholicLootExtract|r: now /reload or log out, the dump is only written to disk then.")
end

SLASH_ALTOEXTRACT1 = "/altoextract"
SlashCmdList["ALTOEXTRACT"] = Run

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	print("|cFF00FF00AltoholicLootExtract|r loaded. Run |cFFFFFFFF/altoextract|r, then /reload.")
end)

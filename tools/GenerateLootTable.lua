--[[
	Turns the dumps written by tools/AltoholicLootExtract into Altoholic's own loot table.

	Run it offline, with any Lua 5.1 interpreter. The dumps go in expansion order, oldest first:

		luajit tools/GenerateLootTable.lua <era dump> <tbc dump> > Altoholic/LootTable.lua

	*** Why the output is layered ***

	The first attempt put everything in one table and left it to the Existence filter to drop
	what the running client does not have. That was wrong, and Era showed it: 44% of the entries
	are Burning Crusade content, and the client's static item database answers for a good many
	of those ids even though the server will never send their name. The filter kept them, the
	rows appeared as "Unknown #12345", and no amount of waiting resolved them, because there was
	nothing to resolve.

	So the split is decided here, where it is known for certain, rather than guessed at runtime.
	The base table is what an Era client should see. Each later expansion is a separate block,
	holding only what it adds, merged in at load time and only on a client that has it. Adding
	Wrath later means one more dump on the command line and one more block in the output.

	*** What is kept, and why ***

	Five of AtlasLoot's modules answer the question this table exists for - where does this item
	come from:

		DungeonsAndRaids   instance loot, the whole point of the exercise
		PvP                battleground and rank rewards
		Factions           reputation rewards
		Collections        mounts, pets, tabards, world epics, seasonal events
		Crafting           everything the professions make, and the recipes that teach them

	A sixth is read last and under a rule of its own:

		TBC_Phase_*        best in slot lists. These are advice, not places, and reading them as
		                   sources produced four rows for Idol of Brutality - one for Stratholme
		                   where it drops, and three more for the druid tank lists of phases 0, 2
		                   and 3. They are still read, because a few hundred items appear nowhere
		                   else in AtlasLoot, but only for what no real loot page accounts for.

	*** What counts as an item id ***

	Measured on the two dumps rather than assumed:

		field 1        position in the loot page, 0..199. Never an item.
		field 2        the item - except on a profession page, where it is the spell that makes
		               the item. Sometimes a string instead: "f529rep8" is AtlasLoot's own
		               placeholder for a reputation level, and a texture name marks a header
		               row. Sometimes a file id above 100000, on the PvP rank tables, which are
		               pictures of rank insignia rather than loot.
		field 3        a second item on the same row, when numeric. A header label when not.
		901 / 902      the Horde and Alliance versions of the same reward. Both are real items
		               and both are kept. A value of true means "this side only", not an id.
		903 / 904      how many of item 1 and item 2 - counts, not ids. Seen up to 1200.
		101..105       the price, as a string. Not an item.
		crafted        written by the extractor, not by AtlasLoot: the item a profession spell
		recipe         produces, and the recipe that teaches it.

	*** On duplicates ***

	Nothing is deduplicated across sources. Two entries collapse only when the instance, the
	boss and the item are all the same, which is the only case where they are the same fact
	written twice. An item that exists in both Era and TBC but drops from different places
	keeps both places - the PvP mounts are exactly that: Era lists the rank 11 mounts and TBC
	the arena ones under the same heading, and all eight belong in the table.

	Where the two dumps do describe the same table, the union of their rows is taken. That is
	not a merge of opinions: 521 of the 536 shared tables are byte for byte identical, and of
	the 15 that differ, most differ because the TBC data spells out a faction pair that the Era
	data left half written. The union keeps the more complete of the two without having to
	decide which one is right.
--]]

-- *** Everything AtlasLoot has ***
--
-- This used to be a list of modules to keep and a list of page kinds to skip, and every single
-- one of those judgements turned out to be wrong when it was finally measured. Trusting
-- AtlasLoot's own IgnoreAsSource flag cost 1348 items - the trash tables of nearly every
-- instance, the pattern drops of Sunwell and Black Temple, the Dire Maul tribute run. Skipping
-- the set pages cost all 72 pieces of Tier 0.5 and 32 of the 36 Tier 3 ones, because those are
-- quest and token rewards that no boss lists.
--
-- So the rule is reversed. Everything is read, and a value is left out only where it is known
-- not to be an item id - which is a question about the value, not about the page it sits on:
--
--   a profession row names the spell that makes the thing, and a set row names the set, so
--   both are translated by the extractor into fields of their own while AtlasLoot is loaded
--
--   anything at or above 100000 is a texture file id, which is what the PvP rank pages hold
--
-- Duplicates take care of themselves: the same item under the same heading is the same fact
-- written twice and collapses, everything else is a genuinely different place to find it.

-- Which fields of a row hold an item, by the kind of page the row sits on.
--
-- Item pages put it in field 2, with a second item in 3 and the faction pair in 901 and 902.
--
-- Profession pages put a spell id in field 2 - the spell that makes the thing - so reading it
-- as an item would fill the table with nonsense. The extractor resolves it while AtlasLoot is
-- loaded and writes the result into fields of its own, which is what is read here.
--
-- Set pages name a set, and the extractor resolves it into its pieces. Skipping them looked
-- safe - Tier 1 and Tier 2 pieces all drop from bosses and are listed there - but Tier 0.5 is
-- a quest chain reward and Tier 3 is handed over for a token, so nothing else lists those. It
-- cost all 72 Tier 0.5 pieces and 32 of the 36 Tier 3 ones.
--
-- Any other kind of page, known or added by a later AtlasLoot, is read as a plain loot page.
-- Its rank insignia and header textures fall out on the id range on their own, and a page kind
-- nobody anticipated is better read wrongly than not read at all.
--
-- The two below hold something else again in field 2, and both are recent: an achievement id,
-- which is numbered in the same range as items and would be taken for one, and a texture file
-- id on the pages that draw PvP rank insignia. Every other field of those pages is read as
-- normal, in case a real reward sits beside the thing being illustrated.
local ID_FIELDS = {
	Profession = { "crafted", "recipe" },
	Set = { "setitems" },
	Achievement = { "3", "901", "902", "crafted", "recipe", "setitems" },
	Dummy = { "3", "901", "902" },
}

local DEFAULT_ID_FIELDS = { "2", "3", "901", "902", "crafted", "recipe", "setitems" }

-- *** Modules that do not declare which expansion they belong to ***
--
-- AtlasLoot's own data files guard themselves - data-tbc.lua opens with GameVersion_LT and
-- returns on anything older - so nothing of theirs reaches a client that should not have it.
--
-- The Burning Crusade best in slot addons do not. They call ItemDB:Add() with no game version
-- at all, so an Era client that happens to have them installed registers Karazhan best in slot
-- lists as if they were Era content, and the dump comes out with them in it.
--
-- The folder name and the interface version in their toc both say what they are, and neither
-- reaches the item database, so the name is what is read here.
local EXPANSION_MODULES = {
	{ token = "_TBC_", minToc = 20000 },
	{ token = "_Wrath_", minToc = 30000 },
	{ token = "_Cata_", minToc = 40000 },
}

local function ModuleBelongsToLayer(module, layer)
	for _, rule in ipairs(EXPANSION_MODULES) do
		if module:find(rule.token, 1, true) then
			return (layer.minToc or 0) >= rule.minToc
		end
	end
	return true
end

-- *** Pages that are advice, not a place ***
--
-- The best in slot modules list, per class and per phase, what to wear. Read as sources they
-- lie: Idol of Brutality came out four times, once for Stratholme where it actually drops and
-- three more for the druid tank lists of phases 0, 2 and 3.
--
-- They are still worth reading, because 611 items appear nowhere else in AtlasLoot at all -
-- quest rewards, vendor goods, world drops that no loot page covers. So they are read last,
-- and only for what nothing else already accounts for.
local function IsAdvisoryModule(module)
	return module:find("_Phase_", 1, true) and true or false
end

-- One field can hold several ids, joined by a plus.
local MULTI_FIELDS = { setitems = true }
local MAX_ITEM_ID = 100000		-- above this the value is a file id, not an item

local DEFAULT_DIFFICULTY = "Normal"

local function LoadDump(path)
	local chunk = assert(loadfile(path), "cannot read " .. tostring(path))
	local env = {}
	setfenv(chunk, env)
	chunk()
	return assert(env.AltoholicLootExtractDB, "no dump in " .. path)
end

local function ParseRow(row)
	local fields = {}
	for pair in row:gmatch("[^,]+") do
		local k, v = pair:match("^([^=]+)=(.*)$")
		if k then fields[k] = v end
	end
	return fields
end

-- One layer per dump, in the order they were given. Everything a layer already carries is
-- taken out of the layers after it, so each one holds only what its expansion adds.
local LAYERS = {
	{ name = "Classic Era", minToc = nil },
	{ name = "The Burning Crusade", minToc = 20000 },
	{ name = "Wrath of the Lich King", minToc = 30000 },
	{ name = "Cataclysm", minToc = 40000 },
}

-- *** Collecting ***

local layers = {}		-- [n] = { table = instance -> boss -> ids, order = ..., instances = ... }

local stats = { kept = 0, items = 0, skippedModule = 0, skippedType = 0, skippedFlagged = 0,
	skippedRow = 0, duplicates = 0, inherited = 0, advisoryKept = 0, advisoryDropped = 0 }

local function BossLabel(source)
	local boss = source.boss
	if not boss or boss == "" then boss = "?" end

	-- Heroic and normal are two different loot tables for the same encounter, and saying so is
	-- the only way a reader can tell why the same boss lists two sets of items.
	local difficulty = source.difficulty
	if difficulty and difficulty ~= "" and difficulty ~= DEFAULT_DIFFICULTY then
		boss = string.format("%s (%s)", boss, difficulty)
	end

	return boss
end

local knownIds = {}		-- every id a real loot page accounted for, across all layers

local function Add(layer, instance, boss, itemID, advisory)
	-- A best in slot list only speaks for an item nothing else places.
	if advisory and knownIds[itemID] then
		stats.advisoryDropped = stats.advisoryDropped + 1
		return
	end

	-- Anything an earlier expansion already lists in the same place is the same fact written
	-- twice, and belongs to the earlier one. Anything it does not is what this expansion adds.
	for i = 1, #layers do
		if layers[i] == layer then break end
		local earlier = layers[i].table[instance]
		if earlier and earlier[boss] and earlier[boss][itemID] then
			stats.inherited = stats.inherited + 1
			return
		end
	end

	local bosses = layer.table[instance]
	if not bosses then
		bosses = {}
		layer.table[instance] = bosses
		layer.order[instance] = {}
		layer.instances[#layer.instances + 1] = instance
	end

	local items = bosses[boss]
	if not items then
		items = {}
		bosses[boss] = items
		layer.order[instance][#layer.order[instance] + 1] = boss
	end

	if items[itemID] then
		stats.duplicates = stats.duplicates + 1
		return
	end

	items[itemID] = true
	items[#items + 1] = itemID
	stats.items = stats.items + 1

	if advisory then stats.advisoryKept = stats.advisoryKept + 1 end

	-- Set for advisory pages too, so an item nothing places is claimed by the first list that
	-- names it and not by all of them. Idol of the Wild has no source in AtlasLoot at all and
	-- was coming out five times, once per druid list that recommends it.
	knownIds[itemID] = true
end

local function Collect(layer, db, advisoryPass)
	for _, source in ipairs(db.sources) do
		if IsAdvisoryModule(source.module) ~= (advisoryPass and true or false) then
			-- not this pass's turn
		elseif not ModuleBelongsToLayer(source.module, layer) then
			stats.skippedModule = stats.skippedModule + 1
		else
			-- IgnoreAsSource and ExtraList are deliberately not honoured here. They were, at
			-- first, on the reading that AtlasLoot knows which of its own pages are not where
			-- an item comes from. That is not what the flags mean: they keep a page out of
			-- AtlasLoot's source tooltip, mostly because the same item is listed elsewhere
			-- too. Trusting them threw away 1348 items - the Trash page of nearly every
			-- instance, the pattern drops of Sunwell and Black Temple, the class books of
			-- Ahn'Qiraj, the Dire Maul tribute run, the Zul'Aman timed chest.
			local instance = source.instance
			if instance and instance ~= "" then
				local boss = BossLabel(source)
				local idFields = ID_FIELDS[source.tableType or ""] or DEFAULT_ID_FIELDS
				stats.kept = stats.kept + 1

				for _, row in ipairs(source.rows) do
					local fields = row ~= "nil" and ParseRow(row)
					if not fields then
						stats.skippedRow = stats.skippedRow + 1
					else
						for _, field in ipairs(idFields) do
							local value = fields[field]

							if value and MULTI_FIELDS[field] then
								for part in value:gmatch("[^+]+") do
									local id = tonumber(part)
									if id and id > 0 and id < MAX_ITEM_ID then
										Add(layer, instance, boss, id, advisoryPass)
									end
								end
							else
								local id = tonumber(value)
								if id and id > 0 and id < MAX_ITEM_ID then
									Add(layer, instance, boss, id, advisoryPass)
								end
							end
						end
					end
				end
			end
		end
	end
end

assert(#arg > 0, "give me the dumps, oldest expansion first")
assert(#arg <= #LAYERS, "more dumps than known expansions")

local dumps = {}
for i = 1, #arg do
	layers[i] = { table = {}, order = {}, instances = {},
		name = LAYERS[i].name, minToc = LAYERS[i].minToc }
	dumps[i] = LoadDump(arg[i])
end

-- Real loot pages first, all of them, so that by the time the best in slot lists are read
-- every item that has a place to come from already has one.
for i = 1, #arg do Collect(layers[i], dumps[i], false) end
for i = 1, #arg do Collect(layers[i], dumps[i], true) end

-- *** Writing ***

local out = {}
local function W(fmt, ...)
	out[#out + 1] = select("#", ...) > 0 and string.format(fmt, ...) or fmt
end

local function WriteTable(layer, indent)
	table.sort(layer.instances)

	for _, instance in ipairs(layer.instances) do
		local bosses = layer.order[instance]
		table.sort(bosses)

		W("%s[%q] = {", indent, instance)
		for _, boss in ipairs(bosses) do
			local items = layer.table[instance][boss]
			local ids = {}
			for i = 1, #items do ids[i] = tostring(items[i]) end

			-- wrapped, so the file can be read and diffed
			local lines = {}
			for i = 1, #ids, 12 do
				lines[#lines + 1] = table.concat(ids, ", ", i, math.min(i + 11, #ids))
			end
			W("%s\t[%q] = { %s },", indent, boss, table.concat(lines, ",\n" .. indent .. "\t\t"))
		end
		W("%s},", indent)
	end
end

W("-- Generated by tools/GenerateLootTable.lua - do not edit by hand.")
W("--")
W("-- Source: AtlasLoot Classic, read out of a running client by tools/AltoholicLootExtract.")
W("-- It replaces the handful of sections that used to live in Loots.lua and the three")
W("-- LibPeriodicTable sets that were read out of DataStore_Inventory's library folder. Those")
W("-- sets were unmaintained, missing whole drops - Idol of the Claw among them - and, being a")
W("-- third party library, could be replaced at runtime by any other addon shipping a newer")
W("-- copy, taking any correction with them.")
W("--")
W("-- The base table is Classic Era. Every later expansion is a block of its own holding only")
W("-- what it adds, merged in at load time and only on a client that has it.")
W("--")
W("-- Leaving that to the Existence filter at runtime does not work: the client's static item")
W("-- database answers for a good many ids the server will never resolve, so an Era client kept")
W("-- Burning Crusade entries and showed them as \"Unknown #12345\" for ever.")
W("")
W("local addonName = ...")
W("local addon = _G[addonName]")
W("")
W("addon.LootTable = {")
WriteTable(layers[1], "\t")
W("}")

for i = 2, #layers do
	local layer = layers[i]
	local count = 0
	for _, bosses in pairs(layer.table) do
		for _, items in pairs(bosses) do count = count + #items end
	end

	W("")
	W("-- *** %s ***", layer.name)
	W("-- %d items this expansion adds, over %d headings.", count, #layer.instances)
	W("if select(4, GetBuildInfo()) >= %d then", layer.minToc)
	W("\tlocal added = {")
	WriteTable(layer, "\t\t")
	W("\t}")
	W("")
	W("\tfor instance, bosses in pairs(added) do")
	W("\t\tlocal known = addon.LootTable[instance]")
	W("\t\tif not known then")
	W("\t\t\taddon.LootTable[instance] = bosses")
	W("\t\telse")
	W("\t\t\tfor boss, items in pairs(bosses) do")
	W("\t\t\t\tlocal list = known[boss]")
	W("\t\t\t\tif not list then")
	W("\t\t\t\t\tknown[boss] = items")
	W("\t\t\t\telse")
	W("\t\t\t\t\t-- an encounter this expansion added drops to, on top of what it already had")
	W("\t\t\t\t\tfor _, itemID in ipairs(items) do list[#list + 1] = itemID end")
	W("\t\t\t\tend")
	W("\t\t\tend")
	W("\t\tend")
	W("\tend")
	W("end")
end

W("")

io.write(table.concat(out, "\n"))

local report = { string.format([[
pages read             %6d
items written          %6d
same item, same page   %6d  (collapsed)
already in an earlier
   expansion           %6d  (left there)
pages of a later
   expansion           %6d  (dropped from that layer)
listed by a best in
   slot page only      %6d  (kept)
placed elsewhere, so
   not taken from one  %6d  (dropped)
rows that held no item %6d

layers:
]], stats.kept, stats.items, stats.duplicates, stats.inherited,
	stats.skippedModule, stats.advisoryKept, stats.advisoryDropped, stats.skippedRow) }

for i = 1, #layers do
	local layer = layers[i]
	local count = 0
	for _, bosses in pairs(layer.table) do
		for _, items in pairs(bosses) do count = count + #items end
	end
	report[#report + 1] = string.format("   %-24s %6d items over %4d headings\n",
		layer.name, count, #layer.instances)
end

io.stderr:write(table.concat(report))

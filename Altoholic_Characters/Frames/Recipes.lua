local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local L = AddonFactory:GetLocale(addonName)
local LCI = LibStub("LibCraftInfo-1.0")

local recipeIsSpell = (LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_BURNING_CRUSADE)
local ITEM_CLASS_ARMOR = LE_ITEM_CLASS_ARMOR or Enum.ItemClass.Armor
local ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON or Enum.ItemClass.Weapon

local SKILL_ANY = 0
local SKILL_ORANGE = 1
local SKILL_YELLOW = 2
local SKILL_GREEN = 3
local SKILL_GREY = 4

local RecipeColors = { 
	[SKILL_GREY] = colors.recipeGrey,
	[SKILL_GREEN] = colors.recipeGreen, 
	[SKILL_YELLOW] = colors.yellow, 
	[SKILL_ORANGE] = colors.recipeOrange, 
}
local RecipeColorNames = { 
	[SKILL_GREY] = L["COLOR_GREY"],
	[SKILL_GREEN] = L["COLOR_GREEN"], 
	[SKILL_YELLOW] = L["COLOR_YELLOW"], 
	[SKILL_ORANGE] = L["COLOR_ORANGE"], 
}

local currentProfession
local mainCategory
local currentColor = SKILL_ANY
local currentSlots = ALL_INVENTORY_SLOTS
local currentSearch = ""

-- *** Utility functions ***
local function IsEnchanting(profession)
	return (profession == GetSpellInfo(7411))
end

local function SetStatus(character, professionName, mainCategory, numRecipes)
	local profession = DataStore:GetProfession(character, professionName)
	local allCategories = (mainCategory == 0)
	
	local text = ""
	
	if not allCategories then
		local categoryName = DataStore:GetRecipeCategoryInfo(profession, mainCategory)
		text = format("%s / %s", professionName, categoryName)
	else
		text = professionName		-- full list, just display "Tailoring"
	end

	local status = format("%s|r / %s (%d %s)", DataStore:GetColoredCharacterName(character), text, numRecipes, TRADESKILL_SERVICE_LEARN)
	AltoholicTabCharacters.Status:SetText(status)
end

local function RecipePassesColorFilter(color)
	-- the recipe is accounted for if we want any color, or if it matches a specific one
	return ((currentColor == SKILL_ANY) or (currentColor == color))
end

-- Get the item crafted by a recipe, or nil if it crafts none (enchants, ..)
local function GetCraftedItemID(recipeID)
	if not recipeID then return end		-- on a data line, recipeID is numeric

	-- Past vanilla, recipes are stored as a spell id, and only the scan knows the crafted item.
	if recipeIsSpell then
		local _, itemID = DataStore:GetCraftResultItem(recipeID)		-- maxMade comes first
		return itemID
	end

	-- In vanilla, recipes are stored as the id of the item they craft, except for enchanting,
	-- where the id is the enchant's spell id, and would resolve to an unrelated item.
	if not IsEnchanting(currentProfession) then
		return C_Item.GetItemInfoInstant(recipeID)
	end
end

local function RecipePassesSlotFilter(recipeID)
	if currentSlots == ALL_INVENTORY_SLOTS then return true end

	local itemID = GetCraftedItemID(recipeID)

	-- enchants, like socket bracer, craft no item at all
	if not itemID then return (currentSlots == NONEQUIPSLOT) end

	-- GetItemInfoInstant does not depend on the item being cached, unlike GetItemInfo
	local _, _, _, itemEquipLoc, _, classID = C_Item.GetItemInfoInstant(itemID)

	if classID == ITEM_CLASS_ARMOR or classID == ITEM_CLASS_WEAPON then
		return (itemEquipLoc and strlen(itemEquipLoc) > 0 and currentSlots == itemEquipLoc) and true or false
	end

	-- not a weapon or armor ? then it is a generic "Created item"
	return (currentSlots == NONEQUIPSLOT)
end

-- An item is only named once the client has cached it, which may not be the case for an alt's
-- recipes. Track those, the search would silently hide them until their name is known.
local isNameMissing
local isWaitingForItemNames

local function NameMatches(name)
	return (name and string.find(strlower(name), currentSearch, 1, true)) and true or false
end

local function RecipePassesSearchFilter(recipeID)
	-- no search filter ? ok
	if currentSearch == "" then return true end
	if not recipeID then return end

	-- Match on the name of the crafted item, which is the one being displayed ..
	local itemID = GetCraftedItemID(recipeID)

	if itemID then
		local name = C_Item.GetItemInfo(itemID)		-- this also queries the server if need be

		if not name then
			isNameMissing = true
			return
		end

		return NameMatches(name)
	end

	-- .. or on the spell name for the recipes that craft no item, like enchants.
	--
	-- The few enchanting entries that do create something (rods, oils) are reached through the
	-- craft library, which answers with the item that this very spell produces. This used to
	-- read recipeID itself as an item id, on the grounds that those entries might be stored
	-- that way: every spell id is also a valid item id for some unrelated item, so searching
	-- "clo" returned Enchant Bracer rows because the item carrying the bracer enchant's number
	-- happened to be a cloak.
	local spellName = GetSpellInfo(recipeID)

	local craftedID = LCI:GetCraftResultItem(recipeID)
	local itemName = craftedID and craftedID > 0 and C_Item.GetItemInfo(craftedID) or nil

	if not spellName and not itemName then
		isNameMissing = true
		return
	end

	return NameMatches(spellName) or NameMatches(itemName)
end

local function GetRecipeList(character, professionName, mainCategory)
	local list = {}
	local profession = DataStore:GetProfession(character, professionName)

	isNameMissing = nil

	DataStore:IterateRecipes(profession, mainCategory, 0, function(color, recipeID, index)
		if RecipePassesColorFilter(color) and RecipePassesSlotFilter(recipeID) and RecipePassesSearchFilter(recipeID) then
			table.insert(list, index)
		end
	end)

	return list
end

addon:Controller("AltoholicUI.Recipes", {
	SetCurrentProfession = function(frame, prof) currentProfession = prof end,
	GetCurrentProfession = function(frame) return currentProfession end,
	SetMainCategory = function(frame, cat) mainCategory = cat end,
	GetMainCategory = function(frame) return mainCategory end,
	SetCurrentSlots = function(frame, slot) currentSlots = slot end,
	GetCurrentSlots = function(frame) return currentSlots end,
	SetCurrentColor = function(frame, color) currentColor = color end,
	GetCurrentColor = function(frame) return currentColor end,
	GetRecipeColorName = function(frame, index) return format("%s%s", RecipeColors[index], RecipeColorNames[index]) end,
	GetCraftedItemID = function(frame, recipeID) return GetCraftedItemID(recipeID) end,

	-- Redo the search when the names missing from the item cache arrive
	WaitForItemNames = function(frame, isWaiting)
		if isWaiting == isWaitingForItemNames then return end		-- already in the right state ?

		isWaitingForItemNames = isWaiting

		-- tag it, the scope is the whole add-on, and this event is of interest to others
		if not isWaiting then
			addon:StopListeningTo("GET_ITEM_INFO_RECEIVED", "Recipes")
			return
		end

		addon:ListenTo("GET_ITEM_INFO_RECEIVED", function()
			-- stop as soon as the recipes are not being looked at anymore
			if not frame:IsVisible() then
				frame:WaitForItemNames(nil)
				return
			end

			frame:Update()
		end, "Recipes")
	end,

	Update = function(frame)
		local character = addon.Tabs.Characters:GetAltKey()
		local recipeList = GetRecipeList(character, currentProfession, mainCategory)

		frame:WaitForItemNames(isNameMissing)

		local isEnchanting = IsEnchanting(currentProfession)
		SetStatus(character, currentProfession, mainCategory, #recipeList)
	
		local scrollFrame = frame.ScrollFrame
		local numRows = scrollFrame.numRows
		local offset = scrollFrame:GetOffset()

		for rowIndex = 1, numRows do
			local rowFrame = scrollFrame:GetRow(rowIndex)
			local line = rowIndex + offset
			
			if line <= #recipeList then	-- if the line is visible
				local color, recipeID, icon = DataStore:GetRecipeInfo_NonRetail(character, currentProfession, recipeList[line])
				
				rowFrame:Update(currentProfession, recipeID, RecipeColors[color])
				rowFrame:Show()
			else
				rowFrame:Hide()
			end
		end

		scrollFrame:Update(#recipeList)
		frame:Show()
	end,
	Link_OnClick = function(frame, button)
		if button ~= "LeftButton" then return end
		
		local character = addon.Tabs.Characters:GetAltKey()
		if not character then return end
		
		if addon.Tabs.Characters:GetRealm() ~= GetRealmName() then
			addon:Print(L["Cannot link another realm's tradeskill"])
			return
		end

		local profession = DataStore:GetProfession(character, currentProfession)
		local link = profession.FullLink

		if not link then
			addon:Print(L["Invalid tradeskill link"])
			return
		end
		
		local chat = ChatEdit_GetLastActiveWindow()
		if chat:IsShown() then
			chat:Insert(format("%s: %s", addon.Tabs.Characters:GetAlt(), link))
		end
	end,
	OnSearchTextChanged = function(frame, self)
		-- lower case it, recipe names are matched in lower case too
		currentSearch = strlower(self:GetText())
		frame:Update()
	end,
})

local addonName = "Altoholic"
local addon = _G[addonName]
local L = AddonFactory:GetLocale(addonName)
local recipeIsSpell = (LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_BURNING_CRUSADE)

-- *** Utility functions ***
local function IsEnchanting(profession)
	return (profession == GetSpellInfo(7411))
end

addon:Controller("AltoholicUI.RecipeRow", {
	Update = function(frame, profession, recipeID, color)
		local maxMade, craftedItemID, itemName, itemLink, itemRarity, spellLink, spellIcon
		maxMade = 0

		-- ** set the crafted item **
		if recipeIsSpell then
			maxMade, craftedItemID = DataStore:GetCraftResultItem(recipeID)
		else
			-- Handle pre-Lich King crafting database
			if not IsEnchanting(profession) then
				craftedItemID = C_Item.GetItemInfoInstant(recipeID)
			end
		end

		if craftedItemID then
			frame.CraftedItem:SetIcon(C_Item.GetItemIconByID(craftedItemID))
			frame.CraftedItem.itemID = craftedItemID
			itemName, itemLink, itemRarity = C_Item.GetItemInfo(craftedItemID)
			
			frame.CraftedItem.Icon:SetVertexColor(1, 1, 1)
			if itemRarity then
				frame.CraftedItem:SetRarity(itemRarity)
			end

			if maxMade > 1 then
				frame.CraftedItem.Count:SetText(maxMade)
				frame.CraftedItem.Count:Show()
			else
				frame.CraftedItem.Count:Hide()
			end
			frame.CraftedItem:Show()
		else
			--frame.CraftedItem:Hide() -- testing showing item results for spells with no result item
			_, _, spellIcon = GetSpellInfo(recipeID)
			frame.CraftedItem:SetIcon(spellIcon)
			frame.CraftedItem.itemID = nil

			frame.CraftedItem.Icon:SetVertexColor(1, 1, 1)
			frame.CraftedItem:SetRarity(1)
			frame.CraftedItem:Show()
		end

		-- ** set the recipe link **
		if recipeID then
			local recipeText, spellInfo
			local link = addon:GetRecipeLink(recipeID, profession, nil)
			if recipeIsSpell or IsEnchanting(profession) then
				spellInfo = C_Spell.GetSpellInfo(recipeID)
				recipeText = spellInfo and spellInfo.name or L["N/A"]
			else
				recipeText = itemName or L["N/A"]
			end

			-- Set the resulting item color IF it makes an item (Enchanting mostly?)
			if itemName then
				local _, _, _, hexColor = C_Item.GetItemQualityColor(itemRarity)
				recipeText = format("|c%s%s|r", hexColor, recipeText)
			end

			frame.RecipeLink.Text:SetText(recipeText)
			if spellInfo then
				frame.RecipeLink.link = link
			end
		else
			-- this should NEVER happen, like NEVER-EVER-ER !!
			frame.RecipeLink.Text:SetText(L["N/A"])
			frame.RecipeLink.link = nil
		end

		-- ** set the reagents **
		local reagents = DataStore:GetCraftReagents(recipeID)		-- reagents = "2996,2|2318,1|2320,1"
		local index = 1

		if reagents then
			for reagent in reagents:gmatch("([^|]+)") do
				local reagentIcon = frame[format("Reagent%d", index)]
				local reagentID, reagentCount = strsplit(",", reagent)
				reagentID = tonumber(reagentID)

				if reagentID then
					reagentCount = tonumber(reagentCount)

					reagentIcon.itemID = reagentID
					reagentIcon:SetIcon(C_Item.GetItemIconByID(reagentID))
					reagentIcon.Count:SetText(reagentCount)
					reagentIcon.Count:Show()

					reagentIcon:Show()
					index = index + 1
				else
					reagentIcon:Hide()
				end
			end
		end

		-- hide unused reagent icons
		while index <= 8 do
			frame[format("Reagent%d", index)]:Hide()
			index = index + 1
		end

		frame:Show()
	end,
	
	Link_OnEnter = function(frame)

		local link = frame.RecipeLink.link
		if not link then return end
		
		local tt = AltoTooltip
		
		tt:ClearLines()
		tt:SetOwner(frame.RecipeLink, "ANCHOR_RIGHT")
		tt:SetHyperlink(link)
		tt:AddLine(" ", 1, 1, 1)

		tt:Show()
		
	end,
	
	RecipeLink_OnClick = function(frame, button)
		if button ~= "LeftButton" or not IsShiftKeyDown() then return end

		local link = frame.RecipeLink.link
		if not link then return end

		local chat = ChatEdit_GetLastActiveWindow()
		-- addon:Print(format(("%s"), link)) -- debug
		if chat:IsShown() then
			chat:Insert(link)
		end
	end,
})

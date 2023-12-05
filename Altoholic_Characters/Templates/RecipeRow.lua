local addonName = "Altoholic"
local addon = _G[addonName]
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

addon:Controller("AltoholicUI.RecipeRow", {
	Update = function(frame, profession, recipeID, color)

		-- ** set the crafted item **
		local craftedItemID, maxMade = DataStore:GetCraftResultItem(recipeID)
		local itemName, itemLink, itemRarity, spellLink, spellIcon

		if craftedItemID then
			frame.CraftedItem:SetIcon(GetItemIcon(craftedItemID))
			frame.CraftedItem.itemID = craftedItemID
			itemName, itemLink, itemRarity = GetItemInfo(craftedItemID)
			
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
			local link = addon:GetRecipeLink(recipeID, profession, nil)
			local recipeText =  GetSpellInfo(recipeID) or L["N/A"]

			-- Set the resulting item color IF it makes an item (Enchanting mostly?)
			if itemName then
				local _, _, _, hexColor = GetItemQualityColor(itemRarity)
				recipeText = format("|c%s%s|r", hexColor, recipeText)
			end

			frame.RecipeLink.Text:SetText(recipeText)
			frame.RecipeLink.link = link
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
					reagentIcon:SetIcon(GetItemIcon(reagentID))
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

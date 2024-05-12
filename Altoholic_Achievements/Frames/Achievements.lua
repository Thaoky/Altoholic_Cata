local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

addon:Controller("AltoholicUI.Achievements", { "AltoholicUI.AchievementsLists", function(Lists)
	
	local currentCategoryID

	return {
		OnBind = function(frame)
			Lists.Initialize()
		end,
		SetCategory = function(frame, categoryID)
			-- for debug only
			-- print(categoryID)
			currentCategoryID = categoryID
		end,
		Update = function(frame)
			local scrollFrame = frame.ScrollFrame
			local numRows = scrollFrame.numRows
			local offset = scrollFrame:GetOffset()
			
			local categorySize = Lists.GetCategorySize(currentCategoryID)
			local realm, account = frame:GetParent():GetRealm()
			
			AltoholicTabAchievements.Status:SetText(format("%s: %s%s", ACHIEVEMENTS, colors.green, categorySize ))
			
			for rowIndex = 1, numRows do
				local rowFrame = scrollFrame:GetRow(rowIndex)
				local line = rowIndex + offset
				
				if line <= categorySize then	-- if the line is visible
					local allianceID, hordeID = Lists.GetAchievementFactionInfo(currentCategoryID, line)
					
					rowFrame:Update(account, realm, allianceID, hordeID)
					rowFrame:Show()
				else
					rowFrame:Hide()
				end
			end

			scrollFrame:Update(categorySize)
			frame:Show()
		end,
	}
end})

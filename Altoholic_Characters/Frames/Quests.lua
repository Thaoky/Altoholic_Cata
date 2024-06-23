local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local L = DataStore:GetLocale(addonName)

local currentCategoryID

local function SetStatus(character, category, numQuests)
	local allCategories = (category == 0)
	
	local text = ""
	
	if allCategories then
		text = format("%s / %s", QUEST_LOG, ALL)
	else
		local headers = DataStore:GetQuestHeaders(character)
		text = format("%s / %s", QUEST_LOG, headers[category])
	end

	local status = format("%s|r / %s (%s%d|r)", DataStore:GetColoredCharacterName(character), text, colors.green, numQuests)

	AltoholicTabCharacters.Status:SetText(status)
end

local function GetQuestList(character, category)
	local list = {}
	
	DataStore:IterateQuests(character, category, function(questIndex) 
		table.insert(list, questIndex)
	end)
	
	return list
end

addon:Controller("AltoholicUI.QuestLog", {
	SetCategory = function(frame, categoryID) currentCategoryID = categoryID end,
	GetCategory = function(frame) return currentCategoryID end,
	
	Update = function(frame)
		local character = addon.Tabs.Characters:GetAltKey()
		local questList = GetQuestList(character, currentCategoryID)
		
		SetStatus(character, currentCategoryID, #questList)

		local scrollFrame = frame.ScrollFrame
		local numRows = scrollFrame.numRows
		local offset = scrollFrame:GetOffset()
		
		for rowIndex = 1, numRows do
			local rowFrame = scrollFrame:GetRow(rowIndex)
			local line = rowIndex + offset
			
			rowFrame:Hide()
			
			if line <= #questList then	-- if the line is visible
				local lineID = questList[line]
				rowFrame:SetID(lineID)
				
				local questID = DataStore:GetQuestLogID(character, lineID)

				rowFrame:SetName(DataStore:GetQuestName(questID), DataStore:GetQuestLevel(questID))
				rowFrame:SetType(DataStore:GetQuestLogTag(character, lineID))
				rowFrame:SetRewards()
				rowFrame:SetInfo(
							DataStore:IsQuestCompleted(character, lineID), 
							DataStore:IsQuestDaily(questID), 
							DataStore:GetQuestGroupSize(questID), 
							DataStore:GetQuestLogMoney(character, lineID))
				rowFrame:Show()
			end
		end

		scrollFrame:Update(#questList)
		frame:Show()
	end,
})

local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local currentTalentGroup
local currentClass		-- ex: "MAGE"
local currentTreeName	-- ex: "Fire"
local currentTreeID
local currentGuildKey
local currentGuildMember	-- guild member currently displayed in the right pane
local currentGuildMemberTalentGroup = 1
local rightTreeKey		-- character key to use when drawing the rightmost tree

local isTreeTalents = LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC or LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE
local isRowTalents = LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_MISTS_OF_PANDARIA

addon:Controller("AltoholicUI.TalentIcon", {
	Icon_OnEnter = function(frame)
		if isTreeTalents then
			local treeName = DataStore:GetTreeNameByID(currentClass, frame:GetID())
			if treeName then
				AltoTooltip:ClearLines()
				AltoTooltip:SetOwner(frame, "ANCHOR_RIGHT")
				AltoTooltip:AddLine(treeName,1,1,1)
				AltoTooltip:Show()
			end
		end
	end,
	Icon_OnClick = function(frame, button)
		if isTreeTalents then
			currentTreeID = frame:GetID()					-- set the current tree
			
			local group = frame:GetParent():GetID()	-- which group of icons did we click ? 1 to 4
			local isPlayer = (group < 3)					-- 1 or 2 = player, 3 or 4 = guild
			local isPrimary = (group % 2 == 1)			-- 1 or 3 = primary, 2 or 4 = secondary

			if isPlayer then
				if isPrimary then
					currentTalentGroup = 1
				else
					currentTalentGroup = 2
				end
			else
				if isPrimary then
					currentGuildMemberTalentGroup = 1
				else
					currentGuildMemberTalentGroup = 2
				end
			end
			
			frame:GetParent():GetParent():Update()
		end
	end,
	
	StopAutoCast = function(frame)
		-- AutoCastShine_AutoCastStop(frame.Shine)
	end,

	StartAutoCast = function(frame, group, id)
		-- if an id is specified, start auto cast shine on this icon
		-- AutoCastShine_AutoCastStart(frame.Shine _G[ format("%s_Icons%d_SpecIcon%dShine", parent, group, id) ] )
	end,
	
})

addon:Controller("AltoholicUI.TalentPanel", {
	OnBind = function(frame)
		frame:HideChildren()

		if isTreeTalents then
			frame.PlayerSpec:Show()
			frame.GuildSpec:Show()
			frame.Icons1:Show()
			frame.Icons3:Show()
		elseif isRowTalents then
			frame.CharacterSpec:Show()
		end
		-- local function OnPlayerTalentUpdate()
			-- if frame:IsVisible() then
				-- frame:Update()
			-- end
		-- end	

		-- addon:RegisterEvent("PLAYER_TALENT_UPDATE", OnPlayerTalentUpdate)
		-- addon:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", OnPlayerTalentUpdate)
	end,
	DrawClassIcons = function(frame, iconGroup, class, character, guildMember)
		local text = frame[format("Icons%d", iconGroup)].Text
		local icon1 = frame[format("Icons%d", iconGroup)].SpecIcon1

		local isPlayer = (iconGroup < 3)					-- 1 or 2 = player, 3 or 4 = guild
		-- local isPrimary = (iconGroup % 2 == 1)			-- 1 or 3 = primary, 2 or 4 = secondary
		
		if isPlayer then
			text:SetJustifyH("LEFT")
			icon1:SetPoint("TOPLEFT", 10, -15)
		else
			text:SetJustifyH("RIGHT")
			icon1:SetPoint("TOPLEFT", 90, -15)
		end
		
		-- if isPrimary then
			text:SetText(TALENT_SPEC_PRIMARY)
		-- else
			-- text:SetText(TALENT_SPEC_SECONDARY)
		-- end
		
		local index = 1
		for tree in DataStore:GetClassTrees(class) do						-- draw spec icons
			local itemButton = frame[format("Icons%d", iconGroup)][format("SpecIcon%d", index)]
			local itemCount = itemButton.Count
			local icon = DataStore:GetTreeInfo(class, tree)
			
			itemButton.Icon:SetTexture(icon)
			
			local count = 0
			if character then
				count = DataStore:GetNumPointsSpent(character, tree)
			elseif guildMember then
				count = DataStore:GetGuildMemberNumPointsSpent(currentGuildKey, guildMember, tree)
			end
			itemCount:SetText(format("%s%d", colors.white, count))
			itemCount:Show()
			itemButton:Show()
			
			if not isPlayer then
				itemButton.Icon:SetDesaturated((character or guildMember) and 0 or 1)
			end
			
			index = index + 1
		end
	end,
	HideChildren = function (frame)
		-- Loop child frames and hide each (not using parent keys)
		local children = {frame:GetChildren()}
		for i, child in ipairs(children) do
			child:Hide()
		end
	end,
	Update = function(frame)
		frame:Hide()

		-- Get character information (or bail)
		local character = addon.Tabs.Characters:GetAltKey()
		if not character then return end
		
		AltoholicTabCharacters.Status:SetText(format("%s|r / %s", DataStore:GetColoredCharacterName(character), TALENTS))
		
		_, currentClass = DataStore:GetCharacterClass(character)
		--if not DataStore:IsClassKnown(currentClass) then return end
		
		local level = DataStore:GetCharacterLevel(character)
		--if not level or level < 10 then return end

		-- What kind of talent structure is being used
		if isTreeTalents then
			-- Talent Tree version
			currentTreeName = DataStore:GetTreeNameByID(currentClass, currentTreeID or 1)

			-- background
			frame.PlayerSpec:DrawBackground(currentClass, currentTreeName)
			frame.GuildSpec:DrawBackground(currentClass, currentTreeName, (not currentGuildMember and not rightTreeKey))
			-- class icons
			frame:DrawClassIcons(1, currentClass, character)
			frame:DrawClassIcons(3, currentClass, rightTreeKey, currentGuildMember)
			-- trees
			frame.PlayerSpec:DrawTree(currentClass, currentTreeName, character)
			--frame.GuildSpec:DrawTree(currentClass, currentTreeName, nil, currentGuildMember)
			frame.GuildSpec:DrawTree(currentClass, currentTreeName, rightTreeKey, currentGuildMember)

		elseif isRowTalents then
			local classTalents = DataStore:GetClassTalentsReference(currentClass)
			local characterTalents = DataStore:GetTalents(character)
			local talentLevels = CLASS_TALENT_LEVELS[class] or CLASS_TALENT_LEVELS["DEFAULT"]
			for tier = 1, MAX_NUM_TALENT_TIERS do
				frame.CharacterSpec.Rows["TalentRow"..tier].level:SetText(talentLevels[tier])
				for column = 1, 3 do
					-- Unselect and turn gray the talent
					frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].knownSelection:Hide()
					frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].icon:SetDesaturated(false)

					-- Get the current talentID, name, texture, and spellID (for mouseover description)
					local talentID = classTalents[tier][column]
					local _, name, texture, _, _, spellID = GetTalentInfoByID(talentID)

					if spellID then
						frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].icon:SetTexture(texture)
						frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].name:SetText(name)
						frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].spellID = spellID
						frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].talentID = talentID
					end
					if characterTalents[tier] == talentID then
						frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].knownSelection:Show()
					else
						frame.CharacterSpec.Rows["TalentRow"..tier]["talent"..column].icon:SetDesaturated(true)
					end
				end
			end

		end
		frame:Show()
	end,
})

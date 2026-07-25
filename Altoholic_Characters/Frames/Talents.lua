local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local currentClass		-- ex: "MAGE"
local currentTreeName	-- ex: "Fire"
local currentTreeID

local isTreeTalents = LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC or LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE
local isRowTalents = LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_MISTS_OF_PANDARIA

-- Both panes always show the same tree, the left one for the primary talent group, the right one for the secondary (dual spec)
local PRIMARY_SPEC_GROUP = 1
local SECONDARY_SPEC_GROUP = 2

local SPEC_GROUP_LABELS = {
	[PRIMARY_SPEC_GROUP] = TALENT_SPEC_PRIMARY or "Primary Talents",
	[SECONDARY_SPEC_GROUP] = TALENT_SPEC_SECONDARY or "Secondary Talents",
}

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
			currentTreeID = frame:GetID()					-- set the current tree, both panes display it

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
			frame.PrimarySpec:Show()
			frame.SecondarySpec:Show()
			frame.Icons1:Show()
			frame.Icons2:Show()
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
	DrawClassIcons = function(frame, class, character, specGroup, isKnown)
		-- One row of icons per talent group : group 1 above the left pane, group 2 above the right one.
		-- isKnown : the character has data saved for this talent group
		local iconsFrame = frame[format("Icons%d", specGroup)]
		local text = iconsFrame.Text
		local icon1 = iconsFrame.SpecIcon1

		if specGroup == PRIMARY_SPEC_GROUP then
			text:SetJustifyH("LEFT")
			icon1:SetPoint("TOPLEFT", 10, -15)
		else
			text:SetJustifyH("RIGHT")
			icon1:SetPoint("TOPLEFT", 90, -15)
		end

		text:SetText(SPEC_GROUP_LABELS[specGroup])

		local index = 1
		for tree in DataStore:GetClassTrees(class) do						-- draw spec icons
			local itemButton = iconsFrame[format("SpecIcon%d", index)]
			local itemCount = itemButton.Count
			local icon = DataStore:GetTreeInfo(class, tree)

			itemButton.Icon:SetTexture(icon)
			itemButton.Icon:SetDesaturated(not isKnown)

			local count = isKnown and DataStore:GetNumPointsSpent(character, tree, specGroup) or 0

			itemCount:SetText(format("%s%d", colors.white, count))
			itemCount:Show()
			itemButton:Show()

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
		if not DataStore:IsClassKnown(currentClass) then return end		-- no reference data for that class yet

		local level = DataStore:GetCharacterLevel(character)
		--if not level or level < 10 then return end

		-- What kind of talent structure is being used
		if isTreeTalents then
			-- Talent Tree version
			currentTreeName = DataStore:GetTreeNameByID(currentClass, currentTreeID or 1)
			if not currentTreeName then return end		-- the class reference is not known yet, nothing to draw

			-- A character without dual talent specialization (or not scanned since it was bought) has no secondary group
			local hasPrimary = DataStore:HasSpecGroup(character, PRIMARY_SPEC_GROUP)
			local hasSecondary = DataStore:HasSpecGroup(character, SECONDARY_SPEC_GROUP)

			-- background
			frame.PrimarySpec:DrawBackground(currentClass, currentTreeName, not hasPrimary)
			frame.SecondarySpec:DrawBackground(currentClass, currentTreeName, not hasSecondary)
			-- class icons
			frame:DrawClassIcons(currentClass, character, PRIMARY_SPEC_GROUP, hasPrimary)
			frame:DrawClassIcons(currentClass, character, SECONDARY_SPEC_GROUP, hasSecondary)
			-- trees
			frame.PrimarySpec:DrawTree(currentClass, currentTreeName, hasPrimary and character or nil, PRIMARY_SPEC_GROUP)
			frame.SecondarySpec:DrawTree(currentClass, currentTreeName, hasSecondary and character or nil, SECONDARY_SPEC_GROUP)

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

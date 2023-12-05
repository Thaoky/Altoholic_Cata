local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors
local icons = addon.Icons

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local TEXTURE_PATH = "Interface\\Icons\\"
local LOCAL_TEXTURE_PATH = "Interface\\Addons\\Altoholic_Grids\\Textures\\"

local function Texture(texture)
	return format("%s%s", TEXTURE_PATH, texture)
end

local function LocatTexture(texture)
	return format("%s%s.tga", LOCAL_TEXTURE_PATH, texture)
end

-- *** Reputations ***
local Factions = {
	-- Factions reference table, based on http://www.wowwiki.com/Factions
	{	-- [1]
		name = EXPANSION_NAME0,	-- "Classic"
		{	-- [1]
			name = FACTION_ALLIANCE,	-- 469
			{ name = DataStore:GetFactionName(69), icon = Texture("Achievement_Character_Nightelf_Female") },	-- "Darnassus"
			{ name = DataStore:GetFactionName(930), icon = Texture("Achievement_Character_Draenei_Male") },	--  name = "Exodar"
			{ name = DataStore:GetFactionName(54), icon = Texture("INV_Misc_Head_Gnome_02") },	-- "Gnomeregan"
			{ name = DataStore:GetFactionName(47), icon = Texture("Achievement_Character_Dwarf_Male") },		-- "Ironforge"
			{ name = DataStore:GetFactionName(72), icon = Texture("INV_Misc_Head_Human_01") },		-- "Stormwind"
		},
		{	-- [2]
			name = FACTION_HORDE,
			{ name = DataStore:GetFactionName(530), icon = Texture("Achievement_Character_Troll_Male") },		-- "Darkspear Trolls"
			{ name = DataStore:GetFactionName(76), icon = Texture("INV_Misc_Head_Orc_01") },		-- "Orgrimmar"
			{ name = DataStore:GetFactionName(81), icon = Texture("INV_Misc_Head_Tauren_01") },		-- "Thunder Bluff"
			{ name = DataStore:GetFactionName(68), icon = Texture("INV_Misc_Head_Undead_02") },		-- "Undercity"
			{ name = DataStore:GetFactionName(911), icon = Texture("Achievement_Character_Bloodelf_Male") },		-- "Silvermoon City"
		},
		{	-- [3]
			name = L["Alliance Forces"],	-- 891
			{ name = DataStore:GetFactionName(509), icon = Texture("inv_jewelry_talisman_05") },	--  name = "The League of Arathor" 
			{ name = DataStore:GetFactionName(890), icon = Texture("inv_banner_03") },	-- "Silverwing Sentinels" 
			{ name = DataStore:GetFactionName(730), icon = Texture("inv_jewelry_necklace_21") },		-- "Stormpike Guard"
		},
		{	-- [4]
			name = L["Horde Forces"],
			{ name = DataStore:GetFactionName(510), icon = Texture("inv_jewelry_talisman_05") },		-- "The Defilers" 
			{ name = DataStore:GetFactionName(889), icon = Texture("inv_banner_03") },	-- "Warsong Outriders" 
			{ name = DataStore:GetFactionName(729), icon = Texture("inv_jewelry_necklace_21") },		-- "Frostwolf Clan" 
		},
		{	-- [5]
			name = L["Steamwheedle Cartel"],
			{ name = DataStore:GetFactionName(21), icon = Texture("inv_helmet_66") },		-- "Booty Bay" 
			{ name = DataStore:GetFactionName(577), icon = Texture("inv_helmet_66") },		-- "Everlook" 
			{ name = DataStore:GetFactionName(369), icon = Texture("inv_helmet_66") },		-- "Gadgetzan" 
			{ name = DataStore:GetFactionName(470), icon = Texture("inv_helmet_66") },		-- "Ratchet" 
		},
		{	-- [6]
			name = OTHER,
			{ name = DataStore:GetFactionName(529), icon = Texture("INV_Jewelry_Talisman_07") },		-- "Argent Dawn" 
			{ name = DataStore:GetFactionName(87), icon = Texture("INV_Helmet_66") },		-- "Bloodsail Buccaneers" 
			{ name = DataStore:GetFactionName(910), icon = Texture("INV_Misc_Head_Dragon_Bronze") },		-- "Brood of Nozdormu" 
			{ name = DataStore:GetFactionName(609), icon = Texture("INV_Scarab_Gold") },		-- "Cenarion Circle" 
			{ name = DataStore:GetFactionName(909), icon = Texture("INV_Misc_Ticket_Darkmoon_01") },		-- "Darkmoon Faire" 
			{ name = DataStore:GetFactionName(92), icon = Texture("INV_Misc_Head_Centaur_01") },			-- "Gelkis Clan Centaur" 
			{ name = DataStore:GetFactionName(749), icon = Texture("inv_potion_83") },		-- "Hydraxian Waterlords" 
			{ name = DataStore:GetFactionName(93), icon = Texture("INV_Misc_Head_Centaur_01") },		-- "Magram Clan Centaur" 
			{ name = DataStore:GetFactionName(349), icon = Texture("INV_ThrowingKnife_04") },		-- "Ravenholdt" 
			{ name = DataStore:GetFactionName(809), icon = Texture("inv_misc_book_11") },		-- "Shen'dralar" 
			{ name = DataStore:GetFactionName(70), icon = Texture("INV_Misc_ArmorKit_03") },		-- "Syndicate" 
			{ name = DataStore:GetFactionName(59), icon = Texture("INV_Ingot_Thorium") },		-- "Thorium Brotherhood" 
			{ name = DataStore:GetFactionName(576), icon = Texture("inv_misc_horn_01") },		-- "Timbermaw Hold" 
			{ name = DataStore:GetFactionName(471), icon = Texture("INV_Misc_Head_Dwarf_01") },		-- "Wildhammer Clan" 
			{ name = DataStore:GetFactionName(922), icon = Texture("Achievement_Zone_Ghostlands") },		-- "Tranquillien" 
			{ name = DataStore:GetFactionName(589), icon = Texture("Ability_Mount_PinkTiger") },		-- "Wintersaber Trainers" 
			{ name = DataStore:GetFactionName(270), icon = Texture("INV_Bijou_Green") },		-- "Zandalar Tribe" 
		}
	},
	{	-- [2]
		name = EXPANSION_NAME1,	-- "The Burning Crusade"
		{	-- [1]
			name = C_Map.GetAreaInfo(676),	-- Outland
			{ name = DataStore:GetFactionName(1012), icon = LocatTexture("Achievement_Reputation_AshtongueDeathsworn") },	-- "Ashtongue Deathsworn" 
			{ name = DataStore:GetFactionName(942), icon = Texture("ability_racial_ultravision") },	-- "Cenarion Expedition" 
			{ name = DataStore:GetFactionName(933), icon = Texture("INV_Enchant_ShardPrismaticLarge") },		-- "The Consortium" 
			{ name = DataStore:GetFactionName(946), icon = Texture("Spell_Misc_HellifrePVPHonorHoldFavor") },	-- "Honor Hold" 
			{ name = DataStore:GetFactionName(978), icon = Texture("INV_Misc_Foot_Centaur") },		-- "Kurenai" 
			{ name = DataStore:GetFactionName(941), icon = LocatTexture("Achievement_Zone_Nagrand_01") },	-- "The Mag'har" 
			{ name = DataStore:GetFactionName(1015), icon = Texture("Ability_Mount_NetherdrakePurple") },		-- "Netherwing" 
			{ name = DataStore:GetFactionName(1038), icon = LocatTexture("Achievement_Reputation_Ogre") },		-- "Ogri'la" 
			{ name = DataStore:GetFactionName(970), icon = Texture("INV_Mushroom_11") },	-- "Sporeggar" 
			{ name = DataStore:GetFactionName(947), icon = Texture("Spell_Misc_HellifrePVPThrallmarFavor") },	-- "Thrallmar" 
		},
		{	-- [2]
			name = C_Map.GetAreaInfo(3703),	-- "Shattrath City"
			{ name = DataStore:GetFactionName(1011), icon = LocatTexture("Achievement_Zone_Terrokar") },		-- "Lower City" 
			{ name = DataStore:GetFactionName(1031), icon = Texture("Ability_Hunter_Pet_NetherRay") },		-- "Sha'tari Skyguard" 
			{ name = DataStore:GetFactionName(1077), icon = Texture("INV_Shield_48") },		-- "Shattered Sun Offensive" 
			{ name = DataStore:GetFactionName(932), icon = LocatTexture("Achievement_Character_Draenei_Female") },	-- "The Aldor" 
			{ name = DataStore:GetFactionName(934), icon = LocatTexture("Achievement_Character_Bloodelf_Female") },		-- "The Scryers" 
			{ name = DataStore:GetFactionName(935), icon = LocatTexture("Achievement_Zone_Netherstorm_01") },		-- "The Sha'tar" 
		},
		{	-- [3]
			name = OTHER,
			{ name = DataStore:GetFactionName(989), icon = LocatTexture("Achievement_Zone_HillsbradFoothills") },		-- "Keepers of Time" 
			{ name = DataStore:GetFactionName(990), icon = Texture("INV_Enchant_DustIllusion") },	-- "The Scale of the Sands" 
			{ name = DataStore:GetFactionName(967), icon = Texture("Spell_Holy_MindSooth") },		-- "The Violet Eye" 
		}
	},
	{	-- [3]
		name = EXPANSION_NAME2,	-- "Wrath of the Lich King"
		{	-- [1]
			name = GetRealZoneText(571),	-- Northrend
			{ name = DataStore:GetFactionName(1106), icon = Texture("Achievement_Reputation_ArgentCrusader") },		-- "Argent Crusade"
			{ name = DataStore:GetFactionName(1090), icon = Texture("Achievement_Reputation_KirinTor") },		-- "Kirin Tor" 
			{ name = DataStore:GetFactionName(1073), icon = Texture("Achievement_Reputation_Tuskarr") },	-- "The Kalu'ak" 
			{ name = DataStore:GetFactionName(1091), icon = Texture("Achievement_Reputation_WyrmrestTemple") },		-- "The Wyrmrest Accord" 
			{ name = DataStore:GetFactionName(1098), icon = Texture("Achievement_Reputation_KnightsoftheEbonBlade") },	-- "Knights of the Ebon Blade" 
			{ name = DataStore:GetFactionName(1119), icon = Texture("Achievement_Boss_Hodir_01") },		-- "The Sons of Hodir" 
			{ name = DataStore:GetFactionName(1156), icon = Texture("Achievement_Reputation_ArgentCrusader") },		-- "The Ashen Verdict" 
		},
		{	-- [2]
			name = DataStore:GetFactionName(1037), 	-- "Alliance Vanguard"
			{ name = DataStore:GetFactionName(1037), icon = Texture("Spell_Misc_HellifrePVPHonorHoldFavor") },	-- "Alliance Vanguard" 
			{ name = DataStore:GetFactionName(1068), icon = Texture("Achievement_Zone_HowlingFjord_02") },	-- "Explorers' League" 
			{ name = DataStore:GetFactionName(1126), icon = Texture("Achievement_Zone_StormPeaks_01") },		-- "The Frostborn" 
			{ name = DataStore:GetFactionName(1094), icon = Texture("Achievement_Zone_CrystalSong_01") },		-- "The Silver Covenant" 
			{ name = DataStore:GetFactionName(1050), icon = Texture("Achievement_Zone_BoreanTundra_01") },	-- "Valiance Expedition" 	
		},
		{	-- [3]
			name = DataStore:GetFactionName(1052), 	-- "Horde Expedition"
			{ name = DataStore:GetFactionName(1052), icon = Texture("Spell_Misc_HellifrePVPThrallmarFavor") },		-- "Horde Expedition" 
			{ name = DataStore:GetFactionName(1067), icon = Texture("Achievement_Zone_HowlingFjord_02") },		-- "The Hand of Vengeance" 
			{ name = DataStore:GetFactionName(1124), icon = Texture("Achievement_Zone_CrystalSong_01") },			-- "The Sunreavers" 
			{ name = DataStore:GetFactionName(1064), icon = Texture("Achievement_Zone_BoreanTundra_02") },		-- "The Taunka" 
			{ name = DataStore:GetFactionName(1085), icon = Texture("Achievement_Zone_BoreanTundra_03") },		-- "Warsong Offensive" 
		},
		{	-- [4]
			name = C_Map.GetMapInfo(119).name,	-- "Sholazar Basin"
			{ name = DataStore:GetFactionName(1104), icon = Texture("Ability_Mount_WhiteDireWolf") },		-- "Frenzyheart Tribe" 
			{ name = DataStore:GetFactionName(1105), icon = Texture("Achievement_Reputation_MurlocOracle") },	-- "The Oracles" 
		},		
	},
}

local CAT_ALLINONE = #Factions + 1

local VertexColors = {
	[FACTION_STANDING_LABEL1] = { r = 0.4, g = 0.13, b = 0.13 },	-- hated
	[FACTION_STANDING_LABEL2] = { r = 0.5, g = 0.0, b = 0.0 },		-- hostile
	[FACTION_STANDING_LABEL3] = { r = 0.6, g = 0.4, b = 0.13 },		-- unfriendly
	[FACTION_STANDING_LABEL4] = { r = 0.6, g = 0.6, b = 0.0 },		-- neutral
	[FACTION_STANDING_LABEL5] = { r = 0.0, g = 0.6, b = 0.0 },		-- friendly
	[FACTION_STANDING_LABEL6] = { r = 0.0, g = 0.6, b = 0.6 },		-- honored
	[FACTION_STANDING_LABEL7] = { r = 0.9, g = 0.3, b = 0.9 },		-- revered
	[FACTION_STANDING_LABEL8] = { r = 1.0, g = 1.0, b = 1.0 },		-- exalted
}

local view
local isViewValid

local OPTION_XPACK = "UI.Tabs.Grids.Reputations.CurrentXPack"
local OPTION_FACTION = "UI.Tabs.Grids.Reputations.CurrentFactionGroup"

local currentFaction
local currentDDMText
local dropDownFrame

local function BuildView()
	view = view or {}
	wipe(view)
	
	local currentXPack = addon:GetOption(OPTION_XPACK)
	local currentFactionGroup = addon:GetOption(OPTION_FACTION)

	if (currentXPack ~= CAT_ALLINONE) then
		for index, faction in ipairs(Factions[currentXPack][currentFactionGroup]) do
			table.insert(view, faction)	-- insert the table pointer
		end
	else	-- all in one, add all factions
		for xPackIndex, xpack in ipairs(Factions) do		-- all xpacks
			for factionGroupIndex, factionGroup in ipairs(xpack) do 	-- all faction groups
				for index, faction in ipairs(factionGroup) do
					table.insert(view, faction)	-- insert the table pointer
				end
			end
		end
		
		table.sort(view, function(a,b) 	-- sort all factions alphabetically
			if not a.name then
				DEFAULT_CHAT_FRAME:AddMessage(a.icon)
			end
			if not b.name then
				DEFAULT_CHAT_FRAME:AddMessage(b.icon)
			end
			
			return a.name < b.name
		end)
	end
	
	isViewValid = true
end

local function OnFactionChange(self, xpackIndex, factionGroupIndex)
	dropDownFrame:Close()

	addon:SetOption(OPTION_XPACK, xpackIndex)
	addon:SetOption(OPTION_FACTION, factionGroupIndex)
		
	local factionGroup = Factions[xpackIndex][factionGroupIndex]
	currentDDMText = factionGroup.name
	AltoholicTabGrids:SetViewDDMText(currentDDMText)
	
	isViewValid = nil
	AltoholicTabGrids:Update()
end

local function OnAllInOneSelected(self)
	dropDownFrame:Close()
	addon:SetOption(OPTION_XPACK, CAT_ALLINONE)
	addon:SetOption(OPTION_FACTION, 1)
	
	currentDDMText = L["All-in-one"]
	AltoholicTabGrids:SetViewDDMText(currentDDMText)
	isViewValid = nil
	AltoholicTabGrids:Update()
end

local function DropDown_Initialize(frame, level)
	if not level then return end

	local info = frame:CreateInfo()
	
	local currentXPack = addon:GetOption(OPTION_XPACK)
	local currentFactionGroup = addon:GetOption(OPTION_FACTION)
	
	if level == 1 then
		for xpackIndex = 1, (CAT_ALLINONE - 1) do
			info.text = Factions[xpackIndex].name
			info.hasArrow = 1
			info.checked = (currentXPack == xpackIndex)
			info.value = xpackIndex
			frame:AddButtonInfo(info, level)
		end
		
		info.text = L["All-in-one"]
		info.hasArrow = nil
		info.func = OnAllInOneSelected
		info.checked = (currentXPack == CAT_ALLINONE)
		frame:AddButtonInfo(info, level)
		
		frame:AddCloseMenu()
	
	elseif level == 2 then
		local menuValue = frame:GetCurrentOpenMenuValue()
		
		for factionGroupIndex, factionGroup in ipairs(Factions[menuValue]) do
			info.text = factionGroup.name
			info.func = OnFactionChange
			info.checked = ((currentXPack == menuValue) and (currentFactionGroup == factionGroupIndex))
			info.arg1 = menuValue
			info.arg2 = factionGroupIndex
			frame:AddButtonInfo(info, level)
		end
	end
end

local callbacks = {
	OnUpdate = function() 
			if not isViewValid then
				BuildView()
			end

			local currentXPack = addon:GetOption(OPTION_XPACK)
			local currentFactionGroup = addon:GetOption(OPTION_FACTION)
			
			if (currentXPack == CAT_ALLINONE) then
				AltoholicTabGrids:SetStatus(L["All-in-one"])
			else
				AltoholicTabGrids:SetStatus(format("%s / %s", Factions[currentXPack].name, Factions[currentXPack][currentFactionGroup].name))
			end
		end,
	GetSize = function() return #view end,
	RowSetup = function(self, rowFrame, dataRowID)
			currentFaction = view[dataRowID]

			rowFrame.Name.Text:SetText(format("%s%s", colors.white, currentFaction.name))
			rowFrame.Name.Text:SetJustifyH("LEFT")
		end,
	RowOnEnter = function()	end,
	RowOnLeave = function() end,
	ColumnSetup = function(self, button, dataRowID, character)
			local faction = currentFaction
			
			button.Background:SetTexture(faction.icon)
			if faction.left then		-- if it's not a full texture, use tcoords
				-- addon:Print("ReputationGrid : not full texture") --debug
				-- button.Background:SetTexture(faction.icon)
				button.Background:SetTexCoord(faction.left, faction.right, faction.top, faction.bottom)
			else
				-- addon:Print("ReputationGrid : is full texture") --debug
				-- button.Background:SetTexture(format("Interface\\Icons\\%s", faction.icon))
				button.Background:SetTexCoord(0, 1, 0, 1)
			end
			
			button.Name:SetFontObject("GameFontNormalSmall")
			button.Name:SetJustifyH("CENTER")
			button.Name:SetPoint("BOTTOMRIGHT", 5, 0)
			button.Background:SetDesaturated(false)
			
			local status, _, _, rate = DataStore:GetReputationInfo(character, faction.name)
			if status and rate then 
				local text
				if status == FACTION_STANDING_LABEL8 then	-- If exalted .. 
					text = icons.ready						-- .. just show the green check
				else
					button.Background:SetDesaturated(true)
					button.Name:SetFontObject("NumberFontNormalSmall")
					button.Name:SetJustifyH("RIGHT")
					button.Name:SetPoint("BOTTOMRIGHT", 0, 0)
					text = format("%2d%%", floor(rate))
				end

				local vc = VertexColors[status]
				button.Background:SetVertexColor(vc.r, vc.g, vc.b);
				
				local color = colors.white
				if status == FACTION_STANDING_LABEL1 or status == FACTION_STANDING_LABEL2 then
					color = colors.darkred
				end

				button.key = character
				button:SetID(dataRowID)
				button.Name:SetText(format("%s%s", color, text))
			else
				button.Background:SetVertexColor(0.3, 0.3, 0.3)	-- greyed out
				button.Name:SetText(icons.notReady)
				button:SetID(0)
				button.key = nil
			end
		end,
		
	OnEnter = function(frame) 
			local character = frame.key
			if not character then return end

			local faction = view[ frame:GetID() ].name
			local status, currentLevel, maxLevel, rate = DataStore:GetReputationInfo(character, faction)
			if not status then return end
			
			AltoTooltip:SetOwner(frame, "ANCHOR_LEFT");
			AltoTooltip:ClearLines()
			AltoTooltip:AddLine(format("%s %s@ %s%s",
				DataStore:GetColoredCharacterName(character), colors.white, colors.teal, faction),1,1,1)

			rate = format("%d%%", floor(rate))
			AltoTooltip:AddLine(format("%s: %d/%d (%s)", status, currentLevel, maxLevel, rate),1,1,1 )
						
			local bottom = DataStore:GetRawReputationInfo(character, faction)
			
			AltoTooltip:AddLine(" ",1,1,1)
			AltoTooltip:AddLine(format("%s = %s", icons.notReady, UNKNOWN), 0.8, 0.13, 0.13)
			AltoTooltip:AddLine(FACTION_STANDING_LABEL1, 0.8, 0.13, 0.13)
			AltoTooltip:AddLine(FACTION_STANDING_LABEL2, 1.0, 0.0, 0.0)
			AltoTooltip:AddLine(FACTION_STANDING_LABEL3, 0.93, 0.4, 0.13)
			AltoTooltip:AddLine(FACTION_STANDING_LABEL4, 1.0, 1.0, 0.0)
			AltoTooltip:AddLine(FACTION_STANDING_LABEL5, 0.0, 1.0, 0.0)
			AltoTooltip:AddLine(FACTION_STANDING_LABEL6, 0.0, 1.0, 0.8)
			AltoTooltip:AddLine(FACTION_STANDING_LABEL7, 1.0, 0.4, 1.0)
			AltoTooltip:AddLine(format("%s = %s", icons.ready, FACTION_STANDING_LABEL8), 1, 1, 1)
			AltoTooltip:AddLine(" ",1,1,1)
			AltoTooltip:AddLine(format("%s%s", colors.green, L["Shift+Left click to link"]))
			AltoTooltip:Show()
		end,
	OnClick = function(frame, button)
			local character = frame.key
			if not character then return end

			local faction = view[ frame:GetParent():GetID() ].name
			local status, currentLevel, maxLevel, rate = DataStore:GetReputationInfo(character, faction)
			if not status then return end
			
			if button == "LeftButton" and IsShiftKeyDown() then
				local chat = ChatEdit_GetLastActiveWindow()
				if chat:IsShown() then
					chat:Insert(format(L["%s is %s with %s (%d/%d)"], DataStore:GetCharacterName(character), status, faction, currentLevel, maxLevel))
				end
			end
		end,
	OnLeave = function(self)
			AltoTooltip:Hide() 
		end,
	InitViewDDM = function(frame, title)
			dropDownFrame = frame
			frame:Show()
			title:Show()

			local currentXPack = addon:GetOption(OPTION_XPACK)
			local currentFactionGroup = addon:GetOption(OPTION_FACTION)
			
			if (currentXPack ~= CAT_ALLINONE) then
				currentDDMText = Factions[currentXPack][currentFactionGroup].name
			else
				currentDDMText = L["All-in-one"]
			end
			
			frame:SetMenuWidth(100) 
			frame:SetButtonWidth(20)
			frame:SetText(currentDDMText)
			frame:Initialize(DropDown_Initialize, "MENU_NO_BORDERS")
		end,
}

AltoholicTabGrids:RegisterGrid(2, callbacks)

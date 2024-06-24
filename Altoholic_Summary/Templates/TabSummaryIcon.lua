local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors
local L = DataStore:GetLocale(addonName)

local OPTION_REALMS = "CurrentRealms"
local OPTION_FACTIONS = "CurrentFactions"
local OPTION_LEVELS = "CurrentLevels"
local OPTION_LEVELS_MIN = "CurrentLevelsMin"
local OPTION_LEVELS_MAX = "CurrentLevelsMax"
local OPTION_CLASSES = "CurrentClasses"
local OPTION_TRADESKILL = "CurrentTradeSkill"

local options

-- ** Icon events **

local function OnRealmFilterChange(frame)
	options[OPTION_REALMS] = frame.value
	addon.Characters:InvalidateView()
	addon.Summary:Update()
end

local function OnFactionFilterChange(frame)
	options[OPTION_FACTIONS] = frame.value
	addon.Characters:InvalidateView()
	addon.Summary:Update()
end

local function OnLevelFilterChange(frame, minLevel, maxLevel)
	options[OPTION_LEVELS] = frame.value
	options[OPTION_LEVELS_MIN] = minLevel
	options[OPTION_LEVELS_MAX] = maxLevel
	addon.Characters:InvalidateView()
	addon.Summary:Update()
end

local function OnTradeSkillFilterChange(frame)
	frame:GetParent():Close()
	
	options[OPTION_TRADESKILL] = frame.value
	addon.Characters:InvalidateView()
	addon.Summary:Update()
end

local function OnClassFilterChange(frame)
	options[OPTION_CLASSES] = frame.value
	addon.Characters:InvalidateView()
	addon.Summary:Update()
end

local function ShowOptionsCategory(self)
	addon.Tabs:OnClick("Options")
	AltoholicTabOptions["MenuItem"..self.value]:Item_OnClick()
end

local function ResetAllData_MsgBox_Handler(self, button)
	if not button then return end
	
	DataStore:ClearAllData()
	addon:Print(L["Information saved in DataStore has been completely deleted !"])
	
	-- rebuild the main character table, and all the menus
	addon.Characters:InvalidateView()
	addon.Summary:Update()
end

local function ResetAllData()
	-- reset all data stored in datastore modules
	AltoMessageBox:SetHandler(ResetAllData_MsgBox_Handler)
	AltoMessageBox:SetText(L["WIPE_DATABASE"])
	AltoMessageBox:Show()
end

-- ** Menu Icons **

local locationLabels = {
	format("%s %s(%s)", L["This realm"], colors.green, L["This account"]),
	format("%s %s(%s)", L["This realm"], colors.green, L["All accounts"]),
	format("%s %s(%s)", L["All realms"], colors.green, L["This account"]),
	format("%s %s(%s)", L["All realms"], colors.green, L["All accounts"]),
}

local function RealmsIcon_Initialize(frame, level)
	frame:AddTitle(L["FILTER_REALMS"])
	local option = options[OPTION_REALMS]

	-- add specific account/realm filters
	for key, text in ipairs(locationLabels) do
		frame:AddButton(text, key, OnRealmFilterChange, nil, (key == option))
	end
	frame:AddCloseMenu()
end

local function FactionIcon_Initialize(frame, level)
	local option = options[OPTION_FACTIONS]

	frame:AddTitle(L["FILTER_FACTIONS"])
	frame:AddButton(FACTION_ALLIANCE, 1, OnFactionFilterChange, nil, (option == 1))
	frame:AddButton(FACTION_HORDE, 2, OnFactionFilterChange, nil, (option == 2))
	frame:AddButton(L["Both factions"], 3, OnFactionFilterChange, nil, (option == 3))
	frame:AddButton(L["This faction"], 4, OnFactionFilterChange, nil, (option == 4))
	frame:AddCloseMenu()
end

local function LevelIcon_Initialize(frame, level)
	local option = options[OPTION_LEVELS]
	
	frame:AddTitle(L["FILTER_LEVELS"])
	frame:AddButtonWithArgs(ALL, 1, OnLevelFilterChange, 1, 85, (option == 1))
	frame:AddTitle()
	frame:AddButtonWithArgs("1-59", 2, OnLevelFilterChange, 1, 59, (option == 2))
	frame:AddButtonWithArgs("1-39", 3, OnLevelFilterChange, 1, 39, (option == 3))
	frame:AddButtonWithArgs("40-59", 4, OnLevelFilterChange, 40, 59, (option == 4))
	frame:AddButtonWithArgs("60-69", 5, OnLevelFilterChange, 60, 69, (option == 5))
	frame:AddButtonWithArgs("70-79", 6, OnLevelFilterChange, 70, 79, (option == 6))
	frame:AddButtonWithArgs("80-84", 7, OnLevelFilterChange, 80, 84, (option == 7))
	frame:AddButtonWithArgs("85", 8, OnLevelFilterChange, 85, 85, (option == 8))
	frame:AddCloseMenu()
end

local function ProfessionsIcon_Initialize(frame, level)
	if not level then return end

	local tradeskills = addon.TradeSkills.AccountSummaryFiltersSpellIDs
	local option = options[OPTION_TRADESKILL]
	
	if level == 1 then
		frame:AddTitle(L["FILTER_PROFESSIONS"])
		frame:AddButton(ALL, 0, OnTradeSkillFilterChange, nil, (option == 0))
		frame:AddTitle()
		frame:AddCategoryButton(PRIMARY_SKILLS, 1, level)
		frame:AddCategoryButton(SECONDARY_SKILLS, 2, level)
		frame:AddCloseMenu()
	
	elseif level == 2 then
		local spell, icon, _
		local firstSecondarySkill = addon.TradeSkills.AccountSummaryFirstSecondarySkillIndex
	
		if frame:GetCurrentOpenMenuValue() == 1 then				-- Primary professions
			for i = 1, (firstSecondarySkill - 1) do
				spell, _, icon = GetSpellInfo(tradeskills[i])
				frame:AddButton(spell, i, OnTradeSkillFilterChange, icon, (option == i), level)
			end
		
		elseif frame:GetCurrentOpenMenuValue() == 2 then		-- Secondary professions
			for i = firstSecondarySkill, #tradeskills do
				spell, _, icon = GetSpellInfo(tradeskills[i])
				
				frame:AddButton(spell, i, OnTradeSkillFilterChange, icon, (option == i), level)
			end
		end
	end
end

local function ClassIcon_Initialize(frame, level)
	local option = options[OPTION_CLASSES]
	
	frame:AddTitle(L["FILTER_CLASSES"])
	frame:AddButton(ALL, 0, OnClassFilterChange, nil, (option == 0))
	frame:AddTitle()
	
	-- See constants.lua
	for key, value in ipairs(CLASS_SORT_ORDER) do
		frame:AddButton(
			format("|c%s%s", RAID_CLASS_COLORS[value].colorStr, LOCALIZED_CLASS_NAMES_MALE[value]), 
			key, OnClassFilterChange, nil, (option == key)
		)
	end
	frame:AddCloseMenu()
end

local function AltoholicOptionsIcon_Initialize(frame, level)
	frame:AddTitle(format("%s: %s", GAMEOPTIONS_MENU, addonName))

	frame:AddButton(GENERAL, 2, ShowOptionsCategory)
	frame:AddButton(L["Calendar"], 5, ShowOptionsCategory)
	frame:AddButton(MAIL_LABEL, 3, ShowOptionsCategory)
	frame:AddButton(MISCELLANEOUS, 6, ShowOptionsCategory)
	-- frame:AddButton(SEARCH, AltoholicSearchOptions, ShowOptionsCategory)
	frame:AddButton(L["Tooltip"], 4, ShowOptionsCategory)
	
	-- frame:AddTitle()
	-- frame:AddTitle(OTHER)	
	-- frame:AddButton("What's new?", AltoholicWhatsNew, ShowOptionsCategory)
	-- frame:AddButton("Getting support", AltoholicSupport, ShowOptionsCategory)
	-- frame:AddButton(L["Memory used"], AltoholicMemoryOptions, ShowOptionsCategory)
	-- frame:AddButton(HELP_LABEL, AltoholicHelp, ShowOptionsCategory)
	frame:AddCloseMenu()
end

local addonList = {
	"DataStore_Auctions",
	"DataStore_Characters",
	"DataStore_Inventory",
	"DataStore_Mails",
	"DataStore_Quests",
}

local function DataStoreOptionsIcon_Initialize(frame, level)
	frame:AddTitle(format("%s: %s", GAMEOPTIONS_MENU, "DataStore"))
	frame:AddButton("Auctions", 8, ShowOptionsCategory)
	frame:AddButton("Characters", 9, ShowOptionsCategory)
	frame:AddButton("Inventory", 10, ShowOptionsCategory)
	frame:AddButton("Mails", 11, ShowOptionsCategory)
	frame:AddButton("Quests", 12, ShowOptionsCategory)
	
	-- frame:AddTitle()
	-- frame:AddButton(L["Reset all data"], nil, ResetAllData)
	-- frame:AddButton(HELP_LABEL, DataStoreHelp, ShowOptionsCategory)
	frame:AddCloseMenu()
end

local menuIconCallbacks = {
	RealmsIcon_Initialize,
	FactionIcon_Initialize,
	LevelIcon_Initialize,
	ProfessionsIcon_Initialize,
	ClassIcon_Initialize,
	AltoholicOptionsIcon_Initialize,
	DataStoreOptionsIcon_Initialize,
}

addon:Controller("AltoholicUI.TabSummaryIcon", {
	Icon_OnEnter = function(frame)
		local currentMenuID = frame:GetID()
		
		local menu = frame:GetParent().ContextualMenu
		
		menu:Initialize(menuIconCallbacks[currentMenuID], "LIST")
		menu:Close()
		menu:Toggle(frame, 0, 0)
	end,
})

-- This should be in TabSummary, not here, move later
DataStore:OnAddonLoaded("Altoholic_Summary", function() 
	Altoholic_SummaryTab_Options = Altoholic_SummaryTab_Options or {
		["ShowRestXP150pc"] = false,					-- display max rest xp in normal 100% mode or in level equivalent 150% mode ?
		["CurrentMode"] = 1,								-- current mode (1 = account summary, 2 = bags, ...)
		["CurrentColumn"] = "Name",					-- current column (default = "Name")
		["CurrentRealms"] = 2,							-- selected realms (current/all in current/all accounts)
		["CurrentAltGroup"] = 0,						-- selected alt group
		["CurrentFactions"] = 3,						-- 1 = Alliance, 2 = Horde, 3 = Both
		["CurrentLevels"] = 1,							-- 1 = All
		["CurrentLevelsMin"] = 1,							
		["CurrentLevelsMax"] = 70,					
		["CurrentBankType"] = 0,						-- 0 = All
		["CurrentClasses"] = 0,							-- 0 = All
		["CurrentTradeSkill"] = 0,						-- 0 = All
		["CurrentMisc"] = 0,								-- 
		["UseColorForTradeSkills"] = true,			-- Use color coding for tradeskills, or neutral
		["SortAscending"] = true,						-- ascending or descending sort order
		["ShowLevelDecimals"] = true,					-- display character level with decimals or not
		["ShowILevelDecimals"] = true,				-- display character level with decimals or not
		["ShowGuildRank"] = false,						-- display the guild rank or the guild name
	}
	options = Altoholic_SummaryTab_Options

end)

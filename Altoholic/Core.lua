local addonName, addon = ...
_G[addonName] = addon

addon.Version = "v4.4.001"
addon.VersionNum = 404001

LibStub("LibMVC-1.0"):Embed(addon)

local L = DataStore:GetLocale(addonName)
local LibSerialize = LibStub:GetLibrary("LibSerialize")
local commPrefix = addonName

-- Reminder: binding is done in bindings.xml
BINDING_HEADER_ALTOHOLIC = addonName
BINDING_NAME_ALTOHOLIC_TOGGLE = "Altoholic - Toggle UI"
 
addon.Colors = {
	white	= "|cFFFFFFFF",
	red = "|cFFFF0000",
	darkred = "|cFFF00000",
	green = "|cFF00FF00",
	felGreen = "|cFFD6EB00",			-- Burning Crusade Fel Green
	orange = "|cFFFF7F00",
	yellow = "|cFFFFFF00",
	gold = "|cFFFFD700",
	teal = "|cFF00FF9A",
	cyan = "|cFF1CFAFE",
	lightBlue = "|cFFB0B0FF",
	battleNetBlue = "|cff82c5ff",
	grey = "|cFF909090",
	
	-- classes
	classMage = "|cFF69CCF0",
	classHunter = "|cFFABD473",
	
	-- recipes
	recipeGrey = "|cFF808080",
	recipeGreen = "|cFF40C040",
	recipeOrange = "|cFFFF8040",
	
	-- rarity : http://wow.gamepedia.com/Quality
	common = "|cFFFFFFFF",
	uncommon = "|cFF1EFF00",
	rare = "|cFF0070DD",
	epic = "|cFFA335EE",
	legendary = "|cFFFF8000",
	heirloom = "|cFFE6CC80",

	Alliance = "|cFF2459FF",
	Horde = "|cFFFF0000",
}

local colors = addon.Colors

addon.Icons = {
	ready = "\124TInterface\\RaidFrame\\ReadyCheck-Ready:14\124t",
	waiting = "\124TInterface\\RaidFrame\\ReadyCheck-Waiting:14\124t",
	notReady = "\124TInterface\\RaidFrame\\ReadyCheck-NotReady:14\124t",
	questionMark = "Interface\\RaidFrame\\ReadyCheck-Waiting",

	Alliance = "Interface\\Icons\\INV_BannerPVP_02",
	Horde = "Interface\\Icons\\INV_BannerPVP_01",
	Neutral = "Interface\\Icons\\Achievement_character_pandaren_female",
}

-- One empty function to rule them all
addon.EmptyFunc = function() end

-- ** LDB Launcher **
LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "launcher",
	icon = "Interface\\Icons\\INV_Drink_13",
	OnClick = function(clickedframe, button)
		addon:ToggleUI()
	end,
	text = (Broker2FuBar) and addonName or nil,		-- only for fubar,  not for ldb
	label = addonName,
})


-- *** Guild Comm ***
local guildMembersVersion = {} 	-- hash table containing guild member info

-- Message types
local MSG_SEND_VERSION							= 1	-- Send Altoholic's version
local MSG_VERSION_REPLY							= 2	-- Reply

-- *** Utility functions ***
local function GuildBroadcast(messageType, ...)
	local data = LibSerialize:Serialize(messageType, ...)
	DataStore:SendChatMessage(commPrefix, data, "GUILD")
end

local function GuildWhisper(player, messageType, ...)
	if DataStore:IsGuildMemberOnline(player) then
		local data = LibSerialize:Serialize(messageType, ...)
		DataStore:SendChatMessage(commPrefix, data, "WHISPER", player)
	end
end

local function SaveVersion(sender, version)
	guildMembersVersion[sender] = version
end

local function SearchBags(searchText)
	if not searchText or string.len(searchText) == 0 then
		addon:Print("Usage = /altoholic search <item name>")
		return
	end
	
	if not AltoholicFrame:IsVisible() then
		AltoholicFrame:Show()
	end
	
	searchText = strlower(searchText)
	
	AltoholicFrame_SearchEditBox:SetText(searchText)
	addon.Tabs:OnClick("Search")
	addon.Search:FindItem()
end

local commandLineCommands = {
	["show"] = function() AltoholicFrame:Show() end,
	["hide"] = function() AltoholicFrame:Hide() end,
	["toggle"] = function() addon:ToggleUI() end,
	["search"] = SearchBags,
}

local function CommandLineCallback(args)
	-- No arguments ? show the options
	if not args or args == "" then
		local yellow = addon.Colors.yellow
	
		addon:Print(format("Arguments to %s/Alto :", yellow))
		print(format("  %sshow|r - %s", yellow, L["Shows the UI"]))
		print(format("  %shide|r - %s", yellow, L["Hides the UI"]))
		print(format("  %stoggle|r - %s", yellow, L["Toggles the UI"]))
		print(format("  %ssearch <item name>|r - %s", yellow, L["Search in bags"]))
		return
	end

	-- Get the command name and its argument
	local name, arg1 = strsplit(" ", args)
	
	if name and commandLineCommands[name] then
		commandLineCommands[name](arg1)
	end
end

local function RegisterChatCommand(command, callback)
	_G[ format("SLASH_%s1", command)] = format("/%s", command:lower())
	SlashCmdList[command] = callback
end

local function OnSendVersion(sender, version)
	if sender ~= UnitName("player") then								-- don't send back to self
		GuildWhisper(sender, MSG_VERSION_REPLY, addon.Version)		-- reply by sending my own version
	end
	SaveVersion(sender, version)											-- .. and save it
	
	if versionNum and versionNum > addon.VersionNum and not Altoholic_UI_Options.moreRecentVersion then
		addon:Print(L["NEW_VERSION_AVAILABLE"])
		addon:Print(L["OFFICIAL_SOURCES"])

		Altoholic_UI_Options.moreRecentVersion = addon.VersionNum
	end
end

local function OnVersionReply(sender, version)
	SaveVersion(sender, version)
end

local GuildCommCallbacks = {
	[MSG_SEND_VERSION] = OnSendVersion,
	[MSG_VERSION_REPLY] = OnVersionReply,
}


DataStore:OnAddonLoaded(addonName, function() 
	addon.ListenTo = function(self, ...) DataStore:ListenToEvent(self, ...)	end
	addon.StopListeningTo = function(self, ...) DataStore:StopListeningToEvent(self, ...)	end
	
	Altoholic_UI_Options = Altoholic_UI_Options or {
		Mail = {
			GuildMailWarning = true,					-- be informed when a guildie sends a mail to one of my alts
			AutoCompleteRecipient = true,				-- Auto complete recipient name when sending a mail
			AutoCompletePriority = 1,					-- Auto complete priority (1 = alphabetical, 2 = most played, 3 = most recent)
			LastExpiryWarning = 0,						-- Last time a mail expiry warning was triggered
			TimeToNextWarning = 3,						-- Time before the warning is repeated ('3' = no warning for 3 hours)
		},
		Minimap = { 
			ShowIcon = true, 
			IconAngle = 180, 
			IconRadius = 102
		},
		Scale = 1.0,
		Transparency = 1.0,
		ClampWindowToScreen = false,
		
		-- ** Global options **
		AHColorCoding = true,							-- color coded recipes at the AH
		VendorColorCoding = true,						-- color coded recipes at vendors
		
		-- To do : Plan removal of these 3
		TotalLoots = 0,							-- make at least one search in the loot tables to initialize these values
		UnknownLoots = 0,	
		unsafeItems = {},
	}
	
	Altoholic_Tooltip_Options = Altoholic_Tooltip_Options or {
		ShowItemSource = true,
		-- ShowItemXPack = true,
		ShowItemCount = true,
		ShowSimpleCount = false,				-- display just the counter, without details (like AH, equipped, etc..)
		ShowTotalItemCount = true,
		ShowKnownRecipes = true,
		ShowItemID = false,						-- display item id & item level in the tooltip (default: off)
		ShowGatheringNodesCount = true,		-- display counters when mousing over a gathering node (default:  on)
		ShowCrossFactionCount = true,		-- display counters for both factions on a pve server
		ShowMergedRealmsCount = true,		-- display counters for characters on connected realms
		ShowAllRealmsCount = true,			-- display counters for all realms (for BoA items)
		ShowAllAccountsCount = true,			-- display counters for all accounts on the same realm
		ShowGuildBankCount = true,			-- display guild bank counters
		ShowGuildBankRealm = false,			-- display the realm of the guild bank
		ShowHearthstoneCount = true,			-- display hearthstone counters
		IncludeGuildBankInTotal = true,		-- total count = alts + guildbank (1) or alts only (0)
		ShowGuildBankCountPerTab = false,	-- guild count = guild:count or guild (tab 1: x, tab2: y ..)
		-- ShowCouldBeStoredOn = false,			-- display "could be stored on" information
		
		ShowSellPrice = true,					-- Sell price per unit
		
		HiddenGuilds = {}						-- Guilds that should not be shown in the tooltip
	}
	
	Altoholic_Sharing_Options = Altoholic_Sharing_Options or {
		IsEnabled = false,						-- account sharing communication handler is disabled by default
		GuildBankAutoUpdate = false,			-- can the guild bank tabs update requests be answered automatically or not.
		Clients = {},
		Domains = {},								-- ["Account.Realm"] 
		SharedContent = {							-- lists the shared content
			--	["Account.Realm.Name"]  = true means the char is shared,
			--	["Account.Realm.Name.Module"]  = true means the module is shared for that char
		},
	}
	
	Altoholic_Calendar_Options = Altoholic_Calendar_Options or {
		WarningsEnabled = true,
		WeekStartsOnMonday = false,
		UseDialogBoxForWarnings = false,				-- use a dialog box for warnings (true), or default chat frame (false)
		WarningType1 = "30,15,10,5,4,3,2,1",		-- for profession cooldowns
		WarningType2 = "30,15,10,5,4,3,2,1",		-- for dungeon resets
		WarningType3 = "30,15,10,5,4,3,2,1",		-- for calendar events
		WarningType4 = "30,15,10,5,4,3,2,1",		-- for item timers (like mysterious egg)
	}

	RegisterChatCommand("Altoholic", CommandLineCallback)
	RegisterChatCommand("Alto", CommandLineCallback)
	
	DataStore:SetGuildCommCallbacks(commPrefix, GuildCommCallbacks)
	DataStore:OnGuildComm(commPrefix, DataStore:GetGuildCommHandler())
	
	addon:ListenTo("DATASTORE_ANNOUNCELOGIN", function(self, guildName)
		GuildBroadcast(MSG_SEND_VERSION, addon.Version, addon.VersionNum)
	end)
	
	-- this event MUST stay here, we have to be able to respond to a request event if the guild tab is not loaded
	addon:ListenTo("DATASTORE_BANKTAB_REQUESTED", function(event, sender, tabName)
		if Altoholic_Sharing_Options.GuildBankAutoUpdate then
			DataStore:SendBankTabToGuildMember(sender, tabName)
			return
		end
		
		AltoMessageBox:SetHeight(130)
		AltoMessageBox.Text:SetHeight(60)
		AltoMessageBox:Ask(format("%s\n\n%s",
				format(L["%s%s|r has requested the bank tab %s%s|r\nSend this information ?"], colors.white, sender, colors.white, tabName),
				format(L["%sWarning:|r make sure this user may view this information before accepting"], colors.white)), 
			
			-- On Yes
			function() DataStore:SendBankTabToGuildMember(sender, tabName) end, 
		
			-- On no
			function() DataStore:RejectBankTabRequest(sender) end)

	end)
	
	addon:ListenTo("DATASTORE_GUILD_MAIL_RECEIVED", function(event, sender, recipient)
		if Altoholic_UI_Options.Mail.GuildMailWarning then
			addon:Print(format(L["%s|r has received a mail from %s"], format("%s%s", colors.green, recipient), format("%s%s", colors.green, sender)))
		end
	end)

	addon:ListenTo("DATASTORE_GLOBAL_MAIL_EXPIRY", function(event, threshold) 
		-- at least one mail has expired
		
		local lastWarning = Altoholic_UI_Options.Mail.LastExpiryWarning
		local timeToNext = Altoholic_UI_Options.Mail.TimeToNextWarning
		local now = time()
		
		if (now - lastWarning) < (timeToNext * 3600) then	-- has enough time passed ?
			return		-- no ? exit !
		end
		
		AltoMessageBox:SetHeight(130)
		AltoMessageBox.Text:SetHeight(60)
		AltoMessageBox:Ask(format("%sAltoholic: %s\n%s\n%s\n\n%s", colors.teal, colors.white, 
			L["Mail is about to expire on at least one character."],
			L["Refer to the activity pane for more details."],
			L["Do you want to view it now ?"]), 
			
			-- On Yes
			function()
				AltoholicFrame:Show()
				AltoholicFrame:SwitchToTab("Summary")
				
				-- Show the activity panel
				local tab = AltoholicFrame.TabSummary
				tab.CategoriesList:ClickCategory("profile", 9)
				tab:Update()
			end)
		
		Altoholic_UI_Options.Mail.LastExpiryWarning = now
	end)
	
	addon:ListenTo("DATASTORE_AUCTIONS_NOT_CHECKED_SINCE", function(event, character, charID, days, threshold)
		if days >= threshold then
			local key = DataStore:GetCharacterKey(charID)
			addon:Print(format(L["AUCTION_HOUSE_NOT_VISITED_WARNING"], DataStore:GetColoredCharacterName(key), days))
		end
	end)
	
	-- if we knew of a more recent version, and we now use an update, then reset the value
	if Altoholic_UI_Options.moreRecentVersion and addon.VersionNum >= Altoholic_UI_Options.moreRecentVersion then
		Altoholic_UI_Options.moreRecentVersion = nil
	end
	
end)

function addon:OnInitialize()
	-- this event MUST stay here, we have to be able to respond to a request event if the guild tab is not loaded

	-- TO DO !!
	addon:RegisterMessage("DATASTORE_GUILD_LEFT")
end

function addon:GetGuildMemberVersion(member)
	if guildMembersVersion[member] then			-- version number of a main ?
		return guildMembersVersion[member]		-- return it immediately
	end
	
	-- check if member is an alt
	local main = DataStore:GetNameOfMain(member)
	if main and guildMembersVersion[main] then
		return guildMembersVersion[main]
	end
end


local SPELL_ID_ALCHEMY = 2259
local SPELL_ID_BLACKSMITHING = 3100
local SPELL_ID_ENCHANTING = 7411
local SPELL_ID_ENGINEERING = 4036
local SPELL_ID_INSCRIPTION = 45357
local SPELL_ID_JEWELCRAFTING = 25229
local SPELL_ID_LEATHERWORKING = 2108

local SPELL_ID_TAILORING = 3908
local SPELL_ID_SKINNING = 8613
local SPELL_ID_MINING = 2575
local SPELL_ID_HERBALISM = 2366
-- local SPELL_ID_SMELTING = 2656

local SPELL_ID_COOKING = 2550
local SPELL_ID_FIRSTAID = 3273
local SPELL_ID_FISHING = 7732			-- do not use 7733, it's "Artisan Fishing", not "Fishing"

addon.TradeSkills = {
	Recipes = {},
	-- spell IDs in alphabetical order (english), primary then secondary
   spellIDs = { 2259, 3100, 7411, 4036, 45357, 25229, 2108, 3908, 8613, 2575, 2366, 2550, 3273, 7732 },
	firstSecondarySkillIndex = 12, -- index of the first secondary profession in the table
		
   AccountSummaryFiltersSpellIDs = { 2259, 3100, 7411, 4036, 45357, 25229, 2108, 3908, 8613, 2575, 2366, 2550, 3273, 7732 },
	AccountSummaryFirstSecondarySkillIndex = 12, -- index of the first secondary profession in the table

	Names = {
		ALCHEMY = GetSpellInfo(2259),
		BLACKSMITHING = GetSpellInfo(3100),
		COOKING = GetSpellInfo(2550),
		ENCHANTING = GetSpellInfo(7411),
		ENGINEERING = GetSpellInfo(4036),
		INSCRIPTION = GetSpellInfo(45357),
		JEWELCRAFTING = GetSpellInfo(25229),
		FIRSTAID = GetSpellInfo(3273),
		FISHING = GetSpellInfo(7732),
		HERBALISM = GetSpellInfo(2366),
		LEATHERWORKING = GetSpellInfo(2108),
		MINING = GetSpellInfo(2575),
		SKINNING = GetSpellInfo(8613),
		-- SMELTING = GetSpellInfo(2656),
		TAILORING = GetSpellInfo(3908),
	},
}

-- ** Tabs **
local tabList = {
	"Summary",
	"Characters",
	"Search",
	"Guild",
	"Achievements",
	"Agenda",
	"Grids",
	"Options",
}

local frameToID = {}
for index, name in ipairs(tabList) do
	frameToID[name] = index
end

local function SafeLoadAddOn(name)
	if not IsAddOnLoaded(name) then
		LoadAddOn(name)
	end
end

local function ShowTab(name)
	local tab = _G[addonName.."Tab" .. name]
	if tab then
		tab:Show()
	end
end

local function HideTab(name)
	local tab = _G[addonName.."Tab" .. name]
	if tab then
		tab:Hide()
	end
end

addon.Tabs = {}

function addon.Tabs:HideAll()
	for _, tabName in pairs(tabList) do
		HideTab(tabName)
	end
end

function addon.Tabs:OnClick(index)
	if type(index) == "string" then
		index = frameToID[index]
	end
	
	PanelTemplates_SetTab(_G[addonName.."Frame"], index);
	self:HideAll()
	self.current = index
	
	if index >= 1 and index <= 8 then
		local moduleName = format("%s_%s", addonName, tabList[index])
		SafeLoadAddOn(moduleName)		-- make this part a bit more generic once we'll have more LoD parts
		
		local parentLevel = AltoholicFrame:GetFrameLevel()
		local childName = format("%sTab%s", addonName, tabList[index])

		local tabFrame = _G[ childName ]
		
		if tabFrame then
			local childLevel = tabFrame:GetFrameLevel()
			
			if childLevel <= parentLevel then	-- if for any reason a child frame has a level lower or equal to its parent, fix it
				tabFrame:SetFrameLevel(parentLevel+1)
			end
		else
			addon:Print(format("%s is disabled.", moduleName))
		end
	end
	
	ShowTab(tabList[index])
end

-- Allow ESC to close the main frame
tinsert(UISpecialFrames, "AltoholicFrame")
tinsert(UISpecialFrames, "AltoMessageBox")

function addon:Print(text)	
	DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", addonName, text))
end

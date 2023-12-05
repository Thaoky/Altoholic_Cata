local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local MAX_BANK_TABS = 8

local rarityIcons = {
	[0] = "Interface\\Icons\\inv_misc_gem_diamond_02",
	[2] = "Interface\\Icons\\inv_jewelcrafting_seasprayemerald_02",
	[3] = "Interface\\Icons\\inv_jewelcrafting_empyreansapphire_02",
	[4] = "Interface\\Icons\\inv_jewelcrafting_shadowsongamethyst_02",
	[5] = "Interface\\Icons\\inv_jewelcrafting_pyrestone_02",
	[6] = "Interface\\Icons\\inv_jewelcrafting_lionseye_02",
}

local function DeleteGuild_MsgBox_Handler(self, button, guildKey)
	if not button then return end
	
	local account, realm, guildName = strsplit(".", guildKey)
	local guild = addon:GetGuild(guildName, realm, account)
	wipe(guild)
	
	DataStore:DeleteGuild(guildKey)
	
	addon:Print(format( L["Guild %s successfully deleted"], guildName))
	
	if guildKey == currentGuildKey then
		currentGuildKey = nil
		currentGuildBankTab = nil
		ns:Update()
	end
end

-- ** Icon events **

local function OnGuildChange(frame, guildBank)
	local guildKey = frame.value
	
	guildBank:SetCurrentGuild(guildKey)
	guildBank:SetCurrentBankTab(nil)
	guildBank:Update()
	
	local _, _, guildName = strsplit(".", guildKey)
	AltoholicTabGuild.Status:SetText(format("%s%s %s/", colors.green, guildName, colors.white))

	local currentGuild = GetGuildInfo("player")
	
	local menuIcons = guildBank.MenuIcons
	
	if guildName == currentGuild then
		menuIcons.UpdateIcon:Enable()
		menuIcons.UpdateIcon.Icon:SetDesaturated(false)
	else
		menuIcons.UpdateIcon:Disable()
		menuIcons.UpdateIcon.Icon:SetDesaturated(true)
	end
	
	guildBank.Info1:SetText("")
	guildBank.Info2:SetText("")
	guildBank.Info3:SetText("")
	guildBank:UpdateBankTabButtons()
	guildBank:Update()
	
	guildBank.ContextualMenu:Close()
end

local function OnHideInTooltip(frame, guildBank)
	local account, realm, name = strsplit(".", frame.value)
	local guild = addon:GetGuild(name, realm, account)
	if guild	then
		guild.hideInTooltip = not guild.hideInTooltip
	end

	guildBank.ContextualMenu:Close()
end

local function OnGuildDelete(frame, guildBank)
	local guildKey = frame.value
	local _, realm, guildName = strsplit(".", guildKey)
	
	AltoMessageBox:SetHandler(DeleteGuild_MsgBox_Handler, guildKey)
	AltoMessageBox:SetText(format("%s\n%s%s %s(%s)", L["Delete Guild Bank?"], colors.green, guildName, colors.white, realm ))
	AltoMessageBox:Show()
	
	guildBank.ContextualMenu:Close()
end

local function OnGuildBankTabChange(frame, guildBank)
	guildBank:SetCurrentBankTab(frame.value)
	guildBank:Update()
end

local function OnBankTabRemoteUpdate(frame, guildBank)
	local tabName = DataStore:GetGuildBankTabName(guildBank:GetCurrentGuild(), guildBank:GetCurrentBankTab())
	local member = frame.value
	
	addon:Print(format(L["Requesting %s information from %s"], tabName, member ))
	DataStore:RequestGuildMemberBankTab(member, tabName)
end

local function OnRarityChange(frame, guildBank)
	local rarity = frame.value

	addon:SetOption("UI.Tabs.Guild.BankItemsRarity", rarity)
	
	guildBank.MenuIcons.RarityIcon:SetRarity(rarity)
	guildBank:Update()
end


-- ** Menu Icons **

local function GuildIcon_Initialize(frame, level)
	local guildBank = frame:GetParent()
	
	local info = frame:CreateInfo()

	if level == 1 then
		local guildKey = guildBank:GetCurrentGuild()
	
		for account in pairs(DataStore:GetAccounts()) do
			for realm in pairs(DataStore:GetRealms(account)) do
				for guildName, guild in pairs(DataStore:GetGuilds(realm, account)) do
					local text = format("%s%s / %s%s", colors.white, realm, colors.green, guildName)

					if account ~= "Default" then
						text = format("%s %s(%s)", text, colors.yellow, account)
					end
				
					info.text = text
					info.hasArrow = 1
					info.checked = (guild == guildKey) and true or nil
					info.value = guild		-- guild key
					info.func = OnGuildChange
					info.arg1 = guildBank
					frame:AddButtonInfo(info, level)
				end
			end
		end
		
	elseif level == 2 then
	
		-- frame:GetCurrentOpenMenuValue()
		-- UIDROPDOWNMENU_MENU_VALUE
		
		local currentMenu = frame:GetCurrentOpenMenuValue()
	
		local account, realm, name = strsplit(".", currentMenu)
		-- local account, realm, name = strsplit(".", UIDROPDOWNMENU_MENU_VALUE)
		local guild = addon:GetGuild(name, realm, account)
	
		info.text = colors.white ..  L["Hide this guild in the tooltip"]
		-- info.value = UIDROPDOWNMENU_MENU_VALUE
		info.value = currentMenu
		info.checked = guild.hideInTooltip
		info.func = OnHideInTooltip
		info.arg1 = guildBank
		frame:AddButtonInfo(info, level)
		
		info.text = colors.white .. DELETE
		-- info.value = UIDROPDOWNMENU_MENU_VALUE
		info.value = currentMenu
		info.checked = nil
		info.func = OnGuildDelete
		info.arg1 = guildBank
		frame:AddButtonInfo(info, level)
	end
end

local function TabsIcon_Initialize(frame, level)
	local guildBank = frame:GetParent()
	local guildKey = guildBank:GetCurrentGuild()
	local bankTab = guildBank:GetCurrentBankTab()

	frame:AddTitle(L["Guild Bank Tabs"])
	
	for tabID = 1, MAX_BANK_TABS do 
		local tabName = DataStore:GetGuildBankTabName(guildKey, tabID)
		
		if tabName then
			local info = frame:CreateInfo()
			
			info.text = tabName
			info.value = tabID
			info.func = OnGuildBankTabChange
			info.icon = DataStore:GetGuildBankTabIcon(guildKey, tabID)
			info.checked = (bankTab == tabID)
			info.arg1 = guildBank
			
			frame:AddButtonInfo(info)
		end
	end
	frame:AddCloseMenu()
end

local function UpdateIcon_Initialize(frame, level)
	local guildBank = frame:GetParent()
	local guildKey = guildBank:GetCurrentGuild()
	local bankTab = guildBank:GetCurrentBankTab()

	if not guildKey or not bankTab or bankTab == 0 then return end
	
	local tabName = DataStore:GetGuildBankTabName(guildKey, bankTab)
	if not tabName then return end
	
	local player = UnitName("player")
	local myClientTime = DataStore:GetGuildMemberBankTabInfo(player, tabName)
	
	local older = {}
	local newer = {}
	
	frame:AddTitle(L["Update current tab from"])
	for member in pairs(DataStore:GetGuildBankTabSuppliers()) do
		if member ~= player then	-- skip current player
			local clientTime = DataStore:GetGuildMemberBankTabInfo(member, tabName)
				
			if clientTime then	-- if there's data, we can add this member in the view for the current bank tab
				if clientTime > myClientTime then
					table.insert(newer, { name = member, timeStamp = clientTime } )
				else
					table.insert(older, { name = member, timeStamp = clientTime } )
				end
			end
		end
	end
	
	if #newer > 0 then
		frame:AddTitle(" ")
		frame:AddTitle(colors.yellow..L["Newer data"])
		
		table.sort(newer, function(a,b) return a.timeStamp > b.timeStamp end)
		
		
		local info = frame:CreateInfo()
		
		for _, member in ipairs(newer) do
			local clientTime = DataStore:GetGuildMemberBankTabInfo(member.name, tabName)
		
			info.text = format("%s%s %s%s", colors.white, member.name, colors.green, date("%m/%d/%Y %H:%M", clientTime))
			info.value = member.name
			info.func = OnBankTabRemoteUpdate
			info.arg1 = guildBank
			frame:AddButtonInfo(info)
		end
	end

	if #older > 0 then
		frame:AddTitle(" ")
		frame:AddTitle(colors.yellow..L["Older data"])
		
		table.sort(older, function(a,b) return a.timeStamp > b.timeStamp end)
		
		local info = frame:CreateInfo()
		
		for _, member in ipairs(older) do
			local clientTime = DataStore:GetGuildMemberBankTabInfo(member.name, tabName)
			
			info.text = format("%s%s %s%s", colors.white, member.name, colors.green, date("%m/%d/%Y %H:%M", clientTime))
			info.value = member.name
			info.func = OnBankTabRemoteUpdate
			info.arg1 = guildBank
			frame:AddButtonInfo(info)
		end
	end

	frame:AddCloseMenu()
end

local function RarityIcon_Initialize(frame, level)
	local rarity = addon:GetOption("UI.Tabs.Guild.BankItemsRarity")
	
	local guildBank = frame:GetParent()
	
	frame:AddTitle(format("|r%s", RARITY))
	
	-- Add the 'Any rarity' option
	frame:AddButtonWithArgs(L["Any"], 0, OnRarityChange, guildBank, nil, (rarity == 0))

	-- Add the rarity levels higher than green (Quality: 0 = poor .. 5 = legendary)
	for i = 2, 6 do
		frame:AddButtonWithArgs(format("%s%s", ITEM_QUALITY_COLORS[i].hex, _G["ITEM_QUALITY"..i.."_DESC"]), i, OnRarityChange, guildBank, nil, (rarity == i))
	end

	frame:AddCloseMenu()
end

local menuIconCallbacks = {
	GuildIcon_Initialize,
	TabsIcon_Initialize,
	UpdateIcon_Initialize,
	RarityIcon_Initialize,
}

addon:Controller("AltoholicUI.GuildBankIcon", {
	Icon_OnEnter = function(frame)
		local currentMenuID = frame:GetID()
		
		local guildBank = frame:GetParent():GetParent()
		local menu = guildBank.ContextualMenu
		
		menu:Initialize(menuIconCallbacks[currentMenuID], "LIST")
		menu:Close()
		menu:Toggle(frame, 0, 0)
	end,
	SetRarity = function(frame, rarity)
		-- technically, this will only be applied to the rarity icon.. but I'll settle for a function a this level ..
		
		if rarityIcons[rarity] then
			frame.Icon:SetTexture(rarityIcons[rarity])
		end
	end,
})

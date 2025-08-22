local addonTabName = ...
local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local L = AddonFactory:GetLocale(addonName)

local tab		-- small shortcut to easily address the frame (set in OnBind)

-- *** Event Handlers ***

local function OnGuildAltsReceived(event, sender, alts)
	tab.Members:InvalidateView()
	tab:Refresh()
end

local function OnBankTabRequestAck(event, sender)
	addon:Print(format(L["Waiting for %s to accept .."], sender))
end

local function OnBankTabRequestRejected(event, sender)
	addon:Print(format(L["Request rejected by %s"], sender))
end

local function OnBankTabUpdateSuccess(event, sender, guildName, tabName, tabID)
	addon:Print(format(L["Guild bank tab %s successfully updated !"], tabName ))
	tab.Bank:Update()
end

local function OnGuildMemberOffline(event, member)
	tab.Members:InvalidateView()
	tab:Refresh()
end

local function OnRosterUpdate()
	local _, onlineMembers = GetNumGuildMembers()
	tab.MenuItem1.Text:SetText(format("%s %s(%d)", L["Guild Members"], colors.green, onlineMembers))
	
	tab.Members:InvalidateView()
	tab:Refresh()
end

addon:Controller("AltoholicUI.TabGuild", {
	OnBind = function(frame)
		tab = frame
		
		frame.MenuItem1:SetText(L["Guild Members"])
		frame.MenuItem2:SetText(GUILD_BANK)
		frame:MenuItem_Highlight(1)
		frame:SetMode(1)

		DataStore:ListenTo("DATASTORE_GUILD_ALTS_RECEIVED", OnGuildAltsReceived)
		DataStore:ListenTo("DATASTORE_BANKTAB_REQUEST_ACK", OnBankTabRequestAck)
		DataStore:ListenTo("DATASTORE_BANKTAB_REQUEST_REJECTED", OnBankTabRequestRejected)
		DataStore:ListenTo("DATASTORE_BANKTAB_UPDATE_SUCCESS", OnBankTabUpdateSuccess)
		DataStore:ListenTo("DATASTORE_GUILD_MEMBER_OFFLINE", OnGuildMemberOffline)
		
		if IsInGuild() then
			addon:ListenTo("GUILD_ROSTER_UPDATE", OnRosterUpdate)
		end
	end,
	HideAll = function(frame)
		frame.Members:Hide()
		frame.Bank:Hide()
	end,
	Refresh = function(frame)
		if frame.Members:IsVisible() then
			frame.Members:Update()
		elseif frame.Bank:IsVisible() then
			frame.Bank:Update()
		end
	end,
	SetMode = function(frame, mode)
		if mode == 1 then
			frame.SortButtons:ShowChildFrames()
			frame.SortButtons:SetButton(1, NAME, 100, function() frame.Members:Sort("name") end)
			frame.SortButtons:SetButton(2, LEVEL, 60, function() frame.Members:Sort("level") end)
			frame.SortButtons:SetButton(3, "AiL", 65, function() frame.Members:Sort("averageItemLvl") end)
			frame.SortButtons:SetButton(4, GAME_VERSION_LABEL, 80, function() frame.Members:Sort("version") end)
			frame.SortButtons:SetButton(5, CLASS, 100, function() frame.Members:Sort("englishClass") end)
		else
			frame.SortButtons:HideChildFrames()
		end
	end,
	SetStatus = function(frame, text)
		frame.Status:SetText(text)
	end,
	MenuItem_Highlight = function(frame, id)
		-- highlight the current menu item
		for i = 1, 2 do 
			frame["MenuItem"..i]:UnlockHighlight()
		end
		frame["MenuItem"..id]:LockHighlight()
	end,
	MenuItem_OnClick = function(frame, id, panel)
		frame:HideAll()
		frame:MenuItem_Highlight(id)

		frame:SetMode(id)
		
		if panel then
			frame[panel]:Update()
		end
	end,
})

AddonFactory:OnAddonLoaded(addonTabName, function() 
	Altoholic_GuildTab_Options = Altoholic_GuildTab_Options or {
		["BankItemsRarity"] = 0,				-- rarity filter in the guild bank tab
		["SortAscending"] = true,				-- ascending or descending sort order
	}
end)

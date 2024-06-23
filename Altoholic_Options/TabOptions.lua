local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local L = DataStore:GetLocale(addonName)

local function GetLabel(label, isHeader)
	return isHeader
		and format("%s%s", colors.white, label)
		or format("|cFFBBFFBB   %s", label)
end

local panels = {}

addon:Controller("AltoholicUI.TabOptions", {
	OnBind = function(frame)
		frame.MenuItem1:SetText(GetLabel(addonName, true))
		frame.MenuItem2:SetText(GetLabel(GENERAL))
		frame.MenuItem3:SetText(GetLabel(MAIL_LABEL))
		frame.MenuItem4:SetText(GetLabel(L["Tooltip"]))
		frame.MenuItem5:SetText(GetLabel(L["Calendar"]))
		frame.MenuItem6:SetText(GetLabel(MISCELLANEOUS))
		
		frame.MenuItem7:SetText(GetLabel("DataStore", true))
		frame.MenuItem8:SetText(GetLabel("Auctions"))
		frame.MenuItem9:SetText(GetLabel("Characters"))
		frame.MenuItem10:SetText(GetLabel("Inventory"))
		frame.MenuItem11:SetText(GetLabel("Mails"))
		frame.MenuItem12:SetText(GetLabel("Quests"))
		
		panels[2] = AltoholicGeneralOptions
		panels[3] = AltoholicMailOptions
		panels[4] = AltoholicTooltipOptions
		panels[5] = AltoholicCalendarOptions
		panels[6] = AltoholicMiscOptions
		
		panels[8] = DataStoreFrames.AuctionsOptions
		panels[9] = DataStoreFrames.CharactersOptions
		panels[10] = DataStoreFrames.InventoryOptions
		panels[11] = DataStoreMailOptions
		panels[12] = DataStoreFrames.QuestsOptions
	end,

	Update = function(frame, panelID)
		for _, p in pairs(panels) do
			p:Hide()
		end
	
		local panel = panels[panelID]
		if not panel then return end
		
		panel:SetParent(frame)
		panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 190, -105)
		panel:Show()
	end,
})

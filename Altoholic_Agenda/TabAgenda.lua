local addonName = "Altoholic"
local addon = _G[addonName]
local L = DataStore:GetLocale(addonName)

addon:Controller("AltoholicUI.TabAgenda", { "AltoholicUI.Events", function(Events)

	local tab		-- small shortcut to easily address the frame (set in OnBind)

	local function OnCalendarDataUpdated(event, itemID)
		Events.BuildList()
		
		tab.Calendar.EventList:InvalidateView()
		tab.Calendar:InvalidateView()
		tab:Refresh()
	end

	return {
		OnBind = function(frame)
			tab = frame
		
			frame.MenuItem1:SetText(L["Calendar"])
			-- frame.MenuItem2:SetText("Contacts")
			-- frame.MenuItem3:SetText("Tasks")
			-- frame.MenuItem4:SetText("Notes")
			-- frame.MenuItem5:SetText("Mail")
			frame:MenuItem_Highlight(1)
			
			DataStore:ListenTo("DATASTORE_PROFESSION_COOLDOWN_UPDATED", OnCalendarDataUpdated)
			DataStore:ListenTo("DATASTORE_ITEM_COOLDOWN_UPDATED", OnCalendarDataUpdated)
			DataStore:ListenTo("DATASTORE_CALENDAR_SCANNED", OnCalendarDataUpdated)
		end,
		HideAll = function(frame)
			frame.Calendar:Hide()
			-- frame.Contacts:Hide()
		end,
		Refresh = function(frame)
			if frame.Calendar:IsVisible() then
				frame.Calendar:Update()
			end
		end,
		MenuItem_Highlight = function(frame, id)
			-- highlight the current menu item
			for i = 1, 5 do 
				frame["MenuItem"..i]:UnlockHighlight()
			end
			frame["MenuItem"..id]:LockHighlight()
		end,
		MenuItem_OnClick = function(frame, id, panel)
			frame:HideAll()
			frame:MenuItem_Highlight(id)

			if panel then
				frame[panel]:Update()
			end
		end,
	}
end})

local addonName = "Altoholic"
local addon = _G[addonName]

addon:Controller("AltoholicUI.TabOptionsMenuItem", {
	Item_OnClick = function(frame)
		local parent = frame:GetParent()
		
		-- update the highlight, unlock all, lock current
		local i = 1
		while parent["MenuItem"..i] do
			parent["MenuItem"..i]:UnlockHighlight()
			i = i + 1
		end
		frame:LockHighlight()
		
		AltoholicTabOptions:Update(frame:GetID())
	end,
})

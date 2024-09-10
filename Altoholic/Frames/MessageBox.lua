local addonName, addon = ...

addon:Controller("AltoholicUI.MessageBox", {
	SetText = function(frame, text)
		frame.Text:SetText(text)
	end,
	Ask = function(frame, text, onClickButton1, onClickButton2)
		--[[--
		frame.UserInput:Hide()
		frame.UserInput:SetText("")
		frame.Button1:SetText(YES)
		frame.Button2:SetText(NO)

		frame.onClickButton1 = onClickButton1		-- callback on "Yes"
		frame.onClickButton2 = onClickButton2		-- callback on "No"
		frame:Show()
		--]]--
		frame.Text:SetText(text)
		frame.onClickButton1 = onClickButton1		-- callback on "Yes"
		frame.onClickButton2 = onClickButton2		-- callback on "No"
		frame:Show()
	end,
	SetHandler = function(frame, func, arg1, arg2)
		frame.onClickCallback = func
		frame.arg1 = arg1
		frame.arg2 = arg2
	end,
	Button_OnClick = function(frame, button)
		-- until I have time to check all the places where msgbox is used, keep "button" as 1 for yes, and nil for no
		-- also, change the handler to work with ...

		if frame.onClickCallback then
			frame:onClickCallback(button, frame.arg1, frame.arg2)
			frame.onClickCallback = nil		-- prevent subsequent calls from coming back here
			frame.arg1 = nil
			frame.arg2 = nil
		elseif button then
			if frame.onClickButton1 then
				frame.onClickButton1()
			end
		elseif button == nil then
			if frame.onClickButton2 then
				frame.onClickButton2()
			end
		else
			addon:Print("MessageBox Handler not defined")
		end
		
		frame:Hide()
		frame:SetHeight(100)
		frame.Text:SetHeight(28)	
	end,
})

local addonName = "Altoholic"
local addon = _G[addonName]

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local WHITE		= "|cFFFFFFFF"
local GREEN		= "|cFF00FF00"

local view
local isViewValid

local currentTokenType
local currentDDMText
local dropDownFrame

local function GetUsedHeaders()
	local account, realm = AltoholicTabGrids:GetRealm()
	
	local usedHeaders = {}
	local isHeader, name, num

	for _, character in pairs(DataStore:GetCharacters(realm, account)) do	-- all alts on this realm
		num = DataStore:GetNumCurrencies(character) or 0
		
		for i = 1, num do
			isHeader, name = DataStore:GetCurrencyInfo(character, i)	-- save ech header found in the table
			if isHeader then
				usedHeaders[name] = true
			end
		end
	end
	
	return DataStore:HashToSortedArray(usedHeaders)
end

local function GetUsedTokens(header)
	-- get the list of tokens found under a specific header, across all alts

	local account, realm = AltoholicTabGrids:GetRealm()
	
	local tokens = {}
	local useData				-- use data for a specific header or not

	for _, character in pairs(DataStore:GetCharacters(realm, account)) do	-- all alts on this realm
		local num = DataStore:GetNumCurrencies(character) or 0
		for i = 1, num do
			local isHeader, name = DataStore:GetCurrencyInfo(character, i)
			
			if isHeader then
				if header and name ~= header then -- if a specific header (filter) was set, and it's not the one we chose, skip
					useData = nil
				else
					useData = true		-- we'll use data in this category
				end
			else
				if useData then		-- mark it as used
					tokens[name] = true
				end
			end
		end
	end
	
	return DataStore:HashToSortedArray(tokens)
end

local function BuildView()
	view = GetUsedTokens(currentTokenType)
	isViewValid = true
end

local function OnTokenChange(self)
	dropDownFrame:Close()

	currentTokenType = self.value
	currentDDMText = currentTokenType
	AltoholicTabGrids:SetViewDDMText(currentDDMText)

	isViewValid = nil
	AltoholicTabGrids:Update()
end

local function OnTokensAllInOne(self)
	dropDownFrame:Close()
	
	currentTokenType = nil
	currentDDMText = L["All-in-one"]
	AltoholicTabGrids:SetViewDDMText(currentDDMText)

	isViewValid = nil
	AltoholicTabGrids:Update()
end

local function DropDown_Initialize(frame)

	for _, header in ipairs(GetUsedHeaders()) do		-- and add them to the DDM
		frame:AddButton(header, header, OnTokenChange)
	end
	frame:AddButton(L["All-in-one"], nil, OnTokensAllInOne)
	frame:AddCloseMenu()
end

local callbacks = {
	OnUpdate = function() 
			if not isViewValid then
				BuildView()
			end
		end,
	GetSize = function() return #view end,
	RowSetup = function(self, rowFrame, dataRowID)
			local token = view[dataRowID]

			if token then
				rowFrame.Name.Text:SetText(WHITE .. token)
				rowFrame.Name.Text:SetJustifyH("LEFT")
				rowFrame.Name.Text:SetPoint("TOPLEFT", 15, 0)
			end
		end,
	ColumnSetup = function(self, button, dataRowID, character)
			button.Name:SetFontObject("NumberFontNormalSmall")
			button.Name:SetJustifyH("CENTER")
			button.Name:SetPoint("BOTTOMRIGHT", 5, 0)
			button.Background:SetDesaturated(false)
			button.Background:SetTexCoord(0, 1, 0, 1)
		
			local token = view[dataRowID]
			local count, currencyID = DataStore:GetCurrencyInfoByName(character, token)
			button.count = count
			
			if count then
				local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)
				button.Background:SetTexture(currencyInfo.iconFileID)		
				button.Background:SetVertexColor(0.5, 0.5, 0.5);	-- greyed out
				button.key = character
				
				if count >= 100000 then
					count = format("%2.1fM", count/1000000)
				elseif count >= 10000 then
					count = format("%2.0fk", count/1000)
				elseif count >= 1000 then
					count = format("%2.1fk", count/1000)
				end
				
				button.Name:SetText(GREEN..count)
				button:SetID(dataRowID)
				button:Show()
			else
				button.key = nil
				button:SetID(0)
				button:Hide()
			end
		end,
	OnEnter = function(frame) 
			local character = frame.key
			if not character then return end
			
			AltoTooltip:SetOwner(frame, "ANCHOR_LEFT")
			AltoTooltip:ClearLines()
			AltoTooltip:AddLine(DataStore:GetColoredCharacterName(character))
			AltoTooltip:AddLine(view[frame:GetID()], 1, 1, 1)
			AltoTooltip:AddLine(GREEN..frame.count)
			AltoTooltip:Show()
		end,
	OnClick = nil,
	OnLeave = function(frame)
			AltoTooltip:Hide() 
		end,
	InitViewDDM = function(frame, title) 
			dropDownFrame = frame
			frame:Show()
			title:Show()

			currentDDMText = currentDDMText or currentTokenType
			
			frame:SetMenuWidth(100) 
			frame:SetButtonWidth(20)
			frame:SetText(currentDDMText)
			frame:Initialize(DropDown_Initialize, "MENU_NO_BORDERS")
		end,
}

local headers = GetUsedHeaders()
currentTokenType = headers[1]

AltoholicTabGrids:RegisterGrid(7, callbacks)

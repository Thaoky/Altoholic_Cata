local addonName = "Altoholic"
local addon = _G[addonName]

local L = AddonFactory:GetLocale(addonName)

local WHITE		= "|cFFFFFFFF"
local GREEN		= "|cFF00FF00"

local view
local isViewValid

local currentTokenType
local currentDDMText
local dropDownFrame

local function GetUsedHeaders()
	-- local account, realm = AltoholicTabGrids:GetRealm()
	
	-- local usedHeaders = {}
	-- local isHeader, name

	-- for _, character in pairs(DataStore:GetCharacters(realm, account)) do	-- all alts on this realm
		
		-- for i = 1, (DataStore:GetNumCurrencies(character) or 0) do
			-- isHeader, name = DataStore:GetCurrencyInfo(character, i)	-- save ech header found in the table
			-- if isHeader then
				-- usedHeaders[name] = true
			-- end
		-- end
	-- end
	
	return DataStore:HashToSortedArray(DataStore_Currencies_Headers.Set)
end

local function GetUsedTokens(header)
	-- get the list of tokens found under a specific header, across all alts

	local account, realm = AltoholicTabGrids:GetRealm()
	
	local tokens = {}
	-- local useData				-- use data for a specific header or not

	for _, character in pairs(DataStore:GetCharacters(realm, account)) do	-- all alts on this realm
		for i = 1, (DataStore:GetNumCurrencies(character) or 0) do
		
			local name, _, _, category = DataStore:GetCurrencyInfo(character, i)
			
			if not header or (category == header) then
				tokens[name] = true
			end		
		
			-- local isHeader, name = DataStore:GetCurrencyInfo(character, i)
			
			-- if isHeader then
				-- if header and name ~= header then -- if a specific header (filter) was set, and it's not the one we chose, skip
					-- useData = nil
				-- else
					-- useData = true		-- we'll use data in this category
				-- end
			-- else
				-- if useData then		-- mark it as used
					-- tokens[name] = true
				-- end
			-- end
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

	local categoryId = self.value
	currentTokenType = categoryId
	currentDDMText = DataStore_Currencies_Headers.List[categoryId]
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

	for header, categoryId in pairs(DataStore_Currencies_Headers.Set) do		-- and add them to the DDM
		frame:AddButton(header, categoryId, OnTokenChange)
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
			local _, count, icon = DataStore:GetCurrencyInfoByName(character, token)

			--button.count = count or 0
			button.count = count
			button.Background:SetTexture(icon)
			button.key = character
			button:SetID(dataRowID)

			if count then
				button.Background:SetVertexColor(1, 1, 1)	-- Full color

				if count >= 100000 then
					count = format("%2.1fM", count/1000000)
				elseif count >= 10000 then
					count = format("%2.0fk", count/1000)
				elseif count >= 1000 then
					count = format("%2.1fk", count/1000)
				end

				--button.Name:SetText(format("%s%s", colors.green, count))
				button.Name:SetText(format("%s%s", GREEN, count))
			else
				button.Background:SetVertexColor(0.5, 0.5, 0.5)	-- greyed out
				button.Name:SetText(button.count)
			end
			button:Show()
		end,
	OnEnter = function(frame) 
			local character = frame.key
			if not character then return end
			
			AltoTooltip:SetOwner(frame, "ANCHOR_LEFT")
			AltoTooltip:ClearLines()
			AltoTooltip:AddLine(DataStore:GetColoredCharacterName(character))
			AltoTooltip:AddLine(view[frame:GetID()], 1, 1, 1)
			if frame.count and frame.count >= 0 then
				AltoTooltip:AddLine(format("%s%s", GREEN, frame.count))
			else
				AltoTooltip:AddLine(format("%s%s", GREEN, L["Not encountered"] or "Not encountered"))
			end
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

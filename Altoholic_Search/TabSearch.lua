local addonTabName = ...
local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors

local L = AddonFactory:GetLocale(addonName)

local parentName = "AltoholicTabSearch"
local parent

local highlightIndex
local selectedClass, selectedSubClass		-- the category the tree on the left is showing as picked

addon.Tabs.Search = {}

local ns = addon.Tabs.Search		-- ns = namespace

local currentClass
local currentSubClass
local function _GetAuctionItemSubClasses(itemClass)
	if type(C_AuctionHouse) ~= type({}) then
		return {GetAuctionItemSubClasses(itemClass)}
	end
	return C_AuctionHouse.GetAuctionItemSubClasses(itemClass)
end
-- from Blizzard_AuctionData.lua & LuaEnum.lua
-- Note : review this later on, I suspect Blizzard will change this again
local categories = {
	{
		name = AUCTION_CATEGORY_WEAPONS,
		class = LE_ITEM_CLASS_WEAPON or Enum.ItemClass.Weapon,
		--[[
		subClasses = {
			LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H,
			LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD2H, 
			LE_ITEM_WEAPON_WARGLAIVE, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_WAND,
			LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF,
			LE_ITEM_WEAPON_BOWS, LE_ITEM_WEAPON_CROSSBOW, LE_ITEM_WEAPON_GUNS, LE_ITEM_WEAPON_THROWN,
			LE_ITEM_WEAPON_FISHINGPOLE,
		},
		--]]
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_WEAPON or Enum.ItemClass.Weapon),
		isCollapsed = true,
	},
	{
		name = AUCTION_CATEGORY_ARMOR,
		class = LE_ITEM_CLASS_ARMOR or Enum.ItemClass.Armor,
		--[[
		subClasses = {
			LE_ITEM_ARMOR_PLATE, LE_ITEM_ARMOR_MAIL, LE_ITEM_ARMOR_LEATHER, LE_ITEM_ARMOR_CLOTH, 
			LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_SHIELD, LE_ITEM_ARMOR_COSMETIC,
		},
		--]]
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_ARMOR or Enum.ItemClass.Armor),
		isCollapsed = true,
	},
	{
		name = AUCTION_CATEGORY_CONTAINERS,
		class = LE_ITEM_CLASS_CONTAINER or Enum.ItemClass.Container,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_CONTAINER or Enum.ItemClass.Container),
		isCollapsed = true,
	},
	{
		name = AUCTION_CATEGORY_GEMS,
		class = LE_ITEM_CLASS_GEM or Enum.ItemClass.Gem,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_GEM or Enum.ItemClass.Gem),
		isCollapsed = true,
	},
	{
		name = AUCTION_CATEGORY_ITEM_ENHANCEMENT,
		class = LE_ITEM_CLASS_ITEM_ENHANCEMENT or Enum.ItemClass.ItemEnhancement,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_ITEM_ENHANCEMENT or Enum.ItemClass.ItemEnhancement),
		isCollapsed = true,
	},
	{
		name = AUCTION_CATEGORY_CONSUMABLES,
		class = LE_ITEM_CLASS_CONSUMABLE or Enum.ItemClass.Consumable,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_CONSUMABLE or Enum.ItemClass.Consumable),
		isCollapsed = true,
	},
	--[[
	{
		name = AUCTION_CATEGORY_GLYPHS,
		class = LE_ITEM_CLASS_GLYPH or Enum.ItemClass.Glyph,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_GLYPH or Enum.ItemClass.Glyph),
		isCollapsed = true,
	},
	]]
	{
		name = AUCTION_CATEGORY_TRADE_GOODS,
		class = LE_ITEM_CLASS_TRADEGOODS or Enum.ItemClass.Tradegoods,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_TRADEGOODS or Enum.ItemClass.Tradegoods) or {},
		isCollapsed = true,
	},
	{
		name = AUCTION_CATEGORY_RECIPES,
		class = LE_ITEM_CLASS_RECIPE or Enum.ItemClass.Recipe,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_RECIPE or Enum.ItemClass.Recipe),
		isCollapsed = true,
	},
	--[[
	{
		name = AUCTION_CATEGORY_BATTLE_PETS,
		class = LE_ITEM_CLASS_BATTLEPET or Enum.ItemClass.Battlepet,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_BATTLEPET or Enum.ItemClass.Battlepet),
		isCollapsed = true,
	},
	--]]
	{
		name = AUCTION_CATEGORY_QUEST_ITEMS,
		class = LE_ITEM_CLASS_QUESTITEM or Enum.ItemClass.Questitem,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_QUESTITEM or Enum.ItemClass.Questitem),
		isCollapsed = true,
	},
	{
		name = AUCTION_CATEGORY_MISCELLANEOUS,
		class = LE_ITEM_CLASS_MISCELLANEOUS or Enum.ItemClass.Miscellaneous,
		subClasses = _GetAuctionItemSubClasses(LE_ITEM_CLASS_MISCELLANEOUS or Enum.ItemClass.Miscellaneous),
		isCollapsed = true,
	},
}

local function Header_OnClick(frame)
	local header = categories[frame.itemTypeIndex]
	header.isCollapsed = not header.isCollapsed

	ns:Update()
end

local function Item_OnClick(frame)
	local category = categories[frame.itemTypeIndex]
	local class = category.class
	local subClass = category.subClasses[frame.itemSubTypeIndex]
	
	-- 1005 = class 1, sub 5
	highlightIndex = (frame.itemTypeIndex * 1000) + frame.itemSubTypeIndex
	ns:Update()

	-- kept so that the search button, which carries no category of its own, does not
	-- silently widen the search while this entry still looks picked
	selectedClass = C_Item.GetItemClassInfo(class)
	selectedSubClass = C_Item.GetItemSubClassInfo(class, subClass)

	addon.Search:FindItem(selectedClass, selectedSubClass)
end

function ns:GetSelectedCategory()
	return selectedClass, selectedSubClass
end

-- An upgrade search comes from a right click in the Grids tab and brings the user here to read
-- its results. Whatever category was picked the last time this tab was used has nothing to do
-- with what is now on screen, and leaving it lit says the list was filtered by it. The rest of
-- the panel is left alone: Reset() is a different thing, and the user did not ask for it.
function ns:ClearCategorySelection()
	if not highlightIndex and not selectedClass then return end

	highlightIndex = nil
	selectedClass, selectedSubClass = nil, nil
	ns:Update()
end

function ns:OnLoad()
	parent = _G[parentName]
	parent.SortButtons.Sort1:SetText(L["Item / Location"])
	parent.SortButtons.Sort2:SetText(L["Character"])
	parent.SortButtons.Sort3:SetText(L["Realm"])
	parent.Slot:SetText(L["Equipment Slot"])
	parent.Location:SetText(L["Location"])
end

function ns:Update()
	local itemTypeCacheIndex		-- index of the item type in the cache table
	local MenuCache = {}
	
	for categoryIndex, category in ipairs (categories) do
	
		table.insert(MenuCache, { linetype = 1, dataIndex = categoryIndex } )
		itemTypeCacheIndex = #MenuCache
	
		if category.isCollapsed == false then
			for subCategoryIndex, subCategory in ipairs(category.subClasses) do
				table.insert(MenuCache, { linetype = 2, dataIndex = subCategoryIndex, parentIndex = categoryIndex } )
				
				if (highlightIndex) and (highlightIndex == ((categoryIndex*1000)+ subCategoryIndex)) then
					MenuCache[#MenuCache].needsHighlight = true
					MenuCache[itemTypeCacheIndex].needsHighlight = true
				end
			end
		end
	end
	
	local buttonWidth = 156
	if #MenuCache > 15 then
		buttonWidth = 136
	end
	
	local scrollFrame = parent.ScrollFrame
	local numRows = scrollFrame.numRows
	local offset = scrollFrame:GetOffset()
	local menuButton
	
	for rowIndex = 1, numRows do
		menuButton = scrollFrame:GetRow(rowIndex)
		
		local line = rowIndex + offset
		
		if line > #MenuCache then
			menuButton:Hide()
		else
			local p = MenuCache[line]
			
			menuButton:SetWidth(buttonWidth)
			menuButton.Text:SetWidth(buttonWidth - 21)
			if p.needsHighlight then
				menuButton:LockHighlight()
			else
				menuButton:UnlockHighlight()
			end			
			
			if p.linetype == 1 then
				menuButton.Text:SetText(format("%s%s", colors.white, categories[p.dataIndex].name))
				menuButton:SetScript("OnClick", Header_OnClick)
				menuButton.itemTypeIndex = p.dataIndex
			elseif p.linetype == 2 then
				local category = categories[p.parentIndex]
				local class = category.class
				local subClass = category.subClasses[p.dataIndex]

				-- Blizzard lists -1 among the sub classes of some categories - Consumable on
				-- Era is one - as the sentinel for "the whole class, no sub filter". It has
				-- no name of its own, so asking for one answers nothing.
				local subClassName = C_Item.GetItemSubClassInfo(class, subClass) or ALL or ""

				menuButton.Text:SetText("|cFFBBFFBB   " .. subClassName)
				menuButton:SetScript("OnClick", Item_OnClick)
				menuButton.itemTypeIndex = p.parentIndex
				menuButton.itemSubTypeIndex = p.dataIndex
			end

			menuButton:Show()
		end
	end
	
	scrollFrame:Update(#MenuCache)
end

function ns:Reset()
	AltoholicFrame_SearchEditBox:SetText("")
	parent.MinLevel:SetText("")
	parent.MaxLevel:SetText("")
	parent.Status:SetText("")				-- .. the search results
	AltoholicFrameSearch:Hide()
	addon.Search:ClearResults()
	collectgarbage()
	
	for _, category in pairs(categories) do			-- rebuild the cache
		category.isCollapsed = true
	end
	highlightIndex = nil
	selectedClass, selectedSubClass = nil, nil
	
	for i = 1, 8 do 
		parent.SortButtons["Sort"..i]:Hide()
		parent.SortButtons["Sort"..i].ascendingSort = nil
	end
	ns:Update()
end

function ns:DropDownRarity_Initialize()
	local info = UIDropDownMenu_CreateInfo(); 

	for i = 0, LE_ITEM_QUALITY_HEIRLOOM do		-- Quality: 0 = poor .. 5 = legendary ..
		info.text = format("|c%s%s", select(4, GetItemQualityColor(i)), _G["ITEM_QUALITY"..i.."_DESC"])
		info.value = i
		info.func = function(self)	
			UIDropDownMenu_SetSelectedValue(parent.SelectRarity, self.value)
		end
		info.checked = nil; 
		info.icon = nil; 
		UIDropDownMenu_AddButton(info, 1);
	end
end 

local slotNames = {		-- temporary workaround
	[1] = INVTYPE_HEAD,
	[2] = INVTYPE_SHOULDER,
	[3] = INVTYPE_CHEST,
	[4] = INVTYPE_WRIST,
	[5] = INVTYPE_HAND,
	[6] = INVTYPE_WAIST,
	[7] = INVTYPE_LEGS,
	[8] = INVTYPE_FEET,
	[9] = INVTYPE_NECK,
	[10] = INVTYPE_CLOAK,
	[11] = INVTYPE_FINGER,
	[12] = INVTYPE_TRINKET,
	[13] = INVTYPE_WEAPON,
	[14] = INVTYPE_2HWEAPON,
	[15] = INVTYPE_WEAPONMAINHAND,
	[16] = INVTYPE_WEAPONOFFHAND,
	[17] = INVTYPE_SHIELD,
	[18] = INVTYPE_RANGED
}

function ns:DropDownSlot_Initialize()
	local function SetSearchSlot(self) 
		UIDropDownMenu_SetSelectedValue(parent.SelectSlot, self.value);
	end
	
	local info = UIDropDownMenu_CreateInfo(); 
	info.text = L["Any"]
	info.value = 0
	info.func = SetSearchSlot
	info.checked = nil; 
	info.icon = nil; 
	UIDropDownMenu_AddButton(info, 1); 	
	
	for i = 1, 18 do
		--info.text = addon.Equipment:GetSlotName(i)
		info.text = slotNames[i]		-- temporary workaround
		info.value = i
		info.func = SetSearchSlot
		info.checked = nil; 
		info.icon = nil; 
		UIDropDownMenu_AddButton(info, 1); 
	end
end 

function ns:DropDownLocation_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	local text = {
		L["This character"],
		format("%s %s(%s)", L["This realm"], colors.green, L["This faction"]),
		format("%s %s(%s)", L["This realm"], colors.green, L["Both factions"]),
		L["All realms"],
		L["All accounts"],
		L["Loot tables"]
	}
	
	for i = 1, #text do
		info.text = text[i]
		info.value = i
		info.func = function(self) 
				UIDropDownMenu_SetSelectedValue(parent.SelectLocation, self.value)
			end
		info.checked = nil; 
		info.icon = nil; 
		UIDropDownMenu_AddButton(info, 1); 		
	end
end

function ns:SetMode(mode)

	-- sets the search mode, and prepares the frame accordingly (search update callback, column sizes, headers, etc..)
	if mode == "realm" then
		addon.Search:SetUpdateHandler("Realm_Update")
		
		parent.SortButtons:SetButton(1, L["Item / Location"], 240, function(self) addon.Search:SortResults(self, "name") end)
		parent.SortButtons:SetButton(2, L["Character"], 160, function(self) addon.Search:SortResults(self, "char") end)
		parent.SortButtons:SetButton(3, L["Realm"], 150, function(self) addon.Search:SortResults(self, "realm") end)
	
	elseif mode == "loots" then
		addon.Search:SetUpdateHandler("Loots_Update")
		
		parent.SortButtons:SetButton(1, L["Item / Location"], 240, function(self) addon.Search:SortResults(self, "item") end)
		-- the source column now holds every place an item drops from, joined: it needs the
		-- room, and the item level column only ever shows a three digit number
		parent.SortButtons:SetButton(2, L["Source"], 240, function(self) addon.Search:SortResults(self, "bossName") end)
		parent.SortButtons:SetButton(3, L["Item Level"], 70, function(self) addon.Search:SortResults(self, "iLvl") end)
		
	elseif mode == "upgrade" then
		addon.Search:SetUpdateHandler("Upgrade_Update")

		parent.SortButtons:SetButton(1, L["Item / Location"], 200, function(self) addon.Search:SortResults(self, "item") end)

		-- the layout the search was set up with, rather than a lookup on the current class:
		-- right-clicking another grid cell overwrites that with the bare class name
		local statFormat = addon.Search:GetUpgradeStatFormat()

		for i=1, 6 do
			local text = statFormat and select(i, strsplit("|", statFormat))
			
			if text then
				parent.SortButtons:SetButton(i+1, string.sub(text, 1, 3), 50, function(self)
					addon.Search:SortResults(self, "stat") -- use a getID to know which stat
				end)
			else
				parent.SortButtons:SetButton(i+1, nil)
			end
		end
		
		parent.SortButtons:SetButton(8, "iLvl", 50, function(self) addon.Search:SortResults(self, "iLvl") end)
	end
end

function ns:TooltipStats(frame)
	AltoTooltip:ClearLines();
	AltoTooltip:SetOwner(frame, "ANCHOR_RIGHT");
	
	AltoTooltip:AddLine(STATS_LABEL)
	AltoTooltip:AddLine(" ");
	
	local s = addon.Search:GetResult(frame:GetID())
	local statFormat = addon.Search:GetUpgradeStatFormat()

	if not s or not statFormat then return end

	for i=1, 6 do
		local text = select(i, strsplit("|", statFormat))
		if text then
			local color
			local diff = select(2, strsplit("|", s["stat"..i]))
			diff = tonumber(diff)

			if diff < 0 then
				color = colors.red
			elseif diff > 0 then 
				color = colors.green
				diff = "+" .. diff
			else
				color = colors.white
			end
			AltoTooltip:AddLine(format("%s%s %s", color, diff, text))
		end
	end
	AltoTooltip:Show()
end

AddonFactory:OnAddonLoaded(addonTabName, function() 
	Altoholic_SearchTab_Options = Altoholic_SearchTab_Options or {
		["IncludeNoMinLevel"] = true,				-- include items with no minimum level
		["IncludeMailboxItems"] = true,
		-- ["IncludeGuildBankItems"] = true,
		["IncludeKnownRecipes"] = true,
		-- ["CurrentLocation"] = 1,
		-- ["UseColorsForAlts"] = true,
		-- ["UseColorsForRealms"] = true,
		["SortAscending"] = true,					-- ascending or descending sort order
				
	}

end)

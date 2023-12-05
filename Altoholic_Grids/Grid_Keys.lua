local addonName = "Altoholic"
local addon = _G[addonName]
local colors = addon.Colors
local icons = addon.Icons

local dungeonKeys = {
	-- *** Classic ***
	
	-- Workshop Key, Gnomeregan
	{ itemID = 6893, area = C_Map.GetAreaInfo(721), level = "26-36", icon = "inv_misc_key_06" },
	
	-- Scarlet Key, Scarlet Monastery
	{ itemID = 7146, area = C_Map.GetAreaInfo(796), level = "26-45", icon = "inv_misc_key_01" },
	
	-- Mallet of Zul'Farrak
	{ itemID = 9240, area = C_Map.GetAreaInfo(1176), level = "42-48", icon = "inv_hammer_19" },

	-- Scepter of Celebras, Maraudon
	{ itemID = 17191, area = C_Map.GetAreaInfo(2100), level = "42-52", icon = "inv_staff_16" },	
	
	-- Yeh'kinya's Scroll, Temple of Atal'Hakkar
	{ itemID = 10818, area = C_Map.GetAreaInfo(1477), level = "50-60", icon = "inv_scroll_02" },
	
	-- Shadowforge Key, Blackrock Depths
	{ itemID = 11000, area = C_Map.GetAreaInfo(1584), level = "52-60", icon = "inv_misc_key_08" },
	
	-- Key to the City, Stratholme
	{ itemID = 12382, area = C_Map.GetAreaInfo(2017), level = "58-60", icon = "inv_misc_key_13" },

	-- Skeleton Key, Scholomance
	{ itemID = 13704, area = C_Map.GetAreaInfo(2057), level = "58-60", icon = "inv_misc_key_11" },
	
	-- Seal of Ascension, Blackrock Spire
	{ itemID = 12344, area = C_Map.GetAreaInfo(1583), level = "58-60", icon = "inv_jewelry_ring_01" },
	
	-- Crescent Key, Dire Maul
	{ itemID = 18249, area = C_Map.GetAreaInfo(2557), level = "58-60", icon = "inv_misc_key_10" },
	
	-- *** Burning Crusade ***
	-- Flamewrought Key, Hellfire Citadel (Alliance)
	{ itemID = 30622, area = C_Map.GetAreaInfo(3545), level = "70", icon = "inv_misc_key_13", isBC = true },
	-- Flamewrought Key, Hellfire Citadel (Horde)
	{ itemID = 30637, area = C_Map.GetAreaInfo(3545), level = "70", icon = "inv_misc_key_13", isBC = true },
	
	-- Reservoir Key, Coilfang Reservoir
	{ itemID = 30623, area = C_Map.GetAreaInfo(3905), level = "70", icon = "inv_misc_key_13", isBC = true },
	
	-- Auchenai Key, Auchindoun
	{ itemID = 30633, area = C_Map.GetAreaInfo(3688), level = "70", icon = "inv_misc_key_11", isBC = true },

	-- Warpforged Key, Tempest Keep
	{ itemID = 30634, area = C_Map.GetAreaInfo(3842), level = "70", icon = "inv_misc_key_09", isBC = true },

	-- Key of Time, Caverns of Time
	{ itemID = 30635, area = C_Map.GetAreaInfo(1941), level = "70", icon = "inv_misc_key_04", isBC = true },

}

local callbacks = {
	OnUpdate = function() end,
	GetSize = function() return #dungeonKeys end,
	RowSetup = function(self, rowFrame, dataRowID)
			local dungeon = dungeonKeys[dataRowID]
			local color = (dungeon.isBC) and colors.felGreen or colors.white
			
			rowFrame.Name.Text:SetText(format("%s%s\n%s%s%s (%s%s%s)", color, GetItemInfo(dungeon.itemID) or "",
				colors.gold, dungeon.area, colors.white,
				colors.green, dungeon.level, colors.white
				))
			rowFrame.Name.Text:SetJustifyH("LEFT")
		end,
	ColumnSetup = function(self, button, dataRowID, character)
			local dungeon = dungeonKeys[dataRowID]
	
			button.Name:SetFontObject("GameFontNormalSmall")
			button.Name:SetJustifyH("CENTER")
			button.Name:SetPoint("BOTTOMRIGHT", 5, 0)
			button.Background:SetDesaturated(false)
			button.Background:SetTexCoord(0, 1, 0, 1)
			button.Background:SetTexture(format("Interface\\ICONS\\%s", dungeon.icon))
			
			local bagCount, bankCount = DataStore:GetContainerItemCount(character, dungeon.itemID)
			
			if bagCount > 0 or bankCount > 0 then
				button.Background:SetVertexColor(1.0, 1.0, 1.0)
				button.Name:SetText(icons.ready)
			else
				button.Background:SetVertexColor(0.4, 0.4, 0.4)
				button.Name:SetText(icons.notReady)
			end
			
			button.id = dataRowID
		end,
	OnEnter = function(frame) 
			local dungeon = dungeonKeys[frame.id]
			if not dungeon then return end

			local _, link = GetItemInfo(dungeon.itemID)
			if not link then return end
			
			GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end,
	OnLeave = function(self)
			GameTooltip:Hide() 
		end,
	InitViewDDM = function(frame, title) 
			frame:Hide()
			title:Hide()
		end,
}

AltoholicTabGrids:RegisterGrid(6, callbacks)

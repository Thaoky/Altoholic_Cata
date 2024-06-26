local addonName = "Altoholic"
local addon = _G[addonName]

local L = DataStore:GetLocale(addonName)
local TS = addon.TradeSkills.Names

if GetLocale() ~= "ruRU" then return end

-- This table contains a list of suggestions to get to the next level of reputation, craft or skill
addon.Suggestions = {

	-- source : http://forums.worldofwarcraft.com/thread.html?topicId=102789457&sid=1
	-- ** Primary professions **
	[TS.TAILORING] = {
		{ 50, "До 50: Рулон льняной ткани" },
		{ 70, "До 70: Льняная сумка" },
		{ 75, "До 75: Усиленная льняная накидка" },
		{ 105, "До 105: Рулон шерсти" },
		{ 110, "До 110: Серая шерстяная рубашка"},
		{ 125, "До 125: Шерстяные наплечники с двойным швом" },
		{ 145, "До 145: Рулон шелка" },
		{ 160, "До 160: Лазурный шелковый капюшон" },
		{ 170, "До 170: Шелковая головная повязка" },
		{ 175, "До 175: Церемониальная белая рубашка" },
		{ 185, "До 185: Рулон магической ткани" },
		{ 205, "До 205: Багровый шелковый жилет" },
		{ 215, "До 215: Багровые шелковые кюлоты" },
		{ 220, "До 220: Черные поножи из магической ткани\nили Черный жилет из магической ткани" },
		{ 230, "До 230: Черные перчатки из магической ткани" },
		{ 250, "До 250: Черная повязка из магической ткани\nили Черные наплечники из магической ткани" },
		{ 260, "До 260: Рулон рунической ткани" },
		{ 275, "До 275: Пояс из рунической ткани" },
		{ 280, "До 280: Сумка из рунической ткани" },
		{ 300, "До 300: Перчатки из рунической ткани" },
	},
	[TS.LEATHERWORKING] = {
		{ 35, "До 35: Накладки из тонкой кожи" },
		{ 55, "До 55: Обработанная легкая шкура" },
		{ 85, "До 85: Тисненые кожаные перчатки" },
		{ 100, "До 100: Тонкий кожаный пояс" },
		{ 120, "До 120: Обработанная средняя шкура" },
		{ 125, "До 125: Тонкий кожаный пояс" },
		{ 150, "До 150: Темный кожаный пояс" },
		{ 160, "До 160: Обработанная тяжелая шкура" },
		{ 170, "До 170: Накладки из толстой кожи" },
		{ 180, "До 180: Мглистые кожаные поножи\nили Штаны стража" },
		{ 195, "До 195: Варварские наплечники" },
		{ 205, "До 205: Мглистые наручи" },
		{ 220, "До 220: Накладки из плотной кожи" },
		{ 225, "До 225: Ночная головная повязка" },
		{ 250, "До 250: Зависит от вашей специализации\nНочная головная повязка/мундир/штаны (сила стихий)\nЖесткая кираса из чешуи скорпида/перчатки (чешуя дракона)\nКомплект из Черепашьего панциря (традиции предков)" },
		{ 260, "До 260: Ночные сапоги" },
		{ 270, "До 270: Гибельные кожаные рукавицы" },
		{ 285, "До 285: Гибельные кожаные наручи" },
		{ 300, "До 300: Гибельная кожаная головная повязка" },
	},
	[TS.ENGINEERING] = {
		{ 40, "До 40: Грубое взрывчатое вещество" },
		{ 50, "До 50: Горсть медных винтов" },
		{ 51, "Изготовьте один Тангенциальный вращатель" },
		{ 65, "До 65: Медные трубы" },
		{ 75, "До 75: Грубый огнестрел" },
		{ 95, "До 95: Низкосортное взрывчатое вещество" },
		{ 105, "До 105: Серебряные контакты" },
		{ 120, "До 120: Бронзовые трубкы" },
		{ 125, "До 125: Небольшие бронзовые бомбы" },
		{ 145, "До 145: Тяжелое взрывчатое вещество" },
		{ 150, "До 150: Большие бронзовые бомбы" },
		{ 175, "До 175: Синие, Зеленые или Красные петарды" },
		{ 176, "Изготовьте один Шлицевой гироинструмент" },
		{ 190, "До 190: Твердое взрывчатое вещество" },
		{ 195, "До 195: Большие железные бомбы" },
		{ 205, "До 205: Мифриловые трубы" },
		{ 210, "До 210: Нестабильные пусковые устройства" },
		{ 225, "До 225: Бронебойные мифриловые пули" },
		{ 235, "До 235: Мифриловую обшивку" },
		{ 245, "До 245: Фугасные бомбы" },
		{ 250, "До 250: Мифриловый гиро-патрон" },
		{ 260, "До 260: Концентрированное взрывчатое вещество" },
		{ 290, "До 290: Ториевое устройство" },
		{ 300, "До 300: Ториевые трубы\nили Ториевые патроны (дешевле)" },
	},
	[TS.ENCHANTING] = {
		{ 2, "До 2: Рунический медный жезл" },
		{ 75, "До 75: Чары для наручей - здоровье I" },
		{ 85, "До 85: Чары для наручей - отражение I" },
		{ 100, "До 100: Чары для наручей - выносливость I" },
		{ 101, "Изготовьте один Рунический серебряный жезл" },
		{ 105, "До 105: Чары для наручей - выносливость I" },
		{ 120, "До 120: Большой магический жезл" },
		{ 130, "До 130: Чары для щита - выносливость I" },
		{ 150, "До 150: Чары для наручей - выносливость II" },
		{ 151, "Изготовьте один Рунический золотой жезл" },
		{ 160, "До 160: Чары для наручей - выносливость II" },
		{ 165, "До 165: Чары для щита - выносливость II" },
		{ 180, "До 180: Чары для наручей - дух III" },
		{ 200, "До 200: Чары для наручей - сила III" },
		{ 201, "Изготовьте один Рунический жезл истинного серебра" },
		{ 205, "До 205: Чары для наручей - сила III" },
		{ 225, "До 225: Чары для плаща - защита II" },
		{ 235, "До 235: Чары для перчаток - ловкость I" },
		{ 245, "До 245: Чары для нагрудника - здоровье V" },
		{ 250, "До 250: Чары для наручей - сила IV" },
		{ 270, "До 270: Простое масло маны\nРецепт продается в Силитусе" },
		{ 290, "До 290: Чары для щита - выносливость IV\nили Чары для обуви - выносливость IV" },
		{ 291, "Изготовьте один Рунический арканитовый жезл" },
		{ 300, "До 300: Чары для плаща - защита III" },
	},
	[TS.BLACKSMITHING] = {	
		{ 25, "До 25: Rough Sharpening Stones" },
		{ 45, "До 45: Rough Grinding Stones" },
		{ 75, "До 75: Copper Chain Belt" },
		{ 80, "До 80: Coarse Grinding Stones" },
		{ 100, "До 100: Runed Copper Belt" },
		{ 105, "До 105: Silver Rod" },
		{ 125, "До 125: Rough Bronze Leggings" },
		{ 150, "До 150: Heavy Grinding Stone" },
		{ 155, "До 155: Golden Rod" },
		{ 165, "До 165: Green Iron Leggings" },
		{ 185, "До 185: Green Iron Bracers" },
		{ 200, "До 200: Golden Scale Bracers" },
		{ 210, "До 210: Solid Grinding Stone" },
		{ 215, "До 215: Golden Scale Bracers" },
		{ 235, "До 235: Steel Plate Helm\nor Mithril Scale Bracers (cheaper)\nRecipe in Aerie Peak (A) or Stonard (H)" },
		{ 250, "До 250: Mithril Coif\nor Mothril Spurs (cheaper)" },
		{ 260, "До 260: Dense Sharpening Stones" },
		{ 270, "До 270: Thorium Belt or Bracers (cheaper)\nEarthforged Leggings (Armorsmith)\nLight Earthforged Blade (Swordsmith)\nLight Emberforged Hammer (Hammersmith)\nLight Skyforged Axe (Axesmith)" },
		{ 295, "До 295: Imperial Plate Bracers" },
		{ 300, "До 300: Imperial Plate Boots" },
	},
	[TS.ALCHEMY] = {	
		{ 60, "До 60: Minor Healing Potion" },
		{ 110, "До 110: Lesser Healing Potion" },
		{ 140, "До 140: Healing Potion" },
		{ 155, "До 155: Lesser Mana Potion" },
		{ 185, "До 185: Greater Healing Potion" },
		{ 210, "До 210: Elixir of Agility" },
		{ 215, "До 215: Elixir of Greater Defense" },
		{ 230, "До 230: Superior Healing Potion" },
		{ 250, "До 250: Elixir of Detect Undead" },
		{ 265, "До 265: Elixir of Greater Agility" },
		{ 285, "До 285: Superior Mana Potion" },
		{ 300, "До 300: Major Healing Potion" },
	},
	[L["Mining"]] = {
		{ 65, "До 65: Mine Copper\nAvailable in all starting zones" },
		{ 125, "До 125: Mine Tin, Silver, Incendicite and Lesser Bloodstone\n\nMine Incendicite at Thelgen Rock (Wetlands)\nEasy leveling up to 125" },
		{ 175, "До 175: Mine Iron and Gold\nDesolace, Ashenvale, Badlands, Arathi Highlands,\nAlterac Mountains, Stranglethorn Vale, Swamp of Sorrows" },
		{ 250, "До 250: Mine Mithril and Truesilver\nBlasted Lands, Searing Gorge, Badlands, The Hinterlands,\nWestern Plaguelands, Azshara, Winterspring, Felwood, Stonetalon Mountains, Tanaris" },
		{ 275, "До 275: Mine Thorium \nUn’goro Crater, Azshara, Winterspring, Blasted Lands\nSearing Gorge, Burning Steppes, Eastern Plaguelands, Western Plaguelands" },
		{ 330, "До 330: Mine Fel Iron\nHellfire Peninsula, Zangarmarsh" },
	},
	[L["Herbalism"]] = {
		{ 50, "До 50: Собираем Сребролист и Мироцвет\nДоступны в начальных зонах" },
		{ 70, "До 70: Собираем Магороза и Земляной корень\nСтепи, Западный Край, Серебряный бор, Лок Модан" },
		{ 100, "До 100: Собираем Остротерн\nСеребряный бор, Сумеречный лес, Темные берега,\nЛок Модан, Красногорье" },
		{ 115, "До 115: Собираем Синячник\nЯсеневый лес, Когтистые горы, Южные степи\nЛок Модан, Красногорье" },
		{ 125, "До 125: Собираем Дикий сталецвет\nКогтистые горы, Нагорье Арати, Тернистая долина\nЮжные степи, Тысяча Игл" },
		{ 160, "До 160: Собираем Королевская кровь\nЯсеневый лес, Когтистые горы, Болотина,\nПредгорья Хилсбрада, Болото Печали" },
		{ 185, "До 185: Собираем Бледнолист\nБолото Печали" },
		{ 205, "До 205: Собираем Кадгаров ус\nВнутренние земли, Нагорье Арати, Болото Печали" },
		{ 230, "До 230: Собираем Огнецвет\nТлеющее ущелье, Выжженные земли, Танарис" },
		{ 250, "До 250: Собираем Солнечник\nОскверненный лес, Фералас, Азшара\nВнутренние земли" },
		{ 270, "До 270: Собираем Кровь Грома\nОскверненный лес, Выжженные земли,\nMannoroc Coven in Пустоши" },
		{ 285, "До 285: Собираем Снолист\nКратер Ун'Горо, Азшара" },
		{ 300, "До 300: Собираем Чумоцвет\nВосточные и Западные Чумные земли, Оскверненный лес\nили Ледяной зев в Зимних Ключах" },
	},
	[L["Skinning"]] = {
		{ 300, "До 300: Разделите ваш текущий уровень на 5,\nи снемайте шкуру с животных полученного уровня" }
	},

	-- source: http://www.almostgaming.com/wowguides/world-of-warcraft-lockpicking-guide
	[L["Lockpicking"]] = {
		{ 85, "До 85: Thieves Training\nAtler Mill, Redridge Moutains (A)\nShip near Ratchet (H)" },
		{ 150, "До 150: Chest near the boss of the poison quest\nWestfall (A) or The Barrens (H)" },
		{ 185, "До 185: Murloc camps (Wetlands)" },
		{ 225, "До 225: Sar'Theris Strand (Desolace)\n" },
		{ 250, "До 250: Angor Fortress (Badlands)" },
		{ 275, "До 275: Slag Pit (Searing Gorge)" },
		{ 300, "До 300: Lost Rigger Cove (Tanaris)\nBay of Storms (Azshara)" },
	},
	
	-- ** Secondary professions **
	[TS.COOKING] = {
		{ 40, "До 40: Хлеб с пряностями"	},
		{ 85, "До 85: Копченая медвежатина, Пирожок с мясом краба" },
		{ 100, "До 100: Cooked Crab Claw (A)\nDig Rat Stew (H)" },
		{ 125, "До 125: Dig Rat Stew (H)\nSeasoned Wolf Kabob (A)" },
		{ 175, "До 175: Curiously Tasty Omelet (A)\nHot Lion Chops (H)" },
		{ 200, "До 200: Roast Raptor" },
		{ 225, "До 225: Spider Sausage\n\n|cFFFFFFFFCooking quest:\n|cFFFFD70012 Giant Eggs,\n10 Zesty Clam Meat,\n20 Alterac Swiss " },
		{ 275, "До 275: Monster Omelet\nor Tender Wolf Steaks" },
		{ 285, "До 285: Runn Tum Tuber Surprise\nDire Maul (Pusillin)" },
		{ 300, "До 300: Smoked Desert Dumplings\nQuest in Silithus" },
	},	
	-- source: http://www.wowguideonline.com/fishing.html
	[TS.FISHING] = {
		{ 50, "До 50: Любая начальная зона" },
		{ 75, "До 75:\nВ каналах Штормграда\nВ прудах Оргриммара" },
		{ 150, "До 150: В реке Предгорья Хилсбрада" },
		{ 225, "До 225: Книга Рыболов-умелец продается в Пиратской бухте\nРыбачьте в Пустоши или Нагорьях Арати" },
		{ 250, "До 250: Внутренние земли, Танарис\n\n|cFFFFFFFFРыболовное задание в Пылевых топях\n|cFFFFD700Синий плавник Гибельного берега (Тернистая долина)\nФералас-ахи (Река Вердантис, Фералас)\nУдарник Сартериса (Северное побережье Сар'Терис, Пустоши)\nМахи-махи с Тростникового берега (Береговая линия Болот Печали)" },
		{ 260, "До 260: Оскверненный лес" },
		{ 300, "До 300: Азшара" },
	},
	
	-- suggested leveling zones, as defined by recommended quest levels. map id's : http://wowpedia.org/MapID
	-- ["Leveling"] = {
		-- { 10, "До 10: Любая начальная зона" },
		-- { 15, "До 15: " .. C_Map.GetMapInfo(39).name},
		-- { 16, "До 16: " .. C_Map.GetMapInfo(684).name},
		-- { 20, "До 20: " .. C_Map.GetMapInfo(181).name .. "\n" .. C_Map.GetMapInfo(35).name .. "\n" .. C_Map.GetMapInfo(476).name
							-- .. "\n" .. C_Map.GetMapInfo(42).name .. "\n" .. C_Map.GetMapInfo(21).name .. "\n" .. C_Map.GetMapInfo(11).name
							-- .. "\n" .. C_Map.GetMapInfo(463).name .. "\n" .. C_Map.GetMapInfo(36).name},
		-- { 25, "До 25: " .. C_Map.GetMapInfo(34).name .. "\n" .. C_Map.GetMapInfo(40).name .. "\n" .. C_Map.GetMapInfo(43).name 
							-- .. "\n" .. C_Map.GetMapInfo(24).name},
		-- { 30, "До 30: " .. C_Map.GetMapInfo(16).name .. "\n" .. C_Map.GetMapInfo(37).name .. "\n" .. C_Map.GetMapInfo(81).name},
		-- { 35, "До 35: " .. C_Map.GetMapInfo(673).name .. "\n" .. C_Map.GetMapInfo(101).name .. "\n" .. C_Map.GetMapInfo(26).name
							-- .. "\n" .. C_Map.GetMapInfo(607).name},
		-- { 40, "До 40: " .. C_Map.GetMapInfo(141).name .. "\n" .. C_Map.GetMapInfo(121).name .. "\n" .. C_Map.GetMapInfo(22).name},
		-- { 45, "До 45: " .. C_Map.GetMapInfo(23).name .. "\n" .. C_Map.GetMapInfo(61).name},
		-- { 48, "До 48: " .. C_Map.GetMapInfo(17).name},
		-- { 50, "До 50: " .. C_Map.GetMapInfo(161).name .. "\n" .. C_Map.GetMapInfo(182).name .. "\n" .. C_Map.GetMapInfo(28).name},
		-- { 52, "До 52: " .. C_Map.GetMapInfo(29).name},
		-- { 54, "До 54: " .. C_Map.GetMapInfo(38).name},
		-- { 55, "До 55: " .. C_Map.GetMapInfo(201).name .. "\n" .. C_Map.GetMapInfo(281).name},
		-- { 58, "До 58: " .. C_Map.GetMapInfo(19).name},
		-- { 60, "До 60: " .. C_Map.GetMapInfo(32).name .. "\n" .. C_Map.GetMapInfo(241).name .. "\n" .. C_Map.GetMapInfo(261).name},
	-- },
}

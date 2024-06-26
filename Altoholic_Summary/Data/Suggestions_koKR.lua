local addonName = "Altoholic"
local addon = _G[addonName]

local L = DataStore:GetLocale(addonName)
local TS = addon.TradeSkills.Names

if GetLocale() ~= "koKR" then return end

-- This table contains a list of suggestions to get to the next level of reputation, craft or skill
addon.Suggestions = {

	-- source : http://forums.worldofwarcraft.com/thread.html?topicId=102789457&sid=1
	-- ** Primary professions **
	[TS.TAILORING] = {
		{ 50, "50 까지: 리넨 두루마리" },
		{ 70, "70 까지: 리넨 가방" },
		{ 75, "75 까지: 질긴 리넨 단망토" },
		{ 105, "105 까지: 양모 두루마리" },
		{ 110, "110 까지: 회색 양모 셔츠"},
		{ 125, "125 까지: 이중 양모 어깨보호구" },
		{ 145, "145 까지: 비단 두루마리" },
		{ 160, "160 까지: 감청색 비단 두건" },
		{ 170, "170 까지: 비단 머리띠" },
		{ 175, "175 까지: 흰색 정장 셔츠" },
		{ 185, "185 까지: 마법 두루마리" },
		{ 205, "205 까지: 심홍색 비단 조끼" },
		{ 215, "215 까지: 심홍색 비단 바지" },
		{ 220, "220 까지: 검은 마법매듭 다리보호구\n또는 검은 마법매듭 조끼" },
		{ 230, "230 까지: 검은 마법매듭 장갑" },
		{ 250, "250 까지: 검은 마법매듭 머리띠\n또는 검은 마법매듭 어깨보호구" },
		{ 260, "260 까지: 룬무늬 두루마리" },
		{ 275, "275 까지: 룬무늬 허리띠" },
		{ 280, "280 까지: 룬매듭 가방" },
		{ 300, "300 까지: 룬매듭 장갑" },
	},
	[TS.LEATHERWORKING] = {
		{ 35, "35 까지: 작은 방어구 키트" },
		{ 55, "55 까지: 얇은 경화 가죽" },
		{ 85, "85 까지: 새김무늬 가죽 장갑" },
		{ 100, "100 까지: 고급 가죽 허리띠" },
		{ 120, "120 까지: 일반 경화 가죽" },
		{ 125, "125 까지: 고급 가죽 허리띠" },
		{ 150, "150 까지: 암색 가죽 허리띠" },
		{ 160, "160 까지: 질긴 경화 가죽" },
		{ 170, "170 까지: 고급 방어구 키트" },
		{ 180, "180 까지: 거무스름한 가죽 다리보호구\n또는 수호 바지" },
		{ 195, "195 까지: 야만전사의 어깨보호구" },
		{ 205, "205 까지: 거무스름한 팔보호구" },
		{ 220, "220 까지: 두꺼운 방어구 키트" },
		{ 225, "225 까지: 밤하늘 머리띠" },
		{ 250, "250 까지: 선택한 전문화에 따라\n(원소)밤하늘 머리띠/튜닉/바지\n(용비늘)단단한 전갈 흉갑/장갑\n(전통)거북 껍질 세트" },
		{ 260, "260 까지: 밤하늘 장화" },
		{ 270, "270 까지: 악의의 가죽 건틀릿" },
		{ 285, "285 까지: 악의의 가죽 팔보호구" },
		{ 300, "300 까지: 악의의 가죽 머리띠" },
	},
	[TS.ENGINEERING] = {
		{ 40, "40 까지: 천연 화약" },
		{ 50, "50 까지: 구리 나사 한 줌" },
		{ 51, "만능 스패너 하나 제작" },
		{ 65, "65 까지: 구리관" },
		{ 75, "75 까지: 조잡한 붐스틱" },
		{ 95, "95 까지: 굵은 화약" },
		{ 105, "105 까지: 은 접지" },
		{ 120, "120 까지: 청동관" },
		{ 125, "125 까지: 소형 청동 폭탄" },
		{ 145, "145 까지: 강한 화약" },
		{ 150, "150 까지: 대형 청동 폭탄" },
		{ 175, "175 까지: 푸른, 녹색, 또는 붉은 폭죽" },
		{ 176, "자동회전 초정밀조율기 하나 제작" },
		{ 190, "190 까지: 조밀한 화약" },
		{ 195, "195 까지: 대형 철제 폭탄" },
		{ 205, "205 까지: 미스릴관" },
		{ 210, "210 까지: 유동성 제동장치" },
		{ 225, "225 까지: 고강도 미스릴 산탄" },
		{ 235, "235 까지: 미스릴 형틀" },
		{ 245, "245 까지: 고폭탄" },
		{ 250, "250 까지: 미스릴 회전탄" },
		{ 260, "260 까지: 강도 높은 화약" },
		{ 290, "290 까지: 토륨 부품" },
		{ 300, "300 까지: 토륨관\n또는 토륨 탄환 (더 저렴)" },
	},
	[TS.ENCHANTING] = {
		{ 2, "2 까지: 룬문자 구리마법막대" },
		{ 75, "75 까지: 손목보호구 마법부여 - 최하급 생명력" },
		{ 85, "85 까지: 손목보호구 마법부여 - 최하급 회피" },
		{ 100, "100 까지: 손목보호구 마법부여 - 최하급 체력" },
		{ 101, "룬문자 은마법막대 하나 제작" },
		{ 105, "105 까지: 손목보호구 마법부여 - 최하급 체력" },
		{ 120, "120 까지: 상급 마술봉" },
		{ 130, "130 까지: 방패 마법부여 - 최하급 체력" },
		{ 150, "150 까지: 손목보호구 마법부여 - 하급 체력" },
		{ 151, "룬문자 금마법막대 하나 제작" },
		{ 160, "160 까지: 손목보호구 마법부여 - 하급 체력" },
		{ 165, "165 까지: 방패 마법부여 - 하급 체력" },
		{ 180, "180 까지: 손목보호구 마법부여 - 정신력" },
		{ 200, "200 까지: 손목보호구 마법부여 - 힘" },
		{ 201, "룬문자 진은마법막대 하나 제작" },
		{ 205, "205 까지: 손목보호구 마법부여 - 힘" },
		{ 225, "225 까지: 망토 마법부여 - 상급 보호" },
		{ 235, "235 까지: 장갑 마법부여 - 민첩성" },
		{ 245, "245 까지: 가슴보호구 마법부여 - 최상급 생명력" },
		{ 250, "250 까지: 손목보호구 마법부여 - 상급 힘" },
		{ 270, "270 까지: 하급 마나 오일\n주문식은 실리더스에서 판매" },
		{ 290, "290 까지: 방패 마법부여 - 상급 체력\n또는 장화 마법부여 - 상급 체력" },
		{ 291, "룬문자 아케이나이트막대 하나 제작" },
		{ 300, "300 까지: 망토 마법부여 - 최상급 보호" },
	},
	[TS.BLACKSMITHING] = {	
		{ 25, "25 까지: 조잡한 숫돌" },
		{ 45, "45 까지: 조잡한 연마석" },
		{ 75, "75 까지: 구리 사슬 허리띠" },
		{ 80, "80 까지: 일반 연마석" },
		{ 100, "100 까지: 구리 룬문자 허리띠" },
		{ 105, "105 까지: 은마법막대" },
		{ 125, "125 까지: 청동 다리보호구" },
		{ 150, "150 까지: 단단한 연마석" },
		{ 155, "155 까지: 금마법막대" },
		{ 165, "165 까지: 녹색 철제 다리보호구" },
		{ 185, "185 까지: 녹색 철제 팔보호구" },
		{ 200, "200 까지: 황금 미늘 팔보호구" },
		{ 210, "210 까지: 견고한 연마석" },
		{ 215, "215 까지: 황금 미늘 팔보호구" },
		{ 235, "235 까지: 강철 판금 투구\n또는 미스릴 미늘 팔보호구 (더 저렴)\n제조법은 맹금의 봉우리(얼) 또는 스토나드(호)" },
		{ 250, "250 까지: 미스릴 코이프\n또는 미스릴 박차 (더 저렴)" },
		{ 260, "260 까지: 강도 톺은 숫돌" },
		{ 270, "270 까지: 토륨 허리띠 또는 팔보호구 (더 저렴)\n대지로 벼려낸 다리보호구(갑옷전문)\n대지로 벼려낸 검(검전문)\n불꽃으로 벼려낸 망치(둔기전문)\n하늘로 벼려낸 도끼(도끼전문)" },
		{ 295, "295 까지: 황제의 판금 팔보호구" },
		{ 300, "300 까지: 황제의 판금 장화" },
	},
	[TS.ALCHEMY] = {	
		{ 60, "60 까지: 최하급 치유 물약" },
		{ 110, "110 까지: 하급 치유 물약" },
		{ 140, "140 까지: 치유 물약" },
		{ 155, "155 까지: 하급 마나 물약" },
		{ 185, "185 까지: 상급 치유 물약" },
		{ 210, "210 까지: 민첩의 비약" },
		{ 215, "215 까지: 상급 방어의 비약" },
		{ 230, "230 까지: 최상급 치유 물약" },
		{ 250, "250 까지: 언데드 감지의 비약" },
		{ 265, "265 까지: 상급 민첩의 비약" },
		{ 285, "285 까지: 최상급 마나 물약" },
		{ 300, "300 까지: 일급 치유 물약" },
	},
	[L["Mining"]] = {
		{ 65, "65 까지: 구리 채광\n모든 시작 지역에서 가능" },
		{ 125, "125 까지: 주석, 은, Incendicite, 하급 혈석 채광\n\nMine Incendicite at Thelgen Rock (저습지)\n125 까지 쉽게 향상" },
		{ 175, "175 까지: 철, 금 채광\n잊혀진 땅, 잿빛 골짜기, 황야의 땅, 아라시 고원,\n알터랙 산맥, 가시덤불 골짜기, 슬픔의 늪" },
		{ 250, "250 까지: 미스릴, 진은 채광\n저주받은 땅, 이글거리는 협곡, 황야의 땅, 동부 내륙지,\n서부 역병지대, 아즈샤라, 여명의 설원, 악령의 숲, 돌발톱 산맥, 타나리스" },
		{ 275, "275 까지: 토륨 채광\n운고로 분화구, 아즈샤라, 여명의 설원, 저주받은 땅\n이글거리는 협곡, 불타는 평원, 동부 역병지대, 서부 역병지대" },
		{ 330, "330 까지: 지옥무쇠 채광\n지옥불 반도, 장가르 습지대" },
	},
	[L["Herbalism"]] = {
		{ 50, "50 까지: 은엽수, 평온초 채집\n모든 시작 지역에서 가능" },
		{ 70, "70 까지: 마법초, 뱀뿌리 채집\n불모의 땅, 서부 몰락지대, 은빛소나무 숲, 모단 호수" },
		{ 100, "100 까지: 찔레가시 채집\n은빛소나무 숲, 그늘숲, 어둠의 해안,\n모단 호수, 붉은마루 산맥" },
		{ 115, "115 까지: 생채기풀 채집\n잿빛 골짜기, 돌발톱 산맥, 남부 불모의 땅\n모단 호수, 붉은마루 산맥" },
		{ 125, "125 까지: 야생 철쭉 채집\n돌발톱 산맥, 아라시 고원, 가시덤불 골짜기\n남부 불모의 땅, 버섯구름 봉우리" },
		{ 160, "160 까지: 왕꽃잎풀 채집\n잿빛 골짜기, 돌발톱 산맥, 저습지,\n언덕마루 구릉지, 슬픔의 늪" },
		{ 185, "185 까지: 미명초 채집\n슬픔의 늪" },
		{ 205, "205 까지: 카드가의 수염 채집\n동부 내륙지, 아라시 고원, 슬픔의 늪" },
		{ 230, "230 까지: 화염초 채집\n이글거리는 협곡, 저주받은 땅, 타나리스" },
		{ 250, "250 까지: 태양풀 채집\n악령의 숲, 페랄라스, 아즈샤라\n동부 내륙지" },
		{ 270, "270 까지: 그롬의 피 채집\n악령의 숲, 저주받은 땅,\nMannoroc Coven in 잊혀진 땅" },
		{ 285, "285 까지: 꿈풀 채집\n운고로 분화구, 아즈샤라" },
		{ 300, "300 까지: 역병초 채집\n동부 및 서부 역병지대, 악령의 숲\nor Icecaps in 여명의 설원" },
	},
	[L["Skinning"]] = {
		{ 300, "300 까지: 현재 숙련도 나누기 5\n 한 레벨의 몹 무두질" }
	},

	-- source: http://www.almostgaming.com/wowguides/world-of-warcraft-lockpicking-guide
	[L["Lockpicking"]] = {
		{ 75, "75 까지: 15 레벨 까지" },
		{ 125, "125 까지: 25 레벨 까지" },
		{ 175, "175 까지: 35 레벨 까지" },
		{ 200, "250 까지: 40 레벨 까지" },
		{ 225, "225 까지: 45 레벨 까지" },
		{ 275, "275 까지: 55 레벨 까지" },
		{ 300, "300 까지: 60 레벨 까지" },
	},
	
	-- ** Secondary professions **
	[TS.COOKING] = {
		{ 40, "40 까지: 매콤한 빵"	},
		{ 85, "85 까지: 곰고기 숯불구이, 게살 케이크" },
		{ 100, "100 까지: 집게발 요리 (얼)\n들쥐 스튜 (호)" },
		{ 125, "125 까지: 들쥐 스튜 (호)\n양념 늑대 케밥 (얼)" },
		{ 175, "175 까지: 진기한 맛의 오믈렛 (얼)\n매운 사자 고기 (호)" },
		{ 200, "200 까지: 랩터 숯불구이" },
		{ 225, "225 까지: 거미 소시지\n\n|cFFFFFFFF요리 퀘스트:\n|cFFFFD70012 거대한 알,\n10 고소한 조개살,\n20 알터렉 스위스 " },
		{ 275, "275 까지: 괴물 오믈렛\n또는 연한 늑대 스테이크" },
		{ 285, "285 까지: 룬툼 줄기 별미\n혈투의 전장 (푸실린)" },
		{ 300, "300 까지: 훈제 사막 경단\n실리더스에서 퀘스트" },
	},	
	-- source: http://www.wowguideonline.com/fishing.html
	[TS.FISHING] = {
		{ 50, "50 까지: 모든 시작 지역" },
		{ 75, "75 까지:\n스톰윈드 안 운하\n오그리마 안 연못" },
		{ 150, "150 까지: 언덕마루 구릉지' 강" },
		{ 225, "225 까지: 숙련 낚시\n잊혀진 땅 또는 아라시 고원에서 낚시" },
		{ 250, "250 까지: 동부 내륙지, 타나리스\n\n|cFFFFFFFFFishing quest in 먼지진흙 슾지대\n|cFFFFD700Savage Coast Blue Sailfin (가시덤불 골짜기)\n페랄라스 Ahi (Verdantis River, 페랄라스)\nSer'theris Striker (Northern Sartheris Strand, 잊혀진 땅)\nMisty Reed Mahi Mahi (슬픔의 늪 해변)" },
		{ 260, "260 까지: 악령의 숲" },
		{ 300, "300 까지: 아즈샤라" },
	},
			
	-- suggested leveling zones, as defined by recommended quest levels. map id's : http://wowpedia.org/MapID
	-- ["Leveling"] = {
		-- { 10, "10 까지: 모든 시작 지역" },
		-- { 15, "15 까지: " .. C_Map.GetMapInfo(39).name},
		-- { 16, "16 까지: " .. C_Map.GetMapInfo(684).name},
		-- { 20, "20 까지: " .. C_Map.GetMapInfo(181).name .. "\n" .. C_Map.GetMapInfo(35).name .. "\n" .. C_Map.GetMapInfo(476).name
							-- .. "\n" .. C_Map.GetMapInfo(42).name .. "\n" .. C_Map.GetMapInfo(21).name .. "\n" .. C_Map.GetMapInfo(11).name
							-- .. "\n" .. C_Map.GetMapInfo(463).name .. "\n" .. C_Map.GetMapInfo(36)},
		-- { 25, "25 까지: " .. C_Map.GetMapInfo(34).name .. "\n" .. C_Map.GetMapInfo(40).name .. "\n" .. C_Map.GetMapInfo(43).name
							-- .. "\n" .. C_Map.GetMapInfo(24).name},
		-- { 30, "30 까지: " .. C_Map.GetMapInfo(16).name .. "\n" .. C_Map.GetMapInfo(37).name .. "\n" .. C_Map.GetMapInfo(81).name},
		-- { 35, "35 까지: " .. C_Map.GetMapInfo(673).name .. "\n" .. C_Map.GetMapInfo(101).name .. "\n" .. C_Map.GetMapInfo(26).name
							-- .. "\n" .. C_Map.GetMapInfo(607).name},
		-- { 40, "40 까지: " .. C_Map.GetMapInfo(141).name .. "\n" .. C_Map.GetMapInfo(121).name .. "\n" .. C_Map.GetMapInfo(22).name},
		-- { 45, "45 까지: " .. C_Map.GetMapInfo(23).name .. "\n" .. C_Map.GetMapInfo(61).name},
		-- { 48, "48 까지: " .. C_Map.GetMapInfo(17).name},
		-- { 50, "50 까지: " .. C_Map.GetMapInfo(161).name .. "\n" .. C_Map.GetMapInfo(182).name .. "\n" .. C_Map.GetMapInfo(28).name},
		-- { 52, "52 까지: " .. C_Map.GetMapInfo(29).name},
		-- { 54, "54 까지: " .. C_Map.GetMapInfo(38).name},
		-- { 55, "55 까지: " .. C_Map.GetMapInfo(201).name .. "\n" .. C_Map.GetMapInfo(281).name},
		-- { 58, "58 까지: " .. C_Map.GetMapInfo(19).name},
		-- { 60, "60 까지: " .. C_Map.GetMapInfo(32).name .. "\n" .. C_Map.GetMapInfo(241).name .. "\n" .. C_Map.GetMapInfo(261).name},
	-- },
}

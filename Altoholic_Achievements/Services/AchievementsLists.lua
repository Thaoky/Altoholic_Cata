local addonName = "Altoholic"
local addon = _G[addonName]

-- From DataStore_Achievements\Enum.lua
local cat = DataStore.Enum.AchievementCategories

--[[
How to read and modify the lists below:

The achievement categories displayed in the add-on are the combination of data found in the 2 tables sortedAchievements & unsortedAchievements.

A given category can be present in just sortedAchievements (if the list is fully sorted) or in both tables.
When data is present in both tables, achievements will be displayed using the following rule:

- First all sorted achievements will be displayed in the specified order.
- Then the remaining achievements from the unsorted list will be added in alphabetical order (based on their name in-game)
=> this implies that the unsorted achievements will be displayed in a different order based on the localization.

Information about factions :

- All achievements that are not faction specific (most of them), are entered as numbers in the tables.
- If an achievement exists for both factions (i.e. with 2 different id's), then it is represented as a string
in the following format "alliance id : horde id", always with the alliance id first.

Note: this rules applies for achievements that are really identical, same objective, same achievement name.

There are some achievements that are identical for both factions, but that bear different names, so treat them separately !

--]]

local sortedAchievements = {
	-- levels, got my mind on my money, riding skill, mounts, pets, tabards, superior items
	[cat.Character] = { 6,7,8,9,10,11,12,13,4826,1176,1177,1178,1180,1181,5455,
		891, 889, 890, 892,
		2141, 2142, 2143, "2536:2537", 1017, 15, 1248, 1250, 2516, 5876, 5877, 5875,
		621,1020,1021 },

	-- Quests
	[cat.Quests] = { 503,504,505,506,507,508,32,978,973,974,975,976,977 },		-- quests completed,  daily quests completed
	[cat.QuestsEasternKingdoms] = { "1676:1677", 4896, 4900, 4909, 4901, 4905, 4907, 4892, 4908, 4895, 4897, 4899, 4906, 4902,
		4910, 4894, 4904, 4893, 4903 },
	[cat.QuestsKalimdor] = { "1678:1680", "4925:4976", 4927, 4926, 4928, 4930, "4929:4978", 4931, "4932:4979", 4933, 4934,
		"4937:4981", "4936:4980", 4935, 4938, 4939, 4940 },
	[cat.QuestsOutland] = { "1262:1274","1189:1271",1190,"1191:1272","1192:1273",1193,1194,1195,1275,939,1276 },
	[cat.QuestsNorthrend] = { "41:1360","33:1358","34:1356","35:1359","37:1357",36,39,38,40 },
	[cat.QuestsCataclysm] = { 4875, 4870, "4869:4982", 4871, 4872, "4873:5501" },
	
	-- Exploration
	[cat.Exploration] = { 42, 43, 44, 45, 4868, 46 },
	[cat.ExplorationEasternKingdoms] = { 761, 765, 766, 775, 777, 627, 778, 771, 776, 859, 858, 772, 868, 779, 781, 780, 774,
		769, 782, 4995, 773, 768, 770, 802, 841, 1206 },
	[cat.ExplorationKalimdor] = { 845, 852, 860, 861, 844, 848, 728, 850, 853, 849, 855, 736, 750, 856, 4996, 847, 851, 842,
		846, 854, 857 },
	[cat.ExplorationOutland] = { 862, 863, 867, 866, 865, 843, 864, 1311, 1312 },
	[cat.ExplorationNorthrend] = { 1254, 1263, 1264, 1265, 1266, 1267, 1457, 1268, 1269, 1270, 1956, 2256, 2257, 2557 },
	[cat.ExplorationCataclysm] = { 4863, 4825, 4864, 4865, 4866, 4975, 5518, 4827 },

	[cat.PvP] = { 238,513,515,516,512,509,239,869,870 },				-- honorable kills
	[cat.PvPArena] = { 397,398,875,876,399,400,401,1159,402,403,405,1160,406,407,404,1161 },
	[cat.PvPWintergrasp] = { 2085,2086,2087,2088,2089 },			-- Stone keeper shards
	[cat.PvPEyeOfTheStorm] = { 208, 209, 1171 },
	[cat.PvPBattleForGilneas] = { 5245, 5246, 5258 },
	[cat.PvPTwinPeaks] = { 5208, 5209, 5223 },
	[cat.PvPRatedBattleground] = { 5269, 5323, 5324, 5325, 5824, 5326, 5345, 5346, 5347, 5348, 5349, 5350, 5351, 5352, 5338,
		5353, 5354, 5355, 5342, 5356, 5268, 5322, 5327, 5328, 5823, 5329, 5330, 5331, 5332, 5333, 5334, 5335, 5336, 5337,
		5359, 5339, 5340, 5341, 5357, 5343 },
	[cat.ExpansionFeaturesTolBarad] = { 5412, "5417:5418", "5489:5490", 5416, 6045, 6108 },
	
	[cat.Dungeons] = { 3844,4316,1283,1285,1284,1287,1286,1288,1289,2136,2137,2138,1658,2957,2958,4016,4017,4602,4603,4476,4477,4478 },
	[cat.DungeonsClassic] = { 629, 628, 630, 631, 632, 633, 635, 634, 636, 637, 638, 639, 640, 641, 642, 643, 644, 645, 646, 1307, 689, 686, 685, 687, 2188 },
	[cat.DungeonsBurningCrusade] = { 647, 667, 648, 668, 649, 669, 650, 670, 651, 671, 666, 672, 652, 673, 653, 674, 654,
		675, 655, 676, 656, 677, 657, 678, 658, 679, 659, 680, 660, 681, 661, 682, 690, 692, 693, 694, 696, 695, 697, 698 },	
	
	[cat.DungeonsCrusade10] = { 3808,3809,3810,4080 },
	[cat.DungeonsCrusade25] = { 3817,3818,3819 },
	[cat.Professions] = { 116,731,732,733,734 },							-- professional journeyman, etc..
	[cat.ProfessionsCooking] = { 121,122,123,124,125,4916,1999,2000,2001,2002,1795,1796,1797,1798,1799,5471,1777,1778,1779, 5472,5473 },			-- level, dalaran awards, num recipes, northrend gourmet
	[cat.ProfessionsFishing] = { 126,127,128,129,130,4917,1556,1557,1558,1559,1560,1561,2094,2095,1957,2096 },						-- level, num fishes, dalaran coins
	[cat.ProfessionsFirstAid] = { 131,132,133,134,135,4918,5480 },					-- journeyman, expert, artisan, master, grand master
	[cat.ProfessionsArchaeology] = { 4857, 4919, 4920, 4921, 4922, 4923, 4858, 4859, 5191, 5192, 5193, 5301, 5511 },
	
	[cat.Reputations] = { 522,523,524,521,520,519,518,1014,1015 },		-- exalted reputations
	[cat.WorldEventsLunarFestival] = { 605,606,607,608,609 },				-- coins of ancestry
	[cat.ExpansionFeaturesArgentTournament] = { 2756,2758,2777,2760,2779,2762,2780,2763,2781,2764,2778,2761,2782,2770,2817,2783,2765,2784,2766,2785,2767,2786,2768,2787,2769,2788,2771,2816 },
}

local unsortedAchievements = {
	[cat.Character] = { 16,545,546,556,557,558,559,705,964,1165,1206,1244,1254,1832,1833,1956,2076,2077,2078,2084,2097,2556,2557,2716 },
	[cat.Quests] = { 31,941,1182,1576,"1681:1682" },
	[cat.QuestsEasternKingdoms] = { 5442, 5444, 940 },
	[cat.QuestsKalimdor] = { 5453, 5454, 5443, 5446, 5447, 5448 },
	[cat.QuestsNorthrend] = { 547,561,938,961,962,1277,1428,1596 },
	[cat.QuestsCataclysm] = { 4874, "5318:5319", 4959, 5483, 5451, 5482, 5450, 5445, 5317, 4961, 5447, 5449, 4960, 5446,
		5452, 5481, "5320:5321", 5859, 5860, 5861, 5862, 5864, 5865, 5866, 5867, 5868, 5869, 5870, 5871, 5872, 5873, 5874, 5879 },
	
--	[cat.ExplorationOutland] = fully sorted
--	[cat.ExplorationNorthrend] = fully sorted
	[cat.PvP] = { 227,229,"230:1175",231,245,"246:1005",247,"388:1006",389,396,603,604,610,611,612,613,614,615,616,617,618,619,700,701,714,727,907,"908:909",1157,"2016:2017" },
	[cat.PvPArena] = { 408,409,699,1162,1174,2090,2091,2092,2093 },
	[cat.PvPAlteracValley] = { 221,582,219,218,"225:1164",706,873,708,709,"224:1151","1167:1168",707,220,226,223,1166,222 },
	[cat.PvPArathi] = { 583,584,165,155,154,73,711,159,"1169:1170",158,1153,161,156,710,157,162 },
	[cat.PvPEyeOfTheStorm] = { 211, 212, 213, 214, 216, 233, 587, 783, 784, 1258 },
	[cat.PvPWintergrasp] = { 1717,1718,1721,1722,1723,1727,"1737:2476",1751,"1752:2776",1755,2080,2199,3136,3137,3836,3837,4585,4586 },
	[cat.PvPStrandOfTheAncients] = { 2191,1766,2189,1763,"1757:2200",2190,1764,2193,"2194:2195","1762:2192",1765,1310,1309,1308,1761 },
	[cat.PvPWarsongGulch] = { 199,872,204,"1172:1173",203,1251,1259,200,"202:1502",207,713,"206:1252",201,168,167,166,712 },
	[cat.PvPIsleOfConquest] = { 3848,3849,3853,3854,3852,"3856:4256",3847,3855,3845,3777,3776,"3857:3957","3851:4177",3850,"3846:4176" },
	[cat.PvPBattleForGilneas] = { 5247, 5248, 5249, 5250, 5251, 5252, 5253, 5254, 5255, 5256, 5257, 5262 },
	[cat.PvPTwinPeaks] = { "5226:5227", "5231:5552", 5229, "5221:5222", 5220, 5219, 5216, "5213:5214", 5211, 5230, 5215,
		5210, 5228 },
	[cat.ExpansionFeaturesTolBarad] = { "5718:5719", 5486, 5487, 5415, 5488 },
	
	[cat.DungeonsLichKing] = { 
		477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,1296,1297,1816,1817,1834,1860,1862,1864,1865,
		1866,1867,1868,1871,1872,1873,1919,2036,2037,2038,2039,2040,2041,2042,2043,2044,2045,2046,2056,2057,2058,2150,2151,2152,2153,2154,2155,2156,
		2157,3778,3802,3803,3804,4296,4297,4298,4516,4517,4518,4519,4520,4521,4522,4523,4524,4525,4526,17213,17283,17285,17291,17292,17293,17295,
		17297,17299,17300,17301,17302,18590,18591,18592,18593,18594,18595,18596,18597,18598,18599,18600,18601,18677,18678,19425,19426,19427,19428,
		19429,19430,19431,19432,19433,19434,19435,19436,19437,19438 },
		
	[cat.RaidsLichKing] = { 
		562,563,564,565,566,567,568,569,572,573,574,575,576,577,578,579,622,623,624,625,1856,1857,1858,1859,1869,1870,1874,1875,1876,1877,1996,1997,
		2047,2048,2049,2050,2051,2052,2053,2054,2139,2140,2146,2147,2148,2149,2176,2177,2178,2179,2180,2181,2182,2183,2184,2185,2886,2887,2888,2889,
		2890,2891,2892,2893,2894,2895,2905,2906,2907,2908,2909,2910,2911,2912,2913,2914,2915,2916,2917,2918,2919,2921,2923,2924,2925,2926,2927,2928,
		2929,2930,2931,2932,2933,2934,2935,2936,2937,2938,2939,2940,2941,2942,2943,2944,2945,2946,2947,2948,2951,2952,2953,2954,2955,2956,2959,2960,
		2961,2962,2963,2965,2967,2968,2969,2970,2971,2972,2973,2974,2975,2976,2977,2978,2979,2980,2981,2982,2983,2984,2985,2989,2995,2996,2997,3002,
		3003,3006,3007,3008,3009,3010,3011,3012,3013,3014,3015,3016,3017,3036,3037,3056,3057,3058,3059,3076,3077,3097,3098,3118,3138,3141,3157,3158,
		3159,3161,3162,3163,3164,3176,3177,3178,3179,3180,3181,3182,3183,3184,3185,3186,3187,3188,3189,3237,3797,3798,3799,3800,3812,3813,3815,3816,
		3916,3917,3918,3936,3937,3996,3997,4396,4397,4402,4403,4404,4405,4406,4407,4527,4528,4529,4530,4531,4532,4534,4535,4536,4537,4538,4539,4577,
		4578,4579,4580,4581,4582,4583,4584,4597,4601,4604,4605,4606,4607,4608,4610,4611,4612,4613,4614,4615,4616,4617,4618,4619,4620,4621,4622,4628,
		4629,4630,4631,4632,4633,4634,4635,4636,4637,4815,4816,4817,4818 },
		
	[cat.DungeonsCataclysm] = {
		4833,4839,4840,4841,4846,4847,4848,5060,5061,5062,5063,5064,5065,5066,5083,5093,5281,5282,5283,5284,5285,5286,5287,5288,5289,5290,5291,5292,
		5293,5294,5295,5296,5297,5298,5366,5367,5368,5369,5370,5371,5503,5504,5505,5743,5744,5750,5759,5760,5761,5762,5765,5768,5769,5858,5995,6070,
		6117,6118,6119,6127,6130,6132 },
	[cat.RaidsCataclysm] = {
		4842,4849,4850,4851,4852,5094,5107,5108,5109,5115,5116,5117,5118,5119,5120,5121,5122,5123,5300,5304,5305,5306,5307,5308,5309,5310,5311,5312,
		5313,5799,5802,5803,5804,5805,5806,5807,5808,5809,5810,5813,5821,5829,5830,5855,6084,6105,6106,6107,6109,6110,6111,6112,6113,6114,6115,6116,
		6128,6129,6133,6174,6175,6177,6180 },
		
		
	[cat.DungeonsUlduar10] = { 2919,3159,2945,2947,2903,2961,2980,3006,2985,2953,2971,3008,3097,3180,2982,2967,3004,3012,3058,3316,2927,2939,2941,2940,3182,2963,3181,2973,2955,3015,2923,3009,3177,3178,3179,3176,2979,2937,2931,2934,2933,3076,3138,2915,3036,3158,3056,2913,2914,2959,2989,2996,2925,2911,2977,2969,2930,3003,2909,2888,2892,2890,2894,2886,3014,2907,3157,3141,2905,2975,2951 },
	[cat.DungeonsUlduar25] = { 2921,3164,2946,2948,2962,2981,2904,3007,2984,2954,2972,3010,3098,3189,2983,2968,3005,3013,3059,2928,2942,2944,2943,3184,2965,3188,2974,2956,3016,2924,3011,3185,3186,3187,3183,3118,2938,2932,2936,2935,3077,2995,2917,3037,3163,3057,2918,2916,2960,3237,2997,2926,2912,2978,2970,2929,3002,2910,2889,2893,2891,2895,2887,3017,2908,3161,3162,2906,2976,2952 },
	[cat.DungeonsCrusade10] = { 3917,3918,3936,3798,3799,3800,3996,3797 },
	[cat.DungeonsCrusade25] = { 3916,3812,3937,3814,3815,3816,3997,3813 },
	[cat.DungeonsIcecrow10] = { 4580,4583,4601,4534,4538,4532,4577,4535,4636,4628,4630,4631,4629,4536,4537,4578,4581,4539,4579,4531,4529,4527,4530,4582,4528 },
	[cat.DungeonsIcecrow25] = { 4620,4621,4610,4614,4608,4615,4611,4637,4632,4634,4635,4633,4612,4613,4616,4622,4618,4619,4604,4606,4607,4597,4584,4617,4605 },
	
	[cat.Professions] = { 730,735 },
	[cat.ProfessionsCooking] = { 877,906,"1563:1784",1780,1781,"1782:1783",1785,1800,1801,1998,3296,"5845:5846", 5842,5841,5475,5474,5843,5844 },
	[cat.ProfessionsFishing] = { 144,150,153,306,560,726,878,905,1225,1243,1257,1516,1517,1836,1837,1958,3217,3218,"5851:5852",5476,5477,5478,5847,5848,5849,5850},
	[cat.ProfessionsFirstAid] = { 137,141 },
	[cat.ProfessionsArchaeology] = { 5315, 5469, 5470, 4854, 4855, 4856 },
	
	[cat.Reputations] = { 762,"942:943",945,948,953,5794 },
	[cat.ReputationsClassic] = { 955, 956, 946, 944 },
	[cat.ReputationsBurningCrusade] = { 896, 893, 902, 894, 901, 899, 898, 903, 1638, 958, "764:763", 900, 959, 960, 897 },
	[cat.ReputationsLichKing] = { 950, 2083, 2082, 1009, 952, 1010, 947, 4598, 1008, 951, "1012:1011", 1007, 949 },
	[cat.ReputationsCataclysm] = { 5375, 4886, 5376, 4884, 4881, 4882, 4883, 4885, 5827 },
	
	
	[cat.WorldEvents] = { "1684:1683",3456,"1707:1693",1793,"1656:1657","1692:1691","2797:2798","3478:3656",3457,1039,1038,913,"2144:2145" },
	[cat.WorldEventsLunarFestival] = { 626,910,911,912,914,915,937,1281,1396,1552 },
	[cat.WorldEventsLoveIsInTheAir] = { 1701,260,1695,1699,"1279:1280",1704,1291,1694,1703,"1697:1698",1700,1188,1702,1696,4624 },
	[cat.WorldEventsNoblegarden] = { 2576,2418,2417,2436,249,2416,2676,"2421:2420",2422,"2419:2497",248 },
	[cat.WorldEventsChildrensWeek] = { 275, 1786, 1788, 1789, 1790, 1791, 1792 },
	[cat.WorldEventsMidSummer] = { 271,1037,1035,"1028:1031","1029:1032","1030:1033",1025,1026,1027,1022,1023,1024,263,1145,"1034:1036",272 },
	[cat.WorldEventsBrewfest] = { 2796,1183,295,293,1936,1186,1260,303,"1184:1203",1185 },
	[cat.WorldEventsHallowsEnd] = { 284,255,291,1261,288,"1040:1041",292,981,979,283,289,972,"970:971","966:967","963:965","969:968" },
	[cat.WorldEventsPilgrimsBounty] = { 3579,"3576:3577","3556:3557","3580:3581","3596:3597",3558,3582,3578,3559 },
	[cat.WorldEventsWinterveil] = { 277,1690,"4436:4437","1686:1685",1295,1282,1689,1687,273,"1255:259",279,1688,252 },
	[cat.ExpansionFeaturesArgentTournament] = { 3676,2773,2836,3736,3677,4596,2772 },
	[cat.WorldEventsDarkmoon] = { 6019, 6020, 6021, 6022, 6023, 6024, 6025, 6026, 6027, 6028, 6029, "6030:6031", 6032 },
	
	[cat.FeatsOfStrength] = { 411,412,414,415,416,418,419,420,424,425,426,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,454,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,"471:453",472,473,662,663,664,665,683,684,725,729,871,879,880,881,882,883,884,885,886,887,888,980,1205,1292,1293,1400,1402,1404,1405,1406,1407,1408,1409,1410,1411,1412,1413,1414,1415,1416,1417,1418,1419,1420,1421,1422,1423,1424,1425,1426,1427,1436,1463,1636,1637,1705,1706,2018,2019,2079,2081,2116,2316,2336,2357,2358,2359,2398,2456,2496,3096,3117,3142,3259,3336,3356,3357,3436,3496,3536,3618,3636,3756,3757,3758,3896,4078,"4079:4156",4400,4496,4576,4599,4600,4623,4625,4626,4627 },

}

addon:Service("AltoholicUI.AchievementsLists", function()

	local function SortByName(a, b)
		if type(a) == "string" then
			a = strsplit(":", a)
			a = tonumber(a)
		end
		if type(b) == "string" then
			b = strsplit(":", b)
			b = tonumber(b)
		end

		local nameA = select(2, GetAchievementInfo(a)) or ""
		local nameB = select(2, GetAchievementInfo(b)) or ""
		return nameA < nameB
	end

	local function GetSortedSize(categoryID)
		return (sortedAchievements[categoryID]) and #sortedAchievements[categoryID] or 0
	end

	local function GetUnsortedSize(categoryID)
		return (unsortedAchievements[categoryID]) and #unsortedAchievements[categoryID] or 0
	end

	local function GetFactionInfo(value)
		-- Achievement is the same for alliance and horde, simply return the value (the achievement ID)
		if type(value) == "number" then return value end

		-- Achievement is different for alliance and horde, return the two values separately
		if type(value) == "string" then
			local ally, horde = strsplit(":", value)
			return tonumber(ally), tonumber(horde) -- return alliance ach id, horde ach id
		end
	end

	return {
		Initialize = function()
			-- order each category by name, do this only once at startup
			for category, data in pairs(unsortedAchievements) do
				table.sort(data, SortByName)
			end
		end,
		GetCategorySize = function(categoryID)
			return GetSortedSize(categoryID) + GetUnsortedSize(categoryID)
		end,
		GetAchievementFactionInfo = function(categoryID, index)
			if index <= 0 then return end

			local size = GetSortedSize(categoryID)

			-- We want index 5 and we have 10 sorted entries, return the info
			if index <= size then
				return GetFactionInfo(sortedAchievements[categoryID][index])
			end

			-- We want index 10, but only 8 in sorted, so we want index 2 of unsorted
			index = index - size
			size = GetUnsortedSize(categoryID)

			-- We want index 2 and we have 5 unsorted entries, return the info
			if index <= size then
				return GetFactionInfo(unsortedAchievements[categoryID][index])
			end
		end,
	}
end)

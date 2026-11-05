--!strict
--[[
	Footballers
	Responsibility: Master pool of 152 real footballers (5 Mythic, 12 Legendary, 25 Epic, 45 Rare, 65 Common) with real full names, real clubs, real countries, 6 FIFA attributes, appearance traits, and official club kit definitions.
	Loop step: action (roll & slot placement)
	Location: ReplicatedStorage/Shared/Footballers (ModuleScript)
]]

local GameConfig = require(script.Parent.GameConfig)

export type AttributeKey = GameConfig.AttributeKey
export type Rarity = GameConfig.Rarity
export type HairStyle = "bald" | "buzz" | "short" | "curly" | "bun" | "long" | "braids" | "mohawk"
export type KitPattern = "solid" | "stripes" | "center" | "half" | "hoops"

export type ClubKit = {
	shirt: string,
	secondary: string,
	sleeve: string,
	shorts: string,
	socks: string,
	trim: string,
	pattern: KitPattern,
}

export type Stats = {
	PAC: number,
	SHO: number,
	PAS: number,
	DRI: number,
	DEF: number,
	PHY: number,
}

export type Footballer = {
	id: string,
	name: string,
	country: string,
	club: string,
	pos: string,
	ovr: number,
	rarity: Rarity,
	kitColor: string,
	skin: number,
	hairStyle: HairStyle,
	hairColor: string,
	beard: boolean,
	stats: Stats,
}

local SKIN_TONES: { Color3 } = table.freeze({
	Color3.fromHex("#FCE0C8"), -- 1: Very fair / Nordic
	Color3.fromHex("#F5CBA7"), -- 2: Fair European
	Color3.fromHex("#E5B287"), -- 3: Light olive / Mediterranean / Latin
	Color3.fromHex("#C98E63"), -- 4: Warm tan / North African / Mixed
	Color3.fromHex("#A56B43"), -- 5: Medium warm brown
	Color3.fromHex("#7B4B2A"), -- 6: Rich dark brown
	Color3.fromHex("#523018"), -- 7: Deep ebony brown
})

local function k(shirt: string, secondary: string, sleeve: string, shorts: string, socks: string, trim: string, pattern: KitPattern): ClubKit
	return table.freeze({
		shirt = shirt,
		secondary = secondary,
		sleeve = sleeve,
		shorts = shorts,
		socks = socks,
		trim = trim,
		pattern = pattern,
	})
end

local CLUB_KITS: { [string]: ClubKit } = table.freeze({
	["Arsenal"] = k("#EF0107", "#FFFFFF", "#FFFFFF", "#FFFFFF", "#EF0107", "#FFFFFF", "solid"),
	["Manchester City"] = k("#6CABDD", "#FFFFFF", "#6CABDD", "#FFFFFF", "#6CABDD", "#FFFFFF", "solid"),
	["Real Madrid"] = k("#F8F9FA", "#1A1D24", "#F8F9FA", "#F8F9FA", "#F8F9FA", "#1A1D24", "solid"),
	["Barcelona"] = k("#004D98", "#A50044", "#A50044", "#004D98", "#004D98", "#EDBB00", "stripes"),
	["Liverpool"] = k("#C8102E", "#FFFFFF", "#C8102E", "#C8102E", "#C8102E", "#F6EB61", "solid"),
	["Manchester United"] = k("#DA291C", "#FFFFFF", "#DA291C", "#FFFFFF", "#18181B", "#FFFFFF", "solid"),
	["Chelsea"] = k("#034694", "#FFFFFF", "#034694", "#034694", "#FFFFFF", "#FFFFFF", "solid"),
	["Tottenham"] = k("#F8FAFC", "#132257", "#132257", "#132257", "#F8FAFC", "#132257", "solid"),
	["Paris Saint-Germain"] = k("#004170", "#DA291C", "#004170", "#004170", "#004170", "#FFFFFF", "center"),
	["Inter Miami"] = k("#F7B5CD", "#18181B", "#F7B5CD", "#F7B5CD", "#F7B5CD", "#18181B", "solid"),
	["Al-Nassr"] = k("#FFD21F", "#0054A6", "#0054A6", "#0054A6", "#FFD21F", "#0054A6", "solid"),
	["Bayern Munich"] = k("#DC052D", "#FFFFFF", "#DC052D", "#DC052D", "#DC052D", "#FFFFFF", "solid"),
	["Inter Milan"] = k("#0068A8", "#14161C", "#14161C", "#14161C", "#14161C", "#FFFFFF", "stripes"),
	["AC Milan"] = k("#FB090B", "#14161C", "#14161C", "#14161C", "#14161C", "#FFFFFF", "stripes"),
	["Bayer Leverkusen"] = k("#E32221", "#14161C", "#14161C", "#14161C", "#E32221", "#14161C", "solid"),
	["Sporting CP"] = k("#008057", "#FFFFFF", "#008057", "#14161C", "#008057", "#FFFFFF", "hoops"),
	["Newcastle United"] = k("#18181B", "#FFFFFF", "#18181B", "#18181B", "#18181B", "#FFFFFF", "stripes"),
	["Galatasaray"] = k("#A90432", "#FDB912", "#FDB912", "#FFFFFF", "#A90432", "#FDB912", "half"),
	["Aston Villa"] = k("#670E36", "#95BFE5", "#95BFE5", "#FFFFFF", "#95BFE5", "#95BFE5", "solid"),
	["West Ham"] = k("#7A263A", "#1BB1E7", "#1BB1E7", "#FFFFFF", "#7A263A", "#1BB1E7", "solid"),
	["Crystal Palace"] = k("#1B458F", "#C4122E", "#1B458F", "#1B458F", "#1B458F", "#FFFFFF", "stripes"),
	["Fulham"] = k("#F8FAFC", "#14161C", "#F8FAFC", "#14161C", "#F8FAFC", "#14161C", "solid"),
	["Everton"] = k("#003399", "#FFFFFF", "#003399", "#FFFFFF", "#FFFFFF", "#FFFFFF", "solid"),
	["Wolves"] = k("#FDB913", "#14161C", "#FDB913", "#14161C", "#FDB913", "#14161C", "solid"),
	["Brentford"] = k("#E30613", "#FFFFFF", "#FFFFFF", "#14161C", "#E30613", "#14161C", "stripes"),
	["Juventus"] = k("#F8FAFC", "#14161C", "#F8FAFC", "#14161C", "#F8FAFC", "#14161C", "stripes"),
	["Atalanta"] = k("#1E71B8", "#14161C", "#14161C", "#14161C", "#14161C", "#FFFFFF", "stripes"),
	["Eintracht Frankfurt"] = k("#E1000F", "#14161C", "#14161C", "#14161C", "#14161C", "#FFFFFF", "stripes"),
	["RB Leipzig"] = k("#F8FAFC", "#DD0741", "#DD0741", "#DD0741", "#F8FAFC", "#DD0741", "solid"),
})

local DEFAULT_KIT: ClubKit = k("#1E6FFF", "#FFFFFF", "#1E6FFF", "#FFFFFF", "#1E6FFF", "#FFFFFF", "solid")

local function c(
	id: string,
	name: string,
	country: string,
	club: string,
	pos: string,
	ovr: number,
	rarity: Rarity,
	skin: number,
	hairStyle: HairStyle,
	hairColor: string,
	beard: boolean,
	pac: number,
	sho: number,
	pas: number,
	dri: number,
	def: number,
	phy: number
): Footballer
	local stats: Stats = table.freeze({
		PAC = pac,
		SHO = sho,
		PAS = pas,
		DRI = dri,
		DEF = def,
		PHY = phy,
	})
	local kit = CLUB_KITS[club] or DEFAULT_KIT
	return table.freeze({
		id = id,
		name = name,
		country = country,
		club = club,
		pos = pos,
		ovr = ovr,
		rarity = rarity,
		kitColor = kit.shirt,
		skin = skin,
		hairStyle = hairStyle,
		hairColor = hairColor,
		beard = beard,
		stats = stats,
	})
end

local POOL: { Footballer } = {
	-- =========================================================
	-- MYTHIC (5) | OVR 94-99
	-- =========================================================
	c("messi", "Lionel Messi", "Argentina", "Inter Miami", "RW", 97, "Mythic", 2, "short", "#2C1D14", true, 88, 95, 97, 98, 40, 72),
	c("ronaldo", "Cristiano Ronaldo", "Portugal", "Al-Nassr", "ST", 97, "Mythic", 3, "short", "#141418", false, 90, 98, 84, 91, 42, 88),
	c("haaland", "Erling Haaland", "Norway", "Manchester City", "ST", 96, "Mythic", 1, "bun", "#E8C868", false, 96, 96, 80, 88, 60, 94),
	c("mbappe", "Kylian Mbappé", "France", "Real Madrid", "ST", 96, "Mythic", 5, "buzz", "#181616", false, 98, 94, 85, 95, 45, 82),
	c("rodri", "Rodri", "Spain", "Manchester City", "CDM", 95, "Mythic", 3, "short", "#261B14", false, 78, 84, 92, 88, 94, 92),

	-- =========================================================
	-- LEGENDARY (12) | OVR 87-93
	-- =========================================================
	c("vinicius", "Vinícius Jr.", "Brazil", "Real Madrid", "LW", 92, "Legendary", 6, "braids", "#141418", false, 96, 86, 83, 94, 35, 72),
	c("bellingham", "Jude Bellingham", "England", "Real Madrid", "CAM", 91, "Legendary", 5, "buzz", "#16161A", false, 84, 87, 86, 90, 80, 88),
	c("kane", "Harry Kane", "England", "Bayern Munich", "ST", 91, "Legendary", 2, "short", "#6E4E32", true, 70, 94, 86, 84, 50, 84),
	c("salah", "Mohamed Salah", "Egypt", "Liverpool", "RW", 90, "Legendary", 4, "curly", "#151518", true, 91, 90, 84, 90, 46, 78),
	c("debruyne", "Kevin De Bruyne", "Belgium", "Manchester City", "CM", 90, "Legendary", 1, "short", "#D9A45B", true, 72, 87, 95, 87, 65, 77),
	c("vandijk", "Virgil van Dijk", "Netherlands", "Liverpool", "CB", 90, "Legendary", 4, "bun", "#16161A", true, 80, 62, 74, 74, 92, 90),
	c("courtois", "Thibaut Courtois", "Belgium", "Real Madrid", "GK", 90, "Legendary", 2, "short", "#2B1E16", false, 85, 50, 78, 88, 92, 89),
	c("lautaro", "Lautaro Martínez", "Argentina", "Inter Milan", "ST", 89, "Legendary", 3, "mohawk", "#1A1716", false, 83, 89, 77, 87, 54, 86),
	c("alisson", "Alisson Becker", "Brazil", "Liverpool", "GK", 89, "Legendary", 3, "short", "#322118", true, 86, 52, 85, 86, 90, 88),
	c("odegaard", "Martin Ødegaard", "Norway", "Arsenal", "CAM", 89, "Legendary", 1, "short", "#C89D54", true, 78, 82, 91, 90, 67, 70),
	c("saka", "Bukayo Saka", "England", "Arsenal", "RW", 88, "Legendary", 6, "buzz", "#141418", false, 87, 84, 85, 89, 62, 74),
	c("saliba", "William Saliba", "France", "Arsenal", "CB", 88, "Legendary", 5, "buzz", "#16161A", false, 83, 45, 72, 76, 89, 86),

	-- =========================================================
	-- EPIC (25) | OVR 80-86
	-- =========================================================
	c("foden", "Phil Foden", "England", "Manchester City", "RW", 86, "Epic", 2, "buzz", "#241B15", false, 86, 85, 85, 91, 56, 64),
	c("valverde", "Federico Valverde", "Uruguay", "Real Madrid", "CM", 86, "Epic", 3, "short", "#2B1E16", false, 88, 83, 84, 84, 82, 85),
	c("musiala", "Jamal Musiala", "Germany", "Bayern Munich", "CAM", 86, "Epic", 4, "curly", "#181618", false, 85, 81, 82, 92, 63, 66),
	c("wirtz", "Florian Wirtz", "Germany", "Bayer Leverkusen", "CAM", 86, "Epic", 2, "short", "#6B4C33", false, 82, 81, 87, 90, 58, 67),
	c("palmer", "Cole Palmer", "England", "Chelsea", "CAM", 86, "Epic", 2, "short", "#C69B56", false, 81, 85, 86, 87, 52, 68),
	c("pedri", "Pedri", "Spain", "Barcelona", "CM", 86, "Epic", 3, "short", "#261B14", false, 79, 70, 86, 90, 72, 66),
	c("rice", "Declan Rice", "England", "Arsenal", "CDM", 86, "Epic", 2, "short", "#36251B", true, 77, 70, 80, 80, 86, 86),
	c("rudiger", "Antonio Rüdiger", "Germany", "Real Madrid", "CB", 86, "Epic", 7, "buzz", "#141418", true, 82, 55, 71, 70, 86, 87),
	c("dias", "Rúben Dias", "Portugal", "Manchester City", "CB", 86, "Epic", 3, "short", "#261B15", true, 68, 48, 70, 69, 88, 87),
	c("yamal", "Lamine Yamal", "Spain", "Barcelona", "RW", 85, "Epic", 5, "curly", "#221A16", false, 86, 79, 83, 89, 36, 58),
	c("leao", "Rafael Leão", "Portugal", "AC Milan", "LW", 85, "Epic", 6, "braids", "#16161A", false, 93, 80, 79, 88, 32, 78),
	c("son", "Son Heung-min", "South Korea", "Tottenham", "LW", 85, "Epic", 2, "short", "#141418", false, 87, 88, 81, 85, 42, 71),
	c("hakimi", "Achraf Hakimi", "Morocco", "Paris Saint-Germain", "RB", 85, "Epic", 4, "buzz", "#16161A", true, 93, 75, 80, 82, 78, 79),
	c("theo", "Theo Hernández", "France", "AC Milan", "LB", 85, "Epic", 3, "mohawk", "#E5C565", false, 93, 74, 78, 82, 79, 86),
	c("bastoni", "Alessandro Bastoni", "Italy", "Inter Milan", "CB", 85, "Epic", 2, "short", "#4B3526", false, 76, 48, 77, 75, 87, 83),
	c("bruno_f", "Bruno Fernandes", "Portugal", "Manchester United", "CAM", 85, "Epic", 3, "short", "#181618", true, 72, 84, 89, 83, 68, 75),
	c("bernardo", "Bernardo Silva", "Portugal", "Manchester City", "CM", 85, "Epic", 3, "short", "#2C1F17", true, 76, 78, 86, 91, 70, 68),
	c("barella", "Nicolò Barella", "Italy", "Inter Milan", "CM", 85, "Epic", 2, "short", "#6B4E35", false, 80, 77, 84, 86, 80, 78),
	c("gyokeres", "Viktor Gyökeres", "Sweden", "Sporting CP", "ST", 84, "Epic", 2, "short", "#7A583B", false, 88, 85, 74, 83, 45, 90),
	c("isak", "Alexander Isak", "Sweden", "Newcastle United", "ST", 84, "Epic", 5, "curly", "#16161A", true, 86, 85, 75, 86, 40, 76),
	c("osimhen", "Victor Osimhen", "Nigeria", "Galatasaray", "ST", 84, "Epic", 7, "mohawk", "#E6C35C", false, 89, 84, 66, 80, 42, 83),
	c("gvardiol", "Joško Gvardiol", "Croatia", "Manchester City", "LB", 84, "Epic", 3, "curly", "#1E1816", true, 81, 65, 76, 78, 85, 84),
	c("macallister", "Alexis Mac Allister", "Argentina", "Liverpool", "CM", 84, "Epic", 2, "short", "#7D4427", true, 72, 79, 85, 84, 77, 76),
	c("kvaratskhelia", "Khvicha Kvaratskhelia", "Georgia", "Paris Saint-Germain", "LW", 84, "Epic", 2, "curly", "#1C1817", true, 85, 80, 81, 88, 42, 72),
	c("dimarco", "Federico Dimarco", "Italy", "Inter Milan", "LB", 83, "Epic", 2, "mohawk", "#E4C770", false, 82, 76, 85, 81, 79, 76),

	-- =========================================================
	-- RARE (45) | OVR 70-79
	-- =========================================================
	c("mainoo", "Kobbie Mainoo", "England", "Manchester United", "CM", 78, "Rare", 5, "curly", "#16161A", false, 75, 68, 77, 82, 73, 72),
	c("garnacho", "Alejandro Garnacho", "Argentina", "Manchester United", "LW", 79, "Rare", 2, "short", "#3B281E", false, 87, 76, 72, 82, 40, 64),
	c("endrick", "Endrick", "Brazil", "Real Madrid", "ST", 77, "Rare", 5, "curly", "#16161A", false, 86, 78, 65, 79, 35, 75),
	c("cubarsi", "Pau Cubarsí", "Spain", "Barcelona", "CB", 76, "Rare", 2, "short", "#3A281E", false, 72, 40, 75, 71, 78, 73),
	c("harvey_e", "Harvey Elliott", "England", "Liverpool", "CAM", 78, "Rare", 2, "curly", "#8C6843", false, 74, 73, 80, 82, 58, 62),
	c("kiwior", "Jakub Kiwior", "Poland", "Arsenal", "CB", 76, "Rare", 2, "short", "#5A4230", false, 74, 46, 68, 68, 77, 76),
	c("zaire_emery", "Warren Zaïre-Emery", "France", "Paris Saint-Germain", "CM", 79, "Rare", 6, "curly", "#16161A", false, 80, 71, 79, 81, 76, 79),
	c("guler", "Arda Güler", "Turkey", "Real Madrid", "CAM", 79, "Rare", 2, "short", "#281D16", false, 76, 78, 82, 84, 50, 60),
	c("savinho", "Savinho", "Brazil", "Manchester City", "RW", 79, "Rare", 5, "curly", "#181618", false, 88, 73, 76, 86, 38, 60),
	c("doku", "Jérémy Doku", "Belgium", "Manchester City", "LW", 79, "Rare", 7, "braids", "#16161A", false, 92, 70, 74, 88, 35, 67),
	c("hojlund_r", "Rasmus Højlund", "Denmark", "Manchester United", "ST", 78, "Rare", 1, "short", "#D8B263", false, 86, 78, 64, 75, 38, 80),
	c("zirkzee", "Joshua Zirkzee", "Netherlands", "Manchester United", "ST", 78, "Rare", 5, "curly", "#181618", false, 76, 77, 76, 82, 40, 78),
	c("yoro", "Leny Yoro", "France", "Manchester United", "CB", 77, "Rare", 6, "curly", "#16161A", false, 79, 42, 68, 70, 78, 76),
	c("amad", "Amad Diallo", "Ivory Coast", "Manchester United", "RW", 77, "Rare", 6, "curly", "#16161A", false, 84, 72, 74, 83, 45, 60),
	c("quansah", "Jarell Quansah", "England", "Liverpool", "CB", 75, "Rare", 5, "braids", "#181618", true, 75, 42, 69, 68, 76, 77),
	c("bradley", "Conor Bradley", "Northern Ireland", "Liverpool", "RB", 75, "Rare", 1, "short", "#5E402B", false, 81, 60, 71, 74, 73, 72),
	c("jones_c", "Curtis Jones", "England", "Liverpool", "CM", 79, "Rare", 4, "curly", "#221A16", true, 75, 73, 79, 83, 72, 74),
	c("gravenberch", "Ryan Gravenberch", "Netherlands", "Liverpool", "CDM", 79, "Rare", 6, "braids", "#16161A", false, 77, 72, 79, 83, 76, 78),
	c("calafiori", "Riccardo Calafiori", "Italy", "Arsenal", "LB", 79, "Rare", 2, "long", "#2A1D16", false, 78, 60, 76, 77, 80, 80),
	c("timber", "Jurriën Timber", "Netherlands", "Arsenal", "RB", 79, "Rare", 5, "buzz", "#16161A", true, 81, 56, 76, 79, 79, 78),
	c("madueke", "Noni Madueke", "England", "Chelsea", "RW", 78, "Rare", 6, "braids", "#16161A", false, 87, 75, 72, 84, 38, 66),
	c("jackson", "Nicolas Jackson", "Senegal", "Chelsea", "ST", 79, "Rare", 7, "buzz", "#16161A", false, 86, 77, 70, 79, 42, 77),
	c("gusto", "Malo Gusto", "France", "Chelsea", "RB", 79, "Rare", 4, "braids", "#1E1816", false, 87, 58, 76, 79, 76, 75),
	c("colwill", "Levi Colwill", "England", "Chelsea", "CB", 78, "Rare", 5, "curly", "#181618", true, 75, 45, 74, 72, 79, 78),
	c("lavia", "Roméo Lavia", "Belgium", "Chelsea", "CDM", 76, "Rare", 6, "braids", "#16161A", false, 74, 56, 74, 77, 76, 76),
	c("van_de_ven", "Micky van de Ven", "Netherlands", "Tottenham", "CB", 79, "Rare", 2, "short", "#5A3F2B", false, 91, 48, 70, 72, 79, 80),
	c("udogie", "Destiny Udogie", "Italy", "Tottenham", "LB", 79, "Rare", 6, "braids", "#16161A", false, 86, 65, 75, 80, 77, 80),
	c("sarr_p", "Pape Matar Sarr", "Senegal", "Tottenham", "CM", 78, "Rare", 7, "buzz", "#16161A", false, 80, 71, 76, 78, 75, 78),
	c("gray_a", "Archie Gray", "England", "Tottenham", "CDM", 73, "Rare", 1, "short", "#9E7447", false, 75, 60, 73, 75, 71, 70),
	c("bergvall", "Lucas Bergvall", "Sweden", "Tottenham", "CM", 74, "Rare", 1, "short", "#DFBC6A", false, 76, 68, 75, 78, 66, 70),
	c("rogers", "Morgan Rogers", "England", "Aston Villa", "CAM", 78, "Rare", 4, "buzz", "#1E1816", true, 83, 76, 75, 82, 55, 80),
	c("duran", "Jhon Durán", "Colombia", "Al-Nassr", "ST", 77, "Rare", 6, "mohawk", "#DFBC6A", false, 83, 79, 64, 75, 38, 81),
	c("gordon", "Anthony Gordon", "England", "Newcastle United", "LW", 79, "Rare", 1, "long", "#DFBC6A", false, 89, 76, 75, 82, 52, 72),
	c("hall_l", "Lewis Hall", "England", "Newcastle United", "LB", 75, "Rare", 2, "short", "#543B29", false, 78, 62, 75, 76, 73, 71),
	c("miley", "Lewis Miley", "England", "Newcastle United", "CM", 72, "Rare", 1, "short", "#6E4E34", false, 70, 65, 73, 74, 68, 71),
	c("fermin", "Fermín López", "Spain", "Barcelona", "CAM", 78, "Rare", 2, "short", "#4A3425", false, 79, 78, 76, 80, 62, 70),
	c("casado", "Marc Casadó", "Spain", "Barcelona", "CDM", 76, "Rare", 2, "short", "#3B291E", false, 73, 60, 77, 76, 76, 74),
	c("balde", "Alejandro Balde", "Spain", "Barcelona", "LB", 79, "Rare", 6, "buzz", "#16161A", false, 91, 60, 74, 81, 74, 71),
	c("pavlovic", "Aleksandar Pavlović", "Germany", "Bayern Munich", "CDM", 77, "Rare", 2, "short", "#2E2118", false, 72, 66, 79, 77, 76, 75),
	c("tel", "Mathys Tel", "France", "Tottenham", "ST", 76, "Rare", 6, "braids", "#16161A", false, 84, 77, 68, 79, 36, 68),
	c("barcola", "Bradley Barcola", "France", "Paris Saint-Germain", "LW", 79, "Rare", 5, "braids", "#16161A", false, 89, 75, 75, 84, 40, 67),
	c("neves_j", "João Neves", "Portugal", "Paris Saint-Germain", "CM", 79, "Rare", 2, "short", "#32231A", false, 78, 68, 79, 82, 78, 78),
	c("doue", "Désiré Doué", "France", "Paris Saint-Germain", "CAM", 77, "Rare", 5, "braids", "#16161A", false, 83, 72, 76, 84, 58, 69),
	c("yildiz", "Kenan Yıldız", "Turkey", "Juventus", "LW", 77, "Rare", 2, "short", "#261B14", false, 82, 76, 74, 82, 42, 68),
	c("scalvini", "Giorgio Scalvini", "Italy", "Atalanta", "CB", 78, "Rare", 2, "short", "#5C422E", false, 74, 48, 70, 70, 80, 78),

	-- =========================================================
	-- COMMON (65) | OVR 60-69
	-- =========================================================
	c("hojlund_o", "Oscar Højlund", "Denmark", "Eintracht Frankfurt", "CM", 67, "Common", 1, "short", "#D8B263", false, 71, 60, 66, 68, 62, 69),
	c("lewis_m", "Myles Lewis-Skelly", "England", "Arsenal", "LB", 68, "Common", 5, "braids", "#16161A", false, 76, 54, 67, 71, 66, 68),
	c("nwaneri", "Ethan Nwaneri", "England", "Arsenal", "CAM", 69, "Common", 6, "braids", "#16161A", false, 77, 68, 69, 75, 42, 56),
	c("marc_g", "Marc Guiu", "Spain", "Chelsea", "ST", 68, "Common", 2, "short", "#3A281E", false, 75, 70, 56, 66, 30, 70),
	c("heaven_a", "Ayden Heaven", "England", "Manchester United", "CB", 65, "Common", 6, "curly", "#16161A", false, 68, 38, 60, 61, 66, 68),
	c("amas_h", "Harry Amass", "England", "Manchester United", "LB", 64, "Common", 4, "curly", "#2A1E16", false, 77, 45, 61, 66, 61, 58),
	c("collyer", "Toby Collyer", "England", "Manchester United", "CDM", 66, "Common", 2, "short", "#543B29", false, 69, 50, 64, 65, 66, 70),
	c("wheatley", "Ethan Wheatley", "England", "Manchester United", "ST", 63, "Common", 3, "short", "#2A1E16", false, 73, 64, 52, 63, 28, 64),
	c("gore_d", "Dan Gore", "England", "Manchester United", "CM", 64, "Common", 2, "short", "#6E4E34", false, 68, 56, 65, 67, 58, 60),
	c("obi_c", "Chido Obi", "Denmark", "Manchester United", "ST", 64, "Common", 6, "buzz", "#16161A", false, 76, 66, 54, 65, 26, 68),
	c("nyoni", "Trey Nyoni", "England", "Liverpool", "CM", 64, "Common", 6, "curly", "#16161A", false, 72, 58, 66, 70, 55, 56),
	c("dann_j", "Jayden Danns", "England", "Liverpool", "ST", 66, "Common", 5, "curly", "#1E1816", false, 73, 67, 58, 66, 32, 66),
	c("morton_t", "Tyler Morton", "England", "Liverpool", "CDM", 69, "Common", 2, "short", "#7A583B", false, 68, 58, 71, 70, 67, 66),
	c("mcConnell", "James McConnell", "England", "Liverpool", "CM", 64, "Common", 2, "short", "#5A402C", false, 67, 55, 65, 65, 61, 62),
	c("doak_b", "Ben Doak", "Scotland", "Liverpool", "RW", 68, "Common", 1, "short", "#C69B56", false, 84, 60, 62, 74, 34, 58),
	c("koumas", "Lewis Koumas", "Wales", "Liverpool", "LW", 65, "Common", 2, "short", "#4A3425", false, 77, 65, 60, 67, 35, 60),
	c("wright_j", "Jacob Wright", "England", "Manchester City", "CM", 64, "Common", 2, "short", "#7A583B", false, 68, 58, 65, 66, 60, 62),
	c("oreilly", "Nico O'Reilly", "England", "Manchester City", "CAM", 66, "Common", 4, "braids", "#1C1817", false, 72, 64, 67, 70, 52, 66),
	c("simpson_p", "Jahmai Simpson-Pusey", "England", "Manchester City", "CB", 64, "Common", 6, "braids", "#16161A", false, 67, 36, 62, 61, 65, 65),
	c("mcbriar", "Kaden Braithwaite", "England", "Manchester City", "CB", 62, "Common", 5, "curly", "#181618", false, 66, 34, 58, 58, 63, 64),
	c("acheampong", "Josh Acheampong", "England", "Chelsea", "RB", 66, "Common", 6, "curly", "#16161A", false, 76, 46, 62, 66, 65, 66),
	c("george_t", "Tyrique George", "England", "Chelsea", "LW", 65, "Common", 6, "buzz", "#16161A", false, 79, 62, 61, 70, 32, 56),
	c("dyer_k", "Kiano Dyer", "England", "Chelsea", "CM", 63, "Common", 5, "curly", "#181618", false, 69, 58, 64, 66, 56, 58),
	c("rak_sakyi", "Samuel Rak-Sakyi", "England", "Chelsea", "CDM", 63, "Common", 6, "buzz", "#16161A", false, 70, 52, 63, 65, 62, 64),
	c("moore_m", "Mikey Moore", "England", "Tottenham", "LW", 67, "Common", 2, "short", "#6E4E34", false, 76, 65, 66, 73, 36, 58),
	c("lankshear", "Will Lankshear", "England", "Tottenham", "ST", 65, "Common", 2, "short", "#4A3425", false, 72, 67, 55, 64, 32, 70),
	c("scarlett", "Dane Scarlett", "England", "Tottenham", "ST", 66, "Common", 5, "buzz", "#181618", false, 76, 66, 56, 66, 32, 65),
	c("dorrington", "Alfie Dorrington", "England", "Tottenham", "CB", 63, "Common", 2, "short", "#7A583B", false, 65, 35, 58, 58, 64, 67),
	c("setford", "Tommy Setford", "England", "Arsenal", "GK", 63, "Common", 1, "short", "#C89D54", false, 64, 35, 62, 64, 65, 63),
	c("nichols_j", "Josh Nichols", "England", "Arsenal", "RB", 63, "Common", 5, "curly", "#181618", false, 74, 44, 59, 63, 62, 61),
	c("butler_o", "Nathan Butler-Oyedeji", "England", "Arsenal", "ST", 63, "Common", 6, "braids", "#16161A", false, 76, 63, 55, 65, 30, 62),
	c("kacurri", "Maldini Kacurri", "Albania", "Arsenal", "CB", 62, "Common", 2, "short", "#2C1F17", false, 64, 34, 55, 56, 63, 68),
	c("bogarde", "Lamare Bogarde", "Netherlands", "Aston Villa", "CB", 67, "Common", 5, "braids", "#16161A", false, 71, 46, 64, 65, 67, 68),
	c("nedeljkovic", "Kosta Nedeljković", "Serbia", "RB Leipzig", "RB", 68, "Common", 2, "short", "#3B281E", false, 83, 50, 63, 67, 65, 67),
	c("swinkels", "Sil Swinkels", "Netherlands", "Aston Villa", "CB", 63, "Common", 2, "short", "#C69B56", false, 65, 35, 58, 58, 64, 66),
	c("young_k", "Kadan Young", "England", "Aston Villa", "LW", 62, "Common", 5, "curly", "#181618", false, 76, 58, 57, 65, 32, 56),
	c("osula", "William Osula", "Denmark", "Newcastle United", "ST", 67, "Common", 5, "braids", "#16161A", false, 80, 66, 56, 67, 32, 72),
	c("murphy_a", "Alex Murphy", "Ireland", "Newcastle United", "CB", 63, "Common", 1, "short", "#4A3425", false, 67, 38, 58, 59, 64, 65),
	c("sanusi", "Trevan Sanusi", "England", "Newcastle United", "LW", 62, "Common", 6, "braids", "#16161A", false, 78, 56, 57, 68, 30, 52),
	c("scarles", "Ollie Scarles", "England", "West Ham", "LB", 65, "Common", 2, "short", "#6E4E34", false, 74, 48, 62, 65, 63, 62),
	c("orford", "Lewis Orford", "England", "West Ham", "CM", 63, "Common", 2, "short", "#5A402C", false, 67, 56, 64, 65, 58, 60),
	c("casey_k", "Kaelan Casey", "England", "West Ham", "CB", 63, "Common", 2, "short", "#4A3425", false, 64, 34, 56, 56, 64, 67),
	c("devanny", "Justin Devenny", "Northern Ireland", "Crystal Palace", "CM", 66, "Common", 1, "short", "#7A583B", false, 70, 60, 66, 67, 61, 64),
	c("agbinone", "Asher Agbinone", "England", "Crystal Palace", "RW", 63, "Common", 6, "buzz", "#16161A", false, 78, 58, 57, 67, 34, 58),
	c("kporha", "Caleb Kporha", "England", "Crystal Palace", "RB", 63, "Common", 6, "curly", "#16161A", false, 77, 46, 58, 64, 61, 63),
	c("king_j", "Josh King", "England", "Fulham", "CAM", 65, "Common", 4, "curly", "#241A15", false, 73, 60, 65, 69, 52, 58),
	c("godp", "Martial Godo", "Ivory Coast", "Fulham", "LW", 65, "Common", 6, "buzz", "#16161A", false, 79, 60, 59, 68, 35, 60),
	c("dixon_r", "Roman Dixon", "England", "Everton", "RB", 64, "Common", 2, "short", "#6E4E34", false, 82, 45, 58, 63, 61, 65),
	c("armstrong_h", "Harrison Armstrong", "England", "Everton", "CM", 64, "Common", 1, "short", "#C69B56", false, 69, 56, 64, 65, 60, 64),
	c("sherrif", "Martin Sherif", "Netherlands", "Everton", "ST", 62, "Common", 6, "buzz", "#16161A", false, 74, 62, 51, 61, 28, 66),
	c("lima_p", "Pedro Lima", "Brazil", "Wolves", "RB", 68, "Common", 4, "buzz", "#181618", false, 80, 54, 65, 70, 64, 65),
	c("pond_a", "Alfie Pond", "England", "Wolves", "CB", 63, "Common", 2, "short", "#4A3425", false, 65, 35, 57, 58, 64, 66),
	c("meupiyou", "Bastien Meupiyou", "France", "Wolves", "CB", 65, "Common", 7, "buzz", "#16161A", false, 70, 36, 58, 60, 66, 70),
	c("konak", "Yunus Emre Konak", "Turkey", "Brentford", "CDM", 66, "Common", 2, "short", "#261B14", false, 69, 54, 65, 66, 65, 68),
	c("maghoma", "Paris Maghoma", "England", "Brentford", "CM", 66, "Common", 6, "braids", "#16161A", false, 71, 60, 66, 68, 60, 64),
	c("kim_j", "Kim Ji-soo", "South Korea", "Brentford", "CB", 65, "Common", 2, "short", "#141418", false, 70, 38, 60, 61, 66, 68),
	c("fort_h", "Héctor Fort", "Spain", "Barcelona", "RB", 69, "Common", 2, "short", "#3B281E", false, 77, 52, 67, 70, 67, 65),
	c("gerard_m", "Gerard Martín", "Spain", "Barcelona", "LB", 68, "Common", 2, "short", "#4A3425", false, 75, 48, 65, 66, 67, 66),
	c("dominguez_s", "Sergi Domínguez", "Spain", "Barcelona", "CB", 66, "Common", 2, "short", "#3B281E", false, 68, 38, 64, 63, 67, 66),
	c("bernal", "Marc Bernal", "Spain", "Barcelona", "CDM", 68, "Common", 2, "short", "#5A402C", false, 67, 55, 70, 69, 68, 70),
	c("pau_v", "Pau Víctor", "Spain", "Barcelona", "ST", 69, "Common", 2, "short", "#32231A", false, 75, 70, 63, 70, 35, 66),
	c("asencio_r", "Raúl Asencio", "Spain", "Real Madrid", "CB", 69, "Common", 2, "short", "#281D16", false, 76, 40, 64, 64, 70, 71),
	c("jacobo_r", "Jacobo Ramón", "Spain", "Real Madrid", "CB", 64, "Common", 2, "short", "#4A3425", false, 67, 35, 58, 59, 65, 66),
	c("chema", "Chema Andrés", "Spain", "Real Madrid", "CDM", 64, "Common", 2, "short", "#3B281E", false, 65, 50, 65, 64, 64, 66),
	c("mbaye", "Ibrahim Mbaye", "France", "Paris Saint-Germain", "RW", 66, "Common", 6, "buzz", "#16161A", false, 82, 61, 61, 71, 34, 58),
}

local byRarity: { [Rarity]: { Footballer } } = {
	Common = {},
	Rare = {},
	Epic = {},
	Legendary = {},
	Mythic = {},
}
local byId: { [string]: Footballer } = {}

for _, card in POOL do
	table.insert(byRarity[card.rarity], card)
	byId[card.id] = card
end

local Footballers = {
	All = table.freeze(POOL),
	ByRarity = table.freeze(byRarity),
	ById = table.freeze(byId),
	SKIN_TONES = SKIN_TONES,
	CLUB_KITS = CLUB_KITS,
}

function Footballers.getDisplayName(card: { name: string }): string
	return card.name
end

function Footballers.getKit(card: { club: string }): ClubKit
	return CLUB_KITS[card.club] or DEFAULT_KIT
end

function Footballers.getSkinColor(card: { skin: number }): Color3
	return SKIN_TONES[math.clamp(card.skin or 3, 1, #SKIN_TONES)]
end

return table.freeze(Footballers)

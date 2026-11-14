--!strict
--[[
	Footballers
	Responsibility: Master pool of 150 real footballers (6 Mythic, 14 Legend, 30 Epic, 40 Rare, 35 Uncommon, 25 Common) with real full names, real clubs, real countries, 6 FIFA attributes, appearance traits, and official club kit definitions.
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
	["Atlético Madrid"] = k("#CB3524", "#FFFFFF", "#CB3524", "#1D3557", "#CB3524", "#FFFFFF", "stripes"),
	["Al-Hilal"] = k("#0054A6", "#FFFFFF", "#0054A6", "#0054A6", "#0054A6", "#FFFFFF", "solid"),
	["Al-Ittihad"] = k("#FFD21F", "#14161C", "#14161C", "#14161C", "#14161C", "#FFD21F", "stripes"),
	["Napoli"] = k("#0082C8", "#FFFFFF", "#0082C8", "#FFFFFF", "#0082C8", "#FFFFFF", "solid"),
	["PSG"] = k("#004170", "#DA291C", "#004170", "#004170", "#004170", "#FFFFFF", "center"),
	["Al Nassr"] = k("#FFD21F", "#0054A6", "#0054A6", "#0054A6", "#FFD21F", "#0054A6", "solid"),
	["Al Ittihad"] = k("#FFD21F", "#14161C", "#14161C", "#14161C", "#14161C", "#FFD21F", "stripes"),
	["Tottenham Hotspur"] = k("#F8FAFC", "#132257", "#132257", "#132257", "#F8FAFC", "#132257", "solid"),
	["West Ham United"] = k("#7A263A", "#1BB1E7", "#1BB1E7", "#FFFFFF", "#7A263A", "#1BB1E7", "solid"),
	["LAFC"] = k("#14161C", "#C39E6D", "#14161C", "#14161C", "#14161C", "#C39E6D", "solid"),
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
	-- MYTHIC (6) | OVR 93-95
	-- =========================================================
	c("mbappe", "Kylian Mbappé", "France", "Real Madrid", "ST", 95, "Mythic", 6, "buzz", "#181616", false, 97, 90, 80, 92, 36, 78),
	c("haaland", "Erling Haaland", "Norway", "Manchester City", "ST", 95, "Mythic", 1, "bun", "#E8C868", false, 89, 93, 66, 80, 45, 88),
	c("messi", "Lionel Messi", "Argentina", "Inter Miami", "RW", 94, "Mythic", 2, "short", "#543927", true, 80, 87, 90, 94, 33, 64),
	c("bellingham", "Jude Bellingham", "England", "Real Madrid", "CAM", 94, "Mythic", 6, "buzz", "#16161A", false, 82, 84, 85, 88, 78, 82),
	c("vinicius", "Vinícius Júnior", "Brazil", "Real Madrid", "LW", 94, "Mythic", 6, "buzz", "#141418", true, 95, 82, 81, 90, 29, 68),
	c("ronaldo", "Cristiano Ronaldo", "Portugal", "Al Nassr", "ST", 93, "Mythic", 3, "short", "#141418", false, 77, 88, 75, 79, 34, 74),
	-- =========================================================
	-- LEGEND (14) | OVR 89-92
	-- =========================================================
	c("debruyne", "Kevin De Bruyne", "Belgium", "Napoli", "CM", 92, "Legend", 1, "short", "#D9A45B", true, 72, 85, 94, 87, 65, 78),
	c("rodri", "Rodri", "Spain", "Manchester City", "CDM", 92, "Legend", 3, "short", "#543927", false, 58, 73, 86, 79, 85, 84),
	c("kane", "Harry Kane", "England", "Bayern Munich", "ST", 91, "Legend", 2, "short", "#DEC06B", true, 69, 93, 84, 83, 49, 83),
	c("salah", "Mohamed Salah", "Egypt", "Liverpool", "RW", 90, "Legend", 4, "curly", "#151518", true, 89, 87, 81, 88, 45, 76),
	c("vandijk", "Virgil van Dijk", "Netherlands", "Liverpool", "CB", 90, "Legend", 4, "bun", "#16161A", true, 78, 60, 71, 72, 89, 86),
	c("alisson", "Alisson Becker", "Brazil", "Liverpool", "GK", 90, "Legend", 3, "short", "#543927", true, 86, 85, 85, 89, 54, 90),
	c("courtois", "Thibaut Courtois", "Belgium", "Real Madrid", "GK", 90, "Legend", 2, "short", "#543927", false, 85, 89, 76, 93, 46, 90),
	c("lewandowski", "Robert Lewandowski", "Poland", "Barcelona", "ST", 89, "Legend", 2, "short", "#543927", false, 75, 91, 80, 82, 44, 84),
	c("griezmann", "Antoine Griezmann", "France", "Atlético Madrid", "CAM", 89, "Legend", 2, "long", "#EAD17E", true, 80, 88, 88, 88, 52, 72),
	c("son", "Heung Min Son", "South Korea", "LAFC", "LW", 89, "Legend", 2, "long", "#141418", false, 87, 89, 80, 84, 42, 69),
	c("ter_stegen", "Marc-André ter Stegen", "Germany", "Barcelona", "GK", 89, "Legend", 1, "short", "#DEC06B", true, 86, 85, 90, 86, 47, 85),
	c("bernardo", "Bernardo Silva", "Portugal", "Manchester City", "CM", 89, "Legend", 3, "short", "#543927", true, 69, 78, 86, 92, 61, 60),
	c("dias", "Rúben Dias", "Portugal", "Manchester City", "CB", 89, "Legend", 3, "short", "#543927", false, 62, 39, 66, 68, 89, 87),
	c("foden", "Phil Foden", "England", "Manchester City", "RW", 89, "Legend", 2, "buzz", "#543927", false, 82, 79, 81, 89, 47, 60),
	-- =========================================================
	-- EPIC (30) | OVR 86-88
	-- =========================================================
	c("saka", "Bukayo Saka", "England", "Arsenal", "RW", 88, "Epic", 6, "braids", "#141418", false, 83, 81, 82, 87, 65, 68),
	c("valverde", "Federico Valverde", "Uruguay", "Real Madrid", "CM", 88, "Epic", 2, "short", "#543927", false, 88, 81, 84, 84, 80, 82),
	c("musiala", "Jamal Musiala", "Germany", "Bayern Munich", "CAM", 88, "Epic", 4, "curly", "#181618", false, 88, 77, 79, 92, 39, 58),
	c("wirtz", "Florian Wirtz", "Germany", "Bayer Leverkusen", "CAM", 88, "Epic", 2, "short", "#6B4C33", false, 77, 80, 86, 88, 50, 60),
	c("odegaard", "Martin Ødegaard", "Norway", "Arsenal", "CAM", 88, "Epic", 1, "short", "#C89D54", false, 75, 80, 89, 88, 58, 63),
	c("ederson", "Ederson", "Brazil", "Manchester City", "GK", 88, "Epic", 3, "buzz", "#543927", true, 86, 82, 93, 86, 47, 88),
	c("oblak", "Jan Oblak", "Slovenia", "Atlético Madrid", "GK", 88, "Epic", 2, "short", "#543927", true, 83, 90, 77, 89, 43, 85),
	c("lautaro", "Lautaro Martínez", "Argentina", "Inter Milan", "ST", 88, "Epic", 3, "buzz", "#543927", false, 83, 86, 74, 85, 48, 84),
	c("osimhen", "Victor Osimhen", "Nigeria", "Galatasaray", "ST", 87, "Epic", 7, "buzz", "#EAD17E", false, 90, 85, 65, 78, 42, 83),
	c("leao", "Rafael Leão", "Portugal", "AC Milan", "LW", 87, "Epic", 6, "braids", "#16161A", true, 93, 77, 75, 87, 27, 77),
	c("barella", "Nicolò Barella", "Italy", "Inter Milan", "CM", 87, "Epic", 2, "short", "#6B4E35", false, 79, 76, 83, 84, 78, 81),
	c("bastoni", "Alessandro Bastoni", "Italy", "Inter Milan", "CB", 87, "Epic", 2, "short", "#4B3526", false, 73, 35, 74, 75, 86, 83),
	c("marquinhos", "Marquinhos", "Brazil", "PSG", "CB", 87, "Epic", 3, "short", "#16161A", false, 78, 42, 75, 74, 87, 80),
	c("dejong", "Frenkie de Jong", "Netherlands", "Barcelona", "CM", 87, "Epic", 1, "long", "#D6B064", false, 82, 69, 86, 87, 77, 78),
	c("gundogan", "İlkay Gündoğan", "Germany", "Manchester City", "CM", 87, "Epic", 3, "short", "#543927", true, 66, 81, 86, 85, 72, 72),
	c("emiliano_m", "Emiliano Martínez", "Argentina", "Aston Villa", "GK", 87, "Epic", 3, "buzz", "#543927", false, 85, 83, 82, 85, 45, 85),
	c("saliba", "William Saliba", "France", "Arsenal", "CB", 87, "Epic", 6, "buzz", "#16161A", false, 82, 39, 70, 72, 87, 82),
	c("rice", "Declan Rice", "England", "Arsenal", "CDM", 87, "Epic", 2, "short", "#543927", false, 71, 65, 81, 78, 84, 83),
	c("bruno_f", "Bruno Fernandes", "Portugal", "Manchester United", "CAM", 87, "Epic", 2, "short", "#543927", true, 71, 85, 88, 83, 69, 76),
	c("trent", "Trent Alexander-Arnold", "England", "Real Madrid", "RB", 86, "Epic", 5, "braids", "#16161A", false, 76, 71, 90, 80, 80, 73),
	c("kvaratskhelia", "Khvicha Kvaratskhelia", "Georgia", "Napoli", "LW", 86, "Epic", 2, "long", "#543927", true, 84, 80, 81, 87, 41, 73),
	c("dembele", "Ousmane Dembélé", "France", "PSG", "RW", 86, "Epic", 6, "buzz", "#16161A", false, 93, 77, 81, 88, 36, 57),
	c("hakimi", "Achraf Hakimi", "Morocco", "PSG", "RB", 86, "Epic", 4, "buzz", "#16161A", true, 92, 75, 80, 81, 76, 78),
	c("theo", "Theo Hernández", "France", "AC Milan", "LB", 86, "Epic", 3, "buzz", "#543927", false, 95, 71, 76, 81, 78, 82),
	c("davies", "Alphonso Davies", "Canada", "Bayern Munich", "LB", 86, "Epic", 6, "braids", "#16161A", false, 95, 68, 77, 84, 76, 77),
	c("araujo", "Ronald Araújo", "Uruguay", "Barcelona", "CB", 86, "Epic", 4, "buzz", "#16161A", false, 79, 43, 61, 62, 86, 84),
	c("pedri", "Pedri", "Spain", "Barcelona", "CM", 86, "Epic", 2, "short", "#543927", false, 78, 67, 88, 88, 70, 63),
	c("yamal", "Lamine Yamal", "Spain", "Barcelona", "RW", 86, "Epic", 5, "buzz", "#16161A", false, 82, 76, 82, 87, 33, 54),
	c("palmer", "Cole Palmer", "England", "Chelsea", "CAM", 86, "Epic", 2, "buzz", "#543927", false, 78, 83, 84, 85, 42, 55),
	c("gabriel_m", "Gabriel Magalhães", "Brazil", "Arsenal", "CB", 86, "Epic", 4, "short", "#181616", true, 68, 40, 63, 60, 86, 84),
	-- =========================================================
	-- RARE (40) | OVR 83-85
	-- =========================================================
	c("tchouameni", "Aurélien Tchouaméni", "France", "Real Madrid", "CDM", 85, "Rare", 6, "buzz", "#16161A", false, 73, 70, 79, 81, 82, 82),
	c("camavinga", "Eduardo Camavinga", "France", "Real Madrid", "CM", 85, "Rare", 6, "braids", "#16161A", false, 79, 66, 80, 83, 80, 81),
	c("rodrygo", "Rodrygo", "Brazil", "Real Madrid", "RW", 85, "Rare", 4, "buzz", "#16161A", false, 88, 82, 79, 86, 32, 60),
	c("militao", "Eder Militão", "Brazil", "Real Madrid", "CB", 85, "Rare", 5, "buzz", "#16161A", false, 85, 50, 70, 72, 85, 82),
	c("luis_diaz", "Luis Díaz", "Colombia", "Liverpool", "LW", 85, "Rare", 4, "short", "#181616", false, 91, 75, 75, 87, 34, 73),
	c("macallister", "Alexis Mac Allister", "Argentina", "Liverpool", "CM", 85, "Rare", 2, "short", "#7D4427", true, 70, 79, 85, 84, 74, 76),
	c("jota", "Diogo Jota", "Portugal", "Liverpool", "ST", 85, "Rare", 2, "short", "#543927", false, 82, 84, 76, 84, 55, 75),
	c("robertson", "Andy Robertson", "Scotland", "Liverpool", "LB", 85, "Rare", 1, "short", "#5E402B", false, 80, 61, 82, 81, 81, 76),
	c("kimmich", "Joshua Kimmich", "Germany", "Bayern Munich", "CDM", 85, "Rare", 2, "short", "#DEC06B", true, 68, 73, 86, 82, 81, 78),
	c("frimpong", "Jeremie Frimpong", "Netherlands", "Liverpool", "RB", 85, "Rare", 6, "braids", "#16161A", false, 94, 68, 76, 84, 76, 66),
	c("grimaldo", "Alejandro Grimaldo", "Spain", "Bayer Leverkusen", "LB", 85, "Rare", 4, "short", "#543927", false, 84, 76, 86, 85, 76, 70),
	c("calhanoglu", "Hakan Çalhanoğlu", "Turkey", "Inter Milan", "CM", 85, "Rare", 2, "short", "#543927", false, 66, 79, 86, 82, 71, 68),
	c("maignan", "Mike Maignan", "France", "AC Milan", "GK", 85, "Rare", 6, "short", "#16161A", true, 85, 82, 85, 88, 50, 85),
	c("rashford", "Marcus Rashford", "England", "Manchester United", "LW", 84, "Rare", 6, "buzz", "#16161A", true, 90, 83, 78, 84, 42, 74),
	c("lisandro_m", "Lisandro Martínez", "Argentina", "Manchester United", "CB", 84, "Rare", 2, "short", "#543927", false, 71, 45, 78, 78, 84, 81),
	c("deligt", "Matthijs de Ligt", "Netherlands", "Manchester United", "CB", 84, "Rare", 1, "short", "#C89D54", false, 66, 59, 72, 69, 84, 86),
	c("sane", "Leroy Sané", "Germany", "Bayern Munich", "RM", 84, "Rare", 5, "braids", "#16161A", false, 91, 81, 79, 85, 38, 63),
	c("coman", "Kingsley Coman", "France", "Bayern Munich", "LM", 84, "Rare", 6, "buzz", "#16161A", false, 89, 76, 77, 86, 30, 57),
	c("goretzka", "Leon Goretzka", "Germany", "Bayern Munich", "CM", 84, "Rare", 2, "short", "#4B3526", false, 78, 82, 81, 82, 80, 86),
	c("upamecano", "Dayot Upamecano", "France", "Bayern Munich", "CB", 84, "Rare", 7, "buzz", "#16161A", false, 82, 42, 67, 68, 84, 83),
	c("kim_mj", "Kim Min Jae", "South Korea", "Bayern Munich", "CB", 84, "Rare", 2, "short", "#141418", false, 80, 33, 63, 64, 84, 84),
	c("xhaka", "Granit Xhaka", "Switzerland", "Bayer Leverkusen", "CDM", 84, "Rare", 2, "short", "#543927", false, 48, 74, 84, 78, 76, 81),
	c("isak", "Alexander Isak", "Sweden", "Liverpool", "ST", 84, "Rare", 6, "buzz", "#16161A", false, 83, 82, 73, 82, 30, 73),
	c("bruno_g", "Bruno Guimarães", "Brazil", "Newcastle United", "CM", 84, "Rare", 2, "short", "#543927", true, 70, 73, 82, 83, 79, 82),
	c("watkins", "Ollie Watkins", "England", "Aston Villa", "ST", 84, "Rare", 5, "buzz", "#543927", false, 85, 83, 72, 80, 38, 74),
	c("bremer", "Gleison Bremer", "Brazil", "Juventus", "CB", 84, "Rare", 6, "buzz", "#16161A", false, 78, 45, 55, 60, 85, 85),
	c("vlahovic", "Dušan Vlahović", "Serbia", "Juventus", "ST", 84, "Rare", 2, "short", "#543927", false, 79, 84, 66, 78, 28, 81),
	c("pavard", "Benjamin Pavard", "France", "Inter Milan", "CB", 84, "Rare", 2, "short", "#4B3526", false, 71, 60, 76, 75, 84, 80),
	c("cancelo", "João Cancelo", "Portugal", "Barcelona", "RB", 84, "Rare", 3, "buzz", "#543927", true, 80, 73, 85, 84, 79, 70),
	c("raphinha", "Raphinha", "Brazil", "Barcelona", "RW", 84, "Rare", 4, "short", "#181616", false, 91, 79, 80, 84, 50, 66),
	c("kounde", "Jules Koundé", "France", "Barcelona", "RB", 84, "Rare", 6, "braids", "#16161A", false, 83, 45, 71, 75, 84, 78),
	c("gavi", "Gavi", "Spain", "Barcelona", "CM", 84, "Rare", 2, "long", "#3B281E", false, 76, 67, 80, 85, 69, 70),
	c("gordon", "Anthony Gordon", "England", "Newcastle United", "LW", 83, "Rare", 1, "short", "#DFBC6A", false, 89, 75, 76, 82, 49, 64),
	c("douglas_luiz", "Douglas Luiz", "Brazil", "Juventus", "CM", 83, "Rare", 5, "buzz", "#16161A", true, 73, 74, 82, 81, 78, 78),
	c("chiesa", "Federico Chiesa", "Italy", "Liverpool", "RW", 83, "Rare", 2, "short", "#543927", false, 90, 80, 76, 85, 45, 69),
	c("thuram", "Marcus Thuram", "France", "Inter Milan", "ST", 83, "Rare", 6, "buzz", "#16161A", true, 85, 81, 73, 82, 35, 81),
	c("tomori", "Fikayo Tomori", "England", "AC Milan", "CB", 83, "Rare", 6, "buzz", "#16161A", false, 86, 40, 63, 68, 83, 80),
	c("pulisic", "Christian Pulisic", "United States", "AC Milan", "RW", 83, "Rare", 2, "short", "#4A3425", true, 89, 75, 74, 84, 37, 59),
	c("joao_felix", "João Félix", "Portugal", "Chelsea", "LW", 83, "Rare", 2, "short", "#543927", false, 81, 78, 79, 85, 40, 60),
	c("balde", "Alejandro Balde", "Spain", "Barcelona", "LB", 83, "Rare", 6, "buzz", "#16161A", false, 91, 55, 73, 80, 76, 66),
	-- =========================================================
	-- UNCOMMON (35) | OVR 80-82
	-- =========================================================
	c("mainoo", "Kobbie Mainoo", "England", "Manchester United", "CM", 82, "Uncommon", 6, "braids", "#16161A", false, 76, 68, 79, 83, 73, 73),
	c("garnacho", "Alejandro Garnacho", "Argentina", "Manchester United", "LW", 82, "Uncommon", 2, "long", "#EAD17E", false, 86, 75, 72, 83, 36, 57),
	c("hojlund_r", "Rasmus Højlund", "Denmark", "Manchester United", "ST", 82, "Uncommon", 1, "long", "#D8B263", false, 85, 80, 63, 74, 40, 82),
	c("gakpo", "Cody Gakpo", "Netherlands", "Liverpool", "LW", 82, "Uncommon", 5, "buzz", "#16161A", false, 83, 80, 78, 81, 41, 74),
	c("nunez", "Darwin Núñez", "Uruguay", "Liverpool", "ST", 82, "Uncommon", 2, "bun", "#543927", false, 90, 81, 71, 78, 42, 83),
	c("szoboszlai", "Dominik Szoboszlai", "Hungary", "Liverpool", "CM", 82, "Uncommon", 2, "short", "#543927", true, 82, 82, 82, 82, 62, 72),
	c("trossard", "Leandro Trossard", "Belgium", "Arsenal", "LW", 82, "Uncommon", 2, "short", "#DEC06B", true, 79, 80, 79, 83, 44, 59),
	c("martinelli", "Gabriel Martinelli", "Brazil", "Arsenal", "LW", 82, "Uncommon", 3, "short", "#16161A", false, 89, 78, 73, 84, 45, 69),
	c("havertz", "Kai Havertz", "Germany", "Arsenal", "ST", 82, "Uncommon", 1, "short", "#4B3526", false, 78, 79, 80, 82, 55, 72),
	c("ben_white", "Ben White", "England", "Arsenal", "RB", 82, "Uncommon", 3, "buzz", "#543927", true, 77, 45, 75, 76, 81, 77),
	c("kulusevski", "Dejan Kulusevski", "Sweden", "Tottenham Hotspur", "RW", 82, "Uncommon", 1, "curly", "#543927", false, 80, 77, 81, 83, 57, 76),
	c("van_de_ven", "Micky van de Ven", "Netherlands", "Tottenham Hotspur", "CB", 82, "Uncommon", 2, "short", "#DEC06B", false, 88, 40, 64, 68, 81, 81),
	c("vicario", "Guglielmo Vicario", "Italy", "Tottenham Hotspur", "GK", 82, "Uncommon", 2, "short", "#3B281E", false, 84, 80, 81, 84, 42, 80),
	c("enzo_f", "Enzo Fernández", "Argentina", "Chelsea", "CM", 82, "Uncommon", 2, "buzz", "#543927", false, 68, 75, 84, 81, 71, 72),
	c("caicedo", "Moisés Caicedo", "Ecuador", "Chelsea", "CDM", 82, "Uncommon", 6, "buzz", "#16161A", false, 74, 62, 77, 78, 79, 81),
	c("reece_james", "Reece James", "England", "Chelsea", "RB", 82, "Uncommon", 6, "buzz", "#16161A", true, 78, 73, 82, 81, 79, 82),
	c("botman", "Sven Botman", "Netherlands", "Newcastle United", "CB", 82, "Uncommon", 1, "short", "#DEC06B", false, 65, 35, 63, 60, 83, 84),
	c("paqueta", "Lucas Paquetá", "Brazil", "West Ham United", "CAM", 82, "Uncommon", 3, "buzz", "#543927", true, 75, 77, 81, 84, 66, 78),
	c("bowen", "Jarrod Bowen", "England", "West Ham United", "RM", 82, "Uncommon", 2, "short", "#543B29", false, 84, 80, 76, 81, 45, 72),
	c("kudus", "Mohammed Kudus", "Ghana", "West Ham United", "RW", 82, "Uncommon", 7, "braids", "#16161A", false, 88, 77, 76, 86, 56, 79),
	c("diaby", "Moussa Diaby", "France", "Al Ittihad", "RM", 82, "Uncommon", 6, "buzz", "#16161A", false, 93, 75, 73, 83, 40, 56),
	c("pau_torres", "Pau Torres", "Spain", "Aston Villa", "CB", 82, "Uncommon", 2, "short", "#3B281E", false, 69, 35, 74, 71, 82, 78),
	c("xavi_simons", "Xavi Simons", "Netherlands", "RB Leipzig", "CAM", 82, "Uncommon", 4, "braids", "#543927", false, 84, 78, 81, 85, 55, 64),
	c("openda", "Loïs Openda", "Belgium", "RB Leipzig", "ST", 82, "Uncommon", 6, "buzz", "#16161A", false, 93, 82, 70, 80, 32, 75),
	c("dani_olmo", "Dani Olmo", "Spain", "Barcelona", "CAM", 82, "Uncommon", 2, "short", "#3B281E", false, 76, 78, 83, 86, 53, 62),
	c("zaire_emery", "Warren Zaïre-Emery", "France", "PSG", "CM", 82, "Uncommon", 6, "buzz", "#16161A", false, 78, 68, 79, 81, 74, 75),
	c("mount", "Mason Mount", "England", "Manchester United", "CAM", 81, "Uncommon", 2, "short", "#4A3425", true, 74, 77, 82, 82, 55, 63),
	c("timber", "Jurriën Timber", "Netherlands", "Arsenal", "CB", 81, "Uncommon", 6, "buzz", "#16161A", false, 82, 45, 72, 78, 81, 78),
	c("richarlison", "Richarlison", "Brazil", "Tottenham Hotspur", "ST", 81, "Uncommon", 4, "buzz", "#543927", false, 79, 80, 72, 80, 48, 79),
	c("porro", "Pedro Porro", "Spain", "Tottenham Hotspur", "RB", 81, "Uncommon", 4, "short", "#3B281E", true, 82, 73, 79, 80, 77, 74),
	c("jackson", "Nicolas Jackson", "Senegal", "Chelsea", "ST", 81, "Uncommon", 7, "buzz", "#16161A", false, 85, 78, 68, 78, 35, 76),
	c("barcola", "Bradley Barcola", "France", "PSG", "LW", 81, "Uncommon", 6, "braids", "#16161A", false, 89, 75, 75, 84, 38, 64),
	c("antony", "Antony", "Brazil", "Manchester United", "RW", 80, "Uncommon", 4, "buzz", "#181616", true, 86, 73, 74, 83, 45, 61),
	c("harvey_e", "Harvey Elliott", "England", "Liverpool", "CAM", 80, "Uncommon", 2, "long", "#8C6843", false, 75, 72, 80, 82, 55, 60),
	c("mudryk", "Mykhailo Mudryk", "Ukraine", "Chelsea", "LW", 80, "Uncommon", 1, "short", "#DFBC6A", false, 91, 71, 72, 79, 45, 58),
	-- =========================================================
	-- COMMON (25) | OVR 75-79
	-- =========================================================
	c("endo", "Wataru Endo", "Japan", "Liverpool", "CDM", 79, "Common", 2, "short", "#141418", false, 65, 64, 74, 74, 78, 80),
	c("maguire", "Harry Maguire", "England", "Manchester United", "CB", 79, "Common", 2, "short", "#3B281E", false, 48, 52, 68, 65, 79, 82),
	c("mctominay", "Scott McTominay", "Scotland", "Napoli", "CM", 79, "Common", 1, "short", "#543B29", false, 70, 72, 74, 73, 75, 83),
	c("werner", "Timo Werner", "Germany", "Tottenham Hotspur", "ST", 79, "Common", 1, "short", "#6E4E32", false, 90, 74, 71, 78, 35, 64),
	c("b_johnson", "Brennan Johnson", "Wales", "Tottenham Hotspur", "RW", 79, "Common", 2, "buzz", "#543927", false, 88, 74, 71, 78, 42, 65),
	c("gallagher", "Conor Gallagher", "England", "Atlético Madrid", "CM", 79, "Common", 1, "short", "#C89D54", false, 75, 71, 76, 77, 73, 77),
	c("madueke", "Noni Madueke", "England", "Chelsea", "RW", 79, "Common", 6, "braids", "#16161A", false, 86, 72, 72, 82, 36, 58),
	c("smith_rowe", "Emile Smith Rowe", "England", "Fulham", "CAM", 79, "Common", 2, "short", "#DEC06B", false, 77, 74, 77, 81, 45, 61),
	c("almiron", "Miguel Almirón", "Paraguay", "Newcastle United", "RW", 79, "Common", 2, "short", "#1C1816", false, 86, 72, 74, 78, 52, 62),
	c("soucek", "Tomás Souček", "Czech Republic", "West Ham United", "CDM", 79, "Common", 1, "short", "#7A583B", true, 60, 73, 73, 74, 77, 84),
	c("pickford", "Jordan Pickford", "England", "Everton", "GK", 79, "Common", 1, "short", "#DEC06B", false, 82, 78, 83, 84, 45, 80),
	c("lindelof", "Victor Lindelöf", "Sweden", "Manchester United", "CB", 78, "Common", 1, "short", "#543B29", false, 65, 45, 71, 69, 79, 76),
	c("wan_bissaka", "Aaron Wan-Bissaka", "England", "West Ham United", "RB", 78, "Common", 6, "braids", "#16161A", false, 82, 42, 66, 75, 81, 72),
	c("dier", "Eric Dier", "England", "Bayern Munich", "CB", 78, "Common", 2, "short", "#4A3425", true, 52, 60, 68, 65, 78, 80),
	c("nketiah", "Eddie Nketiah", "England", "Arsenal", "ST", 78, "Common", 6, "braids", "#16161A", false, 82, 77, 64, 76, 33, 63),
	c("dan_burn", "Dan Burn", "England", "Newcastle United", "CB", 78, "Common", 1, "short", "#DEC06B", false, 52, 36, 63, 60, 78, 82),
	c("calvert_lewin", "Dominic Calvert-Lewin", "England", "Everton", "ST", 78, "Common", 4, "buzz", "#543927", false, 78, 77, 63, 74, 42, 83),
	c("ben_davies", "Ben Davies", "Wales", "Tottenham Hotspur", "LB", 77, "Common", 2, "short", "#4A3425", false, 66, 55, 70, 70, 76, 75),
	c("chalobah", "Trevoh Chalobah", "England", "Crystal Palace", "CB", 77, "Common", 6, "braids", "#16161A", false, 72, 44, 66, 68, 77, 76),
	c("longstaff", "Sean Longstaff", "England", "Newcastle United", "CM", 77, "Common", 1, "short", "#5E402B", false, 68, 68, 73, 71, 71, 76),
	c("antonio", "Michail Antonio", "Jamaica", "West Ham United", "ST", 77, "Common", 6, "bald", "#16161A", true, 76, 75, 68, 75, 45, 83),
	c("phillips", "Kalvin Phillips", "England", "West Ham United", "CDM", 76, "Common", 2, "braids", "#DEC06B", false, 66, 66, 75, 73, 74, 76),
	c("reiss_nelson", "Reiss Nelson", "England", "Arsenal", "RW", 76, "Common", 6, "buzz", "#16161A", false, 83, 68, 70, 78, 42, 55),
	c("j_murphy", "Jacob Murphy", "England", "Newcastle United", "RW", 76, "Common", 4, "buzz", "#543927", false, 83, 69, 71, 75, 50, 60),
	c("jonny_evans", "Jonny Evans", "Northern Ireland", "Manchester United", "CB", 75, "Common", 1, "short", "#3B281E", false, 45, 40, 60, 62, 77, 74),
}
local byRarity: { [Rarity]: { Footballer } } = {
	Common = {},
	Uncommon = {},
	Rare = {},
	Epic = {},
	Legend = {},
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

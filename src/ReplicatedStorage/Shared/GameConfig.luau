--!strict
--[[
	GameConfig
	Responsibility: Shared constants, tuning parameters, rarities, titles, and color palette.
	Loop step: action | reward | progression
	Location: ReplicatedStorage/Shared/GameConfig (ModuleScript)
]]

export type AttributeKey = "PAC" | "SHO" | "PAS" | "DRI" | "DEF" | "PHY"
export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legend" | "Mythic"
export type Grade = "S" | "A" | "B" | "C" | "D"

local GameConfig = {
	ATTRIBUTES = table.freeze({ "SHO", "PAC", "DRI", "PAS", "DEF", "PHY" }) :: { AttributeKey },
	ATTRIBUTE_LABELS = table.freeze({
		SHO = "Shooting",
		PAC = "Pace",
		DRI = "Dribbling",
		PAS = "Passing",
		DEF = "Defending",
		PHY = "Physical",
	}),

	BOT_FILL_MIN = 2,
	BOT_FILL_MAX = 3,
	OPPONENT_ALERT_DELAY_SEC = 3,
	BUILD_TIME = 20,
	SHOWDOWN_TIME = 12,
	REMATCH_TIME = 30,

	DEFAULT_REROLLS = 1,
	DEFAULT_STEALS = 0,
	WIN_BUX = 100,
	LOSS_BUX = 25,
	FRIEND_BOOST_PER_FRIEND = 0.10,

	-- Bot picks the optimal empty slot with this probability (default fallback; MatchService scales by player wins)
	BOT_OPTIMAL_CHANCE = 0.85,
	BOT_STEAL_CHANCE = 0.0,

	RARITY_WEIGHTS = table.freeze({
		Common = 35,
		Uncommon = 25,
		Rare = 20,
		Epic = 12,
		Legend = 6,
		Mythic = 2,
	}),

	RARITY_ORDER = table.freeze({ "Common", "Uncommon", "Rare", "Epic", "Legend", "Mythic" }) :: { Rarity },

	RARITY_COLORS = table.freeze({
		Common = Color3.fromHex("#CD7F32"),
		Uncommon = Color3.fromHex("#22C55E"),
		Rare = Color3.fromHex("#34B6FF"),
		Epic = Color3.fromHex("#A855F7"),
		Legend = Color3.fromHex("#FFD21F"),
		Mythic = Color3.fromHex("#FF2E93"),
	}),

	UI_COLORS = table.freeze({
		RevealAll = Color3.fromHex("#A855F7"),
		SeeBest = Color3.fromHex("#FFB400"),
		Reroll = Color3.fromHex("#0A7A1A"),
		Steal = Color3.fromHex("#E5252A"),
		Shuffle = Color3.fromHex("#2FA7FF"),
		PlayerBlue = Color3.fromHex("#1E6FFF"),
		PlayerDarkBlue = Color3.fromHex("#0B3A8F"),
		BlueAvgBox = Color3.fromHex("#0B3A8F"),
		OppRed = Color3.fromHex("#D61F1F"),
		OppDarkRed = Color3.fromHex("#7A0A0A"),
		RedAvgBox = Color3.fromHex("#7A0A0A"),
		Rematch = Color3.fromHex("#FFA500"),
		SlotSquare = Color3.fromHex("#12161F"),
		PanelDark = Color3.fromHex("#1B1B2F"),
	}),

	TITLES = table.freeze({
		{ name = "Legend", minWins = 100, color = Color3.fromHex("#FFD21F") },
		{ name = "Captain", minWins = 50, color = Color3.fromHex("#A855F7") },
		{ name = "Starter", minWins = 15, color = Color3.fromHex("#1E6FFF") },
		{ name = "Rookie", minWins = 10, color = Color3.fromHex("#3DDC3D") },
		{ name = "Benchwarmer", minWins = 0, color = Color3.fromHex("#C0C0C0") },
	}),

	CHAIR_SKINS = table.freeze({
		{ id = "wood", name = "Classic Wood", cost = 0, color = Color3.fromRGB(124, 71, 40), mat = Enum.Material.WoodPlanks },
		{ id = "stadium", name = "Stadium Blue", cost = 300, color = Color3.fromHex("#1E6FFF"), mat = Enum.Material.SmoothPlastic },
		{ id = "cyber_core", name = "Cyber Core Chair", cost = 3500, color = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },
		{ id = "crimson", name = "Crimson Chair", cost = 6000, color = Color3.fromRGB(150, 15, 25), mat = Enum.Material.WoodPlanks },
		{ id = "frostbite", name = "Frostbite Chair", cost = 10000, color = Color3.fromRGB(120, 210, 255), mat = Enum.Material.Glass },
		{ id = "golden", name = "Football Throne", cost = 15000, color = Color3.fromRGB(255, 195, 30), mat = Enum.Material.SmoothPlastic },
		{ id = "lucky_clover", name = "Lucky Clover Chair", cost = 0, unlockSource = "JACKPOT", color = Color3.fromRGB(16, 160, 75), mat = Enum.Material.SmoothPlastic },
		{ id = "vip_black_diamond", name = "Black Diamond VIP", cost = 0, unlockSource = "VIP", color = Color3.fromRGB(30, 30, 35), mat = Enum.Material.DiamondPlate },
	}),

	DAILY_REWARDS = table.freeze({
		{ day = 1, label = "100 BUX", bux = 100, spins = 0, chair = nil },
		{ day = 2, label = "STADIUM CHAIR", bux = 0, spins = 0, chair = "stadium" },
		{ day = 3, label = "250 BUX", bux = 250, spins = 0, chair = nil },
		{ day = 4, label = "500 BUX", bux = 500, spins = 0, chair = nil },
		{ day = 5, label = "1000 BUX", bux = 1000, spins = 0, chair = nil },
		{ day = 6, label = "2 SPINS", bux = 0, spins = 2, chair = nil },
		-- shortcut: Day 7 rewards 2500 Bux until the dedicated free Day 7 chair model is ready
		{ day = 7, label = "2500 BUX", bux = 2500, spins = 0, chair = nil },
	}),

	PLAYTIME_REWARDS = table.freeze({
		{ id = "pt_1", seconds = 300, timeLabel = "5 MIN", rewardLabel = "$200", bux = 200, spins = 0, chair = nil },
		{ id = "pt_2", seconds = 600, timeLabel = "10 MIN", rewardLabel = "$500", bux = 500, spins = 0, chair = nil },
		{ id = "pt_3", seconds = 900, timeLabel = "15 MIN", rewardLabel = "$500", bux = 500, spins = 0, chair = nil },
		{ id = "pt_4", seconds = 1800, timeLabel = "30 MIN", rewardLabel = "$1K", bux = 1000, spins = 0, chair = nil },
		{ id = "pt_5", seconds = 3600, timeLabel = "1 HOUR", rewardLabel = "$5K + 2 SPINS", bux = 5000, spins = 2, chair = nil },
		{ id = "pt_6", seconds = 7200, timeLabel = "2 HOURS", rewardLabel = "$10K + CHAIR", bux = 10000, spins = 5, chair = "crimson" },
	}),

	QUESTS = table.freeze({
		{ id = "finish_match", title = "Finish a Match", target = 1, rewardLabel = "1 Wheel Spin + $150", bux = 150, spins = 1 },
		{ id = "vote_mythical", title = "Like the Game & Vote for the Next Mythical", target = 1, rewardLabel = "1 Wheel Spin + $150", bux = 150, spins = 1 },
		{ id = "complete_obby", title = "Complete the Obby & Claim the Free Gift", target = 1, rewardLabel = "$500", bux = 500, spins = 0 },
	}),

	GROUP_REWARD_BUX = 250,
	OBBY_REWARD_BUX = 500,
	OBBY_COOLDOWN_SEC = 14400,

	WHEEL_SEGMENTS = table.freeze({
		{ id = 1, label = "350\nBUX", oddsName = "350 BUX", oddsPct = "15.85%", oddsOrder = 6, icon = "💵", assetKey = "Icon_CashCube", color = "#22C55E", strokeColor = "#4ADE80", weight = 15.85, bux = 350, spins = 0, chair = nil, dupBux = 0, toast = "🎡 Wheel Prize: +$350 Bux!" },
		{ id = 2, label = "1 FREE\nSPIN", oddsName = "1 SPIN", oddsPct = "14.14%", oddsOrder = 5, icon = "🎡", assetKey = "Icon_Wheel", color = "#FACC15", strokeColor = "#FACC15", weight = 14.14, bux = 0, spins = 1, chair = nil, dupBux = 0, toast = "🎡 Wheel Prize: +1 Free Spin!" },
		{ id = 3, label = "GRAND\nPRIZE", oddsName = "JACKPOT", oddsPct = "0.99%", oddsOrder = 1, icon = "🍀", assetKey = "Icon_Chair_EmeraldPitch", color = "#EF4444", strokeColor = "#FFD21F", weight = 0.99, bux = 0, spins = 0, chair = "lucky_clover", dupBux = 1000, toast = "🎡 JACKPOT! Lucky Clover Chair Unlocked!" },
		{ id = 4, label = "1500\nBUX", oddsName = "1,500 BUX", oddsPct = "2.38%", oddsOrder = 2, icon = "🎁", assetKey = "Icon_Chest", color = "#10B981", strokeColor = "#22C55E", weight = 2.38, bux = 1500, spins = 0, chair = nil, dupBux = 0, toast = "🎡 Wheel Prize: +$1,500 Bux!" },
		{ id = 5, label = "STADIUM\nCHAIR", oddsName = "STADIUM CHAIR", oddsPct = "13.48%", oddsOrder = 4, icon = "🪑", assetKey = "Icon_Chair_StadiumBlue", color = "#38BDF8", strokeColor = "#38BDF8", weight = 13.48, bux = 0, spins = 0, chair = "stadium", dupBux = 300, toast = "🎡 Wheel Prize: Stadium Blue Chair Unlocked!" },
		{ id = 6, label = "3 FREE\nSPINS", oddsName = "3 SPINS", oddsPct = "4.76%", oddsOrder = 3, icon = "🎡", assetKey = "Icon_Wheel", color = "#A855F7", strokeColor = "#F59E0B", weight = 4.76, bux = 0, spins = 3, chair = nil, dupBux = 0, toast = "🎡 Wheel Prize: +3 Free Spins!" },
		{ id = 7, label = "CLASSIC\nWOOD", oddsName = "CLASSIC WOOD", oddsPct = "17.15%", oddsOrder = 7, icon = "🪑", assetKey = "Icon_Chair_ClassicWood", color = "#8B5CF6", strokeColor = "#A855F7", weight = 17.15, bux = 0, spins = 0, chair = "wood", dupBux = 150, toast = "🎡 Wheel Prize: Classic Wood Chair!" },
		{ id = 8, label = "100\nBUX", oddsName = "100 BUX", oddsPct = "31.25%", oddsOrder = 8, icon = "💵", assetKey = "Icon_CashCube", color = "#14B8A6", strokeColor = "#2DD4BF", weight = 31.25, bux = 100, spins = 0, chair = nil, dupBux = 0, toast = "🎡 Wheel Prize: +$100 Bux!" },
	}),

	LUCK_TIERS = table.freeze({
		{ luck = 1, cost = 0 },
		{ luck = 1.5, cost = 750 },
		{ luck = 2, cost = 2000 },
		{ luck = 3, cost = 5000 },
		{ luck = 5, cost = 12500 },
	}),

	MONETIZATION = table.freeze({
		-- Starter Pack (500 Bux + Crimson Chair | 4 Robux)
		starter_pack = { id = 3730645478, kind = "Product", name = "Starter Pack", robux = 4 },

		-- Permanent Perks (saved to Profile DataStore on purchase)
		vip = { id = 3730645426, kind = "Product", name = "VIP", robux = 19 },
		["2x_bux"] = { id = 3730645380, kind = "Product", name = "2X BUX", robux = 30 },
		["2x_wins"] = { id = 3730645347, kind = "Product", name = "2X WIN", robux = 30 },
		["2x_streak"] = { id = 3730645306, kind = "Product", name = "2X STREAK", robux = 30 },
		["2x_luck"] = { id = 3730645268, kind = "Product", name = "2X LUCK", robux = 45 },
		inf_rerolls = { id = 3730645220, kind = "Product", name = "INFINITY REROLLS", robux = 199 },

		-- Currency Packs (Developer Products for repeatable purchases)
		bux_300 = { id = 3730645154, kind = "Product", name = "300 BUX", robux = 5, bux = 300 },
		bux_1000 = { id = 3730645111, kind = "Product", name = "1000 BUX", robux = 19, bux = 1000 },
		bux_4000 = { id = 3730645071, kind = "Product", name = "4000 BUX", robux = 49, bux = 4000 },
		bux_15000 = { id = 3730645031, kind = "Product", name = "15000 BUX", robux = 149, bux = 15000 },

		-- Utilities
		skip_daily = { id = 3730808261, kind = "Product", name = "Skip day", robux = 11 },
		claim_all_daily = { id = 3730808299, kind = "Product", name = "Claim All", robux = 29 },

		-- Spin Wheel Packs (Developer Products for repeatable buys)
		spin_1 = { id = 0, kind = "Product", name = "1 Spin", robux = 6, spins = 1 },
		spin_5 = { id = 3730644808, kind = "Product", name = "+5 Spins", robux = 23, spins = 5 },
		spin_10 = { id = 3730644744, kind = "Product", name = "+10 Spins", robux = 36, spins = 10 },
		spin_first_offer = { id = 0, kind = "Product", name = "First Spin of Day (83% Off)", robux = 2, spins = 1 },

		-- In-Match Per-Session / Per-Use Consumables (Developer Products for repeatable buys)
		match_reroll = { id = 3730644846, kind = "Product", name = "Reroll", robux = 9 },
		match_reveal_all = { id = 3730644905, kind = "Product", name = "Reveal All", robux = 29 },
		match_see_best = { id = 3730644938, kind = "Product", name = "See Best", robux = 9 },
		match_steal = { id = 3730644975, kind = "Product", name = "Steal", robux = 39 },
	}),
}

function GameConfig.getNextLuckTier(currentLuck: number): { luck: number, cost: number }?
	for _, tier in GameConfig.LUCK_TIERS do
		if tier.luck > currentLuck + 0.01 then
			return tier
		end
	end
	return nil
end

function GameConfig.getChairSkin(chairId: string)
	for _, skin in GameConfig.CHAIR_SKINS do
		if skin.id == chairId then
			return skin
		end
	end
	if chairId == "emerald" then
		for _, skin in GameConfig.CHAIR_SKINS do
			if skin.id == "crimson" then
				return skin
			end
		end
	end
	if chairId == "cyber" then
		for _, skin in GameConfig.CHAIR_SKINS do
			if skin.id == "frostbite" then
				return skin
			end
		end
	end
	if chairId == "clover" then
		for _, skin in GameConfig.CHAIR_SKINS do
			if skin.id == "lucky_clover" then
				return skin
			end
		end
	end
	if chairId == "football_throne" or chairId == "royal" then
		for _, skin in GameConfig.CHAIR_SKINS do
			if skin.id == "golden" then
				return skin
			end
		end
	end
	if chairId == "vip" then
		for _, skin in GameConfig.CHAIR_SKINS do
			if skin.id == "vip_black_diamond" then
				return skin
			end
		end
	end
	return GameConfig.CHAIR_SKINS[1]
end

function GameConfig.getGrade(avgScore: number): Grade
	if avgScore >= 90 then
		return "S"
	elseif avgScore >= 80 then
		return "A"
	elseif avgScore >= 70 then
		return "B"
	elseif avgScore >= 60 then
		return "C"
	end
	return "D"
end

function GameConfig.getTitleForWins(wins: number): string
	for _, entry in GameConfig.TITLES do
		if wins >= entry.minWins then
			return entry.name
		end
	end
	return "Benchwarmer"
end

function GameConfig.getTitleColor(titleName: string): Color3
	for _, entry in GameConfig.TITLES do
		if string.lower(entry.name) == string.lower(titleName) then
			return entry.color
		end
	end
	return Color3.fromHex("#C0C0C0")
end

function GameConfig.formatPlaytime(totalSeconds: number): string
	local sec = math.max(0, math.floor(totalSeconds))
	local d = math.floor(sec / 86400)
	local h = math.floor((sec % 86400) / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	if d > 0 then
		return `{d}d {h}h`
	elseif h > 0 then
		return `{h}h {m}m`
	elseif m > 0 then
		return `{m}m {s}s`
	end
	return `{s}s`
end

return table.freeze(GameConfig)

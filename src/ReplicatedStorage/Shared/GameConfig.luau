--!strict
--[[
	GameConfig
	Responsibility: Shared constants, tuning parameters, rarities, titles, and color palette.
	Loop step: action | reward | progression
	Location: ReplicatedStorage/Shared/GameConfig (ModuleScript)
]]

export type AttributeKey = "PAC" | "SHO" | "PAS" | "DRI" | "DEF" | "PHY"
export type Rarity = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic"
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

	DEFAULT_REROLLS = 2,
	DEFAULT_STEALS = 1,
	WIN_BUX = 100,
	LOSS_BUX = 25,
	FRIEND_BOOST_PER_FRIEND = 0.10,

	-- Bot picks the optimal empty slot with this probability (~58% player win rate target)
	BOT_OPTIMAL_CHANCE = 0.60,
	BOT_STEAL_CHANCE = 0.0,

	RARITY_WEIGHTS = table.freeze({
		Common = 45,
		Rare = 30,
		Epic = 17,
		Legendary = 6,
		Mythic = 2,
	}),

	RARITY_ORDER = table.freeze({ "Common", "Rare", "Epic", "Legendary", "Mythic" }) :: { Rarity },

	RARITY_COLORS = table.freeze({
		Common = Color3.fromHex("#CD7F32"),
		Rare = Color3.fromHex("#C0C0C0"),
		Epic = Color3.fromHex("#FFD21F"),
		Legendary = Color3.fromHex("#A855F7"),
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
		{ id = "crimson", name = "Crimson Striker", cost = 500, color = Color3.fromHex("#E5252A"), mat = Enum.Material.SmoothPlastic },
		{ id = "emerald", name = "Emerald Pitch", cost = 1000, color = Color3.fromHex("#22C55E"), mat = Enum.Material.Neon },
		{ id = "cyber", name = "Neon Cyber", cost = 2000, color = Color3.fromHex("#A855F7"), mat = Enum.Material.Neon },
		{ id = "golden", name = "Golden Ballon d'Or", cost = 5000, color = Color3.fromHex("#FFD21F"), mat = Enum.Material.Neon },
	}),

	DAILY_REWARDS = table.freeze({
		{ day = 1, label = "100 BUX", bux = 100, spins = 0, chair = nil },
		{ day = 2, label = "STADIUM CHAIR", bux = 0, spins = 0, chair = "stadium" },
		{ day = 3, label = "250 BUX", bux = 250, spins = 0, chair = nil },
		{ day = 4, label = "500 BUX", bux = 500, spins = 0, chair = nil },
		{ day = 5, label = "1000 BUX", bux = 1000, spins = 0, chair = nil },
		{ day = 6, label = "2 SPINS", bux = 0, spins = 2, chair = nil },
		{ day = 7, label = "GOLDEN CHAIR", bux = 2500, spins = 0, chair = "golden" },
	}),

	PLAYTIME_REWARDS = table.freeze({
		{ id = "pt_1", seconds = 300, timeLabel = "5 MIN", rewardLabel = "$200", bux = 200, spins = 0, chair = nil },
		{ id = "pt_2", seconds = 600, timeLabel = "10 MIN", rewardLabel = "$500", bux = 500, spins = 0, chair = nil },
		{ id = "pt_3", seconds = 900, timeLabel = "15 MIN", rewardLabel = "$500", bux = 500, spins = 0, chair = nil },
		{ id = "pt_4", seconds = 1800, timeLabel = "30 MIN", rewardLabel = "$1K", bux = 1000, spins = 0, chair = nil },
		{ id = "pt_5", seconds = 3600, timeLabel = "1 HOUR", rewardLabel = "$5K + 2 SPINS", bux = 5000, spins = 2, chair = nil },
		{ id = "pt_6", seconds = 7200, timeLabel = "2 HOURS", rewardLabel = "$10K + CHAIR", bux = 10000, spins = 5, chair = "emerald" },
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
		{ id = 1, label = "$350", icon = "💵", color = "#C5E61A", weight = 10, bux = 350, chair = nil, toast = "🎡 Wheel Prize: +$350!" },
		{ id = 2, label = "$150", icon = "💵", color = "#1D7BF6", weight = 23, bux = 150, chair = nil, toast = "🎡 Wheel Prize: +$150!" },
		{ id = 3, label = "$350", icon = "💵", color = "#CBD5E1", weight = 10, bux = 350, chair = nil, toast = "🎡 Wheel Prize: +$350!" },
		{ id = 4, label = "GRAND\nPRIZE", icon = "🪑", color = "#C85A6E", weight = 8, bux = 500, chair = "cyber", toast = "🎡 JACKPOT! Neon Cyber Chair + $500!" },
		{ id = 5, label = "$750", icon = "💰", color = "#C26D27", weight = 9, bux = 750, chair = nil, toast = "🎡 Wheel Prize: +$750!" },
		{ id = 6, label = "$150", icon = "💵", color = "#C81E2B", weight = 22, bux = 150, chair = nil, toast = "🎡 Wheel Prize: +$150!" },
		{ id = 7, label = "$750", icon = "💰", color = "#D91CE5", weight = 8, bux = 750, chair = nil, toast = "🎡 Wheel Prize: +$750!" },
		{ id = 8, label = "$350", icon = "💵", color = "#1AD633", weight = 10, bux = 350, chair = nil, toast = "🎡 Wheel Prize: +$350!" },
	}),

	LUCK_TIERS = table.freeze({
		{ luck = 1, cost = 0 },
		{ luck = 1.5, cost = 750 },
		{ luck = 2, cost = 2000 },
		{ luck = 3, cost = 5000 },
		{ luck = 5, cost = 12500 },
	}),

	-- shortcut: id = 0 uses Studio/free fallback, replace 0 with published Roblox GamePass/DeveloperProduct IDs before live monetization launch
	MONETIZATION = table.freeze({
		vip = { id = 0, kind = "GamePass" },
		["2x_bux"] = { id = 0, kind = "GamePass" },
		["2x_wins"] = { id = 0, kind = "GamePass" },
		["2x_streak"] = { id = 0, kind = "GamePass" },
		inf_rerolls = { id = 0, kind = "GamePass" },
		starter_pack = { id = 0, kind = "Product" },
		skip_daily = { id = 0, kind = "Product" },
		claim_all_daily = { id = 0, kind = "Product" },
		["2x_luck"] = { id = 0, kind = "GamePass" },
		bux_300 = { id = 0, kind = "Product" },
		bux_1000 = { id = 0, kind = "Product" },
		bux_4000 = { id = 0, kind = "Product" },
		bux_15000 = { id = 0, kind = "Product" },
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

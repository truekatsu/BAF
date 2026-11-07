--!strict
--[[
	LeaderboardConfig
	Responsibility: Configuration table for the 4 stylized cartoon football leaderboards
	(TOP WINS, TOP STREAKS, TOP CASH, TOP PLAYTIME) and backend OrderedDataStores.
	Location: ReplicatedStorage/Shared/LeaderboardConfig (ModuleScript)
]]

export type BoardStatKey = "Wins" | "Streak" | "Cash" | "Playtime" | "Bux"

export type BoardConfig = {
	statKey: BoardStatKey,
	title: string,
	titleIcon: string,
	valueHeader: string,
	accentColor: Color3,
	dataStoreKey: string,
	store: string,
	stat: string,
	refresh: number,
	size: number,
	formatKind: "Compact" | "Raw" | "Currency" | "Time",
	position: Vector3,
	lookTarget: Vector3,
}

local LeaderboardConfig = {
	-- General Refresh & Sizing
	REFRESH_INTERVAL_SEC = 60,
	BOARD_SIZE = Vector3.new(18.0, 24.0, 1.2),
	SCREEN_SIZE = Vector2.new(14.0, 18.0),
	PODIUM_SIZE = Vector3.new(3.6, 3.2, 3.6),
	PODIUM_HEIGHT = 4.0,
	ROW_HEIGHT_STUDS = 3.3,
	ROW_COUNT = 10,
	SPOTLIGHT_BRIGHTNESS = 1.5,
	PIXELS_PER_STUD = 50,
	MAX_DISTANCE = 150,

	-- Season & Backend Settings
	SEASON = 1,
	DEBUG_MODE = false,
	STREAK_USE_DISPLAYED_VALUE = true,
	PLAYTIME_ACTIVE_ONLY = false,
	ALLOW_LIVE_TEST = false,
	MAX_RANK_SCAN = 1000,
	RATE_LIMIT_MY_RANK_SEC = 120,

	-- Sanity rate caps per 60s flush interval (anti-exploit)
	SANITY_CAPS = {
		Wins = 10,              -- Max 10 wins per minute
		Streak = 50,            -- Max 50 streak jump per minute
		Cash = 500_000,         -- Max 500,000 cash per minute
		Playtime = 120,         -- Max 120s per minute (leeway for lag spikes)
	},

	-- Theme Palette matching concept sheet
	PALETTE = {
		RoyalBlue = Color3.fromHex("#1E4FD8"),
		DeepBlue = Color3.fromHex("#1238A8"),
		NavyScreen = Color3.fromHex("#0A1030"),
		NavyScreenAlt = Color3.fromHex("#0E1640"),
		Gold = Color3.fromHex("#FFC400"),
		GoldDark = Color3.fromHex("#E0A000"),
		White = Color3.fromHex("#F2F5FA"),
		NeonCyan = Color3.fromHex("#4FE3FF"),
		GrassGreen = Color3.fromHex("#3DB83A"),
		StoneBase = Color3.fromHex("#9AA3B5"),
		StoneBaseTop = Color3.fromHex("#7B828E"),
		RowDivider = Color3.fromHex("#1E4FD8"),
		MutedGrey = Color3.fromHex("#64748B"),
		LiveGreen = Color3.fromHex("#22C55E"),
	},

	-- Medals for top 3
	MEDAL_COLORS = {
		Gold = Color3.fromHex("#FFD54A"),
		Silver = Color3.fromHex("#D9DEE8"),
		Bronze = Color3.fromHex("#E8894A"),
	},

	-- Asset IDs & Placeholders
	ASSETS = {
		SoccerBallMesh = "rbxassetid://118192748567607",
		SoccerBallTexture = "rbxassetid://1042564705",
		TrophyMesh = "rbxassetid://4534068861",
		FullLeaderboardMesh = "rbxassetid://127378483022959",
		Icon_Trophy = "rbxassetid://1042565768", -- Placeholder 128x128
		Icon_Flame = "rbxassetid://1042565769",
		Icon_Cash = "rbxassetid://1042565770",
		Icon_Clock = "rbxassetid://1042565771",
		Icon_Crown = "rbxassetid://1042565772",
	},

	-- Per-Type Leaderboard Variant Configurations
	BOARDS = {
		Wins = {
			statKey = "Wins",
			title = "TOP WINS",
			titleIcon = "⚽",
			valueHeader = "Wins",
			accentColor = Color3.fromHex("#FFC400"),
			dataStoreKey = "LB_Wins_V1",
			store = "LB_Wins_V1",
			stat = "TotalWins",
			refresh = 60,
			size = 10,
			formatKind = "Compact",
			position = Vector3.new(-33.917, 11.80, -81.609),
			lookTarget = Vector3.new(-4.0, 11.80, 0.0),
		},
		Streak = {
			statKey = "Streak",
			title = "TOP STREAKS",
			titleIcon = "🔥",
			valueHeader = "Streak",
			accentColor = Color3.fromHex("#FF8A1F"),
			dataStoreKey = "LB_Streak_V1",
			store = "LB_Streak_V1",
			stat = "BestStreak",
			refresh = 60,
			size = 10,
			formatKind = "Raw",
			position = Vector3.new(33.917, 11.80, -81.609),
			lookTarget = Vector3.new(4.0, 11.80, 0.0),
		},
		Cash = {
			statKey = "Cash",
			title = "TOP CASH",
			titleIcon = "💰",
			valueHeader = "Cash",
			accentColor = Color3.fromHex("#3DDC3D"),
			dataStoreKey = "LB_Cash_V1",
			store = "LB_Cash_V1",
			stat = "TotalCashEarned",
			refresh = 60,
			size = 10,
			formatKind = "Currency",
			position = Vector3.new(-57.917, 11.80, -91.109),
			lookTarget = Vector3.new(-10.0, 11.80, 0.0),
		},
		Playtime = {
			statKey = "Playtime",
			title = "TOP PLAYTIME",
			titleIcon = "⏰",
			valueHeader = "Time",
			accentColor = Color3.fromHex("#4FE3FF"),
			dataStoreKey = "LB_Playtime_V1",
			store = "LB_Playtime_V1",
			stat = "TotalPlaySeconds",
			refresh = 60,
			size = 10,
			formatKind = "Time",
			position = Vector3.new(57.917, 11.80, -91.109),
			lookTarget = Vector3.new(10.0, 11.80, 0.0),
		},
	} :: { [string]: BoardConfig },

	ROW_COLORS = {
		Dark = Color3.fromHex("#0A1030"),
		Darker = Color3.fromHex("#0E1640"),
	},
}

-- Backward compatibility alias: Bux -> Cash
(LeaderboardConfig.BOARDS :: any).Bux = LeaderboardConfig.BOARDS.Cash

return table.freeze(LeaderboardConfig)

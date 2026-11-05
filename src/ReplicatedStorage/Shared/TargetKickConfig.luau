--!strict
--[[
	TargetKickConfig
	Responsibility: Configuration for the Target Kick minigame:
	- Round kick count, cooldowns, physics parameters
	- Target scoring, colors, hitboxes, and difficulty ramping
	- Combo multipliers and tier-based rewards
	- Stadium visual theme styling
	Location: ReplicatedStorage/Shared/TargetKickConfig.luau
]]

local ShootingCore = require(script.Parent:WaitForChild("ShootingCore"))

export type TargetId = "Green" | "Yellow" | "Red"

export type TargetTierDef = {
	id: TargetId,
	name: string,
	basePoints: number,
	color: Color3,
	baseDiameter: number,
	defaultOffset: Vector3,
	phase: number,
	moveSpeed: number,
	moveRangeZ: number,
}

export type RewardTier = {
	name: string,
	minScore: number,
	buxReward: number,
	color: Color3,
	badgeText: string,
}

local TargetKickConfig = {
	KICKS_PER_ROUND = 5,
	KICK_COOLDOWN_SEC = 0.8,
	BALL_LIFETIME_SEC = 5.0,
	BALL_BASE_SPEED = 78.0,
	MAX_STATION_DISTANCE = 30.0,
	ROUND_TIMEOUT_SEC = 60.0,

	-- Aim & Launch limits
	MIN_POWER_FACTOR = 0.0,
	MAX_POWER_FACTOR = 1.0,
	SWEET_SPOT_MIN = ShootingCore.SWEET_SPOT_MIN,
	SWEET_SPOT_MAX = ShootingCore.SWEET_SPOT_MAX,
	MAX_ERROR_STUDS = 4.0,
	AIM_ASSIST_RADIUS = 2.0,
	AIM_ASSIST_STRENGTH = 0.35,
	SHOW_TRAJECTORY_PREVIEW = true,

	-- Multi-Minigame Configurations
	MINIGAMES = ShootingCore.MINIGAMES,

	-- Combo Multipliers for consecutive hits
	COMBO_MULTIPLIERS = { 1.0, 1.5, 2.0, 2.5, 3.0 },
	MAX_COMBO_INDEX = 5,

	-- Target Definitions
	TARGETS = {
		Green = {
			id = "Green",
			name = "Easy Green",
			basePoints = 75,
			color = Color3.fromHex("#22C55E"),
			baseDiameter = 4.0,
			defaultOffset = Vector3.new(-0.5, 7.8, -7.0),
			phase = 0.0,
			moveSpeed = 1.0,
			moveRangeZ = 0.0,
		},
		Yellow = {
			id = "Yellow",
			name = "Medium Yellow",
			basePoints = 150,
			color = Color3.fromHex("#FFD21F"),
			baseDiameter = 3.0,
			defaultOffset = Vector3.new(-0.5, 4.5, 0.0),
			phase = 2.0,
			moveSpeed = 1.3,
			moveRangeZ = 1.8,
		},
		Red = {
			id = "Red",
			name = "Hard Red",
			basePoints = 300,
			color = Color3.fromHex("#EF4444"),
			baseDiameter = 2.2,
			defaultOffset = Vector3.new(-0.5, 7.8, 6.0),
			phase = 4.0,
			moveSpeed = 2.0,
			moveRangeZ = 3.6,
		},
	} :: { [string]: TargetTierDef },

	-- Difficulty Scaling by Kick Number (1 to 5)
	DIFFICULTY_RAMPS = {
		[1] = { scaleMultiplier = 1.0, speedMultiplier = 1.0 },
		[2] = { scaleMultiplier = 1.0, speedMultiplier = 1.15 },
		[3] = { scaleMultiplier = 0.9, speedMultiplier = 1.35 },
		[4] = { scaleMultiplier = 0.85, speedMultiplier = 1.55 },
		[5] = { scaleMultiplier = 0.8, speedMultiplier = 1.85 },
	},

	-- End of Round Reward Tiers
	TIERS = {
		{ name = "Bronze", minScore = 300, buxReward = 100, color = Color3.fromHex("#E8894A"), badgeText = "BRONZE TIER" },
		{ name = "Silver", minScore = 700, buxReward = 250, color = Color3.fromHex("#D9DEE8"), badgeText = "SILVER TIER" },
		{ name = "Gold", minScore = 1200, buxReward = 500, color = Color3.fromHex("#F5B82E"), badgeText = "GOLD TIER" },
		{ name = "Perfect", minScore = 1800, buxReward = 1000, color = Color3.fromHex("#FFD700"), badgeText = "PERFECT JACKPOT!" },
	} :: { RewardTier },

	PARTICIPATION_REWARD = 25,
	DAILY_BONUS_MULTIPLIER = 2.0,

	-- Visual Theme Colors
	THEME = {
		NavyDark = Color3.fromHex("#0F1530"),
		NavyMedium = Color3.fromHex("#141B3A"),
		RoyalBlue = Color3.fromHex("#1F4FD8"),
		Gold = Color3.fromHex("#F5B82E"),
		GoldLight = Color3.fromHex("#FFD54A"),
		White = Color3.new(1, 1, 1),
		TextMuted = Color3.fromHex("#94A3B8"),
	},
}

return TargetKickConfig

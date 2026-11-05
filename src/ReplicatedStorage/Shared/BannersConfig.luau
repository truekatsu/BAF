--!strict
--[[
	BannersConfig
	Responsibility: Configuration for stadium ads, banners, flags, and bunting:
	- 24 perimeter fence ad boards (14x3 studs) with 8s rotation
	- 8 generic fictional ads (SUPER BOOST, MEGA KICK, GOAL RUSH, TURBO CUP, LUCKY ROLL, POWER SHOT, DREAM XI, FAN ZONE)
	- 2 main hanging banners (40x10 studs) "BUILD A FOOTBALLER"
	- 30 abstract flags with 0.3 Hz wind sway
	- 4 pitch corner flags
	- Entrance bunting string
	Loop step: live lobby atmosphere | visual immersion | stadium identity
	Location: ReplicatedStorage/Shared/BannersConfig (ModuleScript)
]]

export type FictionalAd = {
	title: string,
	tagline: string,
	bgColor: Color3,
	textColor: Color3,
}

local BannersConfig = {
	AD_ROTATION_SEC = 8,
	AD_BOARD_SIZE = Vector3.new(14.0, 3.0, 0.4),
	AD_BOARDS_COUNT = 24, -- 12 along North fence, 12 along South fence
	AD_ELEVATION_Y = 1.5,

	MAIN_BANNER_SIZE = Vector3.new(40.0, 10.0, 0.6),
	MAIN_BANNER_TEXT = "BUILD A FOOTBALLER",

	FLAGS_COUNT = 0, -- Disabled: old perimeter rim flags clip into the new upgraded stadium stands
	WIND_SWAY_DEG = 6.0,
	WIND_SWAY_FREQ_HZ = 0.3,
	LOD_MAX_DISTANCE = 150.0, -- pause wind/ad animation beyond 150 studs

	ADS = {
		{ title = "SUPER BOOST", tagline = "MAX POWER IN EVERY MATCH!", bgColor = Color3.fromHex("#E11D48"), textColor = Color3.new(1, 1, 1) },
		{ title = "MEGA KICK", tagline = "UNLEASH THE STRIKER WITHIN!", bgColor = Color3.fromHex("#2563EB"), textColor = Color3.fromHex("#FFD21F") },
		{ title = "GOAL RUSH", tagline = "SCORE BIG IN 1V1 SHOWDOWN!", bgColor = Color3.fromHex("#059669"), textColor = Color3.new(1, 1, 1) },
		{ title = "TURBO CUP", tagline = "CHAMPIONS ARE BORN HERE!", bgColor = Color3.fromHex("#D97706"), textColor = Color3.new(1, 1, 1) },
		{ title = "LUCKY ROLL", tagline = "ROLL MYTHIC PLAYERS TODAY!", bgColor = Color3.fromHex("#7C3AED"), textColor = Color3.fromHex("#FFD21F") },
		{ title = "POWER SHOT", tagline = "99 SHOOTING UNSTOPPABLE!", bgColor = Color3.fromHex("#DC2626"), textColor = Color3.new(1, 1, 1) },
		{ title = "DREAM XI", tagline = "BUILD YOUR ULTIMATE SQUAD!", bgColor = Color3.fromHex("#0284C7"), textColor = Color3.new(1, 1, 1) },
		{ title = "FAN ZONE", tagline = "SUPPORT YOUR FAVOURITE CLUB!", bgColor = Color3.fromHex("#16A34A"), textColor = Color3.fromHex("#FFD21F") },
	} :: { FictionalAd },

	CORNER_FLAG_POLE_HEIGHT = 5.0,
}

return table.freeze(BannersConfig)

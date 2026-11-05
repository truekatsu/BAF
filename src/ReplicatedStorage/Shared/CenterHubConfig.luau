--!strict
--[[
	CenterHubConfig
	Configuration for Center Circle Hub, rotating pedestal, Rank #1 statue & Streak King billboard.
	To move/resize: Change PITCH_CENTER to shift the whole hub in studs. TIER_1 and TIER_2 control
	podium radii and heights. WALKWAY_BYPASS_WIDTH controls pedestrian clearance on either side.
]]

local CenterHubConfig = {
	-- World Position (Relative to Pitch Center: HubCenter is at (0, 0.2, -39))
	PITCH_CENTER = Vector3.new(0, 0.2, -39),
	
	-- DataStore Names
	LeaderboardWinsStoreName = "BAF_TopWins_v1",
	LeaderboardStreakStoreName = "BAF_TopStreak_v1",
	REFRESH_INTERVAL_SECONDS = 60,

	-- Markings (Pitch level)
	CENTER_CIRCLE_DIAMETER = 60,
	CENTER_CIRCLE_THICKNESS = 1.2,
	CENTER_SPOT_DIAMETER = 3,
	HALFWAY_LINE_WIDTH = 1.2,
	HALFWAY_LINE_LENGTH = 84,

	-- Walkway Bypass (Guarantees >= 20 studs clear pedestrian passage around podium)
	WALKWAY_BYPASS_OUTER_RADIUS = 22,
	WALKWAY_BYPASS_WIDTH = 10,

	-- 2-Tier Podium Dimensions & Styling
	TIER_1 = {
		Radius = 12,
		Height = 2.0,
		Color = Color3.fromHex("#F5B800"),
		RimColor = Color3.fromRGB(18, 18, 20),
	},
	TIER_2 = {
		Radius = 7,
		Height = 4.0,
		Color = Color3.fromHex("#F5B800"),
		RimColor = Color3.fromRGB(18, 18, 20),
	},

	-- Rotating Pedestal
	PEDESTAL = {
		Radius = 4.8,
		Height = 0.8,
		Color = Color3.fromHex("#E09E00"),
		RimColor = Color3.fromRGB(18, 18, 20),
		RotationSpeedDegPerSec = 20,
	},

	-- Lighting & Particles
	LIGHTING = {
		Brightness = 2,
		Angle = 60,
		Range = 40,
		Color = Color3.fromRGB(255, 235, 190),
	},
	PARTICLES = {
		Rate = 4,
		Texture = "rbxassetid://0", -- TEX_Sparkle_Gold placeholder
	},

	-- Streak King Billboard
	BILLBOARD = {
		MaxDistance = 120,
		Size = Vector2.new(12, 3),
		StudsOffset = Vector3.new(0, 5.0, 0),
		StrokeThickness = 4,
	},
}

return table.freeze(CenterHubConfig)

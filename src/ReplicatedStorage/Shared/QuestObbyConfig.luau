--!strict
--[[
	QuestObbyConfig
	Responsibility: Configuration for the Training Ground Obby behind the West Goal:
	- Course layout dimensions, checkpoint indices, hurdle heights, and moving platform speeds
	- Anti-cheat rules (checkpoints 1, 2, 3 in sequential order, min duration 20s)
	- Daily UTC reset rule (00:00 UTC calendar day)
	Loop step: retention | quest progression | daily habit
	Location: ReplicatedStorage/Shared/QuestObbyConfig (ModuleScript)
]]

local QuestObbyConfig = {
	START_POS = Vector3.new(-89.0, 0.5, -12.0),
	FINISH_POS = Vector3.new(-89.0, 5.0, -82.0),
	RESPAWN_Y = -20.0,

	MIN_DURATION_SEC = 20, -- Anti-cheat: run must take at least 20 seconds
	CHECKPOINTS_COUNT = 3,

	MOVING_PLATFORM_SPEED = 8.0, -- studs / second
	MOVING_PLATFORM_TRAVEL = 6.0, -- studs oscillation range in X

	COLORS = {
		StartBlue = Color3.fromHex("#1E6FFF"),
		FinishGold = Color3.fromHex("#FFD21F"),
		ConeOrange = Color3.fromHex("#FF6B00"),
		HurdleCyan = Color3.fromHex("#06B6D4"),
		HurdleGreen = Color3.fromHex("#22C55E"),
		HurdleOrange = Color3.fromHex("#F97316"),
		HurdlePurple = Color3.fromHex("#A855F7"),
		HurdleYellow = Color3.fromHex("#FFD21F"),
		GiftRed = Color3.fromHex("#DC2626"),
		GiftGold = Color3.fromHex("#F5B800"),
	},

	PROMPT_TEXT_CLAIM = "Claim Free Gift",
	PROMPT_TEXT_OBJECT = "Training Obby",
}

return table.freeze(QuestObbyConfig)

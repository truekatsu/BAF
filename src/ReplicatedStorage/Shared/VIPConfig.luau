--!strict
--[[
	VIPConfig
	Responsibility: Configuration for the VIP Lounge (40x14x26 studs, elevated 10 studs,
	gold trim, gamepass gate, VIP tables, red carpet, and buffet).
	Loop step: retention | monetization | prestige
	Location: ReplicatedStorage/Shared/VIPConfig (ModuleScript)
]]

local VIPConfig = {
	-- shortcut: placeholder 0 for dev/Studio testing. Replace with live published GamePass ID on release.
	VIP_GAMEPASS_ID = 0,

	LOUNGE_SIZE = Vector3.new(26.0, 14.0, 40.0), -- depth X=26, height Y=14, width Z=40
	LOUNGE_POSITION = Vector3.new(83.0, 17.0, -18.0), -- center position
	FLOOR_Y = 10.0,
	CEILING_Y = 24.0,

	DOOR_SIZE = Vector3.new(1.0, 9.0, 6.0),
	DOOR_OPEN_OFFSET = Vector3.new(0, 0, 6.5),
	DOOR_TWEEN_DURATION = 0.4,
	DOOR_STAY_OPEN_DURATION = 3.0,

	SPARKLE_RATE = 3, -- ParticleEmitter rate 3/s on sign only

	COLORS = {
		GoldTrim = Color3.fromHex("#F5B800"),
		GoldNeon = Color3.fromHex("#FFD21F"),
		NavyFrame = Color3.fromHex("#12162B"),
		LoungeFloor = Color3.fromHex("#181B24"),
		RedCarpet = Color3.fromHex("#B91C1C"),
		GlassTint = Color3.fromRGB(200, 230, 255),
	},

	PROMPT_TEXT_BUY = "Buy VIP",
	PROMPT_TEXT_OBJECT = "VIP Lounge",
}

return table.freeze(VIPConfig)

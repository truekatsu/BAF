--!strict
--[[
	TableBillboardConfig
	Configuration for table spectator billboards, anti-overlap logic, and hover highlights.
	To move/resize: Change BASE_SIZE (in studs) for the billboard size in world units.
	Change ANCHOR_HEIGHT_ABOVE_CENTRE (7 studs) to raise or lower the billboard.
	Change HOVER_DISTANCE (14 studs) to adjust when SIT TO PLAY! activates.
]]

local TableBillboardConfig = {
	-- World Positioning & Sizing (Studs)
	ANCHOR_HEIGHT_ABOVE_CENTRE = 7.0,
	BASE_SIZE = Vector2.new(10.0, 5.0),
	MAX_DISTANCE = 90.0,
	LIGHT_INFLUENCE = 0.0,
	ALWAYS_ON_TOP = false,

	-- Anti-Overlap & Throttling
	THROTTLE_RATE_HZ = 5.0, -- Check screen overlap at 5 Hz (every 0.2s)
	MAX_SIMULTANEOUS_BILLBOARDS = 10,
	OVERLAP_SHRINK_FACTOR = 0.80, -- 20% shrink for farther overlapping billboard
	OVERLAP_TRANSPARENCY = 0.60, -- Fade farther billboard to 0.6 opacity

	-- Hover Highlight
	HOVER_DISTANCE = 14.0, -- Within 14 studs
	HOVER_GROW_FACTOR = 1.15, -- 15% size boost
	BOUNCE_SPEED = 6.0,
	BOUNCE_AMPLITUDE_PX = 6.0,

	-- UI Colors
	COLORS = {
		TitleWhite = Color3.fromRGB(255, 255, 255),
		OccupancyWhite = Color3.fromRGB(255, 255, 255),
		PriceGreen = Color3.fromHex("#3DDC3D"),
		SitYellow = Color3.fromHex("#FFD21F"),
		VsOrange = Color3.fromHex("#FF7A00"),
		PlayerABlue = Color3.fromHex("#3B82F6"),
		PlayerBRed = Color3.fromHex("#EF4444"),
		SquareEmpty = Color3.fromRGB(55, 65, 81),
		SquareFilledA = Color3.fromHex("#38BDF8"),
		SquareFilledB = Color3.fromHex("#FB923C"),
		StrokeBlack = Color3.fromRGB(0, 0, 0),
	},
}

return table.freeze(TableBillboardConfig)

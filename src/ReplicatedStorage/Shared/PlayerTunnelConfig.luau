--!strict
--[[
	PlayerTunnelConfig
	Configuration for the South End Player Tunnel entrance, spawns, and spawn cinematic camera.
	To move/resize: Change TUNNEL_ENTRANCE_Z to adjust depth or distance along pitch long axis.
	Change OPENING_SIZE for width and height of the tunnel entrance.
]]

local PlayerTunnelConfig = {
	-- World Coordinates (South End centered on long axis X = 0)
	TUNNEL_CENTER_X = 0.0,
	TUNNEL_ENTRANCE_Z = 26.6,
	TUNNEL_DEPTH = 24.0,

	-- Dimensions
	OPENING_WIDTH = 16.0,
	OPENING_HEIGHT = 12.0,

	-- Spawns
	SPAWN_COUNT = 8,
	SPAWN_SPACING_X = 2.0,
	SPAWN_DEPTH_Z = 34.0,
	SPAWN_FORCEFIELD_DURATION = 3,

	-- Lighting & Beam
	LIGHT_COLOR = Color3.fromRGB(255, 232, 194),
	LIGHT_BRIGHTNESS = 1.2,
	LIGHT_RANGE = 18.0,
	BEAM_TRANSPARENCY = 0.85,

	-- Spawn Cinematic Camera
	CAMERA_DURATION_SEC = 3.0,
	REJOIN_COOLDOWN_SEC = 60.0,
	CAM_OFFSET = Vector3.new(1.8, 3.2, 5.5),
	CAM_LOOK_FORWARD_STUDS = 35.0,

	-- Audio
	SPAWN_ROAR_SOUND_ID = "rbxassetid://0", -- SFX_CrowdRoar_Spawn
}

return table.freeze(PlayerTunnelConfig)

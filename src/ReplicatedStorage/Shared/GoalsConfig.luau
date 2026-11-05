--!strict
--[[
	GoalsConfig
	Responsibility: Configuration for Interactive Goals and Target-Kick mini-game (TASK P11):
	- Goal net dimensions and collision boundaries
	- Ball spot positions (18 studs from goal line)
	- Target disc positions, colors, diameters, and bobbing parameters
	- Kick physics: speed 70, up angle clamped 15-35 deg
	- Debounce cooldown (2s) and max active balls (5)
	- Target hit score tracking and billboards
	Loop step: lobby activity | casual mini-game | player engagement
	Location: ReplicatedStorage/Shared/GoalsConfig.luau
]]

export type TargetDef = {
	id: string,
	color: Color3,
	offset: Vector3,
	phase: number,
}

export type GoalDef = {
	name: string,
	goalLineX: number,
	centerZ: number,
	width: number,
	height: number,
	facingX: number,
	ballSpot: Vector3,
	targets: { TargetDef },
	billboardCFrame: CFrame,
}

local GoalsConfig = {
	KICK_SPEED = 70.0,
	MIN_UP_ANGLE_DEG = 15.0,
	MAX_UP_ANGLE_DEG = 35.0,
	PLAYER_COOLDOWN_SEC = 2.0,
	BALL_LIFETIME_SEC = 6.0,
	MAX_ACTIVE_BALLS = 5,
	TARGET_DIAMETER = 3.0,
	BALL_SIZE = Vector3.new(1.6, 1.6, 1.6),

	NET_TRANSPARENCY = 0.4,
	NET_COLOR = Color3.new(1, 1, 1),

	GOALS = {
		West = {
			name = "WestGoal",
			goalLineX = -78.0,
			centerZ = -39.0,
			width = 20.0,
			height = 10.0,
			facingX = -1,
			ballSpot = Vector3.new(-60.0, 0.05, -39.0),
			targets = {
				{ id = "TopLeft", color = Color3.fromHex("#22C55E"), offset = Vector3.new(-0.5, 7.8, -8.0), phase = 0 },
				{ id = "Center", color = Color3.fromHex("#FFD21F"), offset = Vector3.new(-0.5, 4.8, 0.0), phase = 2 },
				{ id = "TopRight", color = Color3.fromHex("#EF4444"), offset = Vector3.new(-0.5, 7.8, 8.0), phase = 4 },
			},
			billboardCFrame = CFrame.new(-78.0, 12.5, -39.0),
		},
		East = {
			name = "EastGoal",
			goalLineX = 78.0,
			centerZ = -39.0,
			width = 20.0,
			height = 10.0,
			facingX = 1,
			ballSpot = Vector3.new(60.0, 0.05, -39.0),
			targets = {
				{ id = "TopLeft", color = Color3.fromHex("#22C55E"), offset = Vector3.new(0.5, 7.8, -8.0), phase = 0 },
				{ id = "Center", color = Color3.fromHex("#FFD21F"), offset = Vector3.new(0.5, 4.8, 0.0), phase = 2 },
				{ id = "TopRight", color = Color3.fromHex("#EF4444"), offset = Vector3.new(0.5, 7.8, 8.0), phase = 4 },
			},
			billboardCFrame = CFrame.new(78.0, 12.5, -39.0),
		},
	},
}

return table.freeze(GoalsConfig)

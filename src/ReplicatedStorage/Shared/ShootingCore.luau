--!strict
--[[
	ShootingCore
	Responsibility: Single shared math and gameplay core for ALL target shooting minigames:
	- AimPlane raycast and 3D projection helper
	- Aim assist / crosshair magnetism toward nearest target
	- Power error calculation (sweet spot [0.70, 0.90] perfect landing, deterministic error outside)
	- Exact ballistic flight solver (v0, T, g) ensuring 0-error arrival at landing point
	- Seeded target generation and synchronized moving target positioning
	- Mathematical 2D/3D hit testing (not physics Touched) with accuracy bonus and combo
	- Configuration dictionary for WestGoal (Penalty1), EastGoal (Penalty2), and future minigames
	Location: ReplicatedStorage/Shared/ShootingCore.luau
]]

local Workspace = game:GetService("Workspace")

export type TargetDef = {
	id: string,
	name: string,
	radius: number,
	basePoints: number,
	color: Color3,
	isMoving: boolean,
	moveSpeed: number,
	moveRange: number,
	phase: number,
	baseCenter: Vector3,
	currentCenter: Vector3?,
}

export type MinigameConfig = {
	id: string,
	name: string,
	displayName: string,
	goalLineX: number,
	centerZ: number,
	width: number,
	height: number,
	facingX: number,
	ballSpot: Vector3,
	aimPlaneName: string,
	ballStartName: string,
	kicksPerRound: number,
	speedMin: number,
	speedMax: number,
	tMin: number,
	tMax: number,
	gravityScale: number,
	maxErrorStuds: number,
	aimAssistRadius: number,
	aimAssistStrength: number,
}

export type BallisticSolve = {
	v0: Vector3,
	flightTime: number,
	gravity: Vector3,
	startPos: Vector3,
	landingPos: Vector3,
}

export type HitResult = {
	isHit: boolean,
	isWide: boolean,
	target: TargetDef?,
	distance: number,
	accuracyBonus: number,
	points: number,
}

local ShootingCore = {}

ShootingCore.SWEET_SPOT_MIN = 0.70
ShootingCore.SWEET_SPOT_MAX = 0.90
ShootingCore.BALL_RADIUS = 0.80 -- Radius for a 1.6x1.6x1.6 stud ball
ShootingCore.TARGET_MIN_SPACING = 4.8

-- Minigame Configurations (West = Minigame 1, East = Minigame 2)
local MINIGAMES: { [string]: MinigameConfig } = {
	West = {
		id = "West",
		name = "WestGoal",
		displayName = "West Stadium Penalty",
		goalLineX = -78.0,
		centerZ = -39.0,
		width = 20.0,
		height = 10.0,
		facingX = -1,
		ballSpot = Vector3.new(-60.0, 0.05, -39.0),
		aimPlaneName = "AimPlane",
		ballStartName = "BallStart",
		kicksPerRound = 5,
		speedMin = 45.0,
		speedMax = 95.0,
		tMin = 0.40,
		tMax = 1.15,
		gravityScale = 1.0,
		maxErrorStuds = 4.0,
		aimAssistRadius = 2.0,
		aimAssistStrength = 0.35,
	},
	East = {
		id = "East",
		name = "EastGoal",
		displayName = "East Stadium Penalty",
		goalLineX = 78.0,
		centerZ = -39.0,
		width = 20.0,
		height = 10.0,
		facingX = 1,
		ballSpot = Vector3.new(60.0, 0.05, -39.0),
		aimPlaneName = "AimPlane",
		ballStartName = "BallStart",
		kicksPerRound = 5,
		speedMin = 45.0,
		speedMax = 95.0,
		tMin = 0.40,
		tMax = 1.15,
		gravityScale = 1.0,
		maxErrorStuds = 4.0,
		aimAssistRadius = 2.0,
		aimAssistStrength = 0.35,
	},
}

-- Aliases for generic minigame numbering
MINIGAMES.Penalty1 = MINIGAMES.West
MINIGAMES.Penalty2 = MINIGAMES.East

ShootingCore.MINIGAMES = MINIGAMES

-- 1. AimPlane CFrame Helper: Normal points toward the ball spot
function ShootingCore.getAimPlaneCFrame(cfg: MinigameConfig): CFrame
	local goalCenter = Vector3.new(cfg.goalLineX, cfg.height * 0.5, cfg.centerZ)
	local targetLook = Vector3.new(cfg.ballSpot.X, goalCenter.Y, cfg.ballSpot.Z)
	return CFrame.lookAt(goalCenter, targetLook)
end

-- 2. Raycast / Projection Helper against AimPlane
function ShootingCore.projectScreenToAimPlane(
	camera: Camera,
	screenPos: Vector2,
	aimPlaneCF: CFrame,
	width: number,
	height: number,
	margin: number?,
	aimPlanePart: BasePart?
): (Vector3, Vector2)
	local m = margin or 0.6
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local center = aimPlaneCF.Position
	local hitPoint: Vector3? = nil

	-- Primary: Whitelist raycast against physical AimPlane part
	if aimPlanePart and aimPlanePart.Parent then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { aimPlanePart }
		params.IgnoreWater = true
		local result = Workspace:Raycast(ray.Origin, ray.Direction * 600, params)
		if result then
			hitPoint = result.Position
		end
	end

	-- Secondary fallback: Mathematical infinite plane intersection
	if not hitPoint then
		local normal = aimPlaneCF.LookVector
		local denom = ray.Direction:Dot(normal)
		if math.abs(denom) > 1e-4 then
			local t = (center - ray.Origin):Dot(normal) / denom
			if t > 0 then
				hitPoint = ray.Origin + ray.Direction * t
			else
				hitPoint = center
			end
		else
			hitPoint = center
		end
	end

	-- Convert to 2D local plane coordinates (U: Right, V: Up)
	local u = (hitPoint - center):Dot(aimPlaneCF.RightVector)
	local v = (hitPoint - center):Dot(aimPlaneCF.UpVector)

	local halfW = (width * 0.5) - m
	local halfH = (height * 0.5) - m

	local uClamped = math.clamp(u, -halfW, halfW)
	local vClamped = math.clamp(v, -halfH, halfH)

	local clamped3D = center + (aimPlaneCF.RightVector * uClamped) + (aimPlaneCF.UpVector * vClamped)
	return clamped3D, Vector2.new(uClamped, vClamped)
end

-- 3. Clamp a 3D point strictly inside AimPlane boundaries
function ShootingCore.clampToAimPlane(
	point: Vector3,
	aimPlaneCF: CFrame,
	width: number,
	height: number,
	margin: number?
): Vector3
	local m = margin or 0.4
	local center = aimPlaneCF.Position
	local u = (point - center):Dot(aimPlaneCF.RightVector)
	local v = (point - center):Dot(aimPlaneCF.UpVector)

	local halfW = (width * 0.5) - m
	local halfH = (height * 0.5) - m

	local uClamped = math.clamp(u, -halfW, halfW)
	local vClamped = math.clamp(v, -halfH, halfH)

	return center + (aimPlaneCF.RightVector * uClamped) + (aimPlaneCF.UpVector * vClamped)
end

-- 4. Aim Assist / Magnetism toward nearest target
function ShootingCore.applyAimAssist(
	aimPoint: Vector3,
	targets: { TargetDef },
	assistRadius: number,
	assistStrength: number
): Vector3
	local bestTarget: TargetDef? = nil
	local minDistance = assistRadius

	for _, target in ipairs(targets) do
		local pos = target.currentCenter or target.baseCenter
		local dist = (aimPoint - pos).Magnitude
		if dist <= minDistance then
			minDistance = dist
			bestTarget = target
		end
	end

	if bestTarget then
		local pos = bestTarget.currentCenter or bestTarget.baseCenter
		return aimPoint:Lerp(pos, assistStrength)
	end

	return aimPoint
end

-- 5. Power Error Calculation (Sweet spot [0.70, 0.90] perfect landing)
function ShootingCore.computePowerError(
	power: number,
	aimPlaneCF: CFrame,
	rng: Random,
	maxErrorStuds: number?
): (Vector3, number)
	local maxErr = maxErrorStuds or 4.0
	local p = math.clamp(power, 0.0, 1.0)

	if p >= ShootingCore.SWEET_SPOT_MIN and p <= ShootingCore.SWEET_SPOT_MAX then
		return Vector3.zero, 0.0
	end

	local ratio: number
	if p < ShootingCore.SWEET_SPOT_MIN then
		ratio = (ShootingCore.SWEET_SPOT_MIN - p) / ShootingCore.SWEET_SPOT_MIN
	else
		ratio = (p - ShootingCore.SWEET_SPOT_MAX) / (1.0 - ShootingCore.SWEET_SPOT_MAX)
	end

	local errMag = math.clamp(ratio, 0.0, 1.0) * maxErr
	local angle = rng:NextNumber(0, math.pi * 2)

	local uErr = math.cos(angle) * errMag
	local vErr = math.sin(angle) * errMag

	local errorOffset = (aimPlaneCF.RightVector * uErr) + (aimPlaneCF.UpVector * vErr)
	return errorOffset, errMag
end

-- 6. Exact Ballistic Solver: p(T) arrives exactly at landingPos
function ShootingCore.solveBallistics(
	startPos: Vector3,
	landingPos: Vector3,
	power: number,
	cfg: MinigameConfig
): BallisticSolve
	local p = math.clamp(power, 0.0, 1.0)
	local speed = cfg.speedMin + (cfg.speedMax - cfg.speedMin) * p
	local delta = landingPos - startPos
	local dist = delta.Magnitude

	local flightTime = math.clamp(dist / speed, cfg.tMin, cfg.tMax)
	local g = Vector3.new(0, -Workspace.Gravity * cfg.gravityScale, 0)

	-- Derived from: landingPos = startPos + v0*T + 0.5*g*T^2
	local v0 = (landingPos - startPos - 0.5 * g * (flightTime * flightTime)) / flightTime

	return {
		v0 = v0,
		flightTime = flightTime,
		gravity = g,
		startPos = startPos,
		landingPos = landingPos,
	}
end

-- 7. Trajectory Parabola Evaluation at time t
function ShootingCore.evalTrajectory(startPos: Vector3, v0: Vector3, g: Vector3, t: number): Vector3
	return startPos + (v0 * t) + (0.5 * g * (t * t))
end

-- 8. Seeded Target Generation & Placement on AimPlane
function ShootingCore.generateTargets(
	aimPlaneCF: CFrame,
	width: number,
	height: number,
	seed: number
): { TargetDef }
	local rng = Random.new(seed)

	local halfW = (width * 0.5) - 2.5
	local halfH = (height * 0.5) - 2.0

	-- 3 standardized target tiers
	local rawDefs = {
		{
			id = "Red",
			name = "Hard Red (Bullseye)",
			radius = 1.1,
			basePoints = 300,
			color = Color3.fromHex("#EF4444"),
			isMoving = true,
			moveSpeed = 2.0,
			moveRange = 3.6,
			phase = rng:NextNumber(0, math.pi * 2),
		},
		{
			id = "Yellow",
			name = "Medium Yellow",
			radius = 1.5,
			basePoints = 150,
			color = Color3.fromHex("#FFD21F"),
			isMoving = true,
			moveSpeed = 1.3,
			moveRange = 1.8,
			phase = rng:NextNumber(0, math.pi * 2),
		},
		{
			id = "Green",
			name = "Easy Green",
			radius = 2.0,
			basePoints = 75,
			color = Color3.fromHex("#22C55E"),
			isMoving = false,
			moveSpeed = 0.0,
			moveRange = 0.0,
			phase = 0.0,
		},
	}

	local placed: { TargetDef } = {}
	local maxAttempts = 60

	for _, def in ipairs(rawDefs) do
		local success = false
		local targetU = 0
		local targetV = 0

		for _ = 1, maxAttempts do
			targetU = rng:NextNumber(-halfW, halfW)
			targetV = rng:NextNumber(-halfH, halfH)

			local valid = true
			for _, other in ipairs(placed) do
				local ou = (other.baseCenter - aimPlaneCF.Position):Dot(aimPlaneCF.RightVector)
				local ov = (other.baseCenter - aimPlaneCF.Position):Dot(aimPlaneCF.UpVector)
				local d = math.sqrt((targetU - ou) ^ 2 + (targetV - ov) ^ 2)
				if d < ShootingCore.TARGET_MIN_SPACING then
					valid = false
					break
				end
			end

			if valid then
				success = true
				break
			end
		end

		-- Deterministic fallback positions if random packing failed
		if not success then
			if def.id == "Red" then
				targetU = halfW * 0.7
				targetV = halfH * 0.5
			elseif def.id == "Yellow" then
				targetU = 0
				targetV = -halfH * 0.3
			else
				targetU = -halfW * 0.7
				targetV = halfH * 0.5
			end
		end

		local center3D = aimPlaneCF.Position + (aimPlaneCF.RightVector * targetU) + (aimPlaneCF.UpVector * targetV)
		local tDef: TargetDef = {
			id = def.id,
			name = def.name,
			radius = def.radius,
			basePoints = def.basePoints,
			color = def.color,
			isMoving = def.isMoving,
			moveSpeed = def.moveSpeed,
			moveRange = def.moveRange,
			phase = def.phase,
			baseCenter = center3D,
			currentCenter = center3D,
		}
		table.insert(placed, tDef)
	end

	return placed
end

-- 9. Moving Target Position at given timestamp (server time sync)
function ShootingCore.getTargetCenterAtTime(target: TargetDef, now: number, aimPlaneCF: CFrame): Vector3
	if not target.isMoving or target.moveRange <= 0 then
		return target.baseCenter
	end
	local offset = math.sin(now * target.moveSpeed + target.phase) * target.moveRange
	return target.baseCenter + (aimPlaneCF.RightVector * offset)
end

-- 10. Mathematical 2D/3D Hit Evaluation
function ShootingCore.evaluateHit(
	landingPos: Vector3,
	targets: { TargetDef },
	width: number,
	height: number,
	aimPlaneCF: CFrame,
	combo: number?
): HitResult
	local currentCombo = combo or 1.0
	local center = aimPlaneCF.Position
	local u = (landingPos - center):Dot(aimPlaneCF.RightVector)
	local v = (landingPos - center):Dot(aimPlaneCF.UpVector)

	-- Check goal opening bounds: miss/wide if outside post/crossbar perimeter
	if math.abs(u) > (width * 0.5) or math.abs(v) > (height * 0.5) then
		return {
			isHit = false,
			isWide = true,
			target = nil,
			distance = 0,
			accuracyBonus = 0,
			points = 0,
		}
	end

	local bestTarget: TargetDef? = nil
	local minDistance = math.huge

	for _, target in ipairs(targets) do
		local tCenter = target.currentCenter or target.baseCenter
		local dist = (landingPos - tCenter).Magnitude
		if dist <= (target.radius + ShootingCore.BALL_RADIUS) then
			if dist < minDistance then
				minDistance = dist
				bestTarget = target
			end
		end
	end

	if bestTarget then
		local isPerfect = minDistance <= (bestTarget.radius * 0.30)
		local accuracyBonus = if isPerfect then 0.5 else 0.0
		local pts = math.floor((bestTarget.basePoints * (1.0 + accuracyBonus) * currentCombo) + 0.5)
		return {
			isHit = true,
			isWide = false,
			target = bestTarget,
			distance = minDistance,
			accuracyBonus = accuracyBonus,
			points = pts,
		}
	end

	return {
		isHit = false,
		isWide = false,
		target = nil,
		distance = minDistance,
		accuracyBonus = 0,
		points = 0,
	}
end

return table.freeze(ShootingCore)

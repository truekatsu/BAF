--!strict
--[[
	StadiumLighting (ModuleScript)
	Location: ReplicatedStorage/StadiumLighting

	Responsibility:
	- Master stadium floodlight configuration and day/night state manager.
	- Procedural lighting builder for floodlight towers and ground glow overlays.
	- Raycast surface sampling to place glow overlays on real surface levels (Pitch, Walkway, Plaza, Podium Tiers).
	- PlazaFill central fill lighting and walkway/plaza restyling.
	- Admin debug visualization (/lightdebug, /lightfix).
	- Synchronizes global state via workspace:SetAttribute("StadiumLightsOn", bool).
]]

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local StadiumLighting = {}

-- ============================================================================
-- MASTER CONFIGURATION
-- ============================================================================
StadiumLighting.CONFIG = {
	-- Auto Mode & Timing
	AUTO_MODE = true,
	NIGHT_START_TIME = 17.5, -- 17:30 (5:30 PM)
	NIGHT_END_TIME = 6.0,    -- 06:00 (6:00 AM)
	RAMP_DURATION = 3.0,     -- Seconds to ramp brightness up/down
	WARMUP_FLICKER = true,   -- Staggered realistic sodium/halide ignition flicker

	-- Optional Day/Night Cycle
	CYCLE_ENABLED = false,   -- False by default; advances ClockTime continuously if true
	CYCLE_MINUTES = 12,      -- Real minutes for a full 24-hour cycle

	-- Light Throw Specifications (per tower)
	SPOT_BRIGHTNESS = 3.5,   -- Raised from 5.0 to 7.0 to overcome Future quadratic distance attenuation
	SPOT_RANGE = 120,        -- Maximum possible in Roblox engine (clamped by engine to [0, 120]; was 110). PlazaFill covers the center (dist 165).
	SPOT_ANGLE = 82,         -- Raised from 75 to 82 degrees to cover walkway bypasses and plaza
	SPOT_COLOR = Color3.fromHex("#FFF4D6"), -- Warm stadium white
	SHADOWS_ENABLED = true,  -- Selective shadow casting: only 2 diagonal key towers cast shadows to eliminate dark criss-cross cutouts
	SHADOW_KEY_TOWERS = {
		["Tower_Corner_NW"] = true,
		["Tower_Corner_SE"] = true,
	},
	MAX_DYNAMIC_LIGHTS = 24, -- Hard dynamic light budget (10 towers * 2 + PlazaFill 2 = 22 <= 24)

	-- Halo, Beams & Flares
	POINT_RANGE = 14,
	POINT_BRIGHTNESS = 0.8,
	BEAMS_ENABLED = true,
	BEAM_TRANSPARENCY = 0.92,
	FLARE_MAX_DIST = 250,
	FLARE_SIZE = 12,

	-- Ground Glow Pool Configuration
	GROUND_GLOW_SIZE = 60,
	GROUND_GLOW_TRANSPARENCY = 0.95, -- Subtle additive ground glow fading smoothly outward
	PITCH_SURFACE_Y = 0.0,           -- Top of grass baseplate ground
	WALKWAY_SURFACE_Y = 0.50,        -- Top of central walkway and plaza roundabout
	PODIUM_TIER1_Y = 2.25,           -- Top of gold podium tier 1
	PODIUM_TIER2_Y = 6.25,           -- Top of gold podium tier 2

	-- Walkway / Plaza Restyle (Step 4)
	WALKWAY_RESTYLE = true,
	WALKWAY_COLOR = Color3.fromHex("#AEB7C7"),  -- Light warm stone
	PLAZA_COLOR = Color3.fromHex("#AEB7C7"),    -- Matching unified plaza stone (no color seam)
	WALKWAY_MATERIAL = Enum.Material.SmoothPlastic,
	WALKWAY_REFLECTANCE = 0.0,

	-- Plaza Fill Light Specification (Step 3)
	PLAZA_FILL = {
		HEIGHT = 25.5,                         -- Studs above ground
		CENTER = Vector3.new(0, 25.5, -39),    -- Central plaza hub position
		SPOT_RANGE = 60,
		SPOT_ANGLE = 120,
		SPOT_BRIGHTNESS = 0.6,
		POINT_RANGE = 30,
		POINT_BRIGHTNESS = 0.4,
		COLOR = Color3.fromHex("#FFF4D6"),
	},

	-- Apex Red Beacon
	BEACON_BLINK_INTERVAL = 1.0,
	BEACON_RANGE = 8,
	BEACON_COLOR = Color3.fromRGB(255, 30, 30),

	-- Pole Yellow Collar Accent
	POLE_GLOW_ENABLED = true,
	COLLAR_COLOR = Color3.fromHex("#F5B82E"),

	-- Distance Culling
	CULL_DISTANCE = 250,

	-- CollectionService Tags
	TAG_TOWER = "StadiumFloodlightTower",
	TAG_LAMP = "StadiumFloodlight",
}

export type LightingMode = "Day" | "Night" | "Auto"
local currentMode: LightingMode = "Auto"
local cycleThread: thread? = nil
local isLightsOn = false
local debugActive = false

-- ============================================================================
-- HELPER: FIND TOWERS
-- ============================================================================
function StadiumLighting.GetTowers(): { Model }
	local towers: { Model } = {}
	local tagged = CollectionService:GetTagged(StadiumLighting.CONFIG.TAG_TOWER)
	if #tagged > 0 then
		for _, inst in ipairs(tagged) do
			if inst:IsA("Model") then
				table.insert(towers, inst)
			end
		end
	else
		local stadium = workspace:FindFirstChild("Stadium")
		local lights = stadium and stadium:FindFirstChild("Lights")
		if lights then
			for _, child in ipairs(lights:GetChildren()) do
				if child:IsA("Model") and child.Name:find("Tower_") then
					table.insert(towers, child)
				end
			end
		end
	end
	return towers
end

-- ============================================================================
-- HELPER: COMPUTE GROUND INTERSECTION
-- ============================================================================
local function calculateGroundTarget(lampPos: Vector3, aimDir: Vector3, groundY: number): Vector3
	if aimDir.Y < -0.05 then
		local t = (groundY - lampPos.Y) / aimDir.Y
		return lampPos + aimDir * t
	else
		return Vector3.new(lampPos.X + aimDir.X * 50, groundY, lampPos.Z + aimDir.Z * 50)
	end
end

-- ============================================================================
-- STEP 2: BUILD GROUND GLOW (Surface sampling & multi-level glow overlays)
-- ============================================================================
function StadiumLighting.buildGroundGlow(tower: Model, towerIdx: number?): { [string]: number }
	local cfg = StadiumLighting.CONFIG
	local idx = towerIdx or 1
	local towerOffset = idx * 0.002 -- 0.002 stud incremental offset per tower to eliminate z-fighting between overlapping pools

	-- 1. Remove previous glow instances for this tower
	for _, inst in ipairs(tower:GetChildren()) do
		if inst.Name:find("Floodlight_GroundGlow") or inst.Name:find("GroundGlow_") then
			inst:Destroy()
		end
	end

	local headFrame = tower:FindFirstChild("HeadFrame") :: BasePart?
	if not headFrame then
		local panel = tower:FindFirstChildWhichIsA("BasePart")
		headFrame = panel
	end
	if not headFrame then return {} end

	local lampPos = headFrame.Position
	local aimDir = headFrame.CFrame.LookVector
	local groundHitPos = calculateGroundTarget(lampPos, aimDir, cfg.PITCH_SURFACE_Y)

	-- 2. Sample 7x7 grid (step = 10 studs) across a 60x60 stud area around pool center
	local halfSize = cfg.GROUND_GLOW_SIZE / 2
	local gridSize = 7
	local step = (halfSize * 2) / (gridSize - 1)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local ignoreList = { tower }
	local stadium = workspace:FindFirstChild("Stadium")
	if stadium and stadium:FindFirstChild("Borders") then
		table.insert(ignoreList, stadium.Borders)
	end
	for _, child in ipairs(tower:GetDescendants()) do
		if child.Name:find("GroundGlow") or child.Name:find("Glow") then
			table.insert(ignoreList, child)
		end
	end
	rayParams.FilterDescendantsInstances = ignoreList

	local hasGrass = false
	local hasWalkway = false
	local hasTier1 = false
	local hasTier2 = false

	for gx = -halfSize, halfSize, step do
		for gz = -halfSize, halfSize, step do
			local origin = Vector3.new(groundHitPos.X + gx, 100, groundHitPos.Z + gz)
			local hit = workspace:Raycast(origin, Vector3.new(0, -120, 0), rayParams)
			if hit and hit.Instance.Transparency < 1 then
				local y = hit.Position.Y
				if y < 0.35 then
					hasGrass = true
				elseif y >= 0.35 and y < 1.0 then
					hasWalkway = true
				elseif y >= 1.0 and y < 3.5 then
					hasTier1 = true
				elseif y >= 3.5 then
					hasTier2 = true
				end
			end
		end
	end

	local createdY: { [string]: number } = {}

	-- Helper to build radial-gradient SurfaceGui glow part
	local function makeGlowPart(name: string, size: Vector3, cf: CFrame, isCylinder: boolean, face: Enum.NormalId, targetSurfaceY: number): Part
		-- Minimum 0.03 stud offset above real surface + tower offset
		local clearance = cf.Position.Y - targetSurfaceY
		if clearance < 0.03 then
			warn(string.format("[StadiumLighting] ASSERTION WARNING: Glow %s on %s is too close to surface! Clearance: %.4f studs (min 0.03 required)", name, tower.Name, clearance))
		end

		local glow = Instance.new("Part")
		glow.Name = name
		glow.Size = size
		if isCylinder then
			glow.Shape = Enum.PartType.Cylinder
		end
		glow.CFrame = cf
		glow.Anchored = true
		glow.CanCollide = false
		glow.CanTouch = false
		glow.CanQuery = false
		glow.CastShadow = false
		glow.Transparency = 1.0
		glow.Material = Enum.Material.SmoothPlastic
		glow.Parent = tower

		local sGui = Instance.new("SurfaceGui")
		sGui.Name = "GlowGui"
		sGui.Face = face
		sGui.LightInfluence = 0
		sGui.AlwaysOnTop = false
		sGui.PixelsPerStud = 10
		sGui.Parent = glow

		local img = Instance.new("ImageLabel")
		img.Name = "GlowImage"
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = "rbxassetid://6014261993" -- Radial falloff gradient
		img.ImageColor3 = cfg.SPOT_COLOR
		img.ImageTransparency = 1.0 -- Off by default; tweened by applyTowerLighting
		img.Parent = sGui

		createdY[name] = glow.Position.Y
		return glow
	end

	-- 1. Grass Pitch Glow Plate
	if hasGrass then
		local grassY = cfg.PITCH_SURFACE_Y + 0.035 + towerOffset
		makeGlowPart(
			"Floodlight_GroundGlow_Pitch",
			Vector3.new(cfg.GROUND_GLOW_SIZE, 0.02, cfg.GROUND_GLOW_SIZE),
			CFrame.new(groundHitPos.X, grassY, groundHitPos.Z),
			false,
			Enum.NormalId.Top,
			cfg.PITCH_SURFACE_Y
		)
	end

	-- 2. Walkway / Plaza Glow Overlays (conforms to walkway width & round plaza disc)
	if hasWalkway then
		local walkwayY = cfg.WALKWAY_SURFACE_Y + 0.040 + towerOffset
		-- Circular Plaza overlay: perfectly matches Plaza_Roundabout cylinder
		local plazaCF = CFrame.new(0, walkwayY, -39) * CFrame.Angles(0, 0, math.pi / 2)
		local plazaPart = makeGlowPart(
			"Floodlight_GroundGlow_Plaza",
			Vector3.new(0.02, 48, 48),
			plazaCF,
			true,
			Enum.NormalId.Right,
			cfg.WALKWAY_SURFACE_Y
		)
		local pImg = plazaPart:FindFirstChild("GlowImage", true) :: ImageLabel?
		if pImg then
			pImg.ImageTransparency = 1.0
		end

		-- Straight Walkway strip: 24 studs wide to match walkway width exactly (no spill onto grass)
		local walkwayStrip = makeGlowPart(
			"Floodlight_GroundGlow_Walkway",
			Vector3.new(24, 0.02, math.clamp(cfg.GROUND_GLOW_SIZE, 24, 48)),
			CFrame.new(0, walkwayY + 0.001, groundHitPos.Z),
			false,
			Enum.NormalId.Top,
			cfg.WALKWAY_SURFACE_Y
		)
		local wImg = walkwayStrip:FindFirstChild("GlowImage", true) :: ImageLabel?
		if wImg then
			wImg.ImageTransparency = 1.0
		end
	end

	-- 3. Podium Tier 1 Glow Disc (Golden warm highlight, preserves gold surface)
	if hasTier1 then
		local tier1Y = cfg.PODIUM_TIER1_Y + 0.035 + towerOffset
		local t1CF = CFrame.new(0, tier1Y, -42) * CFrame.Angles(0, 0, math.pi / 2)
		local t1Part = makeGlowPart(
			"Floodlight_GroundGlow_Tier1",
			Vector3.new(0.02, 24, 24),
			t1CF,
			true,
			Enum.NormalId.Right,
			cfg.PODIUM_TIER1_Y
		)
		local img = t1Part:FindFirstChild("GlowImage", true) :: ImageLabel?
		if img then
			img.ImageColor3 = Color3.fromHex("#FFE89E") -- Warm golden sheen
			img.ImageTransparency = 1.0
		end
	end

	-- 4. Podium Tier 2 Glow Disc
	if hasTier2 then
		local tier2Y = cfg.PODIUM_TIER2_Y + 0.035 + towerOffset
		local t2CF = CFrame.new(0, tier2Y, -42) * CFrame.Angles(0, 0, math.pi / 2)
		local t2Part = makeGlowPart(
			"Floodlight_GroundGlow_Tier2",
			Vector3.new(0.02, 14, 14),
			t2CF,
			true,
			Enum.NormalId.Right,
			cfg.PODIUM_TIER2_Y
		)
		local img = t2Part:FindFirstChild("GlowImage", true) :: ImageLabel?
		if img then
			img.ImageColor3 = Color3.fromHex("#FFE89E")
			img.ImageTransparency = 1.0
		end
	end

	return createdY
end

-- ============================================================================
-- STEP 3: PLAZA FILL LIGHT
-- ============================================================================
function StadiumLighting.setupPlazaFill(): Part
	local cfg = StadiumLighting.CONFIG.PLAZA_FILL
	local stadium = workspace:FindFirstChild("Stadium")
	local lightsFolder = stadium and stadium:FindFirstChild("Lights") or workspace

	local existing = lightsFolder:FindFirstChild("PlazaFill")
	if existing then existing:Destroy() end

	local fillPart = Instance.new("Part")
	fillPart.Name = "PlazaFill"
	fillPart.Size = Vector3.new(1, 1, 1)
	fillPart.CFrame = CFrame.new(cfg.CENTER)
	fillPart.Anchored = true
	fillPart.CanCollide = false
	fillPart.CanTouch = false
	fillPart.CanQuery = false
	fillPart.CastShadow = false
	fillPart.Transparency = 1.0

	local att = Instance.new("Attachment")
	att.Name = "PlazaFillAtt"
	att.Parent = fillPart

	local spot = Instance.new("SpotLight")
	spot.Name = "PlazaFill_Spot"
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = cfg.SPOT_ANGLE
	spot.Range = cfg.SPOT_RANGE
	spot.Brightness = 0.0 -- Activated by SetLightsState
	spot.Color = cfg.COLOR
	spot.Shadows = false
	spot.Parent = att

	local point = Instance.new("PointLight")
	point.Name = "PlazaFill_Point"
	point.Range = cfg.POINT_RANGE
	point.Brightness = 0.0
	point.Color = cfg.COLOR
	point.Shadows = false
	point.Parent = att

	fillPart.Parent = lightsFolder
	return fillPart
end

local function applyPlazaFillLighting(turnOn: boolean)
	local cfg = StadiumLighting.CONFIG.PLAZA_FILL
	local stadium = workspace:FindFirstChild("Stadium")
	local lightsFolder = stadium and stadium:FindFirstChild("Lights") or workspace
	local fillPart = lightsFolder:FindFirstChild("PlazaFill")
	if not fillPart then return end

	local spot = fillPart:FindFirstChild("PlazaFill_Spot", true) :: SpotLight?
	local point = fillPart:FindFirstChild("PlazaFill_Point", true) :: PointLight?
	local tweenInfo = TweenInfo.new(StadiumLighting.CONFIG.RAMP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if turnOn then
		if spot then TweenService:Create(spot, tweenInfo, { Brightness = cfg.SPOT_BRIGHTNESS }):Play() end
		if point then TweenService:Create(point, tweenInfo, { Brightness = cfg.POINT_BRIGHTNESS }):Play() end
	else
		if spot then TweenService:Create(spot, tweenInfo, { Brightness = 0.0 }):Play() end
		if point then TweenService:Create(point, tweenInfo, { Brightness = 0.0 }):Play() end
	end
end

-- ============================================================================
-- STEP 4: WALKWAY / PLAZA RESTYLE & ROLLBACK
-- ============================================================================
function StadiumLighting.applyWalkwayRestyle(applyRestyle: boolean)
	local cfg = StadiumLighting.CONFIG
	local lobby = workspace:FindFirstChild("Lobby")
	local walkwayFolder = lobby and lobby:FindFirstChild("Walkway")
	if not walkwayFolder then return end

	for _, part in ipairs(walkwayFolder:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name:find("EdgeLine") then
				-- Keep edge line markings crisp white
				continue
			end

			if applyRestyle then
				-- Save original properties for clean rollback
				if not part:GetAttribute("OriginalColor") then
					part:SetAttribute("OriginalColor", part.Color:ToHex())
					part:SetAttribute("OriginalMaterial", part.Material.Name)
					part:SetAttribute("OriginalReflectance", part.Reflectance)
				end

				if part.Name == "Plaza_Roundabout" then
					part.Color = cfg.PLAZA_COLOR
				else
					part.Color = cfg.WALKWAY_COLOR
				end
				part.Material = cfg.WALKWAY_MATERIAL
				part.Reflectance = cfg.WALKWAY_REFLECTANCE
			else
				-- Rollback
				local oldHex = part:GetAttribute("OriginalColor") :: string?
				local oldMat = part:GetAttribute("OriginalMaterial") :: string?
				local oldRef = part:GetAttribute("OriginalReflectance") :: number?
				if oldHex then part.Color = Color3.fromHex(oldHex) end
				if oldMat then
					local ok, matEnum = pcall(function() return (Enum.Material :: any)[oldMat] end)
					if ok and matEnum then part.Material = matEnum end
				end
				if oldRef ~= nil then part.Reflectance = oldRef end
			end
		end
	end
end

-- ============================================================================
-- PER-TOWER BUILDER: buildFloodlightLighting(tower, towerIdx)
-- ============================================================================
function StadiumLighting.buildFloodlightLighting(tower: Model, towerIdx: number?)
	local cfg = StadiumLighting.CONFIG
	local idx = towerIdx or 1

	-- 1. Re-runnable: Safely destroy any previously generated Floodlight_* instances
	for _, inst in ipairs(tower:GetDescendants()) do
		if inst.Name:find("Floodlight_") then
			inst:Destroy()
		end
	end

	-- 2. Detect Tower Parts
	local headFrame = tower:FindFirstChild("HeadFrame") :: BasePart?
	local beacon = tower:FindFirstChild("AviationBeacon") :: BasePart?
	local collarMid = tower:FindFirstChild("Collar_Mid") :: BasePart?

	local lampPanels: { BasePart } = {}
	for _, c in ipairs(tower:GetChildren()) do
		if c:IsA("BasePart") and (c.Name:find("LampPanel") or c.Name:find("FloodLamp")) then
			table.insert(lampPanels, c)
			CollectionService:AddTag(c, cfg.TAG_LAMP)
		end
	end

	if not headFrame and #lampPanels > 0 then
		headFrame = lampPanels[1]
	end
	if not headFrame then return end

	CollectionService:AddTag(tower, cfg.TAG_TOWER)
	CollectionService:AddTag(headFrame, cfg.TAG_LAMP)

	-- 3. Determine Face Normal & Aim Direction
	local aimDir = headFrame.CFrame.LookVector
	local lampPos = headFrame.Position
	local groundHitPos = calculateGroundTarget(lampPos, aimDir, cfg.PITCH_SURFACE_Y)

	-- 4. Central Front-Face Attachment
	local headAtt = Instance.new("Attachment")
	headAtt.Name = "Floodlight_HeadAtt"
	headAtt.Position = Vector3.new(0, 0, -0.6)
	headAtt.Parent = headFrame

	-- 5. Primary SpotLight (Range 200, Angle 82, Shadows only on key diagonal towers)
	local spot = Instance.new("SpotLight")
	spot.Name = "Floodlight_Spot"
	spot.Brightness = 0.0 -- Controlled by day/night state
	spot.Range = cfg.SPOT_RANGE
	spot.Angle = cfg.SPOT_ANGLE
	spot.Color = cfg.SPOT_COLOR
	spot.Face = Enum.NormalId.Front
	spot.Shadows = cfg.SHADOW_KEY_TOWERS[tower.Name] == true
	spot.Parent = headAtt

	-- 6. Ambient Halo PointLight
	local halo = Instance.new("PointLight")
	halo.Name = "Floodlight_Point"
	halo.Brightness = 0.0
	halo.Range = cfg.POINT_RANGE
	halo.Color = cfg.SPOT_COLOR
	halo.Shadows = false
	halo.Parent = headAtt

	-- 7. Multi-Surface Ground Glow Overlays
	StadiumLighting.buildGroundGlow(tower, idx)

	-- 8. Volumetric Light Cone Beam
	local groundGlow = tower:FindFirstChild("Floodlight_GroundGlow_Pitch") or tower:FindFirstChild("Floodlight_GroundGlow_Walkway")
	local groundAtt = groundGlow and groundGlow:FindFirstChild("Floodlight_GroundAtt")
	if not groundAtt and groundGlow then
		groundAtt = Instance.new("Attachment")
		groundAtt.Name = "Floodlight_GroundAtt"
		groundAtt.Parent = groundGlow
	end

	if groundAtt then
		local beam = Instance.new("Beam")
		beam.Name = "Floodlight_Beam"
		beam.Attachment0 = headAtt
		beam.Attachment1 = groundAtt
		beam.Width0 = 7.0
		beam.Width1 = 36.0
		beam.FaceCamera = true
		beam.LightEmission = 0.5
		beam.LightInfluence = 0.0
		beam.Color = ColorSequence.new(cfg.SPOT_COLOR)
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, cfg.BEAM_TRANSPARENCY),
			NumberSequenceKeypoint.new(0.6, 0.96),
			NumberSequenceKeypoint.new(1.0, 1.0),
		})
		beam.Enabled = false
		beam.Parent = headFrame
	end

	-- 9. Billboard Lens Flare
	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "Floodlight_FlareGui"
	bbGui.Size = UDim2.fromScale(cfg.FLARE_SIZE, cfg.FLARE_SIZE)
	bbGui.AlwaysOnTop = false
	bbGui.MaxDistance = cfg.FLARE_MAX_DIST
	bbGui.Parent = headAtt

	local flareImg = Instance.new("ImageLabel")
	flareImg.Name = "FlareImage"
	flareImg.Size = UDim2.fromScale(1, 1)
	flareImg.BackgroundTransparency = 1
	flareImg.Image = "rbxassetid://6015897843"
	flareImg.ImageColor3 = cfg.SPOT_COLOR
	flareImg.ImageTransparency = 1.0
	flareImg.Parent = bbGui

	-- 10. Apex Aviation Red Beacon Light
	if beacon then
		local bLight = Instance.new("PointLight")
		bLight.Name = "Floodlight_BeaconLight"
		bLight.Color = cfg.BEACON_COLOR
		bLight.Range = cfg.BEACON_RANGE
		bLight.Brightness = 2.0
		bLight.Shadows = false
		bLight.Parent = beacon
	end

	-- Initialize panels to off state
	for _, p in ipairs(lampPanels) do
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromRGB(42, 45, 52)
		p.Transparency = 0.3
	end
end

-- ============================================================================
-- WARM-UP FLICKER & ON/OFF APPLICATION
-- ============================================================================
local function applyTowerLighting(tower: Model, turnOn: boolean, useWarmup: boolean)
	local cfg = StadiumLighting.CONFIG
	local spot = tower:FindFirstChild("Floodlight_Spot", true) :: SpotLight?
	local point = tower:FindFirstChild("Floodlight_Point", true) :: PointLight?
	local beam = tower:FindFirstChild("Floodlight_Beam", true) :: Beam?
	local collarMid = tower:FindFirstChild("Collar_Mid") :: BasePart?

	-- Gather all glow images for pitch, walkway, and podium tiers
	local glowImgs: { ImageLabel } = {}
	for _, inst in ipairs(tower:GetDescendants()) do
		if inst:IsA("ImageLabel") and inst.Name == "GlowImage" then
			table.insert(glowImgs, inst)
		end
	end

	local panels: { BasePart } = {}
	for _, c in ipairs(tower:GetChildren()) do
		if c:IsA("BasePart") and (c.Name:find("LampPanel") or c.Name:find("FloodLamp")) then
			table.insert(panels, c)
		end
	end

	local tweenInfo = TweenInfo.new(cfg.RAMP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if turnOn then
		task.spawn(function()
			if useWarmup and cfg.WARMUP_FLICKER then
				task.wait(math.random(10, 150) / 100)
				if spot then spot.Brightness = cfg.SPOT_BRIGHTNESS * 0.4 end
				for _, p in ipairs(panels) do p.Material = Enum.Material.Neon; p.Color = Color3.fromHex("#FFF8E0") end
				task.wait(0.08)
				if spot then spot.Brightness = 0.0 end
				for _, p in ipairs(panels) do p.Material = Enum.Material.SmoothPlastic; p.Color = Color3.fromRGB(42, 45, 52) end
				task.wait(0.12)
				if spot then spot.Brightness = cfg.SPOT_BRIGHTNESS * 0.7 end
				for _, p in ipairs(panels) do p.Material = Enum.Material.Neon; p.Color = Color3.fromHex("#FFF8E0") end
				task.wait(0.10)
				if spot then spot.Brightness = 0.1 end
				task.wait(0.06)
			end

			if spot then
				TweenService:Create(spot, tweenInfo, { Brightness = cfg.SPOT_BRIGHTNESS }):Play()
			end
			if point then
				TweenService:Create(point, tweenInfo, { Brightness = cfg.POINT_BRIGHTNESS }):Play()
			end
			if beam and cfg.BEAMS_ENABLED then
				beam.Enabled = true
			end
			for _, img in ipairs(glowImgs) do
				local targetTrans = if img.Parent and img.Parent.Parent and img.Parent.Parent.Name:find("Tier") then 0.85 else cfg.GROUND_GLOW_TRANSPARENCY
				TweenService:Create(img, tweenInfo, { ImageTransparency = targetTrans }):Play()
			end
			for _, p in ipairs(panels) do
				p.Material = Enum.Material.Neon
				p.Transparency = 0.0
				TweenService:Create(p, tweenInfo, { Color = Color3.fromHex("#FFF8E0") }):Play()
			end
			if collarMid and cfg.POLE_GLOW_ENABLED then
				collarMid.Material = Enum.Material.Neon
				collarMid.Color = cfg.COLLAR_COLOR
			end
		end)
	else
		if spot then
			TweenService:Create(spot, tweenInfo, { Brightness = 0.0 }):Play()
		end
		if point then
			TweenService:Create(point, tweenInfo, { Brightness = 0.0 }):Play()
		end
		if beam then
			beam.Enabled = false
		end
		for _, img in ipairs(glowImgs) do
			TweenService:Create(img, tweenInfo, { ImageTransparency = 1.0 }):Play()
		end
		for _, p in ipairs(panels) do
			TweenService:Create(p, tweenInfo, { Color = Color3.fromRGB(42, 45, 52), Transparency = 0.3 }):Play()
			task.delay(cfg.RAMP_DURATION, function()
				if not isLightsOn then
					p.Material = Enum.Material.SmoothPlastic
				end
			end)
		end
		if collarMid then
			collarMid.Material = Enum.Material.SmoothPlastic
		end
	end
end

-- ============================================================================
-- GLOBAL LIGHTING UPDATE
-- ============================================================================
local function updateGlobalLighting(turnOn: boolean)
	local tweenInfo = TweenInfo.new(StadiumLighting.CONFIG.RAMP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local atmosphere = Lighting:FindFirstChildWhichIsA("Atmosphere")
	local bloom = Lighting:FindFirstChildWhichIsA("BloomEffect")

	if turnOn then
		TweenService:Create(Lighting, tweenInfo, {
			Brightness = 0.2,
			OutdoorAmbient = Color3.fromRGB(24, 28, 42),
			Ambient = Color3.fromRGB(10, 12, 18),
			EnvironmentDiffuseScale = 0.25,
			EnvironmentSpecularScale = 0.30,
			ShadowSoftness = 0.60,
		}):Play()
		if atmosphere then
			TweenService:Create(atmosphere, tweenInfo, {
				Color = Color3.fromRGB(25, 35, 60),
				Decay = Color3.fromRGB(12, 16, 30),
				Density = 0.35,
				Haze = 0.40,
				Glare = 0,
			}):Play()
		end
		if bloom then
			TweenService:Create(bloom, tweenInfo, {
				Intensity = 0.25,
				Threshold = 1.8,
				Size = 22,
			}):Play()
		end
	else
		TweenService:Create(Lighting, tweenInfo, {
			Brightness = 2.4,
			OutdoorAmbient = Color3.fromRGB(115, 125, 140),
			Ambient = Color3.fromRGB(35, 40, 48),
			EnvironmentDiffuseScale = 1.0,
			EnvironmentSpecularScale = 1.0,
			ShadowSoftness = 0.20,
		}):Play()
		if atmosphere then
			TweenService:Create(atmosphere, tweenInfo, {
				Color = Color3.fromRGB(220, 235, 255),
				Decay = Color3.fromRGB(120, 170, 255),
				Density = 0.22,
				Haze = 0.20,
			}):Play()
		end
		if bloom then
			TweenService:Create(bloom, tweenInfo, {
				Intensity = 0.20,
				Threshold = 1.8,
				Size = 20,
			}):Play()
		end
	end
end

-- ============================================================================
-- PUBLIC API: SetLightsState / SetMode
-- ============================================================================
function StadiumLighting.SetLightsState(turnOn: boolean, useWarmup: boolean?)
	if isLightsOn == turnOn then return end
	isLightsOn = turnOn
	workspace:SetAttribute("StadiumLightsOn", turnOn)

	local towers = StadiumLighting.GetTowers()
	for _, tower in ipairs(towers) do
		applyTowerLighting(tower, turnOn, if useWarmup ~= nil then useWarmup else true)
	end
	applyPlazaFillLighting(turnOn)
	updateGlobalLighting(turnOn)
end

function StadiumLighting.SetMode(mode: LightingMode)
	currentMode = mode
	workspace:SetAttribute("StadiumLightingMode", mode)

	if mode == "Night" then
		Lighting.ClockTime = 20.0
		StadiumLighting.SetLightsState(true, true)
	elseif mode == "Day" then
		Lighting.ClockTime = 14.0
		StadiumLighting.SetLightsState(false, false)
	elseif mode == "Auto" then
		StadiumLighting.CheckAutoClockTime()
	end
end

function StadiumLighting.GetMode(): LightingMode
	return currentMode
end

function StadiumLighting.CheckAutoClockTime()
	if currentMode ~= "Auto" and not StadiumLighting.CONFIG.AUTO_MODE then return end
	local clock = Lighting.ClockTime
	local cfg = StadiumLighting.CONFIG
	local shouldBeOn = (clock >= cfg.NIGHT_START_TIME or clock < cfg.NIGHT_END_TIME)
	StadiumLighting.SetLightsState(shouldBeOn, true)
end

-- ============================================================================
-- STEP 5: DEBUG & FIX ADMIN TOOLS
-- ============================================================================
function StadiumLighting.SetDebugMode(enabled: boolean)
	debugActive = enabled
	local debugFolder = workspace:FindFirstChild("LightDebugVisuals")
	if debugFolder then debugFolder:Destroy() end

	if not enabled then
		print("[StadiumLightingDebug] Debug visuals disabled.")
		return
	end

	debugFolder = Instance.new("Folder")
	debugFolder.Name = "LightDebugVisuals"
	debugFolder.Parent = workspace

	local towers = StadiumLighting.GetTowers()
	print(string.format("=== [StadiumLightingDebug] AUDITING %d TOWERS ===", #towers))

	local hiddenCount = 0
	local validCount = 0

	for _, tower in ipairs(towers) do
		local head = tower:FindFirstChild("HeadFrame") :: BasePart?
		local spot = tower:FindFirstChild("Floodlight_Spot", true) :: SpotLight?

		-- Inspect glow parts
		for _, child in ipairs(tower:GetChildren()) do
			if child:IsA("BasePart") and child.Name:find("Floodlight_GroundGlow") then
				local surfaceY = 0.20
				if child.Name:find("Walkway") then
					surfaceY = 0.50
				elseif child.Name:find("Tier1") then
					surfaceY = 2.25
				elseif child.Name:find("Tier2") then
					surfaceY = 6.25
				end

				local clearance = child.Position.Y - surfaceY
				local isHidden = clearance < 0.0

				local sBox = Instance.new("SelectionBox")
				sBox.Adornee = child
				sBox.Color3 = if isHidden then Color3.fromRGB(255, 30, 30) else Color3.fromRGB(30, 255, 30)
				sBox.LineThickness = 0.05
				sBox.Parent = debugFolder

				if isHidden then
					hiddenCount += 1
					warn(string.format("[HIDDEN GLOW] %s in %s: Y=%.4f is BELOW surface Y=%.4f (Diff: %.4f)", child.Name, tower.Name, child.Position.Y, surfaceY, clearance))
				else
					validCount += 1
					print(string.format("[VALID GLOW] %s in %s: Y=%.4f sits above surface Y=%.4f (Clearance: +%.4f)", child.Name, tower.Name, child.Position.Y, surfaceY, clearance))
				end
			end
		end
	end

	print(string.format("=== AUDIT COMPLETE: %d VALID GLOWS, %d HIDDEN GLOWS ===", validCount, hiddenCount))
end

function StadiumLighting.RebuildAllGlows(): { [string]: any }
	local towers = StadiumLighting.GetTowers()
	local log = {}
	print(string.format("[StadiumLighting] Rebuilding ground glow for %d towers...", #towers))

	for idx, tower in ipairs(towers) do
		local oldGlow = tower:FindFirstChild("Floodlight_GroundGlow_Pitch") or tower:FindFirstChild("Floodlight_GroundGlow")
		local oldY = oldGlow and oldGlow.Position.Y or 0.22

		StadiumLighting.buildFloodlightLighting(tower, idx)
		table.insert(log, {
			Tower = tower.Name,
			PreviousGlowY = oldY,
		})
	end

	StadiumLighting.setupPlazaFill()
	if StadiumLighting.CONFIG.WALKWAY_RESTYLE then
		StadiumLighting.applyWalkwayRestyle(true)
	end

	-- If lights are currently ON, update transparencies immediately
	if isLightsOn then
		for _, tower in ipairs(towers) do
			for _, inst in ipairs(tower:GetDescendants()) do
				if inst:IsA("ImageLabel") and inst.Name == "GlowImage" then
					local targetTrans = if inst.Parent and inst.Parent.Parent and inst.Parent.Parent.Name:find("Tier") then 0.85 else StadiumLighting.CONFIG.GROUND_GLOW_TRANSPARENCY
					inst.ImageTransparency = targetTrans
				end
			end
		end
		applyPlazaFillLighting(true)
	end

	print(string.format("[StadiumLighting] Successfully rebuilt %d towers with multi-level surface glow.", #towers))
	return log
end

-- ============================================================================
-- OPTIONAL DAY/NIGHT CYCLE
-- ============================================================================
function StadiumLighting.StartDayNightCycle()
	if cycleThread then return end
	StadiumLighting.CONFIG.CYCLE_ENABLED = true
	cycleThread = task.spawn(function()
		while StadiumLighting.CONFIG.CYCLE_ENABLED do
			local rate = 24 / (StadiumLighting.CONFIG.CYCLE_MINUTES * 60)
			Lighting.ClockTime = (Lighting.ClockTime + rate * 0.1) % 24
			StadiumLighting.CheckAutoClockTime()
			task.wait(0.1)
		end
	end)
end

function StadiumLighting.StopDayNightCycle()
	StadiumLighting.CONFIG.CYCLE_ENABLED = false
	if cycleThread then
		task.cancel(cycleThread)
		cycleThread = nil
	end
end

return StadiumLighting

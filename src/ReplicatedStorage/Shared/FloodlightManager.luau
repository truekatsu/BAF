--!strict
--[[
	FloodlightManager
	Responsibility: Procedural generator and lighting controller for the stadium floodlights.
	Features:
	- 10 tall stadium floodlight towers placed outside the roof edge, rising above the roofline.
	- Heavy base pedestal, 34-stud navy mast (#0F1530) with gold collars, service platform with railings,
	  and a gold-beveled 4 x 3 lamp array (12 neon modules) angled down toward the pitch center.
	- 1 wide-throw SpotLight per tower (Range 110, Angle 90, Shadows OFF) + 1 ambient PointLight.
	- Faint volumetric light cone beams (Attachment-based Beams) pointing down to the pitch.
	- Apex blinking red aviation obstruction beacon.
	- Day / Night / Event mode system with smooth TweenService transitions.
	- Mobile-friendly: 20 total light sources (under the 24 budget), no server per-frame loops.
	- Exposes BindableEvent & RemoteEvent for goal / jackpot celebration triggers.

	Location: ReplicatedStorage/Shared/FloodlightManager (ModuleScript)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local FloodlightManager = {}

-- ============================================================================
-- 1. MASTER CONFIGURATION
-- ============================================================================
FloodlightManager.CONFIG = {
	-- Hierarchy & Target
	PARENT_PATH = "Workspace/Stadium/Lights",
	PITCH_CENTER = Vector3.new(0, 0, -43),

	-- Tower Dimensions
	BASE_HEIGHT = 26.0,          -- Height of base pedestal from ground to outer wall rim
	MAST_HEIGHT = 34.0,          -- Height of navy mast pole above pedestal (head at Y ≈ 61.5)
	HEAD_WIDTH = 11.2,           -- Width of rectangular lamp head frame
	HEAD_HEIGHT = 7.6,           -- Height of rectangular lamp head frame
	HEAD_DEPTH = 1.2,            -- Depth of lamp head frame
	LAMP_COLS = 4,               -- Grid columns of neon lamp panels (4 x 3 = 12 panels)
	LAMP_ROWS = 3,               -- Grid rows of neon lamp panels

	-- Light Sources
	SPOT_RANGE = 110.0,          -- Studs distance of main floodlight throw
	SPOT_ANGLE = 90.0,           -- Beam spread angle (degrees)
	POINT_RANGE = 16.0,          -- Ambient flare range around the lamp array
	CAST_SHADOWS = false,        -- Always false for silky 60 FPS mobile performance

	-- Mode Presets
	MODES = {
		Day = {
			ClockTime = 14.2,
			Brightness = 2.2,
			OutdoorAmbient = Color3.fromRGB(120, 135, 155),
			SpotBrightness = 0.0,
			PointBrightness = 0.0,
			LampTransparency = 0.5,
			BeamsEnabled = false,
			AtmosphereDensity = 0.30,
			BloomIntensity = 0.40,
			CCTint = Color3.fromRGB(255, 255, 255),
			CCSaturation = 0.10,
		},
		Night = {
			ClockTime = 20.0,
			Brightness = 0.9,
			OutdoorAmbient = Color3.fromRGB(48, 54, 72),
			SpotBrightness = 1.8,
			PointBrightness = 1.2,
			LampTransparency = 0.0,
			BeamsEnabled = true,
			AtmosphereDensity = 0.38,
			BloomIntensity = 1.10,
			CCTint = Color3.fromRGB(250, 246, 238),
			CCSaturation = 0.18,
		},
	},

	-- Transitions & Timing
	TWEEN_DURATION = 2.5,        -- Duration of Day <-> Night smooth transition (seconds)
	EVENT_DURATION = 3.0,        -- Duration of celebration pulse on goal/jackpot (seconds)

	-- Colors
	COLORS = {
		MastPole = Color3.fromHex("#0F1530"),       -- Deep Dark Navy
		BasePedestal = Color3.fromHex("#151A24"),   -- Gunmetal Steel
		Collars = Color3.fromHex("#F5B82E"),        -- Bright Gold Collar
		Platform = Color3.fromHex("#222630"),       -- Grated Steel Platform
		Railings = Color3.fromHex("#3A4252"),       -- Handrail Dark Charcoal
		HeadFrame = Color3.fromHex("#151A24"),      -- Lamp Bezel Backing
		HeadTrim = Color3.fromHex("#F5B82E"),       -- Gold Bezel Face Trim
		LampPanelWarm = Color3.fromRGB(255, 248, 230), -- Warm Stadium White
		LightColor = Color3.fromRGB(255, 248, 235), -- Light Source Tint
		AviationBeacon = Color3.fromRGB(255, 25, 25), -- Safety Red Obstruction Light
		EventBlue = Color3.fromHex("#1F4FD8"),      -- Celebration Royal Blue
		EventGold = Color3.fromHex("#F5B82E"),      -- Celebration Gold
	},

	-- Tower Layout (10 towers placed outside the roof edge, rising above the roofline)
	TOWERS = {
		{ name = "Tower_Corner_NW", pos = Vector3.new(-126.6, 0, -142.6) },
		{ name = "Tower_Corner_NE", pos = Vector3.new(126.6, 0, -142.6) },
		{ name = "Tower_Corner_SE", pos = Vector3.new(126.6, 0, 56.6) },
		{ name = "Tower_Corner_SW", pos = Vector3.new(-126.6, 0, 56.6) },
		{ name = "Tower_North_1", pos = Vector3.new(-54.0, 0, -157.5) },
		{ name = "Tower_North_2", pos = Vector3.new(54.0, 0, -157.5) },
		{ name = "Tower_South_1", pos = Vector3.new(-54.0, 0, 71.5) },
		{ name = "Tower_South_2", pos = Vector3.new(54.0, 0, 71.5) },
		{ name = "Tower_West", pos = Vector3.new(-141.5, 0, -43.0) },
		{ name = "Tower_East", pos = Vector3.new(141.5, 0, -43.0) },
	},
}

export type FloodlightConfig = typeof(FloodlightManager.CONFIG)

-- State tracking
local currentMode: "Day" | "Night" | "Event" = "Day"
local previousMode: "Day" | "Night" = "Day"
local eventActive = false

-- ============================================================================
-- 2. REPLICATION & NETWORKING SETUP
-- ============================================================================
local function resolveNetworkObjects(): (StringValue, RemoteEvent, BindableEvent)
	local modeVal = ReplicatedStorage:FindFirstChild("LightingMode") :: StringValue?
	if not modeVal then
		modeVal = Instance.new("StringValue")
		modeVal.Name = "LightingMode"
		modeVal.Value = "Day"
		modeVal.Parent = ReplicatedStorage
	end

	local remote = ReplicatedStorage:FindFirstChild("LightingModeChanged") :: RemoteEvent?
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "LightingModeChanged"
		remote.Parent = ReplicatedStorage
	end

	local bindable = ReplicatedStorage:FindFirstChild("LightingModeEvent") :: BindableEvent?
	if not bindable then
		bindable = Instance.new("BindableEvent")
		bindable.Name = "LightingModeEvent"
		bindable.Parent = ReplicatedStorage
	end

	return modeVal :: StringValue, remote :: RemoteEvent, bindable :: BindableEvent
end

-- ============================================================================
-- 3. HELPER FUNCTIONS
-- ============================================================================
local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material?,
	canCollide: boolean?,
	castShadow: boolean?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = if canCollide ~= nil then canCollide else false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = if castShadow ~= nil then castShadow else false
	if transparency then
		p.Transparency = transparency
	end
	p.Parent = parent
	return p
end

local function resolveLightsContainer(): Folder
	local stadium = Workspace:FindFirstChild("Stadium")
	if not stadium then
		stadium = Instance.new("Folder")
		stadium.Name = "Stadium"
		stadium.Parent = Workspace
	end

	local lights = stadium:FindFirstChild("Lights")
	if not lights then
		lights = Instance.new("Folder")
		lights.Name = "Lights"
		lights.Parent = stadium
	end

	return lights :: Folder
end

-- Archives old prototype lighting in Workspace.Stadium.Stands.Lighting
local function archiveOldLighting()
	local stadium = Workspace:FindFirstChild("Stadium")
	local stands = stadium and stadium:FindFirstChild("Stands")
	if stands and stands:FindFirstChild("Lighting") then
		local backupFolder = ServerStorage:FindFirstChild("Stands_Backup")
		if not backupFolder then
			backupFolder = Instance.new("Folder")
			backupFolder.Name = "Stands_Backup"
			backupFolder.Parent = ServerStorage
		end
		local old = stands.Lighting
		old.Name = "OldLighting_Backup"
		old.Parent = backupFolder
	end
end

-- ============================================================================
-- 4. PUBLIC API: GENERATE, CLEAR, REGENERATE
-- ============================================================================

function FloodlightManager.Clear()
	local stadium = Workspace:FindFirstChild("Stadium")
	if stadium and stadium:FindFirstChild("Lights") then
		stadium.Lights:Destroy()
	end
end

function FloodlightManager.Generate(customConfig: FloodlightConfig?): Folder
	local cfg = customConfig or FloodlightManager.CONFIG
	archiveOldLighting()

	local lightsFolder = resolveLightsContainer()
	lightsFolder:ClearAllChildren()

	local pitchCenter = cfg.PITCH_CENTER
	local colors = cfg.COLORS

	for _, tData in ipairs(cfg.TOWERS) do
		local m = Instance.new("Model")
		m.Name = tData.name
		m.Parent = lightsFolder

		local towerPos = tData.pos
		local pedH = cfg.BASE_HEIGHT
		local mastH = cfg.MAST_HEIGHT
		local mastBaseY = pedH + 0.8
		local headY = mastBaseY + mastH + 0.5
		local headPos = towerPos + Vector3.new(0, headY, 0)
		local targetPos = pitchCenter + Vector3.new(0, 2, 0)

		-- 1. Base Pedestal (Ground Y=0 to outer wall rim Y=26)
		makePart(m, "BasePedestal", Vector3.new(3.8, pedH, 3.8), CFrame.new(towerPos + Vector3.new(0, pedH * 0.5, 0)), colors.BasePedestal, Enum.Material.Metal, true, true)
		makePart(m, "Collar_Base", Vector3.new(4.4, 0.8, 4.4), CFrame.new(towerPos + Vector3.new(0, pedH + 0.4, 0)), colors.Collars, Enum.Material.SmoothPlastic, false, false)

		-- 2. Mast Pole (Navy steel, rises from Y=26 to Y=61)
		makePart(m, "MastPole", Vector3.new(2.4, mastH, 2.4), CFrame.new(towerPos + Vector3.new(0, mastBaseY + mastH * 0.5, 0)), colors.MastPole, Enum.Material.Metal, false, false)
		makePart(m, "Collar_Mid", Vector3.new(2.8, 0.6, 2.8), CFrame.new(towerPos + Vector3.new(0, mastBaseY + mastH * 0.55, 0)), colors.Collars, Enum.Material.SmoothPlastic, false, false)

		-- 3. Service Platform (Y = headY - 4.5 studs)
		local platH = headY - 4.5
		local platPos = towerPos + Vector3.new(0, platH, 0)
		local yawAngle = math.atan2(targetPos.X - towerPos.X, targetPos.Z - towerPos.Z)
		local towerRot = CFrame.new(platPos) * CFrame.Angles(0, yawAngle, 0)

		makePart(m, "PlatformFloor", Vector3.new(6.0, 0.4, 4.8), towerRot * CFrame.new(0, 0, 1.0), colors.Platform, Enum.Material.DiamondPlate, false, false)
		makePart(m, "Rail_Back", Vector3.new(6.0, 2.0, 0.2), towerRot * CFrame.new(0, 1.1, -1.3), colors.Railings, Enum.Material.Metal, false, false)
		makePart(m, "Rail_L", Vector3.new(0.2, 2.0, 4.8), towerRot * CFrame.new(-2.9, 1.1, 1.0), colors.Railings, Enum.Material.Metal, false, false)
		makePart(m, "Rail_R", Vector3.new(0.2, 2.0, 4.8), towerRot * CFrame.new(2.9, 1.1, 1.0), colors.Railings, Enum.Material.Metal, false, false)

		-- 4. Lamp Head Frame (Oriented and tilted directly toward pitch center)
		local headLook = CFrame.lookAt(headPos, targetPos)
		local hFrame = makePart(m, "HeadFrame", Vector3.new(cfg.HEAD_WIDTH, cfg.HEAD_HEIGHT, cfg.HEAD_DEPTH), headLook * CFrame.new(0, 0, 0.6), colors.HeadFrame, Enum.Material.Metal, false, false)
		makePart(m, "HeadTrim", Vector3.new(cfg.HEAD_WIDTH + 0.4, cfg.HEAD_HEIGHT + 0.4, 0.3), headLook * CFrame.new(0, 0, 0.0), colors.HeadTrim, Enum.Material.SmoothPlastic, false, false)

		-- 5. 4 x 3 Neon Lamp Panels Grid (12 modules)
		local cols, rows = cfg.LAMP_COLS, cfg.LAMP_ROWS
		local pW = cfg.HEAD_WIDTH / cols
		local pH = cfg.HEAD_HEIGHT / rows
		local startX = -(cols - 1) * pW * 0.5
		local startY = -(rows - 1) * pH * 0.5

		for c = 1, cols do
			for r = 1, rows do
				local lx = startX + (c - 1) * pW
				local ly = startY + (r - 1) * pH
				local pCF = headLook * CFrame.new(lx, ly, -0.1)
				makePart(m, `LampPanel_{c}_{r}`, Vector3.new(pW - 0.25, pH - 0.25, 0.3), pCF, colors.LampPanelWarm, Enum.Material.Neon, false, false, 0.5)
			end
		end

		-- 6. Aviation Obstruction Beacon at Tower Apex
		makePart(m, "BeaconRod", Vector3.new(0.3, 2.0, 0.3), CFrame.new(headPos + Vector3.new(0, cfg.HEAD_HEIGHT * 0.5 + 1.0, 0)), colors.Railings, Enum.Material.Metal, false, false)
		makePart(m, "AviationBeacon", Vector3.new(0.7, 0.7, 0.7), CFrame.new(headPos + Vector3.new(0, cfg.HEAD_HEIGHT * 0.5 + 2.2, 0)), colors.AviationBeacon, Enum.Material.Neon, false, false, 0.0)

		-- 7. Real Light Sources (Shadows OFF for 60 FPS mobile performance)
		local spot = Instance.new("SpotLight")
		spot.Name = "FloodSpot"
		spot.Brightness = 0.0 -- default Day mode
		spot.Range = cfg.SPOT_RANGE
		spot.Angle = cfg.SPOT_ANGLE
		spot.Face = Enum.NormalId.Front
		spot.Color = colors.LightColor
		spot.Shadows = cfg.CAST_SHADOWS
		spot.Parent = hFrame

		local point = Instance.new("PointLight")
		point.Name = "FloodPoint"
		point.Brightness = 0.0
		point.Range = cfg.POINT_RANGE
		point.Color = colors.LightColor
		point.Shadows = cfg.CAST_SHADOWS
		point.Parent = hFrame

		-- 8. Faint Volumetric Light Cone Beam
		local att0 = Instance.new("Attachment")
		att0.Name = "LampBeamAtt"
		att0.Position = Vector3.new(0, 0, -0.5)
		att0.Parent = hFrame

		local groundTarget = makePart(m, "GroundBeamTarget", Vector3.new(1, 1, 1), CFrame.new(targetPos), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false, false, 1.0)
		local att1 = Instance.new("Attachment")
		att1.Name = "GroundBeamAtt"
		att1.Parent = groundTarget

		local beam = Instance.new("Beam")
		beam.Name = "LightConeBeam"
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.FaceCamera = true
		beam.Width0 = 7.0
		beam.Width1 = 36.0
		beam.LightEmission = 0.5
		beam.LightInfluence = 0.0
		beam.Color = ColorSequence.new(colors.LightColor)
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.80),
			NumberSequenceKeypoint.new(0.5, 0.90),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		beam.Enabled = false -- Enabled in Night mode
		beam.Parent = hFrame
	end

	resolveNetworkObjects()
	FloodlightManager.SetMode("Day")

	return lightsFolder
end

function FloodlightManager.Regenerate(customConfig: FloodlightConfig?): Folder
	FloodlightManager.Clear()
	return FloodlightManager.Generate(customConfig)
end

-- ============================================================================
-- 5. DAY / NIGHT / EVENT MODE CONTROLLER
-- ============================================================================

function FloodlightManager.GetMode(): string
	return currentMode
end

function FloodlightManager.SetMode(mode: "Day" | "Night" | "Event")
	if mode == "Event" and eventActive then return end

	local modeVal, remote, bindable = resolveNetworkObjects()

	if mode == "Event" then
		eventActive = true
		modeVal.Value = "Event"
		if RunService:IsRunning() then
			remote:FireAllClients("Event", previousMode)
		end
		bindable:Fire("Event", previousMode)

		-- Automatically restore previous mode after 3 seconds
		task.delay(FloodlightManager.CONFIG.EVENT_DURATION, function()
			eventActive = false
			FloodlightManager.SetMode(previousMode)
		end)
		return
	end

	previousMode = mode
	currentMode = mode
	modeVal.Value = mode

	-- Replicate to all clients (client handles smooth TweenService)
	if RunService:IsRunning() then
		remote:FireAllClients(mode)
	end
	bindable:Fire(mode)

	-- Apply server-side baseline properties
	local preset = FloodlightManager.CONFIG.MODES[mode]
	if preset then
		Lighting.ClockTime = preset.ClockTime
		Lighting.Brightness = preset.Brightness
		Lighting.OutdoorAmbient = preset.OutdoorAmbient

		local lights = Workspace:FindFirstChild("Stadium") and Workspace.Stadium:FindFirstChild("Lights")
		if lights then
			for _, tower in ipairs(lights:GetChildren()) do
				local spot = tower:FindFirstChild("FloodSpot", true) :: SpotLight?
				if spot then spot.Brightness = preset.SpotBrightness end

				local point = tower:FindFirstChild("FloodPoint", true) :: PointLight?
				if point then point.Brightness = preset.PointBrightness end

				local beam = tower:FindFirstChild("LightConeBeam", true) :: Beam?
				if beam then beam.Enabled = preset.BeamsEnabled end

				for _, p in ipairs(tower:GetChildren()) do
					if p.Name:find("LampPanel_") and p:IsA("BasePart") then
						p.Transparency = preset.LampTransparency
					end
				end
			end
		end
	end
end

-- Convenience helper to trigger goal or jackpot celebration
function FloodlightManager.TriggerEvent()
	FloodlightManager.SetMode("Event")
end

return FloodlightManager

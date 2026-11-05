--!strict
--[[
	StadiumLightingClient (LocalScript)
	Location: StarterPlayer/StarterPlayerScripts/StadiumLightingClient.client.luau

	Responsibility:
	- Client-side camera-facing lens flare calculations (throttled to 10 Hz).
	- Shared distance culling at 2 Hz (culls dynamic lights/beams > 250 studs).
	- Graphics quality detection (LOW, MEDIUM, HIGH) & auto mobile adaptation.
	- Desynchronized aviation obstruction beacon blinkers with random offsets.
	- Minigame illumination boost: illuminates the target goal floodlights locally.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera

type QualityPreset = "LOW" | "MEDIUM" | "HIGH"
local currentPreset: QualityPreset = "HIGH"

-- ============================================================================
-- 1. GRAPHICS QUALITY DETECTION
-- ============================================================================
local function detectQualityPreset(): QualityPreset
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if isMobile then
		return "MEDIUM"
	end

	local userSettings = UserSettings()
	local ok, val = pcall(function()
		return userSettings.GameSettings.SavedQualityLevel.Value
	end)

	if ok and typeof(val) == "number" then
		if val > 0 and val <= 3 then
			return "LOW"
		elseif val > 3 and val <= 7 then
			return "MEDIUM"
		elseif val > 7 then
			return "HIGH"
		end
	end

	return "HIGH"
end

currentPreset = detectQualityPreset()

-- ============================================================================
-- 2. TOWER CACHE & HELPERS
-- ============================================================================
type TowerData = {
	tower: Model,
	headFrame: BasePart,
	spot: SpotLight?,
	point: PointLight?,
	beam: Beam?,
	flareImg: ImageLabel?,
	groundGlowImgs: { ImageLabel },
	beacon: BasePart?,
	beaconLight: PointLight?,
	position: Vector3,
	lookVector: Vector3,
}

local cachedTowers: { TowerData } = {}

local function refreshTowers()
	table.clear(cachedTowers)

	local stadium = Workspace:FindFirstChild("Stadium")
	local lightsFolder = stadium and stadium:FindFirstChild("Lights")
	local towerModels = lightsFolder and lightsFolder:GetChildren() or CollectionService:GetTagged("StadiumFloodlightTower")

	for _, tower in ipairs(towerModels) do
		if tower:IsA("Model") then
			local hf = tower:FindFirstChild("HeadFrame") :: BasePart?
			if hf then
				local spot = tower:FindFirstChild("Floodlight_Spot", true) :: SpotLight?
				local point = tower:FindFirstChild("Floodlight_Point", true) :: PointLight?
				local beam = tower:FindFirstChild("Floodlight_Beam", true) :: Beam?
				local flare = tower:FindFirstChild("FlareImage", true) :: ImageLabel?
				local beacon = tower:FindFirstChild("AviationBeacon") :: BasePart?
				local beaconLight = beacon and beacon:FindFirstChild("Floodlight_BeaconLight") :: PointLight?

				local glowImgs: { ImageLabel } = {}
				for _, inst in ipairs(tower:GetDescendants()) do
					if inst:IsA("ImageLabel") and inst.Name == "GlowImage" then
						table.insert(glowImgs, inst)
					end
				end

				table.insert(cachedTowers, {
					tower = tower,
					headFrame = hf,
					spot = spot,
					point = point,
					beam = beam,
					flareImg = flare,
					groundGlowImgs = glowImgs,
					beacon = beacon,
					beaconLight = beaconLight,
					position = hf.Position,
					lookVector = hf.CFrame.LookVector,
				})
			end
		end
	end
end

refreshTowers()

-- Apply graphics preset rules
local function applyQualityPreset(preset: QualityPreset)
	currentPreset = preset
	for _, data in ipairs(cachedTowers) do
		if preset == "LOW" then
			if data.spot then data.spot.Enabled = false end
			if data.point then data.point.Enabled = false end
			if data.beam then data.beam.Enabled = false end
			if data.flareImg then data.flareImg.Visible = false end
		elseif preset == "MEDIUM" then
			if data.spot then
				data.spot.Enabled = true
				data.spot.Shadows = false
			end
			if data.point then data.point.Enabled = true end
			if data.beam then data.beam.Enabled = false end
			if data.flareImg then data.flareImg.Visible = true end
		elseif preset == "HIGH" then
			if data.spot then
				data.spot.Enabled = true
				data.spot.Shadows = (data.tower.Name == "Tower_Corner_NW" or data.tower.Name == "Tower_Corner_SE")
			end
			if data.point then data.point.Enabled = true end
			if data.beam then data.beam.Enabled = true end
			if data.flareImg then data.flareImg.Visible = true end
		end
	end
end

applyQualityPreset(currentPreset)

-- ============================================================================
-- 3. DISTANCE CULLING (2 Hz Loop - Shared)
-- ============================================================================
local CULL_DIST_SQ = 250 * 250

task.spawn(function()
	while true do
		task.wait(0.5) -- 2 Hz update rate
		local camPos = camera.CFrame.Position
		local lightsOn = workspace:GetAttribute("StadiumLightsOn") == true

		for _, data in ipairs(cachedTowers) do
			local distSq = (data.position - camPos).Dot(data.position - camPos)
			local isNear = distSq <= CULL_DIST_SQ

			if lightsOn and currentPreset ~= "LOW" then
				if data.spot then data.spot.Enabled = isNear end
				if data.point then data.point.Enabled = isNear end
				if data.beam and currentPreset == "HIGH" then data.beam.Enabled = isNear end
				if data.flareImg then data.flareImg.Visible = isNear end
			end
		end
	end
end)

-- ============================================================================
-- 4. CAMERA-FACING LENS FLARE (10 Hz Loop)
-- ============================================================================
task.spawn(function()
	while true do
		task.wait(0.1) -- 10 Hz throttled update rate
		local lightsOn = workspace:GetAttribute("StadiumLightsOn") == true
		if not lightsOn or currentPreset == "LOW" then
			for _, data in ipairs(cachedTowers) do
				if data.flareImg and data.flareImg.ImageTransparency ~= 1.0 then
					data.flareImg.ImageTransparency = 1.0
				end
			end
			continue
		end

		local camPos = camera.CFrame.Position
		local camLook = camera.CFrame.LookVector

		for _, data in ipairs(cachedTowers) do
			if data.flareImg and data.flareImg.Visible then
				local toLamp = data.position - camPos
				local dist = toLamp.Magnitude

				if dist <= 250 and dist > 1 then
					local dirToLamp = toLamp / dist
					-- Camera looks toward the lamp
					local camDot = camLook:Dot(dirToLamp)
					-- Lamp front face faces toward the camera
					local lampDot = data.lookVector:Dot(-dirToLamp)

					if camDot > 0.3 and lampDot > 0.1 then
						local intensity = math.clamp((camDot - 0.3) / 0.7, 0, 1) * math.clamp(lampDot, 0, 1)
						-- Fade between 0.3 (bright flare) and 1.0 (invisible)
						data.flareImg.ImageTransparency = 1.0 - (intensity * 0.7)
					else
						data.flareImg.ImageTransparency = 1.0
					end
				else
					data.flareImg.ImageTransparency = 1.0
				end
			end
		end
	end
end)

-- ============================================================================
-- 5. AVIATION BEACON DESYNCHRONIZED BLINKER
-- ============================================================================
for _, data in ipairs(cachedTowers) do
	if data.beacon then
		task.spawn(function()
			-- Desynchronize start phase per tower with a random delay
			task.wait(math.random() * 2.0)
			local beaconOn = false
			local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			while data.beacon and data.beacon.Parent do
				beaconOn = not beaconOn
				if beaconOn then
					data.beacon.Material = Enum.Material.Neon
					data.beacon.Transparency = 0.0
					if data.beaconLight then data.beaconLight.Brightness = 2.0 end
				else
					data.beacon.Material = Enum.Material.SmoothPlastic
					data.beacon.Transparency = 0.85
					if data.beaconLight then data.beaconLight.Brightness = 0.0 end
				end
				task.wait(1.0)
			end
		end)
	end
end

-- ============================================================================
-- 6. MINIGAME ILLUMINATION BOOST
-- ============================================================================
-- When local player enters target kick / shooting minigame, illuminate near goal
local function checkMinigameBoost()
	local inMinigame = localPlayer:GetAttribute("InMinigame") == true
	local targetGoal = localPlayer:GetAttribute("MinigameGoal") :: string?

	if inMinigame then
		local goalPos = if targetGoal == "East" then Vector3.new(82, 12, -39) else Vector3.new(-82, 12, -39)
		for _, data in ipairs(cachedTowers) do
			local distToGoal = (data.position - goalPos).Magnitude
			if distToGoal < 130 then
				-- Boost this tower client-side to full visibility
				if data.spot then
					data.spot.Enabled = true
					data.spot.Brightness = 7.0
				end
				for _, img in ipairs(data.groundGlowImgs) do
					img.ImageTransparency = 0.75
				end
			end
		end
	else
		-- Restore default mode
		local lightsOn = workspace:GetAttribute("StadiumLightsOn") == true
		if not lightsOn then
			for _, data in ipairs(cachedTowers) do
				if data.spot then data.spot.Brightness = 0.0 end
				for _, img in ipairs(data.groundGlowImgs) do
					img.ImageTransparency = 1.0
				end
			end
		end
	end
end

localPlayer:GetAttributeChangedSignal("InMinigame"):Connect(checkMinigameBoost)
localPlayer:GetAttributeChangedSignal("MinigameGoal"):Connect(checkMinigameBoost)

-- ============================================================================
-- 7. CLIENT COMMAND TOGGLE (/lights quality low|medium|high)
-- ============================================================================
localPlayer.Chatted:Connect(function(msg)
	local tokens = string.split(string.lower(string.gsub(msg, "^%s*(.-)%s*$", "%1")), " ")
	if tokens[1] == "/lights" and tokens[2] == "quality" then
		local q = string.upper(tokens[3] or "")
		if q == "LOW" or q == "MEDIUM" or q == "HIGH" then
			applyQualityPreset(q :: QualityPreset)
			print(string.format("[StadiumLightingClient] Quality preset changed to %s", q))
		end
	end
end)

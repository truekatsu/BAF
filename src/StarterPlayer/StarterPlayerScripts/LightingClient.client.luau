--!strict
--[[
	LightingClient
	Responsibility: Client-side smooth lighting transitions and celebration FX for stadium floodlights:
	- Smooth TweenService transitions (2.5s) between Day and Night modes.
	- Interpolates game.Lighting ClockTime, Brightness, OutdoorAmbient, Atmosphere, Bloom, and ColorCorrection.
	- Interpolates floodlight SpotLights, PointLights, lamp panel Neon transparency, and light cone Beams.
	- Blinking red aviation obstruction beacons at tower apexes.
	- 3-second celebration pulse on "Event" mode (goal or jackpot) with alternating royal blue & gold flashes.

	Location: StarterPlayer/StarterPlayerScripts/LightingClient.client.luau
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local TWEEN_TIME = 2.5
local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Lighting effect handles
local atmosphere = Lighting:FindFirstChildWhichIsA("Atmosphere")
local bloom = Lighting:FindFirstChildWhichIsA("BloomEffect")
local colorCorrection = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")

local function getLightsFolder(): Folder?
	local stadium = Workspace:FindFirstChild("Stadium")
	return stadium and stadium:FindFirstChild("Lights") :: Folder?
end

-- ============================================================================
-- 1. MODE TRANSITION LOGIC
-- ============================================================================

local function applyMode(mode: string, prevMode: string?)
	local lightsFolder = getLightsFolder()

	if mode == "Day" then
		-- Global Lighting tweens
		TweenService:Create(Lighting, tweenInfo, {
			ClockTime = 14.2,
			Brightness = 2.2,
			OutdoorAmbient = Color3.fromRGB(115, 125, 140),
			Ambient = Color3.fromRGB(35, 40, 48),
		}):Play()

		if atmosphere then
			TweenService:Create(atmosphere, tweenInfo, { Density = 0.25 }):Play()
		end
		if bloom then
			TweenService:Create(bloom, tweenInfo, { Intensity = 0.20, Threshold = 1.8, Size = 20 }):Play()
		end
		if colorCorrection then
			TweenService:Create(colorCorrection, tweenInfo, {
				TintColor = Color3.fromRGB(255, 255, 255),
				Saturation = 0.08,
			}):Play()
		end

		-- Floodlight tower tweens
		if lightsFolder then
			for _, tower in ipairs(lightsFolder:GetChildren()) do
				local spot = tower:FindFirstChild("FloodSpot", true) :: SpotLight?
				if spot then
					TweenService:Create(spot, tweenInfo, { Brightness = 0.0 }):Play()
				end

				local point = tower:FindFirstChild("FloodPoint", true) :: PointLight?
				if point then
					TweenService:Create(point, tweenInfo, { Brightness = 0.0 }):Play()
				end

				local beam = tower:FindFirstChild("LightConeBeam", true) :: Beam?
				if beam then
					beam.Enabled = false
				end

				for _, p in ipairs(tower:GetChildren()) do
					if p.Name:find("LampPanel_") and p:IsA("BasePart") then
						TweenService:Create(p, tweenInfo, {
							Transparency = 0.5,
							Color = Color3.fromRGB(255, 248, 230),
						}):Play()
					end
				end
			end
		end

	elseif mode == "Night" then
		-- Global Lighting tweens
		TweenService:Create(Lighting, tweenInfo, {
			ClockTime = 20.0,
			Brightness = 0.2,
			OutdoorAmbient = Color3.fromRGB(24, 28, 42),
			Ambient = Color3.fromRGB(10, 12, 18),
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
			TweenService:Create(bloom, tweenInfo, { Intensity = 0.25, Threshold = 1.8, Size = 22 }):Play()
		end
		if colorCorrection then
			TweenService:Create(colorCorrection, tweenInfo, {
				TintColor = Color3.fromRGB(245, 248, 255),
				Saturation = 0.05,
			}):Play()
		end

		-- Floodlight tower tweens
		if lightsFolder then
			for _, tower in ipairs(lightsFolder:GetChildren()) do
				local spot = tower:FindFirstChild("FloodSpot", true) :: SpotLight?
				if spot then
					TweenService:Create(spot, tweenInfo, { Brightness = 1.8 }):Play()
				end

				local point = tower:FindFirstChild("FloodPoint", true) :: PointLight?
				if point then
					TweenService:Create(point, tweenInfo, { Brightness = 1.2 }):Play()
				end

				local beam = tower:FindFirstChild("LightConeBeam", true) :: Beam?
				if beam then
					beam.Enabled = true
				end

				for _, p in ipairs(tower:GetChildren()) do
					if p.Name:find("LampPanel_") and p:IsA("BasePart") then
						TweenService:Create(p, tweenInfo, {
							Transparency = 0.0,
							Color = Color3.fromRGB(255, 248, 230),
						}):Play()
					end
				end
			end
		end

	elseif mode == "Event" then
		-- Rapid 3-second celebration pulses in Blue (#1F4FD8) and Gold (#F5B82E)
		local blue = Color3.fromHex("#1F4FD8")
		local gold = Color3.fromHex("#F5B82E")
		local pulseInfo = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 4, true)

		if colorCorrection then
			TweenService:Create(colorCorrection, pulseInfo, {
				TintColor = Color3.fromRGB(255, 230, 160),
				Saturation = 0.40,
			}):Play()
		end

		if lightsFolder then
			for _, tower in ipairs(lightsFolder:GetChildren()) do
				local spot = tower:FindFirstChild("FloodSpot", true) :: SpotLight?
				if spot then
					spot.Brightness = 2.4
					TweenService:Create(spot, pulseInfo, { Color = gold }):Play()
				end

				for idx, p in ipairs(tower:GetChildren()) do
					if p.Name:find("LampPanel_") and p:IsA("BasePart") then
						local targetColor = (idx % 2 == 0) and blue or gold
						p.Transparency = 0.0
						TweenService:Create(p, pulseInfo, { Color = targetColor }):Play()
					end
				end
			end
		end
	end
end

-- ============================================================================
-- 2. AVIATION BEACON BLINKER
-- ============================================================================
task.spawn(function()
	local blinkOn = true
	while true do
		task.wait(1.0)
		blinkOn = not blinkOn
		local lightsFolder = getLightsFolder()
		if lightsFolder then
			for _, tower in ipairs(lightsFolder:GetChildren()) do
				local beacon = tower:FindFirstChild("AviationBeacon") :: BasePart?
				if beacon then
					beacon.Transparency = blinkOn and 0.0 or 0.85
				end
			end
		end
	end
end)

-- ============================================================================
-- 3. NETWORK LISTENER
-- ============================================================================
local remote = ReplicatedStorage:WaitForChild("LightingModeChanged", 10) :: RemoteEvent?
if remote then
	remote.OnClientEvent:Connect(function(newMode: string, prevMode: string?)
		applyMode(newMode, prevMode)
	end)
end

-- Initial sync from ReplicatedStorage.LightingMode
local initialModeVal = ReplicatedStorage:WaitForChild("LightingMode", 5) :: StringValue?
if initialModeVal then
	applyMode(initialModeVal.Value)
	initialModeVal.Changed:Connect(function(newVal)
		applyMode(newVal)
	end)
end

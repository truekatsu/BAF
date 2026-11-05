--!strict
--[[
	LobbyFX (Client)
	Responsibility: Client-side Atmosphere FX for Stadium Lobby (TASK P8):
	- Feature A: Ambient confetti every 45-90s from 3 random rim emitters (120 particles, disabled on low graphics)
	- Feature B: Crowd wave every 60s (travelling Mexican wave light band across 8 sectors)
	- Feature C: Win celebration on Remotes.MatchResult (3 firework bursts 1.2s apart, smoke puff, Jumbotron confetti within 120 studs)
	- Feature D: Stadium ambience audio (SFX_CrowdAmbient loop, random 20-40s one-shots, in-match low-pass muffle)
	Acceptance: <= 3 active emitters simultaneously, all features togglable in AtmosphereConfig
	Location: StarterPlayer/StarterPlayerScripts/LobbyFX.client.luau
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserSettings = UserSettings
local Workspace = game:GetService("Workspace")

local FXFolder = ReplicatedStorage:WaitForChild("FX", 10)
local AtmosphereConfig = if FXFolder and FXFolder:FindFirstChild("AtmosphereConfig")
	then require(FXFolder.AtmosphereConfig)
	else require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AtmosphereConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local flags = AtmosphereConfig.FLAGS

-- Cache tables
local rimEmitters: { ParticleEmitter } = {}
local sectorWaveOverlays: { [number]: { Frame } } = {}
local tableLastCelebration: { [Model]: number } = {}

-- Helper: Low graphics check
local function isLowQuality(): boolean
	local ok, setting = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel
	end)
	if ok and setting and typeof(setting) == "EnumItem" then
		return setting.Value <= AtmosphereConfig.AMBIENT_CONFETTI.LOW_GRAPHICS_THRESHOLD
	end
	return false
end

-- 1. Setup Workspace.Lobby.FX hierarchy
local function setupLobbyFXHierarchy(): Folder
	local lobby = Workspace:WaitForChild("Lobby", 10) :: Folder?
	if not lobby then
		lobby = Instance.new("Folder")
		lobby.Name = "Lobby"
		lobby.Parent = Workspace
	end

	local fx = lobby:FindFirstChild("FX") :: Folder?
	if not fx then
		fx = Instance.new("Folder")
		fx.Name = "FX"
		fx.Parent = lobby
	end

	return fx
end

-- 2. Build 8 Stand Rim Emitters (Feature A)
local function setupRimEmitters(fx: Folder)
	local rimFolder = fx:FindFirstChild("RimEmitters")
	if not rimFolder then
		rimFolder = Instance.new("Folder")
		rimFolder.Name = "RimEmitters"
		rimFolder.Parent = fx
	end

	table.clear(rimEmitters)

	local confColors = AtmosphereConfig.AMBIENT_CONFETTI.COLORS
	local colorKeypoints: { ColorSequenceKeypoint } = {}
	for i, c in ipairs(confColors) do
		local t = (i - 1) / (#confColors - 1)
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(t, c))
	end
	local colorSeq = ColorSequence.new(colorKeypoints)

	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local x = 115.0 * math.cos(angle)
		local z = -43.0 + 115.0 * math.sin(angle)
		local emitterName = `RimEmitter_{i}`

		local part = rimFolder:FindFirstChild(emitterName) :: Part?
		if not part then
			part = Instance.new("Part")
			part.Name = emitterName
			part.Size = Vector3.new(1, 1, 1)
			part.CFrame = CFrame.new(x, 14.0, z)
			part.Transparency = 1
			part.CanCollide = false
			part.Anchored = true
			part.Parent = rimFolder
		end

		local pe = part:FindFirstChild("Confetti") :: ParticleEmitter?
		if not pe then
			pe = Instance.new("ParticleEmitter")
			pe.Name = "Confetti"
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Color = colorSeq
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0.3),
			})
			pe.Lifetime = NumberRange.new(2.0, 3.5)
			pe.Speed = NumberRange.new(20, 35)
			pe.SpreadAngle = Vector2.new(45, 45)
			pe.Acceleration = Vector3.new(0, -22, 0)
			pe.RotSpeed = NumberRange.new(-180, 180)
			pe.Rate = 0
			pe.Enabled = false
			pe.Parent = part
		end

		table.insert(rimEmitters, pe)
	end
end

-- 3. Setup Crowd Wave Overlays on CrowdStrips (Feature B)
local function setupCrowdWaveOverlays()
	local lobby = Workspace:FindFirstChild("Lobby")
	local bowl = lobby and (lobby:FindFirstChild("StadiumBowl") or (lobby:FindFirstChild("Stands") and lobby.Stands:FindFirstChild("StadiumBowl")))
	if not bowl then return end

	for i = 0, 7 do
		sectorWaveOverlays[i] = {}
	end

	for _, desc in ipairs(bowl:GetChildren()) do
		if desc:IsA("BasePart") and desc.Name:find("CrowdStrip") then
			local p = desc.Position
			local angle = math.deg(math.atan2(p.Z - (-43), p.X))
			if angle < 0 then angle = angle + 360 end
			local octant = math.floor((angle + 22.5) / 45) % 8

			local cg = desc:FindFirstChildWhichIsA("SurfaceGui")
			if cg then
				local overlay = cg:FindFirstChild("WaveOverlay") :: Frame?
				if not overlay then
					overlay = Instance.new("Frame")
					overlay.Name = "WaveOverlay"
					overlay.Size = UDim2.fromScale(1, 1)
					overlay.BackgroundColor3 = AtmosphereConfig.CROWD_WAVE.HIGHLIGHT_COLOR
					overlay.BackgroundTransparency = 1
					overlay.BorderSizePixel = 0
					overlay.ZIndex = 10
					overlay.Parent = cg
				end
				table.insert(sectorWaveOverlays[octant], overlay)
			end
		end
	end
end

-- 4. Feature A: Ambient Confetti Routine
local function startAmbientConfettiLoop()
	if not flags.ENABLE_AMBIENT_CONFETTI then return end

	task.spawn(function()
		local conf = AtmosphereConfig.AMBIENT_CONFETTI
		while true do
			local waitSec = math.random(conf.MIN_INTERVAL_SEC, conf.MAX_INTERVAL_SEC)
			task.wait(waitSec)

			if not isLowQuality() and #rimEmitters >= conf.ACTIVE_EMITTERS_COUNT then
				local chosen = {}
				local count = 0
				while count < conf.ACTIVE_EMITTERS_COUNT do
					local idx = math.random(1, #rimEmitters)
					if not chosen[idx] then
						chosen[idx] = true
						count = count + 1
						local pe = rimEmitters[idx]
						if pe and pe.Parent then
							pe:Emit(40) -- 3 emitters * 40 = 120 particles total
						end
					end
				end
			end
		end
	end)
end

-- 5. Feature B: Crowd Wave Routine (Mexican wave moving light band)
local function startCrowdWaveLoop()
	if not flags.ENABLE_CROWD_WAVE then return end

	task.spawn(function()
		local conf = AtmosphereConfig.CROWD_WAVE
		local tweenInfoIn = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tweenInfoOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		while true do
			task.wait(conf.INTERVAL_SEC)

			-- Mexican wave sweeps around octants 0 through 7
			for octant = 0, conf.SECTORS_COUNT - 1 do
				local overlays = sectorWaveOverlays[octant]
				if overlays and #overlays > 0 then
					for _, ov in ipairs(overlays) do
						local tIn = TweenService:Create(ov, tweenInfoIn, { BackgroundTransparency = conf.PEAK_TRANSPARENCY })
						tIn:Play()
						tIn.Completed:Connect(function()
							local tOut = TweenService:Create(ov, tweenInfoOut, { BackgroundTransparency = 1.0 })
							tOut:Play()
						end)
					end
				end
				task.wait(conf.WAVE_DURATION_SEC / conf.SECTORS_COUNT)
			end
		end
	end)
end

-- 6. Feature C: Win Celebration Handler
local function setupWinCelebration()
	if not flags.ENABLE_WIN_CELEBRATION then return end

	local function findTableForWinner(winnerUid: number, winnerName: string?): Model?
		local searchFolders = {
			Workspace:FindFirstChild("Tables"),
			Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Tables"),
			Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("VIP") and Workspace.Lobby.VIP:FindFirstChild("Tables"),
		}

		for _, folder in ipairs(searchFolders) do
			if folder then
				for _, t in ipairs(folder:GetChildren()) do
					if t:IsA("Model") then
						local pA = t:GetAttribute("PlayerA")
						local pB = t:GetAttribute("PlayerB")
						if (winnerName and (pA == winnerName or pB == winnerName))
							or (winnerUid and (pA == winnerUid or pB == winnerUid))
							or t:GetAttribute("InMatch") == true then
							return t
						end
					end
				end
			end
		end

		local defaultFolder = (Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Tables")) or Workspace:FindFirstChild("Tables")
		return defaultFolder and defaultFolder:FindFirstChild("Table_1") :: Model?
	end

	Remotes.MatchResult.OnClientEvent:Connect(function(dataOrUid, maybeScore)
		local winnerUid = 0
		local winnerName = ""
		if typeof(dataOrUid) == "table" then
			winnerUid = dataOrUid.winnerUserId or 0
			winnerName = dataOrUid.winnerName or ""
		elseif typeof(dataOrUid) == "number" then
			winnerUid = dataOrUid
		end

		local winTable = findTableForWinner(winnerUid, winnerName)
		if not winTable then return end

		local now = os.clock()
		local lastCelebration = tableLastCelebration[winTable] or 0
		if now - lastCelebration < AtmosphereConfig.WIN_CELEBRATION.TABLE_COOLDOWN_SEC then
			return
		end
		tableLastCelebration[winTable] = now

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local playerPos = root and root.Position or Vector3.new(0, 5, -42)
		local tablePos = winTable:GetPivot().Position

		-- 120 stud proximity check
		if (tablePos - playerPos).Magnitude <= AtmosphereConfig.WIN_CELEBRATION.MAX_DISTANCE_STUDS then
			local teamCol = AtmosphereConfig.WIN_CELEBRATION.TEAM_COLORS.Gold
			if winnerUid > 0 and winnerUid % 2 == 1 then
				teamCol = AtmosphereConfig.WIN_CELEBRATION.TEAM_COLORS.Blue
			else
				teamCol = AtmosphereConfig.WIN_CELEBRATION.TEAM_COLORS.Red
			end

			-- Firework bursts (3 bursts, 1.2s apart, <= 180 particles each)
			task.spawn(function()
				for burst = 1, AtmosphereConfig.WIN_CELEBRATION.BURST_COUNT do
					local fwPart = Instance.new("Part")
					fwPart.Name = "FireworkBurst"
					fwPart.Size = Vector3.new(0.5, 0.5, 0.5)
					fwPart.CFrame = CFrame.new(tablePos + Vector3.new(math.random(-2, 2), 6 + burst * 2, math.random(-2, 2)))
					fwPart.Transparency = 1
					fwPart.CanCollide = false
					fwPart.Anchored = true
					fwPart.Parent = Workspace

					local pe = Instance.new("ParticleEmitter")
					pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
					pe.Color = ColorSequence.new(teamCol, Color3.new(1, 1, 1))
					pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.2) })
					pe.Speed = NumberRange.new(20, 35)
					pe.SpreadAngle = Vector2.new(80, 80)
					pe.Acceleration = Vector3.new(0, -18, 0)
					pe.Lifetime = NumberRange.new(1.0, 1.6)
					pe.Rate = 0
					pe.Parent = fwPart

					pe:Emit(60) -- Max 60 particles * 3 bursts = 180 total (<= 200 budget)
					task.delay(2.5, function()
						if fwPart and fwPart.Parent then fwPart:Destroy() end
					end)

					task.wait(AtmosphereConfig.WIN_CELEBRATION.BURST_INTERVAL_SEC)
				end
			end)

			-- Short smoke puff with team kit colour
			task.spawn(function()
				local smokePart = Instance.new("Part")
				smokePart.Name = "WinSmoke"
				smokePart.Size = Vector3.new(0.5, 0.5, 0.5)
				smokePart.CFrame = CFrame.new(tablePos + Vector3.new(0, 3, 0))
				smokePart.Transparency = 1
				smokePart.CanCollide = false
				smokePart.Anchored = true
				smokePart.Parent = Workspace

				local smoke = Instance.new("Smoke")
				smoke.Color = teamCol
				smoke.Size = 4.0
				smoke.RiseVelocity = 3.0
				smoke.Opacity = 0.5
				smoke.Parent = smokePart

				task.delay(1.5, function()
					smoke.Enabled = false
					task.wait(1.0)
					if smokePart and smokePart.Parent then smokePart:Destroy() end
				end)
			end)
		end

		-- Confetti burst at Jumbotron
		local jumbotron = Workspace:FindFirstChild("Lobby") and Workspace.Lobby:FindFirstChild("Jumbotron")
		local jumbotronPart = jumbotron and (jumbotron:FindFirstChild("ScreenFrame") or jumbotron:FindFirstChildWhichIsA("BasePart"))
		if jumbotronPart and (jumbotronPart.Position - playerPos).Magnitude <= AtmosphereConfig.WIN_CELEBRATION.MAX_DISTANCE_STUDS then
			local jConfetti = Instance.new("ParticleEmitter")
			jConfetti.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			jConfetti.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#FFD21F")),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("#EF4444")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#3B82F6")),
			})
			jConfetti.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2) })
			jConfetti.Speed = NumberRange.new(15, 25)
			jConfetti.SpreadAngle = Vector2.new(60, 60)
			jConfetti.Rate = 0
			jConfetti.Parent = jumbotronPart
			jConfetti:Emit(80)
			task.delay(2.5, function()
				if jConfetti and jConfetti.Parent then jConfetti:Destroy() end
			end)
		end
	end)
end

-- 7. Feature D: Stadium Ambience Audio Routine
local function setupStadiumAmbienceAudio()
	if not flags.ENABLE_AMBIENCE_AUDIO then return end

	local audioConf = AtmosphereConfig.AUDIO

	-- Setup SoundGroup
	local soundGroup = SoundService:FindFirstChild("LobbyAmbience") :: SoundGroup?
	if not soundGroup then
		soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = "LobbyAmbience"
		soundGroup.Volume = audioConf.MASTER_VOLUME
		soundGroup.Parent = SoundService
	end

	-- Setup Equalizer (Low-pass muffle during matches)
	local muffle = soundGroup:FindFirstChild("MatchMuffle") :: EqualizerSoundEffect?
	if not muffle then
		muffle = Instance.new("EqualizerSoundEffect")
		muffle.Name = "MatchMuffle"
		muffle.LowGain = audioConf.MUFFLE_EQUALIZER.LowGain
		muffle.MidGain = audioConf.MUFFLE_EQUALIZER.MidGain
		muffle.HighGain = audioConf.MUFFLE_EQUALIZER.HighGain
		muffle.Priority = 0
		muffle.Enabled = false
		muffle.Parent = soundGroup
	end

	-- Ambient Looping Sound
	local ambientSound = soundGroup:FindFirstChild(audioConf.AMBIENT_LOOP.name) :: Sound?
	if not ambientSound then
		ambientSound = Instance.new("Sound")
		ambientSound.Name = audioConf.AMBIENT_LOOP.name
		ambientSound.SoundId = audioConf.AMBIENT_LOOP.id
		ambientSound.Volume = audioConf.AMBIENT_LOOP.volume
		ambientSound.Looped = audioConf.AMBIENT_LOOP.looped
		ambientSound.SoundGroup = soundGroup
		ambientSound.Parent = soundGroup
		pcall(function() ambientSound:Play() end)
	end

	-- Random One-Shots Routine (every 20-40s)
	task.spawn(function()
		local shots = audioConf.ONE_SHOTS
		while true do
			local interval = math.random(audioConf.ONE_SHOT_MIN_INTERVAL_SEC, audioConf.ONE_SHOT_MAX_INTERVAL_SEC)
			task.wait(interval)

			if #shots > 0 then
				local def = shots[math.random(1, #shots)]
				local s = Instance.new("Sound")
				s.Name = def.name
				s.SoundId = def.id
				s.Volume = def.volume
				s.SoundGroup = soundGroup
				s.Parent = soundGroup
				s.Ended:Connect(function()
					s:Destroy()
				end)
				pcall(function() s:Play() end)
				task.delay(8.0, function()
					if s and s.Parent then s:Destroy() end
				end)
			end
		end
	end)

	-- Muffle Monitor (muffles ambient audio when in match)
	local function updateMuffleState()
		local inMatch = player:GetAttribute("InMatch") == true
		if muffle then
			muffle.Enabled = inMatch
		end
	end

	player:GetAttributeChangedSignal("InMatch"):Connect(updateMuffleState)
	updateMuffleState()
end

-- Initialize LobbyFX
local function initLobbyFX()
	local fxHierarchy = setupLobbyFXHierarchy()
	setupRimEmitters(fxHierarchy)
	setupCrowdWaveOverlays()

	startAmbientConfettiLoop()
	startCrowdWaveLoop()
	setupWinCelebration()
	setupStadiumAmbienceAudio()
end

task.defer(initLobbyFX)

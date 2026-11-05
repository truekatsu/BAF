--!strict
--[[
	PlayerTunnelCameraClient (Client)
	Responsibility: Drives the 3-second gentle over-the-shoulder entrance cinematic when a player
	spawns out of the tunnel looking along the central walkway. Skips if rejoining within 60s.
	Preserves match camera system integrity.
	Loop step: arrival experience | cinematic immersion
	Location: StarterPlayer/StarterPlayerScripts/Client/PlayerTunnelCameraClient.client.luau
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("PlayerTunnelConfig"))

local lastSpawnTime = 0

local function playSpawnRoar()
	if not Config.SPAWN_ROAR_SOUND_ID or Config.SPAWN_ROAR_SOUND_ID == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "SFX_CrowdRoar_Spawn"
	sound.SoundId = Config.SPAWN_ROAR_SOUND_ID
	sound.Volume = 0.5
	sound.Parent = Workspace
	pcall(function()
		sound:Play()
	end)
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

local function onCharacterSpawned(character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local hum = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hrp or not hum then
		return
	end

	-- Only trigger if spawning near the tunnel (South end Z > 20)
	if hrp.Position.Z < 18 then
		return
	end

	local now = os.clock()
	if lastSpawnTime > 0 and (now - lastSpawnTime) < Config.REJOIN_COOLDOWN_SEC then
		return
	end
	lastSpawnTime = now

	-- Do not interfere if player is sitting at a match table
	if hum.SeatPart ~= nil then
		return
	end

	playSpawnRoar()

	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end

	-- Start CFrame: over-the-shoulder looking forward along the walkway towards pitch center (Z = -42)
	local charPos = hrp.Position
	local startEye = charPos + Config.CAM_OFFSET
	local lookTarget = charPos + Vector3.new(0, 1.2, -Config.CAM_LOOK_FORWARD_STUDS)
	local startCF = CFrame.lookAt(startEye, lookTarget)

	-- End CFrame: subtle forward dolly
	local endEye = charPos + Vector3.new(1.2, 3.0, 4.0)
	local endLookTarget = charPos + Vector3.new(0, 1.0, -Config.CAM_LOOK_FORWARD_STUDS - 10)
	local endCF = CFrame.lookAt(endEye, endLookTarget)

	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = startCF

	local tween = TweenService:Create(
		cam,
		TweenInfo.new(Config.CAMERA_DURATION_SEC, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ CFrame = endCF }
	)
	tween:Play()

	task.delay(Config.CAMERA_DURATION_SEC, function()
		-- Return to Custom only if another script (like match camera) hasn't taken over
		if cam and cam.CameraType == Enum.CameraType.Scriptable and hum.SeatPart == nil then
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = hum
		end
	end)
end

if localPlayer.Character then
	task.spawn(onCharacterSpawned, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(onCharacterSpawned)

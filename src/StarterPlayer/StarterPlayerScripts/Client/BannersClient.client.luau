--!strict
--[[
	BannersClient (Client)
	Responsibility: Client-side animations and LOD for stadium banners, ads, and flags:
	- Rotates generic ads on 24 perimeter boards every 8s (offset per board)
	- Animates gentle wind sway on 30 stand flags (+/- 6 deg, 0.3 Hz)
	- Pauses animations when player is farther than 150 studs (Client LOD)
	Loop step: live lobby atmosphere | visual immersion | performance
	Location: StarterPlayer/StarterPlayerScripts/Client/BannersClient.client.luau
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BannersConfig = require(Shared:WaitForChild("BannersConfig"))

local player = Players.LocalPlayer

local function initBannersClient()
	local lobby = Workspace:WaitForChild("Lobby", 10)
	if not lobby then return end

	local decor = lobby:WaitForChild("Decor", 10)
	local banners = decor and decor:WaitForChild("Banners", 10)
	if not banners then return end

	local adBoards = banners:WaitForChild("AdBoards", 10)
	local flagsFolder = banners:WaitForChild("Flags", 10)

	-- 1. Cache flag cloth parts
	local flagParts: { { part: BasePart, baseCf: CFrame, phase: number } } = {}
	if flagsFolder then
		for _, child in ipairs(flagsFolder:GetChildren()) do
			if child:IsA("BasePart") and child.Name:find("Cloth") then
				local baseCf = child:GetAttribute("BaseCFrame") :: CFrame? or child.CFrame
				local phase = (child:GetAttribute("Phase") :: number?) or 0
				table.insert(flagParts, {
					part = child,
					baseCf = baseCf,
					phase = phase,
				})
			end
		end
	end

	-- 2. Rotating Ads Timer Loop (every 8s, offset per board)
	task.spawn(function()
		local ads = BannersConfig.ADS
		local adCycle = 0

		while banners and banners.Parent do
			task.wait(BannersConfig.AD_ROTATION_SEC)
			adCycle = adCycle + 1

			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local playerPos = root and root.Position or Vector3.new(0, 5, -42)

			if adBoards then
				for i, board in ipairs(adBoards:GetChildren()) do
					if board:IsA("BasePart") then
						local dist = (board.Position - playerPos).Magnitude
						if dist <= BannersConfig.LOD_MAX_DISTANCE then
							local adIdx = ((adCycle + i - 1) % #ads) + 1
							local adDef = ads[adIdx]
							board.Color = adDef.bgColor

							local sg = board:FindFirstChildWhichIsA("SurfaceGui")
							if sg then
								local titleLbl = sg:FindFirstChild("TitleLabel") :: TextLabel?
								local tagLbl = sg:FindFirstChild("TaglineLabel") :: TextLabel?
								if titleLbl then
									titleLbl.Text = adDef.title
									titleLbl.TextColor3 = adDef.textColor
								end
								if tagLbl then
									tagLbl.Text = adDef.tagline
								end
							end
						end
					end
				end
			end
		end
	end)

	-- 3. Flag Wind Sway Loop (0.3 Hz, +/- 6 deg, throttled LOD)
	local swayRad = math.rad(BannersConfig.WIND_SWAY_DEG)
	local freq = BannersConfig.WIND_SWAY_FREQ_HZ * math.pi * 2

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local playerPos = root and root.Position or Vector3.new(0, 5, -42)

		local t = os.clock()
		for _, item in ipairs(flagParts) do
			if item.part and item.part.Parent then
				local dist = (item.part.Position - playerPos).Magnitude
				if dist <= BannersConfig.LOD_MAX_DISTANCE then
					local angle = math.sin(t * freq + item.phase) * swayRad
					item.part.CFrame = item.baseCf * CFrame.Angles(0, angle, 0)
				end
			end
		end
	end)
end

task.spawn(initBannersClient)

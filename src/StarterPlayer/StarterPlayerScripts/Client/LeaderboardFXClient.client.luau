--!strict
--[[
	LeaderboardFXClient (Client)
	Responsibility: Subtle client-side idle animations for the stylized football leaderboards:
	- Gentle breathing glow pulse on the golden trophy star emblem & spotlights
	- Subtle trophy oscillation / idle bobbing
	- Distance and low-graphics throttling for mobile performance
	Location: StarterPlayer/StarterPlayerScripts/Client/LeaderboardFXClient.client.luau
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MAX_ANIM_DISTANCE = 160.0

local function initFX()
	local lobby = Workspace:WaitForChild("Lobby", 15) :: Instance?
	if not lobby then return end

	local lbFolder = lobby:WaitForChild("Leaderboards", 15) :: Instance?
	if not lbFolder then return end

	-- Collect trophy cups and star emblems
	type TrophyFX = {
		cup: Part,
		baseCF: CFrame,
		star: Part?,
	}
	local fxItems: { TrophyFX } = {}

	for _, board in lbFolder:GetChildren() do
		local trophy = board:FindFirstChild("TrophyWithWreath", true)
		if trophy then
			local cup = trophy:FindFirstChild("Cup") :: Part?
			local star = trophy:FindFirstChild("StarEmblem") :: Part?
			if cup and cup:IsA("Part") then
				table.insert(fxItems, {
					cup = cup,
					baseCF = cup.CFrame,
					star = if star and star:IsA("Part") then star else nil,
				})
			end
		end
	end

	if #fxItems == 0 then return end

	-- Subtle idle animation loop
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t = t + dt
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local camPos = hrp and hrp.Position or Workspace.CurrentCamera.CFrame.Position

		for _, item in ipairs(fxItems) do
			local dist = (item.cup.Position - camPos).Magnitude
			if dist <= MAX_ANIM_DISTANCE then
				-- Gentle yaw oscillation (+- 5 degrees) & vertical floating (+- 0.15 studs)
				local rotY = math.sin(t * 1.4) * math.rad(5.0)
				local floatY = math.sin(t * 2.0) * 0.12
				item.cup.CFrame = item.baseCF * CFrame.new(0, floatY, 0) * CFrame.Angles(0, rotY, 0)

				-- Subtle star pulse
				if item.star then
					item.star.Transparency = 0.1 + math.abs(math.sin(t * 2.5)) * 0.25
				end
			end
		end
	end)
end

task.spawn(initFX)

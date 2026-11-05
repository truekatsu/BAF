--!strict
--[[
	CenterHubClient (Client)
	Responsibility: Smooth client-side 20 deg/sec rotation of the CenterHub pedestal & statue.
	Runs locally on RenderStepped for buttery 60 FPS rotation without server network load.
	Location: StarterPlayer/StarterPlayerScripts/Client/CenterHubClient.client.luau
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CenterHubConfig"))

local speedRadPerSec = math.rad(Config.PEDESTAL.RotationSpeedDegPerSec or 20)

local targetPedestal: Model? = nil

local function getPedestal(): Model?
	if targetPedestal and targetPedestal.Parent then
		return targetPedestal
	end
	local lobby = Workspace:FindFirstChild("Lobby")
	if not lobby then
		return nil
	end
	local hub = lobby:FindFirstChild("CenterHub") or lobby:FindFirstChild("Hub")
	if not hub then
		return nil
	end
	local ped = hub:FindFirstChild("RotatingPedestal")
	if ped and ped:IsA("Model") and ped.PrimaryPart then
		targetPedestal = ped
		return ped
	end
	return nil
end

RunService.RenderStepped:Connect(function(dt: number)
	local ped = getPedestal()
	if not ped or not ped.PrimaryPart then
		return
	end

	local rotAngle = speedRadPerSec * dt
	local currentCF = ped:GetPivot()
	ped:PivotTo(currentCF * CFrame.Angles(0, rotAngle, 0))
end)

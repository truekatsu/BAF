--!strict
--[[
	Main (Server)
	Responsibility: Run startup self-checks, ensure 3D footballer models exist, and initialize ProfileService, MatchService, and LobbyService.
	Loop step: n/a (bootstrap)
	Location: ServerScriptService/Server/Main (Script)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SelfTest = require(Shared:WaitForChild("SelfTest"))
local FootballerModelBuilder = require(Shared:WaitForChild("FootballerModelBuilder"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local LeaderboardService = require(script.Parent:WaitForChild("LeaderboardService"))
local MatchService = require(script.Parent:WaitForChild("MatchService"))
local LobbyService = require(script.Parent:WaitForChild("LobbyService"))

local testOk, testErr = pcall(SelfTest.run)
if not testOk then
	warn("[SelfTest] Diagnostic failed:", testErr)
end
FootballerModelBuilder.ensureAllModels()
LeaderboardService.init()
ProfileService.init()
MatchService.init()
LobbyService.init()

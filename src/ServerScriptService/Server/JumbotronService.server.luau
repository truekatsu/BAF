--!strict
--[[
	JumbotronService (Server)
	Responsibility: Manages the South end Stadium Jumbotron:
	- Maintains the 10-minute skin rotation timer and event countdowns synced via workspace:GetServerTimeNow()
	- Caches social proof data (Latest Winner, Top Player Today, Top Cash Today, Rarest Pull)
	- Ensures 3D model and SurfaceGui on the North stand with Option A roof truss mounts
	Location: ServerScriptService/Server/JumbotronService.server.luau
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JumbotronConfig = require(Shared:WaitForChild("JumbotronConfig"))
local LeaderboardBuilder = require(Shared:WaitForChild("LeaderboardBuilder"))
local Remotes = require(Shared:WaitForChild("Remotes"))

-- 1. Initialize ReplicatedStorage.Config
local configFolder = ReplicatedStorage:FindFirstChild("Config")
if not configFolder then
	local newFolder = Instance.new("Folder")
	newFolder.Name = "Config"
	newFolder.Parent = ReplicatedStorage
	configFolder = newFolder
end

local skinEndsAt = configFolder:FindFirstChild("SkinRotationEndsAt") :: NumberValue?
if not skinEndsAt then
	local val = Instance.new("NumberValue")
	val.Name = "SkinRotationEndsAt"
	val.Value = Workspace:GetServerTimeNow() + JumbotronConfig.SKIN_ROTATION_INTERVAL_SEC
	val.Parent = configFolder
	skinEndsAt = val
end

-- Default event attributes (2X WINS WEEKEND ending in ~1d 04h)
if not configFolder:GetAttribute("EventEndsAt") then
	configFolder:SetAttribute("EventName", "2X WINS WEEKEND")
	configFolder:SetAttribute("EventSubtitle", "Double wins on all tables this weekend!")
	configFolder:SetAttribute("EventEndsAt", Workspace:GetServerTimeNow() + 100800) -- ~1d 04h
	configFolder:SetAttribute("EventActive", true)
end

-- 10-minute skin rotation timer loop using workspace:GetServerTimeNow()
task.spawn(function()
	local endsAtVal = skinEndsAt :: NumberValue
	while true do
		local now = Workspace:GetServerTimeNow()
		if now >= endsAtVal.Value then
			endsAtVal.Value = now + JumbotronConfig.SKIN_ROTATION_INTERVAL_SEC
		end
		task.wait(1)
	end
end)

-- 2. Jumbotron 3D & SurfaceGui Builder
local function buildJumbotron(parent: Instance): Model?
	local existing = parent:FindFirstChild("Jumbotron")
	if existing then
		if existing:FindFirstChild("Screen") and existing:FindFirstChild("TrussArm_Center") then
			return existing :: Model
		end
		existing:Destroy()
	end

	local screenCF = CFrame.lookAt(JumbotronConfig.POSITION, JumbotronConfig.LOOK_TARGET)
	local jModel = LeaderboardBuilder.buildJumbotron(screenCF, parent)

	-- Restyle stand MainBanner_Top if present
	local banner = parent:FindFirstChild("Decor") and parent.Decor:FindFirstChild("Banners") and parent.Decor.Banners:FindFirstChild("MainBanner_Top")
	if banner and banner:IsA("BasePart") then
		LeaderboardBuilder.styleMainBanner(banner)
	end

	return jModel
end

local function ensureJumbotron()
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		if not lobby:FindFirstChild("Jumbotron") then
			buildJumbotron(lobby)
		end
	end
end

ensureJumbotron()

Workspace.ChildAdded:Connect(function(child)
	if child.Name == "Lobby" then
		task.wait(0.2)
		ensureJumbotron()
	end
end)

-- 3. Cache Latest Winner & Social Proof in configFolder
Remotes.MatchResult.OnServerEvent:Connect(function(player, data)
	-- No direct client writing to match result
end)

local function setLatestWinner(data: { winnerName: string, winnerUserId: number, avgScore: number, grade: string, prizeCard: string? })
	if not configFolder then return end
	configFolder:SetAttribute("LatestWinnerName", data.winnerName)
	configFolder:SetAttribute("LatestWinnerUserId", data.winnerUserId)
	configFolder:SetAttribute("LatestWinnerScore", data.avgScore)
	configFolder:SetAttribute("LatestWinnerGrade", data.grade)
	configFolder:SetAttribute("LatestWinnerPrize", data.prizeCard or "MYTHIC PACK")
end

local function setTopStats(data: { topWinsName: string?, topWinsUid: number?, topWinsCount: number?, topCashName: string?, topCashUid: number?, topCashAmount: number?, rarestPullName: string?, rarestPullUid: number?, rarestPullCard: string? })
	if not configFolder then return end
	if data.topWinsName then
		configFolder:SetAttribute("TopPlayerName", data.topWinsName)
		configFolder:SetAttribute("TopPlayerUserId", data.topWinsUid or 1)
		configFolder:SetAttribute("TopPlayerWins", data.topWinsCount or 0)
	end
	if data.topCashName then
		configFolder:SetAttribute("TopCashName", data.topCashName)
		configFolder:SetAttribute("TopCashUserId", data.topCashUid or 1)
		configFolder:SetAttribute("TopCashAmount", data.topCashAmount or 0)
	end
	if data.rarestPullName then
		configFolder:SetAttribute("RarestPullName", data.rarestPullName)
		configFolder:SetAttribute("RarestPullUserId", data.rarestPullUid or 1)
		configFolder:SetAttribute("RarestPullCard", data.rarestPullCard or "MESSI #10")
	end
end

local JumbotronService = {
	setLatestWinner = setLatestWinner,
	setTopStats = setTopStats,
	buildJumbotron = buildJumbotron,
}

return table.freeze(JumbotronService)
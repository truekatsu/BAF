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

-- Real-time weekend event sync (Active Sat-Sun, Inactive Mon-Fri)
local lastEventActive: boolean? = nil
local lastEventSyncAt = 0

local function syncWeekendEvent(force: boolean?)
	if not configFolder then return end
	local now = Workspace:GetServerTimeNow()
	local state = JumbotronConfig.getWeekendEventState(os.time())
	if force or lastEventActive ~= state.active or (now - lastEventSyncAt) >= 60 then
		lastEventActive = state.active
		lastEventSyncAt = now
		configFolder:SetAttribute("EventName", "2X WINS WEEKEND")
		configFolder:SetAttribute("EventSubtitle", if state.active
			then "Double wins on all tables this weekend!"
			else "Double wins on all tables every weekend!")
		configFolder:SetAttribute("EventActive", state.active)
		configFolder:SetAttribute("EventEndsAt", now + state.remainingSec)
	end
end

syncWeekendEvent(true)
task.spawn(function()
	while true do
		task.wait(1)
		syncWeekendEvent(false)
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
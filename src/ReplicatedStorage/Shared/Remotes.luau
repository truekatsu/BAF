--!strict
--[[
	Remotes
	Responsibility: Single source of truth for client/server RemoteEvents.
	Loop step: n/a (networking)
	Location: ReplicatedStorage/Shared/Remotes (ModuleScript)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "BAF_Remotes"
local EVENT_NAMES = { "MatchState", "MatchAction", "ProfileUpdate", "MetaAction", "OpponentAlert", "FeedbackSync", "MatchResult", "ObbyCompleted", "GoalKick", "TargetKickAction", "TargetKickState", "OpenVoteLockedPopup", "RequestVote", "ActivityPing", "MinigameKick", "MinigameState", "MinigameLeave", "MinigameStateChanged" }

local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
if not folder then
	if not RunService:IsClient() or not RunService:IsRunning() then
		local newFolder = Instance.new("Folder")
		newFolder.Name = FOLDER_NAME
		for _, name in EVENT_NAMES do
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = newFolder
		end
		newFolder.Parent = ReplicatedStorage
		folder = newFolder
	else
		folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	end
else
	if not RunService:IsClient() or not RunService:IsRunning() then
		for _, name in EVENT_NAMES do
			if not folder:FindFirstChild(name) then
				local ev = Instance.new("RemoteEvent")
				ev.Name = name
				ev.Parent = folder
			end
		end
	end
end

local resolvedFolder = folder :: Folder

local Remotes = {
	MatchState = resolvedFolder:WaitForChild("MatchState") :: RemoteEvent,
	MatchAction = resolvedFolder:WaitForChild("MatchAction") :: RemoteEvent,
	ProfileUpdate = resolvedFolder:WaitForChild("ProfileUpdate") :: RemoteEvent,
	MetaAction = resolvedFolder:WaitForChild("MetaAction") :: RemoteEvent,
	OpponentAlert = resolvedFolder:WaitForChild("OpponentAlert") :: RemoteEvent,
	FeedbackSync = resolvedFolder:WaitForChild("FeedbackSync") :: RemoteEvent,
	MatchResult = resolvedFolder:WaitForChild("MatchResult") :: RemoteEvent,
	ObbyCompleted = resolvedFolder:WaitForChild("ObbyCompleted") :: RemoteEvent,
	GoalKick = resolvedFolder:WaitForChild("GoalKick") :: RemoteEvent,
	TargetKickAction = resolvedFolder:WaitForChild("TargetKickAction") :: RemoteEvent,
	TargetKickState = resolvedFolder:WaitForChild("TargetKickState") :: RemoteEvent,
	OpenVoteLockedPopup = resolvedFolder:WaitForChild("OpenVoteLockedPopup") :: RemoteEvent,
	RequestVote = resolvedFolder:WaitForChild("RequestVote") :: RemoteEvent,
	ActivityPing = resolvedFolder:WaitForChild("ActivityPing") :: RemoteEvent,
	MinigameKick = resolvedFolder:WaitForChild("MinigameKick") :: RemoteEvent,
	MinigameState = resolvedFolder:WaitForChild("MinigameState") :: RemoteEvent,
	MinigameLeave = resolvedFolder:WaitForChild("MinigameLeave") :: RemoteEvent,
	MinigameStateChanged = resolvedFolder:WaitForChild("MinigameStateChanged") :: RemoteEvent,
}

return table.freeze(Remotes)

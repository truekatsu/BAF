--!strict
--[[
	LeaderboardClient (Client)
	Responsibility: Drives the client-side live leaderboard SurfaceGuis, row transitions,
	rank change indicators, local player footer ranking, countdown ticker, and performance-throttled
	neon pulse animations for all boards tagged with CollectionService "LeaderboardBoard".
	Location: StarterPlayer/StarterPlayerScripts/Client/LeaderboardClient.client.luau
]]

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LeaderboardConfig = require(Shared:WaitForChild("LeaderboardConfig"))
local LeaderboardBuilder = require(Shared:WaitForChild("LeaderboardBuilder"))

local localPlayer = Players.LocalPlayer
local MAX_PULSE_DIST = 100.0
local TWEEN_INFO_ROW = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_INFO_PULSE = TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

type RowItem = {
	frame: Frame,
	rankNum: TextLabel,
	crownIcon: TextLabel,
	avatar: ImageLabel,
	onlineDot: Frame,
	nameLbl: TextLabel,
	userLbl: TextLabel,
	deltaLbl: TextLabel,
	valLbl: TextLabel,
	stroke: UIStroke?,
}

type BoardUI = {
	model: Model,
	boardType: string,
	screen: Frame,
	rows: { RowItem },
	localRow: Frame?,
	localRankText: TextLabel?,
	liveDot: Frame?,
	countdownLabel: TextLabel?,
	prevRanks: { [number]: number }, -- userId -> prev rank
	prevDataSignature: string,
}

local activeBoards: { [Model]: BoardUI } = {}
local neonStrips: { BasePart } = {}
local lastMyRankFetch: { [string]: number } = {}
local myRankCache: { [string]: number } = {}

-- Safely fetch local player's rank via RemoteFunction (Rate-limited to once per 2 minutes)
local function fetchMyRank(boardType: string): number?
	local now = os.time()
	if myRankCache[boardType] and now - (lastMyRankFetch[boardType] or 0) < LeaderboardConfig.RATE_LIMIT_MY_RANK_SEC then
		return myRankCache[boardType]
	end

	local getMyRankRF = ReplicatedStorage:FindFirstChild("GetMyRank") :: RemoteFunction?
	if not getMyRankRF then
		return myRankCache[boardType]
	end

	lastMyRankFetch[boardType] = now
	task.spawn(function()
		local ok, rank = pcall(function()
			return getMyRankRF:InvokeServer(boardType)
		end)
		if ok and typeof(rank) == "number" then
			myRankCache[boardType] = rank
		end
	end)

	return myRankCache[boardType]
end

-- Bind UI references from a spawned Leaderboard Model
local function bindBoardUI(model: Model)
	if activeBoards[model] then
		return
	end

	local boardType = model:GetAttribute("BoardType") or "Wins"
	local screenPart = model:FindFirstChild("ScreenPart", true) :: BasePart?
	if not screenPart then
		return
	end

	local gui = screenPart:FindFirstChild("LeaderboardGui") :: SurfaceGui?
	if not gui then
		return
	end

	local screen = gui:FindFirstChild("Screen") :: Frame?
	if not screen then
		return
	end

	local rows: { RowItem } = {}
	for i = 1, LeaderboardConfig.ROW_COUNT do
		local rowFrame = screen:FindFirstChild(`Row_{i}`) :: Frame?
		if rowFrame then
			local item: RowItem = {
				frame = rowFrame,
				rankNum = rowFrame:FindFirstChild("RankNum") :: TextLabel,
				crownIcon = rowFrame:FindFirstChild("CrownIcon") :: TextLabel,
				avatar = rowFrame:FindFirstChild("Avatar") :: ImageLabel,
				onlineDot = rowFrame:FindFirstChild("OnlineDot") :: Frame,
				nameLbl = rowFrame:FindFirstChild("PlayerName") :: TextLabel,
				userLbl = rowFrame:FindFirstChild("Username") :: TextLabel,
				deltaLbl = rowFrame:FindFirstChild("RankDelta") :: TextLabel,
				valLbl = rowFrame:FindFirstChild("StatValue") :: TextLabel,
				stroke = rowFrame:FindFirstChild("Stroke") :: UIStroke?,
			}
			table.insert(rows, item)
		end
	end

	local localRow = screen:FindFirstChild("LocalPlayerRow") :: Frame?
	local localRankText = localRow and localRow:FindFirstChild("LocalRankText") :: TextLabel?
	local statusBar = screen:FindFirstChild("StatusBar") :: Frame?
	local liveDot = statusBar and statusBar:FindFirstChild("LiveDot") :: Frame?
	local countdownLabel = statusBar and statusBar:FindFirstChild("CountdownLabel") :: TextLabel?

	activeBoards[model] = {
		model = model,
		boardType = boardType,
		screen = screen,
		rows = rows,
		localRow = localRow,
		localRankText = localRankText,
		liveDot = liveDot,
		countdownLabel = countdownLabel,
		prevRanks = {},
		prevDataSignature = "",
	}

	-- Collect neon strips
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") and desc:GetAttribute("IsNeonStrip") == true then
			table.insert(neonStrips, desc)
		end
	end
end

-- Update a specific board UI when data changes
local function updateBoardDisplay(ui: BoardUI, entries: { any }, updatedAt: number)
	local boardDef = LeaderboardConfig.BOARDS[ui.boardType] or LeaderboardConfig.BOARDS.Wins
	local currentSignature = HttpService:JSONEncode(entries)
	local hasChanged = (ui.prevDataSignature ~= currentSignature)
	ui.prevDataSignature = currentSignature

	local newRankMap: { [number]: number } = {}
	local localPlayerEntry = nil

	for rank = 1, LeaderboardConfig.ROW_COUNT do
		local entry = entries[rank]
		local row = ui.rows[rank]
		if not row then
			continue
		end

		if entry then
			local uid = entry.userId
			newRankMap[uid] = rank
			if uid == localPlayer.UserId then
				localPlayerEntry = entry
			end

			local displayName = entry.name or "Player"
			local username = entry.username or displayName
			local valFormatted = LeaderboardBuilder.formatValue(entry.val, boardDef.formatKind)
			local isOnline = (Players:GetPlayerByUserId(uid) ~= nil)

			-- Row update
			row.nameLbl.Text = displayName
			if row.userLbl then
				row.userLbl.Text = `@{username}`
			end
			row.valLbl.Text = valFormatted
			row.avatar.Image = `rbxthumb://type=AvatarHeadShot&id={uid}&w=150&h=150`
			if row.onlineDot then
				row.onlineDot.Visible = isOnline
			end

			-- Rank delta indicator (+ green up arrow, - red down arrow)
			local oldRank = ui.prevRanks[uid]
			if oldRank and oldRank ~= rank and row.deltaLbl then
				local diff = oldRank - rank
				if diff > 0 then
					row.deltaLbl.Text = `▲`
					row.deltaLbl.TextColor3 = LeaderboardConfig.PALETTE.LiveGreen
				else
					row.deltaLbl.Text = `▼`
					row.deltaLbl.TextColor3 = Color3.fromRGB(239, 68, 68)
				end
				-- Clear after 10s
				task.delay(10, function()
					if row.deltaLbl then
						row.deltaLbl.Text = ""
					end
				end)
			end

			-- Local Player Row Highlight inside Top 10 (Lime Green)
			if uid == localPlayer.UserId then
				row.frame.BackgroundColor3 = Color3.fromHex("#1A3A2A")
				if row.stroke then
					row.stroke.Color = Color3.fromHex("#4ADE80")
					row.stroke.Thickness = 2.5
					row.stroke.Transparency = 0
				end
			else
				row.frame.BackgroundColor3 = if rank % 2 == 1 then LeaderboardConfig.PALETTE.NavyScreen else LeaderboardConfig.PALETTE.NavyScreenAlt
				if row.stroke then
					row.stroke.Color = if rank <= 3 then LeaderboardConfig.MEDAL_COLORS[if rank == 1 then "Gold" elseif rank == 2 then "Silver" else "Bronze"] else LeaderboardConfig.PALETTE.RowDivider
					row.stroke.Thickness = if rank <= 3 then 1.5 else 1
					row.stroke.Transparency = if rank <= 3 then 0.2 else 0.6
				end
			end

			-- Smooth slide/fade animation if data changed
			if hasChanged then
				row.frame.BackgroundTransparency = 0.5
				TweenService:Create(row.frame, TWEEN_INFO_ROW, { BackgroundTransparency = 0 }):Play()
			end
		else
			-- Empty Row placeholder
			row.nameLbl.Text = "---"
			if row.userLbl then
				row.userLbl.Text = ""
			end
			row.valLbl.Text = if boardDef.formatKind == "Time" then "0s" else "0"
			row.avatar.Image = ""
			if row.onlineDot then
				row.onlineDot.Visible = false
			end
			if row.deltaLbl then
				row.deltaLbl.Text = ""
			end
			row.frame.BackgroundColor3 = if rank % 2 == 1 then LeaderboardConfig.PALETTE.NavyScreen else LeaderboardConfig.PALETTE.NavyScreenAlt
		end
	end

	ui.prevRanks = newRankMap

	-- Update Local Player Footer Row
	if ui.localRankText then
		if localPlayerEntry then
			local valStr = LeaderboardBuilder.formatValue(localPlayerEntry.val, boardDef.formatKind)
			ui.localRankText.Text = `YOU: #{localPlayerEntry.rank}  -  {valStr}`
			ui.localRankText.TextColor3 = Color3.fromHex("#4ADE80")
		else
			local estimatedRank = fetchMyRank(ui.boardType)
			local rankStr = if estimatedRank and estimatedRank <= LeaderboardConfig.MAX_RANK_SCAN
				then `#{estimatedRank}`
				elseif estimatedRank then "#1000+"
				else "#--"
			ui.localRankText.Text = `YOU: {rankStr}  (Outside Top 10)`
			ui.localRankText.TextColor3 = LeaderboardConfig.PALETTE.White
		end
	end
end

-- Main Client Refresh Loop
local function initClient()
	-- Listen for existing and new boards
	for _, inst in CollectionService:GetTagged("LeaderboardBoard") do
		if inst:IsA("Model") then
			bindBoardUI(inst)
		end
	end

	CollectionService:GetInstanceAddedSignal("LeaderboardBoard"):Connect(function(inst: Instance)
		if inst:IsA("Model") then
			task.wait(0.2)
			bindBoardUI(inst)
		end
	end)

	CollectionService:GetInstanceRemovedSignal("LeaderboardBoard"):Connect(function(inst: Instance)
		if inst:IsA("Model") then
			activeBoards[inst] = nil
		end
	end)

	-- Listen to ReplicatedStorage LeaderboardData StringValues
	local dataFolder = ReplicatedStorage:WaitForChild("LeaderboardData", 15) :: Folder?
	if dataFolder then
		for _, child in dataFolder:GetChildren() do
			if child:IsA("StringValue") then
				local boardKey = child.Name
				child.Changed:Connect(function()
					local ok, entries = pcall(function()
						return HttpService:JSONDecode(child.Value)
					end)
					if ok and typeof(entries) == "table" then
						local updatedAt = child:GetAttribute("UpdatedAt") or os.time()
						for _, ui in activeBoards do
							if ui.boardType == boardKey then
								updateBoardDisplay(ui, entries, updatedAt)
							end
						end
					end
				end)
			end
		end
	end

	-- Soft Neon Pulse Loop (TweenService transparency 0.1 <-> 0.3 only within 100 studs)
	local isPulsing = false
	task.spawn(function()
		while true do
			task.wait(1.0)
			local cam = Workspace.CurrentCamera
			local camPos = cam and cam.CFrame.Position or Vector3.zero

			for _, strip in neonStrips do
				if strip and strip.Parent then
					local dist = (strip.Position - camPos).Magnitude
					if dist <= MAX_PULSE_DIST then
						if not strip:GetAttribute("PulseTweenStarted") then
							strip:SetAttribute("PulseTweenStarted", true)
							local tw = TweenService:Create(strip, TWEEN_INFO_PULSE, { Transparency = 0.32 })
							tw:Play()
						end
					end
				end
			end
		end
	end)

	-- Second Ticker: "LIVE" dot pulsation & "Next update in 0:XX"
	task.spawn(function()
		local liveState = false
		while true do
			task.wait(1.0)
			liveState = not liveState
			local now = os.time()

			for _, ui in activeBoards do
				-- Pulse LIVE dot
				if ui.liveDot then
					ui.liveDot.BackgroundTransparency = if liveState then 0.1 else 0.5
				end

				-- Countdown
				if ui.countdownLabel and dataFolder then
					local sv = dataFolder:FindFirstChild(ui.boardType) :: StringValue?
					local updated = sv and (sv:GetAttribute("UpdatedAt") :: number?) or now
					local elapsed = math.clamp(now - updated, 0, LeaderboardConfig.REFRESH_INTERVAL_SEC)
					local rem = math.max(0, LeaderboardConfig.REFRESH_INTERVAL_SEC - elapsed)
					ui.countdownLabel.Text = string.format("Next update in 0:%02d", rem)
				end
			end
		end
	end)

	-- Initial update pass
	task.wait(1.0)
	if dataFolder then
		for _, child in dataFolder:GetChildren() do
			if child:IsA("StringValue") then
				local ok, entries = pcall(function()
					return HttpService:JSONDecode(child.Value)
				end)
				if ok and typeof(entries) == "table" then
					local updatedAt = child:GetAttribute("UpdatedAt") or os.time()
					for _, ui in activeBoards do
						if ui.boardType == child.Name then
							updateBoardDisplay(ui, entries, updatedAt)
						end
					end
				end
			end
		end
	end
end

task.spawn(initClient)

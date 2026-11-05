--!strict
--[[
	LeaderboardService
	Responsibility: Server-authoritative tracking, OrderedDataStore batching, MemoryStore single-server election,
	MessagingService broadcast, UserService batched name caching, and anti-exploit verification for the 4 leaderboards.
	Location: ServerScriptService/Server/LeaderboardService (ModuleScript)
]]

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LeaderboardConfig = require(Shared:WaitForChild("LeaderboardConfig"))
local LeaderboardBuilder = require(Shared:WaitForChild("LeaderboardBuilder"))
local Remotes = require(Shared:WaitForChild("Remotes"))

export type LeaderboardEntry = {
	rank: number,
	userId: number,
	name: string,
	username: string,
	val: number,
}

local LeaderboardService = {}

-- In-memory state
local pendingAdds: { [number]: { [string]: number } } = {}
local pendingMax: { [number]: { [string]: number } } = {}
local seededPlayers: { [number]: boolean } = {}
local playerLastActive: { [number]: number } = {}
local playerJoinTick: { [number]: number } = {}
local lastRankLookup: { [number]: { [string]: number } } = {}
local myRankCache: { [number]: { [string]: { rank: number, timestamp: number } } } = {}
local nameCache: { [number]: { name: string, username: string, expires: number } } = {}
local globalTopCache: { [string]: { LeaderboardEntry } } = {
	Wins = {},
	Streak = {},
	Cash = {},
	Playtime = {},
}

-- Rate cap tracking per player per 60s
local intervalAccum: { [number]: { [string]: { amount: number, resetAt: number } } } = {}

-- OrderedDataStore Handles
local orderedStores: { [string]: OrderedDataStore? } = {}
pcall(function()
	for key, conf in LeaderboardConfig.BOARDS do
		orderedStores[key] = DataStoreService:GetOrderedDataStore(conf.dataStoreKey)
	end
end)

-- Replicated Data Folder in ReplicatedStorage
local dataFolder = ReplicatedStorage:FindFirstChild("LeaderboardData") :: Folder?
if not dataFolder then
	dataFolder = Instance.new("Folder")
	dataFolder.Name = "LeaderboardData"
	dataFolder.Parent = ReplicatedStorage
end

for key in LeaderboardConfig.BOARDS do
	if not dataFolder:FindFirstChild(key) then
		local sv = Instance.new("StringValue")
		sv.Name = key
		sv.Value = "[]"
		sv:SetAttribute("UpdatedAt", os.time())
		sv.Parent = dataFolder
	end
end

-- RemoteFunction: GetMyRank
local getMyRankRF = ReplicatedStorage:FindFirstChild("GetMyRank") :: RemoteFunction?
if not getMyRankRF then
	getMyRankRF = Instance.new("RemoteFunction")
	getMyRankRF.Name = "GetMyRank"
	getMyRankRF.Parent = ReplicatedStorage
end

-- Exponential Backoff SafeCall Wrapper
local function safeCall<T...>(fn: () -> T..., maxRetries: number?): (boolean, T...)
	local retries = maxRetries or 3
	local backoffs = { 1, 2, 4 }
	local ok, res1, res2, res3
	for i = 1, retries do
		local result = { pcall(fn) }
		if result[1] then
			return true, unpack(result, 2)
		end
		if i < retries then
			task.wait(backoffs[i] or 2)
		else
			return false, unpack(result, 2)
		end
	end
	return false
end

-- Batch Resolve User DisplayName & Username (Cached for 24h)
local function resolveUserBatch(userIds: { number }): { [number]: { name: string, username: string } }
	local out: { [number]: { name: string, username: string } } = {}
	local fetchIds: { number } = {}
	local now = os.time()

	for _, uid in userIds do
		if uid <= 0 then
			out[uid] = { name = "Guest", username = "Guest" }
			continue
		end
		local cached = nameCache[uid]
		if cached and cached.expires > now then
			out[uid] = { name = cached.name, username = cached.username }
		else
			table.insert(fetchIds, uid)
		end
	end

	if #fetchIds > 0 then
		local ok, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(fetchIds)
		end)
		if ok and typeof(infos) == "table" then
			for _, info in infos do
				local uid = tonumber(info.Id) or 0
				local entry = {
					name = info.DisplayName or info.Username or "Player",
					username = info.Username or "Player",
					expires = now + 86400, -- 24 hours
				}
				nameCache[uid] = entry
				out[uid] = { name = entry.name, username = entry.username }
			end
		else
			-- Fallback to Players:GetNameFromUserIdAsync for failed entries
			for _, uid in fetchIds do
				local nameOk, uname = pcall(function()
					return Players:GetNameFromUserIdAsync(uid)
				end)
				local finalName = if nameOk then uname else "Player"
				local entry = { name = finalName, username = finalName, expires = now + 3600 }
				nameCache[uid] = entry
				out[uid] = { name = finalName, username = finalName }
			end
		end
	end

	return out
end

-- Validate and apply rate caps (anti-exploit)
local function checkSanityCap(userId: number, boardType: string, amount: number): boolean
	local cap = LeaderboardConfig.SANITY_CAPS[boardType]
	if not cap then
		return true
	end
	local now = os.clock()
	if not intervalAccum[userId] then
		intervalAccum[userId] = {}
	end
	local entry = intervalAccum[userId][boardType]
	if not entry or now >= entry.resetAt then
		intervalAccum[userId][boardType] = { amount = amount, resetAt = now + 60 }
		return true
	end
	if entry.amount + amount > cap then
		warn(`[LeaderboardService] Rate cap exceeded for User {userId} on {boardType}: +{amount} (Cap: {cap}/min). Ignored.`)
		return false
	end
	entry.amount += amount
	return true
end

-- PUBLIC API: Add delta to board stat
function LeaderboardService.Add(player: Player, boardType: string, amount: number, silent: boolean?): boolean
	if not player or player.UserId <= 0 and not RunService:IsStudio() then
		return false
	end
	if typeof(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge then
		return false
	end
	if not LeaderboardConfig.BOARDS[boardType] then
		return false
	end
	if silent ~= true and not checkSanityCap(player.UserId, boardType, amount) then
		return false
	end

	local uid = player.UserId
	if not pendingAdds[uid] then
		pendingAdds[uid] = {}
	end
	pendingAdds[uid][boardType] = (pendingAdds[uid][boardType] or 0) + math.floor(amount)

	if LeaderboardConfig.DEBUG_MODE then
		print(`[LeaderboardService] Add: {player.DisplayName} -> {boardType} +{amount} (Pending: {pendingAdds[uid][boardType]})`)
	end
	return true
end

-- PUBLIC API: Set historical maximum (e.g. Best Streak)
function LeaderboardService.SetMax(player: Player, boardType: string, val: number, silent: boolean?): boolean
	if not player or player.UserId <= 0 and not RunService:IsStudio() then
		return false
	end
	if typeof(val) ~= "number" or val < 0 or val ~= val or val == math.huge then
		return false
	end
	if not LeaderboardConfig.BOARDS[boardType] then
		return false
	end
	local intVal = math.floor(val)
	if silent ~= true and intVal > 0 and not checkSanityCap(player.UserId, boardType, intVal) then
		return false
	end

	local uid = player.UserId
	if not pendingMax[uid] then
		pendingMax[uid] = {}
	end
	pendingMax[uid][boardType] = math.max(pendingMax[uid][boardType] or 0, intVal)

	if LeaderboardConfig.DEBUG_MODE then
		print(`[LeaderboardService] SetMax: {player.DisplayName} -> {boardType} max {intVal}`)
	end
	return true
end

-- Flush pending deltas to OrderedDataStore via UpdateAsync
local function flushPlayer(userId: number)
	if userId <= 0 and not RunService:IsStudio() then
		return
	end

	local adds = pendingAdds[userId]
	local maxs = pendingMax[userId]
	if not adds and not maxs then
		return
	end

	-- Budget guard: ensure sufficient budget before bulk flush
	local okBudget, budget = pcall(function()
		return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
	end)
	if okBudget and budget and budget < 4 then
		warn("[LeaderboardService] UpdateAsync budget low (< 4). Deferring flush.")
		return
	end

	for boardType, conf in LeaderboardConfig.BOARDS do
		local store = orderedStores[boardType]
		if not store then
			continue
		end

		local delta = adds and adds[boardType]
		local targetMax = maxs and maxs[boardType]

		if delta and delta > 0 then
			adds[boardType] = nil
			local ok, err = safeCall(function()
				store:UpdateAsync(tostring(userId), function(old: number?)
					local current = math.max(0, tonumber(old) or 0)
					local updated = math.clamp(current + delta, 0, 9e15)
					return updated
				end)
			end)
			if not ok then
				-- Re-queue failed delta
				adds[boardType] = (adds[boardType] or 0) + delta
				warn(`[LeaderboardService] Failed to flush {boardType} for {userId}: {tostring(err)}`)
			end
		end

		if targetMax and targetMax > 0 then
			maxs[boardType] = nil
			local ok, err = safeCall(function()
				store:UpdateAsync(tostring(userId), function(old: number?)
					local current = math.max(0, tonumber(old) or 0)
					return math.max(current, targetMax)
				end)
			end)
			if not ok then
				maxs[boardType] = math.max(maxs[boardType] or 0, targetMax)
				warn(`[LeaderboardService] Failed to flush max {boardType} for {userId}: {tostring(err)}`)
			end
		end
	end
end

-- Flush all players
local function flushAll()
	for uid in pendingAdds do
		flushPlayer(uid)
	end
	for uid in pendingMax do
		flushPlayer(uid)
	end
end

-- Broadcast updated top 10 to clients via ReplicatedStorage StringValue
local function replicateBoardData(boardType: string, entries: { LeaderboardEntry })
	globalTopCache[boardType] = entries
	local sv = dataFolder and dataFolder:FindFirstChild(boardType) :: StringValue?
	if sv then
		local json = HttpService:JSONEncode(entries)
		sv.Value = json
		sv:SetAttribute("UpdatedAt", os.time())
	end

	-- Sync top player to Jumbotron config
	local conf = ReplicatedStorage:FindFirstChild("Config")
	if conf and #entries > 0 then
		local top = entries[1]
		if boardType == "Wins" then
			conf:SetAttribute("TopPlayerName", top.name)
			conf:SetAttribute("TopPlayerUserId", top.userId)
			conf:SetAttribute("TopPlayerWins", top.val)
		elseif boardType == "Cash" then
			conf:SetAttribute("TopCashName", top.name)
			conf:SetAttribute("TopCashUserId", top.userId)
			conf:SetAttribute("TopCashAmount", top.val)
		end
	end
end

-- Refresh Top 10 for a single board
local function refreshBoardSorted(boardType: string)
	local store = orderedStores[boardType]
	if not store then
		return
	end

	local okPages, pages = safeCall(function()
		return store:GetSortedAsync(false, LeaderboardConfig.ROW_COUNT)
	end)
	if not okPages or not pages then
		return
	end

	local okPage, page = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not okPage or typeof(page) ~= "table" then
		return
	end

	local uids: { number } = {}
	local rawEntries: { { userId: number, val: number } } = {}
	for _, row in page do
		local uid = tonumber(row.key)
		local v = tonumber(row.value) or 0
		if uid and uid > 0 and v > 0 then
			table.insert(uids, uid)
			table.insert(rawEntries, { userId = uid, val = v })
		end
	end

	local names = resolveUserBatch(uids)
	local finalEntries: { LeaderboardEntry } = {}

	for rank, entry in ipairs(rawEntries) do
		local info = names[entry.userId] or { name = "Player", username = "Player" }
		table.insert(finalEntries, {
			rank = rank,
			userId = entry.userId,
			name = info.name,
			username = info.username,
			val = entry.val,
		})
	end

	replicateBoardData(boardType, finalEntries)

	-- Broadcast via MessagingService to other server instances
	pcall(function()
		MessagingService:PublishAsync(`LBUpdate_{boardType}`, HttpService:JSONEncode(finalEntries))
	end)
end

-- Distributed Single-Server Refresh Loop via MemoryStore
local function runDistributedRefresh(boardType: string)
	local lockMap: MemoryStoreSortedMap? = nil
	pcall(function()
		lockMap = MemoryStoreService:GetSortedMap("LeaderboardElectMap")
	end)

	local isElected = false
	if lockMap then
		local key = `LBLeader_{boardType}`
		local ok, acquired = pcall(function()
			return (lockMap :: any):SetAsync(key, game.JobId, 90)
		end)
		isElected = ok and (acquired ~= false)
	else
		isElected = true -- Fallback for Studio / single server
	end

	if isElected then
		refreshBoardSorted(boardType)
	end
end

-- Estimate local player's rank (rate-limited to 1 request per 2 min per player)
function LeaderboardService.GetMyRank(player: Player, boardType: string): number?
	if not player or player.UserId <= 0 then
		return nil
	end
	local uid = player.UserId
	local now = os.time()

	if not lastRankLookup[uid] then
		lastRankLookup[uid] = {}
	end
	if not myRankCache[uid] then
		myRankCache[uid] = {}
	end

	local cached = myRankCache[uid][boardType]
	if cached and now - cached.timestamp < LeaderboardConfig.RATE_LIMIT_MY_RANK_SEC then
		return cached.rank
	end

	local lastCall = lastRankLookup[uid][boardType] or 0
	if now - lastCall < LeaderboardConfig.RATE_LIMIT_MY_RANK_SEC then
		return cached and cached.rank or nil
	end
	lastRankLookup[uid][boardType] = now

	local store = orderedStores[boardType]
	if not store then
		return nil
	end

	-- Check Top 10 first
	for _, entry in globalTopCache[boardType] or {} do
		if entry.userId == uid then
			myRankCache[uid][boardType] = { rank = entry.rank, timestamp = now }
			return entry.rank
		end
	end

	-- Scan Sorted Pages up to MAX_RANK_SCAN (1000)
	local scanRank = 1
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 100)
	end)
	if not ok or not pages then
		return nil
	end

	while not pages.IsFinished and scanRank <= LeaderboardConfig.MAX_RANK_SCAN do
		local pageOk, page = pcall(function()
			return pages:GetCurrentPage()
		end)
		if not pageOk or typeof(page) ~= "table" then
			break
		end

		for _, item in page do
			if tonumber(item.key) == uid then
				myRankCache[uid][boardType] = { rank = scanRank, timestamp = now }
				return scanRank
			end
			scanRank += 1
		end

		if pages.IsFinished or scanRank > LeaderboardConfig.MAX_RANK_SCAN then
			break
		end
		local advanceOk = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advanceOk then
			break
		end
	end

	local finalRank = if scanRank > LeaderboardConfig.MAX_RANK_SCAN then 1001 else scanRank
	myRankCache[uid][boardType] = { rank = finalRank, timestamp = now }
	return finalRank
end

-- Force refresh all boards
function LeaderboardService.ForceRefresh(boardType: string?)
	if boardType and LeaderboardConfig.BOARDS[boardType] then
		refreshBoardSorted(boardType)
	else
		for key in LeaderboardConfig.BOARDS do
			refreshBoardSorted(key)
		end
	end
end

-- Seed existing player profile data on first join
function LeaderboardService.seedPlayerOnJoin(player: Player, initialWins: number?, initialStreak: number?, initialCash: number?, initialPlaytime: number?)
	local uid = player.UserId
	if uid <= 0 or seededPlayers[uid] then
		return
	end
	seededPlayers[uid] = true

	if initialWins and initialWins > 0 then
		LeaderboardService.Add(player, "Wins", initialWins, true)
	end
	if initialStreak and initialStreak > 0 then
		LeaderboardService.SetMax(player, "Streak", initialStreak, true)
	end
	if initialCash and initialCash > 0 then
		LeaderboardService.Add(player, "Cash", initialCash, true)
	end
	if initialPlaytime and initialPlaytime > 0 then
		LeaderboardService.Add(player, "Playtime", initialPlaytime, true)
	end
end

-- Spawn all 4 boards procedurally in a row
function LeaderboardService.SpawnAllBoards(originCF: CFrame?, parent: Instance?): { Model }
	local rootCF = originCF or CFrame.new(0, 0, -40)
	local targetParent = parent or Workspace
	local models: { Model } = {}
	local spacing = 26.0
	local order = { "Cash", "Wins", "Streak", "Playtime" }

	for idx, key in ipairs(order) do
		local xOffset = (idx - 2.5) * spacing
		local cf = rootCF * CFrame.new(xOffset, 0, 0)
		local m = LeaderboardBuilder.buildLeaderboard(key, cf, targetParent)
		LeaderboardBuilder.verifyGrounding(m)
		table.insert(models, m)
	end

	return models
end

-- Init Lifecycle
function LeaderboardService.init()
	if not RunService:IsServer() then
		return
	end

	-- Wire RemoteFunction for client rank lookups
	getMyRankRF.OnServerInvoke = function(player: Player, boardType: unknown)
		if typeof(boardType) == "string" and LeaderboardConfig.BOARDS[boardType] then
			return LeaderboardService.GetMyRank(player, boardType)
		end
		return nil
	end

	-- Subscribe to cross-server MessagingService updates
	for key in LeaderboardConfig.BOARDS do
		local boardKey = key
		pcall(function()
			MessagingService:SubscribeAsync(`LBUpdate_{boardKey}`, function(message: { Data: string })
				local ok, data = pcall(function()
					return HttpService:JSONDecode(message.Data)
				end)
				if ok and typeof(data) == "table" then
					replicateBoardData(boardKey, data :: { LeaderboardEntry })
				end
			end)
		end)
	end

	-- Single Heartbeat Server Loop for Playtime tracking (Every 30s)
	task.spawn(function()
		local lastTick = os.clock()
		while true do
			task.wait(30)
			local now = os.clock()
			local dt = math.floor(now - lastTick)
			lastTick = now

			for _, player in Players:GetPlayers() do
				local uid = player.UserId
				if uid > 0 then
					-- Ignore first tick after joining to prevent rejoin spam inflation
					if playerJoinTick[uid] and now - playerJoinTick[uid] < 25 then
						continue
					end

					local canCount = true
					if LeaderboardConfig.PLAYTIME_ACTIVE_ONLY then
						local lastActive = playerLastActive[uid] or 0
						canCount = (now - lastActive <= 35)
					end

					if canCount and dt > 0 then
						LeaderboardService.Add(player, "Playtime", dt, true)
					end
				end
			end
		end
	end)

	-- Scheduled flush loop every 60s
	task.spawn(function()
		while true do
			task.wait(60)
			flushAll()
		end
	end)

	-- Staggered refresh loops for the 4 boards (5s apart)
	local boardKeys = { "Wins", "Streak", "Cash", "Playtime" }
	for idx, key in ipairs(boardKeys) do
		local boardKey = key
		task.spawn(function()
			task.wait((idx - 1) * 5)
			while true do
				runDistributedRefresh(boardKey)
				task.wait(LeaderboardConfig.REFRESH_INTERVAL_SEC)
			end
		end)
	end

	-- Activity ping tracking
	if Remotes.ActivityPing then
		Remotes.ActivityPing.OnServerEvent:Connect(function(player: Player)
			playerLastActive[player.UserId] = os.clock()
		end)
	end

	-- Player Added & Removing Lifecycle
	Players.PlayerAdded:Connect(function(player: Player)
		local uid = player.UserId
		playerJoinTick[uid] = os.clock()
		playerLastActive[uid] = os.clock()
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local uid = player.UserId
		flushPlayer(uid)
		pendingAdds[uid] = nil
		pendingMax[uid] = nil
		playerJoinTick[uid] = nil
		playerLastActive[uid] = nil
		lastRankLookup[uid] = nil
		myRankCache[uid] = nil
		intervalAccum[uid] = nil
	end)

	game:BindToClose(function()
		flushAll()
	end)

	-- Admin Chat Commands Listener
	Players.PlayerAdded:Connect(function(player: Player)
		player.Chatted:Connect(function(msg: string)
			local isAllowed = RunService:IsStudio()
				or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
				or (player:GetRankInGroup(game.CreatorId) >= 254)

			if not isAllowed then
				return
			end

			local tokens = string.split(string.gsub(msg, "^%s*(.-)%s*$", "%1"), " ")
			local cmd = string.lower(tokens[1] or "")

			if cmd == "/spawnboards" then
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local spawnCF = if root then root.CFrame * CFrame.new(0, 0, -25) else CFrame.new(0, 0, -40)
				LeaderboardService.SpawnAllBoards(spawnCF, Workspace)
				print(`[Admin] Spawned 4 leaderboards for {player.DisplayName}`)
			elseif cmd == "/lbadd" and tokens[2] and tokens[3] then
				local bType = tokens[2]
				local amt = tonumber(tokens[3]) or 0
				if amt > 0 then
					LeaderboardService.Add(player, bType, amt, true)
					print(`[Admin] Added {amt} to {bType} for {player.DisplayName}`)
				end
			elseif cmd == "/lbrefresh" then
				LeaderboardService.ForceRefresh()
				print(`[Admin] Force refreshed all leaderboards`)
			elseif cmd == "/lbreset" then
				pendingAdds = {}
				pendingMax = {}
				print(`[Admin] Cleared memory accumulators`)
			end
		end)
	end)
end

return table.freeze(LeaderboardService)

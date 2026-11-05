--!strict
--[[
	ProfileService
	Responsibility: Server-authoritative economy (Bux, Wins, Streak, Titles, Streak King, Friends Boost) and DataStore persistence.
	Loop step: reward | progression
	Location: ServerScriptService/Server/ProfileService (ModuleScript)
]]

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Footballers = require(Shared:WaitForChild("Footballers"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local LeaderboardService = require(script.Parent:WaitForChild("LeaderboardService"))

export type Profile = {
	Bux: number,
	Wins: number,
	Streak: number,
	MatchesPlayed: number,
	WheelSpins: number,
	Luck: number,
	InfRerolls: boolean,
	ExtraSteals: number,
	DoubleBux: boolean,
	DoubleWins: boolean,
	DoubleStreak: boolean,
	EquippedTitle: string,
	EquippedChair: string,
	OwnedChairs: { [string]: boolean },
	DailyDay: number,
	LastDailyClaim: number,
	LastObbyClaim: number,
	GroupClaimed: boolean,
	LikedGame: boolean?,
	PlaytimeSeconds: number,
	PlaytimeClaimed: { [string]: boolean },
	SessionJoinTime: number,
	QuestProgress: { [string]: number },
	QuestClaimed: { [string]: boolean },
	DiscoveredCards: { [string]: boolean },
}

export type MatchRewardSummary = {
	buxEarned: number,
	winsEarned: number,
	newStreak: number,
	wheelSpinEarned: number,
	friendsBoostPct: number,
	title: string,
}

local STORE_NAME = "BAF_Profiles_v1"
local FEEDBACK_STORE_NAME = "BAF_PlayerFeedback_v1"
local DAILY_COOLDOWN_SEC = 86400
local FEEDBACK_COOLDOWN_SEC = 10
local profiles: { [Player]: Profile } = {}
local feedbackCooldowns: { [Player]: number } = {}
local feedbackEntries: { string } = {}
local onTrollCallback: ((Player) -> ())? = nil

-- shortcut: plain DataStore GetAsync/SetAsync without session locking, upgrade to ProfileStore if trading is added in v2.0
local store: DataStore? = nil
local feedbackStore: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
	feedbackStore = DataStoreService:GetDataStore(FEEDBACK_STORE_NAME)
end)

local function isOwner(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	elseif game.CreatorType == Enum.CreatorType.Group and game.CreatorId > 0 then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		return ok and rank >= 255
	end
	return false
end

local function buildFeedbackTxt(): string
	local header = table.concat({
		"============================================================",
		"BUILD A FOOTBALLER — PLAYER FEEDBACK LOG (.txt)",
		`Total Feedback: {#feedbackEntries}`,
		"============================================================",
	}, "\n")
	if #feedbackEntries == 0 then
		return header .. "\n(Belum ada feedback pemain.)\n"
	end
	return header .. "\n" .. table.concat(feedbackEntries, "\n") .. "\n"
end

local function syncFeedbackStorage()
	local sv = ServerStorage:FindFirstChild("PlayerFeedback_TXT") :: StringValue?
	if not sv then
		sv = Instance.new("StringValue")
		sv.Name = "PlayerFeedback_TXT"
		sv.Parent = ServerStorage
	end
	local txt = buildFeedbackTxt()
	sv.Value = txt
	for _, plr in Players:GetPlayers() do
		if isOwner(plr) then
			Remotes.FeedbackSync:FireClient(plr, { kind = "Log", txt = txt })
		end
	end
end

local ProfileService = {}

function ProfileService.setTrollCallback(fn: (Player) -> ())
	onTrollCallback = fn
end

local function defaultProfile(): Profile
	return {
		Bux = 0,
		Wins = 0,
		Streak = 0,
		MatchesPlayed = 0,
		WheelSpins = 1,
		Luck = 1,
		InfRerolls = false,
		ExtraSteals = 0,
		DoubleBux = false,
		DoubleWins = false,
		DoubleStreak = false,
		EquippedTitle = "Benchwarmer",
		EquippedChair = "wood",
		OwnedChairs = { wood = true },
		DailyDay = 1,
		LastDailyClaim = 0,
		LastObbyClaim = 0,
		GroupClaimed = false,
		LikedGame = false,
		PlaytimeSeconds = 0,
		PlaytimeClaimed = {},
		SessionJoinTime = Workspace:GetServerTimeNow(),
		QuestProgress = {
			finish_match = 0,
			vote_mythical = 0,
			complete_obby = 0,
		},
		QuestClaimed = {},
		DiscoveredCards = {},
	}
end

local function resolveActiveTitle(profile: Profile): string
	for _, entry in GameConfig.TITLES do
		if entry.name == profile.EquippedTitle and profile.Wins >= entry.minWins then
			return entry.name
		end
	end
	return GameConfig.getTitleForWins(profile.Wins)
end

local function updateStreakKing()
	local bestPlayer: Player? = nil
	local bestStreak = 0
	for player, profile in profiles do
		if profile.Streak > bestStreak then
			bestStreak = profile.Streak
			bestPlayer = player
		end
	end
	for player in profiles do
		player:SetAttribute("IsStreakKing", player == bestPlayer and bestStreak > 0)
	end
end

local function syncLeaderstats(player: Player, profile: Profile, toast: string?)
	local leaderstats = player:FindFirstChild("leaderstats") :: Folder?
	if not leaderstats then
		local f = Instance.new("Folder")
		f.Name = "leaderstats"
		for _, statName in { "Bux", "Wins", "Streak" } do
			local iv = Instance.new("IntValue")
			iv.Name = statName
			iv.Parent = f
		end
		f.Parent = player
		leaderstats = f
	end
	local ls = leaderstats :: Folder
	local buxVal = ls:FindFirstChild("Bux") :: IntValue?
	local winsVal = ls:FindFirstChild("Wins") :: IntValue?
	local streakVal = ls:FindFirstChild("Streak") :: IntValue?
	if buxVal then
		buxVal.Value = profile.Bux
	end
	if winsVal then
		winsVal.Value = profile.Wins
	end
	if streakVal then
		streakVal.Value = profile.Streak
	end

	local title = resolveActiveTitle(profile)
	profile.EquippedTitle = title
	player:SetAttribute("Title", title)
	player:SetAttribute("EquippedChair", profile.EquippedChair)
	player:SetAttribute("LikedGame", profile.LikedGame == true)
	player:SetAttribute("SessionStart", profile.SessionJoinTime)
	local obbyNextAt = if (profile.LastObbyClaim or 0) > 0
		then (profile.LastObbyClaim or 0) + GameConfig.OBBY_COOLDOWN_SEC
		else 0
	player:SetAttribute("ObbyNextClaimAt", obbyNextAt)
	local friendsPct = math.round(ProfileService.getFriendsInServerCount(player) * GameConfig.FRIEND_BOOST_PER_FRIEND * 100)
	player:SetAttribute("FriendsBoostPct", friendsPct)
	updateStreakKing()
	Remotes.ProfileUpdate:FireClient(player, profile, title, toast)
end

function ProfileService.get(player: Player): Profile?
	return profiles[player]
end

function ProfileService.getPlaytimeSeconds(player: Player): number
	local profile = profiles[player]
	if not profile then
		return 0
	end
	local sessionSec = math.max(0, math.floor(Workspace:GetServerTimeNow() - profile.SessionJoinTime))
	return math.max(0, math.floor(profile.PlaytimeSeconds or 0)) + sessionSec
end

function ProfileService.getSessionJoinTime(player: Player): number
	local profile = profiles[player]
	return if profile then profile.SessionJoinTime else Workspace:GetServerTimeNow()
end

function ProfileService.setSessionJoinTime(player: Player, newTime: number)
	local profile = profiles[player]
	if profile then
		profile.SessionJoinTime = newTime
		player:SetAttribute("SessionStart", newTime)
	end
end

function ProfileService.addBux(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or amount <= 0 then
		return false
	end
	local amt = math.round(amount)
	profile.Bux += amt
	LeaderboardService.Add(player, "Cash", amt)
	syncLeaderstats(player, profile)
	return true
end

function ProfileService.recordQuestProgress(player: Player, questId: string, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.QuestProgress[questId] = (profile.QuestProgress[questId] or 0) + amount
	syncLeaderstats(player, profile)
end

function ProfileService.claimObby(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local now = Workspace:GetServerTimeNow()
	local rem = math.ceil(((profile.LastObbyClaim or 0) + GameConfig.OBBY_COOLDOWN_SEC) - now)
	if rem > 0 then
		local h = math.floor(rem / 3600)
		local m = math.floor((rem % 3600) / 60)
		local s = rem % 60
		syncLeaderstats(player, profile, string.format("⏳ Obby Cooldown: %02d:%02d:%02d lagi!", h, m, s))
		return false
	end
	profile.LastObbyClaim = now
	profile.Bux += GameConfig.OBBY_REWARD_BUX
	LeaderboardService.Add(player, "Cash", GameConfig.OBBY_REWARD_BUX)
	profile.QuestProgress.complete_obby = (profile.QuestProgress.complete_obby or 0) + 1
	syncLeaderstats(player, profile, `🎁 Obby Claimed: +${GameConfig.OBBY_REWARD_BUX} Bux! (Cooldown 4 Jam)`)
	return true
end

function ProfileService.discoverCard(player: Player, cardId: string): boolean
	local profile = profiles[player]
	local card = Footballers.ById[cardId]
	if not profile or not card or profile.DiscoveredCards[cardId] then
		return false
	end
	profile.DiscoveredCards[cardId] = true
	local bonus = if card.rarity == "Mythic"
		then 250
		elseif card.rarity == "Legendary" then 100
		elseif card.rarity == "Epic" then 50
		else 25
	profile.Bux += bonus
	LeaderboardService.Add(player, "Cash", bonus)
	syncLeaderstats(player, profile, `📖 NEW {string.upper(card.rarity)}: {Footballers.getDisplayName(card)} (+${bonus} Bux!)`)
	return true
end

function ProfileService.getFriendsInServerCount(player: Player): number
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWith(other.UserId)
			end)
			if ok and isFriend then
				count += 1
			end
		end
	end
	return count
end

function ProfileService.awardMatchResult(player: Player, won: boolean): MatchRewardSummary?
	local profile = profiles[player]
	if not profile then
		return nil
	end

	profile.MatchesPlayed += 1
	profile.WheelSpins += 1
	profile.QuestProgress.finish_match = (profile.QuestProgress.finish_match or 0) + 1

	local friendsCount = ProfileService.getFriendsInServerCount(player)
	local friendMult = 1 + (friendsCount * GameConfig.FRIEND_BOOST_PER_FRIEND)
	local baseBux = if won then GameConfig.WIN_BUX else GameConfig.LOSS_BUX
	local buxMult = if profile.DoubleBux then 2 else 1
	local buxEarned = math.round(baseBux * buxMult * friendMult)
	profile.Bux += buxEarned
	LeaderboardService.Add(player, "Cash", buxEarned)

	local winsEarned = 0
	if won then
		winsEarned = if profile.DoubleWins then 2 else 1
		local streakGain = if profile.DoubleStreak then 2 else 1
		profile.Wins += winsEarned
		profile.Streak += streakGain
		LeaderboardService.Add(player, "Wins", winsEarned)
		LeaderboardService.SetMax(player, "Streak", profile.Streak)
	else
		profile.Streak = 0
		LeaderboardService.SetMax(player, "Streak", 0)
	end

	-- Auto-promote title when reaching a new milestone
	local highestTitle = GameConfig.getTitleForWins(profile.Wins)
	profile.EquippedTitle = highestTitle

	syncLeaderstats(player, profile)
	return {
		buxEarned = buxEarned,
		winsEarned = winsEarned,
		newStreak = profile.Streak,
		wheelSpinEarned = 1,
		friendsBoostPct = math.round(friendsCount * GameConfig.FRIEND_BOOST_PER_FRIEND * 100),
		title = profile.EquippedTitle,
	}
end

local function grantShopItem(player: Player, itemKey: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	if itemKey == "troll_all" then
		if onTrollCallback then
			onTrollCallback(player)
		end
		local msg = `😈 {player.DisplayName} TROLLED THE ENTIRE SERVER!`
		for otherPlayer, otherProfile in profiles do
			syncLeaderstats(otherPlayer, otherProfile, msg)
		end
		return true
	elseif itemKey == "starter_pack" then
		profile.Bux += 500
		LeaderboardService.Add(player, "Cash", 500)
		profile.OwnedChairs["crimson"] = true
		profile.EquippedChair = "crimson"
		syncLeaderstats(player, profile, "Starter Pack Unlocked: +$500 Bux & Crimson Chair!")
		return true
	elseif itemKey == "vip" then
		profile.DoubleBux = true
		profile.OwnedChairs["golden"] = true
		profile.EquippedChair = "golden"
		syncLeaderstats(player, profile, "VIP Activated: Golden Chair + 2x Bux!")
		return true
	elseif itemKey == "2x_bux" then
		profile.DoubleBux = true
		syncLeaderstats(player, profile, "2x Bux Gamepass Activated!")
		return true
	elseif itemKey == "2x_wins" then
		profile.DoubleWins = true
		syncLeaderstats(player, profile, "2x Wins Gamepass Activated!")
		return true
	elseif itemKey == "2x_streak" then
		profile.DoubleStreak = true
		syncLeaderstats(player, profile, "2x Streak Gamepass Activated!")
		return true
	elseif itemKey == "inf_rerolls" then
		profile.InfRerolls = true
		syncLeaderstats(player, profile, "Infinite Rerolls Activated!")
		return true
	elseif itemKey == "bux_300" then
		profile.Bux += 300
		LeaderboardService.Add(player, "Cash", 300)
		syncLeaderstats(player, profile, "+$300 Bux Added!")
		return true
	elseif itemKey == "bux_1000" then
		profile.Bux += 1000
		LeaderboardService.Add(player, "Cash", 1000)
		syncLeaderstats(player, profile, "+$1,000 Bux Added!")
		return true
	elseif itemKey == "bux_4000" then
		profile.Bux += 4000
		LeaderboardService.Add(player, "Cash", 4000)
		syncLeaderstats(player, profile, "+$4,000 Bux Added!")
		return true
	elseif itemKey == "bux_15000" then
		profile.Bux += 15000
		LeaderboardService.Add(player, "Cash", 15000)
		syncLeaderstats(player, profile, "+$15,000 Bux Added!")
		return true
	end
	return false
end

ProfileService.grantShopItem = grantShopItem

function ProfileService.upgradeLuck(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local nextTier = GameConfig.getNextLuckTier(profile.Luck)
	if not nextTier then
		syncLeaderstats(player, profile, "🍀 Max Luck (5x) Already Unlocked!")
		return false
	end
	if profile.Bux < nextTier.cost then
		syncLeaderstats(player, profile, `🍀 Need ${nextTier.cost} for {nextTier.luck}x Luck!`)
		return false
	end
	profile.Bux -= nextTier.cost
	profile.Luck = nextTier.luck
	syncLeaderstats(player, profile, `🍀 Luck Upgraded to {nextTier.luck}x!`)
	return true
end

function ProfileService.handleMetaAction(player: Player, action: unknown, arg: unknown)
	local profile = profiles[player]
	if not profile or typeof(action) ~= "string" then
		return
	end
	local now = Workspace:GetServerTimeNow()

	if action == "ClaimDaily" then
		if now - profile.LastDailyClaim < DAILY_COOLDOWN_SEC then
			return
		end
		local dayIdx = math.clamp(profile.DailyDay, 1, #GameConfig.DAILY_REWARDS)
		local reward = GameConfig.DAILY_REWARDS[dayIdx]
		profile.LastDailyClaim = now
		profile.DailyDay = if dayIdx >= #GameConfig.DAILY_REWARDS then 1 else dayIdx + 1
		if reward.bux > 0 then
			profile.Bux += reward.bux
			LeaderboardService.Add(player, "Cash", reward.bux)
		end
		if reward.spins > 0 then
			profile.WheelSpins += reward.spins
		end
		if reward.chair then
			profile.OwnedChairs[reward.chair] = true
			profile.EquippedChair = reward.chair
		end
		syncLeaderstats(player, profile, `Claimed Day {dayIdx}: {reward.label}!`)
		return
	end

	if action == "ClaimGroup" then
		if profile.GroupClaimed then
			return
		end
		profile.GroupClaimed = true
		profile.Bux += GameConfig.GROUP_REWARD_BUX
		LeaderboardService.Add(player, "Cash", GameConfig.GROUP_REWARD_BUX)
		syncLeaderstats(player, profile, `Claimed Group Reward: +${GameConfig.GROUP_REWARD_BUX} Bux!`)
		return
	end

	if action == "ClaimPlaytime" and typeof(arg) == "string" then
		if profile.PlaytimeClaimed[arg] then
			return
		end
		local elapsed = now - profile.SessionJoinTime
		for _, entry in GameConfig.PLAYTIME_REWARDS do
			if entry.id == arg and elapsed >= entry.seconds then
				profile.PlaytimeClaimed[arg] = true
				profile.Bux += entry.bux
				LeaderboardService.Add(player, "Cash", entry.bux)
				profile.WheelSpins += entry.spins
				if entry.chair then
					profile.OwnedChairs[entry.chair] = true
					profile.EquippedChair = entry.chair
				end
				syncLeaderstats(player, profile, `Claimed Playtime ({entry.timeLabel}): {entry.rewardLabel}!`)
				return
			end
		end
		return
	end

	if action == "ClaimQuest" and typeof(arg) == "string" then
		if profile.QuestClaimed[arg] then
			return
		end
		for _, q in GameConfig.QUESTS do
			if q.id == arg and (profile.QuestProgress[arg] or 0) >= q.target then
				profile.QuestClaimed[arg] = true
				profile.Bux += q.bux
				LeaderboardService.Add(player, "Cash", q.bux)
				profile.WheelSpins += q.spins
				syncLeaderstats(player, profile, `Quest Complete: {q.rewardLabel}!`)
				return
			end
		end
		return
	end

	if action == "EquipTitle" and typeof(arg) == "string" then
		for _, entry in GameConfig.TITLES do
			if entry.name == arg and profile.Wins >= entry.minWins then
				profile.EquippedTitle = entry.name
				syncLeaderstats(player, profile, `Equipped Title: {entry.name}`)
				return
			end
		end
		return
	end

	if action == "BuyOrEquipChair" and typeof(arg) == "string" then
		for _, skin in GameConfig.CHAIR_SKINS do
			if skin.id == arg then
				if profile.OwnedChairs[skin.id] then
					profile.EquippedChair = skin.id
					syncLeaderstats(player, profile, `Equipped {skin.name} Chair!`)
				elseif profile.Bux >= skin.cost then
					profile.Bux -= skin.cost
					profile.OwnedChairs[skin.id] = true
					profile.EquippedChair = skin.id
					syncLeaderstats(player, profile, `Unlocked & Equipped {skin.name} Chair!`)
				end
				return
			end
		end
		return
	end

	if action == "UpgradeLuck" then
		ProfileService.upgradeLuck(player)
		return
	end

	if action == "SpinWheel" then
		if profile.WheelSpins <= 0 then
			return
		end
		profile.WheelSpins -= 1
		local roll = math.random(1, 100)
		local acc = 0
		local chosen = GameConfig.WHEEL_SEGMENTS[1]
		for _, seg in GameConfig.WHEEL_SEGMENTS do
			acc += seg.weight
			if roll <= acc then
				chosen = seg
				break
			end
		end
		if chosen.bux > 0 then
			profile.Bux += chosen.bux
			LeaderboardService.Add(player, "Cash", chosen.bux)
		end
		if chosen.chair then
			profile.OwnedChairs[chosen.chair] = true
			profile.EquippedChair = chosen.chair
		end
		local nextSeq = ((player:GetAttribute("WheelSpinSeq") :: number?) or 0) + 1
		player:SetAttribute("LastWheelSlice", chosen.id)
		player:SetAttribute("WheelSpinSeq", nextSeq)
		syncLeaderstats(player, profile, chosen.toast)
		return
	end

	if action == "SubmitFeedback" and typeof(arg) == "string" then
		local lastAt = feedbackCooldowns[player] or 0
		if now - lastAt < FEEDBACK_COOLDOWN_SEC then
			local waitSec = math.ceil(FEEDBACK_COOLDOWN_SEC - (now - lastAt))
			syncLeaderstats(player, profile, `⏳ Tunggu {waitSec}s sebelum mengirim feedback lagi.`)
			return
		end
		local cleaned = string.gsub(arg, "[\r\n\t]+", " ")
		cleaned = string.match(cleaned, "^%s*(.-)%s*$") or ""
		if #cleaned < 2 then
			return
		end
		if #cleaned > 500 then
			cleaned = string.sub(cleaned, 1, 500)
		end
		feedbackCooldowns[player] = now
		local stamp = os.date("!%Y-%m-%d %H:%M:%S UTC")
		local line = `[{stamp}] {player.DisplayName} (@{player.Name} | ID: {player.UserId}): {cleaned}`
		table.insert(feedbackEntries, line)
		while #feedbackEntries > 200 do
			table.remove(feedbackEntries, 1)
		end
		syncFeedbackStorage()
		if feedbackStore then
			task.spawn(function()
				pcall(function()
					(feedbackStore :: DataStore):UpdateAsync("Entries_v1", function(old: unknown)
						local list: { string } = if typeof(old) == "table" then old :: { string } else {}
						table.insert(list, line)
						while #list > 200 do
							table.remove(list, 1)
						end
						return list
					end)
				end)
			end)
		end
		syncLeaderstats(player, profile, "✅ Feedback terkirim! Terima kasih!")
		Remotes.FeedbackSync:FireClient(player, { kind = "Submitted" })
		return
	end

	if action == "GetOwnerFeedbackTxt" then
		if isOwner(player) then
			Remotes.FeedbackSync:FireClient(player, { kind = "Log", txt = buildFeedbackTxt() })
		end
		return
	end

	if action == "BuyShopItem" and typeof(arg) == "string" then
		local item = (GameConfig.MONETIZATION :: any)[arg]
		if not item then
			return
		end
		if item.id > 0 and not RunService:IsStudio() then
			pcall(function()
				if item.kind == "GamePass" then
					MarketplaceService:PromptGamePassPurchase(player, item.id)
				else
					MarketplaceService:PromptProductPurchase(player, item.id)
				end
			end)
		else
			grantShopItem(player, arg)
		end
	end
end

local function loadPlayer(player: Player)
	local data = defaultProfile()
	if store and player.UserId > 0 then
		local ok, saved = pcall(function()
			return (store :: DataStore):GetAsync(`Player_{player.UserId}`)
		end)
		if ok and typeof(saved) == "table" then
			for k, v in saved do
				if data[k] ~= nil and typeof(v) == typeof(data[k]) then
					(data :: any)[k] = v
				end
			end
		end
	end
	data.SessionJoinTime = Workspace:GetServerTimeNow()
	data.PlaytimeClaimed = {}
	data.OwnedChairs["wood"] = true
	if not player:IsDescendantOf(Players) then
		return
	end
	profiles[player] = data
	syncLeaderstats(player, data)
	LeaderboardService.seedPlayerOnJoin(player, data.Wins, data.Streak, data.Bux, data.PlaytimeSeconds)
end

local function saveAndRemovePlayer(player: Player)
	local profile = profiles[player]
	profiles[player] = nil
	feedbackCooldowns[player] = nil
	updateStreakKing()
	if profile then
		local now = Workspace:GetServerTimeNow()
		local elapsed = math.max(0, math.floor(now - profile.SessionJoinTime))
		profile.PlaytimeSeconds = math.max(0, math.floor(profile.PlaytimeSeconds or 0)) + elapsed
		profile.SessionJoinTime = now
		if store and player.UserId > 0 then
			pcall(function()
				(store :: DataStore):SetAsync(`Player_{player.UserId}`, profile)
			end)
		end
	end
end

function ProfileService.init()
	if not RunService:IsServer() then
		return
	end
	syncFeedbackStorage()
	if feedbackStore then
		task.spawn(function()
			local ok, saved = pcall(function()
				return (feedbackStore :: DataStore):GetAsync("Entries_v1")
			end)
			if ok and typeof(saved) == "table" then
				for _, entry in saved :: { unknown } do
					if typeof(entry) == "string" then
						table.insert(feedbackEntries, entry)
					end
				end
				while #feedbackEntries > 200 do
					table.remove(feedbackEntries, 1)
				end
				syncFeedbackStorage()
			end
		end)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
		if not wasPurchased or gamePassId <= 0 then
			return
		end
		for key, item in GameConfig.MONETIZATION :: any do
			if item.kind == "GamePass" and item.id == gamePassId then
				grantShopItem(player, key)
				break
			end
		end
	end)
	MarketplaceService.ProcessReceipt = function(receiptInfo: { PlayerId: number, ProductId: number })
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player or not profiles[player] then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		for key, item in GameConfig.MONETIZATION :: any do
			if item.kind == "Product" and item.id == receiptInfo.ProductId and item.id > 0 then
				if grantShopItem(player, key) then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	Remotes.MetaAction.OnServerEvent:Connect(ProfileService.handleMetaAction)
	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(saveAndRemovePlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			saveAndRemovePlayer(player)
		end
	end)
end

return table.freeze(ProfileService)

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
local JumbotronConfig = require(Shared:WaitForChild("JumbotronConfig"))
local Footballers = require(Shared:WaitForChild("Footballers"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local LeaderboardService = require(script.Parent:WaitForChild("LeaderboardService"))

export type Profile = {
	Bux: number,
	Wins: number,
	Streak: number,
	MatchesPlayed: number,
	WheelSpins: number,
	LastFirstSpinOfferDay: number?,
	Luck: number,
	InfRerolls: boolean,
	ExtraSteals: number,
	DoubleBux: boolean,
	DoubleWins: boolean,
	DoubleStreak: boolean,
	DoubleLuck: boolean,
	VIP: boolean?,
	StarterPackOwned: boolean?,
	EquippedTitle: string,
	UnlockedTitles: { [string]: boolean },
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
	FirstJoinedAt: number,
	BestStreak: number,
	TotalCashEarned: number,
	WinsDayKey: number,
	WinsToday: number,
	WinsWeekKey: number,
	WinsThisWeek: number,
	TotalCardSpins: number,
	MythicsPulled: number,
	SpinsSinceMythic: number,
	MaxSpinsWithoutMythic: number,
	RarestCardId: string,
	LatestCardId: string,
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
local AUTOSAVE_INTERVAL_SEC = 120
local profiles: { [Player]: Profile } = {}
local dirtyProfiles: { [Player]: boolean } = {}
local feedbackCooldowns: { [Player]: number } = {}
local feedbackEntries: { string } = {}

local RARITY_RANK: { [string]: number } = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legend = 5,
	Mythic = 6,
}

local function isRarerCard(cand: Footballers.Footballer, cur: Footballers.Footballer?): boolean
	if not cur then
		return true
	end
	local rA = RARITY_RANK[cand.rarity] or 0
	local rB = RARITY_RANK[cur.rarity] or 0
	if rA ~= rB then
		return rA > rB
	end
	return cand.ovr >= cur.ovr
end

local function refreshWinBuckets(profile: Profile)
	local now = os.time()
	local dayKey = math.floor(now / 86400)
	local weekKey = math.floor((now + 345600) / 604800)
	if profile.WinsDayKey ~= dayKey then
		profile.WinsDayKey = dayKey
		profile.WinsToday = 0
	end
	if profile.WinsWeekKey ~= weekKey then
		profile.WinsWeekKey = weekKey
		profile.WinsThisWeek = 0
	end
end

local function grantBux(player: Player, profile: Profile, amount: number)
	local amt = math.round(amount)
	if amt <= 0 then
		return
	end
	profile.Bux += amt
	profile.TotalCashEarned = (profile.TotalCashEarned or 0) + amt
	dirtyProfiles[player] = true
	LeaderboardService.Add(player, "Cash", amt)
end

-- shortcut: plain DataStore GetAsync/SetAsync without session locking, upgrade to ProfileStore if trading is added in v2.0
local store: DataStore? = nil
local feedbackStore: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
	feedbackStore = DataStoreService:GetDataStore(FEEDBACK_STORE_NAME)
end)

task.spawn(function()
	if feedbackStore then
		local ok, saved = pcall(function()
			return (feedbackStore :: DataStore):GetAsync("Entries_v1")
		end)
		if ok and typeof(saved) == "table" then
			for _, entry in saved do
				if typeof(entry) == "string" then
					table.insert(feedbackEntries, entry)
				end
			end
			syncFeedbackStorage()
		end
	end
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

local function defaultProfile(): Profile
	return {
		Bux = 0,
		Wins = 0,
		Streak = 0,
		MatchesPlayed = 0,
		WheelSpins = 1,
		LastFirstSpinOfferDay = 0,
		Luck = 1,
		InfRerolls = false,
		ExtraSteals = 0,
		DoubleBux = false,
		DoubleWins = false,
		DoubleStreak = false,
		DoubleLuck = false,
		VIP = false,
		StarterPackOwned = false,
		EquippedTitle = "Benchwarmer",
		UnlockedTitles = { Benchwarmer = true },
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
		FirstJoinedAt = 0,
		BestStreak = 0,
		TotalCashEarned = 0,
		WinsDayKey = math.floor(os.time() / 86400),
		WinsToday = 0,
		WinsWeekKey = math.floor((os.time() + 345600) / 604800),
		WinsThisWeek = 0,
		TotalCardSpins = 0,
		MythicsPulled = 0,
		SpinsSinceMythic = 0,
		MaxSpinsWithoutMythic = 0,
		RarestCardId = "",
		LatestCardId = "",
	}
end

local function isTitleUnlocked(profile: Profile, entry: { name: string, minWins: number }): boolean
	return (profile.UnlockedTitles ~= nil and profile.UnlockedTitles[entry.name] == true) or profile.Wins >= entry.minWins
end

local function syncUnlockedTitles(profile: Profile): string?
	if not profile.UnlockedTitles then
		profile.UnlockedTitles = { Benchwarmer = true }
	end
	profile.UnlockedTitles["Benchwarmer"] = true
	local newlyUnlocked: string? = nil
	local bestNewMinWins = -1
	for _, entry in GameConfig.TITLES do
		if profile.Wins >= entry.minWins then
			local wasUnlocked = profile.UnlockedTitles[entry.name] == true
			profile.UnlockedTitles[entry.name] = true
			if not wasUnlocked and entry.minWins > bestNewMinWins then
				bestNewMinWins = entry.minWins
				newlyUnlocked = entry.name
			end
		end
	end
	return newlyUnlocked
end

local function resolveActiveTitle(profile: Profile): string
	for _, entry in GameConfig.TITLES do
		if entry.name == profile.EquippedTitle and isTitleUnlocked(profile, entry) then
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
	refreshWinBuckets(profile)
	if profile.Streak > (profile.BestStreak or 0) then
		profile.BestStreak = profile.Streak
	end
	player:SetAttribute("Title", title)
	player:SetAttribute("EquippedChair", profile.EquippedChair)
	player:SetAttribute("LikedGame", profile.LikedGame == true)
	player:SetAttribute("IsVIP", profile.VIP == true)
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
	grantBux(player, profile, amount)
	syncLeaderstats(player, profile)
	return true
end

function ProfileService.recordQuestProgress(player: Player, questId: string, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.QuestProgress[questId] = (profile.QuestProgress[questId] or 0) + amount
	dirtyProfiles[player] = true
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
	grantBux(player, profile, GameConfig.OBBY_REWARD_BUX)
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
	local curRarest = if profile.RarestCardId ~= "" then Footballers.ById[profile.RarestCardId] else nil
	if isRarerCard(card, curRarest) then
		profile.RarestCardId = card.id
	end
	local bonus = if card.rarity == "Mythic"
		then 250
		elseif card.rarity == "Legend" then 100
		elseif card.rarity == "Epic" then 50
		else 25
	grantBux(player, profile, bonus)
	syncLeaderstats(player, profile, `📖 NEW {string.upper(card.rarity)}: {Footballers.getDisplayName(card)} (+${bonus} Bux!)`)
	return true
end

function ProfileService.recordCardRoll(player: Player, cardId: string)
	local profile = profiles[player]
	local card = Footballers.ById[cardId]
	if not profile or not card then
		return
	end
	profile.TotalCardSpins = (profile.TotalCardSpins or 0) + 1
	profile.LatestCardId = card.id
	local curRarest = if profile.RarestCardId ~= "" then Footballers.ById[profile.RarestCardId] else nil
	if isRarerCard(card, curRarest) then
		profile.RarestCardId = card.id
	end
	if card.rarity == "Mythic" then
		profile.MythicsPulled = (profile.MythicsPulled or 0) + 1
		profile.SpinsSinceMythic = 0
	else
		profile.SpinsSinceMythic = (profile.SpinsSinceMythic or 0) + 1
		if profile.SpinsSinceMythic > (profile.MaxSpinsWithoutMythic or 0) then
			profile.MaxSpinsWithoutMythic = profile.SpinsSinceMythic
		end
	end
	dirtyProfiles[player] = true
	if not profile.DiscoveredCards[cardId] then
		ProfileService.discoverCard(player, cardId)
	else
		syncLeaderstats(player, profile)
	end
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
	grantBux(player, profile, buxEarned)

	refreshWinBuckets(profile)
	local winsEarned = 0
	if won then
		local eventMult = if JumbotronConfig.isWeekendEventActive() then 2 else 1
		local passMult = if profile.DoubleWins then 2 else 1
		winsEarned = eventMult * passMult
		local streakGain = if profile.DoubleStreak then 2 else 1
		profile.Wins += winsEarned
		profile.WinsToday = (profile.WinsToday or 0) + winsEarned
		profile.WinsThisWeek = (profile.WinsThisWeek or 0) + winsEarned
		profile.Streak += streakGain
		if profile.Streak > (profile.BestStreak or 0) then
			profile.BestStreak = profile.Streak
		end
		LeaderboardService.Add(player, "Wins", winsEarned)
		LeaderboardService.SetMax(player, "Streak", profile.BestStreak)
	else
		profile.Streak = 0
		LeaderboardService.SetMax(player, "Streak", profile.BestStreak or 0)
	end

	-- Unlock and auto-equip new title milestone (10 Rookie, 15 Starter, 50 Captain, 100 Legend)
	local newlyUnlockedTitle = syncUnlockedTitles(profile)
	if newlyUnlockedTitle then
		profile.EquippedTitle = newlyUnlockedTitle
	end

	local unlockToast = if newlyUnlockedTitle then `🏷️ Title Unlocked: {newlyUnlockedTitle}!` else nil
	syncLeaderstats(player, profile, unlockToast)
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
	if itemKey == "starter_pack" then
		grantBux(player, profile, 500)
		profile.OwnedChairs["crimson"] = true
		profile.EquippedChair = "crimson"
		profile.StarterPackOwned = true
		dirtyProfiles[player] = true
		player:SetAttribute("EquippedChair", "crimson")
		syncLeaderstats(player, profile, "Starter Pack Unlocked: +$500 Bux & Crimson Chair!")
		return true
	elseif itemKey == "skip_daily" then
		profile.LastDailyClaim = 0
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "Daily Cooldown Skipped! Ready to claim.")
		return true
	elseif itemKey == "claim_all_daily" then
		for dayIdx = 1, #GameConfig.DAILY_REWARDS do
			local reward = GameConfig.DAILY_REWARDS[dayIdx]
			if reward.bux > 0 then
				grantBux(player, profile, reward.bux)
			end
			if reward.spins > 0 then
				profile.WheelSpins += reward.spins
			end
			if reward.chair then
				profile.OwnedChairs[reward.chair] = true
				profile.EquippedChair = reward.chair
			end
		end
		profile.DailyDay = 1
		profile.LastDailyClaim = Workspace:GetServerTimeNow()
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "All 7 Daily Rewards Claimed Instantly!")
		return true
	elseif itemKey == "2x_luck" then
		profile.DoubleLuck = true
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "2x Luck Gamepass Activated: 2x Legendary Player Luck!")
		return true
	elseif itemKey == "vip" then
		profile.VIP = true
		profile.DoubleBux = true
		profile.OwnedChairs["vip_black_diamond"] = true
		profile.EquippedChair = "vip_black_diamond"
		player:SetAttribute("IsVIP", true)
		player:SetAttribute("EquippedChair", "vip_black_diamond")
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "VIP Activated: Black Diamond VIP Chair + 2x Bux!")
		return true
	elseif itemKey == "2x_bux" then
		profile.DoubleBux = true
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "2x Bux Gamepass Activated: 2x Bux from Games!")
		return true
	elseif itemKey == "2x_wins" then
		profile.DoubleWins = true
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "2x Wins Gamepass Activated: Double Wins!")
		return true
	elseif itemKey == "2x_streak" then
		profile.DoubleStreak = true
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "2x Streak Gamepass Activated: Double Win Streak!")
		return true
	elseif itemKey == "inf_rerolls" then
		profile.InfRerolls = true
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "Infinite Rerolls Activated: Free Rerolls Forever!")
		return true
	elseif itemKey == "bux_300" then
		grantBux(player, profile, 300)
		syncLeaderstats(player, profile, "+$300 Bux Added!")
		return true
	elseif itemKey == "bux_1000" then
		grantBux(player, profile, 1000)
		syncLeaderstats(player, profile, "+$1,000 Bux Added!")
		return true
	elseif itemKey == "bux_4000" then
		grantBux(player, profile, 4000)
		syncLeaderstats(player, profile, "+$4,000 Bux Added!")
		return true
	elseif itemKey == "bux_15000" then
		grantBux(player, profile, 15000)
		syncLeaderstats(player, profile, "+$15,000 Bux Added!")
		return true
	elseif itemKey == "spin_1" or itemKey == "spin_5" or itemKey == "spin_10" then
		local item = (GameConfig.MONETIZATION :: any)[itemKey]
		local count = if item and item.spins then item.spins else 1
		profile.WheelSpins += count
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, `🎡 +{count} Wheel Spin{if count > 1 then "s" else ""} Added!`)
		return true
	elseif itemKey == "spin_first_offer" then
		profile.LastFirstSpinOfferDay = math.floor(os.time() / 86400)
		profile.WheelSpins += 1
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, "🎡 First Spin of Day (83% Off) Claimed! +1 Spin!")
		return true
	end
	return false
end

ProfileService.grantShopItem = grantShopItem

local matchProductHandler: ((player: Player, itemKey: string) -> boolean)? = nil

function ProfileService.setMatchProductHandler(handler: (player: Player, itemKey: string) -> boolean)
	matchProductHandler = handler
end

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
			grantBux(player, profile, reward.bux)
		end
		if reward.spins > 0 then
			profile.WheelSpins += reward.spins
		end
		if reward.chair then
			profile.OwnedChairs[reward.chair] = true
			profile.EquippedChair = reward.chair
		end
		dirtyProfiles[player] = true
		syncLeaderstats(player, profile, `Claimed Day {dayIdx}: {reward.label}!`)
		return
	end

	if action == "ClaimGroup" then
		if profile.GroupClaimed then
			return
		end
		profile.GroupClaimed = true
		grantBux(player, profile, GameConfig.GROUP_REWARD_BUX)
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
				grantBux(player, profile, entry.bux)
				profile.WheelSpins += entry.spins
				if entry.chair then
					profile.OwnedChairs[entry.chair] = true
					profile.EquippedChair = entry.chair
				end
				dirtyProfiles[player] = true
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
				grantBux(player, profile, q.bux)
				profile.WheelSpins += q.spins
				dirtyProfiles[player] = true
				syncLeaderstats(player, profile, `Quest Complete: {q.rewardLabel}!`)
				return
			end
		end
		return
	end

	if action == "EquipTitle" and typeof(arg) == "string" then
		for _, entry in GameConfig.TITLES do
			if entry.name == arg then
				if isTitleUnlocked(profile, entry) then
					profile.UnlockedTitles[entry.name] = true
					profile.EquippedTitle = entry.name
					dirtyProfiles[player] = true
					syncLeaderstats(player, profile, `Equipped Title: {entry.name}`)
				else
					syncLeaderstats(player, profile, `🔒 Need {entry.minWins} Wins to unlock {entry.name}!`)
				end
				return
			end
		end
		return
	end

	if action == "BuyOrEquipChair" and typeof(arg) == "string" then
		for _, skin in GameConfig.CHAIR_SKINS do
			if skin.id == arg then
				local owned = profile.OwnedChairs[skin.id] or (skin.unlockSource == "VIP" and profile.VIP == true)
				if owned then
					profile.OwnedChairs[skin.id] = true
					profile.EquippedChair = skin.id
					syncLeaderstats(player, profile, `Equipped {skin.name} Chair!`)
				elseif not skin.unlockSource and profile.Bux >= skin.cost then
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
			syncLeaderstats(player, profile, "🎡 No spins left! Play matches or get +5/+10 Spins!")
			return
		end
		profile.WheelSpins -= 1
		local totalWeight = 0
		for _, seg in GameConfig.WHEEL_SEGMENTS do
			totalWeight += seg.weight
		end
		local roll = math.random() * totalWeight
		local acc = 0
		local chosen = GameConfig.WHEEL_SEGMENTS[#GameConfig.WHEEL_SEGMENTS]
		for _, seg in GameConfig.WHEEL_SEGMENTS do
			acc += seg.weight
			if roll <= acc then
				chosen = seg
				break
			end
		end
		local resultToast = chosen.toast
		if chosen.bux and chosen.bux > 0 then
			grantBux(player, profile, chosen.bux)
		end
		if chosen.spins and chosen.spins > 0 then
			profile.WheelSpins += chosen.spins
		end
		if chosen.chair then
			if profile.OwnedChairs[chosen.chair] then
				local fallbackBux = chosen.dupBux or 100
				if fallbackBux > 0 then
					grantBux(player, profile, fallbackBux)
					resultToast = `🎡 Already owned {chosen.oddsName}! +${fallbackBux} Bux!`
				end
			else
				profile.OwnedChairs[chosen.chair] = true
				profile.EquippedChair = chosen.chair
				player:SetAttribute("EquippedChair", chosen.chair)
			end
		end
		dirtyProfiles[player] = true
		local nextSeq = ((player:GetAttribute("WheelSpinSeq") :: number?) or 0) + 1
		player:SetAttribute("LastWheelSlice", chosen.id)
		player:SetAttribute("WheelSpinSeq", nextSeq)
		syncLeaderstats(player, profile, resultToast)
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
		-- Prevent re-purchasing unique permanent perks if already owned
		if arg == "starter_pack" and (profile.StarterPackOwned or (profile.OwnedChairs and profile.OwnedChairs["crimson"])) then
			syncLeaderstats(player, profile, "You already own the Starter Pack!")
			return
		end
		if arg == "vip" and profile.VIP then
			syncLeaderstats(player, profile, "You already own VIP!")
			return
		end
		if arg == "2x_bux" and profile.DoubleBux then
			syncLeaderstats(player, profile, "You already own 2x Bux!")
			return
		end
		if arg == "2x_wins" and profile.DoubleWins then
			syncLeaderstats(player, profile, "You already own 2x Wins!")
			return
		end
		if arg == "2x_streak" and profile.DoubleStreak then
			syncLeaderstats(player, profile, "You already own 2x Streak!")
			return
		end
		if arg == "2x_luck" and profile.DoubleLuck then
			syncLeaderstats(player, profile, "You already own 2x Luck!")
			return
		end
		if arg == "inf_rerolls" and profile.InfRerolls then
			syncLeaderstats(player, profile, "You already own Infinite Rerolls!")
			return
		end
		if arg == "spin_first_offer" and (profile.LastFirstSpinOfferDay or 0) == math.floor(os.time() / 86400) then
			syncLeaderstats(player, profile, "You already claimed today's 83% Off Spin!")
			return
		end

		if item.id and item.id > 0 then
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

local function flushPlayerProfile(player: Player, removeAfter: boolean)
	local profile = profiles[player]
	if removeAfter then
		profiles[player] = nil
		dirtyProfiles[player] = nil
		feedbackCooldowns[player] = nil
		updateStreakKing()
	end
	if profile then
		local now = Workspace:GetServerTimeNow()
		local elapsed = math.max(0, math.floor(now - profile.SessionJoinTime))
		profile.PlaytimeSeconds = math.max(0, math.floor(profile.PlaytimeSeconds or 0)) + elapsed
		profile.SessionJoinTime = now
		if not removeAfter then
			player:SetAttribute("SessionStart", now)
		end
		dirtyProfiles[player] = nil
		if store and player.UserId > 0 then
			pcall(function()
				(store :: DataStore):SetAsync(`Player_{player.UserId}`, profile)
			end)
		end
	end
end

local function loadPlayer(player: Player)
	local data = defaultProfile()
	local hadSavedData = false
	if store and player.UserId > 0 then
		local ok, saved = pcall(function()
			return (store :: DataStore):GetAsync(`Player_{player.UserId}`)
		end)
		if ok and typeof(saved) == "table" then
			hadSavedData = true
			for k, v in saved do
				if data[k] ~= nil and typeof(v) == typeof(data[k]) then
					(data :: any)[k] = v
				end
			end
		end
	end
	if not hadSavedData and data.FirstJoinedAt == 0 then
		data.FirstJoinedAt = os.time()
	end
	data.BestStreak = math.max(data.BestStreak or 0, data.Streak or 0)
	data.TotalCashEarned = math.max(data.TotalCashEarned or 0, data.Bux or 0)
	refreshWinBuckets(data)
	if data.LatestCardId ~= "" and not Footballers.ById[data.LatestCardId] then
		data.LatestCardId = ""
	end
	if data.RarestCardId == "" or not Footballers.ById[data.RarestCardId] then
		data.RarestCardId = ""
		local bestCard: Footballers.Footballer? = nil
		for cardId, owned in data.DiscoveredCards do
			local c = if owned then Footballers.ById[cardId] else nil
			if c and isRarerCard(c, bestCard) then
				bestCard = c
			end
		end
		if bestCard then
			data.RarestCardId = bestCard.id
		end
	end
	data.SessionJoinTime = Workspace:GetServerTimeNow()
	data.PlaytimeClaimed = {}
	syncUnlockedTitles(data)
	data.OwnedChairs["wood"] = true
	if data.OwnedChairs["emerald"] and not data.OwnedChairs["crimson"] then
		data.OwnedChairs["crimson"] = true
	end
	if data.EquippedChair == "emerald" then
		data.EquippedChair = "crimson"
	end
	if data.OwnedChairs["cyber"] and not data.OwnedChairs["frostbite"] then
		data.OwnedChairs["frostbite"] = true
	end
	if data.EquippedChair == "cyber" then
		data.EquippedChair = "frostbite"
	end
	if data.OwnedChairs["clover"] and not data.OwnedChairs["lucky_clover"] then
		data.OwnedChairs["lucky_clover"] = true
	end
	if data.EquippedChair == "clover" then
		data.EquippedChair = "lucky_clover"
	end
	if data.VIP or data.OwnedChairs["vip"] then
		data.OwnedChairs["vip_black_diamond"] = true
	end
	if data.EquippedChair == "vip" then
		data.EquippedChair = "vip_black_diamond"
	end
	if not player:IsDescendantOf(Players) then
		return
	end
	profiles[player] = data
	syncLeaderstats(player, data)
	LeaderboardService.seedPlayerOnJoin(player, data.Wins, data.BestStreak, data.TotalCashEarned, data.PlaytimeSeconds)

	-- Verify owned permanent GamePasses asynchronously on join (never auto-grant consumables on rejoin)
	local permanentPassKeys = {
		starter_pack = true,
		vip = true,
		["2x_bux"] = true,
		["2x_wins"] = true,
		["2x_streak"] = true,
		["2x_luck"] = true,
		inf_rerolls = true,
	}
	task.spawn(function()
		if player.UserId <= 0 then
			return
		end
		for key, item in GameConfig.MONETIZATION :: any do
			if permanentPassKeys[key] and item.kind == "GamePass" and item.id and item.id > 0 then
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item.id)
				end)
				if ok and owns and profiles[player] then
					grantShopItem(player, key)
				end
			end
		end
	end)
end

local function saveAndRemovePlayer(player: Player)
	flushPlayerProfile(player, true)
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
				if key == "match_reroll" or key == "match_reveal_all" or key == "match_see_best" or key == "match_steal" then
					if matchProductHandler then
						matchProductHandler(player, key)
					end
				else
					grantShopItem(player, key)
				end
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
				if key == "match_reroll" or key == "match_reveal_all" or key == "match_see_best" or key == "match_steal" then
					if matchProductHandler and matchProductHandler(player, key) then
						return Enum.ProductPurchaseDecision.PurchaseGranted
					end
					return Enum.ProductPurchaseDecision.NotProcessedYet
				elseif grantShopItem(player, key) then
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
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL_SEC)
			for player in dirtyProfiles do
				if profiles[player] then
					local okBudget, budget = pcall(function()
						return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)
					end)
					if not okBudget or (budget and budget >= 2) then
						flushPlayerProfile(player, false)
					end
				end
			end
		end
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			saveAndRemovePlayer(player)
		end
	end)
end

return table.freeze(ProfileService)

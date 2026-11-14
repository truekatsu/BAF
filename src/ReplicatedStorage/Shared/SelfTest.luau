--!strict
--[[
	SelfTest
	Responsibility: Assert-based self-checks for the 150-player Footballers pool, 3D FootballerModelBuilder, and MatchLogic rules.
	Loop step: n/a (verification)
	Location: ReplicatedStorage/Shared/SelfTest (ModuleScript)
]]

local GameConfig = require(script.Parent.GameConfig)
local Footballers = require(script.Parent.Footballers)
local FootballerModelBuilder = require(script.Parent.FootballerModelBuilder)
local MatchLogic = require(script.Parent.MatchLogic)
local Remotes = require(script.Parent.Remotes)

local SelfTest = {}

function SelfTest.run()
	local rng = Random.new(42)

	-- 1. Pool & Rarity distribution check (150 total = 25 Common, 35 Uncommon, 40 Rare, 30 Epic, 14 Legend, 6 Mythic)
	assert(#Footballers.All == 150, `Expected 150 footballers, got {#Footballers.All}`)
	assert(#Footballers.ByRarity.Mythic == 6, `Expected 6 Mythic, got {#Footballers.ByRarity.Mythic}`)
	assert(Footballers.ById["messi"] ~= nil and Footballers.ById["ronaldo"] ~= nil, "Messi and Ronaldo must exist in Mythic")
	assert(#Footballers.ByRarity.Legend == 14, `Expected 14 Legend, got {#Footballers.ByRarity.Legend}`)
	assert(#Footballers.ByRarity.Epic == 30, `Expected 30 Epic, got {#Footballers.ByRarity.Epic}`)
	assert(#Footballers.ByRarity.Rare == 40, `Expected 40 Rare, got {#Footballers.ByRarity.Rare}`)
	assert(#Footballers.ByRarity.Uncommon == 35, `Expected 35 Uncommon, got {#Footballers.ByRarity.Uncommon}`)
	assert(#Footballers.ByRarity.Common == 25, `Expected 25 Common, got {#Footballers.ByRarity.Common}`)

	local seenIds: { [string]: boolean } = {}
	for _, card in Footballers.All do
		assert(not seenIds[card.id], `Duplicate footballer id: {card.id}`)
		seenIds[card.id] = true
		assert(#card.name >= 4 and not string.find(card.name, "^%u%. "), `Expected full real name on {card.id}, got {card.name}`)
		assert(#card.country >= 4, `Expected full country name on {card.id}, got {card.country}`)
		assert(Footballers.CLUB_KITS[card.club] ~= nil, `Missing real club kit for {card.club} on {card.id}`)
		assert(card.skin >= 1 and card.skin <= 7, `Invalid skin index on {card.id}`)
		assert(Footballers.getDisplayName(card) == card.name, `getDisplayName must return real name for {card.id}`)
		for _, attr in GameConfig.ATTRIBUTES do
			local v = (card.stats :: any)[attr]
			assert(typeof(v) == "number" and v >= 1 and v <= 99, `Invalid stat {attr} on {card.id}`)
		end
	end

	-- 1b. 3D FootballerModelBuilder check (skin, hair, club shirt + shorts)
	for _, sampleId in { "saliba", "haaland", "messi", "osimhen", "courtois" } do
		local sampleCard = Footballers.ById[sampleId]
		assert(sampleCard ~= nil, `Missing sample card {sampleId}`)
		local mdl = FootballerModelBuilder.buildModel(sampleCard)
		assert(mdl:FindFirstChild("Head") ~= nil, `Missing Head on 3D model {sampleId}`)
		assert(mdl:FindFirstChild("Torso") ~= nil, `Missing Torso shirt on 3D model {sampleId}`)
		assert(mdl:FindFirstChild("ShortsL") ~= nil and mdl:FindFirstChild("ShortsR") ~= nil, `Missing Shorts on 3D model {sampleId}`)
		assert(mdl:FindFirstChild("Hair") ~= nil, `Missing Hair on 3D model {sampleId}`)
		mdl:Destroy()
	end

	-- 2. PRD 3.3 verification: Haaland in DEF = 45, in SHO = 93
	local haaland = Footballers.ById["haaland"]
	assert(haaland ~= nil, "Haaland must exist in pool")
	assert(haaland.stats.DEF == 45 and haaland.stats.SHO == 93, "Haaland stat mismatch")

	assert(GameConfig.DEFAULT_REROLLS == 1, "Default free rerolls per match must be 1")
	assert(GameConfig.DEFAULT_STEALS == 0, "Default free steals per match must be 0")
	assert(GameConfig.MONETIZATION.match_reroll.id == 3730644846 and GameConfig.MONETIZATION.match_reroll.kind == "Product", "match_reroll product ID mismatch")
	assert(GameConfig.MONETIZATION.match_reveal_all.id == 3730644905 and GameConfig.MONETIZATION.match_reveal_all.kind == "Product", "match_reveal_all product ID mismatch")
	assert(GameConfig.MONETIZATION.match_see_best.id == 3730644938 and GameConfig.MONETIZATION.match_see_best.kind == "Product", "match_see_best product ID mismatch")
	assert(GameConfig.MONETIZATION.match_steal.id == 3730644975 and GameConfig.MONETIZATION.match_steal.kind == "Product", "match_steal product ID mismatch")

	-- 3. Board creation, SeeBest, Place, and Reroll
	local boardA = MatchLogic.createBoard(2, 1, 1, false, rng)
	local boardB = MatchLogic.createBoard(2, 1, 1, false, rng)
	boardA.currentRoll = haaland
	local bestForHaaland = MatchLogic.getBestSlot(boardA, haaland)
	assert(bestForHaaland == "SHO", "Haaland best slot should be SHO (93)")

	assert(MatchLogic.placeInSlot(boardA, "SHO", rng) == true, "Should place Haaland in SHO")
	assert(boardA.slots.SHO == haaland, "SHO slot must hold Haaland")
	assert(MatchLogic.placeInSlot(boardA, "SHO", rng) == false, "Cannot overwrite filled slot")

	local beforeRerolls = boardA.rerollsLeft
	assert(MatchLogic.reroll(boardA, rng) == true, "Should allow reroll when rerollsLeft > 0")
	assert(boardA.rerollsLeft == beforeRerolls - 1, "Reroll must decrement rerollsLeft")

	-- 4. Steal rule: B steals Haaland from A's SHO slot
	assert(MatchLogic.stealSlot(boardB, boardA, "SHO", "SHO", rng) == true, "Steal must succeed on filled opponent slot")
	assert(boardB.slots.SHO == haaland, "Victim card must move to thief slot")
	assert(boardA.slots.SHO == nil, "Victim slot must become empty after steal")
	assert(boardB.stealsLeft == 0, "Steal count must decrement")
	assert(MatchLogic.stealSlot(boardB, boardA, "SHO", "PAC", rng) == false, "Cannot steal with 0 stealsLeft")

	-- 5. Showdown & Grade evaluation
	MatchLogic.autoFillRemaining(boardA, rng)
	MatchLogic.autoFillRemaining(boardB, rng)
	assert(MatchLogic.isBoardFull(boardA) and MatchLogic.isBoardFull(boardB), "Boards must be full after autoFill")

	local res = MatchLogic.resolveShowdown(boardA, boardB, rng)
	assert(res.winner == "A" or res.winner == "B", "Showdown must produce a winner")
	assert(res.evalA.avgScore > 0 and res.evalB.avgScore > 0, "Average scores must be positive")
	assert(GameConfig.getGrade(92) == "S" and GameConfig.getGrade(85) == "A" and GameConfig.getGrade(55) == "D", "Grade thresholds mismatch")

	-- 5a. Bot adaptive optimalChance places card in getBestSlot when optimalChance = 1
	local botBoard = MatchLogic.createBoard(2, 0, 1, false, rng)
	local humanBoard = MatchLogic.createBoard(2, 0, 1, false, rng)
	local expectedBest = MatchLogic.getBestSlot(botBoard)
	MatchLogic.stepBot(botBoard, humanBoard, rng, 1)
	assert(expectedBest ~= nil and botBoard.slots[expectedBest] ~= nil, "stepBot with optimalChance=1 must pick best slot")

	-- 5b. No-repeat footballers within 1 match session, resetting in next session & on full-pool exhaustion
	local sessionUsed: { [string]: boolean } = {}
	local sBoardA = MatchLogic.createBoard(10, 1, 1, true, rng, sessionUsed)
	local sBoardB = MatchLogic.createBoard(10, 1, 1, true, rng, sessionUsed)
	local seenInMatch: { [string]: boolean } = {}
	local function assertUniqueRoll(card: MatchLogic.Footballer?)
		assert(card ~= nil, "Expected a rolled footballer")
		assert(not seenInMatch[(card :: MatchLogic.Footballer).id], `Duplicate footballer {(card :: MatchLogic.Footballer).id} in same session`)
		seenInMatch[(card :: MatchLogic.Footballer).id] = true
	end
	assertUniqueRoll(sBoardA.currentRoll)
	assertUniqueRoll(sBoardB.currentRoll)
	for _, attr in GameConfig.ATTRIBUTES do
		assert(MatchLogic.reroll(sBoardA, rng), "Reroll A should succeed")
		assertUniqueRoll(sBoardA.currentRoll)
		assert(MatchLogic.placeInSlot(sBoardA, attr, rng), "Place A should succeed")
		if sBoardA.currentRoll then
			assertUniqueRoll(sBoardA.currentRoll)
		end
		assert(MatchLogic.reroll(sBoardB, rng), "Reroll B should succeed")
		assertUniqueRoll(sBoardB.currentRoll)
		assert(MatchLogic.placeInSlot(sBoardB, attr, rng), "Place B should succeed")
		if sBoardB.currentRoll then
			assertUniqueRoll(sBoardB.currentRoll)
		end
	end
	-- Exhaust remaining cards up to 150 and verify pool resets cleanly on 151st roll
	local totalUnique = 0
	for _ in seenInMatch do
		totalUnique += 1
	end
	for _ = totalUnique + 1, #Footballers.All do
		local c = MatchLogic.rollFootballer(1, rng, sessionUsed)
		assertUniqueRoll(c)
	end
	local wrapCard = MatchLogic.rollFootballer(1, rng, sessionUsed)
	assert(wrapCard ~= nil, "151st roll must succeed after pool reset")
	-- Next session with fresh usedIds starts clean
	local nextUsed: { [string]: boolean } = {}
	local nextBoard = MatchLogic.createBoard(2, 1, 1, false, rng, nextUsed)
	assert(nextBoard.currentRoll ~= nil, "New session board must roll a footballer")

	-- 6. Meta progression config checks (Daily, Playtime, Quests, Chair Skins)
	assert(#GameConfig.DAILY_REWARDS == 7, "Must have 7 daily rewards")
	assert(#GameConfig.PLAYTIME_REWARDS == 6, "Must have 6 playtime rewards")
	assert(#GameConfig.QUESTS == 3, "Must have 3 daily quests")
	assert(#GameConfig.CHAIR_SKINS == 8, "Must have 8 chair skins")
	assert(GameConfig.CHAIR_SKINS[5].id == "frostbite" and GameConfig.CHAIR_SKINS[6].id == "golden", "Frostbite and Football Throne must occupy slots 5-6")
	assert(GameConfig.CHAIR_SKINS[7].id == "lucky_clover" and GameConfig.CHAIR_SKINS[8].id == "vip_black_diamond", "Lucky Clover and Black Diamond VIP must occupy slots 7-8 below Throne")
	assert(GameConfig.getChairSkin("frostbite").name == "Frostbite Chair" and GameConfig.getChairSkin("frostbite").cost == 10000, "Frostbite Chair must exist and cost 10000 Bux")
	assert(GameConfig.getChairSkin("golden").name == "Football Throne" and GameConfig.getChairSkin("golden").cost == 15000, "Football Throne must exist and cost 15000 Bux")
	assert(GameConfig.getChairSkin("football_throne").id == "golden", "football_throne alias must resolve to Football Throne")
	assert(GameConfig.getChairSkin("royal").id == "golden", "royal alias must resolve to Football Throne")
	assert(GameConfig.getChairSkin("vip_black_diamond").name == "Black Diamond VIP" and GameConfig.getChairSkin("vip_black_diamond").unlockSource == "VIP", "Black Diamond VIP must exist and require VIP")
	assert(GameConfig.getChairSkin("vip").id == "vip_black_diamond", "vip alias must resolve to Black Diamond VIP")
	assert(GameConfig.getChairSkin("cyber_core").name == "Cyber Core Chair" and GameConfig.getChairSkin("cyber_core").cost == 3500, "Cyber Core Chair must exist and cost 3500 Bux")
	assert(GameConfig.getChairSkin("crimson").name == "Crimson Chair" and GameConfig.getChairSkin("crimson").cost == 6000, "Crimson Chair must exist and cost 6000 Bux")
	assert(GameConfig.getChairSkin("emerald").name == "Crimson Chair", "emerald alias must resolve to Crimson Chair")
	assert(GameConfig.getChairSkin("lucky_clover").name == "Lucky Clover Chair" and GameConfig.getChairSkin("lucky_clover").unlockSource == "JACKPOT", "Lucky Clover Chair must exist as JACKPOT reward")
	assert(GameConfig.getChairSkin("clover").id == "lucky_clover", "clover alias must resolve to Lucky Clover Chair")
	assert(GameConfig.WHEEL_SEGMENTS[3].chair == "lucky_clover", "Wheel Jackpot segment must reward lucky_clover")
	assert(GameConfig.DAILY_REWARDS[7].chair == nil, "Day 7 daily reward must not grant a chair until its model is ready")
	assert(GameConfig.getChairSkin("cyber").name == "Frostbite Chair", "cyber alias must resolve to Frostbite Chair")
	assert(GameConfig.getChairSkin("nonexistent").id == "wood", "getChairSkin must fallback to wood")
	assert(GameConfig.MONETIZATION.vip ~= nil, "MONETIZATION table must define vip")
	local nextLuck = GameConfig.getNextLuckTier(1)
	assert(nextLuck ~= nil and nextLuck.luck == 1.5 and nextLuck.cost == 750, "Next luck tier after 1x should be 1.5x for 750 Bux")
	assert(GameConfig.getNextLuckTier(5) == nil, "5x should be max luck tier")
	assert(GameConfig.OBBY_COOLDOWN_SEC == 14400 and GameConfig.OBBY_REWARD_BUX == 500, "Obby cooldown must be 4 hours (14400s) for 500 Bux")
	assert(GameConfig.OPPONENT_ALERT_DELAY_SEC == 3, "Opponent alert delay must be 3s")
	assert(#GameConfig.WHEEL_SEGMENTS == 8, "Spin wheel must have 8 slices")
	local totalWheelWeight = 0
	for _, seg in GameConfig.WHEEL_SEGMENTS do
		totalWheelWeight += seg.weight
		assert(typeof(seg.oddsName) == "string" and typeof(seg.oddsPct) == "string", "Wheel segment must define oddsName and oddsPct")
		assert(typeof(seg.spins) == "number" and typeof(seg.bux) == "number", "Wheel segment must define spins and bux")
	end
	assert(math.abs(totalWheelWeight - 100) < 1e-6, `Expected wheel weight sum 100, got {totalWheelWeight}`)
	assert(GameConfig.MONETIZATION.spin_5 ~= nil and GameConfig.MONETIZATION.spin_10 ~= nil and GameConfig.MONETIZATION.spin_first_offer ~= nil, "MONETIZATION must define spin wheel products")
	assert(GameConfig.MONETIZATION.spin_5.id == 3730644808 and GameConfig.MONETIZATION.spin_5.kind == "Product" and GameConfig.MONETIZATION.spin_5.spins == 5, "spin_5 product mismatch")
	assert(GameConfig.MONETIZATION.spin_10.id == 3730644744 and GameConfig.MONETIZATION.spin_10.kind == "Product" and GameConfig.MONETIZATION.spin_10.spins == 10, "spin_10 product mismatch")
	assert(GameConfig.MONETIZATION.skip_daily.id == 3730808261 and GameConfig.MONETIZATION.skip_daily.kind == "Product" and GameConfig.MONETIZATION.skip_daily.robux == 11, "skip_daily product mismatch")
	assert(GameConfig.MONETIZATION.claim_all_daily.id == 3730808299 and GameConfig.MONETIZATION.claim_all_daily.kind == "Product" and GameConfig.MONETIZATION.claim_all_daily.robux == 29, "claim_all_daily product mismatch")
	assert(Remotes.OpponentAlert ~= nil, "OpponentAlert RemoteEvent must exist")
	assert(GameConfig.getTitleColor("Legend") == Color3.fromHex("#FFD21F"), "Legend title color must be gold")
	assert(GameConfig.getTitleColor("Captain") == Color3.fromHex("#A855F7"), "Captain title color must be purple")
	assert(GameConfig.getTitleForWins(0) == "Benchwarmer" and GameConfig.getTitleForWins(9) == "Benchwarmer", "0-9 wins must resolve to Benchwarmer")
	assert(GameConfig.getTitleForWins(10) == "Rookie" and GameConfig.getTitleForWins(14) == "Rookie", "10-14 wins must resolve to Rookie")
	assert(GameConfig.getTitleForWins(15) == "Starter" and GameConfig.getTitleForWins(49) == "Starter", "15-49 wins must resolve to Starter")
	assert(GameConfig.getTitleForWins(50) == "Captain" and GameConfig.getTitleForWins(99) == "Captain", "50-99 wins must resolve to Captain")
	assert(GameConfig.getTitleForWins(100) == "Legend", "100+ wins must resolve to Legend")
	assert(GameConfig.formatPlaytime(234000) == "2d 17h", "Playtime day/hour format mismatch")
	assert(GameConfig.formatPlaytime(80160) == "22h 16m", "Playtime hour/min format mismatch")
	assert(GameConfig.formatPlaytime(45) == "45s", "Playtime seconds format mismatch")
	assert(Remotes.FeedbackSync ~= nil, "FeedbackSync RemoteEvent must exist")

	-- 6. CenterHubConfig verification
	local CenterHubConfig = require(script.Parent:WaitForChild("CenterHubConfig"))
	assert(CenterHubConfig.CENTER_CIRCLE_DIAMETER == 60, "Center circle diameter must be 60 studs")
	assert(CenterHubConfig.TIER_1.Radius == 12 and CenterHubConfig.TIER_1.Height == 2, "Tier 1 must be r=12, h=2")
	assert(CenterHubConfig.TIER_2.Radius == 7 and CenterHubConfig.TIER_2.Height == 4, "Tier 2 must be r=7, h=4")
	assert(CenterHubConfig.BILLBOARD.MaxDistance == 120, "Billboard MaxDistance must be 120")

	-- 7. TableBillboardConfig verification
	local TableBillboardConfig = require(script.Parent:WaitForChild("TableBillboardConfig"))
	assert(TableBillboardConfig.BASE_SIZE.X == 10 and TableBillboardConfig.BASE_SIZE.Y == 5, "Billboard base size must be 10x5 studs")
	assert(TableBillboardConfig.MAX_DISTANCE == 90, "MaxDistance must be 90 studs")
	assert(TableBillboardConfig.THROTTLE_RATE_HZ == 5, "Throttle rate must be 5 Hz")
	assert(TableBillboardConfig.HOVER_DISTANCE == 14, "Hover distance must be 14 studs")

	-- 8. TableRig Prefab verification
	local prefabsFolder = script.Parent.Parent:FindFirstChild("Prefabs")
	local TableRigBuilder = prefabsFolder and require(prefabsFolder:WaitForChild("TableRigBuilder"))
	if TableRigBuilder then
		local testRig = TableRigBuilder.buildPrefab()
		assert(testRig:FindFirstChild("SeatA") ~= nil and testRig:FindFirstChild("SeatB") ~= nil, "TableRig must have SeatA and SeatB")
		assert(testRig:FindFirstChild("CameraAnchorA") ~= nil and testRig:FindFirstChild("CameraAnchorB") ~= nil, "TableRig must have CameraAnchorA and CameraAnchorB")
		assert(testRig.PrimaryPart ~= nil and testRig.PrimaryPart.Name == "TableTop", "PrimaryPart must be TableTop")
		assert(testRig.PrimaryPart:FindFirstChild("BillboardAnchor") ~= nil, "TableTop must contain BillboardAnchor attachment")
		testRig:Destroy()
	end

	-- 9. PlayerTunnelConfig verification
	local PlayerTunnelConfig = require(script.Parent:WaitForChild("PlayerTunnelConfig"))
	assert(PlayerTunnelConfig.OPENING_WIDTH == 16 and PlayerTunnelConfig.OPENING_HEIGHT == 12, "Tunnel opening must be 16x12")
	assert(PlayerTunnelConfig.TUNNEL_DEPTH == 24, "Tunnel depth must be 24 studs")
	assert(PlayerTunnelConfig.SPAWN_COUNT == 8, "Spawn count must be 8")
	assert(PlayerTunnelConfig.CAMERA_DURATION_SEC == 3, "Camera cinematic duration must be 3s")

	-- 10. LeaderboardConfig verification (P10 Leaderboard Readability & Placement)
	local LeaderboardConfig = require(script.Parent:WaitForChild("LeaderboardConfig"))
	assert(LeaderboardConfig.BOARD_SIZE.X >= 18 and LeaderboardConfig.BOARD_SIZE.Y >= 24, "Board size must be at least 18x24 studs")
	assert(LeaderboardConfig.PODIUM_HEIGHT == 4, "Podium height must be 4 studs")
	assert(LeaderboardConfig.ROW_COUNT >= 5 and LeaderboardConfig.ROW_COUNT <= 10, "Must display top rows")
	assert(LeaderboardConfig.ROW_HEIGHT_STUDS >= 3.2, "Row height must be at least 3.2 studs")
	assert(LeaderboardConfig.SPOTLIGHT_BRIGHTNESS == 1.5, "Spotlight brightness must be 1.5")
	assert(LeaderboardConfig.REFRESH_INTERVAL_SEC == 60, "Refresh interval must be 60s")
	for _, key in { "Bux", "Wins", "Streak", "Playtime" } do
		local b = LeaderboardConfig.BOARDS[key]
		assert(b ~= nil, `Missing board config for {key}`)
		local dist = (Vector3.new(b.position.X, 0, b.position.Z) - Vector3.new(0, 0, -42)).Magnitude
		assert(dist >= 40 and dist <= 80, `Board {key} distance {dist} outside 40-80 stud range`)
	end
	assert(LeaderboardConfig.SANITY_CAPS.Wins == 10, "Sanity cap for Wins must be 10/min")
	assert(LeaderboardConfig.SANITY_CAPS.Cash == 500000, "Sanity cap for Cash must be 500k/min")

	local LeaderboardBuilder = require(script.Parent:WaitForChild("LeaderboardBuilder"))
	assert(LeaderboardBuilder.formatValue(4, "Raw") == "4", "Raw format failed")
	assert(LeaderboardBuilder.formatValue(45, "Time") == "45s", "Time format seconds failed")
	assert(LeaderboardBuilder.formatValue(3665, "Time") == "1h 01m", "Time format hours failed")
	assert(LeaderboardBuilder.formatValue(1500, "Currency") == "$1.5K", "Currency format failed")

	-- 11. JumbotronConfig verification (P2 Jumbotron)
	local JumbotronConfig = require(script.Parent:WaitForChild("JumbotronConfig"))
	assert(JumbotronConfig.SCREEN_SIZE.X == 60 and JumbotronConfig.SCREEN_SIZE.Y == 28, "Screen size must be 60x28 studs")
	assert(JumbotronConfig.BRIGHTNESS == 1.5, "Screen Brightness must be 1.5")
	assert(#JumbotronConfig.PROMO_SLIDES >= 3, "Must have at least 3 promo slides")
	assert(JumbotronConfig.SKIN_ROTATION_INTERVAL_SEC == 600, "Skin rotation interval must be 600s (10 min)")
	local satState = JumbotronConfig.getWeekendEventState(os.time({ year = 2026, month = 11, day = 14, hour = 8, min = 0, sec = 0 }))
	assert(satState.active == true and satState.remainingSec == 40 * 3600, "Saturday 08:00 must be active with 40h remaining")
	local sunState = JumbotronConfig.getWeekendEventState(os.time({ year = 2026, month = 11, day = 15, hour = 22, min = 0, sec = 0 }))
	assert(sunState.active == true and sunState.remainingSec == 2 * 3600, "Sunday 22:00 must be active with 2h remaining")
	local monState = JumbotronConfig.getWeekendEventState(os.time({ year = 2026, month = 11, day = 16, hour = 0, min = 0, sec = 0 }))
	assert(monState.active == false and monState.remainingSec == 5 * 86400, "Monday 00:00 must be inactive with 5d remaining")
	local friState = JumbotronConfig.getWeekendEventState(os.time({ year = 2026, month = 11, day = 20, hour = 18, min = 0, sec = 0 }))
	assert(friState.active == false and friState.remainingSec == 6 * 3600, "Friday 18:00 must be inactive with 6h remaining")

	-- 12. VIPConfig verification (P4 VIP Lounge)
	local VIPConfig = require(script.Parent:WaitForChild("VIPConfig"))
	assert(VIPConfig.LOUNGE_SIZE.Y == 14, "Lounge height must be 14 studs")
	assert(VIPConfig.FLOOR_Y == 10, "Floor must be elevated 10 studs above pitch")
	assert(VIPConfig.DOOR_TWEEN_DURATION == 0.4, "Door tween duration must be 0.4s")
	assert(VIPConfig.SPARKLE_RATE == 3, "Sign sparkle rate must be 3/s")
	assert(VIPConfig.COLORS.GoldTrim ~= nil and VIPConfig.COLORS.RedCarpet ~= nil, "Colors must define GoldTrim and RedCarpet")

	-- 13. QuestObbyConfig verification (P5 Training Obby)
	local QuestObbyConfig = require(script.Parent:WaitForChild("QuestObbyConfig"))
	assert(QuestObbyConfig.MIN_DURATION_SEC == 20, "Min obby duration must be 20s anti-cheat")
	assert(QuestObbyConfig.CHECKPOINTS_COUNT == 3, "Must have 3 checkpoints")
	assert(QuestObbyConfig.MOVING_PLATFORM_SPEED == 8, "Moving platform speed must be 8 studs/s")
	assert(QuestObbyConfig.RESPAWN_Y == -20, "Soft respawn threshold must be Y=-20")
	assert(QuestObbyConfig.COLORS.ConeOrange ~= nil and QuestObbyConfig.COLORS.StartBlue ~= nil, "Colors must define ConeOrange and StartBlue")

	-- 14. StandsConfig verification (P9 Stand Variety & Sectors)
	local StandsConfig = require(script.Parent:WaitForChild("StandsConfig"))
	assert(#StandsConfig.SECTOR_ORDER == 8, "Must have 8 sectors A..H")
	assert(StandsConfig.SECTOR_COLORS.A == Color3.fromHex("#1E6FFF"), "Sector A must be Blue #1E6FFF")
	assert(StandsConfig.SECTOR_COLORS.B == Color3.fromHex("#E5252A"), "Sector B must be Red #E5252A")
	assert(StandsConfig.SECTOR_COLORS.C == Color3.fromHex("#FFD21F"), "Sector C must be Yellow #FFD21F")
	assert(StandsConfig.SECTOR_COLORS.D == Color3.fromHex("#3DDC3D"), "Sector D must be Green #3DDC3D")
	assert(StandsConfig.SECTOR_COLORS.E == Color3.fromHex("#A855F7"), "Sector E must be Purple #A855F7")
	assert(StandsConfig.SECTOR_COLORS.F == Color3.fromHex("#FF8A1F"), "Sector F must be Orange #FF8A1F")
	assert(StandsConfig.SECTOR_COLORS.G == Color3.fromHex("#19C2FF"), "Sector G must be Cyan #19C2FF")
	assert(StandsConfig.SECTOR_COLORS.H == Color3.fromHex("#FF2E93"), "Sector H must be Pink #FF2E93")
	assert(StandsConfig.SPECTATOR_PRIMARY_BIAS == 0.60, "Spectator bias must be 60%")
	assert(StandsConfig.SIGN_SIZE.X == 6 and StandsConfig.SIGN_SIZE.Y == 2, "Sign size must be 6x2 studs")

	-- 15. BannersConfig verification (P7 Banners, Generic Ads & Flags)
	local BannersConfig = require(script.Parent:WaitForChild("BannersConfig"))
	assert(BannersConfig.AD_BOARDS_COUNT == 24, "Must have 24 ad boards")
	assert(#BannersConfig.ADS == 8, "Must have 8 fictional ads")
	assert(BannersConfig.FLAGS_COUNT == 0 or BannersConfig.FLAGS_COUNT == 30, "Must have valid stand flags count")
	assert(BannersConfig.AD_ROTATION_SEC == 8, "Ad rotation interval must be 8s")
	assert(BannersConfig.MAIN_BANNER_SIZE.X == 40 and BannersConfig.MAIN_BANNER_SIZE.Y == 10, "Main banner must be 40x10 studs")
	assert(BannersConfig.MAIN_BANNER_TEXT == "BUILD A FOOTBALLER", "Main banner text mismatch")

	-- 16. GoalsConfig verification (P11 Interactive Goals)
	local GoalsConfig = require(script.Parent:WaitForChild("GoalsConfig"))
	assert(GoalsConfig.KICK_SPEED == 70.0, "Kick speed must be 70")
	assert(GoalsConfig.MIN_UP_ANGLE_DEG == 15.0 and GoalsConfig.MAX_UP_ANGLE_DEG == 35.0, "Up angle clamp must be 15-35 deg")
	assert(GoalsConfig.PLAYER_COOLDOWN_SEC == 2.0, "Cooldown must be 2s")
	assert(GoalsConfig.MAX_ACTIVE_BALLS == 5, "Max active balls must be 5")
	assert(GoalsConfig.TARGET_DIAMETER == 3.0, "Target diameter must be 3 studs")
	assert(GoalsConfig.NET_TRANSPARENCY == 0.4, "Net transparency must be 0.4")
	assert(GoalsConfig.GOALS.West ~= nil and GoalsConfig.GOALS.East ~= nil, "Must define West and East goals")
	assert(math.abs(GoalsConfig.GOALS.West.ballSpot.X - GoalsConfig.GOALS.West.goalLineX) == 18.0, "West spot must be 18 studs from line")
	assert(math.abs(GoalsConfig.GOALS.East.ballSpot.X - GoalsConfig.GOALS.East.goalLineX) == 18.0, "East spot must be 18 studs from line")
	assert(#GoalsConfig.GOALS.West.targets == 3 and #GoalsConfig.GOALS.East.targets == 3, "Each goal must have 3 targets")

	-- 17. AtmosphereConfig verification (P8 Atmosphere FX)
	local AtmosphereConfig = require(script.Parent:WaitForChild("AtmosphereConfig"))
	assert(AtmosphereConfig.FLAGS.ENABLE_AMBIENT_CONFETTI == true, "Ambient confetti flag must default true")
	assert(AtmosphereConfig.FLAGS.ENABLE_CROWD_WAVE == true, "Crowd wave flag must default true")
	assert(AtmosphereConfig.FLAGS.ENABLE_WIN_CELEBRATION == true, "Win celebration flag must default true")
	assert(AtmosphereConfig.FLAGS.ENABLE_AMBIENCE_AUDIO == true, "Ambience audio flag must default true")
	assert(AtmosphereConfig.AMBIENT_CONFETTI.PARTICLES_PER_BURST == 120, "Confetti burst must be 120 particles")
	assert(AtmosphereConfig.AMBIENT_CONFETTI.ACTIVE_EMITTERS_COUNT == 3, "Confetti must pick 3 emitters")
	assert(#AtmosphereConfig.AMBIENT_CONFETTI.COLORS == 6, "Confetti must have 6 bright colors")
	assert(AtmosphereConfig.CROWD_WAVE.INTERVAL_SEC == 60.0, "Crowd wave interval must be 60s")
	assert(AtmosphereConfig.WIN_CELEBRATION.BURST_COUNT == 3, "Win fireworks must have 3 bursts")
	assert(AtmosphereConfig.WIN_CELEBRATION.BURST_INTERVAL_SEC == 1.2, "Burst interval must be 1.2s")
	assert(AtmosphereConfig.WIN_CELEBRATION.MAX_PARTICLES_PER_BURST <= 200, "Max particles per burst must be <= 200")
	assert(AtmosphereConfig.WIN_CELEBRATION.MAX_DISTANCE_STUDS == 120.0, "Win celebration visible within 120 studs")
	assert(AtmosphereConfig.AUDIO.AMBIENT_LOOP.volume == 0.25, "Ambient loop volume must be 0.25")
	assert(#AtmosphereConfig.AUDIO.ONE_SHOTS == 3, "Must define 3 random one-shots")
end

return table.freeze(SelfTest)

--!strict
--[[
	SelfTest
	Responsibility: Assert-based self-checks for the 152-player Footballers pool, 3D FootballerModelBuilder, and MatchLogic rules.
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

	-- 1. Pool & Rarity distribution check (152 total = 65 Common, 45 Rare, 25 Epic, 12 Legendary, 5 Mythic)
	assert(#Footballers.All == 152, `Expected 152 footballers, got {#Footballers.All}`)
	assert(#Footballers.ByRarity.Mythic == 5, `Expected 5 Mythic, got {#Footballers.ByRarity.Mythic}`)
	assert(Footballers.ById["messi"] ~= nil and Footballers.ById["ronaldo"] ~= nil, "Messi and Ronaldo must exist in Mythic")
	assert(#Footballers.ByRarity.Legendary == 12, `Expected 12 Legendary, got {#Footballers.ByRarity.Legendary}`)
	assert(#Footballers.ByRarity.Epic == 25, `Expected 25 Epic, got {#Footballers.ByRarity.Epic}`)
	assert(#Footballers.ByRarity.Rare == 45, `Expected 45 Rare, got {#Footballers.ByRarity.Rare}`)
	assert(#Footballers.ByRarity.Common == 65, `Expected 65 Common, got {#Footballers.ByRarity.Common}`)

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

	-- 2. PRD 3.3 verification: Haaland in DEF = 60, in SHO = 96
	local haaland = Footballers.ById["haaland"]
	assert(haaland ~= nil, "Haaland must exist in pool")
	assert(haaland.stats.DEF == 60 and haaland.stats.SHO == 96, "Haaland stat mismatch")

	-- 3. Board creation, SeeBest, Place, and Reroll
	local boardA = MatchLogic.createBoard(2, 1, 1, false, rng)
	local boardB = MatchLogic.createBoard(2, 1, 1, false, rng)
	boardA.currentRoll = haaland
	local bestForHaaland = MatchLogic.getBestSlot(boardA, haaland)
	assert(bestForHaaland == "PAC" or bestForHaaland == "SHO", "Haaland best slot should be PAC or SHO (96)")

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

	-- 6. Meta progression config checks (Daily, Playtime, Quests, Chair Skins)
	assert(#GameConfig.DAILY_REWARDS == 7, "Must have 7 daily rewards")
	assert(#GameConfig.PLAYTIME_REWARDS == 6, "Must have 6 playtime rewards")
	assert(#GameConfig.QUESTS == 3, "Must have 3 daily quests")
	assert(#GameConfig.CHAIR_SKINS == 6, "Must have 6 chair skins")
	assert(GameConfig.getChairSkin("golden").id == "golden", "getChairSkin must find golden chair")
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
	end
	assert(totalWheelWeight == 100, `Expected wheel weight sum 100, got {totalWheelWeight}`)
	assert(Remotes.OpponentAlert ~= nil, "OpponentAlert RemoteEvent must exist")
	assert(GameConfig.getTitleColor("Legend") == Color3.fromHex("#FFD21F"), "Legend title color must be gold")
	assert(GameConfig.getTitleColor("Captain") == Color3.fromHex("#A855F7"), "Captain title color must be purple")
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

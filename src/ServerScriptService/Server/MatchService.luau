--!strict
--[[
	MatchService
	Responsibility: Table matchmaking (1v1 + 5-10s BOT fill), server-authoritative Build/Showdown/Result loop, and rate-limited remotes.
	Loop step: action | reward | reinvestment (rematch)
	Location: ServerScriptService/Server/MatchService (ModuleScript)
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Footballers = require(Shared:WaitForChild("Footballers"))
local MatchLogic = require(Shared:WaitForChild("MatchLogic"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local ProfileService = require(script.Parent.ProfileService)
local ChairModelBuilder = require(ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("ChairModelBuilder"))

export type Phase = "Idle" | "Waiting" | "Intro" | "Countdown" | "Build" | "Showdown" | "Result"

type TableSession = {
	id: string,
	model: Model,
	seatA: Seat,
	seatB: Seat,
	billboardLabel: TextLabel?,
	phase: Phase,
	subPhase: ("Rolling" | "Selecting")?,
	round: number,
	frozenTimer: number,
	roundEndsAt: number,
	placedThisRoundA: boolean,
	placedThisRoundB: boolean,
	roundRollA: Footballers.Footballer?,
	roundRollB: Footballers.Footballer?,
	playerA: Player?,
	playerB: Player?,
	isBot: boolean,
	botModel: Model?,
	boardA: MatchLogic.BoardState?,
	boardB: MatchLogic.BoardState?,
	phaseToken: number,
	rematchA: boolean,
	rematchB: boolean,
	humanInSeatB: boolean?,
}

local RATE_LIMIT_PER_SEC = 8
local actionTimestamps: { [Player]: { number } } = {}
local rejoinCooldown: { [Player]: number } = {}
local pendingMatchPurchase: { [Player]: { key: string, token: number, attr: GameConfig.AttributeKey?, dest: GameConfig.AttributeKey? } } = {}
local pendingSeeBest: { [Player]: boolean } = {}
local sessionsByTable: { [Model]: TableSession } = {}
local sessionByPlayer: { [Player]: TableSession } = {}

local MatchService = {}

local function allowAction(player: Player): boolean
	local now = os.clock()
	local list = actionTimestamps[player]
	if not list then
		list = {}
		actionTimestamps[player] = list
	end
	while list[1] and now - list[1] > 1 do
		table.remove(list, 1)
	end
	if #list >= RATE_LIMIT_PER_SEC then
		return false
	end
	table.insert(list, now)
	return true
end

local function setCharacterSeatedLock(player: Player?, locked: boolean)
	if not player or not player.Character then
		return
	end
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if locked then
		hum:SetAttribute("SavedJumpPower", hum.JumpPower)
		hum:SetAttribute("SavedJumpHeight", hum.JumpHeight)
		hum.JumpPower = 0
		hum.JumpHeight = 0
	else
		local jp = hum:GetAttribute("SavedJumpPower")
		local jh = hum:GetAttribute("SavedJumpHeight")
		hum.JumpPower = if typeof(jp) == "number" then jp else 50
		hum.JumpHeight = if typeof(jh) == "number" then jh else 7.2
	end
end

local function setWoodChairVisible(tableModel: Model, seatName: string, visible: boolean, color: Color3, mat: Enum.Material)
	for _, child in tableModel:GetChildren() do
		if child:IsA("BasePart") then
			if child.Name == seatName or string.find(child.Name, `^{seatName}_Leg`) ~= nil then
				child.Transparency = if visible then 0 else 1
				child.Color = color
				child.Material = mat
			elseif string.find(child.Name, `^{seatName}_Back`) ~= nil then
				child.Transparency = if visible then 0 else 1
				child.CanCollide = visible
				child.Color = color
				child.Material = mat
			end
		end
	end
end

local function applyChairSkin(tableModel: Model, seatName: string, player: Player?)
	local profile = if player then ProfileService.get(player) else nil
	local equipped = if profile and profile.EquippedChair then profile.EquippedChair elseif player then (player:GetAttribute("EquippedChair") :: string?) else nil
	local skin = GameConfig.getChairSkin(equipped or "wood")
	local seat = tableModel:FindFirstChild(seatName) :: Seat?
	if not seat then return end

	local oldDecor = tableModel:FindFirstChild(seatName .. "_Decor")
	if skin.id == "wood" then
		if oldDecor then
			oldDecor:Destroy()
		end
		setWoodChairVisible(tableModel, seatName, true, skin.color, skin.mat)
		return
	end

	if oldDecor and oldDecor:GetAttribute("SkinId") == skin.id then
		setWoodChairVisible(tableModel, seatName, false, skin.color, skin.mat)
		return
	end

	if oldDecor then
		oldDecor:Destroy()
	end

	local decor = ChairModelBuilder.buildChairForSeat(skin.id, seat, tableModel)
	if decor then
		decor:SetAttribute("SkinId", skin.id)
		decor.Name = seatName .. "_Decor"
		decor.Parent = tableModel
		setWoodChairVisible(tableModel, seatName, false, skin.color, skin.mat)
	else
		setWoodChairVisible(tableModel, seatName, true, skin.color, skin.mat)
	end
end

local function updateTableSign(session: TableSession)
	local occB = session.seatB.Occupant
	local humanInB = session.humanInSeatB or (session.playerB == nil and session.playerA ~= nil and occB ~= nil and occB.Parent ~= nil and Players:GetPlayerFromCharacter(occB.Parent) == session.playerA)
	local seatAPlayer = if humanInB then session.playerB else session.playerA
	local seatBPlayer = if humanInB then session.playerA else session.playerB
	applyChairSkin(session.model, "SeatA", seatAPlayer)
	applyChairSkin(session.model, "SeatB", seatBPlayer)
	local label = session.billboardLabel
	local count = (if session.playerA then 1 else 0) + (if session.playerB or session.isBot then 1 else 0)

	local placedA = 0
	if session.boardA then
		for _, attr in GameConfig.ATTRIBUTES do
			if session.boardA.slots[attr] then
				placedA += 1
			end
		end
	end
	local placedB = 0
	if session.boardB then
		for _, attr in GameConfig.ATTRIBUTES do
			if session.boardB.slots[attr] then
				placedB += 1
			end
		end
	end

	local inMatch = session.phase ~= "Idle" and session.phase ~= "Waiting"
	local nameA = if session.playerA then session.playerA.DisplayName else "Player"
	local nameB = if session.isBot then "BOT" elseif session.playerB then session.playerB.DisplayName else "Player"
	local turnNum = math.clamp(session.round or 1, 1, 6)

	-- P13 reactive table attributes
	session.model:SetAttribute("InMatch", inMatch)
	session.model:SetAttribute("Occupancy", count)
	session.model:SetAttribute("PlayerA", if session.playerA then session.playerA.DisplayName else "")
	session.model:SetAttribute("PlayerB", if session.isBot then "BOT" elseif session.playerB then session.playerB.DisplayName else "")
	session.model:SetAttribute("Turn", if inMatch then turnNum else 1)
	session.model:SetAttribute("PlacedA", placedA)
	session.model:SetAttribute("PlacedB", placedB)

	if not inMatch then
		if label then
			label.Visible = false -- Replaced by P13 spectator billboard
			label.Text = `Default Mode\n{count}/2\n$100`
		end
		session.model:SetAttribute("MatchActive", false)
		for _, attr in GameConfig.ATTRIBUTES do
			session.model:SetAttribute(`SlotA_{attr}`, "")
			session.model:SetAttribute(`SlotB_{attr}`, "")
		end
	else
		if label then
			label.Visible = false
		end
		session.model:SetAttribute("MatchActive", true)
		session.model:SetAttribute("NameA", nameA)
		session.model:SetAttribute("NameB", nameB)
		session.model:SetAttribute("Turn", turnNum)
		for _, attr in GameConfig.ATTRIBUTES do
			local cardA = if session.boardA then session.boardA.slots[attr] else nil
			local cardB = if session.boardB then session.boardB.slots[attr] else nil
			session.model:SetAttribute(`SlotA_{attr}`, if cardA then cardA.id else "")
			session.model:SetAttribute(`SlotB_{attr}`, if cardB then cardB.id else "")
		end
	end
end

local function serializeCard(card: Footballers.Footballer?)
	if not card then
		return nil
	end
	return {
		id = card.id,
		name = Footballers.getDisplayName(card),
		country = card.country,
		club = card.club,
		pos = card.pos,
		ovr = card.ovr,
		rarity = card.rarity,
		kitColor = card.kitColor,
		stats = card.stats,
	}
end

local function serializeBoard(board: MatchLogic.BoardState, displayRoll: Footballers.Footballer?, placedThisRound: boolean?)
	local slots = {}
	for _, attr in GameConfig.ATTRIBUTES do
		slots[attr] = serializeCard(board.slots[attr])
	end
	return {
		slots = slots,
		currentRoll = serializeCard(displayRoll or board.currentRoll),
		placedThisRound = placedThisRound == true,
		rerollsLeft = board.rerollsLeft,
		stealsLeft = board.stealsLeft,
		luck = board.luck,
		infRerolls = board.infRerolls,
		revealedAll = board.revealedAll,
		bestHint = board.bestHint,
	}
end

local function tryUpdateRarestPull(player: Player?, card: Footballers.Footballer?)
	if not player or not card then
		return
	end
	local configFolder = ReplicatedStorage:FindFirstChild("Config")
	if not configFolder then
		return
	end
	local prevOvr = tonumber(configFolder:GetAttribute("RarestPullOvr")) or 0
	if card.ovr >= prevOvr then
		configFolder:SetAttribute("RarestPullName", player.DisplayName)
		configFolder:SetAttribute("RarestPullUserId", player.UserId)
		configFolder:SetAttribute("RarestPullCard", `{Footballers.getDisplayName(card)} ({string.upper(card.rarity)})`)
		configFolder:SetAttribute("RarestPullOvr", card.ovr)
	end
end

local function recordBoardDiscoveries(player: Player?, board: MatchLogic.BoardState?, roundRoll: Footballers.Footballer?)
	if not player or not board then
		return
	end
	if roundRoll then
		ProfileService.discoverCard(player, roundRoll.id)
		tryUpdateRarestPull(player, roundRoll)
	end
	for _, card in board.slots do
		if card then
			ProfileService.discoverCard(player, card.id)
			tryUpdateRarestPull(player, card)
		end
	end
end

local function sendBuildState(session: TableSession, endsAt: number)
	if not session.boardA or not session.boardB then
		return
	end
	if session.subPhase == "Selecting" then
		recordBoardDiscoveries(session.playerA, session.boardA, session.roundRollA)
		recordBoardDiscoveries(session.playerB, session.boardB, session.roundRollB)
	end
	local bA = serializeBoard(session.boardA, session.roundRollA, session.placedThisRoundA)
	local bB = serializeBoard(session.boardB, session.roundRollB, session.placedThisRoundB)
	local nameA = if session.playerA then session.playerA.DisplayName else "Player 1"
	local nameB = if session.isBot then "BOT" elseif session.playerB then session.playerB.DisplayName else "Player 2"
	local uidA = if session.playerA then session.playerA.UserId else 0
	local uidB = if session.isBot then 0 elseif session.playerB then session.playerB.UserId else 0
	local tablePos = session.model:GetPivot().Position
	local effEndsAt = if endsAt > 0 then endsAt else session.roundEndsAt

	if session.playerA then
		Remotes.MatchState:FireClient(session.playerA, {
			phase = "Build",
			subPhase = session.subPhase or "Selecting",
			round = session.round,
			frozenTimer = session.frozenTimer,
			endsAt = effEndsAt,
			tablePos = tablePos,
			myName = nameA,
			oppName = nameB,
			myUserId = uidA,
			oppUserId = uidB,
			isBot = session.isBot,
			myBoard = bA,
			oppBoard = bB,
		})
	end
	if session.playerB then
		Remotes.MatchState:FireClient(session.playerB, {
			phase = "Build",
			subPhase = session.subPhase or "Selecting",
			round = session.round,
			frozenTimer = session.frozenTimer,
			endsAt = effEndsAt,
			tablePos = tablePos,
			myName = nameB,
			oppName = nameA,
			myUserId = uidB,
			oppUserId = uidA,
			isBot = false,
			myBoard = bB,
			oppBoard = bA,
		})
	end
end

local function makeBoardForPlayer(player: Player?, usedIds: { [string]: boolean }?): MatchLogic.BoardState
	local profile = if player then ProfileService.get(player) else nil
	local rerolls = GameConfig.DEFAULT_REROLLS
	local steals = GameConfig.DEFAULT_STEALS + (if profile then profile.ExtraSteals else 0)
	local luck = (if profile then profile.Luck else 1) * (if profile and profile.DoubleLuck then 2 else 1)
	local infRerolls = if profile then profile.InfRerolls else false
	return MatchLogic.createBoard(rerolls, steals, luck, infRerolls, nil, usedIds)
end

local function despawnBotCharacter(session: TableSession)
	if session.botModel then
		session.botModel:Destroy()
		session.botModel = nil
	end
	session.seatA.Disabled = false
	session.seatB.Disabled = false
end

local function spawnBotCharacter(session: TableSession)
	despawnBotCharacter(session)
	local occB = session.seatB.Occupant
	local isHumanInB = session.humanInSeatB or (occB ~= nil and occB.Parent ~= nil and Players:GetPlayerFromCharacter(occB.Parent) == session.playerA)
	local botSeat = if isHumanInB then session.seatA else session.seatB
	botSeat.Disabled = true

	local seatCF = botSeat.CFrame
	local bot = Instance.new("Model")
	bot.Name = "BotOpponent"

	local function makeLimb(name: string, size: Vector3, cf: CFrame, col: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = col
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = true
		p.CanCollide = false
		p.Parent = bot
		return p
	end

	local skinCol = Color3.fromRGB(245, 205, 148)
	local kitCol = Color3.fromHex("#E5252A")
	local shortsCol = Color3.fromRGB(24, 30, 48)

	local torso = makeLimb("Torso", Vector3.new(2, 2, 1), seatCF * CFrame.new(0, 1.9, 0), kitCol)
	local head = makeLimb("Head", Vector3.new(1.2, 1.2, 1.2), seatCF * CFrame.new(0, 3.5, 0), skinCol)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	makeLimb("LeftArm", Vector3.new(1, 2, 1), seatCF * CFrame.new(-1.5, 2.0, -0.35) * CFrame.Angles(math.rad(45), 0, 0), skinCol)
	makeLimb("RightArm", Vector3.new(1, 2, 1), seatCF * CFrame.new(1.5, 2.0, -0.35) * CFrame.Angles(math.rad(45), 0, 0), skinCol)
	makeLimb("LeftLeg", Vector3.new(1, 2, 1), seatCF * CFrame.new(-0.55, 0.65, -0.65) * CFrame.Angles(math.rad(90), 0, 0), shortsCol)
	makeLimb("RightLeg", Vector3.new(1, 2, 1), seatCF * CFrame.new(0.55, 0.65, -0.65) * CFrame.Angles(math.rad(90), 0, 0), shortsCol)

	local bb = Instance.new("BillboardGui")
	bb.Name = "BotOverhead"
	bb.Size = UDim2.fromOffset(140, 48)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.MaxDistance = 70
	bb.Adornee = head
	bb.Parent = head

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextColor3 = Color3.fromHex("#FFD21F")
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled = true
	lbl.Text = "🤖 BOT\nSTRIKER XI"
	lbl.Parent = bb

	bot.PrimaryPart = torso
	bot.Parent = session.model
	session.botModel = bot
end

local function unseatPlayer(player: Player?, fallbackSeat: Seat?)
	if not player then
		return
	end
	rejoinCooldown[player] = os.clock() + 2
	setCharacterSeatedLock(player, false)
	local char = player.Character
	local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
	local seat = if hum and hum.SeatPart and hum.SeatPart:IsA("Seat") then hum.SeatPart else fallbackSeat
	if seat then
		-- Briefly disable seat so character stepping off doesn't immediately re-weld on landing
		seat.Disabled = true
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		task.delay(2.0, function()
			if seat.Parent and not seat.Parent:FindFirstChild("BotOpponent") then
				seat.Disabled = false
			end
		end)
	end
	if hum then
		hum.Sit = false
	end
	-- Step player clear of the chair after stand-up replicates so client doesn't snap back onto the seat
	if char and seat then
		local exitPos = seat.Position + seat.CFrame.RightVector * 6.5 + Vector3.new(0, 2.2, 0)
		local targetCF = CFrame.lookAt(exitPos, exitPos + seat.CFrame.LookVector)
		task.delay(0.1, function()
			if char.Parent then
				char:PivotTo(targetCF)
			end
		end)
	end
end

local function resetSession(session: TableSession, unseat: boolean)
	if session.phase == "Waiting" then
		Remotes.OpponentAlert:FireAllClients({ active = false, tableId = session.id })
	end
	session.phaseToken += 1
	despawnBotCharacter(session)
	local oldA = session.playerA
	local oldB = session.playerB
	local oldHumanInSeatB = session.humanInSeatB == true

	session.phase = "Idle"
	session.subPhase = nil
	session.round = 1
	session.frozenTimer = 15
	session.roundEndsAt = 0
	session.placedThisRoundA = false
	session.placedThisRoundB = false
	session.roundRollA = nil
	session.roundRollB = nil
	session.isBot = false
	session.boardA = nil
	session.boardB = nil
	session.rematchA = false
	session.rematchB = false

	if oldA then
		sessionByPlayer[oldA] = nil
		pendingMatchPurchase[oldA] = nil
		pendingSeeBest[oldA] = nil
		if unseat then
			unseatPlayer(oldA, if oldHumanInSeatB then session.seatB else session.seatA)
		else
			setCharacterSeatedLock(oldA, false)
		end
	end
	if oldB then
		sessionByPlayer[oldB] = nil
		pendingMatchPurchase[oldB] = nil
		pendingSeeBest[oldB] = nil
		if unseat then
			unseatPlayer(oldB, if oldHumanInSeatB then session.seatA else session.seatB)
		else
			setCharacterSeatedLock(oldB, false)
		end
	end

	session.playerA = nil
	session.playerB = nil
	session.humanInSeatB = false
	updateTableSign(session)
end

local startBuildPhase: (session: TableSession) -> ()

local function startShowdownPhase(session: TableSession)
	if session.phase ~= "Build" or not session.boardA or not session.boardB then
		return
	end
	session.phaseToken += 1
	local token = session.phaseToken
	session.phase = "Showdown"
	updateTableSign(session)

	local result = MatchLogic.resolveShowdown(session.boardA, session.boardB)
	local bA = serializeBoard(session.boardA)
	local bB = serializeBoard(session.boardB)
	local nameA = if session.playerA then session.playerA.DisplayName else "Player 1"
	local nameB = if session.isBot then "BOT" elseif session.playerB then session.playerB.DisplayName else "Player 2"
	local uidA = if session.playerA then session.playerA.UserId else 0
	local uidB = if session.isBot then 0 elseif session.playerB then session.playerB.UserId else 0
	local tablePos = session.model:GetPivot().Position
	local tiebreakerPayload = if result.tiebreaker
		then {
			cardA = serializeCard(result.tiebreaker.cardA),
			cardB = serializeCard(result.tiebreaker.cardB),
		}
		else nil

	if session.playerA then
		Remotes.MatchState:FireClient(session.playerA, {
			phase = "Showdown",
			tablePos = tablePos,
			myName = nameA,
			oppName = nameB,
			myUserId = uidA,
			oppUserId = uidB,
			myBoard = bA,
			oppBoard = bB,
			myEval = result.evalA,
			oppEval = result.evalB,
			didWin = result.winner == "A",
			tiebreaker = tiebreakerPayload,
		})
	end
	if session.playerB then
		Remotes.MatchState:FireClient(session.playerB, {
			phase = "Showdown",
			tablePos = tablePos,
			myName = nameB,
			oppName = nameA,
			myUserId = uidB,
			oppUserId = uidA,
			myBoard = bB,
			oppBoard = bA,
			myEval = result.evalB,
			oppEval = result.evalA,
			didWin = result.winner == "B",
			tiebreaker = tiebreakerPayload,
		})
	end

	task.delay(GameConfig.SHOWDOWN_TIME, function()
		if session.phaseToken ~= token or session.phase ~= "Showdown" then
			return
		end
		session.phase = "Result"
		session.rematchA = false
		session.rematchB = false
		updateTableSign(session)

		local rematchEndsAt = Workspace:GetServerTimeNow() + GameConfig.REMATCH_TIME
		if session.playerA then
			local wonA = result.winner == "A"
			local rewardA = ProfileService.awardMatchResult(session.playerA, wonA)
			Remotes.MatchState:FireClient(session.playerA, {
				phase = "Result",
				tablePos = tablePos,
				myName = nameA,
				oppName = nameB,
				myUserId = uidA,
				oppUserId = uidB,
				myBoard = bA,
				oppBoard = bB,
				myEval = result.evalA,
				oppEval = result.evalB,
				didWin = wonA,
				reward = rewardA,
				rematchEndsAt = rematchEndsAt,
			})
		end
		if session.playerB then
			local wonB = result.winner == "B"
			local rewardB = ProfileService.awardMatchResult(session.playerB, wonB)
			Remotes.MatchState:FireClient(session.playerB, {
				phase = "Result",
				tablePos = tablePos,
				myName = nameB,
				oppName = nameA,
				myUserId = uidB,
				oppUserId = uidA,
				myBoard = bB,
				oppBoard = bA,
				myEval = result.evalB,
				oppEval = result.evalA,
				didWin = wonB,
				reward = rewardB,
				rematchEndsAt = rematchEndsAt,
			})
		end

		-- Broadcast to Jumbotron and lobby
		local wonA = result.winner == "A"
		local winnerName = if wonA then nameA else nameB
		local winnerUid = if wonA then uidA else uidB
		local winnerEval = if wonA then result.evalA else result.evalB
		pcall(function()
			Remotes.MatchResult:FireAllClients({
				winnerName = winnerName,
				winnerUserId = winnerUid,
				avgScore = winnerEval.avgScore,
				grade = winnerEval.grade,
			})
			local configFolder = ReplicatedStorage:FindFirstChild("Config")
			if configFolder and winnerUid ~= 0 and winnerName ~= "BOT" then
				configFolder:SetAttribute("LatestWinnerName", winnerName)
				configFolder:SetAttribute("LatestWinnerUserId", winnerUid)
				configFolder:SetAttribute("LatestWinnerScore", winnerEval.avgScore)
				configFolder:SetAttribute("LatestWinnerGrade", winnerEval.grade)
			end
		end)

		local resultToken = session.phaseToken
		task.delay(GameConfig.REMATCH_TIME, function()
			if session.phaseToken == resultToken and session.phase == "Result" then
				if session.playerA then
					Remotes.MatchState:FireClient(session.playerA, { phase = "Idle" })
				end
				if session.playerB then
					Remotes.MatchState:FireClient(session.playerB, { phase = "Idle" })
				end
				resetSession(session, true)
			end
		end)
	end)
end

local startBuildRound: (session: TableSession, roundNum: number, frozenSec: number) -> ()

local function autoPlaceFirstEmpty(board: MatchLogic.BoardState)
	for _, attr in GameConfig.ATTRIBUTES do
		if board.slots[attr] == nil then
			MatchLogic.placeInSlot(board, attr)
			return
		end
	end
end

local function checkAdvanceBuildRound(session: TableSession, expectedToken: number)
	if session.phaseToken ~= expectedToken or session.phase ~= "Build" or not session.boardA or not session.boardB then
		return
	end
	updateTableSign(session)
	sendBuildState(session, session.roundEndsAt)

	if session.placedThisRoundA and session.placedThisRoundB then
		session.phaseToken += 1
		local advToken = session.phaseToken
		local leftover = math.clamp(math.ceil(session.roundEndsAt - Workspace:GetServerTimeNow()), 1, GameConfig.BUILD_TIME)
		task.delay(0.85, function()
			if session.phaseToken ~= advToken or session.phase ~= "Build" or not session.boardA or not session.boardB then
				return
			end
			if MatchLogic.isBoardFull(session.boardA) and MatchLogic.isBoardFull(session.boardB) then
				startShowdownPhase(session)
			else
				startBuildRound(session, session.round + 1, leftover)
			end
		end)
	end
end

startBuildRound = function(session: TableSession, roundNum: number, frozenSec: number)
	if not session.boardA or not session.boardB then
		return
	end
	if MatchLogic.isBoardFull(session.boardA) and MatchLogic.isBoardFull(session.boardB) then
		startShowdownPhase(session)
		return
	end

	session.phaseToken += 1
	local roundToken = session.phaseToken
	session.phase = "Build"
	session.round = math.clamp(roundNum, 1, 6)
	session.subPhase = "Rolling"
	session.frozenTimer = frozenSec
	session.roundEndsAt = 0
	session.placedThisRoundA = MatchLogic.isBoardFull(session.boardA)
	session.placedThisRoundB = MatchLogic.isBoardFull(session.boardB)
	session.roundRollA = session.boardA.currentRoll
	session.roundRollB = session.boardB.currentRoll
	session.boardA.bestHint = nil
	session.boardB.bestHint = nil

	updateTableSign(session)
	sendBuildState(session, 0)

	task.delay(2.4, function()
		if session.phaseToken ~= roundToken or session.phase ~= "Build" or not session.boardA or not session.boardB then
			return
		end
		session.subPhase = "Selecting"
		session.roundEndsAt = Workspace:GetServerTimeNow() + GameConfig.BUILD_TIME
		if session.playerA and session.roundRollA then
			ProfileService.recordCardRoll(session.playerA, session.roundRollA.id)
		end
		if session.playerB and session.roundRollB then
			ProfileService.recordCardRoll(session.playerB, session.roundRollB.id)
		end
		if session.playerA and pendingSeeBest[session.playerA] then
			pendingSeeBest[session.playerA] = nil
			session.boardA.bestHint = MatchLogic.getBestSlot(session.boardA, session.roundRollA or session.boardA.currentRoll)
		end
		if session.playerB and pendingSeeBest[session.playerB] then
			pendingSeeBest[session.playerB] = nil
			session.boardB.bestHint = MatchLogic.getBestSlot(session.boardB, session.roundRollB or session.boardB.currentRoll)
		end
		sendBuildState(session, session.roundEndsAt)

		if session.isBot and not session.placedThisRoundB then
			task.delay(math.random(22, 38) / 10, function()
				if session.phaseToken ~= roundToken or session.phase ~= "Build" or session.placedThisRoundB or not session.boardB or not session.boardA then
					return
				end
				local hostProfile = if session.playerA then ProfileService.get(session.playerA) else nil
				local botOptimalChance = if hostProfile and hostProfile.Wins < 5 then 0.65 else 0.88
				MatchLogic.stepBot(session.boardB, session.boardA, nil, botOptimalChance)
				session.placedThisRoundB = true
				checkAdvanceBuildRound(session, roundToken)
			end)
		end

		task.delay(GameConfig.BUILD_TIME, function()
			if session.phaseToken ~= roundToken or session.phase ~= "Build" or not session.boardA or not session.boardB then
				return
			end
			if not session.placedThisRoundA then
				autoPlaceFirstEmpty(session.boardA)
				session.placedThisRoundA = true
			end
			if not session.placedThisRoundB then
				autoPlaceFirstEmpty(session.boardB)
				session.placedThisRoundB = true
			end
			checkAdvanceBuildRound(session, roundToken)
		end)
	end)
end

startBuildPhase = function(session: TableSession)
	Remotes.OpponentAlert:FireAllClients({ active = false, tableId = session.id })
	if session.playerA then
		pendingMatchPurchase[session.playerA] = nil
		pendingSeeBest[session.playerA] = nil
	end
	if session.playerB then
		pendingMatchPurchase[session.playerB] = nil
		pendingSeeBest[session.playerB] = nil
	end
	session.phaseToken += 1
	local token = session.phaseToken
	local sessionUsedIds: { [string]: boolean } = {}
	session.boardA = makeBoardForPlayer(session.playerA, sessionUsedIds)
	session.boardB = makeBoardForPlayer(session.playerB, sessionUsedIds)
	session.rematchA = false
	session.rematchB = false
	session.round = 1
	session.frozenTimer = 15

	setCharacterSeatedLock(session.playerA, true)
	setCharacterSeatedLock(session.playerB, true)
	if session.isBot then
		spawnBotCharacter(session)
	else
		despawnBotCharacter(session)
	end

	local nameA = if session.playerA then session.playerA.DisplayName else "Player 1"
	local nameB = if session.isBot then "BOT" elseif session.playerB then session.playerB.DisplayName else "Player 2"
	local tablePos = session.model:GetPivot().Position

	-- Step 1: Match Intro over unblurred table camera (Section 5)
	session.phase = "Intro"
	updateTableSign(session)
	if session.playerA then
		Remotes.MatchState:FireClient(session.playerA, {
			phase = "Intro",
			tablePos = tablePos,
			myName = nameA,
			oppName = nameB,
			isBot = session.isBot,
		})
	end
	if session.playerB then
		Remotes.MatchState:FireClient(session.playerB, {
			phase = "Intro",
			tablePos = tablePos,
			myName = nameB,
			oppName = nameA,
			isBot = false,
		})
	end

	task.delay(3.0, function()
		if session.phaseToken ~= token or session.phase ~= "Intro" then
			return
		end
		-- Step 2: Countdown 3, 2, 1, GO! with blurred screen (Section 6)
		session.phase = "Countdown"
		local cdEnds = Workspace:GetServerTimeNow() + 3.4
		if session.playerA then
			Remotes.MatchState:FireClient(session.playerA, {
				phase = "Countdown",
				tablePos = tablePos,
				myName = nameA,
				oppName = nameB,
				endsAt = cdEnds,
			})
		end
		if session.playerB then
			Remotes.MatchState:FireClient(session.playerB, {
				phase = "Countdown",
				tablePos = tablePos,
				myName = nameB,
				oppName = nameA,
				endsAt = cdEnds,
			})
		end

		task.delay(3.4, function()
			if session.phaseToken ~= token or session.phase ~= "Countdown" then
				return
			end
			startBuildRound(session, 1, 15)
		end)
	end)
end

local function getPlayerFromOccupant(occupant: Humanoid?): Player?
	if not occupant or not occupant.Parent then
		return nil
	end
	return Players:GetPlayerFromCharacter(occupant.Parent)
end

local function onSeatChanged(session: TableSession)
	if session.phase ~= "Idle" and session.phase ~= "Waiting" then
		return
	end

	local pA = getPlayerFromOccupant(session.seatA.Occupant)
	local pB = getPlayerFromOccupant(session.seatB.Occupant)

	if pA and (rejoinCooldown[pA] or 0) > os.clock() then
		unseatPlayer(pA, session.seatA)
		pA = nil
	end
	if pB and (rejoinCooldown[pB] or 0) > os.clock() then
		unseatPlayer(pB, session.seatB)
		pB = nil
	end
	if pA and sessionByPlayer[pA] and sessionByPlayer[pA] ~= session then
		pA = nil
	end
	if pB and sessionByPlayer[pB] and sessionByPlayer[pB] ~= session then
		pB = nil
	end

	if not pA and pB then
		pA = pB
		pB = nil
		session.humanInSeatB = true
	elseif pA and not pB then
		session.humanInSeatB = false
	else
		session.humanInSeatB = false
	end

	if not pA and not pB then
		if session.playerA then
			Remotes.MatchState:FireClient(session.playerA, { phase = "Idle" })
		end
		resetSession(session, false)
		return
	end

	if pA and pB and pA ~= pB then
		session.playerA = pA
		session.playerB = pB
		session.isBot = false
		sessionByPlayer[pA] = session
		sessionByPlayer[pB] = session
		startBuildPhase(session)
		return
	end

	if pA and not pB and session.phase == "Idle" then
		session.playerA = pA
		session.playerB = nil
		session.isBot = false
		sessionByPlayer[pA] = session
		session.phase = "Waiting"
		session.phaseToken += 1
		local token = session.phaseToken
		local waitSecs = if #Players:GetPlayers() > 1
			then 8
			else math.random(GameConfig.BOT_FILL_MIN, GameConfig.BOT_FILL_MAX)
		updateTableSign(session)

		Remotes.MatchState:FireClient(pA, {
			phase = "Waiting",
			tablePos = session.model:GetPivot().Position,
			myName = pA.DisplayName,
			endsAt = Workspace:GetServerTimeNow() + waitSecs,
		})

		task.delay(GameConfig.OPPONENT_ALERT_DELAY_SEC, function()
			if session.phaseToken ~= token or session.phase ~= "Waiting" or session.playerA ~= pA or session.playerB ~= nil or session.isBot then
				return
			end
			for _, other in Players:GetPlayers() do
				if other ~= pA and sessionByPlayer[other] == nil then
					Remotes.OpponentAlert:FireClient(other, {
						active = true,
						tableId = session.id,
						hostUserId = pA.UserId,
						hostName = pA.DisplayName,
					})
				end
			end
		end)

		task.delay(waitSecs, function()
			if session.phaseToken == token and session.phase == "Waiting" and session.playerA == pA then
				session.isBot = true
				startBuildPhase(session)
			end
		end)
	end
end

local function handleDisconnectOrLeave(player: Player)
	actionTimestamps[player] = nil
	local session = sessionByPlayer[player]
	if not session then
		return
	end

	if session.phase == "Waiting" then
		Remotes.MatchState:FireClient(player, { phase = "Idle" })
		resetSession(session, true)
		return
	end

	local survivor: Player? = if session.playerA == player then session.playerB else session.playerA
	if survivor and (session.phase == "Intro" or session.phase == "Countdown" or session.phase == "Build" or session.phase == "Showdown") then
		local reward = ProfileService.awardMatchResult(survivor, true)
		Remotes.MatchState:FireClient(survivor, {
			phase = "Result",
			myName = survivor.DisplayName,
			oppName = `{player.DisplayName} (Disconnected)`,
			didWin = true,
			reward = reward,
			rematchEndsAt = Workspace:GetServerTimeNow() + 5,
		})
	elseif survivor and session.phase == "Result" then
		Remotes.MatchState:FireClient(survivor, { phase = "Idle" })
	end
	if session.playerA == player then
		Remotes.MatchState:FireClient(player, { phase = "Idle" })
	elseif session.playerB == player then
		Remotes.MatchState:FireClient(player, { phase = "Idle" })
	end
	resetSession(session, true)
end

local function promptMatchMonetization(player: Player, itemKey: string, session: TableSession, attr: GameConfig.AttributeKey?, dest: GameConfig.AttributeKey?)
	local item = (GameConfig.MONETIZATION :: any)[itemKey]
	if not item or not item.id or item.id <= 0 then
		return
	end
	pendingMatchPurchase[player] = {
		key = itemKey,
		token = session.phaseToken,
		attr = attr,
		dest = dest,
	}
	pcall(function()
		if item.kind == "GamePass" then
			MarketplaceService:PromptGamePassPurchase(player, item.id)
		else
			MarketplaceService:PromptProductPurchase(player, item.id)
		end
	end)
end

local function handleMatchAction(player: Player, action: unknown, arg1: unknown, arg2: unknown)
	if not allowAction(player) or typeof(action) ~= "string" then
		return
	end
	if action == "LeaveTable" then
		if sessionByPlayer[player] then
			handleDisconnectOrLeave(player)
		else
			unseatPlayer(player, nil)
			Remotes.MatchState:FireClient(player, { phase = "Idle" })
		end
		return
	end
	if action == "JoinWaitingTable" and typeof(arg1) == "string" then
		if sessionByPlayer[player] ~= nil then
			return
		end
		local char = player.Character
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		if not char or not hum or hum.Health <= 0 then
			return
		end
		for _, target in sessionsByTable do
			if target.id == arg1 and target.phase == "Waiting" and target.playerA ~= nil and target.playerA ~= player and target.playerB == nil and not target.isBot then
				local openSeat = if target.seatA.Occupant == nil then target.seatA elseif target.seatB.Occupant == nil then target.seatB else nil
				if openSeat then
					hum.Sit = false
					char:PivotTo(openSeat.CFrame + Vector3.new(0, 1.8, 0))
					openSeat:Sit(hum)
				end
				break
			end
		end
		return
	end
	local session = sessionByPlayer[player]
	if not session then
		return
	end

	if (action == "PlayBotNow" or action == "RequestBotMatch") and session.phase == "Waiting" and session.playerA == player then
		session.isBot = true
		startBuildPhase(session)
		return
	end

	if action == "Rematch" and session.phase == "Result" then
		if session.playerA == player then
			session.rematchA = true
		elseif session.playerB == player then
			session.rematchB = true
		end
		if session.isBot and session.rematchA then
			startBuildPhase(session)
		elseif session.rematchA and session.rematchB then
			startBuildPhase(session)
		end
		return
	end

	if session.phase ~= "Build" or not session.boardA or not session.boardB then
		return
	end

	local isA = session.playerA == player
	local myBoard: MatchLogic.BoardState = if isA then session.boardA else session.boardB
	local oppBoard: MatchLogic.BoardState = if isA then session.boardB else session.boardA
	local isPlaced = if isA then session.placedThisRoundA else session.placedThisRoundB
	local prof = ProfileService.get(player)
	if prof then
		myBoard.luck = prof.Luck
	end
	local changed = false

	if action == "PlaceSlot" and typeof(arg1) == "string" then
		if session.subPhase == "Selecting" and not isPlaced then
			if MatchLogic.placeInSlot(myBoard, arg1 :: GameConfig.AttributeKey) then
				if isA then
					session.placedThisRoundA = true
				else
					session.placedThisRoundB = true
				end
				checkAdvanceBuildRound(session, session.phaseToken)
				return
			end
		end
	elseif action == "Reroll" then
		if session.subPhase == "Selecting" and not isPlaced and not MatchLogic.isBoardFull(myBoard) then
			if myBoard.infRerolls or myBoard.rerollsLeft > 0 then
				changed = MatchLogic.reroll(myBoard)
				if changed then
					if isA then
						session.roundRollA = myBoard.currentRoll
					else
						session.roundRollB = myBoard.currentRoll
					end
					if myBoard.currentRoll then
						ProfileService.recordCardRoll(player, myBoard.currentRoll.id)
					end
				end
			else
				promptMatchMonetization(player, "match_reroll", session)
				return
			end
		end
	elseif action == "Steal" and typeof(arg1) == "string" then
		if session.subPhase == "Selecting" and not isPlaced then
			local targetAttr = arg1 :: GameConfig.AttributeKey
			local dest = (if typeof(arg2) == "string" then arg2 else arg1) :: GameConfig.AttributeKey
			if table.find(GameConfig.ATTRIBUTES, targetAttr) and table.find(GameConfig.ATTRIBUTES, dest) and oppBoard.slots[targetAttr] ~= nil and myBoard.slots[dest] == nil then
				if myBoard.stealsLeft > 0 then
					changed = MatchLogic.stealSlot(myBoard, oppBoard, targetAttr, dest)
					if changed then
						if isA and session.placedThisRoundB and not MatchLogic.isBoardFull(oppBoard) then
							session.placedThisRoundB = false
						elseif not isA and session.placedThisRoundA and not MatchLogic.isBoardFull(oppBoard) then
							session.placedThisRoundA = false
						end
					end
				else
					promptMatchMonetization(player, "match_steal", session, targetAttr, dest)
					return
				end
			end
		end
	elseif action == "Shuffle" then
		changed = MatchLogic.shuffleSlots(myBoard)
	elseif action == "SeeBest" then
		if session.subPhase == "Selecting" and not isPlaced and myBoard.bestHint == nil then
			promptMatchMonetization(player, "match_see_best", session)
		end
		return
	elseif action == "RevealAll" then
		if not myBoard.revealedAll then
			promptMatchMonetization(player, "match_reveal_all", session)
		end
		return
	elseif action == "UpgradeLuck" then
		if ProfileService.upgradeLuck(player) then
			local updatedProf = ProfileService.get(player)
			if updatedProf then
				myBoard.luck = updatedProf.Luck
			end
			changed = true
		end
	end

	if changed then
		updateTableSign(session)
		sendBuildState(session, session.roundEndsAt)
		if MatchLogic.isBoardFull(session.boardA) and MatchLogic.isBoardFull(session.boardB) then
			startShowdownPhase(session)
		end
	end
end

local function bindTableModel(model: Model)
	if sessionsByTable[model] then
		return
	end
	local seatA = model:FindFirstChild("SeatA", true) :: Seat?
	local seatB = model:FindFirstChild("SeatB", true) :: Seat?
	if not seatA or not seatB or not seatA:IsA("Seat") or not seatB:IsA("Seat") then
		return
	end
	local oldSitPrompt = model:FindFirstChild("SitPromptLabel", true)
	if oldSitPrompt then
		oldSitPrompt:Destroy()
	end
	local oldSpecGrid = model:FindFirstChild("SpectatorGrid", true)
	if oldSpecGrid then
		oldSpecGrid:Destroy()
	end
	local label = model:FindFirstChild("SignLabel", true) :: TextLabel?

	local session: TableSession = {
		id = model.Name,
		model = model,
		seatA = seatA,
		seatB = seatB,
		billboardLabel = label,
		phase = "Idle",
		subPhase = nil,
		round = 1,
		frozenTimer = 15,
		roundEndsAt = 0,
		placedThisRoundA = false,
		placedThisRoundB = false,
		roundRollA = nil,
		roundRollB = nil,
		playerA = nil,
		playerB = nil,
		isBot = false,
		botModel = nil,
		boardA = nil,
		boardB = nil,
		phaseToken = 0,
		rematchA = false,
		rematchB = false,
		humanInSeatB = false,
	}
	sessionsByTable[model] = session
	updateTableSign(session)

	local function hookPrompt(seat: Seat)
		seat.CanTouch = false
		local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(plr)
				if (rejoinCooldown[plr] or 0) > os.clock() then
					return
				end
				local char = plr.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and not hum.Sit and seat.Occupant == nil then
					seat:Sit(hum)
				end
			end)
		end
	end
	hookPrompt(seatA)
	hookPrompt(seatB)

	seatA:GetPropertyChangedSignal("Occupant"):Connect(function()
		local promptA = seatA:FindFirstChildOfClass("ProximityPrompt")
		if promptA then promptA.Enabled = (seatA.Occupant == nil) end
		onSeatChanged(session)
	end)
	seatB:GetPropertyChangedSignal("Occupant"):Connect(function()
		local promptB = seatB:FindFirstChildOfClass("ProximityPrompt")
		if promptB then promptB.Enabled = (seatB.Occupant == nil) end
		onSeatChanged(session)
	end)
end

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function createStarterTable(parent: Instance, name: string, center: Vector3, angleYDeg: number?): Model
	local model = Instance.new("Model")
	model.Name = name
	local woodColor = Color3.fromRGB(124, 71, 40)
	local darkWood = Color3.fromRGB(95, 52, 28)

	local top = makePart(model, "TableTop", Vector3.new(7, 0.5, 4.4), CFrame.new(center + Vector3.new(0, 2.8, 0)), woodColor, Enum.Material.WoodPlanks)
	for _, offset in {
		Vector3.new(-3.1, 1.3, -1.8),
		Vector3.new(3.1, 1.3, -1.8),
		Vector3.new(-3.1, 1.3, 1.8),
		Vector3.new(3.1, 1.3, 1.8),
	} do
		makePart(model, "TableLeg", Vector3.new(0.45, 2.6, 0.45), CFrame.new(center + offset), darkWood, Enum.Material.Wood)
	end

	local function buildChair(seatName: string, xSide: number): Seat
		local seatPos = center + Vector3.new(xSide * 4.8, 1.6, 0)
		local seat = Instance.new("Seat")
		seat.Name = seatName
		seat.Size = Vector3.new(2.2, 0.4, 2.2)
		seat.CFrame = CFrame.lookAt(seatPos, center + Vector3.new(0, 1.6, 0))
		seat.Anchored = true
		seat.CanTouch = false
		seat.Color = woodColor
		seat.Material = Enum.Material.WoodPlanks
		seat.Parent = model

		makePart(model, `{seatName}_Back`, Vector3.new(0.35, 2.2, 2.2), CFrame.new(seatPos + Vector3.new(xSide * 0.95, 1.2, 0)), darkWood, Enum.Material.Wood)
		for _, legOff in {
			Vector3.new(-0.85, -0.8, -0.85),
			Vector3.new(0.85, -0.8, -0.85),
			Vector3.new(-0.85, -0.8, 0.85),
			Vector3.new(0.85, -0.8, 0.85),
		} do
			makePart(model, `{seatName}_Leg`, Vector3.new(0.3, 1.6, 0.3), CFrame.new(seatPos + legOff), darkWood, Enum.Material.Wood)
		end
		return seat
	end

	buildChair("SeatA", -1)
	buildChair("SeatB", 1)

	local anchor = top:FindFirstChild("BillboardAnchor") :: Attachment?
	if not anchor then
		anchor = Instance.new("Attachment")
		anchor.Name = "BillboardAnchor"
		anchor.Position = Vector3.new(0, 6.2, 0) -- 7 studs above table centre (tableTop Y=2.8, centre Y=2.0)
		anchor.Parent = top
	end

	-- Initialize P13 reactive table attributes
	model:SetAttribute("InMatch", false)
	model:SetAttribute("Occupancy", 0)
	model:SetAttribute("PlayerA", "")
	model:SetAttribute("PlayerB", "")
	model:SetAttribute("Turn", 1)
	model:SetAttribute("PlacedA", 0)
	model:SetAttribute("PlacedB", 0)

	local bb = Instance.new("BillboardGui")
	bb.Name = "StatusBillboard"
	bb.Size = UDim2.fromScale(8.5, 4.8)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.MaxDistance = 85
	bb.AlwaysOnTop = false
	bb.Adornee = top
	bb.Parent = top

	local lbl = Instance.new("TextLabel")
	lbl.Name = "SignLabel"
	lbl.Size = UDim2.new(1, 0, 0.85, 0)
	lbl.Position = UDim2.new(0, 0, 0.08, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextScaled = true
	lbl.Text = "Default Mode\n0/2\n$100"
	lbl.Parent = bb

	model.PrimaryPart = top

	if angleYDeg and angleYDeg ~= 0 then
		local pivotCF = CFrame.new(center + Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, math.rad(angleYDeg), 0)
		model:PivotTo(pivotCF)
	end

	model.Parent = parent
	return model
end

local STARTER_TABLES = {
	{ pos = Vector3.new(-28, 0, -14), rot = -8 },  -- Table_1 (west, north)
	{ pos = Vector3.new(22, 0, -16),  rot = 9 },   -- Table_2 (east, north)
	{ pos = Vector3.new(-17, 0, -31), rot = 10 },  -- Table_3 (west, mid-north)
	{ pos = Vector3.new(34, 0, -34),  rot = -11 }, -- Table_4 (east, mid-north)
	{ pos = Vector3.new(-31, 0, -49), rot = -12 }, -- Table_5 (west, mid-south)
	{ pos = Vector3.new(19, 0, -53),  rot = 8 },   -- Table_6 (east, mid-south)
	{ pos = Vector3.new(-20, 0, -69), rot = 7 },   -- Table_7 (west, south)
	{ pos = Vector3.new(30, 0, -70),  rot = -7 },  -- Table_8 (east, south)
}

function MatchService.buildStarterTables()
	local lobby = Workspace:FindFirstChild("Lobby")
	local tablesFolder = (lobby and lobby:FindFirstChild("Tables")) or Workspace:FindFirstChild("Tables")
	if not tablesFolder then
		tablesFolder = Instance.new("Folder")
		tablesFolder.Name = "Tables"
		tablesFolder.Parent = lobby or Workspace
	end

	if #tablesFolder:GetChildren() == 0 then
		for idx, cfg in STARTER_TABLES do
			createStarterTable(tablesFolder, `Table_{idx}`, cfg.pos, cfg.rot)
		end
	end
	return tablesFolder
end

local function handleMatchProductPurchase(player: Player, itemKey: string): boolean
	local session = sessionByPlayer[player]
	if not session or session.phase ~= "Build" or not session.boardA or not session.boardB then
		return false
	end

	local isA = session.playerA == player
	local myBoard: MatchLogic.BoardState = if isA then session.boardA else session.boardB
	local oppBoard: MatchLogic.BoardState = if isA then session.boardB else session.boardA
	local isPlaced = if isA then session.placedThisRoundA else session.placedThisRoundB
	local pending = pendingMatchPurchase[player]
	pendingMatchPurchase[player] = nil

	if itemKey == "match_reveal_all" then
		myBoard.revealedAll = true
	elseif itemKey == "match_see_best" then
		if session.subPhase == "Selecting" and not isPlaced then
			local activeRoll = if isA then session.roundRollA else session.roundRollB
			myBoard.bestHint = MatchLogic.getBestSlot(myBoard, activeRoll or myBoard.currentRoll)
		else
			pendingSeeBest[player] = true
		end
	elseif itemKey == "match_reroll" then
		myBoard.rerollsLeft += 1
		if session.subPhase == "Selecting" and not isPlaced and not MatchLogic.isBoardFull(myBoard) then
			if MatchLogic.reroll(myBoard) then
				if isA then
					session.roundRollA = myBoard.currentRoll
				else
					session.roundRollB = myBoard.currentRoll
				end
				if myBoard.currentRoll then
					ProfileService.recordCardRoll(player, myBoard.currentRoll.id)
				end
			end
		end
	elseif itemKey == "match_steal" then
		myBoard.stealsLeft += 1
		if pending and pending.key == "match_steal" and pending.token == session.phaseToken and pending.attr and session.subPhase == "Selecting" and not isPlaced then
			if MatchLogic.stealSlot(myBoard, oppBoard, pending.attr, pending.dest) then
				if isA and session.placedThisRoundB and not MatchLogic.isBoardFull(oppBoard) then
					session.placedThisRoundB = false
				elseif not isA and session.placedThisRoundA and not MatchLogic.isBoardFull(oppBoard) then
					session.placedThisRoundA = false
				end
			end
		end
	else
		return false
	end

	updateTableSign(session)
	sendBuildState(session, session.roundEndsAt)
	if MatchLogic.isBoardFull(session.boardA) and MatchLogic.isBoardFull(session.boardB) then
		startShowdownPhase(session)
	end
	return true
end

function MatchService.init()
	local tablesFolder = MatchService.buildStarterTables()
	if not game:GetService("RunService"):IsServer() then
		return
	end
	for _, child in tablesFolder:GetChildren() do
		if child:IsA("Model") then
			bindTableModel(child)
		end
	end
	tablesFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.defer(bindTableModel, child)
		end
	end)

	ProfileService.setMatchProductHandler(handleMatchProductPurchase)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number, _productId: number, isPurchased: boolean)
		if not isPurchased then
			local plr = Players:GetPlayerByUserId(userId)
			if plr then
				pendingMatchPurchase[plr] = nil
			end
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr: Player, _passId: number, wasPurchased: boolean)
		if not wasPurchased then
			pendingMatchPurchase[plr] = nil
		end
	end)
	Remotes.MatchAction.OnServerEvent:Connect(handleMatchAction)
	local function watchPlayerChair(plr: Player)
		plr:GetAttributeChangedSignal("EquippedChair"):Connect(function()
			local session = sessionByPlayer[plr]
			if session then
				updateTableSign(session)
			end
		end)
	end
	for _, plr in Players:GetPlayers() do
		watchPlayerChair(plr)
	end
	Players.PlayerAdded:Connect(watchPlayerChair)
	Players.PlayerRemoving:Connect(function(plr)
		rejoinCooldown[plr] = nil
		pendingMatchPurchase[plr] = nil
		pendingSeeBest[plr] = nil
		handleDisconnectOrLeave(plr)
	end)
end

return table.freeze(MatchService)

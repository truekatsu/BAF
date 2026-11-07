--!strict
--[[
	LobbyService
	Responsibility: Builds the 3D Stadium Island Lobby (striped pitch, walkway, lanterns, 3 neon leaderboards, Next Mythical Vote, Feedback mailbox, Slap Tool pad, Agility Obby) and drives live leaderboard & overhead Streak King tags.
	Loop step: progression | social | retention
	Location: ServerScriptService/Server/LobbyService (ModuleScript)
]]

local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Footballers = require(Shared:WaitForChild("Footballers"))
local FootballerModelBuilder = require(Shared:WaitForChild("FootballerModelBuilder"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local LeaderboardConfig = require(Shared:WaitForChild("LeaderboardConfig"))
local LeaderboardBuilder = require(Shared:WaitForChild("LeaderboardBuilder"))
local VoteConfig = require(Shared:WaitForChild("VoteConfig"))
local ProfileService = require(script.Parent.ProfileService)

local votedPlayers: { [Player]: "A" | "B" } = {}
local playerVoted: { [number]: "A" | "B" } = {}
local lastVoteRequestTime: { [number]: number } = {}
local playerLastActive: { [number]: number } = {}
local playerActiveSeconds: { [number]: number } = {}
local isVoteRoundOpen = true
local voteTouchDebounce: { [Player]: number } = {}
local votesA = 0
local votesB = 0
local refreshVoteDisplayGlobal: (() -> ())? = nil
local metaActionBound = false

local voteStore: GlobalDataStore? = nil
pcall(function()
	voteStore = DataStoreService:GetDataStore("BAF_MythicalVotes_v2")
end)

task.spawn(function()
	if voteStore then
		local ok, saved = pcall(function()
			return voteStore:GetAsync("GlobalTally")
		end)
		if ok and type(saved) == "table" then
			votesA = math.max(0, tonumber(saved.A) or 0)
			votesB = math.max(0, tonumber(saved.B) or 0)
			if refreshVoteDisplayGlobal then
				refreshVoteDisplayGlobal()
			end
		end
	end
end)

type LeaderboardRowRef = {
	avatar: ImageLabel,
	nameLbl: TextLabel,
	valLbl: TextLabel,
}

type BoardRefs = {
	model: Model,
	podiumCF: CFrame,
	accentColor: Color3,
	rows: { LeaderboardRowRef },
	podiumLabel: TextLabel,
	currentStatueUserId: number?,
	statueModel: Model?,
	footerLabel: TextLabel?,
}
local boardRefs: { [string]: BoardRefs } = {}
local userNameCache: { [number]: string } = {}
local lastGlobalSync = 0
local globalTopCache: { [string]: { { userId: number, name: string, val: number } } } = {
	Playtime = {},
	Bux = {},
	Wins = {},
	Streak = {},
}

local orderedStores: { [string]: OrderedDataStore? } = {
	Playtime = nil,
	Bux = nil,
	Wins = nil,
	Streak = nil,
}
pcall(function()
	orderedStores.Playtime = DataStoreService:GetOrderedDataStore("BAF_TopPlaytime_v1")
	orderedStores.Bux = DataStoreService:GetOrderedDataStore("BAF_TopBux_v1")
	orderedStores.Wins = DataStoreService:GetOrderedDataStore("BAF_TopWins_v1")
	orderedStores.Streak = DataStoreService:GetOrderedDataStore("BAF_TopStreak_v1")
end)

local LobbyService = {}

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material?,
	canCollide: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = if canCollide == nil then true else canCollide
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeFloatingText(parent: BasePart, text: string, offset: Vector3, size: UDim2, color: Color3): TextLabel
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(8, 2.8)
	bb.StudsOffset = offset
	bb.MaxDistance = 120
	bb.AlwaysOnTop = false
	bb.Adornee = parent
	bb.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextScaled = true
	lbl.Text = text
	lbl.Parent = bb
	return lbl
end

local function createStoneLantern(parent: Instance, pos: Vector3)
	local m = Instance.new("Model")
	m.Name = "StoneLantern"
	local stone = Color3.fromRGB(102, 108, 118)
	local capStone = Color3.fromRGB(82, 88, 98)
	local iron = Color3.fromRGB(46, 50, 58)
	makePart(m, "Base", Vector3.new(2.2, 0.6, 2.2), CFrame.new(pos + Vector3.new(0, 0.3, 0)), stone, Enum.Material.Concrete)
	makePart(m, "Pillar", Vector3.new(1.2, 2.6, 1.2), CFrame.new(pos + Vector3.new(0, 1.9, 0)), stone, Enum.Material.Concrete)
	local core = makePart(
		m,
		"LampCore",
		Vector3.new(1.36, 1.36, 1.36),
		CFrame.new(pos + Vector3.new(0, 3.9, 0)),
		Color3.fromRGB(232, 196, 128),
		Enum.Material.SmoothPlastic
	)
	core.Transparency = 0.08
	for _, sx in { -0.68, 0.68 } do
		for _, sz in { -0.68, 0.68 } do
			makePart(m, "FrameBar", Vector3.new(0.14, 1.44, 0.14), CFrame.new(pos + Vector3.new(sx, 3.9, sz)), iron, Enum.Material.Metal)
		end
	end
	makePart(m, "Roof", Vector3.new(2.4, 0.5, 2.4), CFrame.new(pos + Vector3.new(0, 4.85, 0)), capStone, Enum.Material.Concrete)
	makePart(m, "Cap", Vector3.new(1.0, 0.5, 1.0), CFrame.new(pos + Vector3.new(0, 5.35, 0)), capStone, Enum.Material.Concrete)

	local light = Instance.new("PointLight")
	light.Brightness = 0.35
	light.Range = 8
	light.Color = Color3.fromRGB(255, 210, 140)
	light.Parent = core

	m.Parent = parent
end

local function createGoalPost(parent: Instance, xSide: number)
	local goalModel = Instance.new("Model")
	goalModel.Name = if xSide < 0 then "WestGoal" else "EastGoal"
	local white = Color3.new(1, 1, 1)
	local gx = xSide * 78
	makePart(goalModel, "PostL", Vector3.new(0.8, 10, 0.8), CFrame.new(gx, 5, -49), white, Enum.Material.SmoothPlastic)
	makePart(goalModel, "PostR", Vector3.new(0.8, 10, 0.8), CFrame.new(gx, 5, -29), white, Enum.Material.SmoothPlastic)
	makePart(goalModel, "Crossbar", Vector3.new(0.8, 0.8, 20.8), CFrame.new(gx, 10, -39), white, Enum.Material.SmoothPlastic)
	local net = makePart(goalModel, "Net", Vector3.new(3.5, 9.6, 20), CFrame.new(gx + xSide * 1.8, 4.8, -39), white, Enum.Material.Fabric, false)
	net.Transparency = 0.55
	goalModel.Parent = parent
end

local function formatComma(n: number): string
	local s = tostring(math.floor(n))
	local out = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
	while true do
		local nextOut, count = string.gsub(out, "^(-?%d+)(%d%d%d)", "%1,%2")
		out = nextOut
		if count == 0 then
			break
		end
	end
	return out
end

local function createLeaderboardBoard(
	parent: Instance,
	statKey: LeaderboardConfig.BoardStatKey
)
	local def = LeaderboardConfig.BOARDS[statKey]
	if not def then
		return
	end

	local boardCF = CFrame.lookAt(def.position, def.lookTarget)
	local model = LeaderboardBuilder.buildLeaderboard(statKey, boardCF, parent)
	LeaderboardBuilder.verifyGrounding(model)
	return model
end

local function createMythicalVoteAndFeedback(parent: Instance)
	local targetParent = if parent:FindFirstChild("Zones") then parent.Zones else parent
	local oldFb = targetParent:FindFirstChild("FeedbackMailbox") or parent:FindFirstChild("FeedbackMailbox")
	if oldFb then
		oldFb:Destroy()
	end
	local oldVote = targetParent:FindFirstChild("NextMythicalVote") or parent:FindFirstChild("NextMythicalVote")
	if oldVote then
		oldVote:Destroy()
	end

	-- Classic Curved-Top Blue Feedback Mailbox matching Image 4
	local fbModel = Instance.new("Model")
	fbModel.Name = "FeedbackMailbox"
	local mbCF = CFrame.new(16.5, 0, -83.5) * CFrame.Angles(0, math.rad(-25), 0)
	local boxCF = mbCF * CFrame.new(0, 3.85, 0)
	local mailBlue = Color3.fromHex("#1D7BF6")
	local mailDarkBlue = Color3.fromHex("#123C8A")

	makePart(fbModel, "BasePlinth", Vector3.new(2.1, 0.36, 2.1), mbCF * CFrame.new(0, 0.18, 0), Color3.fromRGB(104, 112, 128), Enum.Material.Concrete)
	makePart(fbModel, "Post", Vector3.new(0.68, 3.35, 0.68), mbCF * CFrame.new(0, 1.85, 0), Color3.fromRGB(98, 62, 38), Enum.Material.WoodPlanks)

	local boxLower = makePart(fbModel, "Box", Vector3.new(1.86, 1.06, 3.10), boxCF * CFrame.new(0, -0.22, 0), mailBlue, Enum.Material.SmoothPlastic)
	local boxArch = makePart(fbModel, "BoxArch", Vector3.new(3.10, 1.86, 1.86), boxCF * CFrame.new(0, 0.31, 0) * CFrame.Angles(0, math.rad(90), 0), mailBlue, Enum.Material.SmoothPlastic)
	boxArch.Shape = Enum.PartType.Cylinder

	makePart(fbModel, "FrontDoor", Vector3.new(1.66, 0.96, 0.10), boxCF * CFrame.new(0, -0.22, 1.52), mailDarkBlue, Enum.Material.SmoothPlastic, false)
	local doorArch = makePart(fbModel, "FrontDoorArch", Vector3.new(0.10, 1.66, 1.66), boxCF * CFrame.new(0, 0.26, 1.52) * CFrame.Angles(0, math.rad(90), 0), mailDarkBlue, Enum.Material.SmoothPlastic, false)
	doorArch.Shape = Enum.PartType.Cylinder

	makePart(fbModel, "MailSlot", Vector3.new(1.06, 0.13, 0.08), boxCF * CFrame.new(0, 0.22, 1.56), Color3.fromRGB(16, 20, 30), Enum.Material.SmoothPlastic, false)
	makePart(fbModel, "MailCardTag", Vector3.new(0.84, 0.28, 0.08), boxCF * CFrame.new(0, 0.56, 1.56), Color3.fromRGB(238, 244, 252), Enum.Material.SmoothPlastic, false)
	-- Mailbox flags removed per user request

	local fbBb = Instance.new("BillboardGui")
	fbBb.Name = "FeedbackBillboard"
	fbBb.Size = UDim2.fromScale(9.5, 3.0)
	fbBb.StudsOffset = Vector3.new(0, 3.25, 0)
	fbBb.MaxDistance = 95
	fbBb.Adornee = boxLower
	fbBb.Parent = boxLower

	local fbTop = Instance.new("TextLabel")
	fbTop.Size = UDim2.new(1, 0, 0.58, 0)
	fbTop.BackgroundTransparency = 1
	fbTop.Font = Enum.Font.FredokaOne
	fbTop.TextColor3 = Color3.new(1, 1, 1)
	fbTop.TextStrokeTransparency = 0
	fbTop.TextScaled = true
	fbTop.Text = "FEEDBACK"
	fbTop.Parent = fbBb

	local fbSub = Instance.new("TextLabel")
	fbSub.Size = UDim2.new(1, 0, 0.38, 0)
	fbSub.Position = UDim2.new(0, 0, 0.58, 0)
	fbSub.BackgroundTransparency = 1
	fbSub.Font = Enum.Font.FredokaOne
	fbSub.TextColor3 = Color3.fromHex("#93C5FD")
	fbSub.TextStrokeTransparency = 0
	fbSub.TextScaled = true
	fbSub.Text = "Tell us what you think!"
	fbSub.Parent = fbBb

	local fbPrompt = Instance.new("ProximityPrompt")
	fbPrompt.ObjectText = "Feedback"
	fbPrompt.ActionText = "Share Your Feedback"
	fbPrompt.HoldDuration = 0
	fbPrompt.MaxActivationDistance = 14
	fbPrompt.RequiresLineOfSight = false
	fbPrompt.Parent = boxLower
	fbPrompt.Triggered:Connect(function(player)
		Remotes.FeedbackSync:FireClient(player, { kind = "Open" })
	end)

	for _, part in fbModel:GetChildren() do
		if part:IsA("BasePart") then
			local fbClick = Instance.new("ClickDetector")
			fbClick.MaxActivationDistance = 24
			fbClick.Parent = part
			fbClick.MouseClick:Connect(function(player)
				Remotes.FeedbackSync:FireClient(player, { kind = "Open" })
			end)
		end
	end

	fbModel.PrimaryPart = boxLower
	fbModel.Parent = targetParent

	local voteModel = Instance.new("Model")
	voteModel.Name = "NextMythicalVote"

	-- Placed along South touchline (replaces quarantined AdBoard_South_3 at X=-28)
	local stationCF = CFrame.new(-28, 0, 20) * CFrame.Angles(0, math.rad(180), 0)
	local darkSteel = Color3.fromRGB(32, 36, 46)
	local gantryWhite = Color3.fromRGB(242, 245, 252)
	local goldAccent = Color3.fromHex("#FFD21F")
	local neonGold = Color3.fromHex("#FFE600")

	-- 1. Football Stadium Scoreboard Gantry & Floodlight Truss (Football Theme)
	local cylVert = CFrame.Angles(0, 0, math.rad(90))
	for _, side in { -1, 1 } do
		local px = side * 9.4
		-- Heavy concrete stadium footing
		makePart(voteModel, `GantryBase_{side}`, Vector3.new(3.6, 1.2, 3.6), stationCF * CFrame.new(px, 0.6, -1.8), Color3.fromRGB(78, 84, 96), Enum.Material.Concrete)
		-- White tubular steel goalpost/gantry pillar
		local pillar = makePart(voteModel, `GantryPillar_{side}`, Vector3.new(16.8, 1.75, 1.75), stationCF * CFrame.new(px, 9.6, -1.8) * cylVert, gantryWhite, Enum.Material.SmoothPlastic)
		pillar.Shape = Enum.PartType.Cylinder
		-- Dark steel mounting brackets
		local ringBot = makePart(voteModel, `PillarRingBot_{side}`, Vector3.new(0.5, 2.1, 2.1), stationCF * CFrame.new(px, 1.8, -1.8) * cylVert, darkSteel, Enum.Material.Metal)
		ringBot.Shape = Enum.PartType.Cylinder
		local ringTop = makePart(voteModel, `PillarRingTop_{side}`, Vector3.new(0.5, 2.1, 2.1), stationCF * CFrame.new(px, 14.2, -1.8) * cylVert, darkSteel, Enum.Material.Metal)
		ringTop.Shape = Enum.PartType.Cylinder
		-- Diagonal cross-bracing struts
		makePart(voteModel, `PillarBrace_{side}`, Vector3.new(0.8, 6.2, 0.8), stationCF * CFrame.new(side * 8.0, 15.6, -1.8) * CFrame.Angles(0, 0, math.rad(side * 28)), darkSteel, Enum.Material.Metal)
	end

	-- Stadium overhead crossbar truss & neon stadium bar
	makePart(voteModel, "CrossbarTruss", Vector3.new(22.6, 1.35, 1.6), stationCF * CFrame.new(0, 14.8, -1.8), gantryWhite, Enum.Material.SmoothPlastic)
	makePart(voteModel, "CrossbarTrimNeon", Vector3.new(20.4, 0.28, 0.28), stationCF * CFrame.new(0, 14.2, -0.95), neonGold, Enum.Material.Neon)
	makePart(voteModel, "UpperGantryBeam", Vector3.new(23.6, 1.0, 1.4), stationCF * CFrame.new(0, 17.6, -1.8), darkSteel, Enum.Material.Metal)

	-- Football Goal Net Mesh behind the scoreboard
	local goalNet = makePart(voteModel, "GoalNetMesh", Vector3.new(19.2, 11.6, 0.2), stationCF * CFrame.new(0, 7.35, -1.6), Color3.fromRGB(248, 250, 255), Enum.Material.Fabric, false)
	goalNet.Transparency = 0.58

	-- 4 Stadium Spotlights on top of crossbar illuminating the voting board
	for _, lx in { -6.8, -2.3, 2.3, 6.8 } do
		local lampCF = stationCF * CFrame.new(lx, 15.9, -1.3) * CFrame.Angles(math.rad(-22), 0, 0)
		makePart(voteModel, `ScoreboardLampBox_{lx}`, Vector3.new(2.4, 1.3, 1.0), lampCF, darkSteel, Enum.Material.Metal)
		local lampFace = makePart(voteModel, `ScoreboardLamp_{lx}`, Vector3.new(2.1, 1.0, 0.3), lampCF * CFrame.new(0, 0, 0.5), Color3.fromRGB(245, 248, 255), Enum.Material.Neon)
		local spot = Instance.new("SpotLight")
		spot.Brightness = 1.1
		spot.Range = 28
		spot.Angle = 65
		spot.Face = Enum.NormalId.Front
		spot.Parent = lampFace
	end

	-- Golden Ballon d'Or Trophy & Rocky Base atop the scoreboard gantry
	local trophyPrefab = ReplicatedStorage:FindFirstChild("Prefabs") and ReplicatedStorage.Prefabs:FindFirstChild("GoldenFootballTrophy")
	if trophyPrefab then
		local trophy = trophyPrefab:Clone()
		trophy.Parent = voteModel
		trophy:PivotTo(stationCF * CFrame.new(0, 22.292, -1.8) * CFrame.Angles(0, math.rad(180), 0))
	else
		local trophyBase = makePart(voteModel, "TrophyPedestal", Vector3.new(4.6, 0.85, 2.6), stationCF * CFrame.new(0, 18.5, -1.8), goldAccent, Enum.Material.Metal)
		trophyBase.Reflectance = 0.35
		local goldenBall = makePart(voteModel, "GoldenFootballBallonDor", Vector3.new(2.8, 2.8, 2.8), stationCF * CFrame.new(0, 20.3, -1.8), goldAccent, Enum.Material.Metal, false)
		goldenBall.Shape = Enum.PartType.Ball
		goldenBall.Reflectance = 0.45
	end

	-- Stadium Corner Flags on the sides (replaces old stone lanterns!)
	local function createStadiumCornerFlag(parentModel: Instance, pos: Vector3, isYellow: boolean?)
		local cfModel = Instance.new("Model")
		cfModel.Name = "StadiumCornerFlag"
		makePart(cfModel, "GrassBase", Vector3.new(2.4, 0.35, 2.4), CFrame.new(pos + Vector3.new(0, 0.18, 0)), Color3.fromHex("#22C55E"), Enum.Material.Grass).Shape = Enum.PartType.Cylinder
		makePart(cfModel, "FlagSpring", Vector3.new(0.55, 0.7, 0.55), CFrame.new(pos + Vector3.new(0, 0.65, 0)), darkSteel, Enum.Material.Metal).Shape = Enum.PartType.Cylinder
		makePart(cfModel, "FlagPole", Vector3.new(0.22, 6.4, 0.22), CFrame.new(pos + Vector3.new(0, 3.8, 0)), Color3.fromRGB(248, 250, 255), Enum.Material.SmoothPlastic).Shape = Enum.PartType.Cylinder
		local flagCol = if isYellow then Color3.fromHex("#FFD21F") else Color3.fromHex("#EF233C")
		makePart(cfModel, "FlagCloth", Vector3.new(0.06, 1.7, 2.5), CFrame.new(pos + Vector3.new(0, 6.0, 1.25)), flagCol, Enum.Material.Fabric, false)
		cfModel.Parent = parentModel
	end
	-- Stadium Corner Flags disabled per user request
	-- createStadiumCornerFlag(voteModel, (stationCF * CFrame.new(-12.5, 0, 1.8)).Position, false)
	-- createStadiumCornerFlag(voteModel, (stationCF * CFrame.new(15.8, 0, 2.2)).Position, true)

	-- Floating "⭐ BALLON D'OR VOTE ⭐" banner pinned right above the board
	local topSignPlate = makePart(voteModel, "LikeVoteHeaderPlate", Vector3.new(15.2, 1.85, 0.08), stationCF * CFrame.new(0, 13.55, 0.35), darkSteel, Enum.Material.SmoothPlastic, false)
	topSignPlate.Transparency = 1
	local topSg = Instance.new("SurfaceGui")
	topSg.Face = Enum.NormalId.Back
	topSg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	topSg.PixelsPerStud = 48
	topSg.LightInfluence = 0
	topSg.Brightness = 1.2
	topSg.Parent = topSignPlate
	local topHeaderLbl = Instance.new("TextLabel")
	topHeaderLbl.Size = UDim2.fromScale(1, 1)
	topHeaderLbl.BackgroundTransparency = 1
	topHeaderLbl.Font = Enum.Font.FredokaOne
	topHeaderLbl.TextColor3 = Color3.fromHex("#FFD21F")
	topHeaderLbl.TextStrokeTransparency = 0
	topHeaderLbl.TextStrokeColor3 = Color3.fromRGB(24, 28, 38)
	topHeaderLbl.TextScaled = true
	topHeaderLbl.Text = "⭐ BALLON D'OR VOTE ⭐"
	topHeaderLbl.Parent = topSg

	-- 2. Main Stadium Jumbotron LED Scoreboard
	local boardCF = stationCF * CFrame.new(0, 7.35, 0)
	local boardW, boardH = 17.2, 10.4
	local board = makePart(voteModel, "VoteBoard", Vector3.new(boardW, boardH, 0.85), boardCF, Color3.fromRGB(24, 28, 38), Enum.Material.Metal)
	makePart(voteModel, "NeonBorderTop", Vector3.new(boardW + 0.9, 0.48, 1.05), boardCF * CFrame.new(0, boardH * 0.5 + 0.22, 0.05), neonGold, Enum.Material.Neon)
	makePart(voteModel, "NeonBorderBot", Vector3.new(boardW + 0.9, 0.48, 1.05), boardCF * CFrame.new(0, -boardH * 0.5 - 0.22, 0.05), neonGold, Enum.Material.Neon)
	makePart(voteModel, "NeonBorderL", Vector3.new(0.48, boardH + 0.9, 1.05), boardCF * CFrame.new(-boardW * 0.5 - 0.22, 0, 0.05), neonGold, Enum.Material.Neon)
	makePart(voteModel, "NeonBorderR", Vector3.new(0.48, boardH + 0.9, 1.05), boardCF * CFrame.new(boardW * 0.5 + 0.22, 0, 0.05), neonGold, Enum.Material.Neon)

	local sg = Instance.new("SurfaceGui")
	sg.Name = "VoteBoardGui"
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 48
	sg.LightInfluence = 0
	sg.Brightness = 1.2
	sg.Parent = board

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	frame.BorderSizePixel = 0
	frame.Parent = sg

	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(0.96, 0, 0.14, 0)
	banner.Position = UDim2.new(0.02, 0, 0.025, 0)
	banner.BackgroundColor3 = Color3.fromHex("#1E3A8A")
	banner.Parent = frame
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = banner
	local bs = Instance.new("UIStroke")
	bs.Color = Color3.fromRGB(16, 24, 48)
	bs.Thickness = 3
	bs.Parent = banner
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new(Color3.fromHex("#2563EB"), Color3.fromHex("#1D4ED8"))
	bgGrad.Rotation = 90
	bgGrad.Parent = banner

	local bannerLbl = Instance.new("TextLabel")
	bannerLbl.Size = UDim2.new(0.94, 0, 0.84, 0)
	bannerLbl.Position = UDim2.new(0.03, 0, 0.08, 0)
	bannerLbl.BackgroundTransparency = 1
	bannerLbl.Font = Enum.Font.FredokaOne
	bannerLbl.TextColor3 = Color3.new(1, 1, 1)
	bannerLbl.TextStrokeTransparency = 0
	bannerLbl.TextScaled = true
	bannerLbl.Text = "⚽ NEXT MYTHICAL VOTE ⚽"
	bannerLbl.Parent = banner
	bgGrad.Rotation = 90
	bgGrad.Parent = banner

	local bannerLbl = Instance.new("TextLabel")
	bannerLbl.Size = UDim2.new(0.94, 0, 0.84, 0)
	bannerLbl.Position = UDim2.new(0.03, 0, 0.08, 0)
	bannerLbl.BackgroundTransparency = 1
	bannerLbl.Font = Enum.Font.FredokaOne
	bannerLbl.TextColor3 = Color3.new(1, 1, 1)
	bannerLbl.TextStrokeTransparency = 0
	bannerLbl.TextScaled = true
	bannerLbl.Text = "⚽ NEXT MYTHICAL VOTE ⚽"
	bannerLbl.Parent = banner

	local function makePortraitBackdrop(xPos: number, topCol: Color3, botCol: Color3, strokeCol: Color3)
		local pBox = Instance.new("Frame")
		pBox.Size = UDim2.new(0.285, 0, 0.51, 0)
		pBox.Position = UDim2.new(xPos, 0, 0.20, 0)
		pBox.BackgroundColor3 = Color3.new(1, 1, 1)
		pBox.Parent = frame
		local pc = Instance.new("UICorner")
		pc.CornerRadius = UDim.new(0, 8)
		pc.Parent = pBox
		local ps = Instance.new("UIStroke")
		ps.Color = strokeCol
		ps.Thickness = 5
		ps.Parent = pBox
		local pg = Instance.new("UIGradient")
		pg.Color = ColorSequence.new(topCol, botCol)
		pg.Rotation = 90
		pg.Parent = pBox
	end

	makePortraitBackdrop(0.045, Color3.fromHex("#38BDF8"), Color3.fromHex("#0F172A"), Color3.fromHex("#7C3AED"))
	makePortraitBackdrop(0.670, Color3.fromHex("#F59E0B"), Color3.fromHex("#1E1028"), Color3.fromHex("#9333EA"))

	-- Mount real 3D upper-body busts of Lionel Messi & Cristiano Ronaldo on the portrait frames
	local lowerBodyNames = {
		ShortsWaist = true,
		ShortsL = true,
		ShortsR = true,
		ShortsTrimL = true,
		ShortsTrimR = true,
		LegL = true,
		LegR = true,
		SocksL = true,
		SocksR = true,
		BootL = true,
		BootR = true,
	}
	local function mountContenderBust(cardId: string, localX: number, subTitle: string, fullName: string, nameCol: Color3, auraCol: Color3)
		local card = Footballers.ById[cardId]
		if card then
			local bust = FootballerModelBuilder.buildModel(card)
			bust.Name = `Bust_{cardId}`
			for _, ch in bust:GetChildren() do
				if lowerBodyNames[ch.Name] then
					ch:Destroy()
				end
			end
			bust:ScaleTo(1.12)
			bust:PivotTo(boardCF * CFrame.new(localX, -0.05, 0.58) * CFrame.Angles(0, math.rad(180), 0))
			bust.Parent = voteModel

			local auraAnchor = makePart(voteModel, `Aura_{cardId}`, Vector3.new(3.6, 3.8, 0.1), boardCF * CFrame.new(localX, 0.45, 0.46), auraCol, Enum.Material.SmoothPlastic, false)
			auraAnchor.Transparency = 1
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Color = ColorSequence.new(Color3.fromHex("#A855F7"), auraCol)
			pe.LightEmission = 0.85
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.45),
				NumberSequenceKeypoint.new(0.6, 0.85),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.25),
				NumberSequenceKeypoint.new(1, 1),
			})
			pe.Lifetime = NumberRange.new(0.7, 1.2)
			pe.Rate = 12
			pe.Speed = NumberRange.new(0.8, 1.8)
			pe.SpreadAngle = Vector2.new(25, 25)
			pe.Parent = auraAnchor
		end

		local plate = makePart(voteModel, `Nameplate_{cardId}`, Vector3.new(4.65, 1.08, 0.16), boardCF * CFrame.new(localX, -1.45, 1.18), Color3.fromRGB(16, 18, 28), Enum.Material.SmoothPlastic, false)
		local psg = Instance.new("SurfaceGui")
		psg.Face = Enum.NormalId.Back
		psg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		psg.PixelsPerStud = 48
		psg.Parent = plate

		local l1 = Instance.new("TextLabel")
		l1.Size = UDim2.new(0.94, 0, 0.42, 0)
		l1.Position = UDim2.new(0.03, 0, 0.04, 0)
		l1.BackgroundTransparency = 1
		l1.Font = Enum.Font.FredokaOne
		l1.TextColor3 = Color3.new(1, 1, 1)
		l1.TextStrokeTransparency = 0
		l1.TextScaled = true
		l1.Text = subTitle
		l1.Parent = psg

		local l2 = Instance.new("TextLabel")
		l2.Size = UDim2.new(0.96, 0, 0.50, 0)
		l2.Position = UDim2.new(0.02, 0, 0.46, 0)
		l2.BackgroundTransparency = 1
		l2.Font = Enum.Font.FredokaOne
		l2.TextColor3 = nameCol
		l2.TextStrokeTransparency = 0
		l2.TextScaled = true
		l2.Text = fullName
		l2.Parent = psg
	end

	mountContenderBust("messi", -5.38, "GOAT #10", "LIONEL MESSI", Color3.fromHex("#7DD3FC"), Color3.fromHex("#38BDF8"))
	mountContenderBust("ronaldo", 5.38, "CR7 #7", "CRISTIANO RONALDO", Color3.fromHex("#FFD21F"), Color3.fromHex("#F59E0B"))

	-- Center VS + Split Bar + Votes Count + Status
	local vsLbl = Instance.new("TextLabel")
	vsLbl.Size = UDim2.new(0.28, 0, 0.13, 0)
	vsLbl.Position = UDim2.new(0.36, 0, 0.24, 0)
	vsLbl.BackgroundTransparency = 1
	vsLbl.Font = Enum.Font.FredokaOne
	vsLbl.TextColor3 = Color3.fromHex("#FACC15")
	vsLbl.TextStrokeTransparency = 0
	vsLbl.TextScaled = true
	vsLbl.Text = "VS"
	vsLbl.Parent = frame

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.30, 0, 0.11, 0)
	barBg.Position = UDim2.new(0.35, 0, 0.39, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	barBg.ClipsDescendants = true
	barBg.Parent = frame
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = barBg
	local barStroke = Instance.new("UIStroke")
	barStroke.Color = Color3.new(0, 0, 0)
	barStroke.Thickness = 3
	barStroke.Parent = barBg

	local messiBar = Instance.new("Frame")
	messiBar.Size = UDim2.fromScale(0.55, 1)
	messiBar.BackgroundColor3 = Color3.fromHex("#7DD3FC")
	messiBar.BorderSizePixel = 0
	messiBar.Parent = barBg

	local ronaldoBar = Instance.new("Frame")
	ronaldoBar.AnchorPoint = Vector2.new(1, 0)
	ronaldoBar.Position = UDim2.fromScale(1, 0)
	ronaldoBar.Size = UDim2.fromScale(0.45, 1)
	ronaldoBar.BackgroundColor3 = Color3.fromHex("#FBBF24")
	ronaldoBar.BorderSizePixel = 0
	ronaldoBar.Parent = barBg

	local pctALbl = Instance.new("TextLabel")
	pctALbl.Size = UDim2.new(0.46, 0, 0.88, 0)
	pctALbl.Position = UDim2.new(0.03, 0, 0.06, 0)
	pctALbl.BackgroundTransparency = 1
	pctALbl.Font = Enum.Font.FredokaOne
	pctALbl.TextColor3 = Color3.new(1, 1, 1)
	pctALbl.TextStrokeTransparency = 0
	pctALbl.TextXAlignment = Enum.TextXAlignment.Left
	pctALbl.TextScaled = true
	pctALbl.ZIndex = 3
	pctALbl.Parent = barBg

	local pctBLbl = Instance.new("TextLabel")
	pctBLbl.Size = UDim2.new(0.46, 0, 0.88, 0)
	pctBLbl.Position = UDim2.new(0.51, 0, 0.06, 0)
	pctBLbl.BackgroundTransparency = 1
	pctBLbl.Font = Enum.Font.FredokaOne
	pctBLbl.TextColor3 = Color3.new(1, 1, 1)
	pctBLbl.TextStrokeTransparency = 0
	pctBLbl.TextXAlignment = Enum.TextXAlignment.Right
	pctBLbl.TextScaled = true
	pctBLbl.ZIndex = 3
	pctBLbl.Parent = barBg

	local totalVotesLbl = Instance.new("TextLabel")
	totalVotesLbl.Size = UDim2.new(0.32, 0, 0.075, 0)
	totalVotesLbl.Position = UDim2.new(0.34, 0, 0.52, 0)
	totalVotesLbl.BackgroundTransparency = 1
	totalVotesLbl.Font = Enum.Font.FredokaOne
	totalVotesLbl.TextColor3 = Color3.new(1, 1, 1)
	totalVotesLbl.TextStrokeTransparency = 0
	totalVotesLbl.TextScaled = true
	totalVotesLbl.Parent = frame

	local playerVoteStatusLbl = Instance.new("TextLabel")
	playerVoteStatusLbl.Name = "PlayerVoteStatus"
	playerVoteStatusLbl.Size = UDim2.new(0.34, 0, 0.055, 0)
	playerVoteStatusLbl.Position = UDim2.new(0.33, 0, 0.61, 0)
	playerVoteStatusLbl.BackgroundTransparency = 1
	playerVoteStatusLbl.Font = Enum.Font.FredokaOne
	playerVoteStatusLbl.TextColor3 = Color3.new(1, 1, 1)
	playerVoteStatusLbl.TextStrokeTransparency = 0
	playerVoteStatusLbl.TextScaled = true
	playerVoteStatusLbl.Text = "(STEP ON A PAD OR PRESS [E] TO VOTE!)"
	playerVoteStatusLbl.Parent = frame

	local footer1 = Instance.new("TextLabel")
	footer1.Size = UDim2.new(0.90, 0, 0.095, 0)
	footer1.Position = UDim2.new(0.05, 0, 0.74, 0)
	footer1.BackgroundTransparency = 1
	footer1.Font = Enum.Font.FredokaOne
	footer1.TextColor3 = Color3.new(1, 1, 1)
	footer1.TextStrokeTransparency = 0
	footer1.TextScaled = true
	footer1.Text = "⚽ PLAY 5 MINUTES IN SERVER TO VOTE!"
	footer1.Parent = frame

	local footer2 = Instance.new("TextLabel")
	footer2.Size = UDim2.new(0.92, 0, 0.082, 0)
	footer2.Position = UDim2.new(0.04, 0, 0.86, 0)
	footer2.BackgroundTransparency = 1
	footer2.Font = Enum.Font.FredokaOne
	footer2.TextColor3 = Color3.fromHex("#4ADE80")
	footer2.TextStrokeTransparency = 0
	footer2.TextScaled = true
	footer2.Text = "VOTE GOAL! The winner is coming next update!"
	footer2.Parent = frame

	local function refreshVoteText()
		local total = votesA + votesB
		local pctA = 50
		local pctB = 50
		if total > 0 then
			pctA = math.round((votesA / total) * 100)
			pctB = 100 - pctA
			messiBar.Size = UDim2.fromScale(pctA / 100, 1)
			ronaldoBar.Size = UDim2.fromScale(pctB / 100, 1)
		else
			messiBar.Size = UDim2.fromScale(0.5, 1)
			ronaldoBar.Size = UDim2.fromScale(0.5, 1)
		end
		pctALbl.Text = `{pctA}%`
		pctBLbl.Text = `{pctB}%`
		totalVotesLbl.Text = `{formatComma(total)} {if total == 1 then "VOTE" else "VOTES"}`
	end
	refreshVoteDisplayGlobal = refreshVoteText
	refreshVoteText()

	-- 3. Right-side "LIKE THE GAME!" sign matching Image 2
	local sideSignCF = stationCF * CFrame.new(12.2, 0, 1.8) * CFrame.Angles(0, math.rad(-14), math.rad(-4))
	makePart(voteModel, "LikeSignPost", Vector3.new(0.55, 4.6, 0.55), sideSignCF * CFrame.new(0, 2.3, 0), Color3.fromHex("#4A2E1B"), Enum.Material.Wood)
	makePart(voteModel, "LikeSignBorder", Vector3.new(6.8, 3.9, 0.34), sideSignCF * CFrame.new(0, 4.9, 0.05), Color3.fromHex("#3B2314"), Enum.Material.Wood)
	local signFace = makePart(voteModel, "LikeSignFace", Vector3.new(6.3, 3.4, 0.38), sideSignCF * CFrame.new(0, 4.9, 0.08), Color3.fromRGB(24, 28, 38), Enum.Material.SmoothPlastic)
	local signSg = Instance.new("SurfaceGui")
	signSg.Face = Enum.NormalId.Back
	signSg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signSg.PixelsPerStud = 48
	signSg.LightInfluence = 0
	signSg.Brightness = 1.2
	signSg.Parent = signFace

	local signTop = Instance.new("TextLabel")
	signTop.Size = UDim2.new(0.94, 0, 0.38, 0)
	signTop.Position = UDim2.new(0.03, 0, 0.06, 0)
	signTop.BackgroundTransparency = 1
	signTop.Font = Enum.Font.FredokaOne
	signTop.TextColor3 = Color3.fromHex("#4ADE80")
	signTop.TextStrokeTransparency = 0
	signTop.TextScaled = true
	signTop.Text = "⚽ PLAY TO VOTE!"
	signTop.Parent = signSg

	local signBot = Instance.new("TextLabel")
	signBot.Size = UDim2.new(0.92, 0, 0.48, 0)
	signBot.Position = UDim2.new(0.04, 0, 0.46, 0)
	signBot.BackgroundTransparency = 1
	signBot.Font = Enum.Font.FredokaOne
	signBot.TextColor3 = Color3.new(1, 1, 1)
	signBot.TextStrokeTransparency = 0
	signBot.TextScaled = true
	signBot.Text = "Play 5 minutes in this server\nto unlock your vote!"
	signBot.Parent = signSg

	-- 4. Framed Floor Portrait Vote Pads with Football Pitch Chalk Lines
	makePart(voteModel, "PitchChalkBoxF", Vector3.new(14.8, 0.06, 0.28), stationCF * CFrame.new(0, 0.08, 9.2), Color3.fromRGB(248, 250, 255), Enum.Material.SmoothPlastic, false)
	makePart(voteModel, "PitchChalkBoxL", Vector3.new(0.28, 0.06, 6.2), stationCF * CFrame.new(-7.4, 0.08, 6.2), Color3.fromRGB(248, 250, 255), Enum.Material.SmoothPlastic, false)
	makePart(voteModel, "PitchChalkBoxR", Vector3.new(0.28, 0.06, 6.2), stationCF * CFrame.new(7.4, 0.08, 6.2), Color3.fromRGB(248, 250, 255), Enum.Material.SmoothPlastic, false)

	local function sendPlayerToast(player: Player, message: string)
		Remotes.MetaAction:FireClient(player, "Toast", message)
	end

	local function getPlayerSessionSeconds(player: Player): number
		if VoteConfig.COUNT_ONLY_ACTIVE_TIME then
			return math.max(0, math.floor(playerActiveSeconds[player.UserId] or 0))
		end
		local sessionStart = ProfileService.getSessionJoinTime(player)
		return math.max(0, math.floor(Workspace:GetServerTimeNow() - sessionStart))
	end

	local function isNearPad(player: Player, choice: ("A" | "B")?): boolean
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not hrp then return false end
		local padA = (stationCF * CFrame.new(-3.6, 0, 6.2)).Position
		local padB = (stationCF * CFrame.new(3.6, 0, 6.2)).Position
		if choice == "A" then
			return (hrp.Position - padA).Magnitude <= VoteConfig.MAX_PAD_DISTANCE
		elseif choice == "B" then
			return (hrp.Position - padB).Magnitude <= VoteConfig.MAX_PAD_DISTANCE
		else
			return math.min((hrp.Position - padA).Magnitude, (hrp.Position - padB).Magnitude) <= VoteConfig.MAX_PAD_DISTANCE
		end
	end

	local function castVote(player: Player, choice: "A" | "B", checkDistance: boolean?)
		if not isVoteRoundOpen then
			sendPlayerToast(player, "Voting is closed")
			return
		end

		if checkDistance and not isNearPad(player, choice) then
			sendPlayerToast(player, "Step closer to the voting pad!")
			return
		end

		if playerVoted[player.UserId] ~= nil then
			sendPlayerToast(player, "You already voted this round")
			return
		end

		local now = Workspace:GetServerTimeNow()
		if now - (lastVoteRequestTime[player.UserId] or 0) < VoteConfig.RATE_LIMIT_SECONDS then
			return
		end
		lastVoteRequestTime[player.UserId] = now

		local elapsed = getPlayerSessionSeconds(player)
		if elapsed < VoteConfig.MIN_SESSION_SECONDS then
			local remaining = math.ceil(VoteConfig.MIN_SESSION_SECONDS - elapsed)
			Remotes.OpenVoteLockedPopup:FireClient(player, {
				remaining = remaining,
				candidateId = choice,
				minSession = VoteConfig.MIN_SESSION_SECONDS,
			})
			return
		end

		-- Session elapsed >= MIN_SESSION_SECONDS -> Cast the vote!
		playerVoted[player.UserId] = choice
		votedPlayers[player] = choice
		if choice == "A" then
			votesA += 1
			player:SetAttribute("MythicalVote", "Messi")
		else
			votesB += 1
			player:SetAttribute("MythicalVote", "Ronaldo")
		end

		playerVoteStatusLbl.Text = `✔ YOUR VOTE: {if choice == "A" then "LIONEL MESSI" else "CRISTIANO RONALDO"}`
		playerVoteStatusLbl.TextColor3 = if choice == "A" then Color3.fromHex("#38BDF8") else Color3.fromHex("#FBBF24")
		refreshVoteText()
		ProfileService.recordQuestProgress(player, "vote_mythical", 1)

		local candName = if choice == "A" then "LIONEL MESSI" else "CRISTIANO RONALDO"
		sendPlayerToast(player, `Vote cast for {candName}!`)

		if voteStore then
			task.spawn(function()
				pcall(function()
					voteStore:UpdateAsync("GlobalTally", function(old)
						local t = if type(old) == "table" then old else { A = 0, B = 0 }
						if choice == "A" then
							t.A = (tonumber(t.A) or 0) + 1
						else
							t.B = (tonumber(t.B) or 0) + 1
						end
						return t
					end)
				end)
			end)
		end
	end

	local function createFloorVotePad(padName: string, choice: "A" | "B", localX: number, frameCol: Color3, tileCol: Color3, displayTitle: string, jerseyTag: string, titleCol: Color3)
		local padCF = stationCF * CFrame.new(localX, 0, 6.2)
		makePart(voteModel, `{padName}_Frame`, Vector3.new(4.9, 0.32, 4.9), padCF * CFrame.new(0, 0.16, 0), frameCol, Enum.Material.SmoothPlastic)
		local pad = makePart(voteModel, padName, Vector3.new(4.2, 0.38, 4.2), padCF * CFrame.new(0, 0.19, 0), tileCol, Enum.Material.SmoothPlastic)

		local tileSg = Instance.new("SurfaceGui")
		tileSg.Face = Enum.NormalId.Top
		tileSg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		tileSg.PixelsPerStud = 42
		tileSg.LightInfluence = 0
		tileSg.Brightness = 1.2
		tileSg.Parent = pad
		local tileWrap = Instance.new("Frame")
		tileWrap.Size = UDim2.fromScale(1, 1)
		tileWrap.BackgroundColor3 = tileCol
		tileWrap.Rotation = 180
		tileWrap.Parent = tileSg
		local tileLbl = Instance.new("TextLabel")
		tileLbl.Size = UDim2.new(0.9, 0, 0.8, 0)
		tileLbl.Position = UDim2.new(0.05, 0, 0.1, 0)
		tileLbl.BackgroundTransparency = 1
		tileLbl.Font = Enum.Font.FredokaOne
		tileLbl.TextColor3 = titleCol
		tileLbl.TextStrokeTransparency = 0
		tileLbl.TextScaled = true
		tileLbl.Text = jerseyTag
		tileLbl.Parent = tileWrap

		local pbb = Instance.new("BillboardGui")
		pbb.Name = "VotePadBillboard"
		pbb.Size = UDim2.fromScale(7.2, 2.2)
		pbb.StudsOffset = Vector3.new(0, 3.2, 0)
		pbb.MaxDistance = 80
		pbb.AlwaysOnTop = false
		pbb.Adornee = pad
		pbb.Parent = pad

		local pNameLbl = Instance.new("TextLabel")
		pNameLbl.Name = "ContenderLabel"
		pNameLbl.Size = UDim2.new(1, 0, 0.50, 0)
		pNameLbl.Position = UDim2.new(0, 0, 0, 0)
		pNameLbl.BackgroundTransparency = 1
		pNameLbl.Font = Enum.Font.FredokaOne
		pNameLbl.TextColor3 = titleCol
		pNameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		pNameLbl.TextStrokeTransparency = 0
		pNameLbl.TextScaled = true
		pNameLbl.Text = displayTitle
		pNameLbl.Parent = pbb

		local yourVoteLbl = Instance.new("TextLabel")
		yourVoteLbl.Name = "YourVoteTag"
		yourVoteLbl.Size = UDim2.new(1, 0, 0.48, 0)
		yourVoteLbl.Position = UDim2.new(0, 0, 0.50, 0)
		yourVoteLbl.BackgroundTransparency = 1
		yourVoteLbl.Font = Enum.Font.FredokaOne
		yourVoteLbl.TextColor3 = Color3.fromHex("#4ADE80")
		yourVoteLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		yourVoteLbl.TextStrokeTransparency = 0
		yourVoteLbl.TextScaled = true
		yourVoteLbl.Text = "✓YOUR VOTE"
		yourVoteLbl.Visible = false
		yourVoteLbl.Parent = pbb

		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = displayTitle
		prompt.ActionText = "Vote"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = pad
		prompt.Triggered:Connect(function(player)
			castVote(player, choice, true)
		end)

		pad.Touched:Connect(function(hit)
			local plr = if hit.Parent then Players:GetPlayerFromCharacter(hit.Parent) else nil
			if not plr then
				return
			end
			local now = os.clock()
			if now - (voteTouchDebounce[plr] or 0) < 1.2 then
				return
			end
			voteTouchDebounce[plr] = now
			castVote(plr, choice, true)
		end)
	end

	createFloorVotePad("VotePadA", "A", -3.6, Color3.fromHex("#2563EB"), Color3.fromHex("#0F172A"), "LIONEL MESSI", "⚽ #10\nMESSI", Color3.new(1, 1, 1))
	createFloorVotePad("VotePadB", "B", 3.6, Color3.fromHex("#F59E0B"), Color3.fromHex("#1E1028"), "CRISTIANO RONALDO", "⚽ #7\nRONALDO", Color3.fromHex("#FBBF24"))

	if not metaActionBound then
		metaActionBound = true

		Remotes.RequestVote.OnServerEvent:Connect(function(player, choiceArg)
			local choice: "A" | "B" = if (choiceArg == "A" or choiceArg == "Messi") then "A" else "B"
			castVote(player, choice, true)
		end)

		Remotes.ActivityPing.OnServerEvent:Connect(function(player)
			if not VoteConfig.COUNT_ONLY_ACTIVE_TIME then return end
			local now = Workspace:GetServerTimeNow()
			local lastPing = playerLastActive[player.UserId] or now
			if now - lastPing < 9.5 then
				return
			end
			local delta = math.min(now - lastPing, VoteConfig.AFK_THRESHOLD_SECONDS)
			playerActiveSeconds[player.UserId] = (playerActiveSeconds[player.UserId] or 0) + delta
			playerLastActive[player.UserId] = now
		end)

		Remotes.MetaAction.OnServerEvent:Connect(function(player, action, arg)
			if action == "VoteMythical" and typeof(arg) == "string" then
				local choice: "A" | "B" = if (arg == "A" or arg == "Messi") then "A" else "B"
				castVote(player, choice, true)
			elseif action == "ConfirmLikeAndVote" and typeof(arg) == "string" then
				local choice: "A" | "B" = if (arg == "A" or arg == "Messi") then "A" else "B"
				castVote(player, choice, true)
			end
		end)
	end

	voteModel.Parent = targetParent
end

local function buildSlapHandParts(container: Instance, rootCF: CFrame, scale: number, weldTo: BasePart?): BasePart
	local white = Color3.new(1, 1, 1)
	local darkStick = Color3.fromRGB(22, 24, 30)
	local purpleBase = Color3.fromRGB(148, 20, 192)

	local function addPart(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = col
		p.Material = mat
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		if weldTo then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
			if p ~= weldTo then
				local w = Instance.new("WeldConstraint")
				w.Part0 = weldTo
				w.Part1 = p
				w.Parent = p
			end
		else
			p.Anchored = true
			p.CanCollide = false
		end
		p.Parent = container
		return p
	end

	local shaft = weldTo
	if not shaft then
		shaft = addPart("Handle", Vector3.new(0.42, 1.35, 0.42) * scale, rootCF * CFrame.new(0, -0.55 * scale, 0), darkStick, Enum.Material.SmoothPlastic)
	end
	addPart("GripBase", Vector3.new(0.43, 0.78, 0.43) * scale, rootCF * CFrame.new(0, -1.52 * scale, 0), purpleBase, Enum.Material.SmoothPlastic)

	local palm = addPart("Palm", Vector3.new(1.34, 1.16, 0.38) * scale, rootCF * CFrame.new(0, 1.00 * scale, 0), white, Enum.Material.Neon)
	addPart("Wrist", Vector3.new(0.58, 0.94, 0.38) * scale, rootCF * CFrame.new(0, 0.32 * scale, 0), white, Enum.Material.Neon)
	addPart("PalmCurveL", Vector3.new(0.64, 0.64, 0.38) * scale, rootCF * CFrame.new(-0.38 * scale, 0.52 * scale, 0), white, Enum.Material.Neon, Enum.PartType.Ball)
	addPart("PalmCurveR", Vector3.new(0.64, 0.64, 0.38) * scale, rootCF * CFrame.new(0.38 * scale, 0.52 * scale, 0), white, Enum.Material.Neon, Enum.PartType.Ball)

	local cylZ = CFrame.Angles(0, 0, math.rad(90))
	addPart("PalmSideL", Vector3.new(1.06, 0.38, 0.38) * scale, rootCF * CFrame.new(-0.54 * scale, 1.02 * scale, 0) * cylZ, white, Enum.Material.Neon, Enum.PartType.Cylinder)
	addPart("PalmSideR", Vector3.new(1.06, 0.38, 0.38) * scale, rootCF * CFrame.new(0.54 * scale, 1.02 * scale, 0) * cylZ, white, Enum.Material.Neon, Enum.PartType.Cylinder)
	local fingers = {
		{ name = "Pinky", x = -0.55, y = 1.48, len = 0.96, d = 0.30, tilt = 7 },
		{ name = "Ring", x = -0.20, y = 1.56, len = 1.30, d = 0.33, tilt = 2.5 },
		{ name = "Middle", x = 0.16, y = 1.58, len = 1.46, d = 0.34, tilt = -1.5 },
		{ name = "Index", x = 0.51, y = 1.54, len = 1.26, d = 0.33, tilt = -5.5 },
	}
	for _, fg in fingers do
		local baseCF = rootCF * CFrame.new(fg.x * scale, fg.y * scale, 0) * CFrame.Angles(0, 0, math.rad(fg.tilt))
		addPart(
			fg.name,
			Vector3.new(fg.len, fg.d, fg.d) * scale,
			baseCF * CFrame.new(0, fg.len * 0.5 * scale, 0) * cylZ,
			white,
			Enum.Material.Neon,
			Enum.PartType.Cylinder
		)
		addPart(
			`{fg.name}Tip`,
			Vector3.new(fg.d, fg.d, fg.d) * scale,
			baseCF * CFrame.new(0, fg.len * scale, 0),
			white,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
	end

	local thumbBase = rootCF * CFrame.new(0.62 * scale, 0.78 * scale, 0) * CFrame.Angles(0, 0, math.rad(-38))
	addPart("Thumb", Vector3.new(1.04, 0.36, 0.36) * scale, thumbBase * CFrame.new(0, 0.52 * scale, 0) * cylZ, white, Enum.Material.Neon, Enum.PartType.Cylinder)
	addPart("ThumbTip", Vector3.new(0.36, 0.36, 0.36) * scale, thumbBase * CFrame.new(0, 1.04 * scale, 0), white, Enum.Material.Neon, Enum.PartType.Ball)

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "SlapSparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(white)
	sparkles.LightEmission = 1
	sparkles.LightInfluence = 0
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.30 * scale),
		NumberSequenceKeypoint.new(0.45, 0.85 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkles.Lifetime = NumberRange.new(0.55, 1.0)
	sparkles.Rate = 18
	sparkles.RotSpeed = NumberRange.new(-90, 90)
	sparkles.Speed = NumberRange.new(0.6, 1.6)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = palm

	return palm
end

local function giveSlapTool(_player: Player)
	-- Slap tool disabled per user request
end

local function createSpinWheelStation(parent: Instance): Model
	local station = Instance.new("Model")
	station.Name = "SpinWheelStation"

	-- Placed along South touchline (replaces quarantined AdBoard_South_4 at X=28)
	local stationCF = CFrame.new(28, 0, 19.78)
	local wheelCF = stationCF * CFrame.new(0, 8.2, 0)
	local darkFrame = Color3.fromRGB(36, 41, 54)
	local goldBulb = Color3.fromRGB(255, 214, 58)
	local hubRed = Color3.fromHex("#C81E2B")

	-- Support base & rear A-frame legs
	makePart(station, "StandBase", Vector3.new(7.5, 0.5, 3.6), stationCF * CFrame.new(0, 0.25, 1.4), darkFrame, Enum.Material.SmoothPlastic)
	makePart(station, "StandPillarL", Vector3.new(0.85, 8.6, 0.85), stationCF * CFrame.new(-2.1, 4.3, 1.4) * CFrame.Angles(math.rad(-8), 0, math.rad(-12)), darkFrame, Enum.Material.SmoothPlastic)
	makePart(station, "StandPillarR", Vector3.new(0.85, 8.6, 0.85), stationCF * CFrame.new(2.1, 4.3, 1.4) * CFrame.Angles(math.rad(-8), 0, math.rad(12)), darkFrame, Enum.Material.SmoothPlastic)
	makePart(station, "WheelBacking", Vector3.new(0.28, 11.8, 11.8), wheelCF * CFrame.new(0, 0, 0.22) * CFrame.Angles(0, math.rad(90), 0), darkFrame, Enum.Material.SmoothPlastic).Shape = Enum.PartType.Cylinder

	-- 8-Slice 3D Wheel Wedges matching GameConfig.WHEEL_SEGMENTS
	local radius = 5.8
	local halfAng = math.rad(22.5)
	local wedgeH = radius * math.cos(halfAng)
	local wedgeW = radius * math.sin(halfAng)
	local wedgeT = 0.36

	for i, seg in GameConfig.WHEEL_SEGMENTS do
		local theta = math.rad((i - 1) * 45)
		local sliceCF = wheelCF * CFrame.Angles(0, 0, theta)
		local segCol = Color3.fromHex(seg.color)

		for _, side in { -1, 1 } do
			local w = Instance.new("WedgePart")
			w.Name = `Slice_{i}_{if side < 0 then "L" else "R"}`
			w.Size = Vector3.new(wedgeT, wedgeH, wedgeW)
			w.CFrame = sliceCF
				* CFrame.fromMatrix(
					Vector3.new(side * wedgeW * 0.5, wedgeH * 0.5, 0),
					Vector3.new(0, 0, -side),
					Vector3.new(0, -1, 0),
					Vector3.new(-side, 0, 0)
				)
			w.Anchored = true
			w.CanCollide = false
			w.Color = segCol
			w.Material = Enum.Material.SmoothPlastic
			w.Parent = station
		end

		local labelPlate = makePart(station, `SliceLabel_{i}`, Vector3.new(2.1, 2.3, 0.05), sliceCF * CFrame.new(0, 3.55, -0.20), segCol, Enum.Material.SmoothPlastic, false)
		labelPlate.Transparency = 1
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 48
		sg.Parent = labelPlate

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(1, 0, 0.46, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.FredokaOne
		iconLbl.TextColor3 = Color3.new(1, 1, 1)
		iconLbl.TextStrokeTransparency = 0
		iconLbl.TextScaled = true
		iconLbl.Text = seg.icon
		iconLbl.Parent = sg

		local txtLbl = Instance.new("TextLabel")
		txtLbl.Size = UDim2.new(1, 0, 0.52, 0)
		txtLbl.Position = UDim2.new(0, 0, 0.46, 0)
		txtLbl.BackgroundTransparency = 1
		txtLbl.Font = Enum.Font.FredokaOne
		txtLbl.TextColor3 = if seg.id == 4 then Color3.fromHex("#FFD21F") else Color3.fromHex("#3DDC3D")
		txtLbl.TextStrokeTransparency = 0
		txtLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		txtLbl.TextScaled = true
		txtLbl.Text = seg.label
		txtLbl.Parent = sg

		local boundAng = math.rad((i - 1) * 45 + 22.5)
		local boundCF = wheelCF * CFrame.Angles(0, 0, boundAng)
		makePart(station, `Spoke_{i}`, Vector3.new(0.14, radius, 0.40), boundCF * CFrame.new(0, radius * 0.5, -0.02), Color3.fromRGB(22, 25, 34), Enum.Material.SmoothPlastic, false)
		local bulb = makePart(station, `Bulb_{i}`, Vector3.new(0.46, 0.46, 0.46), boundCF * CFrame.new(0, 6.02, -0.34), goldBulb, Enum.Material.Neon, false)
		bulb.Shape = Enum.PartType.Ball
	end

	-- 16-segment dark slate circular bezel
	for k = 1, 16 do
		local ang = math.rad((k - 0.5) * 22.5)
		makePart(station, `Rim_{k}`, Vector3.new(2.52, 0.68, 0.72), wheelCF * CFrame.Angles(0, 0, ang) * CFrame.new(0, 6.02, 0), darkFrame, Enum.Material.SmoothPlastic)
	end

	-- Red center hub & red top pointer triangle
	local hubOuter = makePart(station, "HubBorder", Vector3.new(0.48, 2.05, 2.05), wheelCF * CFrame.new(0, 0, -0.04) * CFrame.Angles(0, math.rad(90), 0), darkFrame, Enum.Material.SmoothPlastic, false)
	hubOuter.Shape = Enum.PartType.Cylinder
	local hubInner = makePart(station, "HubCenter", Vector3.new(0.56, 1.62, 1.62), wheelCF * CFrame.new(0, 0, -0.06) * CFrame.Angles(0, math.rad(90), 0), hubRed, Enum.Material.SmoothPlastic, false)
	hubInner.Shape = Enum.PartType.Cylinder

	local pointerCF = wheelCF * CFrame.new(0, 4.86, -0.44)
	for _, side in { -1, 1 } do
		local pw = Instance.new("WedgePart")
		pw.Name = `TopPointer_{if side < 0 then "L" else "R"}`
		pw.Size = Vector3.new(0.26, 1.48, 0.90)
		pw.CFrame = pointerCF
			* CFrame.fromMatrix(
				Vector3.new(side * 0.45, 0.74, 0),
				Vector3.new(0, 0, -side),
				Vector3.new(0, -1, 0),
				Vector3.new(-side, 0, 0)
			)
		pw.Anchored = true
		pw.CanCollide = false
		pw.Color = Color3.fromHex("#DC2626")
		pw.Material = Enum.Material.SmoothPlastic
		pw.Parent = station
	end

	makeFloatingText(
		hubInner,
		"🎡 PRIZE WHEEL",
		Vector3.new(0, 7.6, 0),
		UDim2.fromOffset(210, 54),
		Color3.fromHex("#FFD21F")
	)

	-- Glowing circular trigger ring + upward-fading rainbow aura cylinder in front of wheel
	local ringRadius = 4.6
	local ringCF = stationCF * CFrame.new(0, 0, -5.58)
	local triggerCenter = makePart(station, "SpinTriggerCenter", Vector3.new(1, 0.2, 1), ringCF * CFrame.new(0, 0.1, 0), goldBulb, Enum.Material.SmoothPlastic, false)
	triggerCenter.Transparency = 1
	triggerCenter:SetAttribute("Radius", ringRadius)

	local spinPrompt = Instance.new("ProximityPrompt")
	spinPrompt.Name = "SpinPrompt"
	spinPrompt.ObjectText = "Prize Wheel"
	spinPrompt.ActionText = "Spin Wheel"
	spinPrompt.HoldDuration = 0
	spinPrompt.MaxActivationDistance = 9
	spinPrompt.RequiresLineOfSight = false
	spinPrompt.Parent = triggerCenter

	local ringSegCount = 24
	local segLen = 2 * ringRadius * math.tan(math.pi / ringSegCount) + 0.08
	for k = 1, ringSegCount do
		local ang = ((k - 1) / ringSegCount) * math.pi * 2
		local hue = ((k - 1) / ringSegCount)
		local ringCol = Color3.fromHSV((0.05 + hue * 0.85) % 1, 0.88, 1)
		local segCF = ringCF * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.09, -ringRadius)
		makePart(station, `TriggerRing_{k}`, Vector3.new(segLen, 0.14, 0.34), segCF, ringCol, Enum.Material.Neon, false)
	end

	local wallSegs = 24
	local wallWidth = 2 * (ringRadius - 0.04) * math.tan(math.pi / wallSegs) + 0.04
	for k = 1, wallSegs do
		local ang = ((k - 1) / wallSegs) * math.pi * 2
		local hueBot = ((0.05 + ((k - 1) / wallSegs) * 0.85) % 1)
		local hueTop = ((hueBot + 0.22) % 1)
		local post = makePart(station, `AuraPost_{k}`, Vector3.new(0.2, 0.2, 0.2), ringCF * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -(ringRadius - 0.04)), goldBulb, Enum.Material.SmoothPlastic, false)
		post.Transparency = 1

		local att0 = Instance.new("Attachment")
		att0.Position = Vector3.new(0, 0.08, 0)
		att0.Axis = Vector3.new(0, 1, 0)
		att0.SecondaryAxis = Vector3.new(1, 0, 0)
		att0.Parent = post

		local att1 = Instance.new("Attachment")
		att1.Position = Vector3.new(0, 3.25, 0)
		att1.Axis = Vector3.new(0, 1, 0)
		att1.SecondaryAxis = Vector3.new(1, 0, 0)
		att1.Parent = post

		local beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.FaceCamera = false
		beam.LightEmission = 0.85
		beam.LightInfluence = 0.15
		beam.Width0 = wallWidth
		beam.Width1 = wallWidth
		beam.Color = ColorSequence.new(Color3.fromHSV(hueBot, 0.85, 1), Color3.fromHSV(hueTop, 0.75, 1))
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.30),
			NumberSequenceKeypoint.new(0.55, 0.72),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Parent = post
	end

	station.PrimaryPart = triggerCenter
	station.Parent = parent
	return station
end

local function createSlapPadAndObby(parent: Instance)
	local targetParent = if parent:FindFirstChild("Zones") then parent.Zones else parent
	local oldSlap = targetParent:FindFirstChild("SlapToolStation") or parent:FindFirstChild("SlapToolStation")
	if oldSlap then
		oldSlap:Destroy()
	end
end

-- Stadium bowl: stepped tribunes on 4 sides + 4 angled corners with stair aisles, banners, seated NPC spectators, 8 floodlights, tree park
local SHIRT_COLORS = { "#1E6FFF", "#E5252A", "#FFFFFF", "#FFD21F", "#38BDF8", "#111827", "#F97316", "#22C55E" }
local SKIN_COLORS = { "#F5CBA7", "#E5B287", "#C98E63", "#7B4B2A", "#523018" }

local function createTribune(parent: Instance, a: Vector3, b: Vector3, outward: Vector3, rng: Random, isCorner: boolean?)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local mid = (a + b) / 2
	local concrete = Color3.fromRGB(148, 156, 170)
	local stairGray = Color3.fromRGB(176, 184, 196)
	local darkWall = Color3.fromRGB(108, 116, 132)
	local seatBlue = Color3.fromHex("#2563EB")

	-- Front inner wall + metal handrail + glass safety barrier + tall invisible border
	local frontC = mid + outward * 0.6 + Vector3.new(0, 1.4, 0)
	local frontRot = CFrame.lookAt(frontC, frontC + outward)
	makePart(parent, "FrontWall", Vector3.new(len + 1.5, 2.8, 1.2), frontRot, concrete, Enum.Material.Concrete)
	makePart(parent, "FrontRailing", Vector3.new(len + 1.5, 0.4, 0.5), frontRot * CFrame.new(0, 1.55, 0), Color3.fromRGB(48, 54, 66), Enum.Material.Metal)
	local glass = makePart(parent, "SafetyGlass", Vector3.new(len + 1.5, 2.8, 0.25), frontRot * CFrame.new(0, 3.1, 0), Color3.fromRGB(200, 230, 255), Enum.Material.Glass, true)
	glass.Transparency = 0.65
	glass.CastShadow = false

	-- Invisible barrier to prevent players from jumping/passing over the front of the tribunes
	local barrier = makePart(parent, "TribuneFrontBarrier", Vector3.new(len + 2.5, 26, 1.6), frontRot * CFrame.new(0, 14.5, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, true)
	barrier.Transparency = 1
	barrier.CanCollide = true
	barrier.CanTouch = false
	barrier.CastShadow = false
	if not isCorner then
		local bannerCount = math.max(2, math.floor(len / 28))
		for idx = 1, bannerCount do
			local bx = -len * 0.5 + (idx - 0.5) * (len / bannerCount)
			local bCol = if idx % 2 == 1 then Color3.fromHex("#E5252A") else Color3.fromHex("#1E6FFF")
			makePart(parent, "WallBanner", Vector3.new(2.6, 2.4, 0.25), frontRot * CFrame.new(bx, 0.1, 0.65), bCol, Enum.Material.SmoothPlastic, false)
		end
	end

	for tier = 1, 5 do
		local h = tier * 1.85
		local tierLen = len + tier * 2.7
		local c = mid + outward * ((tier - 0.5) * 3.2 + 1.0) + Vector3.new(0, h / 2, 0)
		local rot = CFrame.lookAt(c, c + outward)
		makePart(parent, `Tier_{tier}`, Vector3.new(tierLen, h, 3.2), rot, concrete, Enum.Material.Concrete)
		local seat = makePart(parent, `Seats_{tier}`, Vector3.new(tierLen - 1.2, 0.48, 1.25), rot * CFrame.new(0, h / 2 + 0.24, 0.55), seatBlue, Enum.Material.SmoothPlastic, false)
		seat.CastShadow = false

		if not isCorner then
			local stairStepCount = math.max(2, math.floor(len / 38))
			for s = 0, stairStepCount do
				local sx = -len * 0.46 + (s / stairStepCount) * (len * 0.92)
				local st = makePart(parent, "StairAisle", Vector3.new(3.2, 0.56, 3.1), rot * CFrame.new(sx, h / 2 + 0.28, 0), stairGray, Enum.Material.Concrete, false)
				st.CastShadow = false
			end
		end

		-- Crowd strip per tier (replaces 1,600+ 3D parts with 1 part + SurfaceGui per tier for silky mobile performance)
		local stripRot = rot * CFrame.Angles(0, math.pi, 0)
		local strip = makePart(parent, `CrowdStrip_{tier}`, Vector3.new(tierLen - 1.2, 2.6, 0.15), stripRot * CFrame.new(0, h / 2 + 1.3, -0.55), Color3.fromRGB(40, 44, 52), Enum.Material.SmoothPlastic, false)
		strip.CastShadow = false
		strip.Transparency = 1

		local sg = Instance.new("SurfaceGui")
		sg.Name = "CrowdGui"
		sg.Face = Enum.NormalId.Front
		sg.LightInfluence = 0
		sg.AlwaysOnTop = false
		sg.MaxDistance = 350
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 16
		sg.Parent = strip

		local root = Instance.new("Frame")
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundTransparency = 1
		root.Parent = sg

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.Padding = UDim.new(0, 4)
		layout.Parent = root

		local fanCount = math.clamp(math.floor((tierLen - 1.2) * 1.4), 10, 54)
		for f = 1, fanCount do
			local fanFrame = Instance.new("Frame")
			fanFrame.Size = UDim2.new(0, 20, 1, 0)
			fanFrame.BackgroundTransparency = 1
			fanFrame.Parent = root

			local head = Instance.new("Frame")
			head.Size = UDim2.new(0, 14, 0.42, 0)
			head.Position = UDim2.new(0, 3, 0, 0)
			head.BackgroundColor3 = Color3.fromHex(SKIN_COLORS[rng:NextInteger(1, #SKIN_COLORS)])
			head.BorderSizePixel = 0
			head.Parent = fanFrame
			local cr = Instance.new("UICorner")
			cr.CornerRadius = UDim.new(1, 0)
			cr.Parent = head

			local body = Instance.new("Frame")
			body.Size = UDim2.new(0, 20, 0.58, 0)
			body.Position = UDim2.new(0, 0, 0.42, 0)
			body.BackgroundColor3 = Color3.fromHex(SHIRT_COLORS[rng:NextInteger(1, #SHIRT_COLORS)])
			body.BorderSizePixel = 0
			body.Parent = fanFrame
			local cr2 = Instance.new("UICorner")
			cr2.CornerRadius = UDim.new(0, 3)
			cr2.Parent = body
		end
	end

	-- Upper rim walkway + outer stadium perimeter wall
	local rimLen = len + 17.5
	local rimC = mid + outward * 18.2 + Vector3.new(0, 10.2, 0)
	local rimRot = CFrame.lookAt(rimC, rimC + outward)
	makePart(parent, "UpperRim", Vector3.new(rimLen, 1.4, 3.6), rimRot, stairGray, Enum.Material.Concrete)
	local wallC = mid + outward * 19.6 + Vector3.new(0, 6.4, 0)
	makePart(parent, "BackWall", Vector3.new(rimLen + 1.5, 12.8, 1.4), CFrame.lookAt(wallC, wallC + outward), darkWall, Enum.Material.Concrete)
end

local function createStadiumBowl(parent: Instance)
	local bowl = Instance.new("Model")
	bowl.Name = "StadiumBowl"
	local rng = Random.new(7)

	-- Rounded-octagon stadium footprint hugging the pitch & NorthPlaza
	local nx0, nx1 = -76, 76
	local wx, ex = -96, 96
	local nz, sz = -112, 26
	local wz0, wz1 = -92, 6

	createTribune(bowl, Vector3.new(nx0, 0, nz), Vector3.new(nx1, 0, nz), Vector3.new(0, 0, -1), rng, false) -- North
	createTribune(bowl, Vector3.new(nx1, 0, sz), Vector3.new(nx0, 0, sz), Vector3.new(0, 0, 1), rng, false) -- South
	createTribune(bowl, Vector3.new(wx, 0, wz1), Vector3.new(wx, 0, wz0), Vector3.new(-1, 0, 0), rng, false) -- West
	createTribune(bowl, Vector3.new(ex, 0, wz0), Vector3.new(ex, 0, wz1), Vector3.new(1, 0, 0), rng, false) -- East

	-- 4 Beveled 45-degree corner tribunes closing the bowl
	createTribune(bowl, Vector3.new(wx, 0, wz0), Vector3.new(nx0, 0, nz), Vector3.new(-1, 0, -1).Unit, rng, true) -- NW
	createTribune(bowl, Vector3.new(nx1, 0, nz), Vector3.new(ex, 0, wz0), Vector3.new(1, 0, -1).Unit, rng, true) -- NE
	createTribune(bowl, Vector3.new(ex, 0, wz1), Vector3.new(nx1, 0, sz), Vector3.new(1, 0, 1).Unit, rng, true) -- SE
	createTribune(bowl, Vector3.new(nx0, 0, sz), Vector3.new(wx, 0, wz1), Vector3.new(-1, 0, 1).Unit, rng, true) -- SW

	-- 8 Stadium floodlight towers around upper rim (4 corners + 4 North/South rim)
	local floodPositions = {
		Vector3.new(-98, 0, -114),
		Vector3.new(98, 0, -114),
		Vector3.new(-98, 0, 28),
		Vector3.new(98, 0, 28),
		Vector3.new(-44, 0, -130),
		Vector3.new(44, 0, -130),
		Vector3.new(-44, 0, 44),
		Vector3.new(44, 0, 44),
	}
	for _, pos in floodPositions do
		makePart(bowl, "FloodPole", Vector3.new(1.8, 28, 1.8), CFrame.new(pos + Vector3.new(0, 14, 0)), Color3.fromRGB(76, 82, 96), Enum.Material.Metal)
		local headCF = CFrame.lookAt(pos + Vector3.new(0, 29, 0), Vector3.new(pos.X * 0.25, 0, -42))
		makePart(bowl, "FloodFrame", Vector3.new(9.2, 5.2, 0.9), headCF * CFrame.new(0, 0, 0.35), Color3.fromRGB(48, 54, 66), Enum.Material.Metal)
		local lamp = makePart(bowl, "FloodLamp", Vector3.new(8.4, 4.4, 0.6), headCF, Color3.fromRGB(248, 250, 255), Enum.Material.Neon)
		local light = Instance.new("SpotLight")
		light.Brightness = 0.9
		light.Range = 55
		light.Face = Enum.NormalId.Front
		light.Parent = lamp
	end

	-- Outer park trees around the stadium bowl (reduced to single sparse ring of 18 trees, no shadows/collisions for mobile performance)
	local treeCount = 18
	local rx, rz = 158, 125
	for i = 1, treeCount do
		local ang = (i / treeCount) * math.pi * 2
		local p = Vector3.new(math.cos(ang) * rx, 0, -43 + math.sin(ang) * rz)
		local crownSz = 10 + (i % 3) * 1.5
		makePart(bowl, "TreeTrunk", Vector3.new(1.8, 7.5, 1.8), CFrame.new(p + Vector3.new(0, 3.75, 0)), Color3.fromRGB(98, 62, 38), Enum.Material.Wood, false)
		local leaves = makePart(bowl, "TreeLeaves", Vector3.new(crownSz, crownSz, crownSz), CFrame.new(p + Vector3.new(0, 9.8, 0)), Color3.fromHex(if i % 2 == 0 then "#229A42" else "#1B8036"), Enum.Material.SmoothPlastic, false)
		leaves.Shape = Enum.PartType.Ball
		leaves.CastShadow = false
	end

	bowl.Parent = parent
end

local function createPitchMarkings(parent: Instance)
	local markings = Instance.new("Model")
	markings.Name = "PitchMarkings"
	local white = Color3.fromRGB(245, 245, 245)
	local chalkMat = Enum.Material.SmoothPlastic

	local function makeLine(name: string, size: Vector3, cf: CFrame)
		local p = makePart(markings, name, size, cf, white, chalkMat, false)
		p.CastShadow = false
		return p
	end

	-- 1. Outer Boundaries
	makeLine("TouchlineN", Vector3.new(156.5, 0.06, 0.5), CFrame.new(0, 0.08, -84))
	makeLine("TouchlineS", Vector3.new(156.5, 0.06, 0.5), CFrame.new(0, 0.08, 0))
	makeLine("GoalLineW", Vector3.new(0.5, 0.06, 84.5), CFrame.new(-78, 0.08, -42))
	makeLine("GoalLineE", Vector3.new(0.5, 0.06, 84.5), CFrame.new(78, 0.08, -42))

	-- 2. Halfway Line & Center Circle
	makeLine("HalfwayLine", Vector3.new(0.5, 0.06, 84), CFrame.new(0, 0.14, -42))
	local centerSpot = makePart(markings, "CenterSpot", Vector3.new(1.4, 0.07, 1.4), CFrame.new(0, 0.15, -42), white, chalkMat, false)
	centerSpot.CastShadow = false

	local circleRadius = 10
	local segCount = 24
	local segLen = 2 * circleRadius * math.tan(math.pi / segCount) + 0.06
	for k = 1, segCount do
		local ang = ((k - 1) / segCount) * math.pi * 2
		local segCF = CFrame.new(0, 0.14, -42) * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -circleRadius)
		makeLine(`CenterCircle_{k}`, Vector3.new(segLen, 0.06, 0.45), segCF)
	end

	-- 3. Penalty Boxes (West and East)
	for _, xSide in { -1, 1 } do
		local prefix = if xSide < 0 then "West" else "East"
		local goalX = xSide * 78
		local boxFrontX = xSide * 58
		local boxDepth = 20
		local boxWidth = 38

		makeLine(`{prefix}BoxFront`, Vector3.new(0.5, 0.06, boxWidth), CFrame.new(boxFrontX, 0.08, -42))
		makeLine(`{prefix}BoxN`, Vector3.new(boxDepth, 0.06, 0.5), CFrame.new(goalX - xSide * (boxDepth / 2), 0.08, -61))
		makeLine(`{prefix}BoxS`, Vector3.new(boxDepth, 0.06, 0.5), CFrame.new(goalX - xSide * (boxDepth / 2), 0.08, -23))

		local spot = makePart(markings, `{prefix}PenaltySpot`, Vector3.new(1.1, 0.07, 1.1), CFrame.new(goalX - xSide * 11, 0.08, -42), white, chalkMat, false)
		spot.CastShadow = false

		local smallFrontX = goalX - xSide * 7
		makeLine(`{prefix}SmallBoxFront`, Vector3.new(0.5, 0.06, 24), CFrame.new(smallFrontX, 0.08, -42))
		makeLine(`{prefix}SmallBoxN`, Vector3.new(7, 0.06, 0.5), CFrame.new(goalX - xSide * 3.5, 0.08, -54))
		makeLine(`{prefix}SmallBoxS`, Vector3.new(7, 0.06, 0.5), CFrame.new(goalX - xSide * 3.5, 0.08, -30))

		local arcRadius = 7.5
		local arcSegs = 7
		for a = 1, arcSegs do
			local frac = (a - 0.5) / arcSegs
			local angDeg = -45 + frac * 90
			local rad = math.rad(angDeg)
			local arcX = boxFrontX - xSide * (arcRadius * math.cos(rad) - 4.5)
			local arcZ = -42 + arcRadius * math.sin(rad)
			makeLine(`{prefix}Arc_{a}`, Vector3.new(0.45, 0.06, 1.8), CFrame.new(arcX, 0.08, arcZ) * CFrame.Angles(0, math.rad(-angDeg * xSide), 0))
		end
	end

	-- 4. Corner Flags & Corner Arcs (4 corners)
	local corners = {
		{ name = "NW", pos = Vector3.new(-78, 0, -84), xDir = 1, zDir = 1 },
		{ name = "SW", pos = Vector3.new(-78, 0, 0), xDir = 1, zDir = -1 },
		{ name = "NE", pos = Vector3.new(78, 0, -84), xDir = -1, zDir = 1 },
		{ name = "SE", pos = Vector3.new(78, 0, 0), xDir = -1, zDir = -1 },
	}
	for _, c in corners do
		for a = 1, 4 do
			local ang = ((a - 0.5) / 4) * (math.pi / 2)
			local ax = c.pos.X + c.xDir * (2.8 * math.cos(ang))
			local az = c.pos.Z + c.zDir * (2.8 * math.sin(ang))
			makeLine(`Arc_{c.name}_{a}`, Vector3.new(0.4, 0.06, 1.2), CFrame.new(ax, 0.08, az) * CFrame.Angles(0, math.atan2(c.xDir * math.cos(ang), c.zDir * math.sin(ang)), 0))
		end

		local flagBase = makePart(markings, `FlagBase_{c.name}`, Vector3.new(0.7, 0.2, 0.7), CFrame.new(c.pos + Vector3.new(0, 0.1, 0)), Color3.fromRGB(40, 44, 52), chalkMat, false)
		flagBase.CastShadow = false
		local pole = makePart(markings, `FlagPole_{c.name}`, Vector3.new(0.18, 5.2, 0.18), CFrame.new(c.pos + Vector3.new(0, 2.6, 0)), white, chalkMat, false)
		pole.CastShadow = false

		local flag = makePart(markings, `FlagCloth_{c.name}`, Vector3.new(0.06, 1.2, 1.6), CFrame.new(c.pos + Vector3.new(c.xDir * 0.75, 4.5, 0)), Color3.fromHex("#FFD21F"), Enum.Material.Neon, false)
		flag.CastShadow = false
		local flagStripe = makePart(markings, `FlagStripe_{c.name}`, Vector3.new(0.07, 1.2, 0.8), CFrame.new(c.pos + Vector3.new(c.xDir * 0.75, 4.5, 0.4 * c.zDir)), Color3.fromHex("#E5252A"), Enum.Material.SmoothPlastic, false)
		flagStripe.CastShadow = false
	end

	markings.Parent = parent
end

local function setupStadiumLighting()
	Lighting.ClockTime = 14.2
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 135, 155)

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	sky.SkyboxBk = "rbxassetid://271042310"
	sky.SkyboxDn = "rbxassetid://271077241"
	sky.SkyboxFt = "rbxassetid://271042516"
	sky.SkyboxLf = "rbxassetid://271042556"
	sky.SkyboxRt = "rbxassetid://271042467"
	sky.SkyboxUp = "rbxassetid://271077958"
	sky.CelestialBodiesShown = true
	sky.SunAngularSize = 14

	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Parent = Lighting
	end
	atmo.Density = 0.18
	atmo.Offset = 0.05
	atmo.Haze = 0.1
	atmo.Color = Color3.fromRGB(190, 220, 255)
	atmo.Decay = Color3.fromRGB(95, 155, 235)
	atmo.Glare = 0.15

	local cc = Lighting:FindFirstChild("StadiumColorPop") :: ColorCorrectionEffect?
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "StadiumColorPop"
		cc.Parent = Lighting
	end
	cc.Saturation = 0.22
	cc.Contrast = 0.12
	cc.Brightness = 0.02

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.4
	bloom.Size = 18
	bloom.Threshold = 1.8

	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
	if not clouds then
		clouds = Instance.new("Clouds")
		clouds.Parent = Workspace.Terrain
	end
	clouds.Cover = 0.6
	clouds.Density = 0.65
	clouds.Color = Color3.fromRGB(255, 255, 255)
end

local function buildStadiumLobby()
	pcall(function()
		Workspace.StreamingEnabled = true
	end)

	local existing = Workspace:FindFirstChild("Lobby")
	if existing and existing:FindFirstChild("_Layout") then
		-- Lobby structure preserved from phased repairs; do not recreate static geometry
		return
	end
	if existing then
		existing:Destroy()
	end
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"

	local baseplate = Workspace:FindFirstChild("Baseplate") :: BasePart?
	if baseplate then
		baseplate.Color = Color3.fromHex("#2FBF2F")
		baseplate.Material = Enum.Material.Grass
	end

	local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnLoc then
		spawnLoc.CFrame = CFrame.new(0, 0.5, 12)
		spawnLoc.Transparency = 1
		spawnLoc.CanCollide = false
		local decal = spawnLoc:FindFirstChildOfClass("Decal")
		if decal then
			decal.Transparency = 1
		end
	end


	makePart(lobby, "CentralWalkway", Vector3.new(16, 0.25, 126), CFrame.new(0, 0.12, -36), Color3.fromRGB(152, 158, 168), Enum.Material.Concrete)
	makePart(lobby, "WalkwayCurbL", Vector3.new(0.8, 0.4, 126), CFrame.new(-8.4, 0.2, -36), Color3.fromRGB(108, 114, 124), Enum.Material.Concrete)
	makePart(lobby, "WalkwayCurbR", Vector3.new(0.8, 0.4, 126), CFrame.new(8.4, 0.2, -36), Color3.fromRGB(108, 114, 124), Enum.Material.Concrete)
	makePart(lobby, "NorthPlaza", Vector3.new(146, 0.25, 22), CFrame.new(-10, 0.12, -96), Color3.fromRGB(152, 158, 168), Enum.Material.Concrete)

	for _, lpos in {
		Vector3.new(-10.5, 0, -14),
		Vector3.new(10.5, 0, -16),
		Vector3.new(-10.5, 0, -31),
		Vector3.new(10.5, 0, -34),
		Vector3.new(-10.5, 0, -49),
		Vector3.new(10.5, 0, -53),
		Vector3.new(-10.5, 0, -69),
		Vector3.new(10.5, 0, -70),
	} do
		createStoneLantern(lobby, lpos)
	end

	createGoalPost(lobby, -1)
	createGoalPost(lobby, 1)

	local lbFolder = lobby:FindFirstChild("Leaderboards")
	if not lbFolder then
		lbFolder = Instance.new("Folder")
		lbFolder.Name = "Leaderboards"
		lbFolder.Parent = lobby
	end

	createLeaderboardBoard(lbFolder, "Cash")
	createLeaderboardBoard(lbFolder, "Wins")
	createLeaderboardBoard(lbFolder, "Streak")
	createLeaderboardBoard(lbFolder, "Playtime")

	createMythicalVoteAndFeedback(lobby)
	createSlapPadAndObby(lobby)
	createSpinWheelStation(lobby)
	createPitchMarkings(lobby)
	createStadiumBowl(lobby)
	setupStadiumLighting()

	lobby.Parent = Workspace
end

function LobbyService.createCrownModel(head: BasePart): Model
	local crown = Instance.new("Model")
	crown.Name = "StreakKingCrown"

	local gold = Color3.fromRGB(245, 192, 36)
	local brightGold = Color3.fromRGB(255, 222, 82)
	local velvet = Color3.fromRGB(178, 24, 42)
	local gemColors = {
		Color3.fromHex("#EF233C"),
		Color3.fromHex("#2563EB"),
		Color3.fromHex("#10B981"),
		Color3.fromHex("#38BDF8"),
	}

	local rootCF = head.CFrame * CFrame.new(0, 1.38, 0)

	local function addCrownPart(
		className: string,
		name: string,
		size: Vector3,
		cf: CFrame,
		color: Color3,
		mat: Enum.Material,
		refl: number?
	): BasePart
		local p = Instance.new(className) :: BasePart
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		p.Reflectance = refl or 0
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		if p:IsA("Part") then
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
		end
		local w = Instance.new("WeldConstraint")
		w.Part0 = head
		w.Part1 = p
		w.Parent = p
		p.Parent = crown
		return p
	end

	local cylRot = CFrame.Angles(0, 0, math.rad(90))
	local band = addCrownPart("Part", "CrownBand", Vector3.new(0.32, 1.46, 1.46), rootCF * CFrame.new(0, -0.02, 0) * cylRot, gold, Enum.Material.Metal, 0.25) :: Part
	band.Shape = Enum.PartType.Cylinder

	local rimBot = addCrownPart("Part", "RimBottom", Vector3.new(0.10, 1.56, 1.56), rootCF * CFrame.new(0, -0.18, 0) * cylRot, brightGold, Enum.Material.Metal, 0.28) :: Part
	rimBot.Shape = Enum.PartType.Cylinder

	local rimTop = addCrownPart("Part", "RimTop", Vector3.new(0.08, 1.54, 1.54), rootCF * CFrame.new(0, 0.14, 0) * cylRot, brightGold, Enum.Material.Metal, 0.28) :: Part
	rimTop.Shape = Enum.PartType.Cylinder

	local cushion = addCrownPart("Part", "VelvetCushion", Vector3.new(1.34, 0.56, 1.34), rootCF * CFrame.new(0, 0.02, 0), velvet, Enum.Material.Fabric, 0) :: Part
	cushion.Shape = Enum.PartType.Ball

	for i = 1, 8 do
		local theta = math.rad((i - 1) * 45)
		local isCardinal = (i % 2 == 1)
		local spikeH = if isCardinal then 0.54 else 0.40
		local halfW = if isCardinal then 0.23 else 0.19
		local ringCF = rootCF * CFrame.Angles(0, theta, 0) * CFrame.new(0.68, 0.14, 0) * CFrame.Angles(0, 0, math.rad(-14))
		local spikeCenter = ringCF * CFrame.new(0, spikeH * 0.5, 0)

		addCrownPart("WedgePart", `ProngL_{i}`, Vector3.new(0.13, spikeH, halfW), spikeCenter * CFrame.new(0, 0, -halfW * 0.5), gold, Enum.Material.Metal, 0.25)
		addCrownPart("WedgePart", `ProngR_{i}`, Vector3.new(0.13, spikeH, halfW), spikeCenter * CFrame.new(0, 0, halfW * 0.5) * CFrame.Angles(0, math.pi, 0), gold, Enum.Material.Metal, 0.25)

		local pearl = addCrownPart("Part", `TipOrb_{i}`, Vector3.new(0.14, 0.14, 0.14), ringCF * CFrame.new(0, spikeH + 0.04, 0), brightGold, Enum.Material.Metal, 0.30) :: Part
		pearl.Shape = Enum.PartType.Ball

		local gemCol = gemColors[((i - 1) % #gemColors) + 1]
		addCrownPart(
			"Part",
			`Gem_{i}`,
			Vector3.new(0.08, 0.16, 0.16),
			rootCF * CFrame.Angles(0, theta, 0) * CFrame.new(0.73, -0.02, 0) * CFrame.Angles(math.rad(45), 0, 0),
			gemCol,
			Enum.Material.Glass,
			0.25
		)
	end

	crown.PrimaryPart = band
	return crown
end

local function attachOverheadTag(player: Player, character: Model)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	if not head then
		return
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "BAF_Overhead"
	bb.Size = UDim2.fromOffset(260, 104)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.SizeOffset = Vector2.new(0, 0.5) -- pixel-sized gui: anchor its bottom above the head so zoom-out can't sink text into the avatar
	bb.MaxDistance = 85
	bb.Adornee = head
	bb.Parent = head

	local function makeRow(name: string, posY: number, heightPx: number, maxTextSize: number, color: Color3): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.Size = UDim2.new(1, 0, 0, heightPx)
		lbl.Position = UDim2.fromOffset(0, posY)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextColor3 = color
		lbl.TextStrokeTransparency = 0
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.TextScaled = true
		lbl.Parent = bb
		local tc = Instance.new("UITextSizeConstraint")
		tc.MaxTextSize = maxTextSize
		tc.MinTextSize = 8
		tc.Parent = lbl
		return lbl
	end

	local streakLabel = makeRow("StreakLabel", 0, 20, 16, Color3.fromHex("#FFD21F"))
	local nameLabel = makeRow("NameLabel", 20, 38, 32, Color3.new(1, 1, 1))
	local titleLabel = makeRow("TitleLabel", 59, 21, 18, Color3.fromHex("#C0C0C0"))
	local buxLabel = makeRow("BuxLabel", 82, 20, 17, Color3.fromHex("#3DDC3D"))

	local function refreshOverhead()
		local ls = player:FindFirstChild("leaderstats")
		local bux = if ls and ls:FindFirstChild("Bux") then (ls.Bux :: IntValue).Value else 0
		local streak = if ls and ls:FindFirstChild("Streak") then (ls.Streak :: IntValue).Value else 0
		local title = (player:GetAttribute("Title") :: string?) or "Benchwarmer"
		local isKing = player:GetAttribute("IsStreakKing") == true

		if isKing and streak > 0 then
			streakLabel.Text = `👑 STREAK KING  🔥 {streak}`
			streakLabel.Visible = true
		elseif isKing then
			streakLabel.Text = "👑 STREAK KING"
			streakLabel.Visible = true
		elseif streak > 0 then
			streakLabel.Text = `🔥 {streak}`
			streakLabel.Visible = true
		else
			streakLabel.Text = ""
			streakLabel.Visible = false
		end

		nameLabel.Text = player.DisplayName
		titleLabel.Text = string.upper(title)
		titleLabel.TextColor3 = GameConfig.getTitleColor(title)
		buxLabel.Text = `${bux}`

		local existingCrown = character:FindFirstChild("StreakKingCrown")
		if isKing and not existingCrown then
			local crown = LobbyService.createCrownModel(head)
			crown.Parent = character
		elseif not isKing and existingCrown then
			existingCrown:Destroy()
		end
	end

	refreshOverhead()
	player.AttributeChanged:Connect(refreshOverhead)
	local ls = player:WaitForChild("leaderstats", 5)
	if ls then
		for _, child in ls:GetChildren() do
			if child:IsA("IntValue") then
				child.Changed:Connect(refreshOverhead)
			end
		end
	end
end

local function resolveUserName(userId: number): string
	if userNameCache[userId] then
		return userNameCache[userId]
	end
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		userNameCache[userId] = plr.DisplayName
		return plr.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = if ok and typeof(name) == "string" and #name > 0 then name else `Player_{userId}`
	userNameCache[userId] = resolved
	return resolved
end

-- Toggle for 3D champion avatar statue beside leaderboard
local ENABLE_CHAMPION_STATUE = false

local function updatePodiumStatue(refs: BoardRefs, topUserId: number?)
	-- Always clean up any existing legacy or orphaned statues
	for _, c in refs.model:GetChildren() do
		if c.Name == "Rank1Statue" or c.Name == "CrownStatue" or c.Name == "ChampionStatue" then
			c:Destroy()
		end
	end

	if not ENABLE_CHAMPION_STATUE then
		if refs.statueModel then
			refs.statueModel:Destroy()
			refs.statueModel = nil
		end
		return
	end

	local uid = if typeof(topUserId) == "number" and topUserId > 0 then topUserId else nil
	if not uid then
		if refs.statueModel then
			refs.statueModel:Destroy()
			refs.statueModel = nil
		end
		return
	end

	if refs.currentStatueUserId == uid and refs.statueModel and refs.statueModel.Parent then
		return
	end
	refs.currentStatueUserId = uid

	task.spawn(function()
		local ok, rig = pcall(function()
			return Players:CreateHumanoidModelFromUserId(uid)
		end)
		if not ok or not rig or refs.currentStatueUserId ~= uid then
			if rig then
				rig:Destroy()
			end
			return
		end

		rig.Name = "ChampionStatue"
		local hrp = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = rig:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			hum.NameDisplayDistance = 0
			hum.EvaluateStateMachine = false
		end

		-- Resolve stand position beside leaderboard (podium or podiumCF)
		local podiumsFolder = refs.model:FindFirstChild("Podiums")
		local pod = (podiumsFolder and podiumsFolder:FindFirstChild("Podium_L"))
			or refs.model:FindFirstChild("Podium") :: BasePart?
		local podCF = if pod then pod.CFrame else refs.podiumCF
		local standCF = CFrame.new(podCF.Position.X, podCF.Position.Y + 2.85, podCF.Position.Z) * (podCF - podCF.Position)

		-- Use rig:PivotTo BEFORE anchoring so all limbs and accessories move intact together
		rig.PrimaryPart = hrp or rig:FindFirstChild("UpperTorso") or rig:FindFirstChild("Torso")
		rig:PivotTo(standCF)

		-- Anchor parts at destination and strip unnecessary scripts/animators
		for _, desc in rig:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanQuery = false
				desc.CanTouch = false
				desc.CastShadow = true
			elseif desc:IsA("BaseScript") or desc:IsA("Animator") or desc:IsA("Sound") then
				desc:Destroy()
			end
		end

		rig.Parent = refs.model
		refs.statueModel = rig
	end)
end

local function getPlayerStatValue(player: Player, statKey: string): number
	if statKey == "Playtime" then
		return ProfileService.getPlaytimeSeconds(player)
	end
	local ls = player:FindFirstChild("leaderstats")
	local iv = if ls then ls:FindFirstChild(statKey) :: IntValue? else nil
	return if iv then iv.Value else 0
end

local function formatBoardStat(statKey: string, val: number): string
	if statKey == "Playtime" then
		return GameConfig.formatPlaytime(val)
	end
	return LeaderboardBuilder.formatCompact(val)
end

local function syncGlobalOrderedStores()
	for _, statKey in { "Playtime", "Bux", "Wins", "Streak" } do
		local oStore = orderedStores[statKey]
		if not oStore then
			continue
		end
		for _, player in Players:GetPlayers() do
			if player.UserId > 0 then
				local val = getPlayerStatValue(player, statKey)
				if val > 0 then
					pcall(function()
						oStore:SetAsync(tostring(player.UserId), val)
					end)
				end
			end
		end
		local ok, pages = pcall(function()
			return oStore:GetSortedAsync(false, LeaderboardConfig.ROW_COUNT)
		end)
		if ok and pages then
			local pageOk, page = pcall(function()
				return pages:GetCurrentPage()
			end)
			if pageOk and typeof(page) == "table" then
				local list: { { userId: number, name: string, val: number } } = {}
				for _, row in page do
					local uid = tonumber(row.key)
					local v = tonumber(row.value) or 0
					if uid and uid > 0 and v > 0 then
						table.insert(list, {
							userId = uid,
							name = resolveUserName(uid),
							val = v,
						})
					end
				end
				globalTopCache[statKey] = list
			end
		end
	end
end

local function refreshLeaderboards()
	local now = os.clock()
	if now - lastGlobalSync >= LeaderboardConfig.REFRESH_INTERVAL_SEC or lastGlobalSync == 0 then
		lastGlobalSync = now
		task.spawn(syncGlobalOrderedStores)
	end

	local elapsed = math.floor(os.clock() - lastGlobalSync)
	local updatedText = if elapsed < 5 then "UPDATED JUST NOW" else string.format("UPDATED %d:%02d AGO", math.floor(elapsed / 60), elapsed % 60)

	for _, statKey in { "Playtime", "Bux", "Wins", "Streak" } do
		local refs = boardRefs[statKey]
		if not refs then
			continue
		end

		if refs.footerLabel then
			refs.footerLabel.Text = updatedText
		end

		local byUserId: { [number]: { userId: number, name: string, val: number } } = {}
		for _, gEntry in globalTopCache[statKey] or {} do
			byUserId[gEntry.userId] = { userId = gEntry.userId, name = gEntry.name, val = gEntry.val }
		end
		for _, player in Players:GetPlayers() do
			local v = getPlayerStatValue(player, statKey)
			local uid = if player.UserId > 0 then player.UserId else -player:GetDebugId():byte(1, 1)
			local prev = byUserId[uid]
			if not prev or v >= prev.val then
				byUserId[uid] = { userId = player.UserId, name = player.DisplayName, val = v }
			end
		end

		local entries: { { userId: number, name: string, val: number } } = {}
		for _, entry in byUserId do
			table.insert(entries, entry)
		end

		table.sort(entries, function(a, b)
			return a.val > b.val
		end)

		for i = 1, LeaderboardConfig.ROW_COUNT do
			local entry = entries[i]
			local r = refs.rows[i]
			if not r then
				continue
			end
			if entry then
				local thumbUid = if entry.userId > 0 then entry.userId else 1
				r.avatar.Image = `rbxthumb://type=AvatarHeadShot&id={thumbUid}&w=150&h=150`
				r.nameLbl.Text = entry.name
				r.valLbl.Text = formatBoardStat(statKey, entry.val)
			else
				r.avatar.Image = ""
				r.nameLbl.Text = "---"
				r.valLbl.Text = if statKey == "Playtime" then "0s" else "0"
			end
		end

		local top1 = entries[1]
		refs.podiumLabel.Text = if top1 then `👑 {top1.name}` else "👑 Waiting..."
		updatePodiumStatue(refs, if top1 then top1.userId else nil)

		-- Sync top stats to Jumbotron config (only when stat > 0; keeps previous player until replaced)
		local conf = ReplicatedStorage:FindFirstChild("Config")
		if conf then
			local topWins = if statKey == "Wins" then entries[1] else (globalTopCache.Wins and globalTopCache.Wins[1])
			local topCash = if statKey == "Bux" then entries[1] else (globalTopCache.Bux and globalTopCache.Bux[1])
			if topWins and topWins.val > 0 then
				local prevWins = tonumber(conf:GetAttribute("TopPlayerWins")) or 0
				if topWins.val >= prevWins or topWins.userId == conf:GetAttribute("TopPlayerUserId") then
					conf:SetAttribute("TopPlayerName", topWins.name)
					conf:SetAttribute("TopPlayerUserId", topWins.userId)
					conf:SetAttribute("TopPlayerWins", topWins.val)
				end
			end
			if topCash and topCash.val > 0 then
				local prevCash = tonumber(conf:GetAttribute("TopCashAmount")) or 0
				if topCash.val >= prevCash or topCash.userId == conf:GetAttribute("TopCashUserId") then
					conf:SetAttribute("TopCashName", topCash.name)
					conf:SetAttribute("TopCashUserId", topCash.userId)
					conf:SetAttribute("TopCashAmount", topCash.val)
				end
			end
		end
	end
end

local function bindExistingLeaderboards(parent: Instance)
	for _, statKey in { "Playtime", "Bux", "Wins", "Streak" } do
		local model = parent:FindFirstChild(`Leaderboard_{statKey}`)
		if not model then continue end
		local def = LeaderboardConfig.BOARDS[statKey]
		local board = model:FindFirstChild("Board") :: Part?
		local podium = model:FindFirstChild("Podium") :: Part?
		local plaque = model:FindFirstChild("NamePlaque") :: Part?
		local plaqueSg = plaque and plaque:FindFirstChildOfClass("SurfaceGui")
		local podSign = plaqueSg and plaqueSg:FindFirstChildOfClass("TextLabel")
		local sg = board and board:FindFirstChild("LeaderboardGui") :: SurfaceGui?
		local screen = sg and (sg:FindFirstChild("Screen") or sg:FindFirstChildOfClass("Frame"))
		local footer = screen and screen:FindFirstChild("Footer")
		local footerLbl = footer and footer:FindFirstChild("UpdatedLabel") :: TextLabel?

		local rows: { LeaderboardRowRef } = {}
		if screen then
			for i = 1, LeaderboardConfig.ROW_COUNT do
				local row = screen:FindFirstChild(`Row_{i}`)
				if row then
					local avatar = row:FindFirstChild("Avatar") :: ImageLabel?
					local nameLbl = row:FindFirstChild("PlayerName") :: TextLabel?
					local valLbl = row:FindFirstChild("StatValue") :: TextLabel?
					if avatar and nameLbl and valLbl then
						table.insert(rows, {
							avatar = avatar,
							nameLbl = nameLbl,
							valLbl = valLbl,
						})
					end
				end
			end
		end

		local podiumCF = podium and podium.CFrame or model:GetPivot()
		boardRefs[statKey] = {
			model = model,
			podiumCF = podiumCF,
			accentColor = def and def.headerColor or Color3.new(1, 1, 1),
			rows = rows,
			podiumLabel = podSign or Instance.new("TextLabel"),
			currentStatueUserId = nil,
			statueModel = nil,
			footerLabel = footerLbl,
		}
	end
end

function LobbyService.buildStadiumLobby()
	buildStadiumLobby()
end

function LobbyService.init()
	buildStadiumLobby()
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		createMythicalVoteAndFeedback(lobby)
		createSlapPadAndObby(lobby)
	end
	if not game:GetService("RunService"):IsServer() then
		return
	end

	local function bindPlayer(player: Player)
		if player.Character then
			task.spawn(attachOverheadTag, player, player.Character)
		end
		player.CharacterAdded:Connect(function(char)
			task.spawn(attachOverheadTag, player, char)
		end)
		player.Chatted:Connect(function(msg)
			local cmd = string.lower(string.split(string.gsub(msg, "^%s+", ""), " ")[1] or "")
			if cmd == "/skipvotetimer" then
				if VoteConfig.ENABLE_TEST_COMMAND or RunService:IsStudio() or player.UserId == game.CreatorId then
					local newStart = Workspace:GetServerTimeNow() - VoteConfig.MIN_SESSION_SECONDS - 5
					ProfileService.setSessionJoinTime(player, newStart)
					Remotes.MetaAction:FireClient(player, "Toast", "[Admin] Vote timer skipped! (Session playtime > 5m)")
				end
			end
		end)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		votedPlayers[player] = nil
		voteTouchDebounce[player] = nil
		playerVoted[player.UserId] = nil
		lastVoteRequestTime[player.UserId] = nil
		playerLastActive[player.UserId] = nil
		playerActiveSeconds[player.UserId] = nil
	end)
	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end
end

return table.freeze(LobbyService)

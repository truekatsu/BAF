--!strict
--[[
	LeaderboardBuilder
	Responsibility: Procedural 3D builder for the 4 stylized cartoon football leaderboards
	(TOP WINS, TOP STREAKS, TOP CASH, TOP PLAYTIME) and Center Stadium Jumbotron.
	Visual Reference: Concept sheet (~85%+ match) featuring royal blue frame, white pillars with glowing
	cyan neon strips, dark navy header + screen, gold trophy crown with 2 stars + 2 top balls, hanging
	pointed banners, corner podiums with glowing yellow light panels and soccer balls, two-tier stone base,
	grass pitch strip, debossed crown back panel, and SurfaceGui.
	Location: ReplicatedStorage/Shared/LeaderboardBuilder (ModuleScript)
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LeaderboardConfig = require(Shared:WaitForChild("LeaderboardConfig"))

local LeaderboardBuilder = {
	PALETTE = LeaderboardConfig.PALETTE,
	MEDAL_COLORS = LeaderboardConfig.MEDAL_COLORS,
	ASSETS = LeaderboardConfig.ASSETS,
	BOARDS = LeaderboardConfig.BOARDS,
}

-- Compact Number Formatter (1,250 / 12.5K / 1.2M / 4.1B)
function LeaderboardBuilder.formatCompact(n: number): string
	local num = math.max(0, math.floor(n))
	if num >= 1_000_000_000 then
		local v = num / 1_000_000_000
		local s = if v >= 10 then string.format("%dB", math.floor(v)) else string.format("%.1fB", v)
		return (string.gsub(s, "%.0B", "B"))
	elseif num >= 1_000_000 then
		local v = num / 1_000_000
		local s = if v >= 10 then string.format("%dM", math.floor(v)) else string.format("%.1fM", v)
		return (string.gsub(s, "%.0M", "M"))
	elseif num >= 10_000 then
		local v = num / 1_000
		local s = if v >= 100 then string.format("%dK", math.floor(v)) else string.format("%.1fK", v)
		return (string.gsub(s, "%.0K", "K"))
	elseif num >= 1_000 then
		local s = tostring(num)
		return string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
	else
		return tostring(num)
	end
end

-- Currency Formatter ($1.5K / $2.3M / $4.1B)
function LeaderboardBuilder.formatCurrency(n: number): string
	return "$" .. LeaderboardBuilder.formatCompact(n)
end

-- Time Formatter (12h 30m / 45m / 30s)
function LeaderboardBuilder.formatTime(seconds: number): string
	local sec = math.max(0, math.floor(seconds))
	local hours = math.floor(sec / 3600)
	local mins = math.floor((sec % 3600) / 60)
	if hours > 0 then
		return string.format("%dh %02dm", hours, mins)
	elseif mins > 0 then
		return string.format("%dm", mins)
	else
		return string.format("%ds", sec)
	end
end

-- General Stat Formatter by Board Type
function LeaderboardBuilder.formatValue(val: number, formatKind: string?): string
	if formatKind == "Currency" then
		return LeaderboardBuilder.formatCurrency(val)
	elseif formatKind == "Time" then
		return LeaderboardBuilder.formatTime(val)
	elseif formatKind == "Raw" then
		return tostring(math.max(0, math.floor(val)))
	else
		return LeaderboardBuilder.formatCompact(val)
	end
end

-- Helper: Create Anchored Part
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
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = if canCollide == nil then false else canCollide
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- Helper: Create Wedge Part
local function makeWedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material?
): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = mat or Enum.Material.SmoothPlastic
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.CastShadow = false
	w.Parent = parent
	return w
end

-- Helper: Create Stylized Football (Ball part with mesh placeholder)
local function makeFootball(parent: Instance, name: string, diameter: number, cf: CFrame): Part
	local ball = makePart(parent, name, Vector3.new(diameter, diameter, diameter), cf, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, false)
	ball.Shape = Enum.PartType.Ball

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "BallMesh"
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = LeaderboardBuilder.ASSETS.SoccerBallMesh
	mesh.TextureId = LeaderboardBuilder.ASSETS.SoccerBallTexture
	local s = (diameter / 2.0) * 0.035
	mesh.Scale = Vector3.new(s, s, s)
	mesh.Parent = ball
	return ball
end

-- Helper: Create Golden Trophy with Laurel Wreath & Stars
local function makeTrophy(parent: Instance, cf: CFrame): Model
	local trophyModel = Instance.new("Model")
	trophyModel.Name = "TrophyWithWreath"

	local goldCol = LeaderboardBuilder.PALETTE.Gold
	local starCol = LeaderboardBuilder.MEDAL_COLORS.Gold

	-- Stepped Pedestal
	makePart(trophyModel, "TrophyPedestal", Vector3.new(2.8, 0.5, 1.8), cf * CFrame.new(0, 0.25, 0), goldCol, Enum.Material.Metal, false)
	makePart(trophyModel, "TrophyCollar", Vector3.new(2.2, 0.35, 1.4), cf * CFrame.new(0, 0.65, 0), goldCol, Enum.Material.Metal, false)

	-- Center Cup Part
	local cupPart = makePart(trophyModel, "Cup", Vector3.new(3.6, 3.2, 1.8), cf * CFrame.new(0, 2.3, 0) * CFrame.Angles(0, math.rad(90), 0), goldCol, Enum.Material.Metal, false)
	local sm = Instance.new("SpecialMesh")
	sm.Name = "TrophyMesh"
	sm.MeshType = Enum.MeshType.FileMesh
	sm.MeshId = LeaderboardBuilder.ASSETS.TrophyMesh
	sm.Scale = Vector3.new(0.009, 0.009, 0.009)
	sm.Parent = cupPart

	-- Trophy Handles (Left and Right)
	for _, sx in { -1, 1 } do
		local handle = makePart(trophyModel, `TrophyHandle_{if sx < 0 then "L" else "R"}`, Vector3.new(0.35, 1.8, 0.35), cf * CFrame.new(sx * 1.7, 2.4, 0), goldCol, Enum.Material.Metal, false)
		local hm = Instance.new("SpecialMesh")
		hm.MeshType = Enum.MeshType.Cylinder
		hm.Parent = handle
	end

	-- Center Laurel Star Plaque
	local starPlaque = makePart(trophyModel, "StarEmblem", Vector3.new(0.9, 0.9, 0.1), cf * CFrame.new(0, 2.6, 0.95), starCol, Enum.Material.Neon, false)
	local starSg = Instance.new("SurfaceGui")
	starSg.Face = Enum.NormalId.Front
	starSg.LightInfluence = 0
	starSg.CanvasSize = Vector2.new(128, 128)
	starSg.Parent = starPlaque
	local starLbl = Instance.new("TextLabel")
	starLbl.Size = UDim2.fromScale(1, 1)
	starLbl.BackgroundTransparency = 1
	starLbl.Font = Enum.Font.FredokaOne
	starLbl.Text = "★"
	starLbl.TextColor3 = Color3.fromHex("#FFF4A3")
	starLbl.TextScaled = true
	starLbl.Parent = starSg

	-- Laurel Leaves
	local angles = { 20, 42, 64 }
	for _, side in { -1, 1 } do
		for idx, ang in ipairs(angles) do
			local rad = math.rad(ang * side)
			local r = 1.9 + (idx * 0.3)
			local lx = math.sin(rad) * r
			local ly = 0.7 + (idx * 0.9)
			local leaf = makePart(
				trophyModel,
				`LaurelLeaf_{if side < 0 then "L" else "R"}_{idx}`,
				Vector3.new(0.35, 1.0, 0.25),
				cf * CFrame.new(lx, ly, 0.2) * CFrame.Angles(0, 0, math.rad(-ang * side * 0.8)),
				starCol,
				Enum.Material.Metal,
				false
			)
			local lm = Instance.new("SpecialMesh")
			lm.MeshType = Enum.MeshType.Wedge
			lm.Parent = leaf
		end
	end

	trophyModel.Parent = parent
	return trophyModel
end

-- Helper: Create Stylized Bush
local function makeBush(parent: Instance, name: string, cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = name
	local green = LeaderboardBuilder.PALETTE.GrassGreen
	makePart(m, "Main", Vector3.new(1.6, 1.4, 1.6), cf * CFrame.new(0, 0.7, 0), green, Enum.Material.SmoothPlastic, false)
	makePart(m, "Tuft1", Vector3.new(1.2, 1.1, 1.2), cf * CFrame.new(-0.4, 0.8, 0.3), green, Enum.Material.SmoothPlastic, false)
	makePart(m, "Tuft2", Vector3.new(1.1, 1.0, 1.1), cf * CFrame.new(0.4, 0.6, -0.3), green, Enum.Material.SmoothPlastic, false)
	m.Parent = parent
	return m
end

-- 3D Procedural Builder matching Concept Sheet
function LeaderboardBuilder.buildLeaderboard(
	boardTypeOrConfig: any,
	boardCF: CFrame?,
	parent: Instance?
): Model
	local statKey: LeaderboardConfig.BoardStatKey = "Wins"
	if typeof(boardTypeOrConfig) == "string" then
		statKey = boardTypeOrConfig :: any
	elseif typeof(boardTypeOrConfig) == "table" and boardTypeOrConfig.statKey then
		statKey = boardTypeOrConfig.statKey
	end

	local def = LeaderboardConfig.BOARDS[statKey] or LeaderboardConfig.BOARDS.Wins
	local p = LeaderboardBuilder.PALETTE
	local targetParent = parent or Workspace

	-- Compute Base CFrame so pivot rests on ground (Y = 0) with 0.05 stud anti-float overlap
	local originCF = boardCF or (CFrame.new(def.position) * CFrame.Angles(0, math.atan2(def.lookTarget.X - def.position.X, def.lookTarget.Z - def.position.Z) + math.pi, 0))

	local model = Instance.new("Model")
	model.Name = `Leaderboard_{statKey}`

	-- Folder Hierarchy per Prompt Spec: Base, Frame, Screen, Crown, Banners, Podiums, Decor
	local fBase = Instance.new("Folder")
	fBase.Name = "Base"
	fBase.Parent = model

	local fFrame = Instance.new("Folder")
	fFrame.Name = "Frame"
	fFrame.Parent = model

	local fScreen = Instance.new("Folder")
	fScreen.Name = "Screen"
	fScreen.Parent = model

	local fCrown = Instance.new("Folder")
	fCrown.Name = "Crown"
	fCrown.Parent = model

	local fBanners = Instance.new("Folder")
	fBanners.Name = "Banners"
	fBanners.Parent = model

	local fPodiums = Instance.new("Folder")
	fPodiums.Name = "Podiums"
	fPodiums.Parent = model

	local fDecor = Instance.new("Folder")
	fDecor.Name = "Decor"
	fDecor.Parent = model

	-- 1. BASE: PrimaryPart & Stepped Stone Slab
	-- Ground elevation relative to model origin: 0.0. Bottom slab touches -0.05 for zero float.
	local basePlate = makePart(fBase, "BasePlate", Vector3.new(24.0, 0.4, 6.0), originCF * CFrame.new(0, 0.15, 0), p.StoneBase, Enum.Material.Concrete, true)
	model.PrimaryPart = basePlate

	-- Stepped Tier 1 (Lower Wide Tier: Light Gray Stone #9AA3B5)
	makePart(fBase, "BaseStepBottom", Vector3.new(24.0, 0.8, 6.2), originCF * CFrame.new(0, 0.35, 0), p.StoneBase, Enum.Material.Concrete, true)

	-- Stepped Tier 2 (Upper Inset Tier: Medium Gray Stone #7B828E)
	makePart(fBase, "BaseStepTop", Vector3.new(20.4, 0.6, 5.0), originCF * CFrame.new(0, 0.95, 0), p.StoneBaseTop, Enum.Material.Concrete, true)

	-- Vibrant Grass Strip in front of the screen (Pitch turf #3DB83A)
	makePart(fBase, "GrassPitchStrip", Vector3.new(14.6, 0.15, 2.2), originCF * CFrame.new(0, 1.28, 1.35), p.GrassGreen, Enum.Material.SmoothPlastic, false)

	-- 2. PODIUMS: Bottom Corners (Royal Blue with Gold Trim & Glowing Yellow Neon Light Panels)
	for _, sx in { -1, 1 } do
		local sideStr = if sx < 0 then "L" else "R"
		local podCF = originCF * CFrame.new(sx * 9.2, 1.25, 0.8)

		-- Main Podium Box
		makePart(fPodiums, `Podium_{sideStr}`, Vector3.new(3.4, 2.6, 3.4), podCF * CFrame.new(0, 1.3, 0), p.RoyalBlue, Enum.Material.SmoothPlastic, true)

		-- Gold Trim Collars (Bottom & Top)
		makePart(fPodiums, `PodiumTrimBot_{sideStr}`, Vector3.new(3.6, 0.35, 3.6), podCF * CFrame.new(0, 0.18, 0), p.Gold, Enum.Material.Metal, false)
		makePart(fPodiums, `PodiumTrimTop_{sideStr}`, Vector3.new(3.6, 0.35, 3.6), podCF * CFrame.new(0, 2.6, 0), p.Gold, Enum.Material.Metal, false)

		-- Glowing Yellow Light Panel on Front Face (Neon #FFE600)
		local lightPanel = makePart(fPodiums, `PodiumLightPanel_{sideStr}`, Vector3.new(2.4, 1.2, 0.2), podCF * CFrame.new(0, 1.3, 1.7), Color3.fromHex("#FFE600"), Enum.Material.Neon, false)
		local podPointLight = Instance.new("PointLight")
		podPointLight.Name = "Glow"
		podPointLight.Color = Color3.fromHex("#FFE600")
		podPointLight.Brightness = 0.8
		podPointLight.Range = 8
		podPointLight.Parent = lightPanel

		-- Soccer Ball resting securely on top of podium
		makeFootball(fPodiums, `Football_Podium{sideStr}`, 2.8, podCF * CFrame.new(0, 4.2, 0))

		-- Stylized Green Bush beside each podium on outer tier
		makeBush(fDecor, `Bush_{sideStr}`, originCF * CFrame.new(sx * 11.3, 0.75, 1.0))
	end

	-- 3. PILLARS & NEON STRIPS: Two White Pillars with Glowing Cyan Neon Strips
	local pillarHeight = 19.5
	local pillarCenterY = 1.25 + (pillarHeight * 0.5)

	for _, sx in { -1, 1 } do
		local sideStr = if sx < 0 then "L" else "R"
		local pilCF = originCF * CFrame.new(sx * 7.8, pillarCenterY, 0)

		-- White Vertical Pillar (#F2F5FA) overlapping base by 0.3 studs
		makePart(fFrame, `Pillar_{sideStr}`, Vector3.new(1.8, pillarHeight, 1.8), pilCF, p.White, Enum.Material.SmoothPlastic, true)

		-- Outer Royal Blue Brace
		makePart(fFrame, `PillarBrace_{sideStr}`, Vector3.new(0.6, pillarHeight - 2.0, 2.0), pilCF * CFrame.new(sx * 0.9, 0, 0), p.RoyalBlue, Enum.Material.SmoothPlastic, false)

		-- Gold Base Collar & Gold Top Cap
		makePart(fFrame, `PillarBase_{sideStr}`, Vector3.new(2.3, 0.8, 2.3), pilCF * CFrame.new(0, -pillarHeight * 0.5 + 0.4, 0), p.Gold, Enum.Material.Metal, false)
		makePart(fFrame, `PillarCap_{sideStr}`, Vector3.new(2.3, 0.8, 2.3), pilCF * CFrame.new(0, pillarHeight * 0.5 - 0.4, 0), p.Gold, Enum.Material.Metal, false)

		-- Glowing Cyan Neon Strip on Inside Edge (facing screen)
		local neonStrip = makePart(fFrame, `NeonStrip_{sideStr}`, Vector3.new(0.35, pillarHeight - 1.2, 0.35), pilCF * CFrame.new(-sx * 0.95, 0, 0.4), p.NeonCyan, Enum.Material.Neon, false)
		neonStrip:SetAttribute("IsNeonStrip", true)

		local stripGlow = Instance.new("PointLight")
		stripGlow.Name = "CyanGlow"
		stripGlow.Color = p.NeonCyan
		stripGlow.Brightness = 0.6
		stripGlow.Range = 10
		stripGlow.Parent = neonStrip
	end

	-- 4. HANGING BANNERS: Mounted on Gold-Capped Posts with Pointed Bottom Chevron
	for _, sx in { -1, 1 } do
		local sideStr = if sx < 0 then "L" else "R"
		local postCF = originCF * CFrame.new(sx * 9.4, pillarCenterY + 4.5, 0)

		-- Cantilever Mount Bar with Gold Cap
		makePart(fBanners, `BannerPost_{sideStr}`, Vector3.new(2.2, 0.4, 0.4), postCF, p.DeepBlue, Enum.Material.Metal, false)
		makePart(fBanners, `BannerPostCap_{sideStr}`, Vector3.new(0.5, 0.7, 0.7), postCF * CFrame.new(sx * 1.1, 0, 0), p.Gold, Enum.Material.Metal, false)

		-- Banner Cloth (Royal Blue #1E4FD8)
		local bannerCF = postCF * CFrame.new(0, -2.6, 0.2)
		makePart(fBanners, `BannerCloth_{sideStr}`, Vector3.new(1.8, 4.4, 0.15), bannerCF, p.RoyalBlue, Enum.Material.SmoothPlastic, false)

		-- Chevron / Pointed Bottom Trim
		makeWedge(fBanners, `BannerPointL_{sideStr}`, Vector3.new(0.15, 0.9, 0.9), bannerCF * CFrame.new(-0.45, -2.65, 0) * CFrame.Angles(0, math.rad(90), 0), p.Gold, Enum.Material.Metal)
		makeWedge(fBanners, `BannerPointR_{sideStr}`, Vector3.new(0.15, 0.9, 0.9), bannerCF * CFrame.new(0.45, -2.65, 0) * CFrame.Angles(0, math.rad(-90), 0), p.Gold, Enum.Material.Metal)

		-- Soccer Ball Emblem Badge on Banner Face
		local emblemCircle = makePart(fBanners, `BannerBadge_{sideStr}`, Vector3.new(1.2, 1.2, 0.05), bannerCF * CFrame.new(0, 0.4, 0.12), p.White, Enum.Material.SmoothPlastic, false)
		emblemCircle.Shape = Enum.PartType.Cylinder
		emblemCircle.CFrame = bannerCF * CFrame.new(0, 0.4, 0.12) * CFrame.Angles(0, math.rad(90), 0)

		local emblemSg = Instance.new("SurfaceGui")
		emblemSg.Face = Enum.NormalId.Right
		emblemSg.CanvasSize = Vector2.new(128, 128)
		emblemSg.LightInfluence = 0
		emblemSg.Parent = emblemCircle
		local emblemLbl = Instance.new("TextLabel")
		emblemLbl.Size = UDim2.fromScale(1, 1)
		emblemLbl.BackgroundTransparency = 1
		emblemLbl.Font = Enum.Font.FredokaOne
		emblemLbl.Text = "⚽"
		emblemLbl.TextScaled = true
		emblemLbl.Parent = emblemSg
	end

	-- 5. MAIN FRAME & SCREEN: ScreenPart, Royal Blue Frame, Back Panel
	local screenWidth = 14.2
	local screenHeight = 17.6
	local screenCenterY = 1.25 + (screenHeight * 0.5)

	-- Back Panel with Soft White Edge Trim & Debossed Crown Relief
	local backCF = originCF * CFrame.new(0, screenCenterY, -0.6)
	makePart(fFrame, "BackPanel", Vector3.new(screenWidth + 1.2, screenHeight + 2.0, 0.6), backCF, p.DeepBlue, Enum.Material.SmoothPlastic, true)
	makePart(fFrame, "BackTrimTop", Vector3.new(screenWidth + 1.4, 0.4, 0.8), backCF * CFrame.new(0, (screenHeight * 0.5) + 1.0, 0), p.White, Enum.Material.SmoothPlastic, false)
	makePart(fFrame, "BackTrimBot", Vector3.new(screenWidth + 1.4, 0.4, 0.8), backCF * CFrame.new(0, -(screenHeight * 0.5) - 1.0, 0), p.White, Enum.Material.SmoothPlastic, false)

	-- Debossed Crown Emblem on Back
	local crownEmblem = makePart(fFrame, "BackCrownEmblem", Vector3.new(4.2, 2.6, 0.15), backCF * CFrame.new(0, 0.5, -0.32), p.RoyalBlue, Enum.Material.SmoothPlastic, false)
	local crownSg = Instance.new("SurfaceGui")
	crownSg.Face = Enum.NormalId.Back
	crownSg.CanvasSize = Vector2.new(256, 160)
	crownSg.LightInfluence = 0
	crownSg.Parent = crownEmblem
	local crownLbl = Instance.new("TextLabel")
	crownLbl.Size = UDim2.fromScale(1, 1)
	crownLbl.BackgroundTransparency = 1
	crownLbl.Font = Enum.Font.FredokaOne
	crownLbl.Text = "👑"
	crownLbl.TextColor3 = p.RoyalBlue
	crownLbl.TextStrokeTransparency = 0.4
	crownLbl.TextStrokeColor3 = p.White
	crownLbl.TextScaled = true
	crownLbl.Parent = crownSg

	-- Frame Beams (Bottom & Sides)
	makePart(fFrame, "FrameBottom", Vector3.new(screenWidth + 0.6, 0.6, 1.4), originCF * CFrame.new(0, 1.55, 0), p.RoyalBlue, Enum.Material.SmoothPlastic, true)

	-- Main Screen Part (Carrying SurfaceGui)
	local screenPart = makePart(fScreen, "ScreenPart", Vector3.new(screenWidth, screenHeight, 0.6), originCF * CFrame.new(0, screenCenterY, 0), p.NavyScreen, Enum.Material.SmoothPlastic, true)

	-- Dedicated Solid Invisible Collider Barrier (prevents any player phasing or clipping)
	local boardCollider = Instance.new("Part")
	boardCollider.Name = "BoardCollider"
	boardCollider.Size = Vector3.new(23.5, 23.0, 3.8)
	boardCollider.CFrame = originCF * CFrame.new(0, screenCenterY + 1.5, 0)
	boardCollider.Transparency = 1
	boardCollider.Anchored = true
	boardCollider.CanCollide = true
	boardCollider.CanTouch = false
	boardCollider.CanQuery = true
	boardCollider.CastShadow = false
	boardCollider.Parent = fFrame

	-- Header Plaque (Dark Navy with Gold Trim Top/Bottom, spanning screen)
	local headerHeight = 2.8
	local headerCF = originCF * CFrame.new(0, 1.25 + screenHeight + (headerHeight * 0.5), 0.2)
	local headerPlaque = makePart(fFrame, "HeaderPlaque", Vector3.new(screenWidth + 0.8, headerHeight, 1.4), headerCF, p.NavyScreenAlt, Enum.Material.SmoothPlastic, false)
	makePart(fFrame, "HeaderGoldTrimTop", Vector3.new(screenWidth + 1.2, 0.4, 1.6), headerCF * CFrame.new(0, headerHeight * 0.5, 0), p.Gold, Enum.Material.Metal, false)
	makePart(fFrame, "HeaderGoldTrimBot", Vector3.new(screenWidth + 1.2, 0.35, 1.6), headerCF * CFrame.new(0, -headerHeight * 0.5, 0), p.Gold, Enum.Material.Metal, false)

	-- Header Plaque Title SurfaceGui
	local headerSg = Instance.new("SurfaceGui")
	headerSg.Name = "HeaderGui"
	headerSg.Face = Enum.NormalId.Front
	headerSg.LightInfluence = 0
	headerSg.CanvasSize = Vector2.new(800, 160)
	headerSg.Parent = headerPlaque

	local headerContainer = Instance.new("Frame")
	headerContainer.Size = UDim2.fromScale(1, 1)
	headerContainer.BackgroundTransparency = 1
	headerContainer.Parent = headerSg

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Name = "TitleLabel"
	headerTitle.Size = UDim2.new(0.96, 0, 0.68, 0)
	headerTitle.Position = UDim2.new(0.02, 0, 0.05, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Font = Enum.Font.FredokaOne
	headerTitle.Text = `👑  {def.title}`
	headerTitle.TextColor3 = p.White
	headerTitle.TextScaled = true
	headerTitle.Parent = headerContainer
	local htStroke = Instance.new("UIStroke")
	htStroke.Thickness = 2.5
	htStroke.Color = Color3.new(0, 0, 0)
	htStroke.Parent = headerTitle

	local headerSubtitle = Instance.new("TextLabel")
	headerSubtitle.Name = "SubtitleLabel"
	headerSubtitle.Size = UDim2.new(0.96, 0, 0.22, 0)
	headerSubtitle.Position = UDim2.new(0.02, 0, 0.72, 0)
	headerSubtitle.BackgroundTransparency = 1
	headerSubtitle.Font = Enum.Font.FredokaOne
	headerSubtitle.Text = "UPDATES EVERY 60s"
	headerSubtitle.TextColor3 = p.MutedGrey
	headerSubtitle.TextScaled = true
	headerSubtitle.Parent = headerContainer

	-- 6. TOP CROWN: Golden Trophy Flanked by 2 Stars & 2 Soccer Balls on Top Beam
	local crownCF = headerCF * CFrame.new(0, headerHeight * 0.5 + 0.2, 0)
	makeTrophy(fCrown, crownCF)

	-- Flanking Stars at Trophy Base (Neon Gold #FFD54A)
	for _, sx in { -1, 1 } do
		local starPart = makePart(fCrown, `TrophyBaseStar_{if sx < 0 then "L" else "R"}`, Vector3.new(0.65, 0.65, 0.15), crownCF * CFrame.new(sx * 1.9, 0.5, 0.6), LeaderboardBuilder.MEDAL_COLORS.Gold, Enum.Material.Neon, false)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.CanvasSize = Vector2.new(64, 64)
		sg.LightInfluence = 0
		sg.Parent = starPart
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = "★"
		lbl.TextColor3 = Color3.fromRGB(255, 245, 160)
		lbl.TextScaled = true
		lbl.Parent = sg
	end

	-- Flanking Soccer Balls on Top Beam
	makeFootball(fCrown, "Football_TopL", 2.5, crownCF * CFrame.new(-3.6, 1.25, 0))
	makeFootball(fCrown, "Football_TopR", 2.5, crownCF * CFrame.new(3.6, 1.25, 0))

	-- 7. SCREEN UI: SurfaceGui on ScreenPart (10 Rows + Highlighted Local Player Row + Live Indicator)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "LeaderboardGui"
	sg.Face = Enum.NormalId.Front
	sg.LightInfluence = 0
	sg.AlwaysOnTop = false
	sg.MaxDistance = LeaderboardConfig.MAX_DISTANCE
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = LeaderboardConfig.PIXELS_PER_STUD
	sg.Parent = screenPart

	local screen = Instance.new("Frame")
	screen.Name = "Screen"
	screen.Size = UDim2.new(1, 0, 1, 0)
	screen.BackgroundColor3 = p.NavyScreen
	screen.BorderSizePixel = 0
	screen.ClipsDescendants = true
	screen.Parent = sg

	local screenPad = Instance.new("UIPadding")
	screenPad.PaddingTop = UDim.new(0, 10)
	screenPad.PaddingBottom = UDim.new(0, 10)
	screenPad.PaddingLeft = UDim.new(0, 14)
	screenPad.PaddingRight = UDim.new(0, 14)
	screenPad.Parent = screen

	-- Blue Column Header Bar
	local colBar = Instance.new("Frame")
	colBar.Name = "ColumnHeader"
	colBar.Size = UDim2.new(1, 0, 0.055, 0)
	colBar.BackgroundColor3 = p.RoyalBlue
	colBar.BorderSizePixel = 0
	colBar.Parent = screen
	local cbc = Instance.new("UICorner")
	cbc.CornerRadius = UDim.new(0, 8)
	cbc.Parent = colBar

	local colRank = Instance.new("TextLabel")
	colRank.Size = UDim2.new(0.12, 0, 0.84, 0)
	colRank.Position = UDim2.new(0.02, 0, 0.08, 0)
	colRank.BackgroundTransparency = 1
	colRank.Font = Enum.Font.FredokaOne
	colRank.Text = "#"
	colRank.TextColor3 = p.White
	colRank.TextScaled = true
	colRank.Parent = colBar

	local colPlayer = Instance.new("TextLabel")
	colPlayer.Size = UDim2.new(0.52, 0, 0.84, 0)
	colPlayer.Position = UDim2.new(0.16, 0, 0.08, 0)
	colPlayer.BackgroundTransparency = 1
	colPlayer.Font = Enum.Font.FredokaOne
	colPlayer.Text = "Player"
	colPlayer.TextColor3 = p.White
	colPlayer.TextXAlignment = Enum.TextXAlignment.Left
	colPlayer.TextScaled = true
	colPlayer.Parent = colBar

	local colValue = Instance.new("TextLabel")
	colValue.Name = "ValueHeader"
	colValue.Size = UDim2.new(0.28, 0, 0.84, 0)
	colValue.Position = UDim2.new(0.70, 0, 0.08, 0)
	colValue.BackgroundTransparency = 1
	colValue.Font = Enum.Font.FredokaOne
	colValue.Text = def.valueHeader
	colValue.TextColor3 = p.White
	colValue.TextXAlignment = Enum.TextXAlignment.Right
	colValue.TextScaled = true
	colValue.Parent = colBar

	-- 10 Navy Alternating Rows (#0A1030 / #0E1640)
	local rankColors = { LeaderboardBuilder.MEDAL_COLORS.Gold, LeaderboardBuilder.MEDAL_COLORS.Silver, LeaderboardBuilder.MEDAL_COLORS.Bronze }
	local crownIcons = { "👑", "🥈", "🥉" }
	local rowHeight = 0.076
	local startY = 0.068
	local spacing = 0.078

	for i = 1, LeaderboardConfig.ROW_COUNT do
		local row = Instance.new("Frame")
		row.Name = `Row_{i}`
		row.Size = UDim2.new(1, 0, rowHeight, 0)
		row.Position = UDim2.new(0, 0, startY + (i - 1) * spacing, 0)
		row.BackgroundColor3 = if i % 2 == 1 then p.NavyScreen else p.NavyScreenAlt
		row.BorderSizePixel = 0
		row.Parent = screen

		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 8)
		rc.Parent = row

		local rs = Instance.new("UIStroke")
		rs.Name = "Stroke"
		rs.Color = if i <= 3 then rankColors[i] else p.RowDivider
		rs.Thickness = if i <= 3 then 1.5 else 1
		rs.Transparency = if i <= 3 then 0.2 else 0.6
		rs.Parent = row

		-- Rank Number & Crown/Medal Icon
		local rankNum = Instance.new("TextLabel")
		rankNum.Name = "RankNum"
		rankNum.Size = UDim2.new(0.07, 0, 0.78, 0)
		rankNum.Position = UDim2.new(0.02, 0, 0.11, 0)
		rankNum.BackgroundTransparency = 1
		rankNum.Font = Enum.Font.FredokaOne
		rankNum.Text = tostring(i)
		rankNum.TextColor3 = if i <= 3 then rankColors[i] else p.White
		rankNum.TextScaled = true
		rankNum.Parent = row

		local crownLbl = Instance.new("TextLabel")
		crownLbl.Name = "CrownIcon"
		crownLbl.Size = UDim2.new(0.06, 0, 0.65, 0)
		crownLbl.Position = UDim2.new(0.09, 0, 0.18, 0)
		crownLbl.BackgroundTransparency = 1
		crownLbl.Font = Enum.Font.FredokaOne
		crownLbl.Text = crownIcons[i] or ""
		crownLbl.TextColor3 = if i <= 3 then rankColors[i] else p.White
		crownLbl.TextScaled = true
		crownLbl.Parent = row

		-- Avatar Headshot with UICorner
		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.Size = UDim2.new(0.085, 0, 0.82, 0)
		avatar.Position = UDim2.new(0.16, 0, 0.09, 0)
		avatar.BackgroundColor3 = p.DeepBlue
		avatar.BorderSizePixel = 0
		avatar.Image = ""
		avatar.Parent = row
		local ac = Instance.new("UICorner")
		ac.CornerRadius = UDim.new(1, 0)
		ac.Parent = avatar

		-- Online Dot Indicator
		local onlineDot = Instance.new("Frame")
		onlineDot.Name = "OnlineDot"
		onlineDot.Size = UDim2.new(0.016, 0, 0.25, 0)
		onlineDot.Position = UDim2.new(0.24, 0, 0.38, 0)
		onlineDot.BackgroundColor3 = p.LiveGreen
		onlineDot.BorderSizePixel = 0
		onlineDot.Visible = false
		onlineDot.Parent = row
		local odc = Instance.new("UICorner")
		odc.CornerRadius = UDim.new(1, 0)
		odc.Parent = onlineDot

		-- Player Name: Display Name + Small @username
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "PlayerName"
		nameLbl.Size = UDim2.new(0.40, 0, 0.52, 0)
		nameLbl.Position = UDim2.new(0.265, 0, 0.10, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextColor3 = p.White
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.TextScaled = true
		nameLbl.Text = "---"
		nameLbl.Parent = row

		local userLbl = Instance.new("TextLabel")
		userLbl.Name = "Username"
		userLbl.Size = UDim2.new(0.40, 0, 0.32, 0)
		userLbl.Position = UDim2.new(0.265, 0, 0.60, 0)
		userLbl.BackgroundTransparency = 1
		userLbl.Font = Enum.Font.FredokaOne
		userLbl.TextColor3 = p.MutedGrey
		userLbl.TextXAlignment = Enum.TextXAlignment.Left
		userLbl.TextTruncate = Enum.TextTruncate.AtEnd
		userLbl.TextScaled = true
		userLbl.Text = ""
		userLbl.Parent = row

		-- Rank Change Indicator (Green ▲ / Red ▼)
		local deltaLbl = Instance.new("TextLabel")
		deltaLbl.Name = "RankDelta"
		deltaLbl.Size = UDim2.new(0.05, 0, 0.55, 0)
		deltaLbl.Position = UDim2.new(0.66, 0, 0.22, 0)
		deltaLbl.BackgroundTransparency = 1
		deltaLbl.Font = Enum.Font.FredokaOne
		deltaLbl.Text = ""
		deltaLbl.TextScaled = true
		deltaLbl.Parent = row

		-- Value (Right-Aligned, Rank 1-3 highlighted)
		local valLbl = Instance.new("TextLabel")
		valLbl.Name = "StatValue"
		valLbl.Size = UDim2.new(0.26, 0, 0.80, 0)
		valLbl.Position = UDim2.new(0.72, 0, 0.10, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Font = Enum.Font.FredokaOne
		valLbl.TextColor3 = if i <= 3 then def.accentColor else p.White
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.TextScaled = true
		valLbl.Text = if statKey == "Playtime" then "0s" else "0"
		valLbl.Parent = row
	end

	-- Sticky Local Player Footer Row ("YOU: #37 - 120")
	local footerRow = Instance.new("Frame")
	footerRow.Name = "LocalPlayerRow"
	footerRow.Size = UDim2.new(1, 0, 0.075, 0)
	footerRow.Position = UDim2.new(0, 0, 0.865, 0)
	footerRow.BackgroundColor3 = Color3.fromHex("#14204A")
	footerRow.BorderSizePixel = 0
	footerRow.Parent = screen
	local lrc = Instance.new("UICorner")
	lrc.CornerRadius = UDim.new(0, 8)
	lrc.Parent = footerRow
	local lrs = Instance.new("UIStroke")
	lrs.Name = "Stroke"
	lrs.Color = p.Gold
	lrs.Thickness = 1.8
	lrs.Parent = footerRow

	local localRankLbl = Instance.new("TextLabel")
	localRankLbl.Name = "LocalRankText"
	localRankLbl.Size = UDim2.new(0.96, 0, 0.84, 0)
	localRankLbl.Position = UDim2.new(0.02, 0, 0.08, 0)
	localRankLbl.BackgroundTransparency = 1
	localRankLbl.Font = Enum.Font.FredokaOne
	localRankLbl.TextColor3 = p.White
	localRankLbl.TextXAlignment = Enum.TextXAlignment.Left
	localRankLbl.TextScaled = true
	localRankLbl.Text = "YOU: #--  ---"
	localRankLbl.Parent = footerRow

	-- Footer Status Bar: "LIVE" dot + "Next update in 0:42"
	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, 0, 0.045, 0)
	statusBar.Position = UDim2.new(0, 0, 0.950, 0)
	statusBar.BackgroundTransparency = 1
	statusBar.Parent = screen

	local liveDot = Instance.new("Frame")
	liveDot.Name = "LiveDot"
	liveDot.Size = UDim2.new(0.016, 0, 0.50, 0)
	liveDot.Position = UDim2.new(0.02, 0, 0.25, 0)
	liveDot.BackgroundColor3 = p.LiveGreen
	liveDot.BorderSizePixel = 0
	liveDot.Parent = statusBar
	local ldc = Instance.new("UICorner")
	ldc.CornerRadius = UDim.new(1, 0)
	ldc.Parent = liveDot

	local liveLbl = Instance.new("TextLabel")
	liveLbl.Name = "LiveLabel"
	liveLbl.Size = UDim2.new(0.12, 0, 0.90, 0)
	liveLbl.Position = UDim2.new(0.045, 0, 0.05, 0)
	liveLbl.BackgroundTransparency = 1
	liveLbl.Font = Enum.Font.FredokaOne
	liveLbl.TextColor3 = p.LiveGreen
	liveLbl.TextXAlignment = Enum.TextXAlignment.Left
	liveLbl.TextScaled = true
	liveLbl.Text = "LIVE"
	liveLbl.Parent = statusBar

	local countdownLbl = Instance.new("TextLabel")
	countdownLbl.Name = "CountdownLabel"
	countdownLbl.Size = UDim2.new(0.70, 0, 0.90, 0)
	countdownLbl.Position = UDim2.new(0.28, 0, 0.05, 0)
	countdownLbl.BackgroundTransparency = 1
	countdownLbl.Font = Enum.Font.FredokaOne
	countdownLbl.TextColor3 = p.MutedGrey
	countdownLbl.TextXAlignment = Enum.TextXAlignment.Right
	countdownLbl.TextScaled = true
	countdownLbl.Text = "Next update in 0:60"
	countdownLbl.Parent = statusBar

	-- CollectionService & Attributes Tagging
	CollectionService:AddTag(model, "LeaderboardBoard")
	model:SetAttribute("BoardType", statKey)
	model:PivotTo(originCF)
	model.Parent = targetParent

	return model
end

-- Grounding Verification Function: Raycasts downwards from base and pillars
function LeaderboardBuilder.verifyGrounding(model: Model): { valid: boolean, gap: number, warnings: { string } }
	local warnings: { string } = {}
	local maxGap = 0
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }

	local checkParts = {
		model:FindFirstChild("BasePlate", true) :: BasePart?,
		model:FindFirstChild("BaseStepBottom", true) :: BasePart?,
		model:FindFirstChild("Pillar_L", true) :: BasePart?,
		model:FindFirstChild("Pillar_R", true) :: BasePart?,
	}

	for _, part in checkParts do
		if part and part:IsA("BasePart") then
			local rayOrigin = part.Position
			local rayDir = Vector3.new(0, -6, 0)
			local result = Workspace:Raycast(rayOrigin, rayDir, params)
			if result then
				local expectedY = part.Position.Y - (part.Size.Y * 0.5)
				local gap = expectedY - result.Position.Y
				if gap > 0.05 then
					table.insert(warnings, `[GroundCheck] {part.Name} has gap {string.format("%.3f", gap)} studs > 0.05!`)
					maxGap = math.max(maxGap, gap)
				end
			end
		end
	end

	local valid = (#warnings == 0)
	if not valid then
		for _, w in warnings do
			warn(w)
		end
	end
	return { valid = valid, gap = maxGap, warnings = warnings }
end

-- Existing Stadium Jumbotron Builder (Preserved for compatibility)
function LeaderboardBuilder.buildJumbotron(screenCF: CFrame, parent: Instance): Model
	local p = LeaderboardBuilder.PALETTE
	local jModel = Instance.new("Model")
	jModel.Name = "Jumbotron"

	local screen = makePart(jModel, "Screen", Vector3.new(46.0, 18.0, 0.8), screenCF, p.NavyScreen, Enum.Material.SmoothPlastic, true)
	makePart(jModel, "FrameTop", Vector3.new(48.8, 1.4, 2.0), screenCF * CFrame.new(0, 9.61, 0), p.RoyalBlue, Enum.Material.SmoothPlastic, false)
	makePart(jModel, "FrameBottom", Vector3.new(48.8, 1.4, 2.0), screenCF * CFrame.new(0, -9.61, 0), p.RoyalBlue, Enum.Material.SmoothPlastic, false)
	makePart(jModel, "FrameLeft", Vector3.new(1.4, 18.0, 2.0), screenCF * CFrame.new(-23.7, 0, 0), p.RoyalBlue, Enum.Material.SmoothPlastic, false)
	makePart(jModel, "FrameRight", Vector3.new(1.4, 18.0, 2.0), screenCF * CFrame.new(23.7, 0, 0), p.RoyalBlue, Enum.Material.SmoothPlastic, false)

	makePart(jModel, "GoldTrimTop", Vector3.new(49.2, 0.35, 2.2), screenCF * CFrame.new(0, 10.3, 0), p.Gold, Enum.Material.Metal, false)
	makePart(jModel, "GoldTrimBot", Vector3.new(49.2, 0.35, 2.2), screenCF * CFrame.new(0, -10.3, 0), p.Gold, Enum.Material.Metal, false)

	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			makePart(jModel, `GoldCorner_{if sx < 0 then "L" else "R"}_{if sy < 0 then "B" else "T"}`, Vector3.new(2.4, 2.4, 2.4), screenCF * CFrame.new(sx * 23.7, sy * 9.61, 0), p.Gold, Enum.Material.Metal, false)
		end
	end

	makeFootball(jModel, "Football_JumbotronL", 3.2, screenCF * CFrame.new(-18.0, 11.85, 0.0))
	makeFootball(jModel, "Football_JumbotronR", 3.2, screenCF * CFrame.new(18.0, 11.85, 0.0))

	jModel.PrimaryPart = screen
	jModel.Parent = parent
	return jModel
end

-- Existing Main Banner Styler (Preserved for compatibility)
function LeaderboardBuilder.styleMainBanner(bannerPart: BasePart)
	local p = LeaderboardBuilder.PALETTE
	bannerPart.Color = p.NavyScreen
	bannerPart.Material = Enum.Material.SmoothPlastic

	local sg = bannerPart:FindFirstChildWhichIsA("SurfaceGui")
	if not sg then
		sg = Instance.new("SurfaceGui")
		sg.Name = "BannerGui"
		sg.Face = Enum.NormalId.Front
		sg.LightInfluence = 0
		sg.CanvasSize = Vector2.new(1200, 180)
		sg.Parent = bannerPart
	end

	local frame = sg:FindFirstChildOfClass("Frame")
	if not frame then
		frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.Parent = sg
	end
	frame.BackgroundColor3 = p.NavyScreenAlt
	frame.BorderSizePixel = 0

	local fc = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 16)
	fc.Parent = frame

	local fs = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	fs.Color = p.Gold
	fs.Thickness = 3
	fs.Parent = frame

	local lbl = frame:FindFirstChildOfClass("TextLabel") or Instance.new("TextLabel")
	lbl.Name = "BannerText"
	lbl.Size = UDim2.new(0.96, 0, 0.84, 0)
	lbl.Position = UDim2.new(0.02, 0, 0.08, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = "⚽  BUILD A FOOTBALLER  ⚽"
	lbl.TextColor3 = p.Gold
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled = true
	lbl.Parent = frame
end

return table.freeze(LeaderboardBuilder)

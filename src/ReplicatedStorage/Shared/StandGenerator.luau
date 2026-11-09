--!strict
--[[
	StandGenerator
	Responsibility: Procedural generator and live builder for the upgraded stadium stands (tribun).
	Matches reference Image 1 specifications:
	- Tall, multi-tier stepped stands (16 rows default, ~31 deg rake).
	- Distinct color-coded sectors per side:
	    * West: Cyan / Light Blue (#19C2FF)
	    * East: Yellow (#FFD21F)
	    * North: Magenta (#FF2E93) / Purple (#A855F7) / Red (#E5252A) multi-block
	    * South-Left: Orange (#FF8A1F)
	    * South-Right: Green (#3DDC3D)
	- Alternating seat color tread + dark charcoal riser (#181B22) for high-contrast visibility.
	- Vertical stair aisles splitting each side into blocks, with dark handrails & glowing edge lights.
	- Invisible smooth collision ramps over stair aisles to prevent player avatar snagging.
	- Tall dark-navy outer perimeter wall (#0F172A) with gold trim and top concourse walkway ring.
	- Zero-gap 45-degree beveled corners connecting all 8 sectors seamlessly.
	- 8 repositioned floodlight towers along the top outer rim pointing at the pitch.
	- Preserves South player tunnel, pitch, goals, tables, leaderboards, and jumbotron.
	- Grouped under Workspace/Stadium/Stands (with North, South, East, West, Corners, Shell, Lighting).
	- Supports Clear, Generate, and Regenerate workflows.

	Location: ReplicatedStorage/Shared/StandGenerator (ModuleScript)
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local StandGenerator = {}

-- ============================================================================
-- 1. MASTER CONFIGURATION
-- ============================================================================
StandGenerator.CONFIG = {
	-- Hierarchy & Target
	PARENT_PATH = "Workspace/Stadium/Stands",
	FALLBACK_LOBBY_PATH = "Workspace/Lobby/Stands",
	ARCHIVE_OLD_BOWL = true, -- Backs up existing StadiumBowl to ServerStorage

	-- Dimensions & Footprint (Outer boundary 300 x 190 studs)
	STADIUM_WIDTH = 300.0,   -- Total East-West span (X: -150 to +150)
	STADIUM_DEPTH = 190.0,   -- Total North-South span (Z: -138 to +52, center Z = -43)
	PITCH_CENTER = Vector3.new(0, 0, -43),

	-- Stepped Tier Geometry
	ROW_COUNT = 16,          -- Default rows (suggested: 14 - 20)
	ROW_HEIGHT = 1.2,        -- Studs rise per row (16 * 1.2 = 19.2 studs rise)
	ROW_DEPTH = 2.0,         -- Studs run per row (rake = atan(1.2/2.0) ≈ 30.96 deg)
	SEAT_THICKNESS = 0.45,   -- Tread part thickness
	RISER_THICKNESS = 0.40,  -- Front step face thickness

	-- Inner Bowl Perimeter (Front line where lowest row starts)
	INNER_BOUNDS = {
		North_Z = -112.0,     -- Inner North front edge (behind leaderboards/jumbotron)
		South_Z = 26.0,       -- Inner South front edge (at player tunnel mouth)
		West_X = -96.0,       -- Inner West front edge (outside West goal keepout)
		East_X = 96.0,        -- Inner East front edge (outside East goal keepout)
		Corner_Dx = 20.0,     -- Corner bevel delta X
		Corner_Dz = 20.0,     -- Corner bevel delta Z
	},

	-- South Tunnel Opening Cutout
	TUNNEL_CUTOUT = {
		HalfWidth = 9.0,      -- Opening from X = -9.0 to +9.0 (18 studs total clear width)
		Height = 12.0,
		ArchDepth = 3.5,
	},

	-- Section Colors (Exact palette matching Image 1 & project specs)
	COLORS = {
		West = Color3.fromHex("#19C2FF"),        -- Cyan / Light Blue
		East = Color3.fromHex("#FFD21F"),        -- Yellow
		North_West = Color3.fromHex("#A855F7"),  -- Purple (NW block of North)
		North_Mid = Color3.fromHex("#FF2E93"),   -- Magenta (Center North block)
		North_East = Color3.fromHex("#E5252A"),  -- Crimson / Red (NE block of North)
		South_Left = Color3.fromHex("#FF8A1F"),  -- Orange (Sector F, West side of tunnel)
		South_Right = Color3.fromHex("#3DDC3D"), -- Green (Sector D, East side of tunnel)

		-- Structural neutrals
		Riser = Color3.fromHex("#181B22"),       -- Dark Charcoal / Slate riser
		AisleStep = Color3.fromHex("#2D323E"),   -- Non-slip stair aisle surface
		FrontWall = Color3.fromHex("#1E222D"),   -- Front boundary wall
		ConcourseFloor = Color3.fromHex("#1C2029"), -- Top walkway ring floor
		OuterWall = Color3.fromHex("#0F172A"),   -- Deep Dark Navy outer stadium wall
		OuterTrim = Color3.fromHex("#F5B82E"),   -- Bright Gold trim line
		Handrail = Color3.fromRGB(48, 54, 66),   -- Gunmetal metal railing

		-- Lighting & Neon Accents
		EdgeLight = Color3.fromRGB(255, 245, 215), -- Warm white/gold stair edge marker
	},

	-- Vertical Stair Aisles & Railings
	AISLE = {
		Width = 3.8,             -- Width of each walking stair aisle
		StepRiseExtra = 0.08,    -- Slight stair step elevation for readability
		EdgeLightSize = Vector3.new(0.28, 0.16, 0.32),
		EdgeLightSpacing = 2,    -- Light on every 2nd step
		RailingHeight = 2.4,     -- Height of center & side handrails
		RailingRadius = 0.18,    -- Metal post thickness
		CreateInvisibleRamp = true, -- Smooth invisible collision ramp over stairs
	},

	-- Neon Accent Lip Strip
	NEON_LIP = {
		Enabled = false,         -- Disabled to prevent unnatural garish glowing rows
		Thickness = 0.12,
		Height = 0.16,
		Transparency = 0.35,     -- Low brightness, sleek modern accent
	},

	-- Top Concourse Walkway & Outer Shell
	SHELL = {
		ConcourseDepth = 8.5,    -- Width of top walkway ring
		OuterWallHeight = 26.0,  -- Outer wall height from ground (extends above concourse)
		WallThickness = 2.4,     -- Thickness of outer stadium navy wall
		TrimHeight = 1.2,        -- Top rim trim band height
		TrimOutset = 0.35,       -- Slight trim overhang
		CornerPillars = true,    -- 8 structural corner buttresses
		PillarWidth = 4.0,
		PillarHeight = 28.0,
		BannerCount = 20,        -- Hanging banners along exterior wall
	},

	-- Spectator Crowd (Performance Friendly)
	CROWD = {
		Enabled = true,
		Mode = "Billboard",      -- "Billboard" (lightweight SurfaceGui) | "None"
		PrimaryBias = 0.70,      -- 70% matching section primary color
		SpectatorDensity = 1.3,  -- Spectators per stud
		RowHeightStuds = 2.4,
	},

	-- Top Floodlight Towers
	FLOODLIGHTS = {
		Enabled = true,
		Count = 8,               -- 4 Corners + 2 North + 2 South
		MastHeight = 22.0,       -- Height above concourse floor
		HeadWidth = 9.6,
		HeadHeight = 5.2,
		HeadDepth = 1.0,
		LampColor = Color3.fromRGB(255, 250, 240),
		LightBrightness = 1.0,
		LightRange = 75.0,
		LightAngle = 65.0,
		CastShadows = false,     -- Shadows disabled for silky mobile 60 FPS
	},
}

export type GeneratorConfig = typeof(StandGenerator.CONFIG)

local CROWD_NEUTRAL_SHIRTS = {
	Color3.fromHex("#FFFFFF"),
	Color3.fromHex("#1F2937"),
	Color3.fromHex("#4B5563"),
	Color3.fromHex("#9CA3AF"),
	Color3.fromHex("#D1D5DB"),
	Color3.fromHex("#F59E0B"),
}
local CROWD_SKIN_COLORS = {
	Color3.fromHex("#F5CBA7"),
	Color3.fromHex("#E5B287"),
	Color3.fromHex("#C98E63"),
	Color3.fromHex("#7B4B2A"),
	Color3.fromHex("#523018"),
}

-- ============================================================================
-- 2. HELPER FUNCTIONS: INSTANCE CREATION & COLLISION
-- ============================================================================
local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = if canCollide ~= nil then canCollide else true
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = (transparency or 0) < 0.5
	if transparency then
		part.Transparency = transparency
	end
	part.Parent = parent
	return part
end

local function makeWedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cf
	wedge.Color = color
	wedge.Material = material or Enum.Material.SmoothPlastic
	wedge.Anchored = true
	wedge.CanCollide = if canCollide ~= nil then canCollide else true
	wedge.CanTouch = false
	wedge.CanQuery = false
	wedge.CastShadow = false
	if transparency then
		wedge.Transparency = transparency
	end
	wedge.Parent = parent
	return wedge
end

-- Attaches repeating individual seat bucket texture via SurfaceGui
local function attachSeatPattern(treadPart: Part, primaryColor: Color3, accentColor: Color3, tierNumber: number)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "SeatPatternGui"
	sg.Face = Enum.NormalId.Top
	sg.LightInfluence = 1.0
	sg.AlwaysOnTop = false
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 12
	sg.Parent = treadPart

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 2)
	layout.Parent = container

	local seatWidthStuds = 1.4
	local totalSeats = math.max(4, math.floor(treadPart.Size.X / seatWidthStuds))
	local seatPixelWidth = (12 * seatWidthStuds) - 2

	for i = 1, totalSeats do
		local isPrimary = (i + tierNumber) % 5 ~= 0
		local seatFrame = Instance.new("Frame")
		seatFrame.Name = `Seat_{i}`
		seatFrame.Size = UDim2.new(0, seatPixelWidth, 0.88, 0)
		seatFrame.BackgroundColor3 = if isPrimary then primaryColor else accentColor
		seatFrame.BorderSizePixel = 1
		seatFrame.BorderColor3 = Color3.fromHex("#0F131A")
		seatFrame.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = seatFrame

		local groove = Instance.new("Frame")
		groove.Size = UDim2.new(0.7, 0, 0.6, 0)
		groove.Position = UDim2.new(0.15, 0, 0.2, 0)
		groove.BackgroundColor3 = Color3.new(0, 0, 0)
		groove.BackgroundTransparency = 0.82
		groove.BorderSizePixel = 0
		groove.Parent = seatFrame
		local grooveCorner = Instance.new("UICorner")
		grooveCorner.CornerRadius = UDim.new(0, 2)
		grooveCorner.Parent = groove
	end
end

-- Attaches optimized billboard crowd strip per tier
local function attachCrowdStrip(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	primaryColor: Color3,
	rng: Random
)
	local strip = makePart(parent, name, size, cf, Color3.fromRGB(30, 34, 42), Enum.Material.SmoothPlastic, false, 1)
	strip.CastShadow = false

	local sg = Instance.new("SurfaceGui")
	sg.Name = "CrowdGui"
	sg.Face = Enum.NormalId.Front
	sg.LightInfluence = 1.0
	sg.AlwaysOnTop = false
	sg.MaxDistance = 350
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 14
	sg.Parent = strip

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(0, 3)
	layout.Parent = root

	-- Calculate exact fan count to completely fill the strip width without gaps
	local totalPixels = size.X * sg.PixelsPerStud
	local fanCount = math.max(1, math.floor((totalPixels + 3) / 19))
	for f = 1, fanCount do
		local fanFrame = Instance.new("Frame")
		fanFrame.Name = `Fan_{f}`
		fanFrame.Size = UDim2.new(0, 16, 1, 0)
		fanFrame.BackgroundTransparency = 1
		fanFrame.Parent = root

		local head = Instance.new("Frame")
		head.Size = UDim2.new(0, 11, 0.38, 0)
		head.Position = UDim2.new(0, 2.5, 0.04, 0)
		head.BackgroundColor3 = CROWD_SKIN_COLORS[rng:NextInteger(1, #CROWD_SKIN_COLORS)]
		head.BorderSizePixel = 0
		head.Parent = fanFrame
		local hCorner = Instance.new("UICorner")
		hCorner.CornerRadius = UDim.new(1, 0)
		hCorner.Parent = head

		local body = Instance.new("Frame")
		body.Size = UDim2.new(0, 16, 0.58, 0)
		body.Position = UDim2.new(0, 0, 0.42, 0)
		-- All supporter shirts match the stand's color (with subtle tone depth so individual fans remain distinct)
		local r = rng:NextNumber()
		local shirtCol = primaryColor
		if r < 0.20 then
			shirtCol = primaryColor:Lerp(Color3.new(1, 1, 1), 0.15)
		elseif r < 0.35 then
			shirtCol = primaryColor:Lerp(Color3.new(0, 0, 0), 0.15)
		end
		body.BackgroundColor3 = shirtCol
		body.BorderSizePixel = 0
		body.Parent = fanFrame
		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 3)
		bCorner.Parent = body
	end
end

-- Attaches vertical stair aisle with edge lights, center handrail, and invisible walking ramp
local function buildAisle(
	parentFolder: Instance,
	startPos: Vector3,
	outward: Vector3,
	right: Vector3,
	baseLen: number,
	fraction: number,
	aisleIdx: string | number,
	cfg: GeneratorConfig
)
	local af = Instance.new("Folder")
	af.Name = `Aisle_{aisleIdx}`
	af.Parent = parentFolder

	local rows = cfg.ROW_COUNT
	local rowH = cfg.ROW_HEIGHT
	local rowD = cfg.ROW_DEPTH
	local colors = cfg.COLORS
	local aX = (-baseLen * 0.5) + fraction * baseLen

	for tier = 1, rows do
		local d = (tier - 0.5) * rowD + 0.6
		local h = (tier - 0.5) * rowH
		local stepC = startPos + outward * d + right * aX + Vector3.new(0, h + cfg.AISLE.StepRiseExtra, 0)
		local stepRot = CFrame.lookAt(stepC, stepC + outward)
		makePart(af, `AisleStep_{tier}`, Vector3.new(cfg.AISLE.Width, cfg.SEAT_THICKNESS + 0.1, rowD), stepRot, colors.AisleStep, Enum.Material.SmoothPlastic)

		if tier % cfg.AISLE.EdgeLightSpacing == 0 then
			local hw = cfg.AISLE.Width * 0.5 - 0.25
			for _, s in { -1, 1 } do
				local lCF = stepRot * CFrame.new(s * hw, (cfg.SEAT_THICKNESS + 0.1) / 2 + 0.08, rowD * 0.4)
				makePart(af, `EdgeLight_{tier}_{s}`, cfg.AISLE.EdgeLightSize, lCF, colors.EdgeLight, Enum.Material.Neon, false)
			end
		end
	end

	local startHR = startPos + outward * 1.5 + right * aX + Vector3.new(0, rowH + cfg.AISLE.RailingHeight, 0)
	local endHR = startPos + outward * (rows * rowD + 0.6) + right * aX + Vector3.new(0, rows * rowH + cfg.AISLE.RailingHeight, 0)
	local rLen = (endHR - startHR).Magnitude
	local rCF = CFrame.lookAt((startHR + endHR) / 2, endHR)
	makePart(af, "CenterHandrail", Vector3.new(0.36, 0.36, rLen), rCF, colors.Handrail, Enum.Material.Metal)

	for tier = 2, rows, 3 do
		local d = (tier - 0.5) * rowD + 0.6
		local h = (tier - 0.5) * rowH
		local pBase = startPos + outward * d + right * aX + Vector3.new(0, h + cfg.AISLE.StepRiseExtra, 0)
		makePart(af, `RailPost_{tier}`, Vector3.new(0.24, cfg.AISLE.RailingHeight, 0.24), CFrame.new(pBase + Vector3.new(0, cfg.AISLE.RailingHeight * 0.5, 0)), colors.Handrail, Enum.Material.Metal)
	end

	if cfg.AISLE.CreateInvisibleRamp then
		local totalRun = rows * rowD
		local totalRise = rows * rowH
		local rampCenter = startPos + outward * (totalRun * 0.5 + 0.6) + right * aX + Vector3.new(0, totalRise * 0.5 + 0.1, 0)
		local rampRot = CFrame.lookAt(rampCenter, rampCenter + outward)
		makeWedge(af, "AisleWalkRamp", Vector3.new(cfg.AISLE.Width, totalRise, totalRun), rampRot * CFrame.Angles(0, math.pi, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, true, 1)
	end
end

-- ============================================================================
-- 3. CONTAINER RESOLUTION & BACKUP
-- ============================================================================
local function resolveStandsContainer(cfg: GeneratorConfig): (Instance, Folder)
	local stadium = Workspace:FindFirstChild("Stadium")
	if not stadium then
		stadium = Instance.new("Folder")
		stadium.Name = "Stadium"
		stadium.Parent = Workspace
	end

	local stands = stadium:FindFirstChild("Stands")
	if not stands then
		stands = Instance.new("Folder")
		stands.Name = "Stands"
		stands.Parent = stadium
	end

	if cfg.ARCHIVE_OLD_BOWL then
		local lobby = Workspace:FindFirstChild("Lobby")
		local oldBowl = (lobby and lobby:FindFirstChild("StadiumBowl"))
			or (lobby and lobby:FindFirstChild("Stands") and lobby.Stands:FindFirstChild("StadiumBowl"))
		if oldBowl then
			local backupFolder = ServerStorage:FindFirstChild("Stands_Backup")
			if not backupFolder then
				backupFolder = Instance.new("Folder")
				backupFolder.Name = "Stands_Backup"
				backupFolder.Parent = ServerStorage
			end
			if not backupFolder:FindFirstChild(oldBowl.Name) then
				local clone = oldBowl:Clone()
				clone.Parent = backupFolder
			end
			oldBowl.Parent = backupFolder
		end
	end

	return stadium, stands :: Folder
end

-- ============================================================================
-- 4. PUBLIC API: GENERATE, CLEAR, REGENERATE
-- ============================================================================

function StandGenerator.Clear()
	local stadium = Workspace:FindFirstChild("Stadium")
	if stadium then
		if stadium:FindFirstChild("Stands") then
			stadium.Stands:Destroy()
		end
		if stadium:FindFirstChild("Borders") then
			stadium.Borders:Destroy()
		end
	end
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby and lobby:FindFirstChild("Stands") and lobby.Stands:FindFirstChild("UpgradedStands") then
		lobby.Stands.UpgradedStands:Destroy()
	end
end

function StandGenerator.Generate(customConfig: GeneratorConfig?): Folder
	local cfg = customConfig or StandGenerator.CONFIG
	local _, standsFolder = resolveStandsContainer(cfg)
	standsFolder:ClearAllChildren()

	local northF = Instance.new("Folder") northF.Name = "North" northF.Parent = standsFolder
	local southF = Instance.new("Folder") southF.Name = "South" southF.Parent = standsFolder
	local eastF = Instance.new("Folder") eastF.Name = "East" eastF.Parent = standsFolder
	local westF = Instance.new("Folder") westF.Name = "West" westF.Parent = standsFolder
	local cornersF = Instance.new("Folder") cornersF.Name = "Corners" cornersF.Parent = standsFolder

	local rows = cfg.ROW_COUNT
	local rowH = cfg.ROW_HEIGHT
	local rowD = cfg.ROW_DEPTH
	local colors = cfg.COLORS
	local rng = Random.new(1337)

	-- 1. North Stand: Magenta / Purple / Red gradient multi-block
	for tier = 1, rows do
		local d = (tier - 0.5) * rowD + 0.6
		local h = (tier - 0.5) * rowH
		local tierLen = 152 + 2 * d
		local rowC = Vector3.new(0, h, -112 - d)
		local rowRot = CFrame.lookAt(rowC, rowC + Vector3.new(0, 0, -1))

		makePart(northF, `Riser_{tier}`, Vector3.new(tierLen, rowH, cfg.RISER_THICKNESS), rowRot * CFrame.new(0, -rowH * 0.5, rowD * 0.5), colors.Riser)

		local blocks = {
			{ color = colors.North_West, frac = 0.33 },
			{ color = colors.North_Mid, frac = 0.34 },
			{ color = colors.North_East, frac = 0.33 },
		}
		local currLeft = -tierLen * 0.5
		for bIdx, b in ipairs(blocks) do
			local bLen = tierLen * b.frac
			local bC = currLeft + bLen * 0.5
			local tread = makePart(northF, `Seats_{tier}_B{bIdx}`, Vector3.new(bLen - 0.2, cfg.SEAT_THICKNESS, rowD), rowRot * CFrame.new(bC, cfg.SEAT_THICKNESS * 0.5, 0), b.color)
			attachSeatPattern(tread, b.color, Color3.new(1, 1, 1), tier)
			if cfg.NEON_LIP.Enabled then
				makePart(northF, `NeonLip_{tier}_B{bIdx}`, Vector3.new(bLen - 0.2, cfg.NEON_LIP.Height, cfg.NEON_LIP.Thickness), rowRot * CFrame.new(bC, cfg.SEAT_THICKNESS * 0.5, rowD * 0.5 - 0.05), b.color, Enum.Material.Neon, false, cfg.NEON_LIP.Transparency)
			end
			if cfg.CROWD.Enabled then
				local crowdRot = rowRot * CFrame.Angles(0, math.pi, 0)
				attachCrowdStrip(northF, `CrowdStrip_{tier}_B{bIdx}`, Vector3.new(bLen - 0.6, cfg.CROWD.RowHeightStuds, 0.15), crowdRot * CFrame.new(-bC, cfg.CROWD.RowHeightStuds * 0.5 + cfg.SEAT_THICKNESS, -rowD * 0.15), b.color, rng)
			end
			currLeft = currLeft + bLen
		end
	end
	buildAisle(northF, Vector3.new(0, 0, -112), Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), 152, 0.25, 1, cfg)
	buildAisle(northF, Vector3.new(0, 0, -112), Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), 152, 0.50, 2, cfg)
	buildAisle(northF, Vector3.new(0, 0, -112), Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), 152, 0.75, 3, cfg)

	-- 2. West Stand: Cyan / Light Blue
	for tier = 1, rows do
		local d = (tier - 0.5) * rowD + 0.6
		local h = (tier - 0.5) * rowH
		local tierLen = 98 + 2 * d
		local rowC = Vector3.new(-96 - d, h, -43)
		local rowRot = CFrame.lookAt(rowC, rowC + Vector3.new(-1, 0, 0))

		makePart(westF, `Riser_{tier}`, Vector3.new(tierLen, rowH, cfg.RISER_THICKNESS), rowRot * CFrame.new(0, -rowH * 0.5, rowD * 0.5), colors.Riser)
		local tread = makePart(westF, `Seats_{tier}`, Vector3.new(tierLen, cfg.SEAT_THICKNESS, rowD), rowRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, 0), colors.West)
		attachSeatPattern(tread, colors.West, Color3.fromHex("#E2E8F0"), tier)
		if cfg.NEON_LIP.Enabled then
			makePart(westF, `NeonLip_{tier}`, Vector3.new(tierLen, cfg.NEON_LIP.Height, cfg.NEON_LIP.Thickness), rowRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, rowD * 0.5 - 0.05), colors.West, Enum.Material.Neon, false, cfg.NEON_LIP.Transparency)
		end
		if cfg.CROWD.Enabled then
			local crowdRot = rowRot * CFrame.Angles(0, math.pi, 0)
			attachCrowdStrip(westF, `CrowdStrip_{tier}`, Vector3.new(tierLen - 1.0, cfg.CROWD.RowHeightStuds, 0.15), crowdRot * CFrame.new(0, cfg.CROWD.RowHeightStuds * 0.5 + cfg.SEAT_THICKNESS, -rowD * 0.15), colors.West, rng)
		end
	end
	buildAisle(westF, Vector3.new(-96, 0, -43), Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1), 98, 0.33, 1, cfg)
	buildAisle(westF, Vector3.new(-96, 0, -43), Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1), 98, 0.67, 2, cfg)

	-- 3. East Stand: Yellow
	for tier = 1, rows do
		local d = (tier - 0.5) * rowD + 0.6
		local h = (tier - 0.5) * rowH
		local tierLen = 98 + 2 * d
		local rowC = Vector3.new(96 + d, h, -43)
		local rowRot = CFrame.lookAt(rowC, rowC + Vector3.new(1, 0, 0))

		makePart(eastF, `Riser_{tier}`, Vector3.new(tierLen, rowH, cfg.RISER_THICKNESS), rowRot * CFrame.new(0, -rowH * 0.5, rowD * 0.5), colors.Riser)
		local tread = makePart(eastF, `Seats_{tier}`, Vector3.new(tierLen, cfg.SEAT_THICKNESS, rowD), rowRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, 0), colors.East)
		attachSeatPattern(tread, colors.East, Color3.fromHex("#E2E8F0"), tier)
		if cfg.NEON_LIP.Enabled then
			makePart(eastF, `NeonLip_{tier}`, Vector3.new(tierLen, cfg.NEON_LIP.Height, cfg.NEON_LIP.Thickness), rowRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, rowD * 0.5 - 0.05), colors.East, Enum.Material.Neon, false, cfg.NEON_LIP.Transparency)
		end
		if cfg.CROWD.Enabled then
			local crowdRot = rowRot * CFrame.Angles(0, math.pi, 0)
			attachCrowdStrip(eastF, `CrowdStrip_{tier}`, Vector3.new(tierLen - 1.0, cfg.CROWD.RowHeightStuds, 0.15), crowdRot * CFrame.new(0, cfg.CROWD.RowHeightStuds * 0.5 + cfg.SEAT_THICKNESS, -rowD * 0.15), colors.East, rng)
		end
	end
	buildAisle(eastF, Vector3.new(96, 0, -43), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), 98, 0.33, 1, cfg)
	buildAisle(eastF, Vector3.new(96, 0, -43), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), 98, 0.67, 2, cfg)

	-- 4. South Stand: Split into Left = Orange, Right = Green by tunnel opening
	local halfS = 67.0
	for tier = 1, rows do
		local d = (tier - 0.5) * rowD + 0.6
		local h = (tier - 0.5) * rowH
		local wingLen = halfS + d

		-- Left Wing (Orange)
		local leftC = Vector3.new(-9.0 - wingLen * 0.5, h, 26 + d)
		local leftRot = CFrame.lookAt(leftC, leftC + Vector3.new(0, 0, 1))
		makePart(southF, `Riser_L_{tier}`, Vector3.new(wingLen, rowH, cfg.RISER_THICKNESS), leftRot * CFrame.new(0, -rowH * 0.5, rowD * 0.5), colors.Riser)
		local treadL = makePart(southF, `Seats_L_{tier}`, Vector3.new(wingLen, cfg.SEAT_THICKNESS, rowD), leftRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, 0), colors.South_Left)
		attachSeatPattern(treadL, colors.South_Left, Color3.new(1, 1, 1), tier)
		if cfg.NEON_LIP.Enabled then
			makePart(southF, `NeonLip_L_{tier}`, Vector3.new(wingLen, cfg.NEON_LIP.Height, cfg.NEON_LIP.Thickness), leftRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, rowD * 0.5 - 0.05), colors.South_Left, Enum.Material.Neon, false, cfg.NEON_LIP.Transparency)
		end
		if cfg.CROWD.Enabled then
			local crowdRotL = leftRot * CFrame.Angles(0, math.pi, 0)
			attachCrowdStrip(southF, `CrowdStrip_L_{tier}`, Vector3.new(wingLen - 1.0, cfg.CROWD.RowHeightStuds, 0.15), crowdRotL * CFrame.new(0, cfg.CROWD.RowHeightStuds * 0.5 + cfg.SEAT_THICKNESS, -rowD * 0.15), colors.South_Left, rng)
		end

		-- Right Wing (Green)
		local rightC = Vector3.new(9.0 + wingLen * 0.5, h, 26 + d)
		local rightRot = CFrame.lookAt(rightC, rightC + Vector3.new(0, 0, 1))
		makePart(southF, `Riser_R_{tier}`, Vector3.new(wingLen, rowH, cfg.RISER_THICKNESS), rightRot * CFrame.new(0, -rowH * 0.5, rowD * 0.5), colors.Riser)
		local treadR = makePart(southF, `Seats_R_{tier}`, Vector3.new(wingLen, cfg.SEAT_THICKNESS, rowD), rightRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, 0), colors.South_Right)
		attachSeatPattern(treadR, colors.South_Right, Color3.new(1, 1, 1), tier)
		if cfg.NEON_LIP.Enabled then
			makePart(southF, `NeonLip_R_{tier}`, Vector3.new(wingLen, cfg.NEON_LIP.Height, cfg.NEON_LIP.Thickness), rightRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, rowD * 0.5 - 0.05), colors.South_Right, Enum.Material.Neon, false, cfg.NEON_LIP.Transparency)
		end
		if cfg.CROWD.Enabled then
			local crowdRotR = rightRot * CFrame.Angles(0, math.pi, 0)
			attachCrowdStrip(southF, `CrowdStrip_R_{tier}`, Vector3.new(wingLen - 1.0, cfg.CROWD.RowHeightStuds, 0.15), crowdRotR * CFrame.new(0, cfg.CROWD.RowHeightStuds * 0.5 + cfg.SEAT_THICKNESS, -rowD * 0.15), colors.South_Right, rng)
		end
	end
	buildAisle(southF, Vector3.new(-42.5, 0, 26), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), 67, 0.50, "Left_1", cfg)
	buildAisle(southF, Vector3.new(42.5, 0, 26), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), 67, 0.50, "Right_1", cfg)

	-- Tunnel Portal disabled: PlayerTunnelService provides flush tunnel walls; portal jambs penetrated seats
	local SPAWN_TUNNEL_PORTAL = false
	if SPAWN_TUNNEL_PORTAL then
		local tPortal = Instance.new("Folder")
		tPortal.Name = "TunnelPortal"
		tPortal.Parent = southF
		makePart(tPortal, "Jamb_L", Vector3.new(2.4, 12, 3.5), CFrame.new(-10.2, 6, 28.35), colors.OuterWall)
		makePart(tPortal, "Jamb_R", Vector3.new(2.4, 12, 3.5), CFrame.new(10.2, 6, 28.35), colors.OuterWall)
	end

	-- 5. Four 45-Degree Corners (Zero-gap connection)
	local cornerConfigs = {
		{ name = "Corner_NW", sx = -1, sz = -1, color = colors.North_West, cX = -86, cZ = -102 },
		{ name = "Corner_NE", sx = 1, sz = -1, color = colors.North_East, cX = 86, cZ = -102 },
		{ name = "Corner_SE", sx = 1, sz = 1, color = colors.South_Right, cX = 86, cZ = 16 },
		{ name = "Corner_SW", sx = -1, sz = 1, color = colors.South_Left, cX = -86, cZ = 16 },
	}

	local cornerLen = 28.5
	for _, cc in ipairs(cornerConfigs) do
		local f = Instance.new("Folder")
		f.Name = cc.name
		f.Parent = cornersF

		local outward = Vector3.new(cc.sx, 0, cc.sz).Unit
		for tier = 1, rows do
			local d = (tier - 0.5) * rowD + 0.6
			local h = (tier - 0.5) * rowH
			local rowC = Vector3.new(cc.cX + cc.sx * d, h, cc.cZ + cc.sz * d)
			local rowRot = CFrame.lookAt(rowC, rowC + outward)

			makePart(f, `Riser_{tier}`, Vector3.new(cornerLen, rowH, cfg.RISER_THICKNESS), rowRot * CFrame.new(0, -rowH * 0.5, rowD * 0.5), colors.Riser)
			local tread = makePart(f, `Seats_{tier}`, Vector3.new(cornerLen, cfg.SEAT_THICKNESS, rowD), rowRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, 0), cc.color)
			attachSeatPattern(tread, cc.color, Color3.new(1, 1, 1), tier)
			if cfg.NEON_LIP.Enabled then
				makePart(f, `NeonLip_{tier}`, Vector3.new(cornerLen, cfg.NEON_LIP.Height, cfg.NEON_LIP.Thickness), rowRot * CFrame.new(0, cfg.SEAT_THICKNESS * 0.5, rowD * 0.5 - 0.05), cc.color, Enum.Material.Neon, false, cfg.NEON_LIP.Transparency)
			end
			if cfg.CROWD.Enabled then
				local crowdRot = rowRot * CFrame.Angles(0, math.pi, 0)
				attachCrowdStrip(f, `CrowdStrip_{tier}`, Vector3.new(cornerLen - 0.8, cfg.CROWD.RowHeightStuds, 0.15), crowdRot * CFrame.new(0, cfg.CROWD.RowHeightStuds * 0.5 + cfg.SEAT_THICKNESS, -rowD * 0.15), cc.color, rng)
			end
		end
	end

	-- 6. Shell, Outer Navy Wall & Concourse
	local shellF = Instance.new("Folder")
	shellF.Name = "Shell"
	shellF.Parent = standsFolder

	local topElev = rows * rowH
	local topRun = (rows - 0.5) * rowD + 0.6
	local concourseD = cfg.SHELL.ConcourseDepth
	local wallH = cfg.SHELL.OuterWallHeight
	local wallThick = cfg.SHELL.WallThickness

	local allPerimeters = {
		{ name = "North", center = Vector3.new(0, topElev, -112 - topRun - concourseD * 0.5), outward = Vector3.new(0, 0, -1), len = 152 + 2 * topRun },
		{ name = "West", center = Vector3.new(-96 - topRun - concourseD * 0.5, topElev, -43), outward = Vector3.new(-1, 0, 0), len = 98 + 2 * topRun },
		{ name = "East", center = Vector3.new(96 + topRun + concourseD * 0.5, topElev, -43), outward = Vector3.new(1, 0, 0), len = 98 + 2 * topRun },
		{ name = "South", center = Vector3.new(0, topElev, 26 + topRun + concourseD * 0.5), outward = Vector3.new(0, 0, 1), len = 152 + 2 * topRun },
		{ name = "NW", center = Vector3.new(-86 - topRun - concourseD * 0.5 * 0.707, topElev, -102 - topRun - concourseD * 0.5 * 0.707), outward = Vector3.new(-1, 0, -1).Unit, len = cornerLen },
		{ name = "NE", center = Vector3.new(86 + topRun + concourseD * 0.5 * 0.707, topElev, -102 - topRun - concourseD * 0.5 * 0.707), outward = Vector3.new(1, 0, -1).Unit, len = cornerLen },
		{ name = "SE", center = Vector3.new(86 + topRun + concourseD * 0.5 * 0.707, topElev, 16 + topRun + concourseD * 0.5 * 0.707), outward = Vector3.new(1, 0, 1).Unit, len = cornerLen },
		{ name = "SW", center = Vector3.new(-86 - topRun - concourseD * 0.5 * 0.707, topElev, 16 + topRun + concourseD * 0.5 * 0.707), outward = Vector3.new(-1, 0, 1).Unit, len = cornerLen },
	}

	for _, p in ipairs(allPerimeters) do
		local pRot = CFrame.lookAt(p.center, p.center + p.outward)
		makePart(shellF, `Floor_{p.name}`, Vector3.new(p.len, 1.2, concourseD), pRot, colors.ConcourseFloor)
		makePart(shellF, `Railing_{p.name}`, Vector3.new(p.len, 2.4, 0.4), pRot * CFrame.new(0, 1.8, concourseD * 0.5 - 0.3), colors.Handrail, Enum.Material.Metal)

		local wallC = pRot * CFrame.new(0, -topElev + wallH * 0.5, -concourseD * 0.5 - wallThick * 0.5)
		makePart(shellF, `Wall_{p.name}`, Vector3.new(p.len + wallThick, wallH, wallThick), wallC, colors.OuterWall)
		makePart(shellF, `Trim_{p.name}`, Vector3.new(p.len + wallThick + 0.8, cfg.SHELL.TrimHeight, wallThick + 0.8), wallC * CFrame.new(0, wallH * 0.5 + cfg.SHELL.TrimHeight * 0.5, 0), colors.OuterTrim)
	end

	-- 7. Floodlights
	local floodFolder = Instance.new("Folder")
	floodFolder.Name = "Lighting"
	floodFolder.Parent = standsFolder

	local flCfg = cfg.FLOODLIGHTS
	local flPositions = {
		Vector3.new(-120, topElev, -126), Vector3.new(120, topElev, -126),
		Vector3.new(120, topElev, 40), Vector3.new(-120, topElev, 40),
		Vector3.new(-48, topElev, -136), Vector3.new(48, topElev, -136),
		Vector3.new(-48, topElev, 50), Vector3.new(48, topElev, 50),
	}

	for idx, bPos in ipairs(flPositions) do
		local m = Instance.new("Model")
		m.Name = `FloodTower_{idx}`
		m.Parent = floodFolder

		local mastH = flCfg.MastHeight
		makePart(m, "MastPole", Vector3.new(2.4, mastH, 2.4), CFrame.new(bPos + Vector3.new(0, mastH * 0.5, 0)), Color3.fromRGB(52, 58, 70), Enum.Material.Metal)

		local hPos = bPos + Vector3.new(0, mastH + 1.2, 0)
		local hLook = CFrame.lookAt(hPos, Vector3.new(0, 3, -43))
		makePart(m, "HeadFrame", Vector3.new(flCfg.HeadWidth, flCfg.HeadHeight, flCfg.HeadDepth), hLook * CFrame.new(0, 0, 0.4), Color3.fromRGB(36, 40, 50), Enum.Material.Metal)
		local lamp = makePart(m, "FloodLamp", Vector3.new(flCfg.HeadWidth - 0.8, flCfg.HeadHeight - 0.8, 0.6), hLook, flCfg.LampColor, Enum.Material.Neon)

		local light = Instance.new("SpotLight")
		light.Name = "StadiumSpotLight"
		light.Brightness = flCfg.LightBrightness
		light.Range = flCfg.LightRange
		light.Angle = flCfg.LightAngle
		light.Face = Enum.NormalId.Front
		light.Shadows = false
		light.Color = flCfg.LampColor
		light.Parent = lamp
	end

	-- 8. Invisible Perimeter & Ceiling Borders (keep players inside stadium)
	local stadiumParent = standsFolder.Parent
	if stadiumParent then
		StandGenerator.BuildBorders(stadiumParent)
	end

	return standsFolder
end

function StandGenerator.BuildBorders(parentContainer: Instance?): Folder
	local stadium = parentContainer or Workspace:FindFirstChild("Stadium") or Workspace
	local existing = stadium:FindFirstChild("Borders")
	if existing then
		existing:Destroy()
	end

	local borderFolder = Instance.new("Folder")
	borderFolder.Name = "Borders"

	local wallH = 120.0
	local wallThick = 6.0

	local wallDefs = {
		{ name = "Border_North", cf = CFrame.new(0, wallH * 0.5, -153.3), sz = Vector3.new(225.6, wallH, wallThick) },
		{ name = "Border_South", cf = CFrame.new(0, wallH * 0.5, 67.3), sz = Vector3.new(225.6, wallH, wallThick) },
		{ name = "Border_West",  cf = CFrame.new(-137.3, wallH * 0.5, -43), sz = Vector3.new(wallThick, wallH, 171.6) },
		{ name = "Border_East",  cf = CFrame.new(137.3, wallH * 0.5, -43), sz = Vector3.new(wallThick, wallH, 171.6) },
		{ name = "Border_NW",    cf = CFrame.new(-124.5, wallH * 0.5, -140.5) * CFrame.Angles(0, math.rad(45), 0), sz = Vector3.new(38.9, wallH, wallThick) },
		{ name = "Border_NE",    cf = CFrame.new(124.5, wallH * 0.5, -140.5) * CFrame.Angles(0, math.rad(-45), 0), sz = Vector3.new(38.9, wallH, wallThick) },
		{ name = "Border_SE",    cf = CFrame.new(124.5, wallH * 0.5, 54.5) * CFrame.Angles(0, math.rad(-135), 0), sz = Vector3.new(38.9, wallH, wallThick) },
		{ name = "Border_SW",    cf = CFrame.new(-124.5, wallH * 0.5, 54.5) * CFrame.Angles(0, math.rad(135), 0), sz = Vector3.new(38.9, wallH, wallThick) },
	}

	for _, def in ipairs(wallDefs) do
		local p = Instance.new("Part")
		p.Name = def.name
		p.Anchored = true
		p.CanCollide = true
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Transparency = 1
		p.Material = Enum.Material.SmoothPlastic
		p.CFrame = def.cf
		p.Size = def.sz
		p.Parent = borderFolder
	end

	local ceiling = Instance.new("Part")
	ceiling.Name = "Border_Ceiling"
	ceiling.Anchored = true
	ceiling.CanCollide = true
	ceiling.CanTouch = false
	ceiling.CanQuery = false
	ceiling.CastShadow = false
	ceiling.Transparency = 1
	ceiling.Material = Enum.Material.SmoothPlastic
	ceiling.Size = Vector3.new(310, 4, 255)
	ceiling.CFrame = CFrame.new(0, wallH + 2, -43)
	ceiling.Parent = borderFolder

	borderFolder.Parent = stadium
	return borderFolder
end

function StandGenerator.Regenerate(customConfig: GeneratorConfig?): Folder
	StandGenerator.Clear()
	return StandGenerator.Generate(customConfig)
end

function StandGenerator.ToggleCrowd(visible: boolean)
	local stadium = Workspace:FindFirstChild("Stadium")
	if not stadium then return end
	local stands = stadium:FindFirstChild("Stands")
	if not stands then return end

	for _, desc in ipairs(stands:GetDescendants()) do
		if desc:IsA("SurfaceGui") and desc.Name == "CrowdGui" then
			desc.Enabled = visible
		end
	end
end

function StandGenerator.PulseGoalLights(duration: number?)
	local stadium = Workspace:FindFirstChild("Stadium")
	if not stadium then return end
	local lightingFolder = stadium.Stands:FindFirstChild("Lighting")
	if not lightingFolder then return end

	local totalDuration = duration or 5.0
	local targetBrightness = 2.4
	local baseBrightness = StandGenerator.CONFIG.FLOODLIGHTS.LightBrightness
	local goldColor = Color3.fromHex("#FFD21F")
	local baseColor = StandGenerator.CONFIG.FLOODLIGHTS.LampColor

	task.spawn(function()
		local startTime = os.clock()
		while os.clock() - startTime < totalDuration do
			local progress = (os.clock() - startTime) / totalDuration
			local wave = (math.sin(progress * math.pi * 6) + 1) * 0.5
			local currBrightness = baseBrightness + (targetBrightness - baseBrightness) * wave
			local currColor = baseColor:Lerp(goldColor, wave * 0.8)

			for _, tower in ipairs(lightingFolder:GetChildren()) do
				local lamp = tower:FindFirstChild("FloodLamp") :: Part?
				if lamp then
					lamp.Color = currColor
					local spot = lamp:FindFirstChildWhichIsA("SpotLight")
					if spot then
						spot.Brightness = currBrightness
						spot.Color = currColor
					end
				end
			end
			task.wait(0.03)
		end

		for _, tower in ipairs(lightingFolder:GetChildren()) do
			local lamp = tower:FindFirstChild("FloodLamp") :: Part?
			if lamp then
				lamp.Color = baseColor
				local spot = lamp:FindFirstChildWhichIsA("SpotLight")
				if spot then
					spot.Brightness = baseBrightness
					spot.Color = baseColor
				end
			end
		end
	end)
end

return table.freeze(StandGenerator)

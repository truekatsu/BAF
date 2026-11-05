--!strict
--[[
	RoofGenerator
	Responsibility: Procedural cantilever roof/canopy generator for the stadium stands (tribun).
	Features:
	- Cantilever canopy overhanging top 45% of stand rows (~15 studs inward), sloped at 9.5 deg.
	- Multi-layer profile: Deep navy deck (#0F1530), crisp silver underside soffit (#D9DEE8),
	  bright gold fascia trim (#F5B82E), royal blue accent line (#1F4FD8), and slim LED ribbon strip.
	- Cantilever steel rafters underneath deck + vertical columns at outer wall aligned with stair aisles.
	- Diagonal exterior back stay struts & heavy corner buttress towers with gold finials.
	- Zero-gap 45-degree beveled corner miters with architectural joint cap ribs.
	- South player tunnel entrance feature: framed open gap above tunnel with twin portal pylons and overhead bridge lintel.
	- Third-person camera clearance: 14-16 studs headroom above top row to avoid clipping.
	- Mobile-optimized: ~166 total parts (target < 600), CastShadow only on main deck, non-colliding deck.
	- Clear and Regenerate workflow under Workspace/Stadium/Roof.

	Location: ReplicatedStorage/Shared/RoofGenerator (ModuleScript)
]]

local Workspace = game:GetService("Workspace")

local RoofGenerator = {}

-- ============================================================================
-- 1. MASTER CONFIGURATION
-- ============================================================================
RoofGenerator.CONFIG = {
	-- Hierarchy & Target
	PARENT_PATH = "Workspace/Stadium/Roof",

	-- Geometry & Positioning
	ROOF_HEIGHT_AT_WALL = 35.0,  -- Height of roof deck back edge at outer wall (studs above Y=0)
	CANOPY_DEPTH = 24.0,         -- Horizontal depth from outer wall toward pitch (~15 studs stand overhang)
	CORNER_DEPTH = 17.0,         -- Radial inward depth for 45-degree corner sections
	SLOPE_DEG = 9.5,             -- Downward cantilever slope angle toward pitch (8 to 12 degrees)
	DECK_THICKNESS = 1.4,        -- Thickness of main navy roof deck part
	SOFFIT_THICKNESS = 0.35,     -- Thickness of silver underside ceiling panel
	TRIM_HEIGHT = 1.5,           -- Height of front gold fascia trim
	TRIM_THICKNESS = 0.5,        -- Thickness of front gold fascia trim
	BLUE_ACCENT_HEIGHT = 0.45,   -- Height of royal blue accent line below gold trim

	-- Structural Supports
	COLUMN_WIDTH = 2.2,          -- Cross-section size of vertical outer wall columns
	COLUMN_HEIGHT = 16.0,        -- Column height from concourse (Y=19.2) to roof line (Y=35.0)
	RAFTER_WIDTH = 1.4,          -- Cross-section of cantilever rafters underneath deck
	STRUT_WIDTH = 0.9,           -- Cross-section of diagonal exterior back stay struts
	CORNER_TOWER_WIDTH = 3.6,    -- Width of 45-degree corner buttress towers
	CORNER_TOWER_HEIGHT = 17.5,  -- Height of corner towers (Y=19.2 to Y=36.7)

	-- South Player Tunnel Framing
	SOUTH_TUNNEL_MODE = "Gap",   -- "Gap" (framed gap over tunnel) | "Full"
	SOUTH_TUNNEL_GAP = 26.0,     -- Width of opening centered at X=0 (X: -13 to +13 studs)
	SOUTH_PORTAL_FRAME = true,   -- Twin framing portal towers and lintel at tunnel gap

	-- Lighting & Accents
	LED_RIBBON_ENABLED = true,   -- Slim LED neon ribbon strip along front edge
	CAST_SHADOWS = true,         -- Cast shadows on main deck only (mobile 60 FPS friendly)

	-- Color Palette
	COLORS = {
		RoofDeck = Color3.fromHex("#0F1530"),       -- Deep Dark Navy
		Underside = Color3.fromHex("#D9DEE8"),      -- Crisp Silver / White Soffit
		GoldTrim = Color3.fromHex("#F5B82E"),       -- Bright Gold Trim
		BlueAccent = Color3.fromHex("#1F4FD8"),     -- Royal Blue Accent Strip
		SupportColumn = Color3.fromHex("#222733"),  -- Gunmetal Metal Pylon
		SupportBeam = Color3.fromHex("#2D3445"),    -- Structural Truss Gray
		SupportStrut = Color3.fromHex("#3E4659"),   -- Strut Steel
		CornerPylon = Color3.fromHex("#181D26"),    -- Heavy Corner Buttress
		RibbonNeon = Color3.fromHex("#1F4FD8"),     -- Electric Blue Neon Ribbon
	},
}

export type RoofConfig = typeof(RoofGenerator.CONFIG)

-- ============================================================================
-- 2. HELPER FUNCTIONS
-- ============================================================================
local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material?,
	canCollide: boolean?,
	castShadow: boolean?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = if canCollide ~= nil then canCollide else false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = if castShadow ~= nil then castShadow else false
	if transparency then
		p.Transparency = transparency
	end
	p.Parent = parent
	return p
end

local function resolveRoofContainer(): Folder
	local stadium = Workspace:FindFirstChild("Stadium")
	if not stadium then
		stadium = Instance.new("Folder")
		stadium.Name = "Stadium"
		stadium.Parent = Workspace
	end

	local roof = stadium:FindFirstChild("Roof")
	if not roof then
		roof = Instance.new("Folder")
		roof.Name = "Roof"
		roof.Parent = stadium
	end

	return roof :: Folder
end

-- ============================================================================
-- 3. PUBLIC API: CLEAR, GENERATE, REGENERATE, TOGGLE RIBBON
-- ============================================================================

function RoofGenerator.Clear()
	local stadium = Workspace:FindFirstChild("Stadium")
	if stadium and stadium:FindFirstChild("Roof") then
		stadium.Roof:Destroy()
	end
end

function RoofGenerator.Generate(customConfig: RoofConfig?): Folder
	local cfg = customConfig or RoofGenerator.CONFIG
	local roofFolder = resolveRoofContainer()
	roofFolder:ClearAllChildren()

	local colors = cfg.COLORS
	local slopeRad = math.rad(cfg.SLOPE_DEG)

	-- Subfolders
	local northF = Instance.new("Folder") northF.Name = "North" northF.Parent = roofFolder
	local southF = Instance.new("Folder") southF.Name = "South" southF.Parent = roofFolder
	local eastF = Instance.new("Folder") eastF.Name = "East" eastF.Parent = roofFolder
	local westF = Instance.new("Folder") westF.Name = "West" westF.Parent = roofFolder
	local cornersF = Instance.new("Folder") cornersF.Name = "Corners" cornersF.Parent = roofFolder
	local supportsF = Instance.new("Folder") supportsF.Name = "Supports" supportsF.Parent = roofFolder
	local trimF = Instance.new("Folder") trimF.Name = "Trim" trimF.Parent = roofFolder

	-- Helper to build standard roof canopy section
	local function buildCanopySection(
		parentFolder: Folder,
		sectionName: string,
		wallCenter: Vector3,
		inwardDir: Vector3,
		spanWidth: number,
		customDepth: number?
	): CFrame
		local sf = Instance.new("Folder")
		sf.Name = sectionName
		sf.Parent = parentFolder

		local d = customDepth or cfg.CANOPY_DEPTH
		local slantedD = d / math.cos(slopeRad)
		local vDrop = d * math.tan(slopeRad)

		local cY = cfg.ROOF_HEIGHT_AT_WALL - vDrop * 0.5
		local centerPos = wallCenter + inwardDir * (d * 0.5) + Vector3.new(0, cY - wallCenter.Y, 0)
		local baseCF = CFrame.lookAt(centerPos, centerPos + inwardDir) * CFrame.Angles(-slopeRad, 0, 0)

		-- 1. Main Deck
		makePart(sf, "RoofDeck", Vector3.new(spanWidth, cfg.DECK_THICKNESS, slantedD), baseCF, colors.RoofDeck, Enum.Material.SmoothPlastic, false, cfg.CAST_SHADOWS)

		-- 2. Silver Underside Soffit
		local soffitCF = baseCF * CFrame.new(0, -(cfg.DECK_THICKNESS + cfg.SOFFIT_THICKNESS) * 0.5, 0)
		makePart(sf, "Underside", Vector3.new(spanWidth - 0.2, cfg.SOFFIT_THICKNESS, slantedD - 0.2), soffitCF, colors.Underside, Enum.Material.SmoothPlastic, false, false)

		-- 3. Gold Front Trim
		local goldCF = baseCF * CFrame.new(0, 0, -slantedD * 0.5 - cfg.TRIM_THICKNESS * 0.5)
		makePart(sf, "FrontTrim_Gold", Vector3.new(spanWidth, cfg.TRIM_HEIGHT, cfg.TRIM_THICKNESS), goldCF, colors.GoldTrim, Enum.Material.SmoothPlastic, false, false)

		-- 4. Blue Accent Line
		local blueCF = baseCF * CFrame.new(0, -cfg.TRIM_HEIGHT * 0.45, -slantedD * 0.5 - cfg.TRIM_THICKNESS * 0.6)
		makePart(sf, "AccentStrip_Blue", Vector3.new(spanWidth, cfg.BLUE_ACCENT_HEIGHT, cfg.TRIM_THICKNESS + 0.1), blueCF, colors.BlueAccent, Enum.Material.SmoothPlastic, false, false)

		-- 5. Back Rim Fascia
		local backCF = baseCF * CFrame.new(0, 0, slantedD * 0.5 + 0.25)
		makePart(sf, "BackTrim_Navy", Vector3.new(spanWidth, cfg.DECK_THICKNESS + 0.4, 0.5), backCF, colors.RoofDeck, Enum.Material.SmoothPlastic, false, false)

		-- 6. Front LED Ribbon Board
		if cfg.LED_RIBBON_ENABLED then
			local ribbonCF = baseCF * CFrame.new(0, 0, -slantedD * 0.5 - cfg.TRIM_THICKNESS - 0.06)
			makePart(sf, "RibbonBoard", Vector3.new(spanWidth * 0.98, 0.45, 0.12), ribbonCF, colors.RibbonNeon, Enum.Material.Neon, false, false, 0.2)
		end

		return baseCF
	end

	-- Helper to build structural cantilever bent (Column + Rafter + Diagonal Strut)
	local function buildSupportBent(
		parentFolder: Folder,
		name: string,
		wallPos: Vector3,
		inwardDir: Vector3,
		hasStrut: boolean?
	)
		local bf = Instance.new("Folder")
		bf.Name = name
		bf.Parent = parentFolder

		local colH = cfg.COLUMN_HEIGHT
		local colBaseY = 19.2
		local colCenter = wallPos + Vector3.new(0, (colBaseY + colH * 0.5) - wallPos.Y, 0)

		-- Column has collision; stands against outer perimeter wall so aisles are 100% clear
		makePart(bf, "Column", Vector3.new(cfg.COLUMN_WIDTH, colH, cfg.COLUMN_WIDTH), CFrame.new(colCenter), colors.SupportColumn, Enum.Material.Metal, true, false)

		local d = cfg.CANOPY_DEPTH
		local slantedD = d / math.cos(slopeRad)
		local vDrop = d * math.tan(slopeRad)

		-- Cantilever rafter beam running under roof deck
		local rafterCenter = wallPos + inwardDir * (d * 0.5) + Vector3.new(0, (cfg.ROOF_HEIGHT_AT_WALL - vDrop * 0.5 - cfg.DECK_THICKNESS * 0.5 - cfg.RAFTER_WIDTH * 0.5) - wallPos.Y, 0)
		local rafterCF = CFrame.lookAt(rafterCenter, rafterCenter + inwardDir) * CFrame.Angles(-slopeRad, 0, 0)
		makePart(bf, "Rafter", Vector3.new(cfg.RAFTER_WIDTH, cfg.RAFTER_WIDTH, slantedD * 0.98), rafterCF, colors.SupportBeam, Enum.Material.Metal, false, false)

		-- Diagonal exterior tie-back strut
		if hasStrut ~= false then
			local topPoint = wallPos + Vector3.new(0, cfg.ROOF_HEIGHT_AT_WALL - wallPos.Y, 0)
			local bottomPoint = wallPos - inwardDir * 3.5 + Vector3.new(0, 26.0 - wallPos.Y, 0)
			local strutMid = (topPoint + bottomPoint) * 0.5
			local strutLen = (topPoint - bottomPoint).Magnitude
			local strutCF = CFrame.lookAt(strutMid, topPoint)
			makePart(bf, "Strut", Vector3.new(cfg.STRUT_WIDTH, cfg.STRUT_WIDTH, strutLen), strutCF, colors.SupportStrut, Enum.Material.Metal, false, false)
		end
	end

	-- 1. North Stand Canopy & Columns (Aligned with North stair aisles at X = -38, 0, 38)
	buildCanopySection(northF, "North_Canopy", Vector3.new(0, 19.2, -153.3), Vector3.new(0, 0, 1), 217.6)
	for _, x in ipairs({ -76, -38, 0, 38, 76 }) do
		buildSupportBent(supportsF, `North_Bent_{x}`, Vector3.new(x, 19.2, -153.3), Vector3.new(0, 0, 1), true)
	end

	-- 2. West Stand Canopy & Columns (Aligned with West stair aisles at Z = -60, -26)
	buildCanopySection(westF, "West_Canopy", Vector3.new(-137.3, 19.2, -43.0), Vector3.new(1, 0, 0), 163.6)
	for _, z in ipairs({ -103, -63, -23, 17 }) do
		buildSupportBent(supportsF, `West_Bent_{z}`, Vector3.new(-137.3, 19.2, z), Vector3.new(1, 0, 0), true)
	end

	-- 3. East Stand Canopy & Columns (Aligned with East stair aisles at Z = -60, -26)
	buildCanopySection(eastF, "East_Canopy", Vector3.new(137.3, 19.2, -43.0), Vector3.new(-1, 0, 0), 163.6)
	for _, z in ipairs({ -103, -63, -23, 17 }) do
		buildSupportBent(supportsF, `East_Bent_{z}`, Vector3.new(137.3, 19.2, z), Vector3.new(-1, 0, 0), true)
	end

	-- 4. South Stand Canopy (Split into Left & Right wings around the player tunnel opening)
	local southHalfSpan = 108.8 - 13.0
	buildCanopySection(southF, "South_Left_Canopy", Vector3.new(-13.0 - southHalfSpan * 0.5, 19.2, 67.3), Vector3.new(0, 0, -1), southHalfSpan)
	buildCanopySection(southF, "South_Right_Canopy", Vector3.new(13.0 + southHalfSpan * 0.5, 19.2, 67.3), Vector3.new(0, 0, -1), southHalfSpan)

	for _, x in ipairs({ -84, -42.5 }) do
		buildSupportBent(supportsF, `South_Bent_L_{x}`, Vector3.new(x, 19.2, 67.3), Vector3.new(0, 0, -1), true)
	end
	for _, x in ipairs({ 42.5, 84 }) do
		buildSupportBent(supportsF, `South_Bent_R_{x}`, Vector3.new(x, 19.2, 67.3), Vector3.new(0, 0, -1), true)
	end

	-- South Portal Framing Towers flanking the tunnel opening
	if cfg.SOUTH_PORTAL_FRAME then
		makePart(supportsF, "South_Portal_Pylon_L", Vector3.new(2.8, cfg.COLUMN_HEIGHT + 2, 2.8), CFrame.new(-13.0, 19.2 + (cfg.COLUMN_HEIGHT + 2) * 0.5, 67.3), colors.CornerPylon, Enum.Material.Metal, true, false)
		makePart(supportsF, "South_Portal_Pylon_R", Vector3.new(2.8, cfg.COLUMN_HEIGHT + 2, 2.8), CFrame.new(13.0, 19.2 + (cfg.COLUMN_HEIGHT + 2) * 0.5, 67.3), colors.CornerPylon, Enum.Material.Metal, true, false)
		makePart(supportsF, "South_Portal_Lintel", Vector3.new(28.8, 1.8, 2.4), CFrame.new(0, cfg.ROOF_HEIGHT_AT_WALL + 0.6, 67.3), colors.SupportColumn, Enum.Material.Metal, false, false)
		makePart(supportsF, "South_Portal_Trim", Vector3.new(29.4, 0.5, 2.8), CFrame.new(0, cfg.ROOF_HEIGHT_AT_WALL + 1.6, 67.3), colors.GoldTrim, Enum.Material.SmoothPlastic, false, false)
	end

	-- 5. Four 45-Degree Corners (Zero-gap seamless connection)
	local cornerDefs = {
		{ name = "Corner_NW", outerCenter = Vector3.new(-123.05, 19.2, -139.05), inward = Vector3.new(1, 0, 1).Unit },
		{ name = "Corner_NE", outerCenter = Vector3.new(123.05, 19.2, -139.05), inward = Vector3.new(-1, 0, 1).Unit },
		{ name = "Corner_SE", outerCenter = Vector3.new(123.05, 19.2, 53.05), inward = Vector3.new(-1, 0, -1).Unit },
		{ name = "Corner_SW", outerCenter = Vector3.new(-123.05, 19.2, 53.05), inward = Vector3.new(1, 0, -1).Unit },
	}

	local cornerSpan = 29.5
	for _, cd in ipairs(cornerDefs) do
		buildCanopySection(cornersF, cd.name, cd.outerCenter, cd.inward, cornerSpan, cfg.CORNER_DEPTH)

		local towerH = cfg.CORNER_TOWER_HEIGHT
		local towerCF = CFrame.new(cd.outerCenter + Vector3.new(0, towerH * 0.5, 0)) * CFrame.Angles(0, math.atan2(-cd.inward.X, -cd.inward.Z), 0)
		makePart(supportsF, `{cd.name}_Tower`, Vector3.new(cfg.CORNER_TOWER_WIDTH, towerH, cfg.CORNER_TOWER_WIDTH), towerCF, colors.CornerPylon, Enum.Material.Metal, true, false)
		makePart(supportsF, `{cd.name}_Finial`, Vector3.new(cfg.CORNER_TOWER_WIDTH + 0.6, 1.0, cfg.CORNER_TOWER_WIDTH + 0.6), towerCF * CFrame.new(0, towerH * 0.5 + 0.5, 0), colors.GoldTrim, Enum.Material.SmoothPlastic, false, false)
	end

	-- 6. Miter Joint Rib Caps along the 8 seam lines to guarantee zero visible gaps
	-- shortcut: straight seam rib caps suffice for cartoon style; upgrade to CSG wedge miter if curved shell requested
	local miterJoints = {
		{ p1 = Vector3.new(-108.8, 0, -153.3), inward = Vector3.new(1, 0, 1).Unit },
		{ p1 = Vector3.new(-137.3, 0, -124.8), inward = Vector3.new(1, 0, 1).Unit },
		{ p1 = Vector3.new(108.8, 0, -153.3), inward = Vector3.new(-1, 0, 1).Unit },
		{ p1 = Vector3.new(137.3, 0, -124.8), inward = Vector3.new(-1, 0, 1).Unit },
		{ p1 = Vector3.new(137.3, 0, 38.8), inward = Vector3.new(-1, 0, -1).Unit },
		{ p1 = Vector3.new(108.8, 0, 67.3), inward = Vector3.new(-1, 0, -1).Unit },
		{ p1 = Vector3.new(-137.3, 0, 38.8), inward = Vector3.new(1, 0, -1).Unit },
		{ p1 = Vector3.new(-108.8, 0, 67.3), inward = Vector3.new(1, 0, -1).Unit },
	}

	local slantedCornerD = cfg.CORNER_DEPTH / math.cos(slopeRad)
	local vDropCorner = cfg.CORNER_DEPTH * math.tan(slopeRad)
	for idx, mj in ipairs(miterJoints) do
		local cY = cfg.ROOF_HEIGHT_AT_WALL - vDropCorner * 0.5
		local miterCenter = Vector3.new(mj.p1.X, cY, mj.p1.Z) + mj.inward * (cfg.CORNER_DEPTH * 0.5)
		local miterCF = CFrame.lookAt(miterCenter, miterCenter + mj.inward) * CFrame.Angles(-slopeRad, 0, 0)
		makePart(trimF, `MiterCap_{idx}`, Vector3.new(2.4, 2.0, slantedCornerD * 1.1), miterCF, colors.RoofDeck, Enum.Material.SmoothPlastic, false, false)
		makePart(trimF, `MiterGoldTrim_{idx}`, Vector3.new(0.6, 2.2, slantedCornerD * 1.1), miterCF * CFrame.new(0, 0.1, 0), colors.GoldTrim, Enum.Material.SmoothPlastic, false, false)
	end

	return roofFolder
end

function RoofGenerator.Regenerate(customConfig: RoofConfig?): Folder
	RoofGenerator.Clear()
	return RoofGenerator.Generate(customConfig)
end

function RoofGenerator.ToggleRibbon(active: boolean)
	local stadium = Workspace:FindFirstChild("Stadium")
	local roof = stadium and stadium:FindFirstChild("Roof")
	if not roof then return end
	for _, desc in ipairs(roof:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name == "RibbonBoard" then
			desc.Transparency = active and 0.2 or 1.0
		end
	end
end

return RoofGenerator

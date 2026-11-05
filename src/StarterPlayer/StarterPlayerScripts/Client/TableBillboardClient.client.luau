--!strict
--[[
	TableBillboardClient (Client)
	Responsibility: Manages spectator table billboards, reactive attribute updates (InMatch, Occupancy,
	spectator turn/squares), 5 Hz screen-space anti-overlap fading/shrinking, and 14-stud hover banner.
	Loop step: social display | matchmaking clarity | spectator mode
	Location: StarterPlayer/StarterPlayerScripts/Client/TableBillboardClient.client.luau
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("TableBillboardConfig"))

type TableEntry = {
	model: Model,
	anchor: Attachment,
	billboard: BillboardGui,
	canvasGroup: CanvasGroup,
	idleView: Frame,
	matchView: Frame,
	hoverBanner: Frame,
	occupancyLabel: TextLabel,
	nameALabel: TextLabel,
	nameBLabel: TextLabel,
	turnLabel: TextLabel,
	squaresA: { Frame },
	squaresB: { Frame },
	arrowLabel: TextLabel,
}

local tablesByModel: { [Model]: TableEntry } = {}
local throttleAccumulator = 0
local checkInterval = 1 / Config.THROTTLE_RATE_HZ

-- Build the spectator BillboardGui for a table
local function buildTableBillboard(tableModel: Model, anchor: Attachment): TableEntry
	local existing = tableModel:FindFirstChild("TableStatusBillboard", true)
	if existing then
		existing:Destroy()
	end

	-- Hide old simple SignLabel if present so it doesn't duplicate
	local oldLabel = tableModel:FindFirstChild("SignLabel", true) :: TextLabel?
	if oldLabel then
		oldLabel.Visible = false
	end

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "TableStatusBillboard"
	bbg.Adornee = anchor
	bbg.Size = UDim2.fromScale(Config.BASE_SIZE.X, Config.BASE_SIZE.Y)
	bbg.SizeOffset = Vector2.new(0, 0)
	bbg.AlwaysOnTop = Config.ALWAYS_ON_TOP
	bbg.MaxDistance = Config.MAX_DISTANCE
	bbg.LightInfluence = Config.LIGHT_INFLUENCE

	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.Parent = bbg

	----------------------------------------------------------------------
	-- 1. IDLE / WAITING VIEW (Line 1: Default Mode, Line 2: 0/2, Line 3: $100)
	----------------------------------------------------------------------
	local idleView = Instance.new("Frame")
	idleView.Name = "IdleView"
	idleView.Size = UDim2.fromScale(1, 1)
	idleView.BackgroundTransparency = 1
	idleView.Parent = canvas

	local idleLayout = Instance.new("UIListLayout")
	idleLayout.SortOrder = Enum.SortOrder.LayoutOrder
	idleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	idleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	idleLayout.Padding = UDim.new(0, 1)
	idleLayout.Parent = idleView

	-- Line 1: Default Mode (Small, white, bold outline)
	local defaultModeLbl = Instance.new("TextLabel")
	defaultModeLbl.Name = "DefaultModeLabel"
	defaultModeLbl.LayoutOrder = 1
	defaultModeLbl.Size = UDim2.new(1, 0, 0.20, 0)
	defaultModeLbl.BackgroundTransparency = 1
	defaultModeLbl.Font = Enum.Font.FredokaOne
	defaultModeLbl.Text = "Default Mode"
	defaultModeLbl.TextColor3 = Config.COLORS.TitleWhite
	defaultModeLbl.TextScaled = true
	local stroke1 = Instance.new("UIStroke")
	stroke1.Thickness = 4
	stroke1.Color = Config.COLORS.StrokeBlack
	stroke1.Parent = defaultModeLbl
	defaultModeLbl.Parent = idleView

	-- Line 2: Occupancy (Large, white, thick outline)
	local occLbl = Instance.new("TextLabel")
	occLbl.Name = "OccupancyLabel"
	occLbl.LayoutOrder = 2
	occLbl.Size = UDim2.new(1, 0, 0.52, 0)
	occLbl.BackgroundTransparency = 1
	occLbl.Font = Enum.Font.FredokaOne
	occLbl.Text = "0/2"
	occLbl.TextColor3 = Config.COLORS.OccupancyWhite
	occLbl.TextScaled = true
	local stroke2 = Instance.new("UIStroke")
	stroke2.Thickness = 5
	stroke2.Color = Config.COLORS.StrokeBlack
	stroke2.Parent = occLbl
	occLbl.Parent = idleView

	-- Line 3: $100 (Green #3DDC3D, outlined)
	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name = "PriceLabel"
	priceLbl.LayoutOrder = 3
	priceLbl.Size = UDim2.new(1, 0, 0.24, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font = Enum.Font.FredokaOne
	priceLbl.Text = "$100"
	priceLbl.TextColor3 = Config.COLORS.PriceGreen
	priceLbl.TextScaled = true
	local stroke3 = Instance.new("UIStroke")
	stroke3.Thickness = 4
	stroke3.Color = Config.COLORS.StrokeBlack
	stroke3.Parent = priceLbl
	priceLbl.Parent = idleView

	----------------------------------------------------------------------
	-- 2. IN-MATCH SPECTATOR VIEW (<PlayerA> VS <PlayerB>, Turn X/6, 2x6 squares)
	----------------------------------------------------------------------
	local matchView = Instance.new("Frame")
	matchView.Name = "MatchView"
	matchView.Size = UDim2.fromScale(1, 1)
	matchView.BackgroundTransparency = 1
	matchView.Visible = false
	matchView.Parent = canvas

	local matchLayout = Instance.new("UIListLayout")
	matchLayout.SortOrder = Enum.SortOrder.LayoutOrder
	matchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	matchLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	matchLayout.Padding = UDim.new(0, 1)
	matchLayout.Parent = matchView

	-- Line 1: <PlayerA> VS <PlayerB>
	local vsFrame = Instance.new("Frame")
	vsFrame.Name = "VersusFrame"
	vsFrame.LayoutOrder = 1
	vsFrame.Size = UDim2.new(1, 0, 0.28, 0)
	vsFrame.BackgroundTransparency = 1
	vsFrame.Parent = matchView

	local vsLayout = Instance.new("UIListLayout")
	vsLayout.FillDirection = Enum.FillDirection.Horizontal
	vsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	vsLayout.Padding = UDim.new(0, 4)
	vsLayout.Parent = vsFrame

	local nameALbl = Instance.new("TextLabel")
	nameALbl.Name = "NameALabel"
	nameALbl.Size = UDim2.new(0.42, 0, 1, 0)
	nameALbl.BackgroundTransparency = 1
	nameALbl.Font = Enum.Font.FredokaOne
	nameALbl.Text = "Player"
	nameALbl.TextColor3 = Config.COLORS.PlayerABlue
	nameALbl.TextScaled = true
	local strokeA = Instance.new("UIStroke")
	strokeA.Thickness = 4
	strokeA.Color = Config.COLORS.StrokeBlack
	strokeA.Parent = nameALbl
	nameALbl.Parent = vsFrame

	local vsTag = Instance.new("TextLabel")
	vsTag.Name = "VsTag"
	vsTag.Size = UDim2.new(0.12, 0, 1, 0)
	vsTag.BackgroundTransparency = 1
	vsTag.Font = Enum.Font.FredokaOne
	vsTag.Text = "VS"
	vsTag.TextColor3 = Config.COLORS.VsOrange
	vsTag.TextScaled = true
	local strokeVS = Instance.new("UIStroke")
	strokeVS.Thickness = 4
	strokeVS.Color = Config.COLORS.StrokeBlack
	strokeVS.Parent = vsTag
	vsTag.Parent = vsFrame

	local nameBLbl = Instance.new("TextLabel")
	nameBLbl.Name = "NameBLabel"
	nameBLbl.Size = UDim2.new(0.42, 0, 1, 0)
	nameBLbl.BackgroundTransparency = 1
	nameBLbl.Font = Enum.Font.FredokaOne
	nameBLbl.Text = "BOT"
	nameBLbl.TextColor3 = Config.COLORS.PlayerBRed
	nameBLbl.TextScaled = true
	local strokeB = Instance.new("UIStroke")
	strokeB.Thickness = 4
	strokeB.Color = Config.COLORS.StrokeBlack
	strokeB.Parent = nameBLbl
	nameBLbl.Parent = vsFrame

	-- Line 2: Turn X/6
	local turnLbl = Instance.new("TextLabel")
	turnLbl.Name = "TurnLabel"
	turnLbl.LayoutOrder = 2
	turnLbl.Size = UDim2.new(1, 0, 0.22, 0)
	turnLbl.BackgroundTransparency = 1
	turnLbl.Font = Enum.Font.FredokaOne
	turnLbl.Text = "Turn 1/6"
	turnLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	turnLbl.TextScaled = true
	local strokeTurn = Instance.new("UIStroke")
	strokeTurn.Thickness = 4
	strokeTurn.Color = Config.COLORS.StrokeBlack
	strokeTurn.Parent = turnLbl
	turnLbl.Parent = matchView

	-- Line 3: Two rows of 6 small squares (Cards placed)
	local squaresContainer = Instance.new("Frame")
	squaresContainer.Name = "SquaresContainer"
	squaresContainer.LayoutOrder = 3
	squaresContainer.Size = UDim2.new(1, 0, 0.44, 0)
	squaresContainer.BackgroundTransparency = 1
	squaresContainer.Parent = matchView

	local sqList = Instance.new("UIListLayout")
	sqList.SortOrder = Enum.SortOrder.LayoutOrder
	sqList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sqList.VerticalAlignment = Enum.VerticalAlignment.Center
	sqList.Padding = UDim.new(0, 3)
	sqList.Parent = squaresContainer

	local function makeRow(name: string, layoutOrder: number): (Frame, { Frame })
		local row = Instance.new("Frame")
		row.Name = name
		row.LayoutOrder = layoutOrder
		row.Size = UDim2.new(0.85, 0, 0.45, 0)
		row.BackgroundTransparency = 1
		row.Parent = squaresContainer

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.Padding = UDim.new(0.02, 0)
		rowLayout.Parent = row

		local sqs: { Frame } = {}
		for i = 1, 6 do
			local sq = Instance.new("Frame")
			sq.Name = `Sq_{i}`
			sq.Size = UDim2.new(0.14, 0, 1, 0)
			sq.BackgroundColor3 = Config.COLORS.SquareEmpty
			sq.BorderSizePixel = 0

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.2, 0)
			corner.Parent = sq

			local sqStroke = Instance.new("UIStroke")
			sqStroke.Thickness = 2
			sqStroke.Color = Config.COLORS.StrokeBlack
			sqStroke.Parent = sq

			sq.Parent = row
			table.insert(sqs, sq)
		end
		return row, sqs
	end

	local _, sqsA = makeRow("RowA", 1)
	local _, sqsB = makeRow("RowB", 2)

	----------------------------------------------------------------------
	-- 3. HOVER HIGHLIGHT (SIT TO PLAY! + Bouncing Down-Arrow)
	----------------------------------------------------------------------
	local hoverBanner = Instance.new("Frame")
	hoverBanner.Name = "HoverBanner"
	hoverBanner.Size = UDim2.new(1.2, 0, 0.45, 0)
	hoverBanner.Position = UDim2.new(0.5, 0, -0.05, 0)
	hoverBanner.AnchorPoint = Vector2.new(0.5, 1)
	hoverBanner.BackgroundTransparency = 1
	hoverBanner.Visible = false
	hoverBanner.Parent = canvas

	local hoverLayout = Instance.new("UIListLayout")
	hoverLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hoverLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hoverLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hoverLayout.Padding = UDim.new(0, 0)
	hoverLayout.Parent = hoverBanner

	local sitLbl = Instance.new("TextLabel")
	sitLbl.Name = "SitLabel"
	sitLbl.LayoutOrder = 1
	sitLbl.Size = UDim2.new(1, 0, 0.55, 0)
	sitLbl.BackgroundTransparency = 1
	sitLbl.Font = Enum.Font.FredokaOne
	sitLbl.Text = "SIT TO PLAY!"
	sitLbl.TextColor3 = Config.COLORS.SitYellow
	sitLbl.TextScaled = true
	local strokeSit = Instance.new("UIStroke")
	strokeSit.Thickness = 4
	strokeSit.Color = Config.COLORS.StrokeBlack
	strokeSit.Parent = sitLbl
	sitLbl.Parent = hoverBanner

	local arrowLbl = Instance.new("TextLabel")
	arrowLbl.Name = "ArrowLabel"
	arrowLbl.LayoutOrder = 2
	arrowLbl.Size = UDim2.new(0.4, 0, 0.45, 0)
	arrowLbl.BackgroundTransparency = 1
	arrowLbl.Font = Enum.Font.FredokaOne
	arrowLbl.Text = "▼"
	arrowLbl.TextColor3 = Config.COLORS.SitYellow
	arrowLbl.TextScaled = true
	local strokeArrow = Instance.new("UIStroke")
	strokeArrow.Thickness = 4
	strokeArrow.Color = Config.COLORS.StrokeBlack
	strokeArrow.Parent = arrowLbl
	arrowLbl.Parent = hoverBanner

	bbg.Parent = anchor.Parent or tableModel

	local entry: TableEntry = {
		model = tableModel,
		anchor = anchor,
		billboard = bbg,
		canvasGroup = canvas,
		idleView = idleView,
		matchView = matchView,
		hoverBanner = hoverBanner,
		occupancyLabel = occLbl,
		nameALabel = nameALbl,
		nameBLabel = nameBLbl,
		turnLabel = turnLbl,
		squaresA = sqsA,
		squaresB = sqsB,
		arrowLabel = arrowLbl,
	}

	return entry
end

-- Refresh UI contents from table attributes
local function refreshTableFromAttributes(entry: TableEntry)
	local model = entry.model
	local inMatch = model:GetAttribute("InMatch") == true
	local occupancy = tonumber(model:GetAttribute("Occupancy")) or 0
	local playerA = tostring(model:GetAttribute("PlayerA") or "Player")
	local playerB = tostring(model:GetAttribute("PlayerB") or "BOT")
	local turn = tonumber(model:GetAttribute("Turn")) or 1
	local placedA = tonumber(model:GetAttribute("PlacedA")) or 0
	local placedB = tonumber(model:GetAttribute("PlacedB")) or 0

	entry.idleView.Visible = not inMatch
	entry.matchView.Visible = inMatch

	if not inMatch then
		entry.occupancyLabel.Text = `{occupancy}/2`
	else
		entry.nameALabel.Text = if #playerA > 0 then playerA else "Player"
		entry.nameBLabel.Text = if #playerB > 0 then playerB else "BOT"
		entry.turnLabel.Text = `Turn {math.clamp(turn, 1, 6)}/6`

		for i = 1, 6 do
			local sqA = entry.squaresA[i]
			if sqA then
				sqA.BackgroundColor3 = if i <= placedA then Config.COLORS.SquareFilledA else Config.COLORS.SquareEmpty
			end
			local sqB = entry.squaresB[i]
			if sqB then
				sqB.BackgroundColor3 = if i <= placedB then Config.COLORS.SquareFilledB else Config.COLORS.SquareEmpty
			end
		end
	end
end

-- Hook table attributes using GetAttributeChangedSignal
local function bindTable(tableModel: Model)
	if tablesByModel[tableModel] then
		return
	end

	local anchor = tableModel:FindFirstChild("BillboardAnchor", true) :: Attachment?
	if not anchor then
		-- Fallback: locate table top or primary part and attach anchor at 7 studs height
		local top = tableModel:FindFirstChild("TableTop") or tableModel.PrimaryPart or tableModel:FindFirstChildWhichIsA("BasePart")
		if top and top:IsA("BasePart") then
			anchor = Instance.new("Attachment")
			anchor.Name = "BillboardAnchor"
			anchor.Position = Vector3.new(0, 6.2, 0)
			anchor.Parent = top
		end
	end

	if not anchor then
		return
	end

	local entry = buildTableBillboard(tableModel, anchor)
	tablesByModel[tableModel] = entry
	refreshTableFromAttributes(entry)

	-- Attribute listeners
	for _, attrName in { "InMatch", "Occupancy", "PlayerA", "PlayerB", "Turn", "PlacedA", "PlacedB" } do
		tableModel:GetAttributeChangedSignal(attrName):Connect(function()
			refreshTableFromAttributes(entry)
		end)
	end
end

-- Initialize tables in Workspace
local function initTables()
	local lobby = Workspace:WaitForChild("Lobby", 5)
	local tablesFolder = (lobby and lobby:WaitForChild("Tables", 5)) or Workspace:WaitForChild("Tables", 10)
	if tablesFolder then
		for _, child in ipairs(tablesFolder:GetChildren()) do
			if child:IsA("Model") then
				bindTable(child)
			end
		end
		tablesFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				task.defer(bindTable, child)
			end
		end)
	end
end

----------------------------------------------------------------------
-- 4. ANTI-OVERLAP & DISTANCE LOGIC (Throttled to 5 Hz on RenderStepped)
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local char = localPlayer.Character
	local charPos = if char and char.PrimaryPart then char.PrimaryPart.Position else camera.CFrame.Position
	local now = os.clock()
	local bounceY = math.sin(now * Config.BOUNCE_SPEED) * Config.BOUNCE_AMPLITUDE_PX

	-- Update bouncing arrow for any active hover banner
	for _, entry in pairs(tablesByModel) do
		if entry.hoverBanner.Visible then
			entry.arrowLabel.Position = UDim2.new(0.3, 0, 0.45, bounceY)
		end
	end

	throttleAccumulator += dt
	if throttleAccumulator < checkInterval then
		return
	end
	throttleAccumulator = 0

	local viewportSize = camera.ViewportSize
	local vh = viewportSize.Y
	local fovRad = math.rad(camera.FieldOfView)
	local fovFactor = vh / (2 * math.tan(fovRad / 2))

	type ScreenItem = {
		entry: TableEntry,
		distToCam: number,
		distToPlayer: number,
		screenPos: Vector3,
		rect: Rect,
	}

	local candidates: { ScreenItem } = {}

	for _, entry in pairs(tablesByModel) do
		local anchor = entry.anchor
		if not anchor or not anchor.Parent then
			entry.billboard.Enabled = false
			continue
		end

		local worldPos = anchor.WorldPosition
		local distToCam = (camera.CFrame.Position - worldPos).Magnitude
		local distToPlayer = (charPos - worldPos).Magnitude

		if distToCam > Config.MAX_DISTANCE or distToPlayer > Config.MAX_DISTANCE then
			entry.billboard.Enabled = false
			continue
		end

		local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
		if not onScreen or screenPos.Z <= 0 then
			entry.billboard.Enabled = false
			continue
		end

		local projScale = fovFactor / math.max(1, distToCam)
		local wPx = Config.BASE_SIZE.X * projScale
		local hPx = Config.BASE_SIZE.Y * projScale
		local minX = screenPos.X - (wPx / 2)
		local maxX = screenPos.X + (wPx / 2)
		local minY = screenPos.Y - (hPx / 2)
		local maxY = screenPos.Y + (hPx / 2)

		table.insert(candidates, {
			entry = entry,
			distToCam = distToCam,
			distToPlayer = distToPlayer,
			screenPos = screenPos,
			rect = Rect.new(minX, minY, maxX, maxY),
		})
	end

	-- Sort by camera distance ascending (nearest first)
	table.sort(candidates, function(a, b)
		return a.distToCam < b.distToCam
	end)

	-- Disable billboards beyond the top 10 nearest
	for idx = Config.MAX_SIMULTANEOUS_BILLBOARDS + 1, #candidates do
		candidates[idx].entry.billboard.Enabled = false
	end

	local activeLimit = math.min(#candidates, Config.MAX_SIMULTANEOUS_BILLBOARDS)
	local overlappingFlags: { [number]: boolean } = {}

	-- Detect 2D screen-space rectangle overlap
	for j = 2, activeLimit do
		local rectJ = candidates[j].rect
		for i = 1, j - 1 do
			local rectI = candidates[i].rect
			-- Check rectangle intersection
			local intersects = not (
				rectJ.Max.X < rectI.Min.X or
				rectJ.Min.X > rectI.Max.X or
				rectJ.Max.Y < rectI.Min.Y or
				rectJ.Min.Y > rectI.Max.Y
			)
			if intersects then
				overlappingFlags[j] = true
				break
			end
		end
	end

	-- Apply scale, opacity, and hover states
	for idx = 1, activeLimit do
		local item = candidates[idx]
		local entry = item.entry
		local isOverlapping = overlappingFlags[idx] == true
		local isNearHover = item.distToPlayer <= Config.HOVER_DISTANCE and not (entry.model:GetAttribute("InMatch") == true)

		local scale = 1.0
		local transparency = 0.0

		if isOverlapping then
			scale *= Config.OVERLAP_SHRINK_FACTOR
			transparency = Config.OVERLAP_TRANSPARENCY
		end

		if isNearHover then
			scale *= Config.HOVER_GROW_FACTOR
			entry.hoverBanner.Visible = true
		else
			entry.hoverBanner.Visible = false
		end

		entry.canvasGroup.GroupTransparency = transparency
		entry.billboard.Size = UDim2.fromScale(Config.BASE_SIZE.X * scale, Config.BASE_SIZE.Y * scale)
		entry.billboard.Enabled = true
	end
end)

initTables()

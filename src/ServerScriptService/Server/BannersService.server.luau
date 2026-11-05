--!strict
--[[
	BannersService (Server)
	Responsibility: Manages stadium banners, perimeter fence ads, flags, and bunting:
	- Builds Workspace.Lobby.Decor.Banners hierarchy
	- 24 perimeter fence ad boards (14x3 studs) along North & South touchlines
	- 2 main hanging banners (40x10 studs) "BUILD A FOOTBALLER"
	- 30 abstract patterned flags along stand rim with wind sway mounts
	- 4 pitch corner flags (red/yellow triangles)
	- Walkway entrance bunting string
	Loop step: live lobby atmosphere | visual immersion | stadium identity
	Location: ServerScriptService/Server/BannersService.server.luau
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BannersConfig = require(Shared:WaitForChild("BannersConfig"))

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material,
	transparency: number,
	canCollide: boolean
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Transparency = transparency or 0
	p.CanCollide = canCollide
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function buildBannersAndAds()
	local lobby = Workspace:WaitForChild("Lobby", 10)
	if not lobby then return end

	local decor = lobby:FindFirstChild("Decor")
	if not decor then
		decor = Instance.new("Folder")
		decor.Name = "Decor"
		decor.Parent = lobby
	end

	local existing = decor:FindFirstChild("Banners")
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = "Banners"

	-- 1. Perimeter Fence Ad Boards (Disabled per user request)
	local adBoardsFolder = Instance.new("Folder")
	adBoardsFolder.Name = "AdBoards"
	adBoardsFolder.Parent = model

	local SPAWN_PERIMETER_ADS = false
	if SPAWN_PERIMETER_ADS then
		local xStart = -70.0
		local xStep = 12.8

		for i = 1, 12 do
			local xPos = xStart + (i - 1) * xStep
			local adDefNorth = BannersConfig.ADS[((i - 1) % #BannersConfig.ADS) + 1]
			local adDefSouth = BannersConfig.ADS[((i + 3) % #BannersConfig.ADS) + 1]

			-- North fence ad board (facing South, +Z)
			local boardN = makePart(adBoardsFolder, `AdBoard_N_{i}`, BannersConfig.AD_BOARD_SIZE, CFrame.new(xPos, BannersConfig.AD_ELEVATION_Y, -84.0), adDefNorth.bgColor, Enum.Material.SmoothPlastic, 0, false)
			local sgN = Instance.new("SurfaceGui")
			sgN.Name = "AdGui"
			sgN.Face = Enum.NormalId.Back
			sgN.CanvasSize = Vector2.new(700, 150)
			sgN.LightInfluence = 0
			sgN.AlwaysOnTop = false
			sgN.Parent = boardN

			local lblN = Instance.new("TextLabel")
			lblN.Name = "TitleLabel"
			lblN.Size = UDim2.fromScale(1, 0.65)
			lblN.BackgroundTransparency = 1
			lblN.Text = adDefNorth.title
			lblN.TextColor3 = adDefNorth.textColor
			lblN.Font = Enum.Font.FredokaOne
			lblN.TextScaled = true
			local strN = Instance.new("UIStroke")
			strN.Thickness = 3
			strN.Color = Color3.new(0, 0, 0)
			strN.Parent = lblN
			lblN.Parent = sgN

			local subN = Instance.new("TextLabel")
			subN.Name = "TaglineLabel"
			subN.Size = UDim2.fromScale(1, 0.35)
			subN.Position = UDim2.fromScale(0, 0.65)
			subN.BackgroundTransparency = 1
			subN.Text = adDefNorth.tagline
			subN.TextColor3 = Color3.new(1, 1, 1)
			subN.Font = Enum.Font.FredokaOne
			subN.TextScaled = true
			subN.Parent = sgN

			-- South fence ad board (facing North, -Z)
			local boardS = makePart(adBoardsFolder, `AdBoard_S_{i}`, BannersConfig.AD_BOARD_SIZE, CFrame.new(xPos, BannersConfig.AD_ELEVATION_Y, -0.5), adDefSouth.bgColor, Enum.Material.SmoothPlastic, 0, false)
			local sgS = Instance.new("SurfaceGui")
			sgS.Name = "AdGui"
			sgS.Face = Enum.NormalId.Front
			sgS.CanvasSize = Vector2.new(700, 150)
			sgS.LightInfluence = 0
			sgS.AlwaysOnTop = false
			sgS.Parent = boardS

			local lblS = Instance.new("TextLabel")
			lblS.Name = "TitleLabel"
			lblS.Size = UDim2.fromScale(1, 0.65)
			lblS.BackgroundTransparency = 1
			lblS.Text = adDefSouth.title
			lblS.TextColor3 = adDefSouth.textColor
			lblS.Font = Enum.Font.FredokaOne
			lblS.TextScaled = true
			local strS = Instance.new("UIStroke")
			strS.Thickness = 3
			strS.Color = Color3.new(0, 0, 0)
			strS.Parent = lblS
			lblS.Parent = sgS

			local subS = Instance.new("TextLabel")
			subS.Name = "TaglineLabel"
			subS.Size = UDim2.fromScale(1, 0.35)
			subS.Position = UDim2.fromScale(0, 0.65)
			subS.BackgroundTransparency = 1
			subS.Text = adDefSouth.tagline
			subS.TextColor3 = Color3.new(1, 1, 1)
			subS.Font = Enum.Font.FredokaOne
			subS.TextScaled = true
			subS.Parent = sgS
		end
	end

	-- 2. 2 Main Banners: 40x10 studs each at top of East and West stands
	local function makeMainBanner(name: string, cf: CFrame, face: Enum.NormalId)
		local banner = makePart(model, name, BannersConfig.MAIN_BANNER_SIZE, cf, Color3.fromHex("#12162B"), Enum.Material.SmoothPlastic, 0, false)
		local sg = Instance.new("SurfaceGui")
		sg.Name = "MainBannerGui"
		sg.Face = face
		sg.CanvasSize = Vector2.new(1600, 400)
		sg.LightInfluence = 0
		sg.AlwaysOnTop = false
		sg.Parent = banner

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Text = BannersConfig.MAIN_BANNER_TEXT
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextScaled = true
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 8
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Parent = lbl

		-- Gold glow stroke
		local glow = Instance.new("UIStroke")
		glow.Thickness = 14
		glow.Color = Color3.fromHex("#FFD21F")
		glow.Transparency = 0.3
		glow.Parent = lbl

		lbl.Parent = sg
		return banner
	end

	-- West Stand Main Banner (facing East, +X)
	makeMainBanner("MainBanner_West", CFrame.new(-114.0, 16.5, -43.0), Enum.NormalId.Right)
	-- East Stand Main Banner (facing West, -X)
	makeMainBanner("MainBanner_East", CFrame.new(114.0, 16.5, -43.0), Enum.NormalId.Left)

	-- 3. Stand Rim Flags (Disabled per user request)
	if BannersConfig.FLAGS_COUNT > 0 then
		local flagsFolder = Instance.new("Folder")
		flagsFolder.Name = "Flags"
		flagsFolder.Parent = model

		local flagColors = {
			Color3.fromHex("#1E6FFF"), Color3.fromHex("#E5252A"), Color3.fromHex("#FFD21F"),
			Color3.fromHex("#22C55E"), Color3.fromHex("#A855F7"), Color3.fromHex("#F97316"),
			Color3.fromHex("#06B6D4"), Color3.fromHex("#EC4899"),
		}

		for i = 1, BannersConfig.FLAGS_COUNT do
			local angle = (i / BannersConfig.FLAGS_COUNT) * math.pi * 2
			local rX = 115.0 * math.cos(angle)
			local rZ = -43.0 + 115.0 * math.sin(angle)
			local poleCf = CFrame.new(rX, 12.0, rZ)

			-- Pole
			makePart(flagsFolder, `FlagPole_{i}`, Vector3.new(0.3, BannersConfig.CORNER_FLAG_POLE_HEIGHT, 0.3), poleCf + Vector3.new(0, 2.5, 0), Color3.fromHex("#94A3B8"), Enum.Material.SmoothPlastic, 0, false)
			
			-- Cloth part (swayed by client script)
			local clothCol = flagColors[((i - 1) % #flagColors) + 1]
			local cloth = makePart(flagsFolder, `FlagCloth_{i}`, Vector3.new(2.8, 1.8, 0.1), poleCf + Vector3.new(1.4, 4.0, 0), clothCol, Enum.Material.SmoothPlastic, 0, false)
			cloth:SetAttribute("BaseCFrame", cloth.CFrame)
			cloth:SetAttribute("Phase", (i / BannersConfig.FLAGS_COUNT) * math.pi * 2)
		end
	end

	-- 4. 4 Pitch Corner Flags (Disabled per user request)
	local SPAWN_CORNER_FLAGS = false
	if SPAWN_CORNER_FLAGS then
		local cornerCoords = {
			Vector3.new(-78.0, 0.1, -84.0),
			Vector3.new(78.0, 0.1, -84.0),
			Vector3.new(-78.0, 0.1, 0.0),
			Vector3.new(78.0, 0.1, 0.0),
		}

		for i, cPos in ipairs(cornerCoords) do
			local pole = makePart(model, `CornerFlagPole_{i}`, Vector3.new(0.2, 3.2, 0.2), CFrame.new(cPos + Vector3.new(0, 1.6, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0, false)
			local flagCloth = makePart(model, `CornerFlagCloth_{i}`, Vector3.new(1.2, 0.9, 0.08), CFrame.new(cPos + Vector3.new(0.6, 2.7, 0)), if i % 2 == 1 then Color3.fromHex("#EF4444") else Color3.fromHex("#FACC15"), Enum.Material.SmoothPlastic, 0, false)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Wedge
			mesh.Parent = flagCloth
		end
	end

	-- 5. Walkway Entrance Bunting String (Disabled per user request)
	local SPAWN_BUNTING = false
	if SPAWN_BUNTING then
		local buntingFolder = Instance.new("Folder")
		buntingFolder.Name = "Bunting"
		buntingFolder.Parent = model

		local buntingColors = { Color3.fromHex("#EF4444"), Color3.fromHex("#3B82F6"), Color3.fromHex("#EAB308"), Color3.fromHex("#22C55E"), Color3.fromHex("#A855F7") }
		for b = 1, 15 do
			local xPos = -7.0 + (b - 1) * 1.0
			local sag = math.sin((b / 15) * math.pi) * 0.8
			local tri = makePart(buntingFolder, `Bunting_{b}`, Vector3.new(0.8, 1.0, 0.05), CFrame.new(xPos, 8.5 - sag, 24.0), buntingColors[((b - 1) % #buntingColors) + 1], Enum.Material.SmoothPlastic, 0, false)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Wedge
			mesh.Parent = tri
		end
	end

	model.Parent = decor
end

task.defer(buildBannersAndAds)

--!strict
--[[
	PlayerTunnelService (Server)
	Responsibility: Constructs the South End Player Tunnel (Workspace/Lobby/Tunnel), spawns,
	lit arch sign, interior lighting, light-beam effect, and floor chevron arrow chain.
	Loop step: arrival | onboarding | social lobby
	Location: ServerScriptService/Server/PlayerTunnelService.server.luau
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("PlayerTunnelConfig"))

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material,
	canCollide: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Anchored = true
	p.CanCollide = canCollide == true
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function buildPlayerTunnel(): Folder
	local lobby = Workspace:WaitForChild("Lobby", 10) or Workspace
	local existing = lobby:FindFirstChild("Tunnel")
	if existing then
		existing:Destroy()
	end

	local tunnel = Instance.new("Folder")
	tunnel.Name = "Tunnel"

	local x0 = Config.TUNNEL_CENTER_X
	local zEntrance = Config.TUNNEL_ENTRANCE_Z
	local depth = Config.TUNNEL_DEPTH
	local zCenter = zEntrance + (depth / 2)
	local w = Config.OPENING_WIDTH
	local h = Config.OPENING_HEIGHT

	local darkInterior = Color3.fromRGB(24, 26, 32)
	local archGrey = Color3.fromRGB(180, 185, 195)
	local signBgCol = Color3.fromRGB(36, 40, 50)
	local walkwayCol = Color3.fromRGB(152, 158, 168)

	----------------------------------------------------------------------
	-- 1. TUNNEL SHELL (Left, Right, Roof, Back, Floor)
	----------------------------------------------------------------------
	local shell = Instance.new("Model")
	shell.Name = "TunnelShell"

	-- Left Wall (X = -8.5)
	makePart(shell, "WallLeft", Vector3.new(1.0, h, depth), CFrame.new(x0 - (w / 2) - 0.5, h / 2, zCenter), darkInterior, Enum.Material.SmoothPlastic, true)
	-- Right Wall (X = +8.5)
	makePart(shell, "WallRight", Vector3.new(1.0, h, depth), CFrame.new(x0 + (w / 2) + 0.5, h / 2, zCenter), darkInterior, Enum.Material.SmoothPlastic, true)
	-- Roof
	makePart(shell, "Roof", Vector3.new(w + 2.0, 1.0, depth), CFrame.new(x0, h + 0.5, zCenter), darkInterior, Enum.Material.SmoothPlastic, true)
	-- Back Wall
	makePart(shell, "WallBack", Vector3.new(w + 2.0, h, 1.0), CFrame.new(x0, h / 2, zEntrance + depth + 0.5), darkInterior, Enum.Material.SmoothPlastic, true)
	-- Floor (Walkway extension)
	makePart(shell, "Floor", Vector3.new(w, 0.25, depth), CFrame.new(x0, 0.12, zCenter), walkwayCol, Enum.Material.Concrete, true)

	shell.Parent = tunnel

	----------------------------------------------------------------------
	-- 2. ARCH FRAME & LIT SIGN (Disabled per user request)
	----------------------------------------------------------------------
	local SPAWN_ARCH_PORTAL = false
	if SPAWN_ARCH_PORTAL then
		local arch = Instance.new("Model")
		arch.Name = "ArchPortal"

		-- Left and Right Arch Pillars
		makePart(arch, "PillarLeft", Vector3.new(1.6, h + 0.6, 1.6), CFrame.new(x0 - (w / 2) - 0.8, (h + 0.6) / 2, zEntrance - 0.6), archGrey, Enum.Material.Concrete, true)
		makePart(arch, "PillarRight", Vector3.new(1.6, h + 0.6, 1.6), CFrame.new(x0 + (w / 2) + 0.8, (h + 0.6) / 2, zEntrance - 0.6), archGrey, Enum.Material.Concrete, true)
		-- Arch Top Beam
		makePart(arch, "BeamHeader", Vector3.new(w + 3.2, 1.8, 1.8), CFrame.new(x0, h + 0.9, zEntrance - 0.6), archGrey, Enum.Material.Concrete, true)

		-- Lit Sign Board
		local signBoard = makePart(arch, "SignBoard", Vector3.new(15.0, 2.2, 0.25), CFrame.new(x0, h + 2.5, zEntrance - 0.8), signBgCol, Enum.Material.SmoothPlastic, true)
		local signBorder = makePart(arch, "SignTrim", Vector3.new(15.6, 2.6, 0.25), CFrame.new(x0, h + 2.5, zEntrance - 0.4), Color3.fromRGB(255, 215, 0), Enum.Material.SmoothPlastic, false)

		local sGui = Instance.new("SurfaceGui")
		sGui.Name = "EntranceSignGui"
		sGui.Face = Enum.NormalId.Front
		sGui.LightInfluence = 0
		sGui.AlwaysOnTop = false
		sGui.ZOffset = 1

		local signLbl = Instance.new("TextLabel")
		signLbl.Name = "SignLabel"
		signLbl.Size = UDim2.fromScale(1, 1)
		signLbl.BackgroundTransparency = 1
		signLbl.Font = Enum.Font.FredokaOne
		signLbl.Text = "PLAYERS ENTRANCE"
		signLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		signLbl.TextScaled = true

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Parent = signLbl
		signLbl.Parent = sGui
		sGui.Parent = signBoard

		arch.Parent = tunnel
	end

	----------------------------------------------------------------------
	-- 3. INTERIOR WARM POINTLIGHTS (2 lights)
	----------------------------------------------------------------------
	local lightsFolder = Instance.new("Folder")
	lightsFolder.Name = "Lights"

	local function addTunnelLight(name: string, pos: Vector3)
		local lampFixture = makePart(lightsFolder, name, Vector3.new(0.8, 0.3, 0.8), CFrame.new(pos), Color3.fromRGB(50, 52, 60), Enum.Material.Metal, false)
		local pLight = Instance.new("PointLight")
		pLight.Name = "PointLight"
		pLight.Brightness = Config.LIGHT_BRIGHTNESS
		pLight.Range = Config.LIGHT_RANGE
		pLight.Color = Config.LIGHT_COLOR
		pLight.Shadows = true
		pLight.Parent = lampFixture
	end

	addTunnelLight("Lamp_1", Vector3.new(x0, h - 0.3, zEntrance + 8.0))
	addTunnelLight("Lamp_2", Vector3.new(x0, h - 0.3, zEntrance + 18.0))
	lightsFolder.Parent = tunnel

	----------------------------------------------------------------------
	-- 4. 8 SPAWN LOCATIONS (Row facing North along pitch long axis)
	----------------------------------------------------------------------
	local spawnsFolder = Instance.new("Folder")
	spawnsFolder.Name = "Spawns"

	local count = Config.SPAWN_COUNT
	local spacing = Config.SPAWN_SPACING_X
	local zSpawn = Config.SPAWN_DEPTH_Z

	for i = 1, count do
		local xPos = (i - ((count + 1) / 2)) * spacing
		local spawnPos = Vector3.new(xPos, 0.5, zSpawn)
		-- Orient to face pitch center (Z = -42, looking towards negative Z)
		local lookTarget = Vector3.new(xPos, 0.5, -42.0)
		local spawnCF = CFrame.lookAt(spawnPos, lookTarget)

		local sp = Instance.new("SpawnLocation")
		sp.Name = `TunnelSpawn_{i}`
		sp.Size = Vector3.new(1.8, 0.2, 1.8)
		sp.CFrame = spawnCF
		sp.Transparency = 1
		sp.CanCollide = false
		sp.CanTouch = false
		sp.CanQuery = false
		sp.Neutral = true
		sp.Duration = Config.SPAWN_FORCEFIELD_DURATION
		sp.Enabled = true

		local decal = sp:FindFirstChildOfClass("Decal")
		if decal then
			decal:Destroy()
		end

		sp.Parent = spawnsFolder
	end
	spawnsFolder.Parent = tunnel

	----------------------------------------------------------------------
	-- 6. FLOOR DECAL ARROW CHAIN (3 Yellow Chevrons leading to Walkway)
	----------------------------------------------------------------------
	local arrowsFolder = Instance.new("Folder")
	arrowsFolder.Name = "ChevronArrows"

	local chevronZOffsets = { 22.0, 16.0, 10.0 }
	local yellowCol = Color3.fromHex("#FFD21F")

	for idx, zPos in ipairs(chevronZOffsets) do
		local arrowPart = makePart(
			arrowsFolder,
			`Chevron_{idx}`,
			Vector3.new(3.5, 0.04, 2.0),
			CFrame.new(x0, 0.26, zPos),
			yellowCol,
			Enum.Material.SmoothPlastic,
			false
		)
		arrowPart.CastShadow = false

		local arrowDecal = Instance.new("Decal")
		arrowDecal.Name = `DEC_ChevronArrow_{idx}`
		arrowDecal.Face = Enum.NormalId.Top
		arrowDecal.Texture = "rbxassetid://0"
		arrowDecal.Parent = arrowPart
	end
	arrowsFolder.Parent = tunnel

	tunnel.Parent = lobby

	-- Disable default SpawnLocation elsewhere as confirmed
	local defaultSpawn = Workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
	if defaultSpawn then
		defaultSpawn.Enabled = false
	end

	return tunnel
end

local function init()
	buildPlayerTunnel()

	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Lobby" then
			task.defer(buildPlayerTunnel)
		end
	end)
end

init()

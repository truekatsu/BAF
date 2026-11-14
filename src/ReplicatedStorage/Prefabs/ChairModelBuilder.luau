--!strict
--[[
	ChairModelBuilder
	Responsibility: Constructs 3D stylized chair models.
	Includes:
	- Stadium Blue chair (procedural Lego aesthetic with 2x2 stud base plate and ribs)
	- Cyber Core Chair (3D Mesh with PBR SurfaceAppearance, dual glow, cyber data sparks)
	- Crimson Chair (3D Mesh with PBR SurfaceAppearance, flame aura, rising fire and embers)
	- Frostbite Chair (3D Mesh with PBR SurfaceAppearance, cold glow, frost mist particles)
	- Football Throne (3D Mesh with PBR SurfaceAppearance, golden royal sparkles and glow)
	Location: ReplicatedStorage/Prefabs/ChairModelBuilder.luau
]]

local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChairModelBuilder = {}

local MESH_TEMPLATE_CACHE: { [string]: MeshPart } = {}

local function getMeshPart(meshId: string): MeshPart
	local cached = MESH_TEMPLATE_CACHE[meshId]
	if cached then
		return cached:Clone()
	end

	local prefabs = ReplicatedStorage:FindFirstChild("Prefabs")
	local cmFolder = prefabs and prefabs:FindFirstChild("ChairModels")
	if cmFolder then
		for _, child in cmFolder:GetChildren() do
			if child:IsA("MeshPart") and child.MeshId == meshId then
				MESH_TEMPLATE_CACHE[meshId] = child
				return child:Clone()
			end
		end
	end

	local ok, mp = pcall(function()
		return InsertService:CreateMeshPartAsync(meshId, Enum.CollisionFidelity.Default, Enum.RenderFidelity.Precise)
	end)
	if ok and mp and mp:IsA("MeshPart") then
		MESH_TEMPLATE_CACHE[meshId] = mp
		return mp:Clone()
	end

	local fallback = Instance.new("Part")
	local sm = Instance.new("SpecialMesh")
	sm.MeshType = Enum.MeshType.FileMesh
	sm.MeshId = meshId
	sm.Parent = fallback
	return fallback :: any
end

-- Palette tokens matching reference sheet
local COLORS = {
	BlueMain = Color3.fromHex("#1E6FFF"),
	BlueShadow = Color3.fromHex("#1555C5"),
	BlueRib = Color3.fromHex("#2879FF"),
	DarkBase = Color3.fromHex("#242C38"),
	DarkStud = Color3.fromHex("#2B3442"),
}

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	p.Parent = parent
	return p
end

local function makeCylinder(parent: Instance, name: string, length: number, radius: number, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, radius * 2, radius * 2)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	p.Parent = parent
	return p
end

-- Constructs the Lego Stadium Chair model (scaled for 3D UI viewports and game display)
function ChairModelBuilder.buildStadiumChair(cfOffset: CFrame?): Model
	local model = Instance.new("Model")
	model.Name = "Chair_stadium"

	local cfBase = cfOffset or CFrame.identity

	-- 1. Base Plate (2x2 Lego plate, dark slate gray)
	makePart(model, "BasePlate", Vector3.new(1.40, 0.28, 1.40), cfBase * CFrame.new(0, 0.24, -0.05), COLORS.DarkBase)

	-- 2. 4 Base Studs (prominent Lego studs)
	local sDist = 0.38
	makeCylinder(model, "Stud_FL", 0.12, 0.17, cfBase * CFrame.new(-sDist, 0.44, -0.05 + sDist), COLORS.DarkStud)
	makeCylinder(model, "Stud_FR", 0.12, 0.17, cfBase * CFrame.new( sDist, 0.44, -0.05 + sDist), COLORS.DarkStud)
	makeCylinder(model, "Stud_BL", 0.12, 0.17, cfBase * CFrame.new(-sDist, 0.44, -0.05 - sDist), COLORS.DarkStud)
	makeCylinder(model, "Stud_BR", 0.12, 0.17, cfBase * CFrame.new( sDist, 0.44, -0.05 - sDist), COLORS.DarkStud)

	-- 3. Center Pedestal Post (Dark square column connecting base to seat)
	makePart(model, "CenterPost", Vector3.new(0.48, 0.48, 0.48), cfBase * CFrame.new(0, 0.62, -0.05), COLORS.DarkBase)

	-- 4. Seat Lower Plate (Spans underside from front to back of backrest)
	makePart(model, "SeatBase", Vector3.new(1.62, 0.18, 1.60), cfBase * CFrame.new(0, 0.95, -0.05), COLORS.BlueMain)

	-- 5. Seat Front Cushion (Stepped Lego tile on top of seat base)
	local seatCushion = makePart(model, "SeatCushion", Vector3.new(1.58, 0.22, 1.15), cfBase * CFrame.new(0, 1.15, 0.18), COLORS.BlueMain)
	model.PrimaryPart = seatCushion

	-- 6. Backrest Main Slab (Square backrest, tilted back 8.5 deg)
	local backTiltAngle = math.rad(-8.5)
	local backrestCF = cfBase * CFrame.new(0, 1.82, -0.42) * CFrame.Angles(backTiltAngle, 0, 0)
	makePart(model, "BackrestSlab", Vector3.new(1.62, 1.52, 0.26), backrestCF, COLORS.BlueMain)

	-- 7. Backrest Front Ribs (Two vertical raised stadium ribs + shadow backing)
	makePart(model, "RibBacking", Vector3.new(1.36, 1.30, 0.02), backrestCF * CFrame.new(0, 0, 0.13), COLORS.BlueShadow)
	local ribLeftCF = backrestCF * CFrame.new(-0.36, 0, 0.16)
	local ribRightCF = backrestCF * CFrame.new(0.36, 0, 0.16)
	makePart(model, "RibLeft", Vector3.new(0.32, 1.26, 0.06), ribLeftCF, COLORS.BlueRib)
	makePart(model, "RibRight", Vector3.new(0.32, 1.26, 0.06), ribRightCF, COLORS.BlueRib)

	-- 8. Backrest Rear Rim / Recessed Panel Detail
	makePart(model, "BackRimTop", Vector3.new(1.62, 0.12, 0.04), backrestCF * CFrame.new(0, 0.70, -0.15), COLORS.BlueMain)
	makePart(model, "BackRimBottom", Vector3.new(1.62, 0.12, 0.04), backrestCF * CFrame.new(0, -0.70, -0.15), COLORS.BlueMain)
	makePart(model, "BackRimLeft", Vector3.new(0.12, 1.28, 0.04), backrestCF * CFrame.new(-0.75, 0, -0.15), COLORS.BlueMain)
	makePart(model, "BackRimRight", Vector3.new(0.12, 1.28, 0.04), backrestCF * CFrame.new(0.75, 0, -0.15), COLORS.BlueMain)
	makePart(model, "BackRecess", Vector3.new(1.38, 1.28, 0.02), backrestCF * CFrame.new(0, 0, -0.13), COLORS.BlueShadow)

	return model
end

-- Constructs the Classic Wood Chair model
function ChairModelBuilder.buildWoodChair(cfOffset: CFrame?): Model
	local model = Instance.new("Model")
	model.Name = "Chair_wood"

	local cfBase = cfOffset or CFrame.identity
	local woodColor = Color3.fromRGB(124, 71, 40)
	local darkWood = Color3.fromRGB(95, 52, 28)

	local seat = makePart(model, "Seat", Vector3.new(1.6, 0.28, 1.5), cfBase * CFrame.new(0, 0.8, 0), woodColor, Enum.Material.WoodPlanks)
	model.PrimaryPart = seat
	makePart(model, "Back", Vector3.new(1.6, 1.45, 0.28), cfBase * CFrame.new(0, 1.62, -0.62), woodColor, Enum.Material.WoodPlanks)
	makeCylinder(model, "TopCap", 1.6, 0.14, cfBase * CFrame.new(0, 2.34, -0.62), woodColor)

	for _, lx in { -0.60, 0.60 } do
		for _, lz in { -0.55, 0.55 } do
			makePart(model, "Leg", Vector3.new(0.20, 0.8, 0.20), cfBase * CFrame.new(lx, 0.4, lz), darkWood, Enum.Material.Wood)
		end
	end

	return model
end

-- ============================================================================
-- 3D MESH DEFINITIONS & PBR ASSETS
-- ============================================================================
type MeshConfig = {
	name: string,
	meshId: string,
	size: Vector3,
	seatYOffset: number,
	seatSize: Vector3,
	textures: {
		color: string,
		normal: string,
		roughness: string,
		metalness: string,
	},
	setupEffects: (model: Model, mesh: MeshPart) -> (),
}

local MESH_CONFIGS: { [string]: MeshConfig } = {
	cyber_core = {
		name = "CyberCoreChair",
		meshId = "rbxassetid://100806996169984",
		size = Vector3.new(0.696, 1.439, 0.696) * 5.4,
		seatYOffset = 2.5,
		seatSize = Vector3.new(2.6, 0.4, 2.4),
		textures = {
			color = "rbxassetid://103020150903895",
			normal = "rbxassetid://124502511593507",
			roughness = "rbxassetid://132808353051000",
			metalness = "rbxassetid://123953344260890",
		},
		setupEffects = function(model: Model, mesh: MeshPart)
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(0, 240, 255)
			pl.Brightness = 3.0
			pl.Range = 15
			pl.Parent = mesh

			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, 0.6, 0)
			att.Parent = mesh

			local sparks = Instance.new("ParticleEmitter")
			sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color = ColorSequence.new(Color3.fromRGB(0, 255, 240), Color3.fromRGB(255, 0, 180))
			sparks.LightEmission = 1
			sparks.Size = NumberSequence.new(0.45, 0)
			sparks.Lifetime = NumberRange.new(1.0, 2.0)
			sparks.Rate = 18
			sparks.Speed = NumberRange.new(1.5, 3.0)
			sparks.Parent = att

			local hl = Instance.new("Highlight")
			hl.OutlineColor = Color3.fromRGB(0, 255, 240)
			hl.OutlineTransparency = 0.35
			hl.FillColor = Color3.fromRGB(0, 150, 255)
			hl.FillTransparency = 0.90
			hl.Adornee = model
			hl.Parent = model
		end,
	},

	crimson = {
		name = "CrimsonFlameChair",
		meshId = "rbxassetid://90542614974124",
		size = Vector3.new(1.103656, 1.76, 0.812848) * 4.4,
		seatYOffset = 2.6,
		seatSize = Vector3.new(3.0, 0.4, 2.8),
		textures = {
			color = "rbxassetid://109668871310171",
			normal = "rbxassetid://103591948728845",
			roughness = "rbxassetid://137451057992679",
			metalness = "rbxassetid://94438207030744",
		},
		setupEffects = function(model: Model, mesh: MeshPart)
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(255, 60, 30)
			pl.Brightness = 3.5
			pl.Range = 16
			pl.Parent = mesh

			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, 0, 0)
			att.Parent = mesh

			local embers = Instance.new("ParticleEmitter")
			embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			embers.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(180, 20, 10))
			embers.LightEmission = 1
			embers.Size = NumberSequence.new(0.4, 0)
			embers.Lifetime = NumberRange.new(1.2, 2.2)
			embers.Rate = 20
			embers.Speed = NumberRange.new(2, 4)
			embers.Acceleration = Vector3.new(0, 4.5, 0)
			embers.Parent = att

			local fireOffsets = {
				Vector3.new(-1.8, 2.8, -0.2),
				Vector3.new(1.8, 2.8, -0.2),
				Vector3.new(0, -0.8, 0.5),
			}
			for _, off in ipairs(fireOffsets) do
				local fAtt = Instance.new("Attachment")
				fAtt.Position = off
				fAtt.Parent = mesh
				local fire = Instance.new("ParticleEmitter")
				fire.Texture = "rbxassetid://253188732"
				fire.Color = ColorSequence.new(Color3.fromRGB(255, 180, 60), Color3.fromRGB(150, 10, 10))
				fire.LightEmission = 1
				fire.Size = NumberSequence.new(1.5, 0)
				fire.Lifetime = NumberRange.new(0.6, 1.1)
				fire.Rate = 16
				fire.Speed = NumberRange.new(1.5, 3.5)
				fire.Acceleration = Vector3.new(0, 5, 0)
				fire.Parent = fAtt
			end

			local hl = Instance.new("Highlight")
			hl.OutlineColor = Color3.fromRGB(255, 70, 40)
			hl.OutlineTransparency = 0.3
			hl.FillColor = Color3.fromRGB(220, 30, 20)
			hl.FillTransparency = 0.88
			hl.Adornee = model
			hl.Parent = model
		end,
	},

	lucky_clover = {
		name = "LuckyCloverChair",
		meshId = "rbxassetid://113779249418013",
		size = Vector3.new(4.465, 7.70, 4.376),
		seatYOffset = 2.3,
		seatSize = Vector3.new(2.8, 0.4, 2.6),
		textures = {
			color = "rbxassetid://135950506251697",
			normal = "rbxassetid://94633743168876",
			roughness = "rbxassetid://99634164761171",
			metalness = "rbxassetid://100917384734662",
		},
		setupEffects = function(_model: Model, mesh: MeshPart)
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(255, 220, 120)
			pl.Brightness = 2.5
			pl.Range = 14
			pl.Parent = mesh

			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, mesh.Size.Y * 0.42, 0)
			att.Parent = mesh

			local sparkles = Instance.new("ParticleEmitter")
			sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 80), Color3.fromRGB(80, 255, 140))
			sparkles.LightEmission = 1
			sparkles.Size = NumberSequence.new(0.4, 0)
			sparkles.Lifetime = NumberRange.new(0.9, 1.8)
			sparkles.Rate = 10
			sparkles.Speed = NumberRange.new(0.6, 1.6)
			sparkles.SpreadAngle = Vector2.new(60, 60)
			sparkles.Parent = att
		end,
	},

	frostbite = {
		name = "FrostbiteIceThrone",
		meshId = "rbxassetid://76494472528484",
		size = Vector3.new(2.09792, 2.4865, 1.350) * 3.4,
		seatYOffset = 2.5,
		seatSize = Vector3.new(2.8, 0.4, 2.6),
		textures = {
			color = "rbxassetid://111872608785953",
			normal = "rbxassetid://114000707456459",
			roughness = "rbxassetid://85147068810486",
			metalness = "rbxassetid://118447872662274",
		},
		setupEffects = function(model: Model, mesh: MeshPart)
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(160, 240, 255)
			pl.Brightness = 3.0
			pl.Range = 16
			pl.Parent = mesh

			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, mesh.Size.Y * 0.35, 0)
			att.Parent = mesh

			local mist = Instance.new("ParticleEmitter")
			mist.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			mist.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255), Color3.fromRGB(240, 250, 255))
			mist.LightEmission = 0.8
			mist.Size = NumberSequence.new(0.5, 0)
			mist.Lifetime = NumberRange.new(1.2, 2.4)
			mist.Rate = 20
			mist.Speed = NumberRange.new(0.8, 2.0)
			mist.SpreadAngle = Vector2.new(45, 45)
			mist.Acceleration = Vector3.new(0, -1.0, 0)
			mist.Parent = att

			local hl = Instance.new("Highlight")
			hl.OutlineColor = Color3.fromRGB(140, 230, 255)
			hl.OutlineTransparency = 0.4
			hl.FillColor = Color3.fromRGB(180, 240, 255)
			hl.FillTransparency = 0.92
			hl.Adornee = model
			hl.Parent = model
		end,
	},

	golden = {
		name = "RoyalFootballThrone",
		meshId = "rbxassetid://137497051752765",
		size = Vector3.new(1.830697, 2.871224, 1.070442) * 3.0,
		seatYOffset = 2.5,
		seatSize = Vector3.new(2.8, 0.4, 2.6),
		textures = {
			color = "rbxassetid://127537014682491",
			normal = "rbxassetid://132814363835049",
			roughness = "rbxassetid://95768455270132",
			metalness = "rbxassetid://108307943942270",
		},
		setupEffects = function(model: Model, mesh: MeshPart)
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(255, 215, 70)
			pl.Brightness = 3.2
			pl.Range = 16
			pl.Parent = mesh

			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, mesh.Size.Y * 0.38, 0)
			att.Parent = mesh

			local sparkles = Instance.new("ParticleEmitter")
			sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(200, 140, 10))
			sparkles.LightEmission = 1
			sparkles.Size = NumberSequence.new(0.5, 0)
			sparkles.Lifetime = NumberRange.new(1.2, 2.4)
			sparkles.Rate = 18
			sparkles.Speed = NumberRange.new(1.2, 2.8)
			sparkles.Parent = att

			local hl = Instance.new("Highlight")
			hl.OutlineColor = Color3.fromRGB(255, 210, 50)
			hl.OutlineTransparency = 0.35
			hl.FillColor = Color3.fromRGB(255, 190, 30)
			hl.FillTransparency = 0.92
			hl.Adornee = model
			hl.Parent = model
		end,
	},

	vip_black_diamond = {
		name = "BlackDiamondVIPChair",
		meshId = "rbxassetid://137755864340291",
		size = Vector3.new(4.34, 7.7, 3.69),
		seatYOffset = 2.4,
		seatSize = Vector3.new(2.8, 0.4, 2.6),
		textures = {
			color = "rbxassetid://91639274995198",
			normal = "rbxassetid://116365734414723",
			roughness = "rbxassetid://94606636079817",
			metalness = "rbxassetid://88022934415399",
		},
		setupEffects = function(model: Model, mesh: MeshPart)
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(255, 220, 150)
			pl.Brightness = 2.5
			pl.Range = 14
			pl.Parent = mesh

			local att = Instance.new("Attachment")
			att.Position = Vector3.new(0, mesh.Size.Y * 0.42, 0)
			att.Parent = mesh

			local diamondLight = Instance.new("PointLight")
			diamondLight.Color = Color3.fromRGB(200, 240, 255)
			diamondLight.Brightness = 3.5
			diamondLight.Range = 8
			diamondLight.Parent = att

			local sparkles = Instance.new("ParticleEmitter")
			sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 240, 255))
			sparkles.LightEmission = 1
			sparkles.Size = NumberSequence.new(0.4, 0)
			sparkles.Lifetime = NumberRange.new(0.8, 1.6)
			sparkles.Rate = 8
			sparkles.Speed = NumberRange.new(0.6, 1.5)
			sparkles.Parent = att
		end,
	},
}

-- Builds a complete 3D Mesh chair with PBR SurfaceAppearance, effects, and optional Seat
function ChairModelBuilder.buildMeshChair(skinKey: string, cfTarget: CFrame?, withSeat: boolean?): Model
	local cfg = MESH_CONFIGS[skinKey]
	if not cfg then
		return ChairModelBuilder.buildStadiumChair(cfTarget)
	end

	local model = Instance.new("Model")
	model.Name = cfg.name

	local mesh = getMeshPart(cfg.meshId)
	mesh.Name = cfg.name .. "_Mesh"
	mesh.PivotOffset = CFrame.identity
	mesh.Size = cfg.size
	mesh.TextureID = cfg.textures.color
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.CastShadow = true

	local sa = mesh:FindFirstChildWhichIsA("SurfaceAppearance")
	if not sa then
		pcall(function()
			local newSa = Instance.new("SurfaceAppearance")
			newSa.ColorMap = cfg.textures.color
			newSa.NormalMap = cfg.textures.normal
			newSa.RoughnessMap = cfg.textures.roughness
			newSa.MetalnessMap = cfg.textures.metalness
			newSa.Parent = mesh
		end)
	end

	local cfBase = cfTarget or CFrame.identity
	local centerY = cfBase.Position.Y + (cfg.size.Y / 2)
	mesh.CFrame = CFrame.new(cfBase.Position.X, centerY, cfBase.Position.Z) * (cfBase - cfBase.Position)
	mesh.Parent = model
	model.PrimaryPart = mesh

	if cfg.setupEffects then
		cfg.setupEffects(model, mesh)
	end

	if withSeat then
		local seat = Instance.new("Seat")
		seat.Name = "Seat"
		seat.Size = cfg.seatSize
		seat.CFrame = CFrame.new(cfBase.Position.X, cfBase.Position.Y + cfg.seatYOffset, cfBase.Position.Z) * (cfBase - cfBase.Position)
		seat.Transparency = 1
		seat.Anchored = true
		seat.CanCollide = true
		seat.Parent = model
	end

	return model
end

-- Specific chair builders
function ChairModelBuilder.buildCyberCoreChair(cfOffset: CFrame?): Model
	return ChairModelBuilder.buildMeshChair("cyber_core", cfOffset, true)
end

function ChairModelBuilder.buildCrimsonFlameChair(cfOffset: CFrame?): Model
	return ChairModelBuilder.buildMeshChair("crimson", cfOffset, true)
end

function ChairModelBuilder.buildLuckyCloverChair(cfOffset: CFrame?): Model
	return ChairModelBuilder.buildMeshChair("lucky_clover", cfOffset, true)
end

function ChairModelBuilder.buildFrostbiteThrone(cfOffset: CFrame?): Model
	return ChairModelBuilder.buildMeshChair("frostbite", cfOffset, true)
end

function ChairModelBuilder.buildRoyalFootballThrone(cfOffset: CFrame?): Model
	return ChairModelBuilder.buildMeshChair("golden", cfOffset, true)
end

function ChairModelBuilder.buildBlackDiamondVIPChair(cfOffset: CFrame?): Model
	return ChairModelBuilder.buildMeshChair("vip_black_diamond", cfOffset, true)
end

-- Generic dispatcher mapping skin id / chair type to builder function
function ChairModelBuilder.buildChair(chairType: string, cfOffset: CFrame?): Model
	local key = string.lower(chairType)
	if key == "vip_black_diamond" or key == "black_diamond" or key == "blackdiamond" or key == "vipchair" or key == "blackdiamondvipchair" or key == "vip" then
		return ChairModelBuilder.buildBlackDiamondVIPChair(cfOffset)
	elseif key == "crimson" or key == "crimson_chair" or key == "crimsonchair" or key == "crimsonflame" or key == "crimsonflamechair" or key == "emerald" then
		return ChairModelBuilder.buildMeshChair("crimson", cfOffset, true)
	elseif key == "cyber_core" or key == "cybercore" or key == "cybercorechair" then
		return ChairModelBuilder.buildMeshChair("cyber_core", cfOffset, true)
	elseif key == "lucky_clover" or key == "clover" or key == "luckyclover" or key == "cloverchair" or key == "luckycloverchair" then
		return ChairModelBuilder.buildLuckyCloverChair(cfOffset)
	elseif key == "frostbite" or key == "frost" or key == "frostbitethrone" or key == "frostbitechair" or key == "frostchair" or key == "cyber" then
		return ChairModelBuilder.buildFrostbiteThrone(cfOffset)
	elseif key == "golden" or key == "football_throne" or key == "footballthrone" or key == "royal" or key == "royalthrone" or key == "royalfootballthrone" then
		return ChairModelBuilder.buildRoyalFootballThrone(cfOffset)
	elseif key == "wood" or key == "woodchair" or key == "classic" or key == "classicwood" or key == "classic_wood" then
		return ChairModelBuilder.buildWoodChair(cfOffset)
	elseif key == "stadium" or key == "stadiumchair" then
		return ChairModelBuilder.buildStadiumChair(cfOffset)
	else
		return ChairModelBuilder.buildWoodChair(cfOffset)
	end
end

ChairModelBuilder.buildCrimsonChair = ChairModelBuilder.buildCrimsonFlameChair
ChairModelBuilder.buildCyberChair = ChairModelBuilder.buildCyberCoreChair
ChairModelBuilder.buildFrostThrone = ChairModelBuilder.buildFrostbiteThrone
ChairModelBuilder.buildCloverChair = ChairModelBuilder.buildLuckyCloverChair
ChairModelBuilder.buildRoyalThrone = ChairModelBuilder.buildRoyalFootballThrone
ChairModelBuilder.buildGoldenChair = ChairModelBuilder.buildRoyalFootballThrone

type SeatAlignment = {
	rawBottomY: number,
	rawSeatTopY: number,
	backShift: number,
	rawSideShift: number,
	frontYaw: number,
	widthMult: number?,
}

local SEAT_ALIGNMENTS: { [string]: SeatAlignment } = {
	stadium = { rawBottomY = 0.10, rawSeatTopY = 1.26, backShift = 0.25, rawSideShift = 0, frontYaw = math.pi },
	crimson = { rawBottomY = 0, rawSeatTopY = 2.38, backShift = 0.40, rawSideShift = 0, frontYaw = 0 },
	cyber_core = { rawBottomY = 0, rawSeatTopY = 2.93, backShift = 0.45, rawSideShift = 0, frontYaw = 0 },
	frostbite = { rawBottomY = 0, rawSeatTopY = 3.15, backShift = 0.45, rawSideShift = 0, frontYaw = 0 },
	lucky_clover = { rawBottomY = 0, rawSeatTopY = 3.60, backShift = 0.40, rawSideShift = 0.405, frontYaw = 0, widthMult = 1.22 },
	golden = { rawBottomY = 0, rawSeatTopY = 3.20, backShift = 0.75, rawSideShift = 0, frontYaw = 0 },
	vip_black_diamond = { rawBottomY = 0, rawSeatTopY = 2.48, backShift = 0.45, rawSideShift = 0, frontYaw = 0 },
}

local function findGroundY(seat: Seat, tableModel: Model?): number
	local exclude: { Instance } = { if tableModel then tableModel else seat }
	for _, plr in Players:GetPlayers() do
		if plr.Character then
			table.insert(exclude, plr.Character)
		end
	end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.IgnoreWater = true

	-- Skip seated/nearby characters, existing chair decor, and non-collidable zones so the chair scales to the real floor
	local origin = seat.Position + Vector3.new(0, 1, 0)
	for _ = 1, 16 do
		rp.FilterDescendantsInstances = exclude
		local hit = workspace:Raycast(origin, Vector3.new(0, -25, 0), rp)
		if not hit then
			return 0
		end
		local inst = hit.Instance
		local model = inst:FindFirstAncestorOfClass("Model")
		local isChar = model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
		local isDecor = model ~= nil and string.match(model.Name, "_Decor$") ~= nil
		if isChar or isDecor then
			table.insert(exclude, model :: Instance)
			origin = hit.Position - Vector3.new(0, 0.01, 0)
		elseif not inst.CanCollide then
			table.insert(exclude, inst)
			origin = hit.Position - Vector3.new(0, 0.01, 0)
		else
			return hit.Position.Y
		end
	end
	return 0
end

-- Builds and aligns a match-table chair decor so its base touches floorY, cushion matches Seat top, and front faces Seat.LookVector
function ChairModelBuilder.buildChairForSeat(skinId: string, seat: Seat, tableModel: Model?): Model?
	local align = SEAT_ALIGNMENTS[skinId]
	if not align then
		return nil
	end

	local groundY = findGroundY(seat, tableModel)
	local seatTopY = seat.Position.Y + (seat.Size.Y * 0.5)
	local height = seatTopY - groundY
	if height < 0.5 then
		groundY = 0
		height = seatTopY - groundY
	end
	local scale = math.max(0.3, height / (align.rawSeatTopY - align.rawBottomY))

	local decor = if skinId == "stadium"
		then ChairModelBuilder.buildStadiumChair(CFrame.identity)
		else ChairModelBuilder.buildMeshChair(skinId, CFrame.identity, false)

	if align.widthMult and decor.PrimaryPart and decor.PrimaryPart:IsA("BasePart") then
		decor.PrimaryPart.Size = Vector3.new(decor.PrimaryPart.Size.X * align.widthMult, decor.PrimaryPart.Size.Y, decor.PrimaryPart.Size.Z)
	end
	decor.PrimaryPart = nil
	decor.WorldPivot = CFrame.new(0, align.rawBottomY, 0)
	decor:ScaleTo(scale)

	local flatLook = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z)
	local look = if flatLook.Magnitude > 1e-3 then flatLook.Unit else seat.CFrame.LookVector
	local right = look:Cross(Vector3.yAxis)
	local basePos = Vector3.new(seat.Position.X, groundY, seat.Position.Z)
		- (look * align.backShift)
		+ (right * (align.rawSideShift * scale * (align.widthMult or 1)))
	decor:PivotTo(CFrame.lookAt(basePos, basePos + look) * CFrame.Angles(0, align.frontYaw, 0))
	return decor
end

return ChairModelBuilder

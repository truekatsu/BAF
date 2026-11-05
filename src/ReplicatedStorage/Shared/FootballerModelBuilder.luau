--!strict
--[[
	FootballerModelBuilder
	Responsibility: Procedural 3D Roblox Model generator for all 152 real footballers (matching skin tone, hairstyle, hair color, beard/mask, club jersey shirt + pattern + sleeves + club shorts + socks). Populates ReplicatedStorage.FootballerModels and clones models for UI ViewportFrames.
	Loop step: action | reward (visual presentation)
	Location: ReplicatedStorage/Shared/FootballerModelBuilder (ModuleScript)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Footballers = require(script.Parent.Footballers)

export type Footballer = Footballers.Footballer

local FOLDER_NAME = "FootballerModels"

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function addHeadMesh(part: Part, scale: Vector3)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Head
	m.Scale = scale
	m.Parent = part
end

local function makeSphere(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = makePart(parent, name, size, cf, color)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end

local function buildHair(model: Instance, card: Footballer, hairCol: Color3)
	local style = card.hairStyle
	if style == "bald" then
		return
	end

	local darkFade = Color3.fromHex("#18181C")

	if style == "buzz" then
		makeSphere(model, "Hair", Vector3.new(1.31, 0.68, 1.33), CFrame.new(0, 2.44, 0.03), hairCol)
	elseif style == "short" then
		makeSphere(model, "Hair", Vector3.new(1.34, 0.74, 1.36), CFrame.new(0, 2.46, 0.04), hairCol)
		makeSphere(
			model,
			"HairQuiff",
			Vector3.new(1.06, 0.34, 0.76),
			CFrame.new(0.06, 2.66, -0.24) * CFrame.Angles(math.rad(-10), 0, math.rad(-5)),
			hairCol
		)
		makePart(model, "SideHairL", Vector3.new(0.14, 0.34, 0.64), CFrame.new(-0.59, 2.26, 0.08), hairCol)
		makePart(model, "SideHairR", Vector3.new(0.14, 0.34, 0.64), CFrame.new(0.59, 2.26, 0.08), hairCol)
	elseif style == "curly" then
		makeSphere(model, "Hair", Vector3.new(1.36, 0.74, 1.38), CFrame.new(0, 2.46, 0.03), hairCol)
		local puffs = {
			{ Vector3.new(0, 2.74, -0.06), 0.64 },
			{ Vector3.new(-0.34, 2.66, -0.22), 0.54 },
			{ Vector3.new(0.34, 2.66, -0.22), 0.54 },
			{ Vector3.new(-0.38, 2.62, 0.16), 0.56 },
			{ Vector3.new(0.38, 2.62, 0.16), 0.56 },
			{ Vector3.new(0, 2.60, 0.34), 0.58 },
			{ Vector3.new(0, 2.58, -0.38), 0.46 },
		}
		for i, pf in puffs do
			local sz = pf[2] :: number
			makeSphere(model, `HairCurl{i}`, Vector3.new(sz, sz, sz), CFrame.new(pf[1] :: Vector3), hairCol)
		end
	elseif style == "bun" then
		makeSphere(model, "Hair", Vector3.new(1.32, 0.70, 1.34), CFrame.new(0, 2.45, 0.04), hairCol)
		local band = makePart(model, "Headband", Vector3.new(2, 1, 1), CFrame.new(0, 2.38, 0), darkFade)
		addHeadMesh(band, Vector3.new(1.28, 0.12, 1.28))
		makeSphere(model, "HairBun", Vector3.new(0.56, 0.56, 0.56), CFrame.new(0, 2.58, 0.58), hairCol)
		if card.id == "haaland" then
			makeSphere(model, "HairBack", Vector3.new(1.02, 0.72, 0.44), CFrame.new(0, 2.00, 0.48), hairCol)
		end
	elseif style == "long" then
		makeSphere(model, "Hair", Vector3.new(1.36, 0.74, 1.38), CFrame.new(0, 2.46, 0.04), hairCol)
		local band = makePart(model, "Headband", Vector3.new(2, 1, 1), CFrame.new(0, 2.39, 0), darkFade)
		addHeadMesh(band, Vector3.new(1.29, 0.12, 1.29))
		makeSphere(model, "HairFlowL", Vector3.new(0.32, 0.92, 0.82), CFrame.new(-0.58, 2.04, 0.10), hairCol)
		makeSphere(model, "HairFlowR", Vector3.new(0.32, 0.92, 0.82), CFrame.new(0.58, 2.04, 0.10), hairCol)
		makeSphere(model, "HairFlowBack", Vector3.new(1.16, 1.00, 0.46), CFrame.new(0, 2.00, 0.46), hairCol)
	elseif style == "braids" then
		makeSphere(model, "Hair", Vector3.new(1.31, 0.68, 1.33), CFrame.new(0, 2.44, 0.03), darkFade)
		if card.id == "madueke" then
			local band = makePart(model, "Headband", Vector3.new(2, 1, 1), CFrame.new(0, 2.37, 0), Color3.new(1, 1, 1))
			addHeadMesh(band, Vector3.new(1.28, 0.16, 1.28))
		end
		for idx, xOff in { -0.36, -0.18, 0, 0.18, 0.36 } do
			makeSphere(model, `BraidTop{idx}`, Vector3.new(0.18, 0.28, 1.18), CFrame.new(xOff, 2.64, 0.02), hairCol)
			makePart(model, `BraidBack{idx}`, Vector3.new(0.13, 0.62, 0.18), CFrame.new(xOff, 2.18, 0.56), hairCol)
		end
	elseif style == "mohawk" then
		makeSphere(model, "HairFade", Vector3.new(1.30, 0.64, 1.32), CFrame.new(0, 2.42, 0.03), darkFade)
		makeSphere(model, "Hair", Vector3.new(0.84, 0.42, 1.20), CFrame.new(0, 2.66, -0.02), hairCol)
	end
end

local FootballerModelBuilder = {}

function FootballerModelBuilder.buildModel(card: Footballer): Model
	local model = Instance.new("Model")
	model.Name = card.id
	model:SetAttribute("DisplayName", card.name)
	model:SetAttribute("Club", card.club)
	model:SetAttribute("Country", card.country)
	model:SetAttribute("Rarity", card.rarity)

	local skinCol = if Footballers.getSkinColor
		then Footballers.getSkinColor(card)
		else Footballers.SKIN_TONES[math.clamp(card.skin or 3, 1, #Footballers.SKIN_TONES)]
	local hairCol = Color3.fromHex(card.hairColor)
	local browCol = hairCol:Lerp(Color3.fromRGB(22, 18, 16), 0.35)
	local kit = Footballers.getKit(card)

	local shirtCol = Color3.fromHex(kit.shirt)
	local secCol = Color3.fromHex(kit.secondary)
	local sleeveCol = Color3.fromHex(kit.sleeve)
	local shortsCol = Color3.fromHex(kit.shorts)
	local socksCol = Color3.fromHex(kit.socks)
	local trimCol = Color3.fromHex(kit.trim)

	-- 1. Standard R6-proportioned Head (2x1x1 + Head SpecialMesh 1.25 -> clean 1.25x1.25x1.25 skull & native face.png aspect)
	local head = makePart(model, "Head", Vector3.new(2, 1, 1), CFrame.new(0, 2.08, 0), skinCol)
	addHeadMesh(head, Vector3.new(1.25, 1.25, 1.25))

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	makePart(model, "EarL", Vector3.new(0.16, 0.28, 0.20), CFrame.new(-0.62, 2.06, 0.02), skinCol)
	makePart(model, "EarR", Vector3.new(0.16, 0.28, 0.20), CFrame.new(0.62, 2.06, 0.02), skinCol)

	makePart(
		model,
		"BrowL",
		Vector3.new(0.24, 0.06, 0.08),
		CFrame.new(-0.21, 2.28, -0.59) * CFrame.Angles(0, 0, math.rad(-4)),
		browCol
	)
	makePart(
		model,
		"BrowR",
		Vector3.new(0.24, 0.06, 0.08),
		CFrame.new(0.21, 2.28, -0.59) * CFrame.Angles(0, 0, math.rad(4)),
		browCol
	)

	-- Optional Beard / Facial Hair (leaves eyes & smile clear)
	if card.beard then
		local jaw = makePart(model, "BeardJaw", Vector3.new(2, 1, 1), CFrame.new(0, 1.64, -0.02), browCol)
		addHeadMesh(jaw, Vector3.new(1.27, 0.36, 1.27))
		makePart(model, "SideburnL", Vector3.new(0.12, 0.36, 0.44), CFrame.new(-0.59, 1.92, -0.14), browCol)
		makePart(model, "SideburnR", Vector3.new(0.12, 0.36, 0.44), CFrame.new(0.59, 1.92, -0.14), browCol)
		makePart(model, "Mustache", Vector3.new(0.38, 0.055, 0.09), CFrame.new(0, 1.97, -0.60), browCol)
	end

	-- Iconic Osimhen Protective Face Mask
	if card.id == "osimhen" then
		local maskCol = Color3.fromHex("#12141A")
		makePart(model, "MaskBrow", Vector3.new(1.10, 0.14, 0.44), CFrame.new(0, 2.30, -0.44), maskCol)
		makePart(model, "MaskNose", Vector3.new(0.16, 0.26, 0.16), CFrame.new(0, 2.13, -0.60), maskCol)
		makePart(model, "MaskCheekL", Vector3.new(0.38, 0.14, 0.46), CFrame.new(-0.38, 2.03, -0.42), maskCol)
		makePart(model, "MaskCheekR", Vector3.new(0.38, 0.14, 0.46), CFrame.new(0.38, 2.03, -0.42), maskCol)
	end

	-- 2. Hairstyle
	buildHair(model, card, hairCol)

	-- 3. Neck & Club Jersey Shirt (Torso + Pattern + Collar + Crest)
	makePart(model, "Neck", Vector3.new(0.52, 0.28, 0.52), CFrame.new(0, 1.50, 0), skinCol)

	local torso = makePart(model, "Torso", Vector3.new(1.88, 1.86, 0.94), CFrame.new(0, 0.55, 0), shirtCol)
	makePart(model, "Collar", Vector3.new(0.86, 0.16, 0.98), CFrame.new(0, 1.42, 0), trimCol)

	if kit.pattern == "stripes" then
		for idx, xOff in { -0.54, 0, 0.54 } do
			makePart(model, `Stripe{idx}`, Vector3.new(0.30, 1.84, 0.96), CFrame.new(xOff, 0.55, 0), secCol)
		end
	elseif kit.pattern == "center" then
		makePart(model, "StripeBorder", Vector3.new(0.60, 1.84, 0.955), CFrame.new(0, 0.55, 0), trimCol)
		makePart(model, "StripeCenter", Vector3.new(0.44, 1.85, 0.965), CFrame.new(0, 0.55, 0), secCol)
	elseif kit.pattern == "half" then
		makePart(model, "HalfTorso", Vector3.new(0.94, 1.85, 0.96), CFrame.new(-0.47, 0.55, 0), secCol)
	elseif kit.pattern == "hoops" then
		for idx, yOff in { 1.12, 0.54, -0.04 } do
			makePart(model, `Hoop{idx}`, Vector3.new(1.90, 0.30, 0.96), CFrame.new(0, yOff, 0), secCol)
		end
	end

	makePart(model, "ClubCrest", Vector3.new(0.22, 0.24, 0.05), CFrame.new(-0.46, 1.02, -0.48), trimCol)

	-- 4. Sleeves & Arms (slight athletic outward stance)
	local armAngleL = CFrame.new(-1.38, 1.06, 0) * CFrame.Angles(0, 0, math.rad(7))
	local armAngleR = CFrame.new(1.38, 1.06, 0) * CFrame.Angles(0, 0, math.rad(-7))

	makePart(model, "SleeveL", Vector3.new(0.84, 0.82, 0.86), armAngleL, sleeveCol)
	makePart(model, "CuffL", Vector3.new(0.86, 0.11, 0.88), armAngleL * CFrame.new(0, -0.38, 0), trimCol)
	makePart(model, "ArmL", Vector3.new(0.76, 1.02, 0.78), armAngleL * CFrame.new(0, -0.90, 0), skinCol)

	makePart(model, "SleeveR", Vector3.new(0.84, 0.82, 0.86), armAngleR, sleeveCol)
	makePart(model, "CuffR", Vector3.new(0.86, 0.11, 0.88), armAngleR * CFrame.new(0, -0.38, 0), trimCol)
	makePart(model, "ArmR", Vector3.new(0.76, 1.02, 0.78), armAngleR * CFrame.new(0, -0.90, 0), skinCol)

	if card.pos == "GK" then
		local gloveCol = Color3.fromHex("#F8FAFC")
		makePart(model, "GloveL", Vector3.new(0.84, 0.36, 0.86), armAngleL * CFrame.new(0, -1.28, 0), gloveCol)
		makePart(model, "GloveR", Vector3.new(0.84, 0.36, 0.86), armAngleR * CFrame.new(0, -1.28, 0), gloveCol)
	end

	-- 5. Club Shorts, Legs, Socks & Boots
	makePart(model, "ShortsWaist", Vector3.new(1.88, 0.34, 0.95), CFrame.new(0, -0.50, 0), shortsCol)
	makePart(model, "ShortsL", Vector3.new(0.88, 0.86, 0.92), CFrame.new(-0.49, -0.96, 0), shortsCol)
	makePart(model, "ShortsR", Vector3.new(0.88, 0.86, 0.92), CFrame.new(0.49, -0.96, 0), shortsCol)
	makePart(model, "ShortsTrimL", Vector3.new(0.06, 0.84, 0.36), CFrame.new(-0.91, -0.96, 0), trimCol)
	makePart(model, "ShortsTrimR", Vector3.new(0.06, 0.84, 0.36), CFrame.new(0.91, -0.96, 0), trimCol)

	makePart(model, "LegL", Vector3.new(0.76, 0.62, 0.78), CFrame.new(-0.49, -1.67, 0), skinCol)
	makePart(model, "LegR", Vector3.new(0.76, 0.62, 0.78), CFrame.new(0.49, -1.67, 0), skinCol)

	makePart(model, "SocksL", Vector3.new(0.80, 0.56, 0.82), CFrame.new(-0.49, -2.23, 0), socksCol)
	makePart(model, "SocksR", Vector3.new(0.80, 0.56, 0.82), CFrame.new(0.49, -2.23, 0), socksCol)

	local bootCol = Color3.fromHex("#181A22")
	makePart(model, "BootL", Vector3.new(0.82, 0.30, 1.08), CFrame.new(-0.49, -2.62, -0.10), bootCol)
	makePart(model, "BootR", Vector3.new(0.82, 0.30, 1.08), CFrame.new(0.49, -2.62, -0.10), bootCol)

	model.PrimaryPart = torso
	return model
end

function FootballerModelBuilder.ensureAllModels(): Folder
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, card in Footballers.All do
		if not folder:FindFirstChild(card.id) then
			local m = FootballerModelBuilder.buildModel(card)
			m.Parent = folder
		end
	end
	return folder
end

function FootballerModelBuilder.cloneModel(cardId: string): Model?
	local card = Footballers.ById[cardId]
	if not card then
		return nil
	end
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder?
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	local template = folder:FindFirstChild(cardId) :: Model?
	if not template then
		template = FootballerModelBuilder.buildModel(card)
		template.Parent = folder
	end
	return template:Clone()
end

return table.freeze(FootballerModelBuilder)

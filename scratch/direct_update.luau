local s = game.ReplicatedStorage.Prefabs.ChairModelBuilder
s.Source = [====[
--!strict
--[[
	ChairModelBuilder
	Responsibility: Constructs 3D stylized Lego chair models matching the game's toy-brick aesthetic.
	Specifically builds the Stadium Blue chair based on the 4-view orthographic reference
	(dark 2x2 stud base plate, dark center pedestal, stepped blue seat cushion, and angled ribbed backrest).
	Location: ReplicatedStorage/Prefabs/ChairModelBuilder.luau
]]

local ChairModelBuilder = {}

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

-- Constructs the stylized Crimson Flame Chair model (chunky crimson wood, iron caps, diamond gems & flame aura)
function ChairModelBuilder.buildCrimsonFlameChair(cfOffset: CFrame?): Model
	local cfBase = cfOffset or CFrame.identity
	local model = Instance.new("Model")
	model.Name = "CrimsonFlameChair"

	local C_WOOD = Color3.fromRGB(150, 15, 25)
	local C_LEG = Color3.fromRGB(110, 10, 20)
	local C_IRON = Color3.fromRGB(30, 24, 28)
	local C_GEM = Color3.fromRGB(255, 40, 50)
	local C_EMBLEM = Color3.fromRGB(40, 10, 15)

	local function make(name: string, size: Vector3, relCF: CFrame, color: Color3, mat: Enum.Material, canCollide: boolean?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cfBase * relCF
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.CanCollide = if canCollide ~= nil then canCollide else false
		p.CastShadow = true
		p.Parent = model
		return p
	end

	-- 1. Seat
	local seat = Instance.new("Seat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(4, 0.7, 4)
	seat.CFrame = cfBase * CFrame.new(0, 2.85, 0)
	seat.Color = C_WOOD
	seat.Material = Enum.Material.WoodPlanks
	seat.Anchored = true
	seat.CanCollide = true
	seat.CastShadow = true
	seat.Parent = model
	model.PrimaryPart = seat

	local seatEmblem = Instance.new("Decal")
	seatEmblem.Name = "FlameEmblem_Seat"
	seatEmblem.Face = Enum.NormalId.Top
	seatEmblem.Texture = "rbxassetid://90165853329906"
	seatEmblem.Color3 = C_EMBLEM
	seatEmblem.Transparency = 0.1
	seatEmblem.Parent = seat

	-- 2. Legs
	local legOffsets = {
		FL = Vector3.new(-1.6, 1.25, -1.6),
		FR = Vector3.new( 1.6, 1.25, -1.6),
		BL = Vector3.new(-1.6, 1.25,  1.6),
		BR = Vector3.new( 1.6, 1.25,  1.6),
	}
	for tag, offset in legOffsets do
		make("Leg_" .. tag, Vector3.new(0.8, 2.5, 0.8), CFrame.new(offset), C_LEG, Enum.Material.WoodPlanks, true)
	end

	-- 3. Backrest posts
	make("Post_Left", Vector3.new(0.8, 5, 0.8), CFrame.new(-1.6, 5.7, 1.6), C_WOOD, Enum.Material.WoodPlanks, true)
	make("Post_Right", Vector3.new(0.8, 5, 0.8), CFrame.new( 1.6, 5.7, 1.6), C_WOOD, Enum.Material.WoodPlanks, true)

	-- 4. Backrest panel
	local backrest = make("BackrestPanel", Vector3.new(3.2, 4.4, 0.4), CFrame.new(0, 5.7, 1.6), C_WOOD, Enum.Material.WoodPlanks, true)
	local backEmblem = Instance.new("Decal")
	backEmblem.Name = "FlameEmblem_Backrest"
	backEmblem.Face = Enum.NormalId.Front
	backEmblem.Texture = "rbxassetid://90165853329906"
	backEmblem.Color3 = C_EMBLEM
	backEmblem.Transparency = 0.1
	backEmblem.Parent = backrest

	-- 5. Dark iron caps
	local legCaps = {}
	for tag, offset in legOffsets do
		legCaps[tag] = make("LegCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), CFrame.new(offset.X, 0.25, offset.Z), C_IRON, Enum.Material.Slate, false)
	end
	local postCapL = make("PostCap_Left", Vector3.new(0.95, 0.5, 0.95), CFrame.new(-1.6, 8.2, 1.6), C_IRON, Enum.Material.Slate, false)
	local postCapR = make("PostCap_Right", Vector3.new(0.95, 0.5, 0.95), CFrame.new( 1.6, 8.2, 1.6), C_IRON, Enum.Material.Slate, false)

	-- 6. Corner brackets on seat
	local cornerDirs = {
		FL = { -1, -1 },
		FR = {  1, -1 },
		BL = { -1,  1 },
		BR = {  1,  1 },
	}
	for tag, d in cornerDirs do
		local cx, cz = d[1], d[2]
		make("CornerBracket_X_" .. tag, Vector3.new(0.85, 0.12, 0.28), CFrame.new(cx * (2 - 0.85 / 2), 3.26, cz * (2 - 0.28 / 2)), C_IRON, Enum.Material.Slate, false)
		make("CornerBracket_Z_" .. tag, Vector3.new(0.28, 0.12, 0.85), CFrame.new(cx * (2 - 0.28 / 2), 3.26, cz * (2 - 0.85 / 2)), C_IRON, Enum.Material.Slate, false)
		local gemRelCF = CFrame.lookAt(Vector3.new(cx * 1.80, 3.32, cz * 1.80), Vector3.new(cx * 1.80, 4.32, cz * 1.80), Vector3.new(0, 0, 1)) * CFrame.Angles(0, 0, math.rad(45))
		make("Gem_Corner_" .. tag, Vector3.new(0.24, 0.24, 0.08), gemRelCF, C_GEM, Enum.Material.Neon, false)
	end

	-- Diamond gem inlays
	local function makeFaceGem(gemName: string, centerPos: Vector3, normal: Vector3, upVec: Vector3?)
		local offsetPos = centerPos + normal * (0.95 / 2 + 0.02)
		local up = upVec or (if math.abs(normal.Y) > 0.9 then Vector3.new(0, 0, 1) else Vector3.new(0, 1, 0))
		local gemRelCF = CFrame.lookAt(offsetPos, offsetPos + normal, up) * CFrame.Angles(0, 0, math.rad(45))
		make(gemName, Vector3.new(0.24, 0.24, 0.08), gemRelCF, C_GEM, Enum.Material.Neon, false)
	end

	makeFaceGem("Gem_LegCap_FL_Front", Vector3.new(-1.6, 0.25, -1.6), Vector3.new(0, 0, -1))
	makeFaceGem("Gem_LegCap_FL_Left",  Vector3.new(-1.6, 0.25, -1.6), Vector3.new(-1, 0, 0))
	makeFaceGem("Gem_LegCap_FR_Front", Vector3.new( 1.6, 0.25, -1.6), Vector3.new(0, 0, -1))
	makeFaceGem("Gem_LegCap_FR_Right", Vector3.new( 1.6, 0.25, -1.6), Vector3.new(1, 0, 0))
	makeFaceGem("Gem_LegCap_BL_Back",  Vector3.new(-1.6, 0.25,  1.6), Vector3.new(0, 0, 1))
	makeFaceGem("Gem_LegCap_BL_Left",  Vector3.new(-1.6, 0.25,  1.6), Vector3.new(-1, 0, 0))
	makeFaceGem("Gem_LegCap_BR_Back",  Vector3.new( 1.6, 0.25,  1.6), Vector3.new(0, 0, 1))
	makeFaceGem("Gem_LegCap_BR_Right", Vector3.new( 1.6, 0.25,  1.6), Vector3.new(1, 0, 0))

	makeFaceGem("Gem_PostCap_L_Front", Vector3.new(-1.6, 8.2, 1.6), Vector3.new(0, 0, -1))
	makeFaceGem("Gem_PostCap_L_Left",  Vector3.new(-1.6, 8.2, 1.6), Vector3.new(-1, 0, 0))
	makeFaceGem("Gem_PostCap_L_Top",   Vector3.new(-1.6, 8.2, 1.6), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
	makeFaceGem("Gem_PostCap_R_Front", Vector3.new( 1.6, 8.2, 1.6), Vector3.new(0, 0, -1))
	makeFaceGem("Gem_PostCap_R_Right", Vector3.new( 1.6, 8.2, 1.6), Vector3.new(1, 0, 0))
	makeFaceGem("Gem_PostCap_R_Top",   Vector3.new( 1.6, 8.2, 1.6), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))

	-- 7. Fire aura emitters
	local function addFire(targetPart: Part, name: string)
		local att = Instance.new("Attachment")
		att.Name = "AuraAtt_" .. name
		att.Position = Vector3.zero
		att.Parent = targetPart

		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "FireEmitter"
		emitter.Texture = "rbxassetid://253188732"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(120, 0, 10))
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Size = NumberSequence.new(1.8, 0)
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Rate = 24
		emitter.Speed = NumberRange.new(2, 4)
		emitter.SpreadAngle = Vector2.new(15, 15)
		emitter.Acceleration = Vector3.new(0, 5, 0)
		emitter.Transparency = NumberSequence.new(0.2, 1)
		emitter.Parent = att
	end

	addFire(legCaps.FL, "Leg_FL")
	addFire(legCaps.FR, "Leg_FR")
	addFire(legCaps.BL, "Leg_BL")
	addFire(legCaps.BR, "Leg_BR")
	addFire(postCapL, "Post_L")
	addFire(postCapR, "Post_R")

	-- 8. Glow
	local glow = Instance.new("PointLight")
	glow.Name = "SeatGlow"
	glow.Color = Color3.fromRGB(255, 40, 40)
	glow.Brightness = 2
	glow.Range = 14
	glow.Shadows = false
	glow.Parent = seat

	-- 9. Embers
	local emberAtt = Instance.new("Attachment")
	emberAtt.Name = "EmberAtt"
	emberAtt.Position = Vector3.zero
	emberAtt.Parent = seat

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "EmberEmitter"
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 160, 40), Color3.fromRGB(220, 40, 20))
	embers.LightEmission = 1
	embers.LightInfluence = 0
	embers.Size = NumberSequence.new(0.25, 0.05)
	embers.Lifetime = NumberRange.new(1.5, 3)
	embers.Rate = 8
	embers.Speed = NumberRange.new(0.8, 2)
	embers.SpreadAngle = Vector2.new(180, 180)
	embers.Acceleration = Vector3.new(0, 2, 0)
	embers.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	embers.Parent = emberAtt

	-- 10. Highlight
	local hl = Instance.new("Highlight")
	hl.Name = "FlameHighlight"
	hl.OutlineColor = Color3.fromRGB(255, 60, 50)
	hl.OutlineTransparency = 1
	hl.FillColor = Color3.fromRGB(200, 20, 30)
	hl.FillTransparency = 0.95
	hl.Adornee = model
	hl.Parent = model

	-- 11. Controller Script
	local scriptObj = Instance.new("Script")
	scriptObj.Name = "ChairEffectController"
	scriptObj.Source = [[
--!strict
local TweenService = game:GetService("TweenService")
local model = script.Parent
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
for _, desc in ipairs(model:GetDescendants()) do
	if desc:IsA("BasePart") and desc.Name:find("Gem") then
		desc.Color = Color3.fromRGB(153, 24, 30)
		local tw = TweenService:Create(desc, tweenInfo, { Color = Color3.fromRGB(255, 40, 50) })
		tw:Play()
	end
end
]]
	scriptObj.Parent = model

	return model
end

ChairModelBuilder.buildCrimsonChair = ChairModelBuilder.buildCrimsonFlameChair

return ChairModelBuilder

]====]
return "Direct update successful! Source length: " .. #s.Source

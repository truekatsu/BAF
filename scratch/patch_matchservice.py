path = r'd:\BAF\src\ServerScriptService\Server\MatchService.luau'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

target1 = """\tlocal isCrimson = (skin.id == "crimson" or skin.id == "emerald")
\tlocal isFrostbite = (skin.id == "frostbite" or skin.id == "cyber")"""

replace1 = """\tlocal isCrimson = (skin.id == "crimson" or skin.id == "emerald")
\tlocal isFrostbite = (skin.id == "frostbite" or skin.id == "cyber")
\tlocal isRoyal = (skin.id == "golden" or skin.id == "football_throne")"""

target2 = """\tfor _, child in tableModel:GetChildren() do
\t\tif child:IsA("BasePart") then
\t\t\tif child.Name == seatName then
\t\t\t\tchild.Color = skin.color
\t\t\t\tchild.Material = skin.mat
\t\t\telseif string.find(child.Name, `^{seatName}_Leg`) ~= nil then
\t\t\t\tchild.Transparency = if isStadium then 1 else 0
\t\t\t\tchild.Color = skin.color
\t\t\t\tchild.Material = skin.mat
\t\t\telseif string.find(child.Name, `^{seatName}_Back`) ~= nil then
\t\t\t\tchild.Color = skin.color
\t\t\t\tchild.Material = skin.mat
\t\t\tend
\t\tend
\tend"""

replace2 = """\tfor _, child in tableModel:GetChildren() do
\t\tif child:IsA("BasePart") then
\t\t\tif child.Name == seatName then
\t\t\t\tchild.Color = if isRoyal then Color3.fromRGB(180, 20, 32) else skin.color
\t\t\t\tchild.Material = skin.mat
\t\t\telseif string.find(child.Name, `^{seatName}_Leg`) ~= nil then
\t\t\t\tchild.Transparency = if isStadium then 1 else 0
\t\t\t\tchild.Color = if isRoyal then Color3.fromRGB(255, 195, 30) else skin.color
\t\t\t\tchild.Material = skin.mat
\t\t\telseif string.find(child.Name, `^{seatName}_Back`) ~= nil then
\t\t\t\tchild.Color = if isRoyal then Color3.fromRGB(255, 195, 30) else skin.color
\t\t\t\tchild.Material = skin.mat
\t\t\tend
\t\tend
\tend"""

target3 = """\t\tdecor.Parent = tableModel
\tend
end

local function updateTableSign(session: TableSession)"""

replace3 = """\t\tdecor.Parent = tableModel
\telseif isRoyal and seat then
\t\tlocal decor = Instance.new("Model")
\t\tdecor.Name = seatName .. "_Decor"

\t\tlocal cGold = Color3.fromRGB(255, 195, 30)
\t\tlocal cVelvet = Color3.fromRGB(180, 20, 32)
\t\tlocal cRuby = Color3.fromRGB(255, 30, 50)
\t\tlocal cWhite = Color3.fromRGB(255, 255, 255)
\t\tlocal cBlack = Color3.fromRGB(20, 20, 22)
\t\tlocal seatCF = seat.CFrame

\t\tlocal function addDecorPart(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?, shape: Enum.PartType?): Part
\t\t\tlocal p = Instance.new("Part")
\t\t\tp.Name = name
\t\t\tp.Size = size
\t\t\tp.CFrame = cf
\t\t\tp.Color = col
\t\t\tp.Material = mat or Enum.Material.SmoothPlastic
\t\t\tp.Anchored = true
\t\t\tp.CanCollide = false
\t\t\tp.CastShadow = false
\t\t\tif shape then
\t\t\t\tp.Shape = shape
\t\t\tend
\t\t\tp.Parent = decor
\t\t\treturn p
\t\tend

\t\t-- Gold base foot slabs & front ruby diamond frame
\t\taddDecorPart("BaseSlabL", Vector3.new(0.6, 0.25, 2.0), seatCF * CFrame.new(-1.1, -1.3, 0), cGold)
\t\taddDecorPart("BaseSlabR", Vector3.new(0.6, 0.25, 2.0), seatCF * CFrame.new( 1.1, -1.3, 0), cGold)
\t\taddDecorPart("FrontDiamond", Vector3.new(0.6, 0.6, 0.1), seatCF * CFrame.new(0, 0, -1.05) * CFrame.Angles(0, 0, math.rad(45)), cGold)
\t\taddDecorPart("FrontRuby", Vector3.new(0.3, 0.3, 0.15), seatCF * CFrame.new(0, 0, -1.1) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

\t\t-- Armrest gold caps
\t\taddDecorPart("ArmrestCapL", Vector3.new(0.45, 0.35, 1.6), seatCF * CFrame.new(-1.25, 0.6, 0), cGold)
\t\taddDecorPart("ArmrestCapR", Vector3.new(0.45, 0.35, 1.6), seatCF * CFrame.new( 1.25, 0.6, 0), cGold)

\t\t-- Backrest crown peaks, soccer ball emblem & golden sparkles
\t\tlocal backPart = tableModel:FindFirstChild(seatName .. "_Back") :: BasePart?
\t\tif backPart then
\t\t\tlocal bCF = backPart.CFrame
\t\t\tlocal crownPeaks = {
\t\t\t\t{ -0.6, 0.5, -18 },
\t\t\t\t{ -0.3, 0.8,  -9 },
\t\t\t\t{  0.0, 1.1,   0 },
\t\t\t\t{  0.3, 0.8,   9 },
\t\t\t\t{  0.6, 0.5,  18 },
\t\t\t}
\t\t\tfor idx, cfg in ipairs(crownPeaks) do
\t\t\t\tlocal px, ph, prot = cfg[1], cfg[2], cfg[3]
\t\t\t\taddDecorPart("CrownPeak_" .. idx, Vector3.new(0.28, ph, 0.2), bCF * CFrame.new(px, 1.2 + ph * 0.4, 0) * CFrame.Angles(0, 0, math.rad(prot)), cGold)
\t\t\tend
\t\t\taddDecorPart("CrownRuby", Vector3.new(0.28, 0.28, 0.15), bCF * CFrame.new(0, 1.9, -0.1) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

\t\t\taddDecorPart("EmblemRing", Vector3.new(1.1, 1.1, 0.12), bCF * CFrame.new(0, 0.7, 0.18) * CFrame.Angles(0, 0, math.rad(45)), cGold)
\t\t\taddDecorPart("SoccerBall", Vector3.new(0.85, 0.85, 0.85), bCF * CFrame.new(0, 0.7, 0.18), cWhite, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
\t\t\taddDecorPart("SoccerPatch", Vector3.new(0.25, 0.25, 0.05), bCF * CFrame.new(0, 0.7, 0.62) * CFrame.Angles(0, 0, math.rad(36)), cBlack)

\t\t\tlocal pl = Instance.new("PointLight")
\t\t\tpl.Color = Color3.fromRGB(255, 210, 90)
\t\t\tpl.Brightness = 2.0
\t\t\tpl.Range = 12
\t\t\tpl.Parent = backPart

\t\t\tlocal att = Instance.new("Attachment")
\t\t\tatt.Parent = backPart
\t\t\tlocal sparkles = Instance.new("ParticleEmitter")
\t\t\tsparkles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 180, 20))
\t\t\tsparkles.LightEmission = 1
\t\t\tsparkles.Size = NumberSequence.new(0.35, 0.05)
\t\t\tsparkles.Lifetime = NumberRange.new(0.8, 1.8)
\t\t\tsparkles.Rate = 8
\t\t\tsparkles.Speed = NumberRange.new(0.6, 1.5)
\t\t\tsparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
\t\t\tsparkles.Parent = att
\t\tend

\t\tdecor.Parent = tableModel
\tend
end

local function updateTableSign(session: TableSession)"""

crlf = '\r\n' in text
text_norm = text.replace('\r\n', '\n')
target1_norm = target1.replace('\r\n', '\n')
replace1_norm = replace1.replace('\r\n', '\n')
target2_norm = target2.replace('\r\n', '\n')
replace2_norm = replace2.replace('\r\n', '\n')
target3_norm = target3.replace('\r\n', '\n')
replace3_norm = replace3.replace('\r\n', '\n')

assert target1_norm in text_norm, 'target1 not found'
text_norm = text_norm.replace(target1_norm, replace1_norm, 1)

assert target2_norm in text_norm, 'target2 not found'
text_norm = text_norm.replace(target2_norm, replace2_norm, 1)

assert target3_norm in text_norm, 'target3 not found'
text_norm = text_norm.replace(target3_norm, replace3_norm, 1)

if crlf:
    text_norm = text_norm.replace('\n', '\r\n')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text_norm)

print("SUCCESS: MatchService patched")

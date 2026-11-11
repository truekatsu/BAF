with open('src/ServerScriptService/Server/MatchService.luau', 'r', encoding='utf-8') as f:
    text = f.read()

target = """local function applyChairSkin(tableModel: Model, seatName: string, player: Player?)
\tlocal profile = if player then ProfileService.get(player) else nil
\tlocal skin = GameConfig.getChairSkin(if profile then profile.EquippedChair else "wood")
\tfor _, child in tableModel:GetChildren() do
\t\tif child:IsA("BasePart") and (child.Name == seatName or string.find(child.Name, `^{seatName}_`) ~= nil) then
\t\t\tchild.Color = skin.color
\t\t\tchild.Material = skin.mat
\t\tend
\tend
end"""

replacement = """local function applyChairSkin(tableModel: Model, seatName: string, player: Player?)
\tlocal profile = if player then ProfileService.get(player) else nil
\tlocal skin = GameConfig.getChairSkin(if profile then profile.EquippedChair else "wood")
\tlocal seat = tableModel:FindFirstChild(seatName) :: Seat?

\tlocal oldDecor = tableModel:FindFirstChild(seatName .. "_Decor")
\tif oldDecor then
\t\toldDecor:Destroy()
\tend

\tlocal isStadium = (skin.id == "stadium")

\tfor _, child in tableModel:GetChildren() do
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
\tend

\tif isStadium and seat then
\t\tlocal decor = Instance.new("Model")
\t\tdecor.Name = seatName .. "_Decor"

\t\tlocal darkBase = Color3.fromHex("#242C38")
\t\tlocal darkStud = Color3.fromHex("#2B3442")
\t\tlocal blueRib = Color3.fromHex("#2879FF")
\t\tlocal seatCF = seat.CFrame

\t\tlocal function addDecorPart(name: string, size: Vector3, cf: CFrame, col: Color3): Part
\t\t\tlocal p = Instance.new("Part")
\t\t\tp.Name = name
\t\t\tp.Size = size
\t\t\tp.CFrame = cf
\t\t\tp.Color = col
\t\t\tp.Material = Enum.Material.SmoothPlastic
\t\t\tp.Anchored = true
\t\t\tp.CanCollide = false
\t\t\tp.CastShadow = false
\t\t\tp.Parent = decor
\t\t\treturn p
\t\tend

\t\tlocal function addDecorCylinder(name: string, len: number, rad: number, cf: CFrame, col: Color3): Part
\t\t\tlocal p = Instance.new("Part")
\t\t\tp.Name = name
\t\t\tp.Shape = Enum.PartType.Cylinder
\t\t\tp.Size = Vector3.new(len, rad * 2, rad * 2)
\t\t\tp.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
\t\t\tp.Color = col
\t\t\tp.Material = Enum.Material.SmoothPlastic
\t\t\tp.Anchored = true
\t\t\tp.CanCollide = false
\t\t\tp.CastShadow = false
\t\t\tp.Parent = decor
\t\t\treturn p
\t\tend

\t\tlocal floorY = seatCF.Position.Y - 1.45
\t\tlocal centerXZ = Vector3.new(seatCF.Position.X, floorY, seatCF.Position.Z)
\t\tlocal baseCF = (seatCF - seatCF.Position) + centerXZ

\t\taddDecorPart("BasePlate", Vector3.new(1.8, 0.3, 1.8), baseCF * CFrame.new(0, 0.15, 0), darkBase)
\t\tlocal sDist = 0.5
\t\taddDecorCylinder("Stud_1", 0.14, 0.22, baseCF * CFrame.new(-sDist, 0.35, -sDist), darkStud)
\t\taddDecorCylinder("Stud_2", 0.14, 0.22, baseCF * CFrame.new( sDist, 0.35, -sDist), darkStud)
\t\taddDecorCylinder("Stud_3", 0.14, 0.22, baseCF * CFrame.new(-sDist, 0.35,  sDist), darkStud)
\t\taddDecorCylinder("Stud_4", 0.14, 0.22, baseCF * CFrame.new( sDist, 0.35,  sDist), darkStud)
\t\taddDecorPart("CenterPost", Vector3.new(0.6, 1.1, 0.6), baseCF * CFrame.new(0, 0.85, 0), darkBase)

\t\tlocal backPart = tableModel:FindFirstChild(seatName .. "_Back") :: BasePart?
\t\tif backPart then
\t\t\tlocal bCF = backPart.CFrame
\t\t\taddDecorPart("RibLeft", Vector3.new(0.4, 1.6, 0.08), bCF * CFrame.new(-0.45, 0, 0.18), blueRib)
\t\t\taddDecorPart("RibRight", Vector3.new(0.4, 1.6, 0.08), bCF * CFrame.new(0.45, 0, 0.18), blueRib)
\t\tend

\t\tdecor.Parent = tableModel
\tend
end"""

assert target in text, "Target applyChairSkin not found in MatchService.luau"
text = text.replace(target, replacement, 1)

with open('src/ServerScriptService/Server/MatchService.luau', 'w', encoding='utf-8') as f:
    f.write(text)

print("MatchService.luau updated successfully!")

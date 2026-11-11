with open('src/ServerScriptService/Server/MatchService.luau', 'rb') as f:
    content = f.read()

target = b'''\tlocal isStadium = (skin.id == "stadium")'''

replacement = b'''\tlocal isStadium = (skin.id == "stadium")\r
\tlocal isCrimson = (skin.id == "crimson")'''

assert target in content, 'target 1 not found'
content = content.replace(target, replacement, 1)

target2 = b'''\t\tdecor.Parent = tableModel\r
\tend\r
end'''

replacement2 = b'''\t\tdecor.Parent = tableModel\r
\telseif isCrimson and seat then\r
\t\tlocal decor = Instance.new("Model")\r
\t\tdecor.Name = seatName .. "_Decor"\r
\r
\t\tlocal darkIron = Color3.fromRGB(30, 24, 28)\r
\t\tlocal neonRed = Color3.fromRGB(255, 40, 50)\r
\t\tlocal seatCF = seat.CFrame\r
\r
\t\tlocal function addDecorPart(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?): Part\r
\t\t\tlocal p = Instance.new("Part")\r
\t\t\tp.Name = name\r
\t\t\tp.Size = size\r
\t\t\tp.CFrame = cf\r
\t\t\tp.Color = col\r
\t\t\tp.Material = mat or Enum.Material.Slate\r
\t\t\tp.Anchored = true\r
\t\t\tp.CanCollide = false\r
\t\t\tp.CastShadow = false\r
\t\t\tp.Parent = decor\r
\t\t\treturn p\r
\t\tend\r
\r
\t\tfor _, cx in { -1, 1 } do\r
\t\t\tfor _, cz in { -1, 1 } do\r
\t\t\t\tlocal cornerPos = seatCF * CFrame.new(cx * 1.8, 0.38, cz * 1.8)\r
\t\t\t\taddDecorPart("BracketX", Vector3.new(0.8, 0.1, 0.25), cornerPos, darkIron)\r
\t\t\t\taddDecorPart("BracketZ", Vector3.new(0.25, 0.1, 0.8), cornerPos, darkIron)\r
\t\t\t\taddDecorPart("Gem", Vector3.new(0.22, 0.22, 0.08), cornerPos * CFrame.new(0, 0.08, 0) * CFrame.Angles(0, math.rad(45), 0), neonRed, Enum.Material.Neon)\r
\t\t\tend\r
\t\tend\r
\r
\t\tfor _, lx in { -1.6, 1.6 } do\r
\t\t\tfor _, lz in { -1.6, 1.6 } do\r
\t\t\t\tlocal legBasePos = seatCF * CFrame.new(lx, -2.6, lz)\r
\t\t\t\tlocal cap = addDecorPart("IronCap", Vector3.new(0.95, 0.4, 0.95), legBasePos, darkIron)\r
\t\t\t\tlocal att = Instance.new("Attachment")\r
\t\t\t\tatt.Name = "FireAtt"\r
\t\t\t\tatt.Position = Vector3.zero\r
\t\t\t\tatt.Parent = cap\r
\r
\t\t\t\tlocal emitter = Instance.new("ParticleEmitter")\r
\t\t\t\temitter.Name = "TableFireEmitter"\r
\t\t\t\temitter.Texture = "rbxassetid://253188733"\r
\t\t\t\temitter.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(120, 0, 10))\r
\t\t\t\temitter.LightEmission = 1\r
\t\t\t\temitter.LightInfluence = 0\r
\t\t\t\temitter.Size = NumberSequence.new(1.2, 0)\r
\t\t\t\temitter.Lifetime = NumberRange.new(0.6, 1.2)\r
\t\t\t\temitter.Rate = 12\r
\t\t\t\temitter.Speed = NumberRange.new(1.5, 3)\r
\t\t\t\temitter.SpreadAngle = Vector2.new(15, 15)\r
\t\t\t\temitter.Acceleration = Vector3.new(0, 5, 0)\r
\t\t\t\temitter.Transparency = NumberSequence.new(0.2, 1)\r
\t\t\t\temitter.Parent = att\r
\t\t\tend\r
\t\tend\r
\r
\t\tdecor.Parent = tableModel\r
\tend\r
end'''

assert target2 in content, 'target 2 not found'
content = content.replace(target2, replacement2, 1)

with open('src/ServerScriptService/Server/MatchService.luau', 'wb') as f:
    f.write(content)

print('Successfully patched MatchService.luau with crimson decor!')

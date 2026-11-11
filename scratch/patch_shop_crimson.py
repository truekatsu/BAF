with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'rb') as f:
    content = f.read()

old_chair_data = b'crimson = { name = "Crimson Striker", color = Color3.fromRGB(229, 37, 42), legColor = Color3.fromRGB(140, 20, 25), mat = Enum.Material.SmoothPlastic },'
new_chair_data = b'crimson = { name = "Crimson Striker", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },'

assert old_chair_data in content, 'old_chair_data not found'
content = content.replace(old_chair_data, new_chair_data, 1)

old_crimson_block = b'''\telseif skinId == "crimson" then\r
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), Color3.fromRGB(255, 215, 0))\r
\t\tlocal wingCol = Color3.fromRGB(175, 25, 30)\r
\t\tmakePart("WingL", Vector3.new(0.25, 0.55, 0.28), CFrame.new(-0.92, 2.05, -0.62), wingCol)\r
\t\tmakePart("WingR", Vector3.new(0.25, 0.55, 0.28), CFrame.new(0.92, 2.05, -0.62), wingCol)\r
\t\tlocal wCol = Color3.fromRGB(255, 255, 255)\r
\t\tmakePart("Chev1", Vector3.new(0.50, 0.25, 0.03), CFrame.new(0, 2.05, -0.47), wCol)\r
\t\tmakePart("Chev2", Vector3.new(0.34, 0.25, 0.03), CFrame.new(0, 1.80, -0.47), wCol)\r
\t\tmakePart("Chev3", Vector3.new(0.18, 0.25, 0.03), CFrame.new(0, 1.55, -0.47), wCol)\r
\t\tmakePart("Chev4", Vector3.new(0.08, 0.20, 0.03), CFrame.new(0, 1.32, -0.47), wCol)'''

stadium_end = b'''\t\tmakePart("BackRecess", Vector3.new(1.38, 1.28, 0.02), backrestCF * CFrame.new(0, 0, -0.13), blueShadow)\r
\t\treturn model\r
\tend'''

new_crimson_section = b'''\t\tmakePart("BackRecess", Vector3.new(1.38, 1.28, 0.02), backrestCF * CFrame.new(0, 0, -0.13), blueShadow)\r
\t\treturn model\r
\tend\r
\r
\tif skinId == "crimson" then\r
\t\tlocal cWood = Color3.fromRGB(150, 15, 25)\r
\t\tlocal cLeg = Color3.fromRGB(110, 10, 20)\r
\t\tlocal cIron = Color3.fromRGB(30, 24, 28)\r
\t\tlocal cGem = Color3.fromRGB(255, 40, 50)\r
\t\tlocal cEmblem = Color3.fromRGB(40, 10, 15)\r
\r
\t\tlocal seatPart = makePart("Seat", Vector3.new(1.6, 0.28, 1.6), CFrame.new(0, 1.14, 0), cWood, Enum.Material.WoodPlanks)\r
\t\tmodel.PrimaryPart = seatPart\r
\r
\t\tlocal seatEmblem = Instance.new("Decal")\r
\t\tseatEmblem.Name = "FlameEmblem_Seat"\r
\t\tseatEmblem.Face = Enum.NormalId.Top\r
\t\tseatEmblem.Texture = "rbxassetid://83629576036526"\r
\t\tseatEmblem.Color3 = cEmblem\r
\t\tseatEmblem.Transparency = 0.6\r
\t\tseatEmblem.Parent = seatPart\r
\r
\t\tlocal legOffsets = {\r
\t\t\tFL = Vector3.new(-0.64, 0.50, -0.64),\r
\t\t\tFR = Vector3.new( 0.64, 0.50, -0.64),\r
\t\t\tBL = Vector3.new(-0.64, 0.50,  0.64),\r
\t\t\tBR = Vector3.new( 0.64, 0.50,  0.64),\r
\t\t}\r
\t\tfor tag, offset in legOffsets do\r
\t\t\tmakePart("Leg_" .. tag, Vector3.new(0.32, 1.0, 0.32), CFrame.new(offset), cLeg, Enum.Material.WoodPlanks)\r
\t\t\tmakePart("LegCap_" .. tag, Vector3.new(0.38, 0.20, 0.38), CFrame.new(offset.X, 0.10, offset.Z), cIron, Enum.Material.Slate)\r
\t\tend\r
\r
\t\tmakePart("Post_Left", Vector3.new(0.32, 2.0, 0.32), CFrame.new(-0.64, 2.28, 0.64), cWood, Enum.Material.WoodPlanks)\r
\t\tmakePart("Post_Right", Vector3.new(0.32, 2.0, 0.32), CFrame.new( 0.64, 2.28, 0.64), cWood, Enum.Material.WoodPlanks)\r
\t\tmakePart("PostCap_Left", Vector3.new(0.38, 0.20, 0.38), CFrame.new(-0.64, 3.28, 0.64), cIron, Enum.Material.Slate)\r
\t\tmakePart("PostCap_Right", Vector3.new(0.38, 0.20, 0.38), CFrame.new( 0.64, 3.28, 0.64), cIron, Enum.Material.Slate)\r
\r
\t\tlocal backrest = makePart("BackrestPanel", Vector3.new(1.28, 1.20, 0.16), CFrame.new(0, 2.04, 0.64), cWood, Enum.Material.WoodPlanks)\r
\t\tlocal backEmblem = Instance.new("Decal")\r
\t\tbackEmblem.Name = "FlameEmblem_Backrest"\r
\t\tbackEmblem.Face = Enum.NormalId.Front\r
\t\tbackEmblem.Texture = "rbxassetid://83629576036526"\r
\t\tbackEmblem.Color3 = cEmblem\r
\t\tbackEmblem.Transparency = 0.6\r
\t\tbackEmblem.Parent = backrest\r
\r
\t\tlocal cornerDirs = {\r
\t\t\tFL = { -1, -1 },\r
\t\t\tFR = {  1, -1 },\r
\t\t\tBL = { -1,  1 },\r
\t\t\tBR = {  1,  1 },\r
\t\t}\r
\t\tfor tag, d in cornerDirs do\r
\t\t\tlocal cx, cz = d[1], d[2]\r
\t\t\tmakePart("CornerBracket_X_" .. tag, Vector3.new(0.34, 0.05, 0.11), CFrame.new(cx * (0.8 - 0.17), 1.30, cz * (0.8 - 0.055)), cIron, Enum.Material.Slate)\r
\t\t\tmakePart("CornerBracket_Z_" .. tag, Vector3.new(0.11, 0.05, 0.34), CFrame.new(cx * (0.8 - 0.055), 1.30, cz * (0.8 - 0.17)), cIron, Enum.Material.Slate)\r
\t\t\tmakePart("Gem_Corner_" .. tag, Vector3.new(0.10, 0.10, 0.04), CFrame.new(cx * 0.72, 1.33, cz * 0.72) * CFrame.Angles(0, math.rad(45), 0), cGem, Enum.Material.Neon)\r
\t\tend\r
\r
\t\tmakePart("Gem_PostCap_L_Front", Vector3.new(0.09, 0.09, 0.03), CFrame.new(-0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)\r
\t\tmakePart("Gem_PostCap_R_Front", Vector3.new( 0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)\r
\t\tmakePart("Gem_PostCap_L_Top",   Vector3.new(0.09, 0.09, 0.03), CFrame.new(-0.64, 3.39, 0.64) * CFrame.Angles(0, math.rad(45), 0), cGem, Enum.Material.Neon)\r
\t\tmakePart("Gem_PostCap_R_Top",   Vector3.new(0.09, 0.09, 0.03), CFrame.new( 0.64, 3.39, 0.64) * CFrame.Angles(0, math.rad(45), 0), cGem, Enum.Material.Neon)\r
\r
\t\treturn model\r
\tend'''

assert stadium_end in content, 'stadium_end not found'
assert old_crimson_block in content, 'old_crimson_block not found'

content = content.replace(stadium_end, new_crimson_section, 1)
content = content.replace(old_crimson_block, b'', 1)

with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'wb') as f:
    f.write(content)

print('Successfully patched ShopDailyUI.luau!')

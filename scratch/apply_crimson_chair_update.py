"""
apply_crimson_chair_update.py
Replaces Emerald Pitch (card in image) with Crimson Flame Chair:
- Name: "Crimson Chair"
- Price: 6000 BUX
- Removes previous emerald pitch model from buildChairModel
- Updates GameConfig, ShopDailyUI, MatchService, ChairModelBuilder, SelfTest
"""

import os

# 1. Patch GameConfig.luau
gc_path = r"d:\BAF\src\ReplicatedStorage\Shared\GameConfig.luau"
with open(gc_path, "r", encoding="utf-8") as f:
    gc_text = f.read()

old_emerald_skin = '{ id = "emerald", name = "Emerald Pitch", cost = 1000, color = Color3.fromHex("#22C55E"), mat = Enum.Material.Neon },'
new_crimson_skin = '{ id = "crimson", name = "Crimson Chair", cost = 6000, color = Color3.fromRGB(150, 15, 25), mat = Enum.Material.WoodPlanks },'

assert old_emerald_skin in gc_text, "old_emerald_skin not found in GameConfig.luau"
gc_text = gc_text.replace(old_emerald_skin, new_crimson_skin, 1)

old_get_chair = """\tif chairId == "crimson" then
\t\tfor _, skin in GameConfig.CHAIR_SKINS do
\t\t\tif skin.id == "cyber_core" then
\t\t\t\treturn skin
\t\t\tend
\t\tend
\tend"""

new_get_chair = """\tif chairId == "emerald" then
\t\tfor _, skin in GameConfig.CHAIR_SKINS do
\t\t\tif skin.id == "crimson" then
\t\t\t\treturn skin
\t\t\tend
\t\tend
\tend"""

assert old_get_chair in gc_text, "old_get_chair not found in GameConfig.luau"
gc_text = gc_text.replace(old_get_chair, new_get_chair, 1)

with open(gc_path, "w", encoding="utf-8") as f:
    f.write(gc_text)
print("GameConfig.luau successfully patched with Crimson Chair (6000 BUX)!")


# 2. Patch ShopDailyUI.luau
shop_path = r"d:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau"
with open(shop_path, "r", encoding="utf-8") as f:
    shop_text = f.read()

# Update CHAIR_DATA
old_cd = """\tcyber_core = { name = "Cyber Core Chair", color = Color3.fromRGB(18, 20, 32), legColor = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },
\tcrimson = { name = "Cyber Core Chair", color = Color3.fromRGB(18, 20, 32), legColor = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },
\temerald = { name = "Emerald Pitch", color = Color3.fromRGB(34, 197, 94), legColor = Color3.fromRGB(20, 110, 50), mat = Enum.Material.SmoothPlastic },"""

new_cd = """\tcyber_core = { name = "Cyber Core Chair", color = Color3.fromRGB(18, 20, 32), legColor = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },
\tcrimson = { name = "Crimson Chair", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },
\temerald = { name = "Crimson Chair", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },"""

assert old_cd in shop_text, "old_cd not found in ShopDailyUI.luau"
shop_text = shop_text.replace(old_cd, new_cd, 1)

# In buildChairModel:
shop_text = shop_text.replace('if skinId == "cyber_core" or skinId == "crimson" then', 'if skinId == "cyber_core" then', 1)

# Replace old emerald model block (lines 716-720) with Crimson Flame Chair model
old_emerald_block = """\telseif skinId == "emerald" then
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), Color3.fromRGB(255, 255, 255))
\t\tmakePart("PitchLine", Vector3.new(0.05, 1.35, 0.03), CFrame.new(0, 1.62, -0.47), Color3.fromRGB(255, 255, 255))
\t\tmakeCylinder("CircleOuter", 0.04, 0.32, CFrame.new(0, 1.62, -0.47), Color3.fromRGB(255, 255, 255))
\t\tmakeCylinder("CircleInner", 0.05, 0.25, CFrame.new(0, 1.62, -0.47), info.color, info.mat)"""

new_crimson_block = """\telseif skinId == "crimson" or skinId == "emerald" then
\t\tlocal cWood = Color3.fromRGB(150, 15, 25)
\t\tlocal cLeg = Color3.fromRGB(110, 10, 20)
\t\tlocal cIron = Color3.fromRGB(30, 24, 28)
\t\tlocal cGem = Color3.fromRGB(255, 40, 50)
\t\tlocal cEmblem = Color3.fromRGB(40, 10, 15)

\t\t-- 4 Legs & Dark Iron Caps with Gems
\t\tlocal legOffsets = {
\t\t\tFL = Vector3.new(-0.64, 0.50, -0.64),
\t\t\tFR = Vector3.new( 0.64, 0.50, -0.64),
\t\t\tBL = Vector3.new(-0.64, 0.50,  0.64),
\t\t\tBR = Vector3.new( 0.64, 0.50,  0.64),
\t\t}
\t\tfor tag, offset in legOffsets do
\t\t\tmakePart("Leg_" .. tag, Vector3.new(0.32, 1.0, 0.32), CFrame.new(offset), cLeg, Enum.Material.WoodPlanks)
\t\t\tmakePart("LegCap_" .. tag, Vector3.new(0.38, 0.20, 0.38), CFrame.new(offset.X, 0.10, offset.Z), cIron, Enum.Material.Slate)
\t\t\tmakePart("Gem_LegCap_" .. tag, Vector3.new(0.10, 0.10, 0.03), CFrame.new(offset.X, 0.10, offset.Z - 0.20) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
\t\tend

\t\t-- Backrest Posts & Caps with Gems
\t\tmakePart("Post_Left", Vector3.new(0.32, 2.0, 0.32), CFrame.new(-0.64, 2.28, 0.64), cWood, Enum.Material.WoodPlanks)
\t\tmakePart("Post_Right", Vector3.new(0.32, 2.0, 0.32), CFrame.new( 0.64, 2.28, 0.64), cWood, Enum.Material.WoodPlanks)
\t\tmakePart("PostCap_Left", Vector3.new(0.38, 0.20, 0.38), CFrame.new(-0.64, 3.28, 0.64), cIron, Enum.Material.Slate)
\t\tmakePart("PostCap_Right", Vector3.new(0.38, 0.20, 0.38), CFrame.new( 0.64, 3.28, 0.64), cIron, Enum.Material.Slate)
\t\tmakePart("Gem_PostCap_L", Vector3.new(0.10, 0.10, 0.03), CFrame.new(-0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
\t\tmakePart("Gem_PostCap_R", Vector3.new( 0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)

\t\t-- Backrest Panel with Flame Emblem
\t\tlocal backrest = makePart("BackrestPanel", Vector3.new(1.28, 1.40, 0.16), CFrame.new(0, 2.14, 0.64), cWood, Enum.Material.WoodPlanks)
\t\tlocal backEmblem = Instance.new("Decal")
\t\tbackEmblem.Name = "FlameEmblem_Backrest"
\t\tbackEmblem.Face = Enum.NormalId.Front
\t\tbackEmblem.Texture = "rbxassetid://90165853329906"
\t\tbackEmblem.Color3 = cEmblem
\t\tbackEmblem.Transparency = 0.2
\t\tbackEmblem.Parent = backrest

\t\t-- Seat Corner Brackets & Gems
\t\tfor tag, d in { FL = { -1, -1 }, FR = { 1, -1 }, BL = { -1, 1 }, BR = { 1, 1 } } do
\t\t\tlocal cx, cz = d[1], d[2]
\t\t\tmakePart("CornerBracket_X_" .. tag, Vector3.new(0.34, 0.05, 0.11), CFrame.new(cx * (0.8 - 0.17), 1.05, cz * (0.8 - 0.055)), cIron, Enum.Material.Slate)
\t\t\tmakePart("CornerBracket_Z_" .. tag, Vector3.new(0.11, 0.05, 0.34), CFrame.new(cx * (0.8 - 0.055), 1.05, cz * (0.8 - 0.17)), cIron, Enum.Material.Slate)
\t\t\tmakePart("Gem_Corner_" .. tag, Vector3.new(0.10, 0.10, 0.04), CFrame.new(cx * 0.72, 1.08, cz * 0.72) * CFrame.Angles(0, math.rad(45), 0), cGem, Enum.Material.Neon)
\t\tend"""

assert old_emerald_block in shop_text, "old_emerald_block not found in ShopDailyUI.luau"
shop_text = shop_text.replace(old_emerald_block, new_crimson_block, 1)

with open(shop_path, "w", encoding="utf-8") as f:
    f.write(shop_text)
print("ShopDailyUI.luau successfully patched with Crimson Flame Chair preview!")


# 3. Patch MatchService.luau
match_path = r"d:\BAF\src\ServerScriptService\Server\MatchService.luau"
with open(match_path, "r", encoding="utf-8") as f:
    match_text = f.read()

old_flags = """\tlocal isCyberCore = (skin.id == "cyber_core" or skin.id == "crimson")
\tlocal isCrimson = false"""

new_flags = """\tlocal isCyberCore = (skin.id == "cyber_core")
\tlocal isCrimson = (skin.id == "crimson" or skin.id == "emerald")"""

assert old_flags in match_text, "old_flags not found in MatchService.luau"
match_text = match_text.replace(old_flags, new_flags, 1)

old_end_cyber = """\t\tdecor.Parent = tableModel
\tend
end"""

new_end_both = """\t\tdecor.Parent = tableModel
\telseif isCrimson and seat then
\t\tlocal decor = Instance.new("Model")
\t\tdecor.Name = seatName .. "_Decor"

\t\tlocal darkIron = Color3.fromRGB(30, 24, 28)
\t\tlocal neonRed = Color3.fromRGB(255, 40, 50)
\t\tlocal seatCF = seat.CFrame

\t\tlocal function addDecorPart(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?): Part
\t\t\tlocal p = Instance.new("Part")
\t\t\tp.Name = name
\t\t\tp.Size = size
\t\t\tp.CFrame = cf
\t\t\tp.Color = col
\t\t\tp.Material = mat or Enum.Material.Slate
\t\t\tp.Anchored = true
\t\t\tp.CanCollide = false
\t\t\tp.CastShadow = false
\t\t\tp.Parent = decor
\t\t\treturn p
\t\tend

\t\tfor _, cx in { -1, 1 } do
\t\t\tfor _, cz in { -1, 1 } do
\t\t\t\tlocal cornerPos = seatCF * CFrame.new(cx * 1.8, 0.38, cz * 1.8)
\t\t\t\taddDecorPart("BracketX", Vector3.new(0.8, 0.1, 0.25), cornerPos, darkIron)
\t\t\t\taddDecorPart("BracketZ", Vector3.new(0.25, 0.1, 0.8), cornerPos, darkIron)
\t\t\t\taddDecorPart("Gem", Vector3.new(0.22, 0.22, 0.08), cornerPos * CFrame.new(0, 0.08, 0) * CFrame.Angles(0, math.rad(45), 0), neonRed, Enum.Material.Neon)
\t\t\tend
\t\tend

\t\tfor _, lx in { -1.6, 1.6 } do
\t\t\tfor _, lz in { -1.6, 1.6 } do
\t\t\t\tlocal legBasePos = seatCF * CFrame.new(lx, -2.6, lz)
\t\t\t\tlocal cap = addDecorPart("IronCap", Vector3.new(0.95, 0.4, 0.95), legBasePos, darkIron)
\t\t\t\tlocal att = Instance.new("Attachment")
\t\t\t\tatt.Name = "FireAtt"
\t\t\t\tatt.Position = Vector3.zero
\t\t\t\tatt.Parent = cap

\t\t\t\tlocal emitter = Instance.new("ParticleEmitter")
\t\t\t\temitter.Name = "TableFireEmitter"
\t\t\t\temitter.Texture = "rbxassetid://253188732"
\t\t\t\temitter.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(120, 0, 10))
\t\t\t\temitter.LightEmission = 1
\t\t\t\temitter.LightInfluence = 0
\t\t\t\temitter.Size = NumberSequence.new(1.2, 0)
\t\t\t\temitter.Lifetime = NumberRange.new(0.6, 1.2)
\t\t\t\temitter.Rate = 12
\t\t\t\temitter.Speed = NumberRange.new(1.5, 3)
\t\t\t\temitter.SpreadAngle = Vector2.new(15, 15)
\t\t\t\temitter.Acceleration = Vector3.new(0, 5, 0)
\t\t\t\temitter.Transparency = NumberSequence.new(0.2, 1)
\t\t\t\temitter.Parent = att
\t\t\tend
\t\tend

\t\tdecor.Parent = tableModel
\tend
end"""

assert old_end_cyber in match_text, "old_end_cyber not found in MatchService.luau"
match_text = match_text.replace(old_end_cyber, new_end_both, 1)

with open(match_path, "w", encoding="utf-8") as f:
    f.write(match_text)
print("MatchService.luau successfully patched with both Cyber Core and Crimson table decors!")


# 4. Patch ChairModelBuilder.luau
builder_path = r"d:\BAF\src\ReplicatedStorage\Prefabs\ChairModelBuilder.luau"
with open(builder_path, "r", encoding="utf-8") as f:
    builder_text = f.read()

old_dispatch = """\tlocal key = string.lower(chairType)
\tif key == "cyber_core" or key == "cybercore" or key == "crimson" or key == "crimsonflame" or key == "crimsonflamechair" then
\t\t-- Replaces previous crimson chair with Cyber Core Chair
\t\treturn ChairModelBuilder.buildCyberCoreChair(cfOffset)"""

new_dispatch = """\tlocal key = string.lower(chairType)
\tif key == "crimson" or key == "crimson_chair" or key == "crimsonchair" or key == "crimsonflame" or key == "crimsonflamechair" or key == "emerald" then
\t\treturn ChairModelBuilder.buildCrimsonFlameChair(cfOffset)
\telseif key == "cyber_core" or key == "cybercore" or key == "cyber" or key == "cybercorechair" then
\t\treturn ChairModelBuilder.buildCyberCoreChair(cfOffset)"""

assert old_dispatch in builder_text, "old_dispatch not found in ChairModelBuilder.luau"
builder_text = builder_text.replace(old_dispatch, new_dispatch, 1)

with open(builder_path, "w", encoding="utf-8") as f:
    f.write(builder_text)
print("ChairModelBuilder.luau dispatch updated!")


# 5. Patch SelfTest.luau
test_path = r"d:\BAF\src\ReplicatedStorage\Shared\SelfTest.luau"
with open(test_path, "r", encoding="utf-8") as f:
    test_text = f.read()

old_test = '\tassert(GameConfig.getChairSkin("crimson").name == "Cyber Core Chair", "crimson alias must resolve to Cyber Core Chair")'
new_test = """\tassert(GameConfig.getChairSkin("crimson").name == "Crimson Chair" and GameConfig.getChairSkin("crimson").cost == 6000, "Crimson Chair must exist and cost 6000 Bux")
\tassert(GameConfig.getChairSkin("emerald").name == "Crimson Chair", "emerald alias must resolve to Crimson Chair")"""

assert old_test in test_text, "old_test not found in SelfTest.luau"
test_text = test_text.replace(old_test, new_test, 1)

with open(test_path, "w", encoding="utf-8") as f:
    f.write(test_text)
print("SelfTest.luau successfully patched with Crimson Chair 6000 BUX test!")

print("All updates completed successfully!")

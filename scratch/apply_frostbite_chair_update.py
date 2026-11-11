"""
apply_frostbite_chair_update.py
Replaces Neon Cyber (card in image) with Frostbite Chair:
- Name: "Frostbite Chair"
- Price: 10000 BUX
- Removes previous Neon Cyber model from buildChairModel
- Updates GameConfig, ShopDailyUI, MatchService, ChairModelBuilder, ProfileService, SelfTest
"""

import os

# 1. Patch GameConfig.luau
gc_path = r"d:\BAF\src\ReplicatedStorage\Shared\GameConfig.luau"
with open(gc_path, "r", encoding="utf-8") as f:
    gc_text = f.read()

old_cyber_skin = '{ id = "cyber", name = "Neon Cyber", cost = 2000, color = Color3.fromHex("#A855F7"), mat = Enum.Material.Neon },'
new_frost_skin = '{ id = "frostbite", name = "Frostbite Chair", cost = 10000, color = Color3.fromRGB(120, 210, 255), mat = Enum.Material.Glass },'

assert old_cyber_skin in gc_text, "old_cyber_skin not found in GameConfig.luau"
gc_text = gc_text.replace(old_cyber_skin, new_frost_skin, 1)

# Wheel segment
old_wheel = '{ id = 4, label = "GRAND\\nPRIZE", icon = "🪑", color = "#C85A6E", weight = 8, bux = 500, chair = "cyber", toast = "🎡 JACKPOT! Neon Cyber Chair + $500!" },'
new_wheel = '{ id = 4, label = "GRAND\\nPRIZE", icon = "🪑", color = "#C85A6E", weight = 8, bux = 500, chair = "frostbite", toast = "🎡 JACKPOT! Frostbite Chair + $500!" },'
if old_wheel in gc_text:
    gc_text = gc_text.replace(old_wheel, new_wheel, 1)

# getChairSkin alias
old_get_chair = """\tif chairId == "emerald" then
\t\tfor _, skin in GameConfig.CHAIR_SKINS do
\t\t\tif skin.id == "crimson" then
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
\tend
\tif chairId == "cyber" then
\t\tfor _, skin in GameConfig.CHAIR_SKINS do
\t\t\tif skin.id == "frostbite" then
\t\t\t\treturn skin
\t\t\tend
\t\tend
\tend"""

assert old_get_chair in gc_text, "old_get_chair not found in GameConfig.luau"
gc_text = gc_text.replace(old_get_chair, new_get_chair, 1)

with open(gc_path, "w", encoding="utf-8") as f:
    f.write(gc_text)
print("GameConfig.luau successfully patched with Frostbite Chair (10000 BUX)!")


# 2. Patch ShopDailyUI.luau
shop_path = r"d:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau"
with open(shop_path, "r", encoding="utf-8") as f:
    shop_text = f.read()

# Update CHAIR_DATA
old_cd = '\tcyber = { name = "Neon Cyber", color = Color3.fromRGB(168, 85, 247), legColor = Color3.fromRGB(90, 40, 140), mat = Enum.Material.SmoothPlastic },'
new_cd = (
    '\tfrostbite = { name = "Frostbite Chair", color = Color3.fromRGB(120, 210, 255), legColor = Color3.fromRGB(60, 150, 230), mat = Enum.Material.Glass },\n'
    '\tcyber = { name = "Frostbite Chair", color = Color3.fromRGB(120, 210, 255), legColor = Color3.fromRGB(60, 150, 230), mat = Enum.Material.Glass },'
)

assert old_cd in shop_text, "old_cd not found in ShopDailyUI.luau"
shop_text = shop_text.replace(old_cd, new_cd, 1)

# Replace old cyber model block with Frostbite Chair preview model
old_cyber_block = """\telseif skinId == "cyber" then
\t\tlocal cCol = Color3.fromRGB(0, 240, 255)
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), cCol, Enum.Material.Neon)
\t\tmakePart("Trace1", Vector3.new(0.40, 0.06, 0.03), CFrame.new(-0.25, 1.95, -0.47), cCol, Enum.Material.Neon)
\t\tmakePart("TraceDiag", Vector3.new(0.35, 0.06, 0.03), CFrame.new(0.06, 1.83, -0.47) * CFrame.Angles(0, 0, math.rad(-38)), cCol, Enum.Material.Neon)
\t\tmakePart("Trace2", Vector3.new(0.25, 0.06, 0.03), CFrame.new(0.28, 1.71, -0.47), cCol, Enum.Material.Neon)
\t\tmakeCylinder("Node1", 0.04, 0.09, CFrame.new(-0.45, 1.95, -0.47), cCol, Enum.Material.Neon)
\t\tmakeCylinder("Node2", 0.04, 0.08, CFrame.new(0.40, 1.71, -0.47), cCol, Enum.Material.Neon)
\t\tmakePart("CyberAccent", Vector3.new(0.28, 0.08, 0.03), CFrame.new(0, 1.25, -0.47), cCol, Enum.Material.Neon)"""

new_frost_block = """\telseif skinId == "frostbite" or skinId == "cyber" then
\t\tlocal cDeep = Color3.fromRGB(60, 150, 230)
\t\tlocal cMain = Color3.fromRGB(120, 210, 255)
\t\tlocal cGlow = Color3.fromRGB(160, 240, 255)
\t\tlocal cSnow = Color3.fromRGB(245, 250, 255)
\t\tlocal cGem = Color3.fromRGB(100, 235, 255)

\t\t-- Seat Cushion Recess
\t\tmakePart("SeatRecess", Vector3.new(1.3, 0.08, 1.2), CFrame.new(0, 0.96, 0.05), cMain, Enum.Material.Glass)

\t\t-- 3 Front Chevron Plates
\t\tfor i = 0, 2 do
\t\t\tlocal yOff = 0.88 - (i * 0.18)
\t\t\tmakePart("Chevron_L_" .. i, Vector3.new(0.45, 0.10, 0.06), CFrame.new(-0.22, yOff, 0.76) * CFrame.Angles(0, 0, math.rad(-22)), cGlow, Enum.Material.Neon)
\t\t\tmakePart("Chevron_R_" .. i, Vector3.new(0.45, 0.10, 0.06), CFrame.new( 0.22, yOff, 0.76) * CFrame.Angles(0, 0, math.rad( 22)), cGlow, Enum.Material.Neon)
\t\tend

\t\t-- 4 Chipped Foot Blocks
\t\tfor _, lx in { -0.60, 0.60 } do
\t\t\tfor _, lz in { -0.55, 0.55 } do
\t\t\t\tmakePart("FootBlock", Vector3.new(0.36, 0.22, 0.36), CFrame.new(lx, 0.11, lz), cMain, Enum.Material.Glass)
\t\t\tend
\t\tend

\t\t-- 2 Armrests with Snow Caps & Icicles
\t\tfor _, ax in { -0.80, 0.80 } do
\t\t\tmakePart("Armrest", Vector3.new(0.24, 0.24, 1.25), CFrame.new(ax, 1.15, 0), cDeep, Enum.Material.Glass)
\t\t\tmakePart("SnowCap", Vector3.new(0.28, 0.08, 1.25), CFrame.new(ax, 1.30, 0), cSnow, Enum.Material.SmoothPlastic)
\t\t\tfor ic = 0, 2 do
\t\t\t\tmakePart("Icicle", Vector3.new(0.04, 0.20, 0.04), CFrame.new(ax, 0.95 - ic * 0.03, -0.4 + ic * 0.4), cGlow, Enum.Material.Glass)
\t\t\tend
\t\tend

\t\t-- 5 Backrest Chevrons
\t\tfor i = 0, 4 do
\t\t\tlocal yOff = 1.15 + (i * 0.24)
\t\t\tlocal w = 0.55 - (i * 0.06)
\t\t\tmakePart("BackChevron_L_" .. i, Vector3.new(w, 0.08, 0.04), CFrame.new(-w * 0.45, yOff, -0.47) * CFrame.Angles(0, 0, math.rad(-26)), cMain, Enum.Material.Glass)
\t\t\tmakePart("BackChevron_R_" .. i, Vector3.new(w, 0.08, 0.04), CFrame.new( w * 0.45, yOff, -0.47) * CFrame.Angles(0, 0, math.rad( 26)), cMain, Enum.Material.Glass)
\t\tend

\t\t-- Crown Fan of 7 Crystal Shards
\t\tlocal shards = {
\t\t\t{ -0.65, 1.2, -28, 0.14 },
\t\t\t{ -0.42, 1.6, -18, 0.16 },
\t\t\t{ -0.20, 1.9,  -8, 0.18 },
\t\t\t{  0.00, 2.1,   0, 0.20 }, -- Center
\t\t\t{  0.20, 1.9,   8, 0.18 },
\t\t\t{  0.42, 1.6,  18, 0.16 },
\t\t\t{  0.65, 1.2,  28, 0.14 },
\t\t}
\t\tfor idx, cfg in ipairs(shards) do
\t\t\tlocal sx, sh, srot, sw = cfg[1], cfg[2], cfg[3], cfg[4]
\t\t\tmakePart("Shard_" .. idx, Vector3.new(sw, sh, sw), CFrame.new(sx, 1.8 + sh * 0.4, -0.62) * CFrame.Angles(0, 0, math.rad(srot)), cGlow, Enum.Material.Neon)
\t\tend

\t\t-- Center Top Diamond Crystal Gem
\t\tmakePart("TopGem", Vector3.new(0.36, 0.52, 0.22), CFrame.new(0, 2.95, -0.58) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)"""

assert old_cyber_block in shop_text, "old_cyber_block not found in ShopDailyUI.luau"
shop_text = shop_text.replace(old_cyber_block, new_frost_block, 1)

with open(shop_path, "w", encoding="utf-8") as f:
    f.write(shop_text)
print("ShopDailyUI.luau successfully patched with Frostbite Chair preview!")


# 3. Patch MatchService.luau
match_path = r"d:\BAF\src\ServerScriptService\Server\MatchService.luau"
with open(match_path, "r", encoding="utf-8") as f:
    match_text = f.read()

old_flags = """\tlocal isCyberCore = (skin.id == "cyber_core")
\tlocal isCrimson = (skin.id == "crimson" or skin.id == "emerald")"""

new_flags = """\tlocal isCyberCore = (skin.id == "cyber_core")
\tlocal isCrimson = (skin.id == "crimson" or skin.id == "emerald")
\tlocal isFrostbite = (skin.id == "frostbite" or skin.id == "cyber")"""

assert old_flags in match_text, "old_flags not found in MatchService.luau"
match_text = match_text.replace(old_flags, new_flags, 1)

# Add isFrostbite decor after isCrimson decor
old_end_crimson = """\t\tdecor.Parent = tableModel
\tend
end"""

new_end_all = """\t\tdecor.Parent = tableModel
\telseif isFrostbite and seat then
\t\tlocal decor = Instance.new("Model")
\t\tdecor.Name = seatName .. "_Decor"

\t\tlocal cDeep = Color3.fromRGB(60, 150, 230)
\t\tlocal cGlow = Color3.fromRGB(160, 240, 255)
\t\tlocal seatCF = seat.CFrame

\t\tlocal function addDecorPart(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?): Part
\t\t\tlocal p = Instance.new("Part")
\t\t\tp.Name = name
\t\t\tp.Size = size
\t\t\tp.CFrame = cf
\t\t\tp.Color = col
\t\t\tp.Material = mat or Enum.Material.Glass
\t\t\tp.Anchored = true
\t\t\tp.CanCollide = false
\t\t\tp.CastShadow = false
\t\t\tp.Parent = decor
\t\t\treturn p
\t\tend

\t\t-- Ice chevron plates on front
\t\taddDecorPart("IceChevronL", Vector3.new(0.9, 0.2, 0.1), seatCF * CFrame.new(-0.45, 0.1, -1.05) * CFrame.Angles(0, 0, math.rad(-20)), cGlow, Enum.Material.Neon)
\t\taddDecorPart("IceChevronR", Vector3.new(0.9, 0.2, 0.1), seatCF * CFrame.new( 0.45, 0.1, -1.05) * CFrame.Angles(0, 0, math.rad( 20)), cGlow, Enum.Material.Neon)

\t\t-- Hanging icicles under seat edge
\t\tfor i = 0, 3 do
\t\t\taddDecorPart("Icicle_" .. i, Vector3.new(0.08, 0.4, 0.08), seatCF * CFrame.new(-0.75 + i * 0.5, -0.3, -1.05), cGlow, Enum.Material.Glass)
\t\tend

\t\t-- Top crystal shard on backrest
\t\tlocal backPart = tableModel:FindFirstChild(seatName .. "_Back") :: BasePart?
\t\tif backPart then
\t\t\tlocal bCF = backPart.CFrame
\t\t\tlocal gem = addDecorPart("IceGem", Vector3.new(0.5, 0.7, 0.3), bCF * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(45)), cGlow, Enum.Material.Neon)
\t\t\t
\t\t\tlocal pl = Instance.new("PointLight")
\t\t\tpl.Color = Color3.fromRGB(140, 230, 255)
\t\t\tpl.Brightness = 2.0
\t\t\tpl.Range = 12
\t\t\tpl.Parent = gem

\t\t\tlocal att = Instance.new("Attachment")
\t\t\tatt.Parent = gem
\t\t\tlocal mist = Instance.new("ParticleEmitter")
\t\t\tmist.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255), Color3.fromRGB(255, 255, 255))
\t\t\tmist.LightEmission = 0.8
\t\t\tmist.Size = NumberSequence.new(0.6, 0.1)
\t\t\tmist.Lifetime = NumberRange.new(0.8, 1.6)
\t\t\tmist.Rate = 10
\t\t\tmist.Speed = NumberRange.new(0.6, 1.5)
\t\t\tmist.Parent = att
\t\tend

\t\tdecor.Parent = tableModel
\tend
end"""

assert old_end_crimson in match_text, "old_end_crimson not found in MatchService.luau"
match_text = match_text.replace(old_end_crimson, new_end_all, 1)

with open(match_path, "w", encoding="utf-8") as f:
    f.write(match_text)
print("MatchService.luau successfully patched with Frostbite table decor!")


# 4. Patch ChairModelBuilder.luau
builder_path = r"d:\BAF\src\ReplicatedStorage\Prefabs\ChairModelBuilder.luau"
with open(builder_path, "r", encoding="utf-8") as f:
    builder_text = f.read()

old_dispatch = """\telseif key == "cyber_core" or key == "cybercore" or key == "cyber" or key == "cybercorechair" then
\t\treturn ChairModelBuilder.buildCyberCoreChair(cfOffset)
\telseif key == "cyber" or key == "cybercore" or key == "cybercorechair" then
\t\treturn ChairModelBuilder.buildCyberCoreChair(cfOffset)
\telseif key == "frostbite" or key == "frost" or key == "frostbitethrone" or key == "frostbiteicethrone" then
\t\treturn ChairModelBuilder.buildFrostbiteThrone(cfOffset)"""

new_dispatch = """\telseif key == "cyber_core" or key == "cybercore" or key == "cybercorechair" then
\t\treturn ChairModelBuilder.buildCyberCoreChair(cfOffset)
\telseif key == "frostbite" or key == "frost" or key == "frostbitethrone" or key == "frostbitechair" or key == "frostchair" or key == "cyber" then
\t\treturn ChairModelBuilder.buildFrostbiteThrone(cfOffset)"""

assert old_dispatch in builder_text, "old_dispatch not found in ChairModelBuilder.luau"
builder_text = builder_text.replace(old_dispatch, new_dispatch, 1)

with open(builder_path, "w", encoding="utf-8") as f:
    f.write(builder_text)
print("ChairModelBuilder.luau dispatch updated!")


# 5. Patch ProfileService.luau
profile_path = r"d:\BAF\src\ServerScriptService\Server\ProfileService.luau"
with open(profile_path, "r", encoding="utf-8") as f:
    profile_text = f.read()

old_prof_migration = """\tif data.EquippedChair == "emerald" then
\t\tdata.EquippedChair = "crimson"
\tend"""

new_prof_migration = """\tif data.EquippedChair == "emerald" then
\t\tdata.EquippedChair = "crimson"
\tend
\tif data.OwnedChairs["cyber"] and not data.OwnedChairs["frostbite"] then
\t\tdata.OwnedChairs["frostbite"] = true
\tend
\tif data.EquippedChair == "cyber" then
\t\tdata.EquippedChair = "frostbite"
\tend"""

assert old_prof_migration in profile_text, "old_prof_migration not found in ProfileService.luau"
profile_text = profile_text.replace(old_prof_migration, new_prof_migration, 1)

with open(profile_path, "w", encoding="utf-8") as f:
    f.write(profile_text)
print("ProfileService.luau successfully patched with Frostbite Chair migration!")


# 6. Patch SelfTest.luau
test_path = r"d:\BAF\src\ReplicatedStorage\Shared\SelfTest.luau"
with open(test_path, "r", encoding="utf-8") as f:
    test_text = f.read()

old_test = """\tassert(GameConfig.getChairSkin("crimson").name == "Crimson Chair" and GameConfig.getChairSkin("crimson").cost == 6000, "Crimson Chair must exist and cost 6000 Bux")
\tassert(GameConfig.getChairSkin("emerald").name == "Crimson Chair", "emerald alias must resolve to Crimson Chair")"""

new_test = """\tassert(GameConfig.getChairSkin("crimson").name == "Crimson Chair" and GameConfig.getChairSkin("crimson").cost == 6000, "Crimson Chair must exist and cost 6000 Bux")
\tassert(GameConfig.getChairSkin("emerald").name == "Crimson Chair", "emerald alias must resolve to Crimson Chair")
\tassert(GameConfig.getChairSkin("frostbite").name == "Frostbite Chair" and GameConfig.getChairSkin("frostbite").cost == 10000, "Frostbite Chair must exist and cost 10000 Bux")
\tassert(GameConfig.getChairSkin("cyber").name == "Frostbite Chair", "cyber alias must resolve to Frostbite Chair")"""

assert old_test in test_text, "old_test not found in SelfTest.luau"
test_text = test_text.replace(old_test, new_test, 1)

with open(test_path, "w", encoding="utf-8") as f:
    f.write(test_text)
print("SelfTest.luau successfully patched with Frostbite Chair 10000 BUX test!")

print("All updates completed successfully!")

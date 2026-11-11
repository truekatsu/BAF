"""
apply_cyber_core_update.py
Replaces the Crimson Striker model with Cyber Core Chair:
- Name: "Cyber Core Chair"
- Price: 3500 BUX
- Removes previous crimson model so it does not overlap or conflict
"""

import os

# 1. Patch ShopDailyUI.luau
shop_path = r"d:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau"
with open(shop_path, "rb") as f:
    shop_content = f.read()

# Replace CHAIR_DATA
old_chair_data = b'\tcrimson = { name = "Crimson Striker", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },'
new_chair_data = (
    b'\tcyber_core = { name = "Cyber Core Chair", color = Color3.fromRGB(18, 20, 32), legColor = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },\r\n'
    b'\tcrimson = { name = "Cyber Core Chair", color = Color3.fromRGB(18, 20, 32), legColor = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },'
)
assert old_chair_data in shop_content, "old_chair_data not found in ShopDailyUI.luau"
shop_content = shop_content.replace(old_chair_data, new_chair_data, 1)

# Replace the crimson model block with the cyber core chair block
start_marker = b'\tif skinId == "crimson" then\r\n'
end_marker = b'\t\treturn model\r\n\tend\r\n\r\n\t-- Base Geometry: Seat, Backrest, Rounded Top Cap'

idx_start = shop_content.find(start_marker)
idx_end = shop_content.find(end_marker)
assert idx_start != -1 and idx_end != -1, "Crimson block markers not found in ShopDailyUI.luau"

new_cyber_block = b'''\tif skinId == "cyber_core" or skinId == "crimson" then
\t\tlocal cMetal = Color3.fromRGB(18, 20, 32)
\t\tlocal cCap = Color3.fromRGB(35, 40, 60)
\t\tlocal cCyan = Color3.fromRGB(0, 255, 240)
\t\tlocal cMagenta = Color3.fromRGB(255, 0, 200)

\t\tlocal seatPart = makePart("Seat", Vector3.new(1.6, 0.28, 1.6), CFrame.new(0, 1.14, 0), cMetal, Enum.Material.Metal)
\t\tmodel.PrimaryPart = seatPart

\t\t-- Glowing circuit traces on seat
\t\tmakePart("SeatCircuitX1", Vector3.new(1.5, 0.04, 0.06), CFrame.new(0, 1.29, -0.72), cCyan, Enum.Material.Neon)
\t\tmakePart("SeatCircuitX2", Vector3.new(1.5, 0.04, 0.06), CFrame.new(0, 1.29,  0.72), cCyan, Enum.Material.Neon)
\t\tmakePart("SeatCircuitZ1", Vector3.new(0.06, 0.04, 1.4), CFrame.new(-0.72, 1.29, 0), cMagenta, Enum.Material.Neon)
\t\tmakePart("SeatCircuitZ2", Vector3.new(0.06, 0.04, 1.4), CFrame.new( 0.72, 1.29, 0), cMagenta, Enum.Material.Neon)
\t\tmakePart("SeatChipCenter", Vector3.new(0.48, 0.03, 0.48), CFrame.new(0, 1.29, 0) * CFrame.Angles(0, math.rad(45), 0), cCyan, Enum.Material.Neon)

\t\t-- 4 Legs & Caps
\t\tlocal legOffsets = {
\t\t\tFL = Vector3.new(-0.64, 0.50, -0.64),
\t\t\tFR = Vector3.new( 0.64, 0.50, -0.64),
\t\t\tBL = Vector3.new(-0.64, 0.50,  0.64),
\t\t\tBR = Vector3.new( 0.64, 0.50,  0.64),
\t\t}
\t\tfor tag, offset in legOffsets do
\t\t\tmakePart("Leg_" .. tag, Vector3.new(0.32, 1.0, 0.32), CFrame.new(offset), cMetal, Enum.Material.Metal)
\t\t\tmakePart("LegTrace_" .. tag, Vector3.new(0.05, 0.95, 0.05), CFrame.new(offset.X, 0.50, offset.Z - 0.15), cCyan, Enum.Material.Neon)
\t\t\tmakePart("LegCap_" .. tag, Vector3.new(0.38, 0.20, 0.38), CFrame.new(offset.X, 0.10, offset.Z), cCap, Enum.Material.Metal)
\t\t\tmakePart("Gem_LegCap_" .. tag, Vector3.new(0.10, 0.10, 0.03), CFrame.new(offset.X, 0.10, offset.Z - 0.20) * CFrame.Angles(0, 0, math.rad(45)), cMagenta, Enum.Material.Neon)
\t\tend

\t\t-- Backrest Posts & Caps
\t\tmakePart("Post_Left", Vector3.new(0.32, 2.0, 0.32), CFrame.new(-0.64, 2.28, 0.64), cMetal, Enum.Material.Metal)
\t\tmakePart("Post_Right", Vector3.new(0.32, 2.0, 0.32), CFrame.new( 0.64, 2.28, 0.64), cMetal, Enum.Material.Metal)
\t\tmakePart("PostTrace_Left", Vector3.new(0.05, 1.9, 0.05), CFrame.new(-0.64, 2.28, 0.47), cMagenta, Enum.Material.Neon)
\t\tmakePart("PostTrace_Right", Vector3.new(0.05, 1.9, 0.05), CFrame.new( 0.64, 2.28, 0.47), cMagenta, Enum.Material.Neon)
\t\tmakePart("PostCap_Left", Vector3.new(0.38, 0.20, 0.38), CFrame.new(-0.64, 3.28, 0.64), cCap, Enum.Material.Metal)
\t\tmakePart("PostCap_Right", Vector3.new(0.38, 0.20, 0.38), CFrame.new( 0.64, 3.28, 0.64), cCap, Enum.Material.Metal)
\t\tmakePart("Gem_PostCap_L_Front", Vector3.new(0.10, 0.10, 0.03), CFrame.new(-0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cCyan, Enum.Material.Neon)
\t\tmakePart("Gem_PostCap_R_Front", Vector3.new( 0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cCyan, Enum.Material.Neon)

\t\t-- Backrest Panel & Hex Frame
\t\tmakePart("BackrestPanel", Vector3.new(1.28, 1.40, 0.16), CFrame.new(0, 2.14, 0.64), cMetal, Enum.Material.Metal)

\t\tlocal hexR = 0.34
\t\tfor i = 0, 5 do
\t\t\tlocal rad = math.rad(i * 60)
\t\t\tlocal hx = math.cos(rad) * hexR
\t\t\tlocal hy = math.sin(rad) * hexR
\t\t\tmakePart("HexStrut_" .. i, Vector3.new(0.18, 0.04, 0.05), CFrame.new(hx, 2.14 + hy, 0.54) * CFrame.Angles(0, 0, rad + math.rad(30)), cMagenta, Enum.Material.Neon)
\t\tend

\t\t-- Energy Core (floating rotating gem)
\t\tmakePart("EnergyCore", Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 2.14, 0.54) * CFrame.Angles(math.rad(45), math.rad(45), 0), cCyan, Enum.Material.Neon)

\t\treturn model
\tend\r\n\r\n\t-- Base Geometry: Seat, Backrest, Rounded Top Cap'''.replace(b'\n', b'\r\n')

shop_content = shop_content[:idx_start] + new_cyber_block + shop_content[idx_end + len(end_marker):]

with open(shop_path, "wb") as f:
    f.write(shop_content)
print("ShopDailyUI.luau successfully patched with Cyber Core Chair preview!")

# 2. Patch MatchService.luau table decor
match_path = r"d:\BAF\src\ServerScriptService\Server\MatchService.luau"
with open(match_path, "rb") as f:
    match_content = f.read()

# Replace isCrimson with isCyberCore
old_is_crimson = b'\tlocal isCrimson = (skin.id == "crimson")'
new_is_cyber = (
    b'\tlocal isCyberCore = (skin.id == "cyber_core" or skin.id == "crimson")\r\n'
    b'\tlocal isCrimson = false'
)
if old_is_crimson in match_content:
    match_content = match_content.replace(old_is_crimson, new_is_cyber, 1)

# Replace table decor block for crimson with cyber core decor
old_crimson_decor = b'\telseif isCrimson and seat then\r\n'
idx_c = match_content.find(old_crimson_decor)
if idx_c != -1:
    end_decor = b'\t\tdecor.Parent = tableModel\r\n\tend\r\nend'
    idx_end_c = match_content.find(end_decor, idx_c)
    assert idx_end_c != -1, "end_decor not found in MatchService.luau"

    new_cyber_decor = b'''\telseif isCyberCore and seat then
\t\tlocal decor = Instance.new("Model")
\t\tdecor.Name = seatName .. "_Decor"

\t\tlocal cMetal = Color3.fromRGB(18, 20, 32)
\t\tlocal cCyan = Color3.fromRGB(0, 255, 240)
\t\tlocal cMagenta = Color3.fromRGB(255, 0, 200)
\t\tlocal seatCF = seat.CFrame

\t\tlocal function addDecorPart(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?): Part
\t\t\tlocal p = Instance.new("Part")
\t\t\tp.Name = name
\t\t\tp.Size = size
\t\t\tp.CFrame = cf
\t\t\tp.Color = col
\t\t\tp.Material = mat or Enum.Material.Metal
\t\t\tp.Anchored = true
\t\t\tp.CanCollide = false
\t\t\tp.CastShadow = false
\t\t\tp.Parent = decor
\t\t\treturn p
\t\tend

\t\t-- Seat border neon circuit traces
\t\taddDecorPart("CircuitX1", Vector3.new(2.1, 0.06, 0.08), seatCF * CFrame.new(0, 0.22, -1.05), cCyan, Enum.Material.Neon)
\t\taddDecorPart("CircuitX2", Vector3.new(2.1, 0.06, 0.08), seatCF * CFrame.new(0, 0.22,  1.05), cCyan, Enum.Material.Neon)
\t\taddDecorPart("CircuitZ1", Vector3.new(0.08, 0.06, 2.1), seatCF * CFrame.new(-1.05, 0.22, 0), cMagenta, Enum.Material.Neon)
\t\taddDecorPart("CircuitZ2", Vector3.new(0.08, 0.06, 2.1), seatCF * CFrame.new( 1.05, 0.22, 0), cMagenta, Enum.Material.Neon)

\t\t-- Leg caps & magenta light
\t\tfor _, lx in { -0.85, 0.85 } do
\t\t\tfor _, lz in { -0.85, 0.85 } do
\t\t\t\tlocal legBase = seatCF * CFrame.new(lx, -0.7, lz)
\t\t\t\tlocal cap = addDecorPart("CyberCap", Vector3.new(0.42, 0.22, 0.42), legBase, cMetal)
\t\t\t\taddDecorPart("CapGem", Vector3.new(0.12, 0.12, 0.04), legBase * CFrame.new(0, 0, -0.22) * CFrame.Angles(0, 0, math.rad(45)), cMagenta, Enum.Material.Neon)
\t\t\tend
\t\tend

\t\t-- Backrest neon accent & digital spark emitter
\t\tlocal backPart = tableModel:FindFirstChild(seatName .. "_Back") :: BasePart?
\t\tif backPart then
\t\t\tlocal bCF = backPart.CFrame
\t\t\taddDecorPart("CoreTrace", Vector3.new(0.08, 2.0, 0.08), bCF * CFrame.new(0, 0, 0.18), cCyan, Enum.Material.Neon)
\t\t\tlocal core = addDecorPart("MiniCore", Vector3.new(0.4, 0.4, 0.4), bCF * CFrame.new(0, 0.4, 0.22) * CFrame.Angles(math.rad(45), math.rad(45), 0), cCyan, Enum.Material.Neon)
\t\t\t
\t\t\tlocal pl = Instance.new("PointLight")
\t\t\tpl.Color = cCyan
\t\t\tpl.Brightness = 2.0
\t\t\tpl.Range = 10
\t\t\tpl.Parent = core

\t\t\tlocal att = Instance.new("Attachment")
\t\t\tatt.Parent = core
\t\t\tlocal sparks = Instance.new("ParticleEmitter")
\t\t\tsparks.Color = ColorSequence.new(cCyan, cMagenta)
\t\t\tsparks.LightEmission = 1
\t\t\tsparks.Size = NumberSequence.new(0.4, 0.05)
\t\t\tsparks.Lifetime = NumberRange.new(0.6, 1.2)
\t\t\tsparks.Rate = 10
\t\t\tsparks.Speed = NumberRange.new(1, 2.5)
\t\t\tsparks.Parent = att
\t\tend

\t\tdecor.Parent = tableModel
\tend
end'''.replace(b'\n', b'\r\n')

    match_content = match_content[:idx_c] + new_cyber_decor + match_content[idx_end_c + len(end_decor):]

    with open(match_path, "wb") as f:
        f.write(match_content)
    print("MatchService.luau successfully patched with Cyber Core table decor!")

# 3. Patch ChairModelBuilder.luau
builder_path = r"d:\BAF\src\ReplicatedStorage\Prefabs\ChairModelBuilder.luau"
with open(builder_path, "rb") as f:
    builder_content = f.read()

old_dispatch = b'''\tlocal key = string.lower(chairType)
\tif key == "crimson" or key == "crimsonflame" or key == "crimsonflamechair" then
\t\treturn ChairModelBuilder.buildCrimsonFlameChair(cfOffset)'''

new_dispatch = b'''\tlocal key = string.lower(chairType)
\tif key == "cyber_core" or key == "cybercore" or key == "crimson" or key == "crimsonflame" or key == "crimsonflamechair" then
\t\t-- Replaces previous crimson chair with Cyber Core Chair
\t\treturn ChairModelBuilder.buildCyberCoreChair(cfOffset)'''

if old_dispatch in builder_content:
    builder_content = builder_content.replace(old_dispatch, new_dispatch, 1)
    with open(builder_path, "wb") as f:
        f.write(builder_content)
    print("ChairModelBuilder.luau successfully updated dispatch to Cyber Core Chair!")

# 4. Patch ProfileService.luau
profile_path = r"d:\BAF\src\ServerScriptService\Server\ProfileService.luau"
with open(profile_path, "rb") as f:
    profile_content = f.read()

old_starter = b'''\t\tprofile.OwnedChairs["crimson"] = true
\t\tprofile.EquippedChair = "crimson"
\t\tsyncLeaderstats(player, profile, "Starter Pack Unlocked: +$500 Bux & Crimson Chair!")'''

new_starter = b'''\t\tprofile.OwnedChairs["cyber_core"] = true
\t\tprofile.OwnedChairs["crimson"] = true
\t\tprofile.EquippedChair = "cyber_core"
\t\tsyncLeaderstats(player, profile, "Starter Pack Unlocked: +$500 Bux & Cyber Core Chair!")'''

if old_starter in profile_content:
    profile_content = profile_content.replace(old_starter, new_starter, 1)
    with open(profile_path, "wb") as f:
        f.write(profile_content)
    print("ProfileService.luau successfully patched starter pack to Cyber Core Chair!")

print("All patches successfully applied!")

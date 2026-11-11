path = r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update CHAIR_DATA
target1 = """\tgolden = { name = \"Golden Ballon d'Or\", color = Color3.fromRGB(255, 210, 31), legColor = Color3.fromRGB(180, 120, 15), mat = Enum.Material.SmoothPlastic },"""
replace1 = """\tgolden = { name = \"Football Throne\", color = Color3.fromRGB(255, 195, 30), legColor = Color3.fromRGB(205, 140, 10), mat = Enum.Material.SmoothPlastic },
\tfootball_throne = { name = \"Football Throne\", color = Color3.fromRGB(255, 195, 30), legColor = Color3.fromRGB(205, 140, 10), mat = Enum.Material.SmoothPlastic },"""

# 2. Add makeSphere helper inside buildChairModel
target2 = """\tlocal function makeCylinder(name: string, length: number, radius: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
\t\tlocal p = Instance.new("Part")
\t\tp.Name = name
\t\tp.Shape = Enum.PartType.Cylinder
\t\tp.Size = Vector3.new(length, radius * 2, radius * 2)
\t\tp.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
\t\tp.Color = color
\t\tp.Material = mat or Enum.Material.SmoothPlastic
\t\tp.Anchored = true
\t\tp.CanCollide = false
\t\tp.CastShadow = false
\t\tp.Parent = model
\t\treturn p
\tend"""

replace2 = """\tlocal function makeCylinder(name: string, length: number, radius: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
\t\tlocal p = Instance.new("Part")
\t\tp.Name = name
\t\tp.Shape = Enum.PartType.Cylinder
\t\tp.Size = Vector3.new(length, radius * 2, radius * 2)
\t\tp.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
\t\tp.Color = color
\t\tp.Material = mat or Enum.Material.SmoothPlastic
\t\tp.Anchored = true
\t\tp.CanCollide = false
\t\tp.CastShadow = false
\t\tp.Parent = model
\t\treturn p
\tend

\tlocal function makeSphere(name: string, diameter: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
\t\tlocal p = makePart(name, Vector3.new(diameter, diameter, diameter), cf, color, mat)
\t\tp.Shape = Enum.PartType.Ball
\t\treturn p
\tend"""

# 3. Add standalone Royal Football Throne branch (so base chair parts are never built)
target3 = """\t\t-- Energy Core (floating rotating gem)
\t\tmakePart("EnergyCore", Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 2.14, 0.54) * CFrame.Angles(math.rad(45), math.rad(45), 0), cCyan, Enum.Material.Neon)

\t\treturn model
\tend



\t-- Base Geometry: Seat, Backrest, Rounded Top Cap"""

replace3 = """\t\t-- Energy Core (floating rotating gem)
\t\tmakePart("EnergyCore", Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 2.14, 0.54) * CFrame.Angles(math.rad(45), math.rad(45), 0), cCyan, Enum.Material.Neon)

\t\treturn model
\tend

\tif skinId == "golden" or skinId == "football_throne" then
\t\tlocal cGold = Color3.fromRGB(255, 195, 30)
\t\tlocal cVelvet = Color3.fromRGB(180, 20, 32)
\t\tlocal cDark = Color3.fromRGB(30, 24, 22)
\t\tlocal cRuby = Color3.fromRGB(255, 30, 50)
\t\tlocal cWhite = Color3.fromRGB(255, 255, 255)
\t\tlocal cBlack = Color3.fromRGB(20, 20, 22)

\t\t-- 1. Base Foot Slabs, Pillars & Red Inset Panels
\t\tfor _, tag in { "Left", "Right" } do
\t\t\tlocal bx = if tag == "Left" then -0.62 else 0.62
\t\t\tmakePart("FootSlab_" .. tag, Vector3.new(0.48, 0.18, 1.2), CFrame.new(bx, 0.09, 0), cGold)
\t\t\tmakePart("Pillar_" .. tag, Vector3.new(0.40, 0.62, 0.90), CFrame.new(bx, 0.49, 0), cGold)
\t\t\tmakePart("PillarPanel_" .. tag, Vector3.new(0.28, 0.46, 0.04), CFrame.new(bx, 0.49, -0.46), cVelvet)
\t\tend
\t\tmakePart("UndersideHollow", Vector3.new(0.72, 0.54, 0.90), CFrame.new(0, 0.45, 0), cDark)

\t\t-- 2. Seat Frame & Red Quilted Cushion (Seat)
\t\tmakePart("SeatFrame", Vector3.new(1.65, 0.22, 1.25), CFrame.new(0, 0.88, 0), cGold)
\t\tlocal seatCushion = makePart("SeatCushion", Vector3.new(1.48, 0.28, 1.10), CFrame.new(0, 1.08, 0.04), cVelvet)
\t\tmodel.PrimaryPart = seatCushion

\t\tmakePart("FrontDiamondFrame", Vector3.new(0.46, 0.46, 0.06), CFrame.new(0, 0.88, -0.63) * CFrame.Angles(0, 0, math.rad(45)), cGold)
\t\tmakePart("FrontRubyGem", Vector3.new(0.22, 0.22, 0.08), CFrame.new(0, 0.88, -0.66) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

\t\t-- 3. Chunky Armrests with Inset Panels & Gold Diamond
\t\tfor _, tag in { "Left", "Right" } do
\t\t\tlocal ax = if tag == "Left" then -0.76 else 0.76
\t\t\tmakePart("Armrest_" .. tag, Vector3.new(0.38, 0.45, 1.15), CFrame.new(ax, 1.34, 0), cGold)
\t\t\tmakePart("ArmrestPanel_" .. tag, Vector3.new(0.26, 0.32, 0.04), CFrame.new(ax, 1.34, -0.58), cVelvet)
\t\t\tmakePart("ArmrestGem_" .. tag, Vector3.new(0.12, 0.12, 0.04), CFrame.new(ax, 1.34, -0.60) * CFrame.Angles(0, 0, math.rad(45)), cGold)
\t\tend

\t\t-- 4. Backrest Outer Frame & Wing-Spikes
\t\tmakePart("BackrestFrame", Vector3.new(1.68, 1.95, 0.28), CFrame.new(0, 2.05, 0.52), cGold)
\t\tmakePart("WingSpike_Left", Vector3.new(0.40, 0.65, 0.22), CFrame.new(-0.95, 2.95, 0.52) * CFrame.Angles(0, 0, math.rad(35)), cGold)
\t\tmakePart("WingSpike_Right", Vector3.new(0.40, 0.65, 0.22), CFrame.new( 0.95, 2.95, 0.52) * CFrame.Angles(0, 0, math.rad(-35)), cGold)

\t\t-- 5. Inner Red Quilted Panel & Tuft Buttons
\t\tmakePart("QuiltedPanel", Vector3.new(1.22, 1.48, 0.18), CFrame.new(0, 1.92, 0.42), cVelvet)
\t\tfor row = 0, 2 do
\t\t\tfor col = 0, 2 do
\t\t\t\tlocal bx = (col - 1) * 0.36
\t\t\t\tlocal by = 1.55 + row * 0.37
\t\t\t\tmakeSphere("TuftButton_" .. row .. "_" .. col, 0.11, CFrame.new(bx, by, 0.32), cGold)
\t\t\tend
\t\tend

\t\t-- 6. Soccer Ball & Gold Emblem Ring
\t\tmakePart("EmblemRing", Vector3.new(0.92, 0.92, 0.14), CFrame.new(0, 2.58, 0.40) * CFrame.Angles(0, 0, math.rad(45)), cGold)
\t\tmakeSphere("SoccerBall", 0.68, CFrame.new(0, 2.58, 0.38), cWhite)
\t\tmakePart("SoccerPentagon", Vector3.new(0.18, 0.18, 0.04), CFrame.new(0, 2.58, 0.04) * CFrame.Angles(0, 0, math.rad(36)), cBlack)

\t\t-- 7. 5-Peak Crown with Ruby Gem
\t\tlocal crownPeaks = {
\t\t\t{ -0.42, 0.30, -18 },
\t\t\t{ -0.21, 0.45,  -9 },
\t\t\t{  0.00, 0.60,   0 },
\t\t\t{  0.21, 0.45,   9 },
\t\t\t{  0.42, 0.30,  18 },
\t\t}
\t\tfor idx, cfg in ipairs(crownPeaks) do
\t\t\tlocal px, ph, prot = cfg[1], cfg[2], cfg[3]
\t\t\tmakePart("CrownPeak_" .. idx, Vector3.new(0.18, ph, 0.15), CFrame.new(px, 3.12 + ph * 0.38, 0.42) * CFrame.Angles(0, 0, math.rad(prot)), cGold)
\t\tend
\t\tmakePart("CrownRubyGem", Vector3.new(0.18, 0.18, 0.08), CFrame.new(0, 3.38, 0.33) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

\t\t-- 8. Side Banners
\t\tmakePart("Banner_Left", Vector3.new(0.24, 0.75, 0.04), CFrame.new(-0.96, 2.12, 0.44), cVelvet)
\t\tmakePart("Banner_Right", Vector3.new(0.24, 0.75, 0.04), CFrame.new( 0.96, 2.12, 0.44), cVelvet)
\t\tmakePart("BannerCrown_L", Vector3.new(0.14, 0.10, 0.02), CFrame.new(-0.96, 2.26, 0.42), cGold, Enum.Material.Neon)
\t\tmakePart("BannerCrown_R", Vector3.new(0.14, 0.10, 0.02), CFrame.new( 0.96, 2.26, 0.42), cGold, Enum.Material.Neon)

\t\treturn model
\tend

\t-- Base Geometry: Seat, Backrest, Rounded Top Cap"""

# 4. Remove old golden medallion parts
target4 = """\t\t-- Center Top Diamond Crystal Gem
\t\tmakePart("TopGem", Vector3.new(0.36, 0.52, 0.22), CFrame.new(0, 2.95, -0.58) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
\telseif skinId == "golden" then
\t\tlocal oCol = Color3.fromRGB(240, 150, 0)
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), oCol)
\t\tmakeCylinder("MedallionOuter", 0.04, 0.38, CFrame.new(0, 1.62, -0.47), oCol)
\t\tmakeCylinder("MedallionInner", 0.05, 0.30, CFrame.new(0, 1.62, -0.47), info.color, info.mat)
\t\tlocal sCol = Color3.fromRGB(255, 255, 255)
\t\tmakePart("Star1", Vector3.new(0.28, 0.28, 0.06), CFrame.new(0, 1.62, -0.47) * CFrame.Angles(0, 0, math.rad(45)), sCol, Enum.Material.Neon)
\t\tmakePart("Star2", Vector3.new(0.28, 0.28, 0.06), CFrame.new(0, 1.62, -0.47), sCol, Enum.Material.Neon)
\tend"""

replace4 = """\t\t-- Center Top Diamond Crystal Gem
\t\tmakePart("TopGem", Vector3.new(0.36, 0.52, 0.22), CFrame.new(0, 2.95, -0.58) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
\tend"""

# 5. Replace card display name hardcoding
target5 = """\t\t-- Chair Name at top (warm creamy yellow)
\t\tlocal displayName = if skin.id == "golden" then "Golden Ball" else skin.name"""

replace5 = """\t\t-- Chair Name at top (warm creamy yellow)
\t\tlocal displayName = skin.name"""

crlf = '\r\n' in text
text_norm = text.replace('\r\n', '\n')

for idx, (t, r) in enumerate([(target1, replace1), (target2, replace2), (target3, replace3), (target4, replace4), (target5, replace5)], 1):
    t_n = t.replace('\r\n', '\n')
    r_n = r.replace('\r\n', '\n')
    assert t_n in text_norm, f"Target {idx} not found in ShopDailyUI.luau"
    text_norm = text_norm.replace(t_n, r_n, 1)
    print(f"Target {idx} matched and replaced")

if crlf:
    text_norm = text_norm.replace('\n', '\r\n')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text_norm)

print("SUCCESS: ShopDailyUI.luau patched")

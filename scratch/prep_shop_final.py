import json

with open(r'd:\BAF\scratch\shop_sub_block.txt', 'r', encoding='utf-8') as f:
    sub_block = f.read()

# Edit 1: add makeSphere
old_cyl_end = """\t\tp.Material = mat or Enum.Material.SmoothPlastic
\t\tp.Anchored = true
\t\tp.CanCollide = false
\t\tp.CastShadow = false
\t\tp.Parent = model
\t\treturn p
\tend

\t\tif skinId == "stadium" then"""

new_cyl_end = """\t\tp.Material = mat or Enum.Material.SmoothPlastic
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
\tend

\tif skinId == "stadium" then"""

# Edit 2: replace lines 650-704 with sub_block
# In Studio, lines 647-704:
old_base_geom = """\t\treturn model
\tend

\t-- Base Geometry: Seat, Backrest, Rounded Top Cap
\tmakePart("Seat", Vector3.new(1.6, 0.28, 1.5), CFrame.new(0, 0.8, 0), info.color, info.mat)
\tmakePart("Back", Vector3.new(1.6, 1.45, 0.28), CFrame.new(0, 1.62, -0.62), info.color, info.mat)
\tmakeCylinder("TopCap", 1.6, 0.14, CFrame.new(0, 2.34, -0.62), info.color, info.mat)

\t-- 4 Legs
\tfor _, lx in { -0.60, 0.60 } do
\t\tfor _, lz in { -0.55, 0.55 } do
\t\t\tmakePart("Leg", Vector3.new(0.20, 0.8, 0.20), CFrame.new(lx, 0.4, lz), info.legColor, info.mat)
\t\tend
\tend

\t-- Skin-specific 3D features
\tif skinId == "wood" then
\t\tlocal grooveCol = Color3.fromRGB(75, 42, 24)
\t\tmakePart("Slat1", Vector3.new(0.04, 1.35, 0.02), CFrame.new(-0.27, 1.62, -0.47), grooveCol, Enum.Material.WoodPlanks)
\t\tmakePart("Slat2", Vector3.new(0.04, 1.35, 0.02), CFrame.new(0.27, 1.62, -0.47), grooveCol, Enum.Material.WoodPlanks)
\t\tmakePart("SlatH", Vector3.new(1.5, 0.04, 0.02), CFrame.new(0, 1.62, -0.47), grooveCol, Enum.Material.WoodPlanks)

\telseif skinId == "crimson" then
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), Color3.fromRGB(255, 215, 0))
\t\tlocal wingCol = Color3.fromRGB(175, 25, 30)
\t\tmakePart("WingL", Vector3.new(0.25, 0.55, 0.28), CFrame.new(-0.92, 2.05, -0.62), wingCol)
\t\tmakePart("WingR", Vector3.new(0.25, 0.55, 0.28), CFrame.new(0.92, 2.05, -0.62), wingCol)
\t\tlocal wCol = Color3.fromRGB(255, 255, 255)
\t\tmakePart("Chev1", Vector3.new(0.50, 0.25, 0.03), CFrame.new(0, 2.05, -0.47), wCol)
\t\tmakePart("Chev2", Vector3.new(0.34, 0.25, 0.03), CFrame.new(0, 1.80, -0.47), wCol)
\t\tmakePart("Chev3", Vector3.new(0.18, 0.25, 0.03), CFrame.new(0, 1.55, -0.47), wCol)
\t\tmakePart("Chev4", Vector3.new(0.08, 0.20, 0.03), CFrame.new(0, 1.32, -0.47), wCol)
\telseif skinId == "emerald" then
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), Color3.fromRGB(255, 255, 255))
\t\tmakePart("PitchLine", Vector3.new(0.05, 1.35, 0.03), CFrame.new(0, 1.62, -0.47), Color3.fromRGB(255, 255, 255))
\t\tmakeCylinder("CircleOuter", 0.04, 0.32, CFrame.new(0, 1.62, -0.47), Color3.fromRGB(255, 255, 255))
\t\tmakeCylinder("CircleInner", 0.05, 0.25, CFrame.new(0, 1.62, -0.47), info.color, info.mat)
\telseif skinId == "cyber" then
\t\tlocal cCol = Color3.fromRGB(0, 240, 255)
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), cCol, Enum.Material.Neon)
\t\tmakePart("Trace1", Vector3.new(0.40, 0.06, 0.03), CFrame.new(-0.25, 1.95, -0.47), cCol, Enum.Material.Neon)
\t\tmakePart("TraceDiag", Vector3.new(0.35, 0.06, 0.03), CFrame.new(0.06, 1.83, -0.47) * CFrame.Angles(0, 0, math.rad(-38)), cCol, Enum.Material.Neon)
\t\tmakePart("Trace2", Vector3.new(0.25, 0.06, 0.03), CFrame.new(0.28, 1.71, -0.47), cCol, Enum.Material.Neon)
\t\tmakeCylinder("Node1", 0.04, 0.09, CFrame.new(-0.45, 1.95, -0.47), cCol, Enum.Material.Neon)
\t\tmakeCylinder("Node2", 0.04, 0.08, CFrame.new(0.40, 1.71, -0.47), cCol, Enum.Material.Neon)
\t\tmakePart("CyberAccent", Vector3.new(0.28, 0.08, 0.03), CFrame.new(0, 1.25, -0.47), cCol, Enum.Material.Neon)
\telseif skinId == "golden" then
\t\tlocal oCol = Color3.fromRGB(240, 150, 0)
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), oCol)
\t\tmakeCylinder("MedallionOuter", 0.04, 0.38, CFrame.new(0, 1.62, -0.47), oCol)
\t\tmakeCylinder("MedallionInner", 0.05, 0.30, CFrame.new(0, 1.62, -0.47), info.color, info.mat)
\t\tlocal sCol = Color3.fromRGB(255, 255, 255)
\t\tmakePart("Star1", Vector3.new(0.28, 0.28, 0.06), CFrame.new(0, 1.62, -0.47) * CFrame.Angles(0, 0, math.rad(45)), sCol, Enum.Material.Neon)
\t\tmakePart("Star2", Vector3.new(0.28, 0.28, 0.06), CFrame.new(0, 1.62, -0.47), sCol, Enum.Material.Neon)
\tend

\treturn model
end"""

new_base_geom = "\t\treturn model\n\tend\n\n\t" + sub_block

# Edit 3: Card display name
old_disp_name = '\t\tlocal displayName = if skin.id == "golden" then "Golden Ball" else skin.name'
new_disp_name = '\t\tlocal displayName = skin.name'

args = {
    "studio_id": "d4b5150f-b416-44a9-af38-ab450d8935e5",
    "datamodel_type": "Edit",
    "file_path": "game.StarterPlayer.StarterPlayerScripts.Client.ShopDailyUI",
    "edits": [
        {
            "old_string": old_cyl_end,
            "new_string": new_cyl_end,
            "replace_all": False
        },
        {
            "old_string": old_base_geom,
            "new_string": new_base_geom,
            "replace_all": False
        },
        {
            "old_string": old_disp_name,
            "new_string": new_disp_name,
            "replace_all": False
        }
    ]
}

with open(r'd:\BAF\scratch\shop_args.json', 'w', encoding='utf-8') as f:
    json.dump(args, f)

print("Generated shop_args.json successfully!")

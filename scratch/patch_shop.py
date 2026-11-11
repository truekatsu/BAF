with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    text = f.read()

target = """\t-- Base Geometry: Seat, Backrest, Rounded Top Cap"""

replacement = """\tif skinId == "stadium" then
\t\t-- Lego Stadium Chair matching orthographic reference sheet (pedestal, 2x2 stud base, ribbed backrest)
\t\tlocal blueMain = Color3.fromHex("#1E6FFF")
\t\tlocal blueShadow = Color3.fromHex("#1555C5")
\t\tlocal blueRib = Color3.fromHex("#2879FF")
\t\tlocal darkBase = Color3.fromHex("#242C38")
\t\tlocal darkStud = Color3.fromHex("#2B3442")

\t\tmakePart("BasePlate", Vector3.new(1.40, 0.28, 1.40), CFrame.new(0, 0.24, -0.05), darkBase)
\t\tlocal sDist = 0.38
\t\tmakeCylinder("Stud_FL", 0.12, 0.17, CFrame.new(-sDist, 0.44, -0.05 + sDist), darkStud)
\t\tmakeCylinder("Stud_FR", 0.12, 0.17, CFrame.new( sDist, 0.44, -0.05 + sDist), darkStud)
\t\tmakeCylinder("Stud_BL", 0.12, 0.17, CFrame.new(-sDist, 0.44, -0.05 - sDist), darkStud)
\t\tmakeCylinder("Stud_BR", 0.12, 0.17, CFrame.new( sDist, 0.44, -0.05 - sDist), darkStud)
\t\tmakePart("CenterPost", Vector3.new(0.48, 0.48, 0.48), CFrame.new(0, 0.62, -0.05), darkBase)
\t\tmakePart("SeatBase", Vector3.new(1.62, 0.18, 1.60), CFrame.new(0, 0.95, -0.05), blueMain)
\t\tlocal seatCushion = makePart("SeatCushion", Vector3.new(1.58, 0.22, 1.15), CFrame.new(0, 1.15, 0.18), blueMain)
\t\tmodel.PrimaryPart = seatCushion

\t\tlocal backTiltAngle = math.rad(-8.5)
\t\tlocal backrestCF = CFrame.new(0, 1.82, -0.42) * CFrame.Angles(backTiltAngle, 0, 0)
\t\tmakePart("BackrestSlab", Vector3.new(1.62, 1.52, 0.26), backrestCF, blueMain)
\t\tmakePart("RibBacking", Vector3.new(1.36, 1.30, 0.02), backrestCF * CFrame.new(0, 0, 0.13), blueShadow)
\t\tmakePart("RibLeft", Vector3.new(0.32, 1.26, 0.06), backrestCF * CFrame.new(-0.36, 0, 0.16), blueRib)
\t\tmakePart("RibRight", Vector3.new(0.32, 1.26, 0.06), backrestCF * CFrame.new(0.36, 0, 0.16), blueRib)

\t\tmakePart("BackRimTop", Vector3.new(1.62, 0.12, 0.04), backrestCF * CFrame.new(0, 0.70, -0.15), blueMain)
\t\tmakePart("BackRimBottom", Vector3.new(1.62, 0.12, 0.04), backrestCF * CFrame.new(0, -0.70, -0.15), blueMain)
\t\tmakePart("BackRimLeft", Vector3.new(0.12, 1.28, 0.04), backrestCF * CFrame.new(-0.75, 0, -0.15), blueMain)
\t\tmakePart("BackRimRight", Vector3.new(0.12, 1.28, 0.04), backrestCF * CFrame.new(0.75, 0, -0.15), blueMain)
\t\tmakePart("BackRecess", Vector3.new(1.38, 1.28, 0.02), backrestCF * CFrame.new(0, 0, -0.13), blueShadow)
\t\treturn model
\tend

\t-- Base Geometry: Seat, Backrest, Rounded Top Cap"""

assert target in text, "Target not found in ShopDailyUI.luau"
text = text.replace(target, replacement, 1)

old_stadium = """\telseif skinId == "stadium" then
\t\tmakePart("SeatBar", Vector3.new(1.1, 0.14, 0.05), CFrame.new(0, 0.82, 0.77), Color3.fromRGB(255, 255, 255))
\t\tmakePart("Plaque", Vector3.new(0.68, 0.68, 0.03), CFrame.new(0, 1.78, -0.47), Color3.fromRGB(255, 255, 255))
\t\tlocal bCol = Color3.fromRGB(30, 111, 255)
\t\tmakePart("D1", Vector3.new(0.08, 0.42, 0.03), CFrame.new(-0.13, 1.78, -0.45), bCol)
\t\tmakePart("D1_serif", Vector3.new(0.08, 0.08, 0.03), CFrame.new(-0.16, 1.95, -0.45), bCol)
\t\tmakePart("D0_L", Vector3.new(0.07, 0.42, 0.03), CFrame.new(0.07, 1.78, -0.45), bCol)
\t\tmakePart("D0_R", Vector3.new(0.07, 0.42, 0.03), CFrame.new(0.23, 1.78, -0.45), bCol)
\t\tmakePart("D0_T", Vector3.new(0.23, 0.07, 0.03), CFrame.new(0.15, 1.96, -0.45), bCol)
\t\tmakePart("D0_B", Vector3.new(0.23, 0.07, 0.03), CFrame.new(0.15, 1.60, -0.45), bCol)"""

assert old_stadium in text, "old_stadium not found in ShopDailyUI.luau"
text = text.replace(old_stadium, "", 1)

with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'w', encoding='utf-8') as f:
    f.write(text)

print("ShopDailyUI.luau updated successfully!")

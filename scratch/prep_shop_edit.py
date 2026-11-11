import json

with open(r'd:\BAF\scratch\shop_chair_block.txt', 'r', encoding='utf-8') as f:
    new_block = f.read()

# Instead of replacing 130 lines at once, let's make 4 clean, precise edits in ShopDailyUI!
# Edit 1: Update CHAIR_DATA
old_chair_data = """local CHAIR_DATA: { [string]: { name: string, color: Color3, legColor: Color3, mat: Enum.Material } } = {
\twood = { name = "Classic Wood", color = Color3.fromRGB(124, 71, 40), legColor = Color3.fromRGB(75, 42, 24), mat = Enum.Material.WoodPlanks },
\tstadium = { name = "Stadium Blue", color = Color3.fromRGB(30, 111, 255), legColor = Color3.fromRGB(15, 60, 150), mat = Enum.Material.SmoothPlastic },
\tcrimson = { name = "Crimson Striker", color = Color3.fromRGB(229, 37, 42), legColor = Color3.fromRGB(140, 20, 25), mat = Enum.Material.SmoothPlastic },
\temerald = { name = "Emerald Pitch", color = Color3.fromRGB(34, 197, 94), legColor = Color3.fromRGB(20, 110, 50), mat = Enum.Material.SmoothPlastic },
\tcyber = { name = "Neon Cyber", color = Color3.fromRGB(168, 85, 247), legColor = Color3.fromRGB(90, 40, 140), mat = Enum.Material.SmoothPlastic },
\tgolden = { name = "Golden Ballon d'Or", color = Color3.fromRGB(255, 210, 31), legColor = Color3.fromRGB(180, 120, 15), mat = Enum.Material.SmoothPlastic },
}"""

new_chair_data = """local CHAIR_DATA: { [string]: { name: string, color: Color3, legColor: Color3, mat: Enum.Material } } = {
\twood = { name = "Classic Wood", color = Color3.fromRGB(124, 71, 40), legColor = Color3.fromRGB(75, 42, 24), mat = Enum.Material.WoodPlanks },
\tstadium = { name = "Stadium Blue", color = Color3.fromRGB(30, 111, 255), legColor = Color3.fromRGB(15, 60, 150), mat = Enum.Material.SmoothPlastic },
\tcyber_core = { name = "Cyber Core Chair", color = Color3.fromRGB(18, 20, 32), legColor = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },
\tcrimson = { name = "Crimson Chair", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },
\temerald = { name = "Crimson Chair", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },
\tfrostbite = { name = "Frostbite Chair", color = Color3.fromRGB(120, 210, 255), legColor = Color3.fromRGB(60, 150, 230), mat = Enum.Material.Glass },
\tcyber = { name = "Frostbite Chair", color = Color3.fromRGB(120, 210, 255), legColor = Color3.fromRGB(60, 150, 230), mat = Enum.Material.Glass },
\tgolden = { name = "Football Throne", color = Color3.fromRGB(255, 195, 30), legColor = Color3.fromRGB(205, 140, 10), mat = Enum.Material.SmoothPlastic },
\tfootball_throne = { name = "Football Throne", color = Color3.fromRGB(255, 195, 30), legColor = Color3.fromRGB(205, 140, 10), mat = Enum.Material.SmoothPlastic },
}"""

print("old_chair_data length:", len(old_chair_data))
print("new_chair_data length:", len(new_chair_data))

import os

path = r"d:\BAF\models\export_roblox_chairs.py"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

target = """local existing = Workspace:FindFirstChild("ExportedChairs_Showcase")
if existing then
    existing:Destroy()
end"""

replacement = """local existing = Workspace:FindFirstChild("ExportedChairs_Showcase")
if existing then
    existing:Destroy()
end

-- Clean up any existing loose chair models in Workspace so they don't overlap / tertimpa
for _, oldName in { "CrimsonFlameChair", "Chair_crimson", "CrimsonChair", "Chair_cyber_core", "CyberCoreChair" } do
    local old = Workspace:FindFirstChild(oldName)
    if old then
        old:Destroy()
    end
end"""

assert target in text, "Target not found in export_roblox_chairs.py"
text = text.replace(target, replacement, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("export_roblox_chairs.py updated successfully!")

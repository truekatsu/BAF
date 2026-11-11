p = r"d:\BAF\models\roblox_models\SpawnAllChairsInStudio.luau"
with open(p, "r", encoding="utf-8") as f:
    text = f.read()

old_cleanup = 'for _, oldName in { "CrimsonFlameChair", "Chair_crimson", "CrimsonChair", "Chair_cyber_core", "CyberCoreChair" } do'
new_cleanup = 'for _, oldName in { "CrimsonFlameChair", "Chair_crimson", "CrimsonChair", "Chair_cyber_core", "CyberCoreChair", "FrostbiteIceThrone", "FrostbiteChair", "Chair_frostbite", "RoyalFootballThrone", "RoyalThrone" } do'

assert old_cleanup in text, "old_cleanup not found"
text = text.replace(old_cleanup, new_cleanup, 1)

with open(p, "w", encoding="utf-8") as f:
    f.write(text)

print("SpawnAllChairsInStudio.luau cleanup successfully updated!")

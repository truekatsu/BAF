path = r"d:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i in range(488, min(520, len(lines))):
    print(f"{i+1}: {repr(lines[i])}")

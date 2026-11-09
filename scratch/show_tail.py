with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Check syntax with luau if available, or print lines 990 to 1117 with line numbers
for idx in range(990, len(lines)):
    print(f"{idx+1:4d}: {lines[idx]}", end='')

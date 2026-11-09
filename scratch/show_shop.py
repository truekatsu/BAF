with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for idx in range(34, 535):
    print(f"{idx+1:4d}: {lines[idx]}", end='')

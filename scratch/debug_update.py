import re

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(995, 1115):
    lno = i + 1
    line = lines[i]
    code = line.split('--')[0].strip()
    words = re.findall(r'\b(do|elseif|if|function|repeat|end|until)\b', code)
    print(f"L{lno:4d}: {words} | {code[:60]}")

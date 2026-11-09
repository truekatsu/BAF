import sys
sys.stdout.reconfigure(encoding='utf-8')

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i in range(934, 1150):
    l = lines[i]
    if l.startswith("-- ==") or "Page" in l:
        print(f"{i+1}: {l.strip()[:60]}")

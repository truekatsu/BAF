with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i in range(835, 1700):
    l = lines[i]
    if l.startswith("--") or "Page" in l or "page" in l:
        if len(l.strip()) > 3:
            print(f"{i+1}: {l.strip()[:60]}")

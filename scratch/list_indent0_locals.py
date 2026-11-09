with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()[:3661]

# Let's inspect what's at lines 1 to 1000
for i, l in enumerate(lines):
    stripped = l.strip()
    if stripped.startswith("local ") and not stripped.startswith("local function"):
        # print if it looks like top level (indent == 0)
        if not l.startswith(" ") and not l.startswith("\t"):
            print(f"{i+1}: {stripped}")

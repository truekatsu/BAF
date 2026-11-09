import sys
sys.stdout.reconfigure(encoding='utf-8')

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()[:3661]

count = 0
for i, l in enumerate(lines):
    stripped = l.strip()
    if (stripped.startswith("local ") or stripped.startswith("export local ")) and not stripped.startswith("local function"):
        if not l.startswith(" ") and not l.startswith("\t"):
            count += 1
            print(f"{count}. Line {i+1}: {stripped[:50]}")

print("Total indent-0 locals before 3661:", count)

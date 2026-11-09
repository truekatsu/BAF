with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
# Let's see what is around line 3661
for i in range(3650, min(3685, len(lines))):
    print(f"{i+1}: {lines[i].rstrip()}")

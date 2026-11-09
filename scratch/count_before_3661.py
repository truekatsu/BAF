with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

count = 0
for i, line in enumerate(lines[:3665]):
    if line.startswith('local ') or line.startswith('local function '):
        count += 1
        name = line.strip().split()[1] if not line.startswith('local function ') else line.strip().split()[2]
        if count >= 190 and count <= 210:
            print(f"#{count:03d} L{i+1}: {name} -> {line.strip()[:60]}")

print("Total locals before line 3661:", count)

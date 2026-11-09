import re

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.split('\n')

col0_locals = []
for i, line in enumerate(lines):
    if line.startswith('local ') or line.startswith('local function '):
        # get var name
        parts = line.strip().split()
        if line.startswith('local function '):
            name = parts[2].split('(')[0]
        else:
            name = parts[1].split(':')[0].split('=')[0].strip()
        col0_locals.append((i+1, name))

print(f"Total col0 locals: {len(col0_locals)}")

# Count occurrences of each name in the file
single_use = []
for ln, name in col0_locals:
    # use word boundary regex
    matches = list(re.finditer(rf'\b{re.escape(name)}\b', text))
    count = len(matches)
    if count <= 2:
        single_use.append((ln, name, count))

print(f"Col0 locals with <= 2 occurrences: {len(single_use)}")
for ln, name, c in single_use[:40]:
    print(f"L{ln:4d}: {name} (count={c})")

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

col0_locals = [ (i+1, line.split()[1] if not line.startswith('local function ') else line.split()[2].split('(')[0], line.strip())
                for i, line in enumerate(lines) if line.startswith('local ') or line.startswith('local function ') ]

with open('D:/BAF/scratch/all_col0_locals.txt', 'w', encoding='utf-8') as out:
    for idx, (ln, name, line) in enumerate(col0_locals):
        out.write(f"#{idx+1:03d} L{ln:4d}: {name:<25} | {line[:80]}\n")

print(f"Written {len(col0_locals)} locals to scratch/all_col0_locals.txt")

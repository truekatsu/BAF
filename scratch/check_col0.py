with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Let's track exact Luau main scope.
# When are we at main scope?
# When indent == 0!
# Notice: in MatchClient.client.luau, standard formatting has:
# - main scope lines start at column 0 (indent == 0).
# - inside functions/blocks, lines are indented with '\t' or spaces!
# Let's check how many lines start with 'local ' at column 0!

col0_locals = []
for i, line in enumerate(lines):
    if line.startswith('local ') or line.startswith('local function '):
        name = line.split()[1] if not line.startswith('local function ') else line.split()[2].split('(')[0]
        col0_locals.append((i+1, name, line.strip()))

print(f"Total column 0 'local' declarations: {len(col0_locals)}")
print("\nFirst 30:")
for ln, name, s in col0_locals[:30]:
    print(f"L{ln}: {name} -> {s[:60]}")

print(f"\nLocals around 3660-3680:")
for ln, name, s in col0_locals:
    if 3600 <= ln <= 3750:
        print(f"L{ln}: {name} -> {s[:60]}")

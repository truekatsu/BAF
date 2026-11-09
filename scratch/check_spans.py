import re

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

text = "".join(lines)

col0_locals = []
for i, line in enumerate(lines):
    if line.startswith('local ') or line.startswith('local function '):
        parts = line.strip().split()
        if line.startswith('local function '):
            name = parts[2].split('(')[0]
        else:
            name = parts[1].split(':')[0].split('=')[0].split(',')[0].strip()
        col0_locals.append((i+1, name))

short_span = []
long_span = []

for ln, name in col0_locals:
    if not name or not name.isidentifier():
        continue
    # find line numbers of matches
    occurrences = [i+1 for i, l in enumerate(lines) if re.search(rf'\b{name}\b', l)]
    if not occurrences:
        continue
    min_ln = min(occurrences)
    max_ln = max(occurrences)
    span = max_ln - min_ln
    if span < 60: # used only within 60 lines!
        short_span.append((ln, name, span, min_ln, max_ln, len(occurrences)))
    else:
        long_span.append((ln, name, span, min_ln, max_ln, len(occurrences)))

print(f"Total col0 locals checked: {len(col0_locals)}")
print(f"Locals with span < 60 lines (LOCAL TO A TINY BLOCK): {len(short_span)}")
print(f"Locals with span >= 60 lines: {len(long_span)}")

print("\nSample short span variables:")
for ln, name, span, mn, mx, count in short_span[:30]:
    print(f"L{ln:4d}: {name:<25} span={span:<3} (L{mn}-L{mx}, {count} uses)")

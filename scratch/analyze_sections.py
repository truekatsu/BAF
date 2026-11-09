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
            is_func = True
        else:
            name = parts[1].split(':')[0].split('=')[0].split(',')[0].strip()
            is_func = False
        if name and name.isidentifier():
            col0_locals.append((i+1, name, is_func, line.strip()))

# For each local, find all references in the file
results = []
for ln, name, is_func, line_str in col0_locals:
    occ = [i+1 for i, l in enumerate(lines) if re.search(rf'\b{name}\b', l)]
    last_line = max(occ) if occ else ln
    first_line = min(occ) if occ else ln
    results.append({
        'name': name,
        'decl_line': ln,
        'is_func': is_func,
        'count': len(occ),
        'first_line': first_line,
        'last_line': last_line,
        'span': last_line - first_line,
        'line_str': line_str
    })

# How many locals have last_line < 3660?
before_3660_and_dead_before_3660 = [r for r in results if r['decl_line'] < 3660 and r['last_line'] < 3660]
print(f"Total col0 locals: {len(results)}")
print(f"Col0 locals declared before L3660: {len([r for r in results if r['decl_line'] < 3660])}")
print(f"Col0 locals declared before L3660 AND NEVER USED AT OR AFTER L3660: {len(before_3660_and_dead_before_3660)}")

print("\n--- Breakdown by section ---")
# Group by declaration line ranges:
ranges = [
    ("Header & Services (1-280)", 1, 280),
    ("Lobby HUD top/nav/pills (281-598)", 281, 598),
    ("Modal Window Base (599-835)", 599, 835),
    ("Page 1B Group (836-930)", 836, 930),
    ("Page 1C Playtime (931-1127)", 931, 1127),
    ("Page 2 Quests (1128-1165)", 1128, 1165),
    ("Page 3 Skins (1166-1389)", 1166, 1389),
    ("Page 4 Titles (1390-1454)", 1390, 1454),
    ("Page 6 Index (1455-1501)", 1455, 1501),
    ("Page 7 Wheel (1502-2100)", 1502, 2100),
    ("Modal Switching (2101-2260)", 2101, 2260),
    ("Match UI Waiting/Intro/Countdown (2261-2455)", 2261, 2455),
    ("Match UI Build Cards & Viewports (2456-2886)", 2456, 2886),
    ("Match UI Showdown (2887-2940)", 2887, 2940),
    ("Match UI Summary/Popups (2941-3365)", 2941, 3365),
    ("Match Logic & Profile (3366-3660)", 3366, 3660),
    ("Mythical Vote & Post-3660 (3661-end)", 3661, 5200)
]

for title, rstart, rend in ranges:
    section_locals = [r for r in results if rstart <= r['decl_line'] <= rend]
    dead_in_section = [r for r in section_locals if r['last_line'] <= rend]
    alive_after = [r for r in section_locals if r['last_line'] > rend]
    print(f"\n{title}: Total {len(section_locals)} locals")
    print(f"   -> Dead within section: {len(dead_in_section)}")
    print(f"   -> Needed after section: {len(alive_after)} ({', '.join(r['name'] for r in alive_after)})")

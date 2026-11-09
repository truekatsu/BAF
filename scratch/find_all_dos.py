with open(r'd:\BAF\scratch\MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines, 1):
    stripped = line.strip()
    if stripped.startswith('do') and not stripped.startswith('document'):
        print(f'Line {i}: {line.rstrip()}')
    if stripped.startswith('end --') or stripped == 'end':
        if 'Page' in line or 'Quests' in line or 'Titles' in line or 'Skins' in line or 'Index' in line:
            print(f'Line {i}: {line.rstrip()}')

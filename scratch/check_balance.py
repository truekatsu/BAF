with open(r'd:\BAF\scratch\MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

stack = []

for idx, line in enumerate(lines, 1):
    # Remove strings and comments for simple token check
    # But Luau keywords are: do, then, function, if, for, while, repeat ... until, end
    stripped = line.strip()
    words = stripped.split()
    if not words or stripped.startswith('--'):
        continue
    # Let's count 'do' and 'end' specifically when on line by themselves or at end of line
    # Actually let's look at the blocks we added
    if stripped.startswith('do') and words[0] == 'do':
        stack.append((idx, 'do', line.strip()))
    elif stripped.startswith('end') and (words[0] == 'end' or words[0].startswith('end')):
        # Check if this end closes a block
        pass

print(f'Total lines: {len(lines)}')

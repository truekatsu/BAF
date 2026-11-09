with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

scope = 0
file_locals = []
for idx, line in enumerate(lines):
    # strip comments and strings naively for tracking block depth
    code = line.split('--')[0].strip()
    if not code:
        continue
    
    words = code.replace('(', ' ').replace(')', ' ').replace(',', ' ').replace(';', ' ').split()
    
    # check depth before line
    if scope == 0 and words and words[0] == 'local':
        file_locals.append((idx + 1, code[:80]))
        
    for w in words:
        if w in ('do', 'then', 'repeat', 'function'):
            scope += 1
        elif w in ('end', 'until'):
            scope = max(0, scope - 1)

print(f"Total file-level locals detected: {len(file_locals)}")
print("First 20:")
for ln, txt in file_locals[:20]:
    print(f"  {ln}: {txt}")
print("Last 20:")
for ln, txt in file_locals[-20:]:
    print(f"  {ln}: {txt}")

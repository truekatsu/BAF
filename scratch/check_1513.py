with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Check blocks from line 1510 to 2260
stack = []
for i in range(1510, 2260):
    line = lines[i].strip()
    # strip comments
    code = line.split('--')[0].strip()
    words = code.split()
    if not words:
        continue
    # Check for standalone 'do' or at end of line: 'for ... do', 'while ... do'
    if words[-1] == 'do' or words[0] == 'do':
        stack.append((i+1, line[:40]))
    if words[0] == 'end' or words[-1] == 'end' or ' end' in code:
        if stack:
            popped = stack.pop()
            # print(f"Closed {popped[0]} at {i+1}")
        else:
            print(f"Extra end at line {i+1}: {line}")

print(f"Unclosed blocks between 1510 and 2260: {len(stack)}")
for ln, s in stack:
    print(f"  Unclosed {ln}: {s}")

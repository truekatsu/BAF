import re

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Track block stack
stack = []
for i, line in enumerate(lines):
    # strip comments
    code = line.split('--')[0]
    # remove strings
    code = re.sub(r'"(?:\\.|[^"\\])*"', '""', code)
    code = re.sub(r"'(?:\\.|[^'\\])*'", "''", code)
    code = re.sub(r"`(?:\\.|[^`\\])*`", "``", code)
    
    # check tokens: function, do, then (if statement), repeat, end, until
    # Note: `then` in `if cond then`
    # Check if ternary `if` vs statement `if`
    # In statements, `if` starts at beginning of statement or after ; / newline
    tokens = re.findall(r'\b(function|do|repeat|then|end|until)\b', code)
    for t in tokens:
        # Ignore ternary if ... then ... else
        # A simple check: if line has 'else' on same line or preceded by 'if ... then ... else', but let's check
        if t in ('function', 'do', 'repeat'):
            stack.append((i+1, t, line.strip()[:40]))
        elif t == 'then':
            # Check if ternary
            if re.search(r'\bif\b.*\bthen\b.*\belse\b', code):
                pass
            elif re.search(r'=\s*if\b', code) or re.search(r'\(\s*if\b', code):
                pass
            else:
                stack.append((i+1, t, line.strip()[:40]))
        elif t in ('end', 'until'):
            if stack:
                stack.pop()
            else:
                print(f"Extra {t} at line {i+1}: {line.strip()[:40]}")

print(f"Unclosed items in stack: {len(stack)}")
for ln, t, s in stack:
    print(f"  Line {ln:4d} ({t}): {s}")

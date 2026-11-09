import re

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's inspect line by line
lines = text.split('\n')
depth = 0

for idx, line in enumerate(lines):
    line_num = idx + 1
    # Strip comments
    s = line.split('--')[0]
    # Simple strings removal
    s = re.sub(r'"(?:\\.|[^"\\])*"', '""', s)
    s = re.sub(r"'(?:\\.|[^'\\])*'", "''", s)
    s = re.sub(r"`(?:\\.|[^`\\])*`", "``", s)
    
    # In Lua, keywords that start a block:
    # 'function' (except if it's an anonymous function or type declaration or function call? wait: `type Foo = () -> ()` or `function(a)` starts a block)
    # 'then', 'do', 'repeat'
    # Keywords that close:
    # 'end', 'until'
    # Wait: does 'for ... do' have BOTH 'for' and 'do'? In lua, 'do' starts the block, 'for' doesn't!
    # Does 'while ... do' have BOTH 'while' and 'do'? 'do' starts the block!
    # Does 'if ... then' have BOTH 'if' and 'then'? 'then' starts the block!
    # But what about 'function'?
    # Wait, in Luau type annotations:
    # e.g.: `local myFunc: (a: number) -> ()` -> does not have 'function' keyword.
    # But what if someone writes `local f: (... -> ...) = ...`?
    # What about `do` in `do ... end`?
    # Let's see what tokens occur:
    tokens = re.findall(r'\b(do|then|repeat|function|end|until)\b', s)
    d_delta = 0
    for t in tokens:
        if t in ('do', 'then', 'repeat', 'function'):
            depth += 1
            d_delta += 1
        elif t in ('end', 'until'):
            depth -= 1
            d_delta -= 1
    if line_num <= 120:
        print(f"{line_num:4d} (depth={depth:2d}, delta={d_delta:+d}): {line.strip()[:60]}")

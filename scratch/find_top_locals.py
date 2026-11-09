with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# A simple stack-based Luau block tracker:
# Tokens that open a block:
# 'do', 'repeat'
# 'then' ONLY IF it's part of an 'if' STATEMENT (not 'if ... then ... else ...' expression)
# 'function' ONLY IF not followed by '(' on type annotation, but wait: `function(...)` opens a block. `() -> ()` doesn't have function.
# Tokens that close a block:
# 'end', 'until'

# Let's inspect where 'local ' appears and see how many there are.
# In fact, how many `local ` lines exist in the file total?
print("Total lines:", len(lines))

local_lines = []
for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith("local "):
        local_lines.append((i+1, stripped))

print("Total 'local ' lines:", len(local_lines))

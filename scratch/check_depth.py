import re

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    code = f.read()

lines = code.split("\n")
depth = 0

depth_log = []
for idx, line in enumerate(lines, 1):
    stripped = re.sub(r'--.*$', '', line).strip()
    stripped_no_str = re.sub(r'"([^"\\]|\\.)*"', '""', stripped)
    stripped_no_str = re.sub(r"'([^'\\]|\\.)*'", "''", stripped_no_str)
    
    tokens = re.findall(r'\b(do|then|repeat|function|end|until)\b', stripped_no_str)
    for t in tokens:
        if t in ('do', 'then', 'repeat', 'function'):
            depth += 1
        elif t in ('end', 'until'):
            depth -= 1
    depth_log.append((idx, depth, line))

print(f"Final depth at end of file: {depth}")
for idx, d, l in depth_log:
    if idx % 500 == 0 or idx == 3661 or idx == 1 or idx == len(lines):
        print(f"Line {idx}: depth={d}")

import re

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    code = f.read()

# We can find out which locals are at depth 0
# A simple Luau tokenizer / block counter
lines = code.split("\n")

depth = 0
top_locals = []

# Keywords that open a block:
# function ... (not followed by single line?), do, then (from if), else (doesn't increase depth), elseif, repeat
# Note: we need to be careful with strings and comments

open_keywords = re.compile(r'\b(do|then|repeat|function)\b')
close_keywords = re.compile(r'\b(end|until)\b')

for idx, line in enumerate(lines, 1):
    stripped = re.sub(r'--.*$', '', line).strip() # remove comments
    # remove string literals roughly
    stripped_no_str = re.sub(r'"([^"\\]|\\.)*"', '""', stripped)
    stripped_no_str = re.sub(r"'([^'\\]|\\.)*'", "''", stripped_no_str)
    
    # check if line has local at depth 0
    if depth == 0:
        m = re.match(r'^(?:export\s+)?local\s+(?:function\s+)?([A-Za-z0-9_,\s]+)', stripped_no_str)
        if m:
            var_part = m.group(1).split("=")[0].split(":")[0]
            for var in var_part.split(","):
                v = var.strip()
                if v and v not in ("function",):
                    top_locals.append((idx, v))

    # update depth
    # Count occurrences of block openers vs closers
    tokens = re.findall(r'\b(do|then|repeat|function|end|until)\b', stripped_no_str)
    for t in tokens:
        if t in ('do', 'then', 'repeat', 'function'):
            depth += 1
        elif t in ('end', 'until'):
            depth = max(0, depth - 1)

print(f"Total top-level locals detected: {len(top_locals)}")
with open("d:/BAF/scratch/top_locals.txt", "w", encoding="utf-8") as out:
    for line_no, name in top_locals:
        out.write(f"{line_no}: {name}\n")
print("Written to top_locals.txt")

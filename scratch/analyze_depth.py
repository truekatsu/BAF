import re

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's tokenize properly or remove strings/comments:
# Multi-line comments --[[ ... ]]
text_no_comments = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.DOTALL)
# Single line comments -- ...
text_no_comments = re.sub(r'--[^\n]*', '', text_no_comments)
# Multi-line strings [[ ... ]]
text_no_comments = re.sub(r'\[\[.*?\]\]', '""', text_no_comments, flags=re.DOTALL)
# Strings: double quotes, single quotes, backticks
# Note: backticks might have interpolated { ... }
# But in Luau, strings don't contain keyword 'function' or 'end' usually, but let's be careful.

lines = text_no_comments.split('\n')

depth = 0
top_locals = []
for idx, line in enumerate(lines):
    line_num = idx + 1
    # remove simple strings
    s = re.sub(r'"(?:\\.|[^"\\])*"', '""', line)
    s = re.sub(r"'(?:\\.|[^'\\])*'", "''", s)
    s = re.sub(r"`(?:\\.|[^`\\])*`", "``", s)
    
    tokens = re.findall(r'\b(function|do|then|repeat|end|until|local)\b', s)
    
    if depth == 0 and 'local' in tokens:
        top_locals.append((line_num, line.strip()))
        
    for t in tokens:
        if t in ('do', 'then', 'repeat', 'function'):
            depth += 1
        elif t in ('end', 'until'):
            depth -= 1

print(f"Total top locals at depth 0: {len(top_locals)}")
print("Depth at end of file:", depth)
for ln, l in top_locals[:30]:
    print(f"{ln}: {l[:60]}")
if len(top_locals) > 30:
    print("...")
    for ln, l in top_locals[-30:]:
        print(f"{ln}: {l[:60]}")

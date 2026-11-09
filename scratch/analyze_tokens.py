import re

with open(r'd:\BAF\scratch\MatchClient_clean.luau', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = re.compile(
    r'--\[\[.*?\]\]'           # multiline comment
    r'|--[^\n]*'               # single-line comment
    r'|"(?:[^"\\]|\\.)*"'      # double-quoted string
    r'|\'(?:[^\'\\]|\\.)*\''   # single-quoted string
    r'|`(?:\\[\s\S]|[^`])*`'   # interpolated string (backticks)
    r'|\[\[.*?\]\]'            # multiline string
    r'|\b[a-zA-Z_][a-zA-Z0-9_]*\b', # identifier/keyword
    re.DOTALL
)

tokens = []
for m in pattern.finditer(text):
    tok = m.group(0)
    tokens.append((tok, m.start()))

depth = 0
chunk_locals = []

# In Luau:
# block starters: do, function, repeat
# if ... then starts a block.
# elseif ... then does NOT start a new nested block; it continues the if block!
# block enders: end, until

prev_tok = None
for tok, pos in tokens:
    if tok.startswith('--') or tok.startswith('"') or tok.startswith("'") or tok.startswith('`') or tok.startswith('[['):
        continue
    
    if tok in ('do', 'repeat'):
        depth += 1
    elif tok == 'function':
        depth += 1
    elif tok == 'then':
        if prev_tok != 'elseif':
            depth += 1
    elif tok in ('end', 'until'):
        depth = max(0, depth - 1)
    elif tok == 'local' and depth == 0:
        line_num = text.count('\n', 0, pos) + 1
        chunk_locals.append((line_num, pos))
    
    prev_tok = tok

print(f"EOF depth: {depth}")
print(f"Total chunk-level locals (depth 0): {len(chunk_locals)}")
if len(chunk_locals) > 180:
    for lnum, pos in chunk_locals[180:220]:
        line = text[pos:text.find('\n', pos)]
        print(f"Line {lnum}: {line[:60]}")

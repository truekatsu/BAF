import sys
sys.stdout.reconfigure(encoding='utf-8')

def get_top_level_vars(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        code = f.read()

    # We tokenize properly
    import re
    # Strip multi-line comments --[[ ... ]]
    code = re.sub(r'--\[\[.*?\]\]', '', code, flags=re.DOTALL)
    # Strip single-line comments
    lines = code.split('\n')
    
    depth = 0
    top_vars = []
    
    for line_num, line in enumerate(lines, 1):
        clean = re.sub(r'--.*$', '', line).strip()
        if not clean:
            continue
        # Replace string contents
        clean_no_str = re.sub(r'"([^"\\]|\\.)*"', '""', clean)
        clean_no_str = re.sub(r"'([^'\\]|\\.)*'", "''", clean_no_str)
        clean_no_str = re.sub(r'`([^`\\]|\\.)*`', '``', clean_no_str)
        
        # Check if local declaration at depth 0
        if depth == 0:
            m = re.match(r'^(?:export\s+)?local\s+(?:function\s+([a-zA-Z0-9_]+)|([a-zA-Z0-9_,\s]+))', clean_no_str)
            if m:
                if m.group(1):
                    top_vars.append((line_num, m.group(1), "func"))
                else:
                    # e.g. local a, b: Type = ...
                    var_list = m.group(2).split('=')[0].split(':')[0]
                    for v in var_list.split(','):
                        v = v.strip()
                        if v and v != 'type':
                            top_vars.append((line_num, v, "var"))
        
        # Update depth
        # Watch out for: if ... then, elseif ... then, for ... do, while ... do, do, function(...)
        # and closing: end, until
        # Note: 'then' after 'elseif' does NOT increase depth because elseif shares the if-block!
        # But in standard Lua, if/elseif/else/end is ONE block or chained.
        # Actually in Lua compiler, each `if` creates a block, `elseif` is sugar for `else if` (so it enters another block until end),
        # but in grammar, `end` closes all if/else branches.
        # Let's count simple tokens:
        tokens = re.findall(r'\b(do|then|repeat|function|end|until)\b', clean_no_str)
        for t in tokens:
            if t == 'function':
                depth += 1
            elif t == 'then':
                # only if not elseif? Wait, if ... then -> +1. elseif ... then -> replaces current if block (depth unchanged)
                if not re.search(r'\belseif\b', clean_no_str):
                    depth += 1
            elif t == 'do':
                depth += 1
            elif t == 'repeat':
                depth += 1
            elif t == 'end':
                depth -= 1
            elif t == 'until':
                depth -= 1
                
    return top_vars

orig = get_top_level_vars("d:/BAF/scratch/orig_MatchClient.luau")
curr = get_top_level_vars("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau")

print(f"Orig top level vars: {len(orig)}")
print(f"Curr top level vars: {len(curr)}")

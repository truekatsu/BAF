import re

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

stack = []
for i in range(len(lines)):
    lno = i + 1
    line = lines[i]
    code = line.split('--')[0].strip()
    
    code_no_if_expr = re.sub(r'\bif\b\s+[^\n]+?\s+\bthen\b\s+[^\n]+?\s+\belse\b', '<expr>', code)
    code_no_inline = re.sub(r'\bif\b\s+[^\n]+?\s+\bthen\b\s+[^\n]+?\s+\bend\b', '<stmt>', code_no_if_expr)
    
    words = re.findall(r'\b(do|if|function|repeat|end|until)\b', code_no_inline)
    for w in words:
        if w in ('do', 'if', 'function', 'repeat'):
            stack.append((lno, w, code[:60]))
            if lno >= 1000:
                print(f"PUSH L{lno} [{w}] (depth {len(stack)}): {code[:40]}")
        elif w in ('end', 'until'):
            if stack:
                top_lno, top_w, top_c = stack.pop()
                if lno >= 1000 or top_lno >= 1000:
                    print(f"POP  L{lno} 'end' matched L{top_lno} [{top_w}] (depth {len(stack)}): {code[:40]}")
            else:
                print(f"EXTRA 'end' at L{lno}: {code}")

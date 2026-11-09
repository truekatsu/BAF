with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's test the entire file, not just initShop!
lines = text.split('\n')
stack = []

for lno, line in enumerate(lines):
    # remove comments
    code = line.split('--')[0].strip()
    # remove strings
    # remove if ... then ... else ... expressions:
    # replace 'if ... then ... else' on single lines
    while 'if ' in code and ' then ' in code and ' else ' in code:
        # replace the innermost if-then-else
        start_if = code.rfind('if ')
        end_else = code.find(' else ', start_if)
        if end_else != -1:
            code = code[:start_if] + '<expr>' + code[end_else+6:]
        else:
            break
            
    words = code.replace('(', ' ').replace(')', ' ').replace('{', ' ').replace('}', ' ').replace(';', ' ').replace(',', ' ').split()
    
    for w in words:
        if w in ('do', 'repeat', 'function'):
            stack.append((lno + 1, w, code[:60]))
        elif w == 'then':
            # Check if it was an if-statement (not if-expression)
            stack.append((lno + 1, w, code[:60]))
        elif w in ('end', 'until'):
            if stack:
                opened_lno, opened_type, opened_code = stack.pop()
            else:
                print(f"Extra closing '{w}' at L{lno+1}: {code}")

print(f"\nUnclosed blocks remaining in file: {len(stack)}")
for lno, w, code in stack:
    print(f"  Line {lno:4d} opened '{w}': {code}")

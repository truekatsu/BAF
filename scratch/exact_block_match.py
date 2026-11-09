import re

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
text = re.sub(r"`(?:\\.|[^`\\])*`", "``", text)
text = re.sub(r'--[^\n]*', '', text)
while True:
    new_text = re.sub(r'\bif\b\s+[^\n]+?\s+\bthen\b\s+[^\n]+?\s+\belse\b', '<ifexpr>', text)
    if new_text == text: break
    text = new_text

lines = text.split('\n')
stack = []
for lno, line in enumerate(lines):
    # treat 'elseif ... then' as continuing the current if, not pushing a new one
    words = re.findall(r'\b(do|elseif|if|function|repeat|end|until)\b', line)
    for w in words:
        if w in ('do', 'if', 'function', 'repeat'):
            stack.append((lno + 1, w, line.strip()))
        elif w == 'elseif':
            pass # continues current 'if'
        elif w in ('end', 'until'):
            if stack:
                top_lno, top_w, top_line = stack.pop()
            else:
                print(f"Extra closing '{w}' at line {lno+1}")

print(f"\nRemaining unclosed: {len(stack)}")
for lno, w, ltext in stack:
    print(f"  Line {lno:4d}: [{w}] {ltext[:70]}")

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
    words = re.findall(r'\b(do|then|function|repeat|end|until)\b', line)
    for w in words:
        if w in ('do', 'then', 'function', 'repeat'):
            stack.append((lno + 1, w, line.strip()))
        elif w in ('end', 'until'):
            if stack:
                top_lno, top_w, top_line = stack.pop()
                if 715 <= lno + 1 <= 900 or 715 <= top_lno <= 900:
                    print(f"L{lno+1}: 'end' closed [{top_w}] from L{top_lno}")

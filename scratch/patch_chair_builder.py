path = r'd:\BAF\src\ReplicatedStorage\Prefabs\ChairModelBuilder.luau'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

target = 'elseif key == "golden" or key == "royal" or key == "royalthrone" or key == "royalfootballthrone" then'
replacement = 'elseif key == "golden" or key == "football_throne" or key == "footballthrone" or key == "royal" or key == "royalthrone" or key == "royalfootballthrone" then'

crlf = '\r\n' in text
text_norm = text.replace('\r\n', '\n')
target_norm = target.replace('\r\n', '\n')
replacement_norm = replacement.replace('\r\n', '\n')

if target_norm in text_norm:
    new_text = text_norm.replace(target_norm, replacement_norm, 1)
    if crlf:
        new_text = new_text.replace('\n', '\r\n')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("SUCCESS: ChairModelBuilder patched")
else:
    print("FAILED: target not found")

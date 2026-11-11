path = r'd:\BAF\src\ReplicatedStorage\Shared\SelfTest.luau'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

target = '\tassert(GameConfig.getChairSkin("golden").id == "golden", "getChairSkin must find golden chair")'
replacement = """\tassert(GameConfig.getChairSkin("golden").name == "Football Throne" and GameConfig.getChairSkin("golden").cost == 15000, "Football Throne must exist and cost 15000 Bux")
\tassert(GameConfig.getChairSkin("football_throne").name == "Football Throne", "football_throne alias must resolve to Football Throne")"""

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
    print("SUCCESS: SelfTest patched")
else:
    print("FAILED: target not found")

path = r'd:\BAF\src\ReplicatedStorage\Shared\GameConfig.luau'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

target = """\tif chairId == "cyber" then
\t\tfor _, skin in GameConfig.CHAIR_SKINS do
\t\t\tif skin.id == "frostbite" then
\t\t\t\treturn skin
\t\t\tend
\t\tend
\tend"""

addition = """\tif chairId == "cyber" then
\t\tfor _, skin in GameConfig.CHAIR_SKINS do
\t\t\tif skin.id == "frostbite" then
\t\t\t\treturn skin
\t\t\tend
\t\tend
\tend
\tif chairId == "football_throne" or chairId == "royal" then
\t\tfor _, skin in GameConfig.CHAIR_SKINS do
\t\t\tif skin.id == "golden" then
\t\t\t\treturn skin
\t\t\tend
\t\tend
\tend"""

# normalize line endings for replacement
crlf = '\r\n' in text
text_norm = text.replace('\r\n', '\n')
target_norm = target.replace('\r\n', '\n')
addition_norm = addition.replace('\r\n', '\n')

if target_norm in text_norm:
    new_text = text_norm.replace(target_norm, addition_norm, 1)
    if crlf:
        new_text = new_text.replace('\n', '\r\n')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("SUCCESS: GameConfig patched with alias")
else:
    print("FAILED: target not found")

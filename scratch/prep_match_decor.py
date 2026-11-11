with open(r'd:\BAF\src\ServerScriptService\Server\MatchService.luau', 'r', encoding='utf-8') as f:
    text = f.read().replace('\r\n', '\n')

anchor = "\t\tdecor.Parent = tableModel\n\telseif isCyberCore and seat then"
idx = text.find(anchor)
assert idx != -1

end_anchor = "local function updateTableSign(session: TableSession)"
idx2 = text.find(end_anchor)
assert idx2 != -1

replacement = text[idx:idx2].strip()

print("replacement starts with:", repr(replacement[:60]))
print("replacement ends with:", repr(replacement[-60:]))

with open(r'd:\BAF\scratch\match_decor_replace.txt', 'w', encoding='utf-8') as f:
    f.write(replacement)

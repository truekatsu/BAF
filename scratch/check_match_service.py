import json

# Read what's on disk
with open(r'd:\BAF\src\ServerScriptService\Server\MatchService.luau', 'r', encoding='utf-8') as f:
    disk_text = f.read().replace('\r\n', '\n')

s_idx = disk_text.find('local function applyChairSkin')
e_idx = disk_text.find('local function updateTableSign')
new_apply = disk_text[s_idx:e_idx].strip()

print("new_apply starts with:", repr(new_apply[:50]))
print("new_apply ends with:", repr(new_apply[-50:]))

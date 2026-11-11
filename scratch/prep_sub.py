with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    text = f.read().replace('\r\n', '\n')

anchor = 'if skinId == "cyber_core" then'
s_idx = text.find(anchor)
assert s_idx != -1

e_idx = text.find('local function createChairViewport')
assert e_idx != -1

sub = text[s_idx:e_idx].strip()
print('Starts with:', repr(sub[:50]))
print('Ends with:', repr(sub[-50:]))
print('Length:', len(sub))

with open(r'd:\BAF\scratch\shop_sub_block.txt', 'w', encoding='utf-8') as f:
    f.write(sub)

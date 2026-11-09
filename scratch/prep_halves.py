import json

with open(r'd:\BAF\scratch\MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('\r\n', '\n').replace('\r', '\n')
print(f'Length: {len(text)}')

mid = len(text) // 2
part1 = text[:mid]
part2 = text[mid:]

print(f'Part 1: {len(part1)}, Part 2: {len(part2)}')

p1_json = json.dumps({'c': part1})
p2_json = json.dumps({'c': part2})

with open(r'd:\BAF\scratch\half_1.luau', 'w', encoding='utf-8') as f:
    f.write(f'_G.mc_half1 = game:GetService("HttpService"):JSONDecode({json.dumps(p1_json)}).c\nreturn "Half 1 loaded: " .. tostring(#_G.mc_half1)')

with open(r'd:\BAF\scratch\half_2.luau', 'w', encoding='utf-8') as f:
    f.write(f'_G.mc_half2 = game:GetService("HttpService"):JSONDecode({json.dumps(p2_json)}).c\nreturn "Half 2 loaded: " .. tostring(#_G.mc_half2)')

print('Done writing half_1 and half_2')

import json

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

total_len = len(text)
NUM_PARTS = 5
part_size = (total_len + NUM_PARTS - 1) // NUM_PARTS

for idx in range(NUM_PARTS):
    start = idx * part_size
    end = min(start + part_size, total_len)
    chunk = text[start:end]
    payload = json.dumps({'c': chunk})
    luau_code = f'_G.local_parts = _G.local_parts or {{}}\n_G.local_parts[{idx+1}] = game:GetService("HttpService"):JSONDecode({json.dumps(payload)}).c\nreturn "Part {idx+1} loaded: " .. tostring(#_G.local_parts[{idx+1}])'
    
    filename = rf'd:\BAF\scratch\lpart_{idx+1}.luau'
    with open(filename, 'w', encoding='utf-8') as out:
        out.write(luau_code)

print('Done writing lparts')

import json

with open(r'd:\BAF\scratch\MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    text = f.read()

chunk_size = 35000
chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
print(f'Total len: {len(text)}, number of chunks: {len(chunks)}')

for idx, chunk in enumerate(chunks, 1):
    payload = json.dumps({'c': chunk})
    luau_code = f'_G.mc_chunks = _G.mc_chunks or {{}}\n_G.mc_chunks[{idx}] = game:GetService("HttpService"):JSONDecode({json.dumps(payload)}).c\nreturn "Chunk {idx} len: " .. tostring(#_G.mc_chunks[{idx}])'
    with open(rf'd:\BAF\scratch\p_{idx}.luau', 'w', encoding='utf-8') as out:
        out.write(luau_code)
print('Generated p_1 .. p_6 files')

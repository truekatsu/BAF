import json

with open(r'd:\BAF\scratch\MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Make sure all newlines are standard \n
text = text.replace('\r\n', '\n').replace('\r', '\n')
print(f'Total length of text: {len(text)}')

CHUNK_SIZE = 20000
chunks = [text[i:i+CHUNK_SIZE] for i in range(0, len(text), CHUNK_SIZE)]
print(f'Number of chunks: {len(chunks)}')

for idx, chunk in enumerate(chunks, 1):
    payload = json.dumps({'c': chunk})
    luau_code = f'_G.new_chunks = _G.new_chunks or {{}}\n_G.new_chunks[{idx}] = game:GetService("HttpService"):JSONDecode({json.dumps(payload)}).c\nreturn "Loaded chunk {idx} (size " .. tostring(#_G.new_chunks[{idx}]) .. ")"'
    with open(rf'd:\BAF\scratch\nc_{idx}.luau', 'w', encoding='utf-8') as out:
        out.write(luau_code)

print('Generated nc_1 to nc_10')

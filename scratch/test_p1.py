import json

with open(r'd:\BAF\scratch\MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    text = f.read()

chunk_size = 35000
chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
for i, c in enumerate(chunks, 1):
    print(f'Chunk {i} len: {len(c)}')

import json

with open('src/ReplicatedStorage/Prefabs/ChairModelBuilder.luau', 'r', encoding='utf-8') as f:
    code = f.read()

# We can split into chunks of ~5000 characters and concatenate in Luau
chunks = [code[i:i+5000] for i in range(0, len(code), 5000)]

luau_parts = []
luau_parts.append('local s = game.ReplicatedStorage.Prefabs.ChairModelBuilder')
luau_parts.append('local chunks = {}')
for chunk in chunks:
    escaped = chunk.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    luau_parts.append(f'table.insert(chunks, "{escaped}")')

luau_parts.append('s.Source = table.concat(chunks)')
luau_parts.append('return "Synced ChairModelBuilder! Length: " .. #s.Source')

full_script = '\n'.join(luau_parts)
with open('scratch/do_sync_cmb.luau', 'w', encoding='utf-8') as f:
    f.write(full_script)

print('Generated scratch/do_sync_cmb.luau with length:', len(full_script))

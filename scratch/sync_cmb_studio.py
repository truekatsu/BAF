import json

with open('src/ReplicatedStorage/Prefabs/ChairModelBuilder.luau', 'r', encoding='utf-8') as f:
    code = f.read()

chunks = [code[i:i+4000] for i in range(0, len(code), 4000)]
luau_parts = [
    'local s = game.ReplicatedStorage.Prefabs.ChairModelBuilder',
    'local chunks = {}'
]
for c in chunks:
    esc = c.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    luau_parts.append(f'table.insert(chunks, "{esc}")')

luau_parts.append('s.Source = table.concat(chunks)')
luau_parts.append('return "OK! Len: " .. #s.Source')

cmd = '\n'.join(luau_parts)
with open('scratch/sync_cmb_exec.json', 'w', encoding='utf-8') as out:
    json.dump({
        'studio_id': '649a33bb-29a0-415b-a167-51eaf7f9f85f',
        'datamodel_type': 'Edit',
        'code': cmd
    }, out)

print('Generated scratch/sync_cmb_exec.json')

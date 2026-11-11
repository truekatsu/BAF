with open('src/ServerScriptService/Server/MatchService.luau', 'r', encoding='utf-8') as f:
    code = f.read()

# Chunks of 4000 characters
chunks = [code[i:i+4000] for i in range(0, len(code), 4000)]

luau_parts = []
luau_parts.append('local s = game.ServerScriptService.Server.MatchService')
luau_parts.append('local chunks = {}')
for chunk in chunks:
    escaped = chunk.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    luau_parts.append(f'table.insert(chunks, "{escaped}")')

luau_parts.append('s.Source = table.concat(chunks)')
luau_parts.append('return "Synced MatchService! Length: " .. #s.Source')

full_script = '\n'.join(luau_parts)
with open('scratch/do_sync_ms.luau', 'w', encoding='utf-8') as f:
    f.write(full_script)

print('Generated scratch/do_sync_ms.luau with length:', len(full_script), 'Chunks:', len(chunks))

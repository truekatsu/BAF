with open('src/ServerScriptService/Server/MatchService.luau', 'r', encoding='utf-8') as f:
    code = f.read()

chunks = [code[i:i+4000] for i in range(0, len(code), 4000)]

# Part 1: chunks 0 to 5
p1 = ['_G.__msChunks = {}']
for c in chunks[:6]:
    escaped = c.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    p1.append(f'table.insert(_G.__msChunks, "{escaped}")')
p1.append('return "Part 1 stored: " .. #_G.__msChunks')

with open('scratch/ms_part1.luau', 'w', encoding='utf-8') as f:
    f.write('\n'.join(p1))

# Part 2: chunks 6 to end + apply
p2 = []
for c in chunks[6:]:
    escaped = c.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    p2.append(f'table.insert(_G.__msChunks, "{escaped}")')
p2.append('local s = game.ServerScriptService.Server.MatchService')
p2.append('s.Source = table.concat(_G.__msChunks)')
p2.append('_G.__msChunks = nil')
p2.append('return "Synced MatchService! Length: " .. #s.Source')

with open('scratch/ms_part2.luau', 'w', encoding='utf-8') as f:
    f.write('\n'.join(p2))

print('Part 1 and 2 ready!')

with open('src/ReplicatedStorage/Prefabs/ChairModelBuilder.luau', 'r', encoding='utf-8') as f:
    code = f.read()

escaped = code.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')

with open('scratch/do_sync.luau', 'w', encoding='utf-8') as out:
    out.write('local s = game.ReplicatedStorage.Prefabs.ChairModelBuilder\n')
    out.write(f's.Source = "{escaped}"\n')
    out.write('return "Updated ChairModelBuilder Source! Length: " .. #s.Source\n')

print('Generated scratch/do_sync.luau')

with open('src/ReplicatedStorage/Prefabs/ChairModelBuilder.luau', 'r', encoding='utf-8') as f:
    code = f.read()

with open('scratch/direct_update.luau', 'w', encoding='utf-8') as out:
    out.write('local s = game.ReplicatedStorage.Prefabs.ChairModelBuilder\n')
    out.write('s.Source = [====[\n')
    out.write(code)
    out.write('\n]====]\n')
    out.write('return "Direct update successful! Source length: " .. #s.Source\n')

print('Generated direct_update.luau successfully')

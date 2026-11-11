import json

with open('src/ReplicatedStorage/Prefabs/ChairModelBuilder.luau', 'r', encoding='utf-8') as f:
    code = f.read()

payload = json.dumps({'code': code})

with open('scratch/push_json.luau', 'w', encoding='utf-8') as out:
    out.write('local hs = game:GetService("HttpService")\n')
    # Write as a raw string or escaped JSON
    escaped = payload.replace('\\', '\\\\').replace('"', '\\"')
    out.write(f'local data = hs:JSONDecode("{escaped}")\n')
    out.write('local s = game.ReplicatedStorage.Prefabs.ChairModelBuilder\n')
    out.write('s.Source = data.code\n')
    out.write('return "Successfully updated ChairModelBuilder! Source length: " .. #s.Source\n')

print('Generated push_json.luau')

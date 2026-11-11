import base64
with open('src/ReplicatedStorage/Prefabs/ChairModelBuilder.luau', 'rb') as f:
    b64 = base64.b64encode(f.read()).decode('utf-8')

# Split into chunks of 3000 chars
chunks = [b64[i:i+3000] for i in range(0, len(b64), 3000)]
with open('scratch/push_script.luau', 'w') as out:
    out.write('local parts = {\n')
    for c in chunks:
        out.write(f'"{c}",\n')
    out.write('}\n')
    out.write('local fullB64 = table.concat(parts, "")\n')
    out.write('local fullCode = game:GetService("HttpService"):Base64Decode(fullB64)\n')
    out.write('local s = game.ReplicatedStorage.Prefabs.ChairModelBuilder\n')
    out.write('s.Source = fullCode\n')
    out.write('return "Updated ChairModelBuilder! New length: " .. #s.Source\n')

print('Generated push_script.luau')

import json

with open(r'd:\BAF\src\ReplicatedStorage\Shared\UITheme.luau', 'r', encoding='utf-8') as f:
    text = f.read()

mid = len(text) // 2
part1 = text[:mid]
part2 = text[mid:]

with open(r'd:\BAF\scratch\ui_p1.luau', 'w', encoding='utf-8') as f:
    f.write(f'_G.ui_theme_chunks = {{}}\n_G.ui_theme_chunks[1] = game:GetService("HttpService"):JSONDecode({json.dumps(json.dumps({"c": part1}))}).c\nreturn #_G.ui_theme_chunks[1]')

with open(r'd:\BAF\scratch\ui_p2.luau', 'w', encoding='utf-8') as f:
    f.write(f'_G.ui_theme_chunks[2] = game:GetService("HttpService"):JSONDecode({json.dumps(json.dumps({"c": part2}))}).c\nlocal full = table.concat(_G.ui_theme_chunks)\nlocal fn, err = loadstring(full)\nif fn then\n    game.ReplicatedStorage.Shared.UITheme.Source = full\n    return game:GetService("HttpService"):JSONEncode({{ success = true, len = #full, hasAnimate = string.find(full, "animateWindowOpen") ~= nil }})\nelse\n    return game:GetService("HttpService"):JSONEncode({{ success = false, err = err }})\nend')

print("Wrote ui_p1.luau and ui_p2.luau!")

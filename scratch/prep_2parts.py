import json

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    local_txt = f.read()

mid = len(local_txt) // 2
part1 = local_txt[:mid]
part2 = local_txt[mid:]

code1 = f'_G.temp_p1 = game:GetService("HttpService"):JSONDecode({json.dumps(json.dumps({"s": part1}))}).s\nreturn #_G.temp_p1'

code2 = f"""local HS = game:GetService("HttpService")
local p2 = HS:JSONDecode({json.dumps(json.dumps({"s": part2}))}).s
local full = _G.temp_p1 .. p2
_G.temp_p1 = nil
local fn, err = loadstring(full)
return {{
    ok = (fn ~= nil),
    err = tostring(err),
    full_len = #full
}}"""

with open('D:/BAF/scratch/p1.luau', 'w', encoding='utf-8') as out:
    out.write(code1)

with open('D:/BAF/scratch/p2.luau', 'w', encoding='utf-8') as out:
    out.write(code2)

print(f"Part 1 size: {len(code1)}, Part 2 size: {len(code2)}")

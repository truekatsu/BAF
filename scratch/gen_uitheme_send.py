import json

with open(r'd:\BAF\src\ReplicatedStorage\Shared\UITheme.luau', 'r', encoding='utf-8') as f:
    text = f.read()

payload = json.dumps({'code': text})

luau = f"""
local payload = game:GetService("HttpService"):JSONDecode({json.dumps(payload)})
local fn, err = loadstring(payload.code)
if fn then
    local target = game.ReplicatedStorage.Shared.UITheme
    target.Source = payload.code
    return game:GetService("HttpService"):JSONEncode({{
        success = true,
        len = #target.Source,
        hasAnimate = string.find(target.Source, "animateWindowOpen") ~= nil
    }})
else
    return game:GetService("HttpService"):JSONEncode({{
        success = false,
        err = err
    }})
end
"""

with open(r'd:\BAF\scratch\send_uitheme.luau', 'w', encoding='utf-8') as f:
    f.write(luau)

print("Saved send_uitheme.luau!")

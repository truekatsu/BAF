import json

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    text = f.read()

payload = json.dumps({'code': text})

luau = f"""
local payload = game:GetService("HttpService"):JSONDecode({json.dumps(payload)})
local fn, err = loadstring(payload.code)
return game:GetService("HttpService"):JSONEncode({{
    valid = fn ~= nil,
    err = err
}})
"""

with open(r'd:\BAF\scratch\test_sd_compile.luau', 'w', encoding='utf-8') as f:
    f.write(luau)

print("Saved test_sd_compile.luau!")

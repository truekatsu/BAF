import json

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    local_txt = f.read()

# Let's wrap local_txt in a JSON payload:
payload = json.dumps({'src': local_txt})
print(f"Payload length: {len(payload)}")

# Generate luau code:
luau_code = f"""local HS = game:GetService("HttpService")
local data = HS:JSONDecode({json.dumps(payload)})
local fn, err = loadstring(data.src)
return {{
    ok = (fn ~= nil),
    err = tostring(err),
    len = string.len(data.src)
}}"""

with open('D:/BAF/scratch/test_compile_local.luau', 'w', encoding='utf-8') as out:
    out.write(luau_code)

print(f"Luau code length: {len(luau_code)}")

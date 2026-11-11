# scratch/push_hud_to_studio.py
import json

with open("scratch/hud_edits_payload.json", "r", encoding="utf-8") as f:
    data = json.load(f)

edits = data["edits"]
old1 = json.dumps(edits[0]["old_string"])
new1 = json.dumps(edits[0]["new_string"])
old2 = json.dumps(edits[1]["old_string"])
new2 = json.dumps(edits[1]["new_string"])

luau_code = f"""
local clientScript = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client"):FindFirstChild("MatchClient")
local src = clientScript.Source

local old1 = {old1}
local new1 = {new1}
local old2 = {old2}
local new2 = {new2}

local s1, e1 = string.find(src, old1, 1, true)
if not s1 then
    return "FAILED: old1 block not found in MatchClient!"
end

local s2, e2 = string.find(src, old2, 1, true)
if not s2 then
    return "FAILED: old2 block not found in MatchClient!"
end

src = string.sub(src, 1, s1 - 1) .. new1 .. string.sub(src, e1 + 1)

-- Find old2 again because indices shifted
s2, e2 = string.find(src, old2, 1, true)
if not s2 then
    return "FAILED: old2 block not found after first replacement!"
end
src = string.sub(src, 1, s2 - 1) .. new2 .. string.sub(src, e2 + 1)

clientScript.Source = src
return "SUCCESS: MatchClient updated in Studio!"
"""

with open("scratch/studio_update_code.luau", "w", encoding="utf-8") as f:
    f.write(luau_code)

print("Luau code written, length:", len(luau_code))

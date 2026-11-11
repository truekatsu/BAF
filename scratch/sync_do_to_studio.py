# scratch/sync_do_to_studio.py
import json

with open("scratch/do_hud_code.txt", "r", encoding="utf-8") as f:
    do_code = f.read()

# Let's inspect what is currently in Studio MatchClient around line 720-800
# We can find "-- Top-Left Currency & Friends Boost HUD" and replace until the end of updateFriendsDisplay function
luau_code = f"""
local clientScript = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client"):FindFirstChild("MatchClient")
local src = clientScript.Source

local startMarker = "-- Top-Left Currency & Friends Boost HUD"
local endMarker = "\\nend\\nend\\n"

local s = string.find(src, startMarker, 1, true)
if not s then
    return "FAILED: startMarker not found"
end

local e = string.find(src, endMarker, s, true)
if not e then
    return "FAILED: endMarker not found"
end

local newCode = {json.dumps(do_code)}

src = string.sub(src, 1, s - 1) .. newCode .. "\\n" .. string.sub(src, e + #endMarker)
clientScript.Source = src
return "SUCCESS: MatchClient updated in Studio with do ... end block!"
"""

with open("scratch/studio_sync_do.luau", "w", encoding="utf-8") as f:
    f.write(luau_code)

print("Studio sync do script written")

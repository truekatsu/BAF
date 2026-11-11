# scratch/make_exec_do.py
import json

with open("scratch/do_hud_code.txt", "r", encoding="utf-8") as f:
    do_code = f.read()

code = f"""local clientScript = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client"):FindFirstChild("MatchClient")
local src = clientScript.Source

local startMarker = "-- Top-Left Currency & Friends Boost HUD"
local endMarker = "-- Opponent Needed Notification Banner"

local s = string.find(src, startMarker, 1, true)
if not s then return "FAILED: startMarker not found" end

local e = string.find(src, endMarker, s, true)
if not e then return "FAILED: endMarker not found" end

local newCode = {json.dumps(do_code)}

src = string.sub(src, 1, s - 1) .. newCode .. "\\n\\n" .. string.sub(src, e)
clientScript.Source = src
return "SUCCESS: Studio MatchClient updated with do ... end block!"
"""

with open("scratch/exec_do.luau", "w", encoding="utf-8") as f:
    f.write(code)

print("Generated exec_do.luau successfully")

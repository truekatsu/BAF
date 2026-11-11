# scratch/make_exec_min.py
import json

with open("scratch/min_reg_code.txt", "r", encoding="utf-8") as f:
    min_code = f.read()

code = f"""local clientScript = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client"):FindFirstChild("MatchClient")
local src = clientScript.Source

local startMarker = "-- Top-Left Currency & Friends Boost HUD"
local endMarker = "-- Opponent Needed Notification Banner"

local s = string.find(src, startMarker, 1, true)
if not s then return "FAILED: startMarker not found" end

local e = string.find(src, endMarker, s, true)
if not e then return "FAILED: endMarker not found" end

local newCode = {json.dumps(min_code)}

src = string.sub(src, 1, s - 1) .. newCode .. "\\n\\n" .. string.sub(src, e)

local oldRefresh = "updateCashDisplay(p.Bux or 0)\\n\\tlocal boostPct = (localPlayer:GetAttribute(\\"FriendsBoostPct\\") :: number?) or 0\\n\\tupdateFriendsDisplay(boostPct)"
local newRefresh = "if HUD.updateCash then HUD.updateCash(p.Bux or 0) else cashLabel.Text = `$` .. tostring(p.Bux) end\\n\\tlocal boostPct = (localPlayer:GetAttribute(\\"FriendsBoostPct\\") :: number?) or 0\\n\\tif HUD.updateFriends then HUD.updateFriends(boostPct) else friendsLabel.Text = `FRIENDS BOOST: +{{boostPct}}%` end"

local sR = string.find(src, oldRefresh, 1, true)
if sR then
    src = string.sub(src, 1, sR - 1) .. newRefresh .. string.sub(src, sR + #oldRefresh)
end

clientScript.Source = src
return "SUCCESS: Studio MatchClient updated with minimal registers!"
"""

with open("scratch/exec_min_reg.luau", "w", encoding="utf-8") as f:
    f.write(code)

print("Generated exec_min_reg.luau")

import json

with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    full_source = f.read()

# Generate a small patch script for execute_luau in Edit mode
# We only need to replace createChairViewport and ensure UserInputService is at top
start_marker = 'local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame'
end_marker = 'local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame'

idx1 = full_source.find(start_marker)
idx2 = full_source.find(end_marker)

assert idx1 != -1 and idx2 != -1

new_snippet = full_source[idx1:idx2]

top_block = '''local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer'''

old_top_block = '''local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer'''

esc_snippet = new_snippet.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
esc_top = top_block.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
esc_old_top = old_top_block.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')

luau = f"""
local s = game.StarterPlayer.StarterPlayerScripts.Client.ShopDailyUI
local source = s.Source

local oldTop = "{esc_old_top}"
local newTop = "{esc_top}"
local pIdx = string.find(source, oldTop, 1, true)
if pIdx then
    source = string.sub(source, 1, pIdx - 1) .. newTop .. string.sub(source, pIdx + #oldTop)
end

local startM = "local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame"
local endM = "local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame"

local i1 = string.find(source, startM, 1, true)
local i2 = string.find(source, endM, 1, true)

if not i1 or not i2 then
    return "Markers not found in Studio script! i1=" .. tostring(i1) .. ", i2=" .. tostring(i2)
end

local snippet = "{esc_snippet}"
source = string.sub(source, 1, i1 - 1) .. snippet .. string.sub(source, i2)
s.Source = source
return "Synced to Studio ShopDailyUI successfully! Total len: " .. #s.Source
"""

with open('scratch/sync_shop_viewport_live.luau', 'w', encoding='utf-8') as f:
    f.write(luau)

print("Generated sync_shop_viewport_live.luau, size:", len(luau))

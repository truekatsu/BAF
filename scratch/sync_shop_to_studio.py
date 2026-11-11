import json

with open('scratch/shop_multi_edit_args.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

new_str = d['edits'][1]['new_string']
esc_new = new_str.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')

luau = f"""
local s = game.StarterPlayer.StarterPlayerScripts.Client.ShopDailyUI
local source = s.Source

local p1 = "local TweenService = game:GetService(\\"TweenService\\")\\nlocal Players = game:GetService(\\"Players\\")"
local r1 = "local TweenService = game:GetService(\\"TweenService\\")\\nlocal RunService = game:GetService(\\"RunService\\")\\nlocal ReplicatedStorage = game:GetService(\\"ReplicatedStorage\\")\\nlocal Players = game:GetService(\\"Players\\")\\nlocal ChairModelBuilder = require(ReplicatedStorage:WaitForChild(\\"Prefabs\\"):WaitForChild(\\"ChairModelBuilder\\"))"

local startM = "local function buildChairModel(skinId: string): Model"
local endM = "local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame"

local i1 = string.find(source, startM, 1, true)
local i2 = string.find(source, endM, 1, true)

if not i1 or not i2 then
    return "Markers not found! i1=" .. tostring(i1) .. ", i2=" .. tostring(i2)
end

local pIdx = string.find(source, p1, 1, true)
if pIdx then
    source = string.sub(source, 1, pIdx - 1) .. r1 .. string.sub(source, pIdx + #p1)
end

i1 = string.find(source, startM, 1, true)
i2 = string.find(source, endM, 1, true)

local newCode = "{esc_new}"
source = string.sub(source, 1, i1 - 1) .. newCode .. "\\n" .. string.sub(source, i2)
s.Source = source
return "Success! ShopDailyUI updated, new length: " .. #s.Source
"""

with open('scratch/run_shop_sync.luau', 'w', encoding='utf-8') as out:
    out.write(luau)

print('Generated scratch/run_shop_sync.luau with length:', len(luau))

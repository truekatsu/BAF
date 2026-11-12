import re

# 1. Update Studio via Luau script
fix_luau = '''
local clientScript = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client"):FindFirstChild("MatchClient")
local src = clientScript.Source

-- Fix topRightBar declaration
src = string.sub(src, 1, string.find(src, "local questBadge: TextLabel", 1, true) + 26) .. "\nlocal topRightBar: Frame\n" .. string.sub(src, string.find(src, "do\n\tlocal topRightBar = Instance.new(\"Frame\")", 1, true) + 3)
src = string.gsub(src, "do\n\tlocal topRightBar = Instance.new%(\"Frame\"%)", "do\n\ttopRightBar = Instance.new(\"Frame\")", 1)

-- Fix currencyGroup declaration
src = string.gsub(src, "local btnAddCash: TextButton", "local btnAddCash: TextButton\nlocal currencyGroup: Frame", 1)
src = string.gsub(src, "do\n\tlocal currencyGroup = Instance.new%(\"Frame\"%)", "do\n\tcurrencyGroup = Instance.new(\"Frame\")", 1)

-- Guard registerHudGroupScale against nil frames
local old_reg = [[local function registerHudGroupScale(frame: GuiObject): UIScale
	local sc = frame:FindFirstChild("GroupUIScale") :: UIScale?]]

local new_reg = [[local function registerHudGroupScale(frame: GuiObject?): UIScale?
	if not frame then return nil end
	local sc = frame:FindFirstChild("GroupUIScale") :: UIScale?]]

src = string.gsub(src, "local function registerHudGroupScale%(frame: GuiObject%): UIScale\n\tlocal sc = frame:FindFirstChild%(\"GroupUIScale\"%) :: UIScale%?", new_reg, 1)

local fn, err = loadstring(src)
if not fn then
	return "COMPILE ERROR: " .. tostring(err)
end

clientScript.Source = src
return "SUCCESS! Scopes fixed in Studio. New length: " .. #src
'''

with open('scratch/fix_scopes.luau', 'w', encoding='utf-8') as f:
    f.write(fix_luau)

print("Generated scratch/fix_scopes.luau")

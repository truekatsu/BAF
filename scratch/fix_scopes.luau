
local clientScript = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client"):FindFirstChild("MatchClient")
local src = clientScript.Source

-- Fix topRightBar declaration
src = string.sub(src, 1, string.find(src, "local questBadge: TextLabel", 1, true) + 26) .. "
local topRightBar: Frame
" .. string.sub(src, string.find(src, "do
	local topRightBar = Instance.new("Frame")", 1, true) + 3)
src = string.gsub(src, "do
	local topRightBar = Instance.new%("Frame"%)", "do
	topRightBar = Instance.new("Frame")", 1)

-- Fix currencyGroup declaration
src = string.gsub(src, "local btnAddCash: TextButton", "local btnAddCash: TextButton
local currencyGroup: Frame", 1)
src = string.gsub(src, "do
	local currencyGroup = Instance.new%("Frame"%)", "do
	currencyGroup = Instance.new("Frame")", 1)

-- Guard registerHudGroupScale against nil frames
local old_reg = [[local function registerHudGroupScale(frame: GuiObject): UIScale
	local sc = frame:FindFirstChild("GroupUIScale") :: UIScale?]]

local new_reg = [[local function registerHudGroupScale(frame: GuiObject?): UIScale?
	if not frame then return nil end
	local sc = frame:FindFirstChild("GroupUIScale") :: UIScale?]]

src = string.gsub(src, "local function registerHudGroupScale%(frame: GuiObject%): UIScale
	local sc = frame:FindFirstChild%("GroupUIScale"%) :: UIScale%?", new_reg, 1)

local fn, err = loadstring(src)
if not fn then
	return "COMPILE ERROR: " .. tostring(err)
end

clientScript.Source = src
return "SUCCESS! Scopes fixed in Studio. New length: " .. #src

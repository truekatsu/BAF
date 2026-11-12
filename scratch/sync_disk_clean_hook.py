with open('src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    src = f.read()

# Replace the previous scale hook if present
old_hook_start = "-- Responsive UIScale across all HUD groups"
old_hook_end = "updateAllHudScales()\n\n"

clean_hook = '''-- Responsive UIScale across all HUD groups (clamp(vpH / 1080, 0.6, 1.0) * 0.85 on touch)
local function updateAllHudScales()
	local cam = Workspace.CurrentCamera
	local vpH = if cam then cam.ViewportSize.Y else 1080
	local baseScale = math.clamp(vpH / 1080, 0.6, 1.0)
	local isMobileTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local finalScale = if isMobileTouch then baseScale * 0.85 else baseScale

	local groups = {
		lobbyHud:FindFirstChild("CurrencyGroup"),
		lobbyHud:FindFirstChild("LeftNavGroup"),
		lobbyHud:FindFirstChild("RightPromoGroup"),
		screenGui:FindFirstChild("TopRightBar"),
	}
	for _, grp in ipairs(groups) do
		if grp then
			local sc = grp:FindFirstChild("GroupUIScale") :: UIScale?
			if not sc then
				sc = Instance.new("UIScale")
				sc.Name = "GroupUIScale"
				sc.Parent = grp
			end
			sc.Scale = finalScale
		end
	end
end

if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAllHudScales)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAllHudScales)
		updateAllHudScales()
	end
end)
updateAllHudScales()

'''

import re
pattern = r'-- Responsive UIScale across all HUD groups.*?updateAllHudScales\(\)\s*'
src, count = re.subn(pattern, clean_hook, src, flags=re.DOTALL)
print("Updated disk hook, count:", count)

with open('src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'w', encoding='utf-8') as f:
    f.write(src)

print("Disk updated successfully.")

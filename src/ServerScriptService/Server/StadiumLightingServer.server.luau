--!strict
--[[
	StadiumLightingServer (Script)
	Location: ServerScriptService/Server/StadiumLightingServer.server.luau

	Responsibility:
	- Server-side initiator for stadium floodlights.
	- Builds and tags floodlights and multi-surface ground glows on all stadium towers.
	- Sets up central PlazaFill illumination and walkway restyling.
	- Handles Auto Day/Night clock monitoring.
	- Listens to workspace.StadiumLightsOn attribute triggers.
	- Provides /lights, /lightdebug, and /lightfix admin commands.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local StadiumLighting = require(ReplicatedStorage:WaitForChild("StadiumLighting"))

-- 1. Build and Prepare Towers
local towers = StadiumLighting.GetTowers()
print(string.format("[StadiumLighting] Initializing %d floodlight towers...", #towers))
for idx, tower in ipairs(towers) do
	StadiumLighting.buildFloodlightLighting(tower, idx)
end
print(string.format("[StadiumLighting] Built and tagged %d floodlight towers with multi-level ground glow.", #towers))

-- 2. Setup Central Plaza Fill Light
StadiumLighting.setupPlazaFill()
print("[StadiumLighting] PlazaFill central illumination initialized.")

-- 3. Apply Walkway & Plaza Restyling if enabled
if StadiumLighting.CONFIG.WALKWAY_RESTYLE then
	StadiumLighting.applyWalkwayRestyle(true)
	print("[StadiumLighting] Walkway and Plaza restyled with warm stone materials.")
end

-- 4. Initial Mode & ClockTime Sync
StadiumLighting.SetMode("Auto")

-- 5. ClockTime Listener for Auto Mode
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	if StadiumLighting.GetMode() == "Auto" then
		StadiumLighting.CheckAutoClockTime()
	end
end)

-- 6. External Attribute Trigger Listener (Minigames / Event match overrides)
workspace:GetAttributeChangedSignal("StadiumLightsOn"):Connect(function()
	local forcedState = workspace:GetAttribute("StadiumLightsOn")
	if typeof(forcedState) == "boolean" then
		StadiumLighting.SetLightsState(forcedState, true)
	end
end)

-- 7. Day/Night Cycle Starter if configured
if StadiumLighting.CONFIG.CYCLE_ENABLED then
	StadiumLighting.StartDayNightCycle()
end

-- ============================================================================
-- 8. ADMIN COMMAND HANDLER (/lights, /lightdebug, /lightfix)
-- ============================================================================
local function processLightsCommand(sender: Player, message: string)
	local cleanMsg = string.lower(string.gsub(message, "^%s*(.-)%s*$", "%1"))
	local tokens = string.split(cleanMsg, " ")

	if tokens[1] == "/lightdebug" then
		local state = tokens[2]
		if state == "on" or state == "1" or state == "true" then
			StadiumLighting.SetDebugMode(true)
			print(string.format("[StadiumLighting] Admin %s enabled /lightdebug.", sender.Name))
		elseif state == "off" or state == "0" or state == "false" then
			StadiumLighting.SetDebugMode(false)
			print(string.format("[StadiumLighting] Admin %s disabled /lightdebug.", sender.Name))
		end
		return
	end

	if tokens[1] == "/lightfix" then
		local log = StadiumLighting.RebuildAllGlows()
		print(string.format("[StadiumLighting] Admin %s ran /lightfix. Rebuilt %d towers.", sender.Name, #log))
		return
	end

	if tokens[1] ~= "/lights" then return end

	local subCmd = tokens[2]
	if subCmd == "on" then
		StadiumLighting.SetMode("Night")
		print(string.format("[StadiumLighting] Admin %s forced Night mode (Lights ON).", sender.Name))
	elseif subCmd == "off" then
		StadiumLighting.SetMode("Day")
		print(string.format("[StadiumLighting] Admin %s forced Day mode (Lights OFF).", sender.Name))
	elseif subCmd == "auto" then
		StadiumLighting.SetMode("Auto")
		print(string.format("[StadiumLighting] Admin %s set Auto mode.", sender.Name))
	elseif subCmd == "cycle" then
		local action = tokens[3]
		if action == "start" or action == "on" then
			StadiumLighting.StartDayNightCycle()
			print(string.format("[StadiumLighting] Admin %s started day/night cycle.", sender.Name))
		elseif action == "stop" or action == "off" then
			StadiumLighting.StopDayNightCycle()
			print(string.format("[StadiumLighting] Admin %s stopped day/night cycle.", sender.Name))
		end
	end
end

-- Modern TextChatService support
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	local generalChannel = TextChatService:WaitForChild("TextChannels", 5) and TextChatService.TextChannels:FindFirstChild("RBXGeneral") :: TextChannel?
	if generalChannel then
		generalChannel.MessageReceived:Connect(function(textChatMessage)
			local sender = Players:GetPlayerByUserId(textChatMessage.TextSource.UserId)
			if sender then
				processLightsCommand(sender, textChatMessage.Text)
			end
		end)
	end
end

-- Legacy Chat fallback
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		processLightsCommand(player, msg)
	end)
end)

--!strict
--[[
	VIPClient (Client)
	Responsibility: Client-side handling of VIP status.
	(Physical VIP Lounge structure removed).
	Location: StarterPlayer/StarterPlayerScripts/Client/VIPClient.client.luau
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- VIP status listener for UI / local effects
player:GetAttributeChangedSignal("IsVIP"):Connect(function()
	-- Local VIP status changed (handled by UI and ProfileService)
end)

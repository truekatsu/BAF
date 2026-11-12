--!strict
--[[
	VIPService (Server)
	Responsibility: Manages VIP gamepass ownership and attributes.
	(Physical VIP Lounge structure removed per design request).
	Location: ServerScriptService/Server/VIPService.server.luau
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VIPConfig = require(Shared:WaitForChild("VIPConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local vipCache: { [number]: boolean } = {}

local function getVIPPassId(): number
	if GameConfig.MONETIZATION.vip and GameConfig.MONETIZATION.vip.id > 0 then
		return GameConfig.MONETIZATION.vip.id
	end
	return VIPConfig.VIP_GAMEPASS_ID
end

-- 1. Helper to check VIP ownership
local function isPlayerVIP(player: Player): boolean
	if player:GetAttribute("IsVIP") == true then
		return true
	end

	local gamepassId = getVIPPassId()
	if gamepassId <= 0 then
		return player:GetAttribute("IsVIP") == true
	end

	local cached = vipCache[player.UserId]
	if cached ~= nil then
		return cached
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	local result = success and (owns == true)
	vipCache[player.UserId] = result
	player:SetAttribute("IsVIP", result)
	return result
end

-- 2. Clean up any existing physical VIP Lounge model in Workspace
local function cleanupVIPModel()
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		local existing = lobby:FindFirstChild("VIP")
		if existing then
			existing:Destroy()
		end
		local layout = lobby:FindFirstChild("_Layout")
		if layout then
			local entrance = layout:FindFirstChild("VIPEntrance")
			if entrance then
				entrance:Destroy()
			end
		end
	end
	local debugFolder = Workspace:FindFirstChild("_LayoutDebug")
	if debugFolder then
		local marker = debugFolder:FindFirstChild("VIPEntrance_Marker")
		if marker then
			marker:Destroy()
		end
	end
end

cleanupVIPModel()

-- 3. Player Lifecycle & GamePass purchase listener
Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("IsVIP", isPlayerVIP(player))
end)

for _, player in ipairs(Players:GetPlayers()) do
	player:SetAttribute("IsVIP", isPlayerVIP(player))
end

Players.PlayerRemoving:Connect(function(player)
	vipCache[player.UserId] = nil
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	local vId = getVIPPassId()
	if wasPurchased and (passId == vId or (VIPConfig.VIP_GAMEPASS_ID > 0 and passId == VIPConfig.VIP_GAMEPASS_ID)) then
		vipCache[player.UserId] = true
		player:SetAttribute("IsVIP", true)
	end
end)

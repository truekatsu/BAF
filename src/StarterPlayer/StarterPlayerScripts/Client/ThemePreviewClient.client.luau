--!strict
--[[
	ThemePreviewClient.client.luau
	Listens for /themepreview chat command to open the UI theme preview showcase.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local UITheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UITheme"))
local player = Players.LocalPlayer

local function handleMessage(msg: string)
	local trimmed = string.lower(string.match(msg, "^%s*(.-)%s*$") or "")
	if trimmed == "/themepreview" or trimmed == "!themepreview" or trimmed == "/preview" then
		local playerGui = player:WaitForChild("PlayerGui")
		UITheme.preview(playerGui)
	end
end

-- Legacy chat listener
player.Chatted:Connect(handleMessage)

-- Modern TextChatService command listener
pcall(function()
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local textCommands = TextChatService:WaitForChild("TextChatCommands", 3)
		if textCommands then
			local cmd = Instance.new("TextChatCommand")
			cmd.Name = "ThemePreviewCommand"
			cmd.PrimaryAlias = "/themepreview"
			cmd.SecondaryAlias = "/preview"
			cmd.Triggered:Connect(function()
				local playerGui = player:WaitForChild("PlayerGui")
				UITheme.preview(playerGui)
			end)
			cmd.Parent = textCommands
		end
	end
end)

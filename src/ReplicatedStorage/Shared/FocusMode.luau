--!strict
--[[
	FocusMode
	Responsibility: Minigame focus mode & clean screen isolation for ALL minigames:
	- Hides all non-whitelisted UI (sidebars, promo buttons, top bar, HUDs, modals)
	- Disables Roblox CoreGui (PlayerList, Chat, Backpack, EmotesMenu, Health)
	- Whitelist approach: tracks newly created ScreenGuis via ChildAdded
	- Robust restoration: on exit, returns all UI and CoreGui to previous states
	- Top-left chunky brick LEAVE button with high DisplayOrder
	- ContextActionService keybinds for PC [Q] and Gamepad [ButtonB]
	- In-round confirmation popup ("Leave minigame? Progress will be lost")
	- 3-second safety net timeout to prevent stuck screens
	Location: ReplicatedStorage/Shared/FocusMode.luau
]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local FOCUS_KEEP: { [string]: boolean } = {
	TargetKickGui = true,
	LeaveButtonGui = true,
	FocusConfirmGui = true,
	Freecam = true,
}

local FocusMode = {}

local isActive = false
local currentMinigameId: string? = nil
local savedGuiStates: { [ScreenGui]: boolean } = {}
local childAddedConn: RBXScriptConnection? = nil
local onLeaveCallback: (() -> ())? = nil
local isRoundPlaying = false

local leaveGui: ScreenGui? = nil
local confirmGui: ScreenGui? = nil
local safetyTimerThread: thread? = nil

local ACTION_LEAVE = "FocusMode_LeaveAction"

local function safeSetCoreGui(enabled: boolean)
	task.spawn(function()
		for _ = 1, 3 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, enabled)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, enabled)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, enabled)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, enabled)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, enabled)
			end)
			if ok then break end
			task.wait(0.2)
		end
	end)
end

local function closeConfirmModal()
	if confirmGui then
		confirmGui:Destroy()
		confirmGui = nil
	end
end

local function openConfirmModal()
	if confirmGui then return end

	confirmGui = Instance.new("ScreenGui")
	confirmGui.Name = "FocusConfirmGui"
	confirmGui.ResetOnSpawn = false
	confirmGui.DisplayOrder = 120
	confirmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	confirmGui.Parent = playerGui

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.55
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Parent = confirmGui

	local modal = Instance.new("Frame")
	modal.Name = "ModalCard"
	modal.Size = UDim2.fromOffset(360, 210)
	modal.Position = UDim2.new(0.5, -180, 0.5, -105)
	modal.BackgroundColor3 = Color3.fromHex("#0F1530")
	modal.Parent = backdrop

	local mCorner = Instance.new("UICorner")
	mCorner.CornerRadius = UDim.new(0, 14)
	mCorner.Parent = modal

	local mStroke = Instance.new("UIStroke")
	mStroke.Thickness = 3
	mStroke.Color = Color3.fromHex("#1F4FD8")
	mStroke.Parent = modal

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 42)
	title.Position = UDim2.new(0, 0, 0, 14)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.Text = "LEAVE MINIGAME?"
	title.TextColor3 = Color3.fromHex("#FFD54A")
	title.TextScaled = true
	title.Parent = modal

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.88, 0, 0, 48)
	desc.Position = UDim2.new(0.06, 0, 0, 60)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.GothamMedium
	desc.Text = "Your progress and kicks for this round will be lost. Return to the stadium lobby?"
	desc.TextColor3 = Color3.fromHex("#CBD5E1")
	desc.TextWrapped = true
	desc.TextSize = 15
	desc.Parent = modal

	local btnContainer = Instance.new("Frame")
	btnContainer.Size = UDim2.new(0.9, 0, 0, 48)
	btnContainer.Position = UDim2.new(0.05, 0, 0, 138)
	btnContainer.BackgroundTransparency = 1
	btnContainer.Parent = modal

	-- Stay Button (Lime)
	local stayBtn = Instance.new("TextButton")
	stayBtn.Name = "StayBtn"
	stayBtn.Size = UDim2.new(0.47, 0, 1, 0)
	stayBtn.Position = UDim2.new(0, 0, 0, 0)
	stayBtn.BackgroundColor3 = Color3.fromHex("#22C55E")
	stayBtn.Font = Enum.Font.FredokaOne
	stayBtn.Text = "STAY"
	stayBtn.TextColor3 = Color3.new(1, 1, 1)
	stayBtn.TextScaled = true
	stayBtn.Parent = btnContainer
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 10)
	sc.Parent = stayBtn
	local ss = Instance.new("UIStroke")
	ss.Thickness = 2.5
	ss.Color = Color3.new(0, 0, 0)
	ss.Parent = stayBtn

	stayBtn.Activated:Connect(function()
		closeConfirmModal()
	end)

	-- Leave Button (Red)
	local leaveConfirmBtn = Instance.new("TextButton")
	leaveConfirmBtn.Name = "LeaveConfirmBtn"
	leaveConfirmBtn.Size = UDim2.new(0.47, 0, 1, 0)
	leaveConfirmBtn.Position = UDim2.new(0.53, 0, 0, 0)
	leaveConfirmBtn.BackgroundColor3 = Color3.fromHex("#EF4444")
	leaveConfirmBtn.Font = Enum.Font.FredokaOne
	leaveConfirmBtn.Text = "LEAVE"
	leaveConfirmBtn.TextColor3 = Color3.new(1, 1, 1)
	leaveConfirmBtn.TextScaled = true
	leaveConfirmBtn.Parent = btnContainer
	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(0, 10)
	lc.Parent = leaveConfirmBtn
	local ls = Instance.new("UIStroke")
	ls.Thickness = 2.5
	ls.Color = Color3.new(0, 0, 0)
	ls.Parent = leaveConfirmBtn

	leaveConfirmBtn.Activated:Connect(function()
		closeConfirmModal()
		if onLeaveCallback then
			onLeaveCallback()
		end
	end)
end

local function triggerLeaveRequest()
	if not isActive then return end
	if isRoundPlaying then
		openConfirmModal()
	else
		if onLeaveCallback then
			onLeaveCallback()
		end
	end
end

local function createLeaveButtonGui()
	if leaveGui then leaveGui:Destroy() end

	leaveGui = Instance.new("ScreenGui")
	leaveGui.Name = "LeaveButtonGui"
	leaveGui.ResetOnSpawn = false
	leaveGui.DisplayOrder = 100
	leaveGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	leaveGui.Parent = playerGui

	local inset = GuiService:GetGuiInset()

	local leaveBtn = Instance.new("TextButton")
	leaveBtn.Name = "ChunkyLeaveButton"
	leaveBtn.Size = UDim2.fromOffset(130, 44)
	leaveBtn.Position = UDim2.new(0, 20, 0, math.max(16, inset.Y + 8))
	leaveBtn.BackgroundColor3 = Color3.fromHex("#FF4D4D")
	leaveBtn.Font = Enum.Font.FredokaOne
	leaveBtn.Text = "✕ LEAVE [Q]"
	leaveBtn.TextColor3 = Color3.new(1, 1, 1)
	leaveBtn.TextScaled = true
	leaveBtn.AutoButtonColor = false
	leaveBtn.Parent = leaveGui

	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, 10)
	uic.Parent = leaveBtn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = leaveBtn

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromHex("#FF4D4D"), Color3.fromHex("#C21F1F"))
	grad.Rotation = 90
	grad.Parent = leaveBtn

	-- Chunky Button Tween Reactions
	leaveBtn.MouseEnter:Connect(function()
		TweenService:Create(leaveBtn, TweenInfo.new(0.12), { Size = UDim2.fromOffset(136, 46) }):Play()
	end)
	leaveBtn.MouseLeave:Connect(function()
		TweenService:Create(leaveBtn, TweenInfo.new(0.12), { Size = UDim2.fromOffset(130, 44) }):Play()
	end)
	leaveBtn.MouseButton1Down:Connect(function()
		TweenService:Create(leaveBtn, TweenInfo.new(0.08), { Size = UDim2.fromOffset(124, 40) }):Play()
	end)
	leaveBtn.MouseButton1Up:Connect(function()
		TweenService:Create(leaveBtn, TweenInfo.new(0.08), { Size = UDim2.fromOffset(130, 44) }):Play()
	end)

	leaveBtn.Activated:Connect(function()
		triggerLeaveRequest()
	end)
end

function FocusMode.Enter(minigameId: string, onLeaveReq: () -> ())
	if isActive then return end
	isActive = true
	currentMinigameId = minigameId
	onLeaveCallback = onLeaveReq
	isRoundPlaying = true

	table.clear(savedGuiStates)

	-- 1. Whitelist-based ScreenGui hiding
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and not FOCUS_KEEP[child.Name] then
			savedGuiStates[child] = child.Enabled
			child.Enabled = false
		end
	end

	-- 2. Watch for newly created ScreenGuis while in Focus Mode
	if childAddedConn then childAddedConn:Disconnect() end
	childAddedConn = playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and not FOCUS_KEEP[child.Name] then
			savedGuiStates[child] = child.Enabled
			child.Enabled = false
		end
	end)

	-- 3. Disable CoreGui elements
	safeSetCoreGui(false)

	-- 4. Create LEAVE button & bind keybinds [Q] / Gamepad [ButtonB]
	createLeaveButtonGui()

	ContextActionService:BindActionAtPriority(
		ACTION_LEAVE,
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				triggerLeaveRequest()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		3000,
		Enum.KeyCode.Q,
		Enum.KeyCode.ButtonB
	)
end

function FocusMode.SetRoundPlaying(playing: boolean)
	isRoundPlaying = playing
	if not playing then
		closeConfirmModal()
	end
end

function FocusMode.Exit()
	if not isActive then return end
	isActive = false
	currentMinigameId = nil
	onLeaveCallback = nil
	isRoundPlaying = false

	if safetyTimerThread then
		task.cancel(safetyTimerThread)
		safetyTimerThread = nil
	end

	closeConfirmModal()

	if leaveGui then
		leaveGui:Destroy()
		leaveGui = nil
	end

	if childAddedConn then
		childAddedConn:Disconnect()
		childAddedConn = nil
	end

	ContextActionService:UnbindAction(ACTION_LEAVE)

	-- Restore ScreenGuis to their previous states
	for gui, wasEnabled in pairs(savedGuiStates) do
		if gui and gui.Parent then
			gui.Enabled = wasEnabled
		end
	end
	table.clear(savedGuiStates)

	-- Restore CoreGui elements
	safeSetCoreGui(true)
end

function FocusMode.IsActive(): boolean
	return isActive
end

-- Safety net: starts a 3-second timeout that restores UI if server does not respond
function FocusMode.ArmSafetyTimeout()
	if safetyTimerThread then task.cancel(safetyTimerThread) end
	safetyTimerThread = task.delay(3.0, function()
		if isActive then
			warn("[FocusMode] Safety timeout reached! Server failed to confirm exit, forcing UI restore.")
			FocusMode.Exit()
		end
	end)
end

return FocusMode

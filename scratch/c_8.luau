_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[8] = [=[
		slot.stroke.Color = Color3.fromRGB(238, 244, 255)
		slot.stroke.Thickness = 2.5
		slot.stroke.Transparency = 0
		slot.viewport.Visible = true
		mountViewportModel(slot.viewport, slot.mount, card.id)
		slot.nameLbl.Text = Footballers.getDisplayName(card)
		slot.nameLbl.Visible = true
	else
		slot.box.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
		slot.box.BackgroundTransparency = 0.32
		slot.stroke.Color = Color3.fromRGB(175, 184, 198)
		slot.stroke.Thickness = 2
		slot.stroke.Transparency = 0.18
		slot.viewport.Visible = false
		mountViewportModel(slot.viewport, slot.mount, nil)
		slot.nameLbl.Text = ""
		slot.nameLbl.Visible = false
	end
end

local function bindSpectateTable(tableModel: Instance)
	if not tableModel:IsA("Model") or spectateRefreshers[tableModel] then
		return
	end
	local tableTop = tableModel:WaitForChild("TableTop", 5)
	if not tableTop or not tableTop:IsA("BasePart") or spectateRefreshers[tableModel] then
		return
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = `BAF_Spectate_{tableModel.Name}`
	bb.Size = UDim2.fromScale(22.5, 8.8)
	bb.StudsOffset = Vector3.new(0, 6.2, 0)
	bb.MaxDistance = 95
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Enabled = false
	bb.Adornee = tableTop
	bb.Parent = playerGui

	local function makeSpectateText(name: string, size: UDim2, pos: UDim2, strokeThick: number): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.Size = size
		lbl.Position = pos
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextScaled = true
		lbl.Parent = bb
		local st = Instance.new("UIStroke")
		st.Color = Color3.new(0, 0, 0)
		st.Thickness = strokeThick
		st.Parent = lbl
		return lbl
	end

	local pvpHeader = makeSpectateText("PvPHeader", UDim2.fromScale(1, 0.14), UDim2.fromScale(0, 0), 2.5)
	pvpHeader.Text = "PvP"

	local namesRow = makeSpectateText("NamesRow", UDim2.fromScale(1, 0.19), UDim2.fromScale(0, 0.13), 3)
	namesRow.RichText = true

	local turnRow = makeSpectateText("TurnRow", UDim2.fromScale(1, 0.13), UDim2.fromScale(0, 0.32), 2.5)
	turnRow.Text = "Turn 1/6"

	local slotsArea = Instance.new("Frame")
	slotsArea.Name = "SlotsArea"
	slotsArea.Size = UDim2.fromScale(1, 0.54)
	slotsArea.Position = UDim2.fromScale(0, 0.46)
	slotsArea.BackgroundTransparency = 1
	slotsArea.Parent = bb

	local sideASlots = createSpectateSideSlots(slotsArea, "SideA", 0)
	buildClashBolt(slotsArea)
	local sideBSlots = createSpectateSideSlots(slotsArea, "SideB", 0.545)

	local function refreshThisTable()
		local active = tableModel:GetAttribute("MatchActive") == true
		bb.Enabled = active and (currentPhase == "Idle")
		if not active then
			return
		end

		local nameA = tostring(tableModel:GetAttribute("NameA") or "Player 1")
		local nameB = tostring(tableModel:GetAttribute("NameB") or "BOT")
		local turn = tonumber(tableModel:GetAttribute("Turn")) or 1
		local maxTurns = #GameConfig.ATTRIBUTES

		pvpHeader.Text = "PvP"
		namesRow.Text = string.format(
			'<font color="#22D3EE">%s</font>  <font color="#FFD21F">VS</font>  <font color="#EF4444">%s</font>',
			escapeRichText(nameA),
			escapeRichText(nameB)
		)
		turnRow.Text = `Turn {math.clamp(turn, 1, maxTurns)}/{maxTurns}`

		for _, attr in GameConfig.ATTRIBUTES do
			local idA = tostring(tableModel:GetAttribute(`SlotA_{attr}`) or "")
			local idB = tostring(tableModel:GetAttribute(`SlotB_{attr}`) or "")
			updateSpectateSlot(sideASlots[attr], idA)
			updateSpectateSlot(sideBSlots[attr], idB)
		end
	end

	spectateRefreshers[tableModel] = refreshThisTable
	local attrConn = tableModel.AttributeChanged:Connect(refreshThisTable)
	tableModel.Destroying:Connect(function()
		attrConn:Disconnect()
		spectateRefreshers[tableModel] = nil
		bb:Destroy()
	end)
	refreshThisTable()
end

refreshAllSpectateBillboards = function()
	for _, fn in spectateRefreshers do
		fn()
	end
end

task.spawn(function()
	local lobby = Workspace:WaitForChild("Lobby", 5)
	local tablesFolder = (lobby and lobby:WaitForChild("Tables", 5)) or Workspace:WaitForChild("Tables", 15)
	if not tablesFolder then
		return
	end
	for _, child in tablesFolder:GetChildren() do
		task.spawn(bindSpectateTable, child)
	end
	tablesFolder.ChildAdded:Connect(function(child)
		task.spawn(bindSpectateTable, child)
	end)
end)
end -- setupSpectatorDisplay
setupSpectatorDisplay()
end -- spectator display

-- ============================================================
-- 8. SHARE YOUR FEEDBACK MODAL + PRIVATE OWNER feedback.txt VIEWER
-- ============================================================
do
local function setupFeedbackModal()
local feedbackModal = Instance.new("Frame")
feedbackModal.Name = "FeedbackModal"
feedbackModal.Size = UDim2.fromOffset(480, 360)
feedbackModal.AnchorPoint = Vector2.new(0.5, 0.5)
feedbackModal.Position = UDim2.fromScale(0.5, 0.5)
feedbackModal.BackgroundColor3 = Color3.fromRGB(35, 37, 41)
feedbackModal.BorderSizePixel = 0
feedbackModal.ZIndex = 32
feedbackModal.Visible = false
feedbackModal.Parent = screenGui
addCorner(feedbackModal, 14)
addStroke(feedbackModal, Color3.fromRGB(60, 63, 70), 1)

local fbCloseBtn = Instance.new("TextButton")
fbCloseBtn.Name = "CloseBtn"
fbCloseBtn.Size = UDim2.fromOffset(44, 40)
fbCloseBtn.Position = UDim2.fromOffset(22, 10)
fbCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 41)
fbCloseBtn.Text = ""
fbCloseBtn.ZIndex = 33
fbCloseBtn.Parent = feedbackModal
addCorner(fbCloseBtn, 10)
addStroke(fbCloseBtn, Color3.new(1, 1, 1), 2.5)
for _, rot in { 45, -45 } do
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(18, 2)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.Rotation = rot
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BorderSizePixel = 0
	bar.ZIndex = 34
	bar.Parent = fbCloseBtn
end

local fbTitle = Instance.new("TextLabel")
fbTitle.Name = "Title"
fbTitle.Size = UDim2.new(1, -180, 0, 40)
fbTitle.Position = UDim2.fromOffset(90, 10)
fbTitle.BackgroundTransparency = 1
fbTitle.Font = Enum.Font.GothamBold
fbTitle.TextSize = 21
fbTitle.TextColor3 = Color3.new(1, 1, 1)
fbTitle.Text = "Share Your Feedback"
fbTitle.ZIndex = 33
fbTitle.Parent = feedbackModal

local isLikelyOwner = RunService:IsStudio()
	or (game.CreatorType == Enum.CreatorType.User and localPlayer.UserId == game.CreatorId)
local fbOwnerBtn = Instance.new("TextButton")
fbOwnerBtn.Name = "OwnerTxtBtn"
fbOwnerBtn.Size = UDim2.fromOffset(96, 30)
fbOwnerBtn.Position = UDim2.new(1, -116, 0, 15)
fbOwnerBtn.BackgroundColor3 = Color3.fromRGB(54, 58, 66)
fbOwnerBtn.Font = Enum.Font.GothamBold
fbOwnerBtn.TextSize = 12
fbOwnerBtn.TextColor3 = Color3.fromRGB(220, 228, 245)
fbOwnerBtn.Text = "📄 feedback.txt"
fbOwnerBtn.Visible = isLikelyOwner
fbOwnerBtn.ZIndex = 33
fbOwnerBtn.Parent = feedbackModal
addCorner(fbOwnerBtn, 8)
addStroke(fbOwnerBtn, Color3.fromRGB(95, 102, 115), 1)

local fbDivider = Instance.new("Frame")
fbDivider.Name = "Divider"
fbDivider.Size = UDim2.new(1, -48, 0, 1)
fbDivider.Position = UDim2.fromOffset(24, 58)
fbDivider.BackgroundColor3 = Color3.fromRGB(72, 75, 82)
fbDivider.BorderSizePixel = 0
fbDivider.ZIndex = 33
fbDivider.Parent = feedbackModal

-- Compose Pane (matches Image 5)
local fbComposePane = Instance.new("Frame")
fbComposePane.Name = "ComposePane"
fbComposePane.Size = UDim2.new(1, -48, 1, -74)
fbComposePane.Position = UDim2.fromOffset(24, 68)
fbComposePane.BackgroundTransparency = 1
fbComposePane.ZIndex = 33
fbComposePane.Parent = feedbackModal

local fbPromptLbl = Instance.new("TextLabel")
fbPromptLbl.Name = "PromptLabel"
fbPromptLbl.Size = UDim2.new(1, 0, 0, 24)
fbPromptLbl.Position = UDim2.fromOffset(0, 6)
fbPromptLbl.BackgroundTransparency = 1
fbPromptLbl.Font = Enum.Font.GothamMedium
fbPromptLbl.TextSize = 17
fbPromptLbl.TextColor3 = Color3.fromRGB(238, 240, 245)
fbPromptLbl.TextXAlignment = Enum.TextXAlignment.Left
fbPromptLbl.Text = "Tell us about your experience."
fbPromptLbl.ZIndex = 33
fbPromptLbl.Parent = fbComposePane

local fbInputWrap = Instance.new("Frame")
fbInputWrap.Name = "InputWrap"
fbInputWrap.Size = UDim2.new(1, 0, 0, 112)
fbInputWrap.Position = UDim2.fromOffset(0, 42)
fbInputWrap.BackgroundColor3 = Color3.fromRGB(45, 48, 53)
fbInputWrap.BorderSizePixel = 0
fbInputWrap.ZIndex = 33
fbInputWrap.Parent = fbComposePane
addCorner(fbInputWrap, 10)

local fbInput = Instance.new("TextBox")
fbInput.Name = "FeedbackInput"
fbInput.Size = UDim2.new(1, -28, 1, -24)
fbInput.Position = UDim2.fromOffset(14, 12)
fbInput.BackgroundTransparency = 1
fbInput.Font = Enum.Font.Gotham
fbInput.TextSize = 16
fbInput.TextColor3 = Color3.fromRGB(245, 247, 250)
fbInput.PlaceholderColor3 = Color3.fromRGB(162, 166, 174)
fbInput.PlaceholderText = "Tell us what you think..."
fbInput.Text = ""
fbInput.MultiLine = true
fbInput.ClearTextOnFocus = false
fbInput.TextWrapped = true
fbInput.TextXAlignment = Enum.TextXAlignment.Left
fbInput.TextYAlignment = Enum.TextYAlignment.Top
fbInput.ZIndex = 34
fbInput.Parent = fbInputWrap

local fbSubmitBtn = Instance.new("TextButton")
fbSubmitBtn.Name = "SubmitBtn"
fbSubmitBtn.Size = UDim2.new(1, 0, 0, 42)
fbSubmitBtn.Position = UDim2.fromOffset(0, 178)
fbSubmitBtn.BackgroundColor3 = Color3.fromRGB(43, 56, 99)
fbSubmitBtn.BorderSizePixel = 0
fbSubmitBtn.Font = Enum.Font.GothamMedium
fbSubmitBtn.TextSize = 16
fbSubmitBtn.TextColor3 = Color3.fromRGB(155, 163, 181)
fbSubmitBtn.Text = "Submit"
fbSubmitBtn.ZIndex = 33
fbSubmitBtn.Parent = fbComposePane
addCorner(fbSubmitBtn, 8)

local fbFooter = Instance.new("TextLabel")
fbFooter.Name = "FooterDisclaimer"
fbFooter.Size = UDim2.new(1, 0, 0, 38)
fbFooter.Position = UDim2.fromOffset(0, 234)
fbFooter.BackgroundTransparency = 1
fbFooter.Font = Enum.Font.Gotham
fbFooter.TextSize = 13
fbFooter.TextColor3 = Color3.fromRGB(178, 182, 190)
fbFooter.TextXAlignment = Enum.TextXAlignment.Left
fbFooter.TextYAlignment = Enum.TextYAlignment.Top
fbFooter.TextWrapped = true
fbFooter.RichText = true
fbFooter.Text = "Responses are shared anonymously and constitute\nfeedback per the <u>Roblox Terms of Use</u>."
fbFooter.ZIndex = 33
fbFooter.Parent = fbComposePane

-- Owner-only Private .txt Log Pane (read-only & selectable so owner can copy into player_feedback.txt)
local fbOwnerPane = Instance.new("Frame")
fbOwnerPane.Name = "OwnerTxtPane"
fbOwnerPane.Size = UDim2.new(1, -48, 1, -74)
fbOwnerPane.Position = UDim2.fromOffset(24, 68)
fbOwnerPane.BackgroundTransparency = 1
fbOwnerPane.Visible = false
fbOwnerPane.ZIndex = 33
fbOwnerPane.Parent = feedbackModal

local fbOwnerHint = Instance.new("TextLabel")
fbOwnerHint.Size = UDim2.new(1, 0, 0, 22)
fbOwnerHint.Position = UDim2.fromOffset(0, 2)
fbOwnerHint.BackgroundTransparency = 1
fbOwnerHint.Font = Enum.Font.GothamMedium
fbOwnerHint.TextSize = 13
fbOwnerHint.TextColor3 = Color3.fromRGB(165, 220, 185)
fbOwnerHint.TextXAlignment = Enum.TextXAlignment.Left
fbOwnerHint.Text = "Owner Private Log (player_feedback.txt) — Select & Ctrl+C to copy:"
fbOwnerHint.ZIndex = 33
fbOwnerHint.Parent = fbOwnerPane

local fbOwnerScroll = Instance.new("ScrollingFrame")
fbOwnerScroll.Name = "TxtScroll"
fbOwnerScroll.Size = UDim2.new(1, 0, 1, -30)
fbOwnerScroll.Position = UDim2.fromOffset(0, 26)
fbOwnerScroll.BackgroundColor3 = Color3.fromRGB(24, 26, 30)
fbOwnerScroll.BorderSizePixel = 0
fbOwnerScroll.ScrollBarThickness = 6
fbOwnerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
fbOwnerScroll.CanvasSize = UDim2.new()
fbOwnerScroll.ZIndex = 33
fbOwnerScroll.Parent = fbOwnerPane
addCorner(fbOwnerScroll, 8)
addStroke(fbOwnerScroll, Color3.fromRGB(64, 68, 76), 1)

local fbOwnerTxtBox = Instance.new("TextBox")
fbOwnerTxtBox.Name = "OwnerTxtBox"
fbOwnerTxtBox.Size = UDim2.new(1, -20, 0, 0)
fbOwnerTxtBox.Position = UDim2.fromOffset(10, 10)
fbOwnerTxtBox.AutomaticSize = Enum.AutomaticSize.Y
fbOwnerTxtBox.BackgroundTransparency = 1
fbOwnerTxtBox.Font = Enum.Font.Code
fbOwnerTxtBox.TextSize = 13
fbOwnerTxtBox.TextColor3 = Color3.fromRGB(228, 232, 240)
fbOwnerTxtBox.TextXAlignment = Enum.TextXAlignment.Left
fbOwnerTxtBox.TextYAlignment = Enum.TextYAlignment.Top
fbOwnerTxtBox.TextWrapped = true
fbOwnerTxtBox.TextEditable = false
fbOwnerTxtBox.ClearTextOnFocus = false
fbOwnerTxtBox.Text = "Loading player_feedback.txt..."
fbOwnerTxtBox.ZIndex = 34
fbOwnerTxtBox.Parent = fbOwnerScroll

local function updateSubmitButtonVisual()
	local trimmed = string.match(fbInput.Text, "^%s*(.-)%s*$") or ""
	local canSend = #trimmed >= 2
	fbSubmitBtn.BackgroundColor3 = if canSend then Color3.fromRGB(56, 92, 214) else Color3.fromRGB(43, 56, 99)
	fbSubmitBtn.TextColor3 = if canSend then Color3.new(1, 1, 1) else Color3.fromRGB(155, 163, 181)
end

fbInput:GetPropertyChangedSignal("Text"):Connect(function()
	if #fbInput.Text > 500 then
		fbInput.Text = string.sub(fbInput.Text, 1, 500)
	end
	updateSubmitButtonVisual()
end)

closeFeedbackModal = function()
	feedbackModal.Visible = false
end

fbCloseBtn.Activated:Connect(function()
	playSfx("click")
	feedbackModal.Visible = false
end)

fbOwnerBtn.Activated:Connect(function()
	playSfx("click")
	local showingLog = not fbOwnerPane.Visible
	fbOwnerPane.Visible = showingLog
	fbComposePane.Visible = not showingLog
	fbOwnerBtn.Text = if showingLog then "✏️ Compose" else "📄 feedback.txt"
	if showingLog then
		Remotes.MetaAction:FireServer("GetOwnerFeedbackTxt")
	end
end)

fbSubmitBtn.Activated:Connect(function()
	local trimmed = string.match(fbInput.Text, "^%s*(.-)%s*$") or ""
	if #trimmed < 2 then
		return
	end
	playSfx("click")
	popGui(fbSubmitBtn, 0.96)
	Remotes.MetaAction:FireServer("SubmitFeedback", trimmed)
end)

openFeedbackModal = function()
	if currentPhase ~= "Idle" then
		return
	end
	modalWrap.Visible = false
	shopWindow.Visible = false
	fbOwnerPane.Visible = false
	fbComposePane.Visible = true
	fbOwnerBtn.Text = "📄 feedback.txt"
	updateSubmitButtonVisual()
	feedbackModal.Visible = true
	popGui(feedbackModal, 0.92)
	playSfx("click")
end

Remotes.FeedbackSync.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	if payload.kind == "Open" then
		openFeedbackModal()
	elseif payload.kind == "Submitted" then
		fbInput.Text = ""
		updateSubmitButtonVisual()
		feedbackModal.Visible = false
		playSfx("rare")
	elseif payload.kind == "Log" and typeof(payload.txt) == "string" then
		fbOwnerBtn.Visible = true
		fbOwnerTxtBox.Text = payload.txt
	end
end)
end -- setupFeedbackModal
setupFeedbackModal()
end -- feedback modal]=]
print("Loaded c_8")

_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[5] = [=[ 40), UDim2.new(0.5, -26, 0.46, -20), Color3.fromHex("#FFD21F"))

local rolledInfoLabel = makeLabel(overlay, "ROLLING...", UDim2.new(0.46, 0, 0, 32), UDim2.new(0.27, 0, 0.68, 0), Color3.new(1, 1, 1))
local luckBtn = makeButton(buildCenterWrap, "      LUCK: 1x [→1.5x $750]", UDim2.fromOffset(216, 30), UDim2.new(0.5, -108, 0.74, 0), Color3.fromHex("#22C55E"))
UITheme.styleButton(luckBtn, "Lime", 6)
UITheme.addStuds(luckBtn, 0.88, 16)

do
	local matchClover = Instance.new("ImageLabel")
	matchClover.Name = "Icon_Clover"
	matchClover.Size = UDim2.fromOffset(24, 24)
	matchClover.Position = UDim2.new(0, 6, 0.5, -12)
	matchClover.BackgroundTransparency = 1
	matchClover.Image = UITheme.Assets.CloverIcon
	matchClover.ScaleType = Enum.ScaleType.Fit
	matchClover.ZIndex = luckBtn.ZIndex + 3
	matchClover.Parent = luckBtn
end
luckBtn.Activated:Connect(function()
	Remotes.MatchAction:FireServer("UpgradeLuck")
end)

-- Left (My 6 Attribute Slots) & Right (Opponent 6 Attribute Slots) matching Section 7.2 & 7.3
type SlotRow = {
	rowFrame: Frame,
	squareBtn: TextButton,
	plusLabel: TextLabel,
	miniPortrait: Frame,
	faceViewport: ViewportFrame,
	faceMount: ViewportMount,
	titleLabel: TextLabel,
	subLabel: TextLabel,
	scoreBadge: TextLabel,
	stealTag: TextButton?,
}
local mySlotRows: { [string]: SlotRow } = {}
local oppSlotRows: { [string]: SlotRow } = {}

local leftHeader = makeLabel(overlay, "YOU", UDim2.new(0.26, 0, 0, 26), UDim2.new(0.03, 0, 0.14, 0), Color3.fromHex("#1E6FFF"))
leftHeader.Visible = false
local rightHeader = makeLabel(overlay, "OPPONENT", UDim2.new(0.26, 0, 0, 26), UDim2.new(0.71, 0, 0.14, 0), Color3.fromHex("#E5252A"))
rightHeader.Visible = false

local function animateCardFlyToSlot(targetSquare: GuiObject)
	if not myCardWidget.frame.Visible then
		return
	end
	local clone = Instance.new("Frame")
	clone.Size = UDim2.fromOffset(186, 214)
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Position = myCardWidget.frame.Position
	clone.BackgroundColor3 = myCardWidget.kitColor
	clone.ZIndex = 25
	addCorner(clone, 12)
	addStroke(clone, Color3.new(1, 1, 1), 3)
	clone.Parent = overlay

	local absPos = targetSquare.AbsolutePosition
	local absSize = targetSquare.AbsoluteSize
	local targetCenter = absPos + absSize * 0.5
	local vp = overlay.AbsoluteSize
	local destScale = if vp.X > 0 and vp.Y > 0
		then UDim2.fromScale(targetCenter.X / vp.X, targetCenter.Y / vp.Y)
		else UDim2.fromScale(0.265, 0.4)

	local tw = TweenService:Create(clone, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = destScale,
		Size = UDim2.fromOffset(48, 48),
		BackgroundTransparency = 0.2,
	})
	tw:Play()
	tw.Completed:Connect(function()
		clone:Destroy()
	end)
end

for idx, attr in GameConfig.ATTRIBUTES do
	local yPos = 0.18 + (idx - 1) * 0.092
	local icon = ATTR_ICONS[attr] or ""
	local fullLabel = GameConfig.ATTRIBUTE_LABELS[attr] or attr

	-- LEFT ROW (YOUR SLOTS): Right-aligned [FullLabel + Icon] + Subtitle on left, 48x48 [+] Square at x = 0.25
	local myWrap = Instance.new("Frame")
	myWrap.Size = UDim2.new(0.275, 0, 0, 52)
	myWrap.Position = UDim2.new(0.02, 0, yPos, 0)
	myWrap.BackgroundTransparency = 1
	myWrap.Parent = overlay

	local myTitle = makeLabel(myWrap, `{fullLabel} {icon}`, UDim2.new(1, -60, 0, 28), UDim2.new(0, 0, 0, 2), Color3.new(1, 1, 1))
	myTitle.TextXAlignment = Enum.TextXAlignment.Right

	local mySub = makeLabel(myWrap, "Please Select...", UDim2.new(1, -60, 0, 18), UDim2.new(0, 0, 0, 30), Color3.fromRGB(200, 208, 222))
	mySub.TextXAlignment = Enum.TextXAlignment.Right

	local mySq = makeButton(myWrap, "", UDim2.fromOffset(48, 48), UDim2.new(1, -48, 0.5, -24), GameConfig.UI_COLORS.SlotSquare)
	mySq.BackgroundTransparency = 0.25

	local myPlus = makeLabel(mySq, "+", UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.1, 0, 0.1, 0), Color3.new(1, 1, 1))

	local myMini = Instance.new("Frame")
	myMini.Size = UDim2.new(1, -6, 1, -6)
	myMini.Position = UDim2.fromOffset(3, 3)
	myMini.BackgroundColor3 = Color3.fromHex("#1E6FFF")
	myMini.ClipsDescendants = true
	myMini.Visible = false
	addCorner(myMini, 8)
	myMini.Parent = mySq
	local myFaceVp = createFaceViewport(myMini)
	addCorner(myFaceVp, 8)

	local myBadge = makeLabel(mySq, "84", UDim2.fromOffset(34, 24), UDim2.new(1, -18, 1, -14), Color3.fromHex("#FFD21F"))
	myBadge.BackgroundTransparency = 0
	myBadge.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	myBadge.ZIndex = 5
	myBadge.Visible = false
	addCorner(myBadge, 6)
	addStroke(myBadge, Color3.new(0, 0, 0), 2)

	-- Make entire row clickable for easy placement
	local rowClick = Instance.new("TextButton")
	rowClick.Size = UDim2.new(1, -52, 1, 0)
	rowClick.BackgroundTransparency = 1
	rowClick.Text = ""
	rowClick.Parent = myWrap

	local function triggerPlace()
		if currentPhase == "Build" and currentSubPhase == "Selecting" and not currentPlacedThisRound and myPlus.Visible then
			currentPlacedThisRound = true
			animateCardFlyToSlot(mySq)
			Remotes.MatchAction:FireServer("PlaceSlot", attr)
		end
	end
	mySq.Activated:Connect(triggerPlace)
	rowClick.Activated:Connect(triggerPlace)

	mySlotRows[attr] = {
		rowFrame = myWrap,
		squareBtn = mySq,
		plusLabel = myPlus,
		miniPortrait = myMini,
		faceViewport = myFaceVp,
		faceMount = { model = nil, modelId = nil },
		titleLabel = myTitle,
		subLabel = mySub,
		scoreBadge = myBadge,
		stealTag = nil,
	}

	-- RIGHT ROW (OPPONENT SLOTS): Mirrored! 48x48 Square on left, Left-aligned [Icon + FullLabel] + Subtitle on right
	local oppWrap = Instance.new("Frame")
	oppWrap.Size = UDim2.new(0.275, 0, 0, 52)
	oppWrap.Position = UDim2.new(0.705, 0, yPos, 0)
	oppWrap.BackgroundTransparency = 1
	oppWrap.Parent = overlay

	local oppSq = makeButton(oppWrap, "", UDim2.fromOffset(48, 48), UDim2.new(0, 0, 0.5, -24), GameConfig.UI_COLORS.SlotSquare)
	oppSq.BackgroundTransparency = 0.25
	oppSq.AutoButtonColor = false

	local oppPlus = makeLabel(oppSq, "", UDim2.fromScale(1, 1), UDim2.new(), Color3.new(1, 1, 1))

	local oppMini = Instance.new("Frame")
	oppMini.Size = UDim2.new(1, -6, 1, -6)
	oppMini.Position = UDim2.fromOffset(3, 3)
	oppMini.BackgroundColor3 = Color3.fromHex("#E5252A")
	oppMini.ClipsDescendants = true
	oppMini.Visible = false
	addCorner(oppMini, 8)
	oppMini.Parent = oppSq
	local oppFaceVp = createFaceViewport(oppMini)
	addCorner(oppFaceVp, 8)

	local oppBadge = makeLabel(oppSq, "80", UDim2.fromOffset(34, 24), UDim2.new(0, -14, 1, -14), Color3.fromHex("#FFD21F"))
	oppBadge.BackgroundTransparency = 0
	oppBadge.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	oppBadge.ZIndex = 5
	oppBadge.Visible = false
	addCorner(oppBadge, 6)
	addStroke(oppBadge, Color3.new(0, 0, 0), 2)

	local stealTag = makeButton(oppSq, "STEAL", UDim2.new(1.16, 0, 0, 20), UDim2.new(-0.08, 0, 1, -16), GameConfig.UI_COLORS.Steal)
	stealTag.ZIndex = 6
	stealTag.Visible = false
	stealTag.Activated:Connect(function()
		Remotes.MatchAction:FireServer("Steal", attr, attr)
	end)
	oppSq.Activated:Connect(function()
		if stealTag.Visible then
			Remotes.MatchAction:FireServer("Steal", attr, attr)
		end
	end)

	local oppTitle = makeLabel(oppWrap, `{icon} {fullLabel}`, UDim2.new(1, -60, 0, 28), UDim2.new(0, 60, 0, 2), Color3.new(1, 1, 1))
	oppTitle.TextXAlignment = Enum.TextXAlignment.Left

	local oppSub = makeLabel(oppWrap, "Selecting...", UDim2.new(1, -60, 0, 18), UDim2.new(0, 60, 0, 30), Color3.fromRGB(200, 208, 222))
	oppSub.TextXAlignment = Enum.TextXAlignment.Left

	oppSlotRows[attr] = {
		rowFrame = oppWrap,
		squareBtn = oppSq,
		plusLabel = oppPlus,
		miniPortrait = oppMini,
		faceViewport = oppFaceVp,
		faceMount = { model = nil, modelId = nil },
		titleLabel = oppTitle,
		subLabel = oppSub,
		scoreBadge = oppBadge,
		stealTag = stealTag,
	}
end

-- 5 Bottom Action Buttons (Build phase)
local actionBar = Instance.new("Frame")
actionBar.Size = UDim2.new(0.76, 0, 0, 56)
actionBar.Position = UDim2.new(0.12, 0, 0.83, 0)
actionBar.BackgroundTransparency = 1
actionBar.Parent = overlay

local btnRevealAll = makeButton(actionBar, "👁️ REVEAL ALL\nR$29", UDim2.new(0.18, 0, 1, 0), UDim2.new(0.00, 0, 0, 0), GameConfig.UI_COLORS.RevealAll)
local btnSeeBest = makeButton(actionBar, "🔍 SEE BEST\nR$9", UDim2.new(0.18, 0, 1, 0), UDim2.new(0.205, 0, 0, 0), GameConfig.UI_COLORS.SeeBest)
local btnReroll = makeButton(actionBar, "🎲 REROLL (2)\nR$19", UDim2.new(0.18, 0, 1, 0), UDim2.new(0.41, 0, 0, 0), GameConfig.UI_COLORS.Reroll)
local btnSteal = makeButton(actionBar, "😈 STEAL (1)\nR$39", UDim2.new(0.18, 0, 1, 0), UDim2.new(0.615, 0, 0, 0), GameConfig.UI_COLORS.Steal)
local btnShuffle = makeButton(actionBar, "🔀 SHUFFLE\nFREE", UDim2.new(0.18, 0, 1, 0), UDim2.new(0.82, 0, 0, 0), GameConfig.UI_COLORS.Shuffle)

btnRevealAll.Activated:Connect(function()
	Remotes.MatchAction:FireServer("RevealAll")
end)
btnSeeBest.Activated:Connect(function()
	Remotes.MatchAction:FireServer("SeeBest")
end)
btnReroll.Activated:Connect(function()
	Remotes.MatchAction:FireServer("Reroll")
end)
btnShuffle.Activated:Connect(function()
	Remotes.MatchAction:FireServer("Shuffle")
end)
btnSteal.Activated:Connect(function()
	for _, attr in GameConfig.ATTRIBUTES do
		local sBtn = oppSlotRows[attr].stealTag
		if sBtn and sBtn.Visible then
			Remotes.MatchAction:FireServer("Steal", attr, attr)
			break
		end
	end
end)

-- ============================================================
-- 2D. SHOWDOWN SCREEN (COUNTDOWN 5..1..FIGHT!, SLIDE-IN CLASH, LOSER KNOCKOUT)
-- ============================================================
local showdownWrap = Instance.new("Frame")
showdownWrap.Size = UDim2.fromScale(1, 1)
showdownWrap.BackgroundTransparency = 1
showdownWrap.Visible = false
showdownWrap.Parent = overlay

local function createPortraitCard(parent: Instance, pos: UDim2, _bgCol: Color3)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(180, 196)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = pos
	card.BackgroundTransparency = 1
	card.Parent = parent

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromOffset(168, 168)
	img.Position = UDim2.fromOffset(6, 0)
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = card

	local nameLbl = makeLabel(card, "Player", UDim2.new(0.92, 0, 0, 24), UDim2.new(0.04, 0, 1, -26), Color3.new(1, 1, 1))
	return card, img, nameLbl
end

local sdMyCard, sdMyImg, sdMyName = createPortraitCard(showdownWrap, UDim2.fromScale(0.35, 0.34), Color3.fromHex("#1E6FFF"))
local sdOppCard, sdOppImg, sdOppName = createPortraitCard(showdownWrap, UDim2.fromScale(0.65, 0.34), Color3.fromHex("#D61F1F"))
local sdVsLabel = makeLabel(showdownWrap, "VS", UDim2.fromOffset(64, 48), UDim2.new(0.5, -32, 0.34, -24), Color3.fromHex("#FFD21F"))
local sdCountdownLbl = makeLabel(showdownWrap, "5", UDim2.fromOffset(180, 74), UDim2.new(0.5, -90, 0.14, 0), Color3.new(1, 1, 1))
local sdClashSpark = makeLabel(showdownWrap, "⚽", UDim2.fromOffset(72, 72), UDim2.new(0.5, -36, 0.45, -36), Color3.new(1, 1, 1))
sdClashSpark.Visible = false

local function createAvgScoreBox(parent: Instance, pos: UDim2, bgCol: Color3)
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(132, 70)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = pos
	box.BackgroundColor3 = bgCol
	addCorner(box, 10)
	addStroke(box, Color3.new(0, 0, 0), 3)
	box.Parent = parent

	makeLabel(box, "AVG SCORE", UDim2.new(0.9, 0, 0, 20), UDim2.new(0.05, 0, 0, 6), Color3.new(1, 1, 1))
	local valLbl = makeLabel(box, "0.0", UDim2.new(0.9, 0, 0, 38), UDim2.new(0.05, 0, 0, 26), Color3.fromHex("#FFD21F"))
	return box, valLbl
end

local sdMyAvgBox, sdMyAvgLbl = createAvgScoreBox(showdownWrap, UDim2.fromScale(0.35, 0.80), GameConfig.UI_COLORS.BlueAvgBox)
local sdOppAvgBox, sdOppAvgLbl = createAvgScoreBox(showdownWrap, UDim2.fromScale(0.65, 0.80), GameConfig.UI_COLORS.RedAvgBox)

-- ============================================================
-- 2E. WINNER SCREEN + GRADE SLAM + RADAR CHART + FLIP + SUMMARY POPUP
-- ============================================================
local winnerWrap = Instance.new("Frame")
winnerWrap.Size = UDim2.fromScale(1, 1)
winnerWrap.BackgroundTransparency = 1
winnerWrap.Visible = false
winnerWrap.Parent = overlay

local winPortraitCard, winPortraitImg, winPortraitName = createPortraitCard(winnerWrap, UDim2.fromScale(0.50, 0.36), Color3.fromHex("#1E6FFF"))
local winCrownLabel = Instance.new("ImageLabel")
winCrownLabel.Name = "WinCrown"
winCrownLabel.Size = UDim2.fromOffset(52, 52)
winCrownLabel.Position = UDim2.new(0.5, -26, 0, -36)
winCrownLabel.BackgroundTransparency = 1
winCrownLabel.Image = UITheme.Assets.CrownIcon
winCrownLabel.ScaleType = Enum.ScaleType.Fit
winCrownLabel.ZIndex = winPortraitCard.ZIndex + 5
winCrownLabel.Parent = winPortraitCard

local winGradeBadge = makeLabel(winPortraitCard, "B", UDim2.fromOffset(42, 42), UDim2.new(1, -22, 1, -24), Color3.fromHex("#22C55E"))
winGradeBadge.BackgroundTransparency = 0
winGradeBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
winGradeBadge.ZIndex = 8
addCorner(winGradeBadge, 10)
addStroke(winGradeBadge, Color3.new(0, 0, 0), 3)

local winAvgBox, winAvgValLbl = createAvgScoreBox(winnerWrap, UDim2.fromScale(0.50, 0.56), GameConfig.UI_COLORS.BlueAvgBox)

local btnFlipBoard = makeButton(winnerWrap, "", UDim2.fromOffset(70, 58), UDim2.new(0.59, 0, 0.36, -29), Color3.fromHex("#FFA500"))
do
	local ink = Color3.fromRGB(22, 24, 28)
	local icon = Instance.new("Frame")
	icon.Name = "RefreshIcon"
	icon.Size = UDim2.fromOffset(28, 26)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 5)
	icon.BackgroundTransparency = 1
	icon.Parent = btnFlipBoard

	local topClip = Instance.new("Frame")
	topClip.Name = "TopArcClip"
	topClip.Size = UDim2.fromOffset(24, 10)
	topClip.Position = UDim2.fromOffset(2, 2)
	topClip.BackgroundTransparency = 1
	topClip.ClipsDescendants = true
	topClip.Parent = icon

	local topRing = Instance.new("Frame")
	topRing.Size = UDim2.fromOffset(20, 20)
	topRing.Position = UDim2.fromOffset(2, 1)
	topRing.BackgroundTransparency = 1
	topRing.Parent = topClip
	addCorner(topRing, 10)
	addStroke(topRing, ink, 3.6)

	local botClip = Instance.new("Frame")
	botClip.Name = "BotArcClip"
	botClip.Size = UDim2.fromOffset(24, 10)
	botClip.Position = UDim2.fromOffset(2, 14)
	botClip.BackgroundTransparency = 1
	botClip.ClipsDescendants = true
	botClip.Parent = icon

	local botRing = Instance.new("Frame")
	botRing.Size = UDim2.fromOffset(20, 20)
	botRing.Position = UDim2.fromOffset(2, -11)
	botRing.BackgroundTransparency = 1
	botRing.Parent = botClip
	addCorner(botRing, 10)
	addStroke(botRing, ink, 3.6)

	local function makeWing(name: string, w: number, h: number, anchor: Vector2, pos: UDim2, rot: number)
		local wing = Instance.new("Frame")
		wing.Name = name
		wing.Size = UDim2.fromOffset(w, h)
		wing.AnchorPoint = anchor
		wing.Position = pos
		wing.Rotation = rot
		wing.BackgroundColor3 = ink
		wing.BorderSizePixel = 0
		wing.Parent = icon
		local wc = Instance.new("UICorner")
		wc.CornerRadius = UDim.new(1, 0)
		wc.Parent = wing
	end

	-- Top-right clockwise arrowhead
	makeWing("ArrowTR_V", 4, 10, Vector2.new(0.5, 0.5), UDim2.fromOffset(23, 7), -14)
	makeWing("ArrowTR_H", 10, 4, Vector2.new(0.5, 0.5), UDim2.fromOffset(20, 11), 14)

	-- Bottom-left clockwise arrowhead
	makeWing("ArrowBL_V", 4, 10, Vector2.new(0.5, 0.5), UDim2.fromOffset(5, 19), -14)
	makeWing("ArrowBL_H", 10, 4, Vector2.new(0.5, 0.5), UDim2.fromOffset(8, 15), 14)

	local flipLbl = makeLabel(btnFlipBoard, "FLIP", UDim2.new(0.92, 0, 0, 22), UDim2.new(0.04, 0, 1, -24), Color3.new(1, 1, 1))
	flipLbl.Name = "FlipLabel"
end

-- Bottom-Right Roblox Badge Awarded Toast on Winner Screen
local badgeToast = Instance.new("Frame")
badgeToast.Size = UDim2.fromOffset(230, 58)
badgeToast.Position = UDim2.new(1, -246, 1, -74)
badgeToast.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
badgeToast.BackgroundTransparency = 0.12
addCorner(badgeToast, 10)
addStroke(badgeToast, Color3.fromHex("#FFD21F"), 2)
badgeToast.Parent = winnerWrap
makeLabel(badgeToast, "🏅", UDim2.fromOffset(42, 42), UDim2.fromOffset(8, 8), Color3.fromHex("#FFD21F"))
local badgeToastTitle = makeLabel(badgeToast, "Badge Awarded!", UDim2.new(1, -58, 0, 22), UDim2.fromOffset(52, 6), Color3.fromHex("#FFD21F"))
badgeToastTitle.TextXAlignment = Enum.TextXAlignment.Left
local badgeToastSub = makeLabel(badgeToast, "First Match Complete!", UDim2.new(1, -58, 0, 20), UDim2.fromOffset(52, 28), Color3.new(1, 1, 1))
badgeToastSub.TextXAlignment = Enum.TextXAlignment.Left

-- 6-Axis Hexagon Radar Chart (Right side of Winner Screen)
local RADAR_SIZE = 246
local RADAR_CENTER = Vector2.new(RADAR_SIZE * 0.5, RADAR_SIZE * 0.5)
local RADAR_RADIUS = 86

local radarPanel = Instance.new("Frame")
radarPanel.Size = UDim2.fromOffset(RADAR_SIZE, RADAR_SIZE)
radarPanel.AnchorPoint = Vector2.new(0.5, 0.5)
radarPanel.Position = UDim2.fromScale(0.81, 0.45)
radarPanel.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
radarPanel.BackgroundTransparency = 0.15
addCorner(radarPanel, 14)
addStroke(radarPanel, Color3.new(0, 0, 0), 3)
radarPanel.Parent = winnerWrap

local function getRadarPoint(idx: number, ratio: number): Vector2
	local angle = math.rad(-90 + (idx - 1) * 60)
	local r = RADAR_RADIUS * math.clamp(ratio, 0.08, 1)
	return RADAR_CENTER + Vector2.new(math.cos(angle) * r, math.sin(angle) * r)
end

for i = 1, 6 do
	local pOuter = getRadarPoint(i, 1)
	local pNext = getRadarPoint((i % 6) + 1, 1)
	local pMid = getRadarPoint(i, 0.55)
	local pMidNext = getRadarPoint((i % 6) + 1, 0.55)

	local axisLine = makeLine(radarPanel, Color3.fromRGB(75, 85, 110), 1)
	setLine(axisLine, RADAR_CENTER, pOuter, 1)

	local outerEdge = makeLine(radarPanel, Color3.fromRGB(95, 110, 140), 2)
	setLine(outerEdge, pOuter, pNext, 2)

	local midEdge = makeLine(radarPanel, Color3.fromRGB(60, 70, 92), 1)
	setLine(midEdge, pMid, pMidNext, 1)

	local lblPos = getRadarPoint(i, 1.24)
	local attrLbl = makeLabel(radarPanel, GameConfig.ATTRIBUTES[i], UDim2.fromOffset(42, 20), UDim2.fromOffset(lblPos.X - 21, lblPos.Y - 10), Color3.new(1, 1, 1))
	attrLbl.ZIndex = 3
end

local radarPolyEdges: { Frame } = {}
local radarSpokeLines: { Frame } = {}
local radarVertexDots: { Frame } = {}
for i = 1, 6 do
	local spoke = makeLine(radarPanel, Color3.fromHex("#F59E0B"), 2)
	spoke.ZIndex = 4
	table.insert(radarSpokeLines, spoke)

	local edge = makeLine(radarPanel, Color3.fromHex("#FFFFFF"), 3)
	edge.ZIndex = 5
	table.insert(radarPolyEdges, edge)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(8, 8)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.ZIndex = 6
	addCorner(dot, 4)
	dot.Parent = radarPanel
	table.insert(radarVertexDots, dot)
end

local radarAnimToken = 0
local function updateRadarChart(slotScores: { [string]: number }?, isSelf: boolean)
	radarAnimToken += 1
	local myToken = radarAnimToken
	local edgeCol = Color3.new(1, 1, 1)
	local spokeCol = if isSelf then Color3.fromHex("#F59E0B") else Color3.fromHex("#F43F5E")

	task.spawn(function()
		local steps = 12
		for step = 1, steps do
			if radarAnimToken ~= myToken then
				return
			end
			local alpha = step / steps
			local pts: { Vector2 } = {}
			for i, attr in GameConfig.ATTRIBUTES do
				local sc = if slotScores and slotScores[attr] then slotScores[attr] else 50
				pts[i] = getRadarPoint(i, (sc / 99) * alpha)
			end
			for i = 1, 6 do
				local p1 = pts[i]
				local p2 = pts[(i % 6) + 1]
				radarPolyEdges[i].BackgroundColor3 = edgeCol
				setLine(radarPolyEdges[i], p1, p2, 3)
				radarSpokeLines[i].BackgroundColor3 = spokeCol
				setLine(radarSpokeLines[i], RADAR_CENTER, p1, 2)
				radarVertexDots[i].Position = UDim2.fromOffset(p1.X, p1.Y)
			end
			task.wait(0.025)
		end
	end)
end

local rematchStatusLbl = makeLabel(winnerWrap, "0/1 - 30s", UDim2.fromOffset(180, 24), UDim2.new(0.5, -166, 0.80, 0), Color3.new(1, 1, 1))
local bottomRematchBtn = makeButton(winnerWrap, "REMATCH", UDim2.fromOffset(180, 48), UDim2.new(0.5, -166, 0.84, 0), Color3.fromHex("#FFA500"))
local rematchVoted = false
bottomRematchBtn.Activated:Connect(function()
	rematchVoted = true
	Remotes.MatchAction:FireServer("Rematch")
end)

local bottomLeaveBtn = makeButton(winnerWrap, "LEAVE", UDim2.fromOffset(140, 48), UDim2.new(0.5, 26, 0.84, 0), GameConfig.UI_COLORS.Steal)
bottomLeaveBtn.Activated:Connect(function()
	Remotes.MatchAction:FireServer("LeaveTable")
end)

-- Post-Match VICTORY! (3s) Summary Modal Popup (parented to screenGui so it displays cleanly on return to Lobby or on demand)
local resultPopup = Instance.new("Frame")
resultPopup.Size = UDim2.fromOffset(620, 360)
resultPopup.AnchorPoint = Vector2.new(0.5, 0.5)
resultPopup.Position = UDim2.fromScale(0.5, 0.50)
resultPopup.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
resultPopup.Visible = false
resultPopup.ZIndex = 28
addCorner(resultPopup, 16)
addStroke(resultPopup, Color3.new(0, 0, 0), 4)
resultPopup.Parent = screenGui

local resultHeader = Instance.new("Frame")
resultHeader.Size = UDim2.new(1, 0, 0, 54)
resultHeader.BackgroundColor3 = Color3.fromHex("#F59E0B")
resultHeader.ZIndex = 28
addCorner(resultHeader, 16)
addStroke(resultHeader, Color3.new(0, 0, 0), 3)
resultHeader.Parent = resultPopup

local resultTitle = makeLabel(resultHeader, "VICTORY! (3s)", UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.04, 0, 0.1, 0), Color3.new(1, 1, 1))
resultTitle.TextXAlignment = Enum.TextXAlignment.Left
resultTitle.ZIndex = 29

local btnCloseResultPopup = makeButton(resultHeader, "X", UDim2.fromOffset(40, 40), UDim2.new(1, -48, 0, 7), Color3.fromHex("#E5252A"))
btnCloseResultPopup.ZIndex = 29
btnCloseResultPopup.Activated:Connect(function()
	resultPopup.Visible = false
end)

local function makeSummaryCard(pos: UDim2, size: UDim2, titleText: string, bg: Color3)
	local c = Instance.new("Frame")
	c.Size = size
	c.Position = pos
	c.BackgroundColor3 = bg
	c.ZIndex = 29
	addCorner(c, 10)
	addStroke(c, Color3.new(0, 0, 0), 2)
	c.Parent = resultPopup

	local t = makeLabel(c, titleText, UDim2.new(0.92, 0, 0.28, 0), UDim2.new(0.04, 0, 0.06, 0), Color3.new(1, 1, 1))
	t.ZIndex = 30
	local v = makeLabel(c, "", UDim2.new(0.92, 0, 0.44, 0), UDim2.new(0.04, 0, 0.42, 0), Color3.fromHex("#FFD21F"))
	v.ZIndex = 30
	return c, v
end

local _, sumBuxVal = makeSummaryCard(UDim2.new(0.025, 0, 0, 66), UDim2.new(0.225, 0, 0, 118), "CASH EARNED", Color3.fromRGB(30, 75, 46))
sumBuxVal.TextColor3 = Color3.fromHex("#3DDC3D")
local sumWinsCard, sumWinsVal = makeSummaryCard(UDim2.new(0.266, 0, 0, 66), UDim2.new(0.225, 0, 0, 118), "WINS", Color3.fromRGB(28, 56, 98))
do
	local sumTrophy = Instance.new("ImageLabel")
	sumTrophy.Name = "Icon_Trophy"
	sumTrophy.Size = UDim2.fromOffset(26, 26)
	sumTrophy.Position = UDim2.new(1, -30, 0, 4)
	sumTrophy.BackgroundTransparency = 1
	sumTrophy.Image = UITheme.Assets.TrophyIcon
	sumTrophy.ScaleType = Enum.ScaleType.Fit
	sumTrophy.ZIndex = sumWinsCard.ZIndex + 2
	sumTrophy.Parent = sumWinsCard
end
local _, sumStreakVal = makeSummaryCard(UDim2.new(0.507, 0, 0, 66), UDim2.new(0.225, 0, 0, 118), "WIN STREAK", Color3.fromRGB(98, 42, 28))
local sumQuestCard, sumQuestVal = makeSummaryCard(UDim2.new(0.748, 0, 0, 66), UDim2.new(0.225, 0, 0, 118), "FINISH A MATCH", Color3.fromRGB(58, 36, 92))
sumQuestVal.Size = UDim2.new(0.92, 0, 0.28, 0)
sumQuestVal.Position = UDim2.new(0.04, 0, 0.34, 0)
sumQuestVal.Text = "🎡 +1 SPIN"
local btnSumClaimQuest = makeButton(sumQuestCard, "CLAIM!", UDim2.new(0.84, 0, 0.28, 0), UDim2.new(0.08, 0, 0.66, 0), Color3.fromHex("#22C55E"))
btnSumClaimQuest.ZIndex = 30
btnSumClaimQuest.Activated:Connect(function()
	Remotes.MetaAction:FireServer("ClaimQuest", "finish_match")
	btnSumClaimQuest.Text = "CLAIMED ✓"
	btnSumClaimQuest.BackgroundColor3 = Color3.fromRGB(95, 100, 115)
end)

local _, sumPlay30Val = makeSummaryCard(UDim2.new(0.025, 0, 0, 196), UDim2.new(0.305, 0, 0, 112), "PLAY FOR 30 MINUTES", Color3.fromRGB(36, 44, 62))
local _, sumNextPtVal = makeSummaryCard(UDim2.new(0.347, 0, 0, 196), UDim2.new(0.305, 0, 0, 112), "NEXT: PLAYTIME BUX", Color3.fromRGB(36, 44, 62))
local _, sumNextSkinVal = makeSummaryCard(UDim2.new(0.669, 0, 0, 196), UDim2.new(0.305, 0, 0, 112), "NEXT CHAIR SKIN", Color3.fromRGB(36, 44, 62))

local sumFooterLabel = makeLabel(resultPopup, "1 MATCH PLAYED • 1 WON", UDim2.new(0.8, 0, 0, 26), UDim2.new(0.1, 0, 1, -34), Color3.new(1, 1, 1))
sumFooterLabel.ZIndex = 30

local popupCountdownToken = 0
local lastDidWin = true
local pendingSummaryPopup = false

local function showSummaryPopupWithCountdown(didWin: boolean)
	popupCountdownToken += 1
	local myToken = popupCountdownToken
	resultPopup.Visible = true
	popGui(resultPopup, 0.85)
	local baseTitle = if didWin then "VICTORY!" else "DEFEAT!"
	resultHeader.BackgroundColor3 = if didWin then Color3.fromHex("#F59E0B") else Color3.fromHex("#E5252A")
	task.spawn(function()
		for sec = 3, 1, -1 do
			if popupCountdownToken ~= myToken or not resultPopup.Visible then
				return
			end
			resultTitle.Text = `{baseTitle} ({sec}s)`
			task.wait(1)
		end
		if popupCountdownToken == myToken then
			resultPopup.Visible = false
		end
	end)]=]
print("Loaded c_5")

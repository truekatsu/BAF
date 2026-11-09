_G.oc[4] = [=[ RADAR CHART + FLIP + SUMMARY POPUP
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
	end)
end

-- Helper to populate a slot row in Build, Showdown, or Winner mode
local function populateSlotRow(row: SlotRow, card: any, defaultSub: string, showScore: boolean, scoreVal: number?)
	if card then
		row.plusLabel.Visible = false
		row.miniPortrait.Visible = true
		row.miniPortrait.BackgroundColor3 = Color3.fromHex(card.kitColor):Lerp(Color3.fromRGB(36, 44, 62), 0.32)
		mountViewportModel(row.faceViewport, row.faceMount, card.id)
		row.subLabel.Text = Footballers.getDisplayName(card)
		row.subLabel.TextColor3 = Color3.new(1, 1, 1)
		row.squareBtn.BackgroundColor3 = GameConfig.UI_COLORS.SlotSquare
	else
		row.plusLabel.Visible = true
		row.miniPortrait.Visible = false
		mountViewportModel(row.faceViewport, row.faceMount, nil)
		row.subLabel.Text = defaultSub
		row.subLabel.TextColor3 = Color3.fromRGB(200, 208, 222)
		row.squareBtn.BackgroundColor3 = GameConfig.UI_COLORS.SlotSquare
	end
	row.scoreBadge.Visible = showScore
	if showScore and scoreVal then
		row.scoreBadge.Text = tostring(scoreVal)
	end
end

-- Winner Screen Inspection State (supports FLIP button)
local lastResultState: any = nil
local inspectingSelf = true

local function refreshWinnerInspection(animateSlam: boolean?)
	local st = lastResultState
	if not st then
		return
	end
	local isSelf = inspectingSelf
	local board = if isSelf then st.myBoard else st.oppBoard
	local eval = if isSelf then st.myEval else st.oppEval
	local name = if isSelf then (st.myName or "YOU") else (st.oppName or "OPPONENT")
	local uid = if isSelf then st.myUserId else st.oppUserId
	local isThisWinner = (isSelf and st.didWin) or (not isSelf and not st.didWin)

	modeSubLabel.Visible = true
	if st.didWin then
		modeSubLabel.Text = "🏆 VICTORY!"
		modeSubLabel.TextColor3 = Color3.fromHex("#3DDC3D")
	else
		modeSubLabel.Text = `DEFEAT • WINNER: {st.oppName or "BOT"}`
		modeSubLabel.TextColor3 = Color3.fromHex("#FFD21F")
	end

	headerLabel.Text = if isSelf then "YOUR RESULT" else "OPPONENT RESULT"
	headerLabel.TextColor3 = if isSelf then Color3.fromHex("#FFD21F") else Color3.fromHex("#FF6B6B")
	winnerNameLabel.Visible = true
	winnerNameLabel.Text = name

	winPortraitImg.Image = getAvatarThumb(uid)
	winPortraitName.Text = name
	winCrownLabel.Visible = isThisWinner

	local grade = if eval then eval.grade else "C"
	winGradeBadge.Text = grade
	winGradeBadge.TextColor3 = if grade == "S" or grade == "A" then Color3.fromHex("#22C55E") else Color3.fromHex("#FFD21F")

	winAvgBox.BackgroundColor3 = if isSelf then GameConfig.UI_COLORS.BlueAvgBox else GameConfig.UI_COLORS.RedAvgBox
	winAvgValLbl.Text = if eval then tostring(eval.avgScore) else "0.0"

	for idx, attr in GameConfig.ATTRIBUTES do
		local row = mySlotRows[attr]
		row.rowFrame.Visible = true
		local card = if board and board.slots then board.slots[attr] else nil
		local score = if eval and eval.slotScores then eval.slotScores[attr] else 0
		populateSlotRow(row, card, "-", true, score)
		if animateSlam then
			row.scoreBadge.Visible = false
			task.delay(0.1 * idx, function()
				if currentPhase == "Result" then
					row.scoreBadge.Visible = true
					popGui(row.scoreBadge, 0.45)
				end
			end)
		end
	end

	updateRadarChart(if eval then eval.slotScores else nil, isSelf)
	popGui(winPortraitCard, 0.85)
	if animateSlam then
		popGui(winGradeBadge, 2.4)
	else
		popGui(winGradeBadge, 1.35)
	end
end

btnFlipBoard.Activated:Connect(function()
	inspectingSelf = not inspectingSelf
	refreshWinnerInspection(false)
end)

-- ============================================================
-- 3. STATE SYNC & LIVE TIMERS
-- ============================================================
local function setMyColumnVisible(vis: boolean)
	for _, attr in GameConfig.ATTRIBUTES do
		mySlotRows[attr].rowFrame.Visible = vis
	end
end

local function setOppColumnVisible(vis: boolean)
	for _, attr in GameConfig.ATTRIBUTES do
		oppSlotRows[attr].rowFrame.Visible = vis
		if not vis and oppSlotRows[attr].stealTag then
			oppSlotRows[attr].stealTag.Visible = false
		end
	end
end

local function refreshObbyPrompt(now: number)
	local lobby = Workspace:FindFirstChild("Lobby")
	local obby = if lobby then lobby:FindFirstChild("AgilityObby") else nil
	local finish = if obby then obby:FindFirstChild("ObbyFinish") else nil
	if not finish then
		return
	end
	local nextAt = (localPlayer:GetAttribute("ObbyNextClaimAt") :: number?) or 0
	if nextAt <= 0 and cachedProfile and (cachedProfile.LastObbyClaim or 0) > 0 then
		nextAt = cachedProfile.LastObbyClaim + GameConfig.OBBY_COOLDOWN_SEC
	end
	local rem = nextAt - now
	local prompt = finish:FindFirstChildOfClass("ProximityPrompt")
	local bb = finish:FindFirstChildOfClass("BillboardGui")
	local lbl = if bb then bb:FindFirstChildOfClass("TextLabel") else nil
	if rem > 0 then
		local cd = formatHHMMSS(rem)
		if prompt then
			prompt.ActionText = `Cooldown {cd}`
		end
		if lbl then
			lbl.Text = `⏳ COOLDOWN\n{cd}`
			lbl.TextColor3 = Color3.fromHex("#FFD21F")
		end
	else
		if prompt then
			prompt.ActionText = `Claim +${GameConfig.OBBY_REWARD_BUX}!`
		end
		if lbl then
			lbl.Text = `🎁 FREE GIFT!\n+${GameConfig.OBBY_REWARD_BUX}`
			lbl.TextColor3 = Color3.fromHex("#3DDC3D")
		end
	end
end

local function refreshMetaUI()
	local now = Workspace:GetServerTimeNow()
	refreshObbyPrompt(now)
	local p = cachedProfile
	if not p then
		return
	end
	cashLabel.Text = `$` .. tostring(p.Bux)
	local boostPct = (localPlayer:GetAttribute("FriendsBoostPct") :: number?) or 0
	friendsLabel.Text = `FRIENDS BOOST: +{boostPct}%`
	local wSpinLbl = wheelSpinBtn:FindFirstChild("BtnLabel") :: TextLabel?
	if wSpinLbl then
		wSpinLbl.Text = `🎡 SPIN WHEEL ({p.WheelSpins})`
	else
		wheelSpinBtn.Text = `🎡 SPIN WHEEL ({p.WheelSpins})`
	end
	UITheme.styleButton(wheelSpinBtn, if p.WheelSpins > 0 then "Purple" else "Gray", 8)

	wheelSpinsCountLbl.Text = `🎟️ AVAILABLE SPINS: {p.WheelSpins}`

	local doSpinBtn = spinBtnLabel.Parent :: TextButton
	spinBtnLabel.Text = if wheelSpinning then "🎡 SPINNING..." else `🎡 SPIN WHEEL ({p.WheelSpins})`
	UITheme.styleButton(doSpinBtn, if p.WheelSpins > 0 and not wheelSpinning then "Lime" else "Gray", 10)

	local curLuck = p.Luck or 1
	local nextLuck = GameConfig.getNextLuckTier(curLuck)
	local luckLbl = luckUpgradeBtn:FindFirstChild("BtnLabel") :: TextLabel?
	if nextLuck then
		local txt = `LUCK: {curLuck}x → {nextLuck.luck}x (${nextLuck.cost})`
		if luckLbl then luckLbl.Text = txt else luckUpgradeBtn.Text = txt end
		UITheme.styleButton(luckUpgradeBtn, if p.Bux >= nextLuck.cost then "Lime" else "Gray", 8)
	else
		local txt = `LUCK: {curLuck}x (MAX)`
		if luckLbl then luckLbl.Text = txt else luckUpgradeBtn.Text = txt end
		UITheme.styleButton(luckUpgradeBtn, "Gold", 8)
	end

	-- 1. Daily Rewards
	local dailyRem = math.max(0, DAILY_COOLDOWN_SEC - (now - (p.LastDailyClaim or 0)))
	local canClaimDaily = dailyRem == 0
	if dailyCountdownPlate then
		local countLbl = dailyCountdownPlate:FindFirstChild("CountText") :: TextLabel?
		if countLbl then
			countLbl.Text = formatHHMMSS(dailyRem)
		end
	end
	for i, _ in GameConfig.DAILY_REWARDS do
		local st = dailyStatusLabels[i]
		local card = dailyCardFrames[i]
		if i < p.DailyDay then
			st.Text = "CLAIMED ✓"
			st.TextColor3 = UITheme.Colors.MoneyGreen
			card.BackgroundColor3 = Color3.fromRGB(24, 46, 32)
			UITheme.applyStroke(card, 3, UITheme.Colors.Black)
		elseif i == p.DailyDay then
			st.Text = if canClaimDaily then "READY!" else formatMMSS(dailyRem)
			st.TextColor3 = UITheme.Colors.NoticeYellow
			card.BackgroundColor3 = if canClaimDaily then Color3.fromRGB(56, 48, 22) else UITheme.Colors.CardBg
			UITheme.applyStroke(card, 3.5, if canClaimDaily then UITheme.Colors.NoticeYellow else UITheme.Colors.Black)
		else
			st.Text = "LOCKED"
			st.TextColor3 = Color3.fromRGB(150, 155, 170)
			card.BackgroundColor3 = UITheme.Colors.CardBg
			UITheme.applyStroke(card, 3, UITheme.Colors.Black)
		end
	end
	if canClaimDaily then
		btnClaimDaily.Visible = true
		btnClaimDaily.Text = `CLAIM!`
		UITheme.styleButton(btnClaimDaily, "Lime", 8)
	else
		btnClaimDaily.Visible = false
	end

	-- 2. Group Reward
	local grpLbl = btnClaimGroup:FindFirstChild("BtnLabel") :: TextLabel?
	if p.GroupClaimed then
		if grpLbl then
			grpLbl.Text = "✓ CLAIMED"
			grpLbl.TextColor3 = UITheme.Colors.TabInactiveText
		end
		UITheme.styleButton(btnClaimGroup, "Gray", 8)
	else
		if grpLbl then
			grpLbl.Text = "CLAIM $250!"
			grpLbl.TextColor3 = UITheme.Colors.White
		end
		UITheme.styleButton(btnClaimGroup, "Lime", 8)
	end

	-- 3. Playtime Rewards
	local elapsed = math.max(0, now - (p.SessionJoinTime or now))
	playedElapsedLabel.Text = `⏱️ {formatMMSS(elapsed)} played`
	local readyPlaytimeCount = 0
	local nextPtRem = 0
	for _, pt in GameConfig.PLAYTIME_REWARDS do
		local b = playtimeButtons[pt.id]
		local claimed = p.PlaytimeClaimed and p.PlaytimeClaimed[pt.id]
		local progFill = b:FindFirstChild("ProgressFill") :: Frame?
		if progFill then
			local pct = math.clamp(elapsed / pt.seconds, 0, 1)
			progFill.Size = UDim2.fromScale(pct, 1)
		end
		if claimed then
			b.Text = "✓ CLAIMED"
			UITheme.styleButton(b, "Dark", 6)
			b.TextColor3 = UITheme.Colors.TabInactiveText
		elseif elapsed >= pt.seconds then
			b.Text = "CLAIM!"
			UITheme.styleButton(b, "Lime", 6)
			b.TextColor3 = UITheme.Colors.White
			UITheme.applyStroke(b, 2.5, UITheme.Colors.Black)
			readyPlaytimeCount += 1
		else
			local rem = pt.seconds - elapsed
			if nextPtRem == 0 then
				nextPtRem = rem
			end
			b.Text = `🔒 {formatMMSS(rem)}`
			UITheme.styleButton(b, "Dark", 6)
			b.TextColor3 = Color3.fromHex("#D0D4DC")
			UITheme.applyStroke(b, 2, UITheme.Colors.Black)
		end
	end
	playtimeTabBadge.Visible = readyPlaytimeCount > 0
	playtimeTabBadge.Text = tostring(readyPlaytimeCount)

	local freeReadyTotal = (if canClaimDaily then 1 else 0) + (if not p.GroupClaimed then 1 else 0) + readyPlaytimeCount
	freeBadge.Visible = freeReadyTotal > 0
	freeBadge.Text = tostring(freeReadyTotal)

	-- 4. Quests
	local readyQuests = 0
	for _, q in GameConfig.QUESTS do
		local prog = math.min(q.target, (p.QuestProgress and p.QuestProgress[q.id]) or 0)
		local claimed = p.QuestClaimed and p.QuestClaimed[q.id]
		local pLbl = questProgLabels[q.id]
		local cBtn = questClaimBtns[q.id]
		pLbl.Text = `{prog}/{q.target}`
		pLbl.BackgroundColor3 = if prog >= q.target then UITheme.Colors.LimeTop else UITheme.Colors.CardDark
		if claimed then
			cBtn.Text = "CLAIMED"
			UITheme.styleButton(cBtn, "Gray", 6)
		elseif prog >= q.target then
			cBtn.Text = "CLAIM!"
			UITheme.styleButton(cBtn, "Lime", 6)
			readyQuests += 1
		else
			cBtn.Text = "CLAIM"
			UITheme.styleButton(cBtn, "Gray", 6)
		end
	end
	questBadge.Visible = readyQuests > 0
	questBadge.Text = tostring(readyQuests)

	-- 5. Skins
	local nextSkinNeeded = 0
	for _, skin in GameConfig.CHAIR_SKINS do
		local b = skinActionBtns[skin.id]
		if b then
			local owned = p.OwnedChairs and p.OwnedChairs[skin.id]
			if not owned and skin.cost > 0 and nextSkinNeeded == 0 then
				nextSkinNeeded = math.max(0, skin.cost - p.Bux)
			end
			if p.EquippedChair == skin.id then
				UITheme.skinButton(b, "EQUIPPED", skin.cost, true)
			elseif owned then
				UITheme.skinButton(b, "EQUIP", skin.cost, true)
			else
				local canAfford = (p.Bux >= skin.cost)
				UITheme.skinButton(b, "BUY", skin.cost, canAfford)
			end
		end
	end

	-- 6. Titles
	titlesWinsHeader.Text = `WINS: {p.Wins}`
	for _, entry in GameConfig.TITLES do
		local b = titleActionBtns[entry.name]
		if p.EquippedTitle == entry.name then
			b.Text = "EQUIPPED"
			UITheme.styleButton(b, "Lime", 6)
		elseif p.Wins >= entry.minWins then
			b.Text = "EQUIP"
			UITheme.styleButton(b, "Blue", 6)
		else
			b.Text = `LOCKED ({entry.minWins})`
			UITheme.styleButton(b, "Gray", 6)
		end
	end

	-- 7. Card Index (152 Footballers)
	local disc = p.DiscoveredCards or {}
	local discCount = 0
	for cardId, cellInfo in indexCardCells do
		local c = cellInfo.card
		if disc[cardId] then
			discCount += 1
			cellInfo.frame.BackgroundColor3 = Color3.fromRGB(32, 42, 60)
			cellInfo.label.TextColor3 = GameConfig.RARITY_COLORS[c.rarity]
			cellInfo.label.Text = `{c.ovr} {c.pos}\n{Footballers.getDisplayName(c)}\n{string.upper(c.rarity)}`
		else
			cellInfo.frame.BackgroundColor3 = UITheme.Colors.CardBg
			cellInfo.label.TextColor3 = Color3.fromRGB(140, 145, 160)
			cellInfo.label.Text = `??? {c.pos}\nLOCKED\n{string.upper(c.rarity)}`
		end
	end
	local pct = math.round((discCount / #Footballers.All) * 100)
	indexProgressHeader.Text = `DISCOVERED: {discCount} / {#Footballers.All} ({pct}%) • +$25–$250 PER NEW CARD!`
	local ib = btnNavIndex:FindFirstChild("IndexBadge") :: TextLabel?
	if ib then
		ib.Text = `{discCount}/{#Footballers.All}`
	end

	-- 8. Player Profile & Stats Tracker
	updateProfilePage(p, elapsed, disc, discCount, pct)

	local minsPlayed = math.min(30, math.floor(elapsed / 60))
	sumPlay30Val.Text = `{minsPlayed}/30 MIN`
	sumNextPtVal.Text = if readyPlaytimeCount > 0 then "READY TO CLAIM!" else `{formatMMSS(nextPtRem)} LEFT`
	sumNextSkinVal.Text = if nextSkinNeeded > 0 then `\${nextSkinNeeded} MORE` else "READY / UNLOCKED!"
	sumFooterLabel.Text = `{p.MatchesPlayed or 1} MATCH PLAYED • {p.Wins or 0} WON`
end

local refreshMythicalVoteUI: () -> ()

local function setupMythicalVoteUI()
	-- Backdrop (click outside to close)
	local voteBackdrop = Instance.new("TextButton")
	voteBackdrop.Name = "VoteLockedBackdrop"
	voteBackdrop.Size = UDim2.fromScale(1, 1)
	voteBackdrop.Position = UDim2.fromScale(0, 0)
	voteBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	voteBackdrop.BackgroundTransparency = 0.55
	voteBackdrop.Text = ""
	voteBackdrop.AutoButtonColor = false
	voteBackdrop.ZIndex = 48
	voteBackdrop.Visible = false
	voteBackdrop.Parent = screenGui

	local voteLockedModal = Instance.new("Frame")
	voteLockedModal.Name = "VoteLockedModal"
	voteLockedModal.Size = UDim2.fromOffset(480, 360)
	voteLockedModal.AnchorPoint = Vector2.new(0.5, 0.5)
	voteLockedModal.Position = UDim2.fromScale(0.5, 0.5)
	voteLockedModal.BackgroundColor3 = UITheme.Colors.WindowBody
	voteLockedModal.ZIndex = 50
	voteLockedModal.Visible = false
	UITheme.addCorner(voteLockedModal, 16)
	UITheme.applyStroke(voteLockedModal, 4, UITheme.Colors.Black)
	UITheme.addStuds(voteLockedModal, 0.90, 24)
	voteLockedModal.Parent = screenGui

	local modalScale = Instance.new("UIScale")
	modalScale.Scale = 1
	modalScale.Parent = voteLockedModal

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.ZIndex = 51
	UITheme.styleHeader(header, "Orange", "VOTE LOCKED", "Play 5 minutes to unlock your vote")
	header.Parent = voteLockedModal

	local btnCloseVote = Instance.new("TextButton")
	btnCloseVote.Name = "CloseBtn"
	btnCloseVote.Size = UDim2.fromOffset(40, 40)
	btnCloseVote.Position = UDim2.new(1, -48, 0, 8)
	btnCloseVote.Text = "✕"
	btnCloseVote.ZIndex = 52
	UITheme.styleButton(btnCloseVote, "Red", 8)
	btnCloseVote.Parent = header

	local candidateLbl = makeLabel(voteLockedModal, "Voting for: ⚽ LIONEL MESSI", UDim2.new(0.92, 0, 0, 26), UDim2.new(0.04, 0, 0, 66), Color3.fromHex("#38BDF8"))
	candidateLbl.ZIndex = 51

	local clockIcon = Instance.new("ImageLabel")
	clockIcon.Name = "ClockIcon"
	clockIcon.Size = UDim2.fromOffset(36, 36)
	clockIcon.Position = UDim2.new(0.24, 0, 0, 100)
	clockIcon.BackgroundTransparency = 1
	clockIcon.Image = UITheme.Assets.ClockIcon
	clockIcon.ZIndex = 51
	clockIcon.Parent = voteLockedModal

	local countdownLbl = Instance.new("TextLabel")
	countdownLbl.Name = "CountdownLabel"
	countdownLbl.Size = UDim2.new(0.44, 0, 0, 40)
	countdownLbl.Position = UDim2.new(0.34, 0, 0, 98)
	countdownLbl.BackgroundTransparency = 1
	countdownLbl.Font = UITheme.Fonts.Titles
	countdownLbl.TextColor3 = UITheme.Colors.White
	countdownLbl.TextScaled = true
	countdownLbl.Text = "05:00"
	countdownLbl.ZIndex = 51
	UITheme.applyTextStroke(countdownLbl, 3, UITheme.Colors.Black)
	countdownLbl.Parent = voteLockedModal

	local progressRail = Instance.new("Frame")
	progressRail.Name = "ProgressRail"
	progressRail.Size = UDim2.new(0.88, 0, 0, 20)
	progressRail.Position = UDim2.new(0.06, 0, 0, 148)
	progressRail.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	progressRail.ZIndex = 51
	progressRail.ClipsDescendants = true
	UITheme.addCorner(progressRail, 10)
	UITheme.applyStroke(progressRail, 2.5, UITheme.Colors.Black)
	progressRail.Parent = voteLockedModal

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = UITheme.Colors.LimeTop
	progressFill.ZIndex = 52
	UITheme.addCorner(progressFill, 10)
	UITheme.applyGradient(progressFill, UITheme.Colors.LimeTop, UITheme.Colors.LimeBottom, 90)
	progressFill.Parent = progressRail

	local descLbl = Instance.new("TextLabel")
	descLbl.Name = "DescLabel"
	descLbl.Size = UDim2.new(0.88, 0, 0, 36)
	descLbl.Position = UDim2.new(0.06, 0, 0, 176)
	descLbl.BackgroundTransparency = 1
	descLbl.Font = UITheme.Fonts.Body
	descLbl.TextSize = 14
	descLbl.TextColor3 = Color3.fromRGB(210, 218, 235)
	descLbl.TextWrapped = true
	descLbl.Text = "You can vote once you've played for 5 minutes in this server. Keep playing!"
	descLbl.ZIndex = 51
	UITheme.applyTextStroke(descLbl, 1.5, UITheme.Colors.Black)
	descLbl.Parent = voteLockedModal

	local btnVoteAction = Instance.new("TextButton")
	btnVoteAction.Name = "VoteActionButton"
	btnVoteAction.Size = UDim2.new(0.88, 0, 0, 52)
	btnVoteAction.Position = UDim2.new(0.06, 0, 0, 220)
	btnVoteAction.ZIndex = 51
	UITheme.styleButton(btnVoteAction, "Gray", 10)
	btnVoteAction.Text = "VOTE (05:00)"
	btnVoteAction.Parent = voteLockedModal

	local friendlyFooter = Instance.new("TextLabel")
	friendlyFooter.Name = "FriendlyFooter"
	friendlyFooter.Size = UDim2.new(0.92, 0, 0, 22)
	friendlyFooter.Position = UDim2.new(0.04, 0, 0, 286)
	friendlyFooter.BackgroundTransparency = 1
	friendlyFooter.Font = UITheme.Fonts.Body
	friendlyFooter.TextSize = 12
	friendlyFooter.TextColor3 = Color3.fromRGB(156, 163, 175)
	friendlyFooter.Text = "👍 Enjoying the game? Tap the thumbs-up on the game page!"
	friendlyFooter.ZIndex = 51
	UITheme.applyTextStroke(friendlyFooter, 1.5, UITheme.Colors.Black)
	friendlyFooter.Parent = voteLockedModal

	local pendingVoteChoice = "A"
	local isUnlocked = false
	local voteClickDebounce = false
	local countdownThreadToken = 0

	local function closeVoteModal()
		countdownThreadToken += 1
		voteLockedModal.Visible = false
		voteBackdrop.Visible = false
	end

	local function openVoteLockedPopup(payload: any)
		local choice = if type(payload) == "table" then tostring(payload.candidateId or "A") else tostring(payload or "A")
		pendingVoteChoice = if (choice == "A" or choice == "Messi") then "A" else "B"

		local name = if pendingVoteChoice == "A" then "⚽ LIONEL MESSI" else "⚽ CRISTIANO RONALDO"
		local col = if pendingVoteChoice == "A" then Color3.fromHex("#38BDF8") else Color3.fromHex("#FBBF24")
		candidateLbl.Text = `Voting for: {name}`
		candidateLbl.TextColor3 = col

		voteBackdrop.Visible = true
		voteLockedModal.Visible = true
		modalScale.Scale = 0.85
		TweenService:Create(modalScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()

		countdownThreadToken += 1
		local myToken = countdownThreadToken

		task.spawn(function()
			while voteLockedModal.Visible and countdownThreadToken == myToken do
				local sessionStart = (localPlayer:GetAttribute("SessionStart") :: number?) or Workspace:GetServerTimeNow()
				local elapsed = math.max(0, math.floor(Workspace:GetServerTimeNow() - sessionStart))
				local remaining = math.max(0, math.ceil(VoteConfig.MIN_SESSION_SECONDS - elapsed))
				local mm = math.floor(remaining / 60)
				local ss = remaining % 60
				local timeStr = string.format("%02d:%02d", mm, ss)

				countdownLbl.Text = timeStr
				local progress = math.clamp(elapsed / VoteConfig.MIN_SESSION_SECONDS, 0, 1)
				progressFill.Size = UDim2.fromScale(progress, 1)

				if remaining <= 0 then
					if not isUnlocked then
						isUnlocked = true
						UITheme.styleButton(btnVoteAction, "Lime", 10)
						btnVoteAction.Text = "VOTE NOW!"
						UITheme.addPulse(btnVoteAction, 1.0, 1.04, 0.8)
					end
				else
					isUnlocked = false
					btnVoteAction.Text = `VOTE ({timeStr})`
				end

				task.wait(1)
			end
		end)
	end

	btnCloseVote.Activated:Connect(closeVoteModal)
	voteBackdrop.Activated:Connect(closeVoteModal)

	btnVoteAction.Activated:Connect(function()
		if not isUnlocked then
			return
		end
		if voteClickDebounce then
			return
		end
		voteClickDebounce = true
		task.delay(1.5, function()
			voteClickDebounce = false
		end)

		closeVoteModal()
		Remotes.RequestVote:FireServer(pendingVoteChoice)
		Remotes.MetaAction:FireServer("VoteMythical", pendingVoteChoice)
		playSfx("win")
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Escape and voteLockedModal.Visible then
			closeVoteModal()
		end
	end)

	localPlayer.CharacterAdded:Connect(function()
		closeVoteModal()
	end)

	Remotes.OpenVoteLockedPopup.OnClientEvent:Connect(function(payload)
		openVoteLockedPopup(payload)
	end)

	Remotes.MetaAction.OnClientEvent:Connect(function(action, arg)
		if action == "RequireLikeToVote" or action == "OpenVoteLockedPopup" then
			openVoteLockedPopup(tostring(arg or "A"))
		elseif action == "Toast" and typeof(arg) == "string" then
			showToast(arg)
		end
	end)

	-- Session 5-minute unlock global toast notification
	if VoteConfig.NOTIFY_WHEN_UNLOCKED then
		task.spawn(function()
			local hasNotifiedUnlock = false
			while not hasNotifiedUnlock do
				local start = localPlayer:GetAttribute("SessionStart") :: number?
				if start then
					local elapsed = Workspace:GetServerTimeNow() - start
					if elapsed >= VoteConfig.MIN_SESSION_SECONDS then
						hasNotifiedUnlock = true
						showToast("You can now vote!")
						break
					end
				end
				task.wait(2)
			end
		end)
	end

	-- Optional anti-AFK activity ping (client throttled to at most once per 10s)
	if VoteConfig.COUNT_ONLY_ACTIVE_TIME then
		local lastPingSent = 0
		local function reportActivity()
			local now = Workspace:GetServerTimeNow()
			if now - lastPingSent >= 10 then
				lastPingSent = now
				Remotes.ActivityPing:FireServer()
			end
		end
		UserInputService.InputBegan:Connect(function(_input, _processed)
			reportActivity()
		end)
	end

	refreshMythicalVoteUI = function()
		local lobby = Workspace:FindFirstChild("Lobby")
		local voteModel = if lobby then (lobby:FindFirstChild("NextMythicalVote") or (lobby:FindFirstChild("Zones") and lobby.Zones:FindFirstChild("NextMythicalVote"))) else nil
		if not voteModel then
			return
		end
		local myVote = localPlayer:GetAttribute("MythicalVote") :: string?

		local function syncPad(padName: string, voteKey: string)
			local pad = voteModel:FindFirstChild(padName)
			if not pad then
				return
			end
			local bb = pad:FindFirstChild("VotePadBillboard")
			local tag = if bb then bb:FindFirstChild("YourVoteTag") :: TextLabel? else nil
			if tag then
				tag.Visible = (myVote == voteKey)
			end
			local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.ActionText = if myVote == voteKey then "Already Voted" else "Vote"
			end
		end

		syncPad("VotePadA", "Messi")
		syncPad("VotePadB", "Ronaldo")

		local board = voteModel:FindFirstChild("VoteBoard")
		local sg = if board then board:FindFirstChild("VoteBoardGui") else nil
		if sg then
			local statusLbl = sg:FindFirstChild("PlayerVoteStatus", true) :: TextLabel?
			if statusLbl then
				if myVote == "Messi" then
					statusLbl.Text = "(YOUR VOTE: LIONEL MESSI)"
					statusLbl.TextColor3 = Color3.fromHex("#38BDF8")
				elseif myVote == "Ronaldo" then
					statusLbl.Text = "(YOUR VOTE: CRISTIANO RONALDO)"
					statusLbl.TextColor3 = Color3.fromHex("#FBBF24")
				else
					statusLbl.Text = "(STEP ON A PAD OR PRESS [E] TO VOTE!)"
					statusLbl.TextColor3 = Color3.new(1, 1, 1)
				end
			end
		end
	end

	localPlayer:GetAttributeChangedSignal("MythicalVote"):Connect(refreshMythicalVoteUI)
	localPlayer:GetAttributeChangedSignal("LikedGame"):Connect(refreshMythicalVoteUI)
	task.defer(refreshMythicalVoteUI)
end
setupMythicalVoteUI()

local lastTick = 0
local lastCountdownText = ""

local function setupWheelZone()
	local insideWheelZone = false
	local cachedSpinCenter: BasePart? = nil
	local function getSpinCenter(): BasePart?
		if cachedSpinCenter and cachedSpinCenter.Parent then
			return cachedSpinCenter
		end
		local lobby = Workspace:FindFirstChild("Lobby")
		cachedSpinCenter = if lobby then (lobby:FindFirstChild("SpinTriggerCenter", true) :: BasePart?) else (Workspace:FindFirstChild("SpinTriggerCenter", true) :: BasePart?)
		return cachedSpinCenter
	end

	local PPS = game:GetService("ProximityPromptService")
	PPS.PromptTriggered:Connect(function(prompt, player)
		if player == localPlayer and prompt.Name == "SpinPrompt" then
			openModal("WHEEL")
		end
	end)

	local function checkWheelZone()
		if currentPhase ~= "Idle" then return end
		local centerPart = getSpinCenter()
		local hrp = if localPlayer.Character then localPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if centerPart and hrp then
			local radius = math.max((centerPart:GetAttribute("Radius") :: number?) or 4.6, 5.5)
			local dx = hrp.Position.X - centerPart.Position.X
			local dz = hrp.Position.Z - centerPart.Position.Z
			local distXZ = math.sqrt(dx * dx + dz * dz)
			if not insideWheelZone and distXZ <= radius then
				insideWheelZone = true
				openModal("WHEEL")
			elseif insideWheelZone and distXZ > radius + 2.0 then
				insideWheelZone = false
				if modalWrap.Visible and pageWheel.Visible and not wheelSpinning then
					modalWrap.Visible = false
				end
			end
		end
	end

	RunService.Heartbeat:Connect(checkWheelZone)
end
setupWheelZone()

RunService.Heartbeat:Connect(function()
	local now = Workspace:GetServerTimeNow()
	if currentPhase ~= "Idle" then
		if opponentAlertBanner.Visible then
			opponentAlertBanner.Visible = false
		end
	end
	if currentPhase ~= "Idle" and activeEndsAt > 0 then
		local remFloat = math.max(0, activeEndsAt - now)
		local rem = math.ceil(remFloat)
		if currentPhase == "Build" and currentSubPhase == "Rolling" then
			-- Timer stays frozen during ROLLING... subPhase
		else
			timerLabel.Text = `{rem}`
		end
		if currentPhase == "Countdown" then
			local cdText = if remFloat > 2.4
				then "3"
				elseif remFloat > 1.5 then "2"
				elseif remFloat > 0.6 then "1"
				else "GO!"
			if cdText ~= lastCountdownText then
				lastCountdownText = cdText
				countdownBigLabel.Text = cdText
				countdownBigLabel.TextColor3 = if cdText == "GO!" then Color3.fromHex("#3DDC3D") else Color3.new(1, 1, 1)
				popGui(countdownBigLabel, 1.55)
				playSfx("reveal")
			end
		elseif curren]=]
print("Loaded orig 4")

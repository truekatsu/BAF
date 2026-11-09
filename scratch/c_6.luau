_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[6] = [=[
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

	-- 1. Daily Rewards (Figma 25:4 States: Claimed, Ready, Upcoming)
	local canClaimDaily = dailyHandler.update(p, now)
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

	-- 3. Playtime Rewards (Prompt 4 / R6: piece-wise linear rail & nodes)
	local elapsed = math.max(0, now - (p.SessionJoinTime or now))
	playedElapsedLabel.Text = `⏱️ {formatMMSS(elapsed)} played`
	local readyPlaytimeCount = 0
	local nextPtRem = 0
	local pts = GameConfig.PLAYTIME_REWARDS
	local numPts = #pts

	-- Calculate piecewise progress fill across 6 nodes
	local railPct = 0
	if elapsed >= pts[numPts].seconds then
		railPct = 1.0
	else
		for i = 1, numPts - 1 do
			local s0 = if i == 1 then 0 else pts[i - 1].seconds
			local s1 = pts[i].seconds
			if elapsed < s1 then
				local frac = math.clamp((elapsed - s0) / (s1 - s0), 0, 1)
				railPct = ((i - 1) + frac) / (numPts - 1)
				break
			end
		end
	end
	if ptRailFill then
		ptRailFill.Size = UDim2.fromScale(railPct, 1)
	end

	for i, pt in pts do
		local b = playtimeButtons[pt.id]
		local node = playtimeNodes[pt.id]
		local nodeLbl = playtimeNodeIcons[pt.id]
		local inset = playtimeInsetFrames[pt.id]
		local lock = playtimeLockBadges[pt.id]
		local claimed = p.PlaytimeClaimed and p.PlaytimeClaimed[pt.id]
		local isReady = elapsed >= pt.seconds and not claimed

		local progFill = b and b:FindFirstChild("ProgressFill") :: Frame?
		if progFill then
			local sPrev = if i == 1 then 0 else pts[i - 1].seconds
			local cardFrac = math.clamp((elapsed - sPrev) / (pt.seconds - sPrev), 0, 1)
			progFill.Size = UDim2.fromScale(cardFrac, 1)
		end

		-- Node styling
		if node and nodeLbl then
			if claimed then
				node.BackgroundColor3 = Color3.fromHex("#7CFF2B")
				nodeLbl.Text = "✓"
				nodeLbl.TextColor3 = Color3.new(0, 0, 0)
			elseif isReady then
				node.BackgroundColor3 = Color3.fromHex("#FFD21F")
				nodeLbl.Text = "!"
				nodeLbl.TextColor3 = Color3.new(0, 0, 0)
			elseif elapsed >= pt.seconds then
				node.BackgroundColor3 = Color3.fromHex("#FFD21F")
				nodeLbl.Text = ""
			else
				node.BackgroundColor3 = Color3.fromHex("#3A3A40")
				nodeLbl.Text = ""
			end
		end

		-- Lock badge visibility
		if lock then
			lock.Visible = not claimed and not isReady
		end

		-- Button and Inset styling
		if b then
			if claimed then
				b.Text = "✓ CLAIMED"
				UITheme.styleButton(b, "Dark", 5)
				b.TextColor3 = UITheme.Colors.TabInactiveText
				if inset then inset.BackgroundColor3 = Color3.fromRGB(22, 28, 38) end
			elseif isReady then
				b.Text = "CLAIM!"
				UITheme.styleButton(b, "Lime", 5)
				b.TextColor3 = UITheme.Colors.White
				readyPlaytimeCount += 1
				if inset then
					inset.BackgroundColor3 = Color3.fromHex("#FFB940")
				end
			else
				local rem = pt.seconds - elapsed
				if nextPtRem == 0 then nextPtRem = rem end
				b.Text = `🔒 {formatMMSS(rem)}`
				UITheme.styleButton(b, "Dark", 5)
				b.TextColor3 = Color3.fromHex("#FFFFFF")
			end
		end
	end
	dailyTabBadge.Visible = canClaimDaily
	dailyTabBadge.Text = "1"
	groupTabBadge.Visible = not p.GroupClaimed
	groupTabBadge.Text = "1"
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

	-- 5b. Shop Gamepass Ownership (Reactive OWNED badges)
	shopHandler.updateGamepasses(p)
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

do
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
end -- setupMythicalVoteUI

local lastTick = 0
local lastCountdownText = ""

do
local function setupWheelZone()
	local insideWheelZone = false
	local cachedSpinCenter: BasePart? = nil
	local func]=]
print("Loaded c_6")

_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[7] = [=[tion getSpinCenter(): BasePart?
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
		elseif currentPhase == "Result" then
			local prefix = if rematchVoted then `1/1 - {rem}s` else `0/1 - {rem}s`
			rematchStatusLbl.Text = prefix
		end
	end
	if now - lastTick >= 1 then
		lastTick = now
		refreshMetaUI()
		refreshMythicalVoteUI()
	end
end)

Remotes.ProfileUpdate.OnClientEvent:Connect(function(profile: any, _title: string, toast: string?)
	cachedProfile = profile
	local seq = (localPlayer:GetAttribute("WheelSpinSeq") :: number?) or 0
	if seq > lastHandledWheelSeq then
		lastHandledWheelSeq = seq
		local sliceIdx = (localPlayer:GetAttribute("LastWheelSlice") :: number?) or 1
		wheelSpinning = true
		refreshMetaUI()
		playSfx("roll")
		local targetMod = (360 - ((sliceIdx - 1) * 45)) % 360
		local baseTurns = math.floor(wheelCurrentRot / 360) * 360 + 1440
		wheelCurrentRot = baseTurns + targetMod
		local tw = TweenService:Create(wheelRotVal, TweenInfo.new(2.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Value = wheelCurrentRot,
		})
		tw:Play()
		task.delay(2.25, function()
			wheelSpinning = false
			refreshMetaUI()
			if toast and #toast > 0 then
				showToast(toast)
			end
		end)
		return
	end
	refreshMetaUI()
	if toast and #toast > 0 then
		showToast(toast)
	end
end)

Remotes.OpponentAlert.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	if payload.active == true and typeof(payload.tableId) == "string" then
		if currentPhase ~= "Idle" then
			return
		end
		activeAlertTableId = payload.tableId
		alertTitleLbl.Text = `{payload.hostName or "Player"} needs an opponent...`
		alertAvatarImg.Image = getAvatarThumb(payload.hostUserId)
		opponentAlertBanner.Visible = true
		popGui(opponentAlertBanner, 0.90)
		playSfx("rare")
	elseif payload.active == false then
		if payload.tableId == nil or payload.tableId == activeAlertTableId then
			opponentAlertBanner.Visible = false
			activeAlertTableId = nil
		end
	end
end)

local refreshAllSpectateBillboards: () -> () = function() end
local closeFeedbackModal: () -> () = function() end
local openFeedbackModal: () -> () = function() end

Remotes.MatchState.OnClientEvent:Connect(function(state: any)
	local prevPhase = currentPhase
	currentPhase = state.phase
	currentSubPhase = state.subPhase or ""
	setBgmPhase(state.phase)
	refreshAllSpectateBillboards()

	if state.phase == "Idle" then
		currentPlacedThisRound = false
		overlay.Visible = false
		lobbyHud.Visible = true
		activeEndsAt = 0
		rollingToken += 1
		showdownToken += 1
		setMatchBlur(false)
		focusTableCamera(nil, "Idle")
		if prevPhase == "Result" and pendingSummaryPopup then
			pendingSummaryPopup = false
			showSummaryPopupWithCountdown(lastDidWin)
		end
		return
	end

	overlay.Visible = true
	modalWrap.Visible = false
	shopWindow.Visible = false
	closeFeedbackModal()
	if typeof(state.endsAt) == "number" and state.endsAt > 0 then
		activeEndsAt = state.endsAt
	elseif typeof(state.rematchEndsAt) == "number" and state.rematchEndsAt > 0 then
		activeEndsAt = state.rematchEndsAt
	end

	-- 1. SEATED WAITING SCREEN
	if state.phase == "Waiting" then
		setMatchBlur(false)
		overlay.BackgroundTransparency = 0.55
		lobbyHud.Visible = false
		modeSubLabel.Visible = true
		modeSubLabel.Text = "MEJA PERTANDINGAN"
		headerLabel.Visible = true
		headerLabel.Text = "MENUNGGU LAWAN... (BOT MASUK DALAM 3 DETIK)"
		winnerNameLabel.Visible = false
		timerLabel.Visible = false
		waitingWrap.Visible = true
		introWrap.Visible = false
		countdownWrap.Visible = false
		buildCenterWrap.Visible = false
		showdownWrap.Visible = false
		winnerWrap.Visible = false
		actionBar.Visible = false
		rolledInfoLabel.Visible = false
		setMyColumnVisible(false)
		setOppColumnVisible(false)
		focusTableCamera(state.tablePos, "Build")
		return
	end

	waitingWrap.Visible = false

	-- 2. MATCH INTRO ("<PlayerA> VS <PlayerB/BOT> / DEFAULT MODE")
	if state.phase == "Intro" then
		setMatchBlur(false)
		overlay.BackgroundTransparency = 1
		lobbyHud.Visible = false
		modeSubLabel.Visible = false
		headerLabel.Visible = false
		winnerNameLabel.Visible = false
		timerLabel.Visible = false
		introWrap.Visible = true
		countdownWrap.Visible = false
		buildCenterWrap.Visible = false
		showdownWrap.Visible = false
		winnerWrap.Visible = false
		actionBar.Visible = false
		rolledInfoLabel.Visible = false
		setMyColumnVisible(false)
		setOppColumnVisible(false)
		focusTableCamera(state.tablePos, "Build")

		introMyName.Text = state.myName or localPlayer.Name
		introOppName.Text = state.oppName or "BOT"
		introOppName.TextColor3 = if state.oppName == "BOT" then Color3.fromHex("#FF2E93") else Color3.fromHex("#D61F1F")
		introMyName.Visible = true
		introVs.Visible = false
		introOppName.Visible = false
		introMode.Visible = false
		popGui(introMyName, 0.3)
		playSfx("reveal")
		task.delay(0.32, function()
			if currentPhase == "Intro" then
				introVs.Visible = true
				popGui(introVs, 0.3)
			end
		end)
		task.delay(0.64, function()
			if currentPhase == "Intro" then
				introOppName.Visible = true
				popGui(introOppName, 0.3)
				playSfx("reveal")
			end
		end)
		task.delay(0.96, function()
			if currentPhase == "Intro" then
				introMode.Visible = true
				popGui(introMode, 0.4)
			end
		end)
		return
	end

	introWrap.Visible = false

	-- 3. COUNTDOWN SCREEN ("3, 2, 1, GO!" with strong BlurEffect)
	if state.phase == "Countdown" then
		setMatchBlur(true)
		overlay.BackgroundTransparency = 0.35
		lobbyHud.Visible = false
		modeSubLabel.Visible = true
		modeSubLabel.Text = "DEFAULT MODE"
		modeSubLabel.TextColor3 = Color3.new(1, 1, 1)
		headerLabel.Visible = true
		headerLabel.Text = "BUILD A FOOTBALLER"
		headerLabel.TextColor3 = Color3.new(1, 1, 1)
		winnerNameLabel.Visible = false
		timerLabel.Visible = false
		countdownWrap.Visible = true
		buildCenterWrap.Visible = false
		showdownWrap.Visible = false
		winnerWrap.Visible = false
		actionBar.Visible = false
		rolledInfoLabel.Visible = false
		setMyColumnVisible(false)
		setOppColumnVisible(false)
		lastCountdownText = ""
		focusTableCamera(state.tablePos, "Build")
		return
	end

	countdownWrap.Visible = false
	setMatchBlur(true)
	overlay.BackgroundTransparency = 0.35
	lobbyHud.Visible = false

	-- 4. BUILD SCREEN (6-ROUND ROLLING -> SELECTING)
	if state.phase == "Build" then
		focusTableCamera(state.tablePos, "Build")
		modeSubLabel.Visible = true
		modeSubLabel.Text = "DEFAULT MODE"
		modeSubLabel.TextColor3 = Color3.new(1, 1, 1)
		headerLabel.Visible = true
		headerLabel.Text = "BUILD A FOOTBALLER"
		headerLabel.TextColor3 = Color3.new(1, 1, 1)
		winnerNameLabel.Visible = false
		timerLabel.Visible = true
		buildCenterWrap.Visible = true
		showdownWrap.Visible = false
		winnerWrap.Visible = false
		actionBar.Visible = true
		rolledInfoLabel.Visible = true
		setMyColumnVisible(true)
		setOppColumnVisible(true)

		buildMyAvatar.Image = getAvatarThumb(state.myUserId or localPlayer.UserId)
		buildOppAvatar.Image = getAvatarThumb(state.oppUserId or 0)

		local myB = state.myBoard
		local oppB = state.oppBoard
		currentPlacedThisRound = if myB then myB.placedThisRound == true else false
		vsCenterLabel.Visible = true

		if state.subPhase == "Rolling" then
			timerLabel.Text = tostring(state.frozenTimer or 15)
			rolledInfoLabel.Text = "ROLLING..."
			rollingToken += 1
			local myRollToken = rollingToken
			playSfx("roll")
			task.spawn(function()
				while currentPhase == "Build" and currentSubPhase == "Rolling" and rollingToken == myRollToken do
					local rA = Footballers.All[math.random(1, #Footballers.All)]
					local rB = Footballers.All[math.random(1, #Footballers.All)]
					setCardSilhouette(myCardWidget, rA)
					setCardSilhouette(oppCardWidget, rB)
					task.wait(0.12)
				end
			end)
		else
			rollingToken += 1
			populateBuildCard(myCardWidget, myB.currentRoll, true, myB.placedThisRound == true)
			populateBuildCard(oppCardWidget, oppB.currentRoll, false, oppB.placedThisRound == true)
			if myB.placedThisRound then
				rolledInfoLabel.Text = "WAITING FOR OPPONENT..."
			elseif myB.currentRoll then
				rolledInfoLabel.Text = `YOU ROLLED {string.upper(Footballers.getDisplayName(myB.currentRoll))}`
			else
				rolledInfoLabel.Text = "ALL SLOTS FILLED - WAITING FOR SHOWDOWN..."
			end
		end

		local curLuck = myB.luck or 1
		local nextLuck = GameConfig.getNextLuckTier(curLuck)
		luckBtn.Text = if nextLuck then `      LUCK: {curLuck}x [→{nextLuck.luck}x ${nextLuck.cost}]` else `      LUCK: {curLuck}x [MAX]`

		btnReroll.Text = if myB.infRerolls then "🎲 REROLL (INF)\nR$19" else `🎲 REROLL ({myB.rerollsLeft})\nR$19`
		btnSteal.Text = `😈 STEAL ({myB.stealsLeft})\nR$39`

		for _, attr in GameConfig.ATTRIBUTES do
			local myCard = myB.slots[attr]
			local myRow = mySlotRows[attr]
			if myCard then
				populateSlotRow(myRow, myCard, "Please Select...", myB.revealedAll == true, myCard.stats[attr])
			else
				local isBest = myB.bestHint == attr
				populateSlotRow(myRow, nil, if isBest then "★ BEST SLOT ★" else "Please Select...", false, nil)
				if isBest then
					myRow.subLabel.TextColor3 = Color3.fromHex("#FFD21F")
					myRow.squareBtn.BackgroundColor3 = Color3.fromHex("#B8860B")
				end
			end

			local oppCard = oppB.slots[attr]
			local oppRow = oppSlotRows[attr]
			if oppCard then
				populateSlotRow(oppRow, oppCard, "Selecting...", false, nil)
				if oppRow.stealTag then
					oppRow.stealTag.Visible = (state.subPhase == "Selecting" and myB.stealsLeft > 0 and not myB.placedThisRound and myCard == nil)
				end
			else
				populateSlotRow(oppRow, nil, "Selecting...", false, nil)
				if oppRow.stealTag then
					oppRow.stealTag.Visible = false
				end
			end
		end
		return
	end

	rollingToken += 1

	-- 5. SHOWDOWN SCREEN (COUNTDOWN 5..1..FIGHT!, SLIDE-IN CLASH, LOSER KNOCKOUT)
	if state.phase == "Showdown" then
		focusTableCamera(state.tablePos, "Showdown")
		modeSubLabel.Visible = false
		headerLabel.Visible = true
		headerLabel.Text = "SHOWDOWN"
		headerLabel.TextColor3 = Color3.fromHex("#FFD21F")
		winnerNameLabel.Visible = false
		timerLabel.Visible = false
		buildCenterWrap.Visible = false
		showdownWrap.Visible = true
		winnerWrap.Visible = false
		actionBar.Visible = false
		rolledInfoLabel.Visible = false
		setMyColumnVisible(true)
		setOppColumnVisible(true)

		-- Reset Showdown card positions & rotation
		sdMyCard.Position = UDim2.fromScale(0.35, 0.34)
		sdMyCard.Rotation = 0
		sdOppCard.Position = UDim2.fromScale(0.65, 0.34)
		sdOppCard.Rotation = 0
		sdMyAvgBox.Position = UDim2.fromScale(0.35, 0.80)
		sdOppAvgBox.Position = UDim2.fromScale(0.65, 0.80)
		sdOppAvgBox.Visible = true
		sdMyAvgBox.Visible = true
		sdVsLabel.Visible = true
		sdCountdownLbl.Visible = true
		sdClashSpark.Visible = false

		sdMyImg.Image = getAvatarThumb(state.myUserId or localPlayer.UserId)
		sdMyName.Text = state.myName or "YOU"
		sdOppImg.Image = getAvatarThumb(state.oppUserId or 0)
		sdOppName.Text = state.oppName or "BOT"
		sdMyAvgLbl.Text = "0.0"
		sdOppAvgLbl.Text = "0.0"

		for _, attr in GameConfig.ATTRIBUTES do
			local myCard = state.myBoard.slots[attr]
			local oppCard = state.oppBoard.slots[attr]
			populateSlotRow(mySlotRows[attr], myCard, "-", false, nil)
			populateSlotRow(oppSlotRows[attr], oppCard, "-", false, nil)
			if oppSlotRows[attr].stealTag then
				oppSlotRows[attr].stealTag.Visible = false
			end
		end

		showdownToken += 1
		local mySdToken = showdownToken
		task.spawn(function()
			-- Rapid 5..4..3..2..1..FIGHT! countdown
			local steps = { "5", "4", "3", "2", "1", "FIGHT!" }
			for _, txt in steps do
				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then
					return
				end
				sdCountdownLbl.Text = txt
				sdCountdownLbl.TextColor3 = if txt == "FIGHT!" then Color3.fromHex("#FFD21F") else Color3.new(1, 1, 1)
				popGui(sdCountdownLbl, 1.45)
				playSfx("reveal")
				task.wait(0.38)
			end
			if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then
				return
			end

			-- Slide both cards & AVG SCORE boxes inward toward center
			sdVsLabel.Visible = false
			sdCountdownLbl.Visible = false
			TweenService:Create(sdMyCard, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.42, 0.34),
			}):Play()
			TweenService:Create(sdOppCard, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.58, 0.34),
			}):Play()
			TweenService:Create(sdMyAvgBox, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.42, 0.80),
			}):Play()
			TweenService:Create(sdOppAvgBox, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.58, 0.80),
			}):Play()
			task.wait(0.32)

			local sumMy = 0
			local sumOpp = 0
			for idx, attr in GameConfig.ATTRIBUTES do
				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then
					return
				end
				local myScore = state.myEval.slotScores[attr]
				local oppScore = state.oppEval.slotScores[attr]
				sumMy += myScore
				sumOpp += oppScore

				local myRow = mySlotRows[attr]
				local oppRow = oppSlotRows[attr]
				myRow.scoreBadge.Text = tostring(myScore)
				myRow.scoreBadge.Visible = true
				popGui(myRow.scoreBadge, 0.45)

				oppRow.scoreBadge.Text = tostring(oppScore)
				oppRow.scoreBadge.Visible = true
				popGui(oppRow.scoreBadge, 0.45)

				-- Reset soccer ball to center at each stat row, then animate toward the loser
				local yPos = 0.18 + (idx - 1) * 0.092
				sdClashSpark.Rotation = 0
				sdClashSpark.Position = UDim2.new(0.5, -36, yPos, -10)
				sdClashSpark.Visible = true
				popGui(sdClashSpark, 0.4)
				playSfx("reveal")

				sdMyAvgLbl.Text = string.format("%.1f", sumMy / idx)
				sdOppAvgLbl.Text = string.format("%.1f", sumOpp / idx)
				popGui(sdMyAvgLbl, 1.25)
				popGui(sdOppAvgLbl, 1.25)

				task.wait(0.15)
				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then
					return
				end
				if myScore ~= oppScore then
					local targetX = if myScore > oppScore then 0.72 else 0.28
					local spinDeg = if myScore > oppScore then 360 else -360
					TweenService:Create(sdClashSpark, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(targetX, -36, yPos, -10),
						Rotation = spinDeg,
					}):Play()
				end
				task.wait(0.30)
				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then
					return
				end
				-- Knock away the losing row in this attribute clash
				if myScore < oppScore then
					myRow.rowFrame.Visible = false
				elseif oppScore < myScore then
					oppRow.rowFrame.Visible = false
				end
				task.wait(0.60)
			end

			if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then
				return
			end
			sdClashSpark.Visible = false
			sdMyAvgLbl.Text = tostring(state.myEval.avgScore)
			sdOppAvgLbl.Text = tostring(state.oppEval.avgScore)

			-- Loser card tilts 18° and flies off-screen to bottom-right; Winner card slides to center x = 0.50
			local loserCard = if state.didWin then sdOppCard else sdMyCard
			local winnerCard = if state.didWin then sdMyCard else sdOppCard
			local loserAvg = if state.didWin then sdOppAvgBox else sdMyAvgBox
			local winnerAvg = if state.didWin then sdMyAvgBox else sdOppAvgBox

			loserAvg.Visible = false
			TweenService:Create(loserCard, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.fromScale(1.15, 1.15),
				Rotation = 18,
			}):Play()
			TweenService:Create(winnerCard, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.50, 0.36),
			}):Play()
			TweenService:Create(winnerAvg, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.50, 0.56),
			}):Play()
		end)
		return
	end

	showdownToken += 1

	-- 6. RESULT SCREEN (Defaults to Player's Own Result; FLIP toggles Opponent)
	if state.phase == "Result" then
		focusTableCamera(state.tablePos, "Result")
		playSfx(if state.didWin then "win" else "lose")
		headerLabel.Visible = true
		timerLabel.Visible = false
		buildCenterWrap.Visible = false
		showdownWrap.Visible = false
		winnerWrap.Visible = true
		actionBar.Visible = false
		rolledInfoLabel.Visible = false
		setOppColumnVisible(false)

		rematchVoted = false
		lastResultState = state
		lastDidWin = state.didWin == true
		pendingSummaryPopup = true
		inspectingSelf = true
		refreshWinnerInspection(true)

		-- Slide in Bottom-Right Badge Awarded Toast
		badgeToast.Position = UDim2.new(1, 20, 1, -74)
		badgeToastSub.Text = if state.didWin then "Match Victory!" else "Match Completed!"
		TweenService:Create(badgeToast, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -246, 1, -74),
		}):Play()

		-- Populate Post-Match Summary Popup values (shown with 3s countdown when returning to Lobby)
		local r = state.reward
		sumBuxVal.Text = if r then `+${r.buxEarned}` else "+$25"
		sumWinsVal.Text = if r then `+{r.winsEarned}` else "+0"
		sumStreakVal.Text = if r then `🔥 {r.newStreak}` else "0"
		btnSumClaimQuest.Text = "CLAIM!"
		btnSumClaimQuest.BackgroundColor3 = Color3.fromHex("#22C55E")
		refreshMetaUI()
	end
end)

-- ============================================================
-- 7. LIVE TABLE SPECTATOR DISPLAY (PvP / PlayerA VS PlayerB / Turn X/6 + 6v6 3D SLOTS)
-- ============================================================
do
local function setupSpectatorDisplay()
type SpectateSlotWidget = {
	box: Frame,
	stroke: UIStroke,
	viewport: ViewportFrame,
	mount: ViewportMount,
	nameLbl: TextLabel,
}

local spectateRefreshers: { [Instance]: () -> () } = {}

local function escapeRichText(raw: string): string
	local s = string.gsub(raw, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	s = string.gsub(s, '"', "&quot;")
	return s
end

local function buildClashBolt(parent: Instance)
	local wrap = Instance.new("Frame")
	wrap.Name = "ClashBolt"
	wrap.Size = UDim2.fromScale(0.08, 0.78)
	wrap.AnchorPoint = Vector2.new(0.5, 0.5)
	wrap.Position = UDim2.fromScale(0.5, 0.47)
	wrap.BackgroundTransparency = 1
	wrap.Parent = parent

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 0.62
	aspect.Parent = wrap

	local function makeSeg(name: string, size: UDim2, pos: UDim2, rot: number, col: Color3, zIdx: number): Frame
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = size
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = pos
		f.Rotation = rot
		f.BackgroundColor3 = col
		f.BorderSizePixel = 0
		f.ZIndex = zIdx
		f.Parent = wrap
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.22, 0)
		c.Parent = f
		return f
	end

	-- Black outline backing segments (seamless, no crossing internal stroke)
	makeSeg("BackTop", UDim2.fromScale(0.46, 0.64), UDim2.fromScale(0.44, 0.34), 20, Color3.new(0, 0, 0), 1)
	makeSeg("BackMid", UDim2.fromScale(0.68, 0.22), UDim2.fromScale(0.50, 0.50), -8, Color3.new(0, 0, 0), 1)
	makeSeg("BackBot", UDim2.fromScale(0.46, 0.64), UDim2.fromScale(0.56, 0.66), 20, Color3.new(0, 0, 0), 1)

	-- Crisp white-to-silver front segments
	local frontCols = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 214, 228))
	for _, seg in {
		makeSeg("FrontTop", UDim2.fromScale(0.32, 0.56), UDim2.fromScale(0.44, 0.34), 20, Color3.new(1, 1, 1), 2),
		makeSeg("FrontMid", UDim2.fromScale(0.54, 0.14), UDim2.fromScale(0.50, 0.50), -8, Color3.new(1, 1, 1), 2),
		makeSeg("FrontBot", UDim2.fromScale(0.32, 0.56), UDim2.fromScale(0.56, 0.66), 20, Color3.new(1, 1, 1), 2),
	} do
		local g = Instance.new("UIGradient")
		g.Color = frontCols
		g.Rotation = 90
		g.Parent = seg
	end
end

local function createSpectateSideSlots(parent: Instance, sideName: string, posX: number): { [string]: SpectateSlotWidget }
	local sideFrame = Instance.new("Frame")
	sideFrame.Name = sideName
	sideFrame.Size = UDim2.fromScale(0.455, 1)
	sideFrame.Position = UDim2.fromScale(posX, 0)
	sideFrame.BackgroundTransparency = 1
	sideFrame.Parent = parent

	local map: { [string]: SpectateSlotWidget } = {}
	local colW = 1 / #GameConfig.ATTRIBUTES

	for idx, attr in GameConfig.ATTRIBUTES do
		local col = Instance.new("Frame")
		col.Name = attr
		col.Size = UDim2.fromScale(colW, 1)
		col.Position = UDim2.fromScale((idx - 1) * colW, 0)
		col.BackgroundTransparency = 1
		col.Parent = sideFrame

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name = "AttrIcon"
		iconLbl.Size = UDim2.fromScale(1, 0.24)
		iconLbl.Position = UDim2.fromScale(0, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.FredokaOne
		iconLbl.TextColor3 = Color3.new(1, 1, 1)
		iconLbl.TextScaled = true
		iconLbl.Text = ATTR_ICONS[attr] or ""
		iconLbl.Parent = col

		local box = Instance.new("Frame")
		box.Name = "PortraitBox"
		box.Size = UDim2.fromScale(0.86, 0.50)
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.50)
		box.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
		box.BackgroundTransparency = 0.32
		box.ClipsDescendants = true
		box.Parent = col

		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = box

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.18, 0)
		corner.Parent = box

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(175, 184, 198)
		stroke.Thickness = 2
		stroke.Transparency = 0.18
		stroke.Parent = box

		local vp = createFaceViewport(box)
		vp.Visible = false
		local vpCorner = Instance.new("UICorner")
		vpCorner.CornerRadius = UDim.new(0.18, 0)
		vpCorner.Parent = vp

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "PlayerCardName"
		nameLbl.Size = UDim2.fromScale(1.06, 0.25)
		nameLbl.AnchorPoint = Vector2.new(0.5, 0)
		nameLbl.Position = UDim2.fromScale(0.5, 0.76)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextColor3 = Color3.new(1, 1, 1)
		nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		nameLbl.TextStrokeTransparency = 0
		nameLbl.TextWrapped = true
		nameLbl.TextScaled = true
		nameLbl.Visible = false
		nameLbl.Text = ""
		nameLbl.Parent = col

		map[attr] = {
			box = box,
			stroke = stroke,
			viewport = vp,
			mount = { model = nil, modelId = nil },
			nameLbl = nameLbl,
		}
	end

	return map
end

local function updateSpectateSlot(slot: SpectateSlotWidget, cardId: string)
	local card = if #cardId > 0 then Footballers.ById[cardId] else nil
	if card then
		slot.box.BackgroundColor3 = Color3.fromHex(card.kitColor)
		slot.box.BackgroundTransparency = 0.04]=]
print("Loaded c_7")

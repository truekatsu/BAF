_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[4] = [=[OrangeTop)
	local profTotalCashVal = makeStatTile(secMatch, UDim2.new(0, 12, 0, 100), UDim2.new(0.333, -16, 0, 56), "TOTAL CASH DIDAPAT", UITheme.Colors.MoneyGreen)
	local profWinsTodayVal = makeStatTile(secMatch, UDim2.new(0.333, 4, 0, 100), UDim2.new(0.333, -8, 0, 56), "WINS HARI INI", UITheme.Colors.CyanTop)
	local profWinsWeekVal = makeStatTile(secMatch, UDim2.new(0.666, 4, 0, 100), UDim2.new(0.334, -16, 0, 56), "WINS MINGGU INI", UITheme.Colors.CyanTop)

	-- 3. KOLEKSI KARTU
	local secCards = makeProfileSection(3, "3. KOLEKSI KARTU", UITheme.Colors.MagentaTop, 232)

	local profIndexBarBg = Instance.new("Frame")
	profIndexBarBg.Size = UDim2.new(1, -24, 0, 26)
	profIndexBarBg.Position = UDim2.fromOffset(12, 38)
	profIndexBarBg.BackgroundColor3 = UITheme.Colors.CardBg
	profIndexBarBg.BorderSizePixel = 0
	profIndexBarBg.ZIndex = 72
	UITheme.addCorner(profIndexBarBg, 8)
	UITheme.applyStroke(profIndexBarBg, 1.5, UITheme.Colors.MagentaTop)
	profIndexBarBg.Parent = secCards

	local profIndexBarFill = Instance.new("Frame")
	profIndexBarFill.Size = UDim2.fromScale(0, 1)
	profIndexBarFill.BackgroundColor3 = Color3.fromRGB(210, 55, 190)
	profIndexBarFill.BorderSizePixel = 0
	profIndexBarFill.ZIndex = 73
	UITheme.addCorner(profIndexBarFill, 8)
	profIndexBarFill.Parent = profIndexBarBg

	local profIndexBarText = Instance.new("TextLabel")
	profIndexBarText.Size = UDim2.fromScale(1, 1)
	profIndexBarText.BackgroundTransparency = 1
	profIndexBarText.Font = UITheme.Fonts.Primary
	profIndexBarText.TextColor3 = UITheme.Colors.White
	profIndexBarText.TextScaled = true
	profIndexBarText.Text = "PROGRES CARD INDEX: 0/152 (0%)"
	profIndexBarText.ZIndex = 74
	UITheme.addTextConstraint(profIndexBarText, 11, 17)
	UITheme.applyTextStroke(profIndexBarText, 2, UITheme.Colors.Black)
	profIndexBarText.Parent = profIndexBarBg

	local rarityTileOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
	local profRarityVals: { [string]: TextLabel } = {}
	for idx, rName in rarityTileOrder do
		local xScale = (idx - 1) * 0.2
		profRarityVals[rName] = makeStatTile(
			secCards,
			UDim2.new(xScale, if idx == 1 then 12 else 4, 0, 70),
			UDim2.new(0.2, if idx == 1 or idx == 5 then -16 else -8, 0, 48),
			string.upper(rName),
			GameConfig.RARITY_COLORS[rName]
		)
	end

	local profTotalSpinsVal = makeStatTile(secCards, UDim2.new(0, 12, 0, 124), UDim2.new(0.5, -16, 0, 48), "TOTAL SPIN & MYTHIC DIDAPAT", GameConfig.RARITY_COLORS.Mythic)
	local profPityVal = makeStatTile(secCards, UDim2.new(0.5, 4, 0, 124), UDim2.new(0.5, -16, 0, 48), "SPIN TANPA MYTHIC (MAX / SKRG)", GameConfig.RARITY_COLORS.Legendary)
	local profRarestCardVal = makeStatTile(secCards, UDim2.new(0, 12, 0, 176), UDim2.new(0.5, -16, 0, 48), "KARTU TERLANGKA", GameConfig.RARITY_COLORS.Mythic)
	local profLatestCardVal = makeStatTile(secCards, UDim2.new(0.5, 4, 0, 176), UDim2.new(0.5, -16, 0, 48), "KARTU TERBARU", UITheme.Colors.CyanTop)

	local lastRankFetchAt = 0
	refreshProfileGlobalRanks = function()
		if os.clock() - lastRankFetchAt < 8 then
			return
		end
		lastRankFetchAt = os.clock()
		for _, rb in rankBoards do
			local lbl = rankLabels[rb.key]
			if lbl then
				task.spawn(function()
					local ok, rank = pcall(function()
						return Remotes.GetMyLeaderboardRank:InvokeServer(rb.key)
					end)
					if ok and typeof(rank) == "number" and rank > 0 then
						lbl.Text = `#{rank}`
					else
						lbl.Text = "-"
					end
				end)
			end
		end
	end

	updateProfilePage = function(p: any, elapsed: number, disc: { [string]: boolean }, discCount: number, pct: number)
		local eqTitle = p.EquippedTitle or "Benchwarmer"
		profTitleBadge.Text = `🏷️ GELAR: {string.upper(eqTitle)}`
		profTitleBadge.TextColor3 = GameConfig.getTitleColor(eqTitle)

		local firstJoin = p.FirstJoinedAt or 0
		profFirstJoinVal.Text = if firstJoin > 0 then os.date("%d %b %Y", firstJoin) else "-"

		local totalPtSec = (p.PlaytimeSeconds or 0) + elapsed
		profPlaytimeVal.Text = GameConfig.formatPlaytime(totalPtSec)

		if pageProfile.Visible then
			refreshProfileGlobalRanks()
		end

		local wins = p.Wins or 0
		local curStreak = p.Streak or 0
		local bestStreak = math.max(p.BestStreak or 0, curStreak)
		local totalCash = math.max(p.TotalCashEarned or 0, p.Bux or 0)
		profTotalWinsVal.Text = tostring(wins)
		profBestStreakVal.Text = tostring(bestStreak)
		profCurStreakVal.Text = tostring(curStreak)
		profTotalCashVal.Text = `\${totalCash}`
		profWinsTodayVal.Text = tostring(p.WinsToday or 0)
		profWinsWeekVal.Text = tostring(p.WinsThisWeek or p.WinsWeek or 0)

		profIndexBarFill.Size = UDim2.fromScale(math.clamp(discCount / #Footballers.All, 0, 1), 1)
		profIndexBarText.Text = `PROGRES CARD INDEX: {discCount}/{#Footballers.All} ({pct}%)`

		local rCounts: { [string]: number } = { Common = 0, Rare = 0, Epic = 0, Legendary = 0, Mythic = 0 }
		local rTotal: { [string]: number } = { Common = 0, Rare = 0, Epic = 0, Legendary = 0, Mythic = 0 }
		local rarityRankMap: { [string]: number } = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
		local fallbackRarestCard: any = nil
		for _, card in Footballers.All do
			rTotal[card.rarity] = (rTotal[card.rarity] or 0) + 1
			if disc[card.id] then
				rCounts[card.rarity] = (rCounts[card.rarity] or 0) + 1
				if not fallbackRarestCard then
					fallbackRarestCard = card
				else
					local rCand = rarityRankMap[card.rarity] or 0
					local rCur = rarityRankMap[fallbackRarestCard.rarity] or 0
					if rCand > rCur or (rCand == rCur and card.ovr > fallbackRarestCard.ovr) then
						fallbackRarestCard = card
					end
				end
			end
		end
		for rName, lbl in profRarityVals do
			lbl.Text = `{rCounts[rName] or 0}/{rTotal[rName] or 0}`
		end

		local totalSpins = p.TotalCardSpins or 0
		local mythicsPulled = p.MythicsPulled or 0
		local hasSpinHistory = totalSpins > 0 or (p.MatchesPlayed or 0) == 0
		profTotalSpinsVal.Text = if hasSpinHistory then `{totalSpins} SPIN • {mythicsPulled} MYTHIC` else "-"
		profPityVal.Text = if hasSpinHistory then `{p.MaxSpinsWithoutMythic or 0} MAX (SKRG: {p.SpinsSinceMythic or 0})` else "-"

		local rarestCard = if p.RarestCardId and p.RarestCardId ~= "" then Footballers.ById[p.RarestCardId] else fallbackRarestCard
		if rarestCard then
			profRarestCardVal.Text = `{Footballers.getDisplayName(rarestCard)} ({rarestCard.rarity} {rarestCard.ovr})`
			profRarestCardVal.TextColor3 = GameConfig.RARITY_COLORS[rarestCard.rarity] or UITheme.Colors.White
		else
			profRarestCardVal.Text = "-"
			profRarestCardVal.TextColor3 = UITheme.Colors.White
		end

		local latestCard = if p.LatestCardId and p.LatestCardId ~= "" then Footballers.ById[p.LatestCardId] else nil
		if latestCard then
			profLatestCardVal.Text = `{Footballers.getDisplayName(latestCard)} ({latestCard.rarity} {latestCard.ovr})`
			profLatestCardVal.TextColor3 = GameConfig.RARITY_COLORS[latestCard.rarity] or UITheme.Colors.White
		else
			profLatestCardVal.Text = "-"
			profLatestCardVal.TextColor3 = UITheme.Colors.White
		end
	end
end

-- Modal Navigation Logic
local function hideAllModalPages()
	pageFreeDaily.Visible = false
	pageFreeGroup.Visible = false
	pageFreePlaytime.Visible = false
	pageQuests.Visible = false
	pageSkins.Visible = false
	pageTitles.Visible = false
	pageShop.Visible = false
	pageIndex.Visible = false
	pageWheel.Visible = false
	pageProfile.Visible = false
	freeTabsBar.Visible = false
end

local function openShop()
	if modalWrap.Visible then
		modalWrap.Visible = false
	end
	modalBackdrop.Visible = true
	shopHandler.open()
end

local function closeShop()
	modalBackdrop.Visible = false
	shopHandler.close()
end

local function openFreeTab(tab: "DAILY" | "GROUP" | "PLAYTIME")
	if shopWindow.Visible then
		shopWindow.Visible = false
	end
	modalBackdrop.Visible = true
	UITheme.animateWindowOpen(modalWrap, modalBox)
	hideAllModalPages()
	freeTabsBar.Visible = true

	setTabActive(btnTabDaily, tab == "DAILY", "📅 DAILY")
	setTabActive(btnTabGroup, tab == "GROUP", "👥 GROUP")
	setTabActive(btnTabPlaytime, tab == "PLAYTIME", "⏰ PLAYTIME")

	if tab == "DAILY" then
		UITheme.styleHeader(modalHeader, "Daily", "DAILY REWARDS")
		pageFreeDaily.Visible = true
		if cachedProfile then
			local activeDay = cachedProfile.DailyDay or 1
			if activeDay >= 4 then
			dailyHandler.scrollToActiveDay(activeDay)
			else
			end
		end
	elseif tab == "GROUP" then
		UITheme.styleHeader(modalHeader, "Gold", "GROUP REWARD", "Like + Join = free cash!")
		pageFreeGroup.Visible = true
	else
		UITheme.styleHeader(modalHeader, "Blue", "PLAYTIME REWARDS", "Resets in 18:39:12")
		UITheme.styleButton(btnCloseModal, "Red", 6)
		pageFreePlaytime.Visible = true
	end
end

local function openModal(kind: "FREE" | "QUESTS" | "SKINS" | "TITLES" | "SHOP" | "INDEX" | "WHEEL" | "PROFILE")
	if kind == "SHOP" then
		openShop()
		return
	end
	if shopWindow.Visible then
		shopWindow.Visible = false
	end
	if kind == "FREE" then
		openFreeTab("DAILY")
		return
	end
	modalBackdrop.Visible = true
	UITheme.animateWindowOpen(modalWrap, modalBox)
	hideAllModalPages()

	if kind == "QUESTS" then
		UITheme.styleHeader(modalHeader, "Lime", "DAILY QUESTS")
		pageQuests.Visible = true
	elseif kind == "SKINS" then
		UITheme.styleHeader(modalHeader, "ChairSkins", "CHAIR SKINS")
		UITheme.styleButton(btnCloseModal, "Magenta", 10)
		pageSkins.Visible = true
	elseif kind == "TITLES" then
		UITheme.styleHeader(modalHeader, "Cyan", "TITLES")
		pageTitles.Visible = true
	elseif kind == "INDEX" then
		UITheme.styleHeader(modalHeader, "Magenta", "CARD INDEX (152 FOOTBALLERS)")
		pageIndex.Visible = true
	elseif kind == "WHEEL" then
		UITheme.styleHeader(modalHeader, "Purple", "PRIZE SPIN WHEEL")
		pageWheel.Visible = true
	elseif kind == "PROFILE" then
		UITheme.styleHeader(modalHeader, "Blue", "PLAYER PROFILE & STATS TRACKER")
		pageProfile.Visible = true
		refreshProfileGlobalRanks()
	end
end

btnCloseModal.Activated:Connect(function()
	modalBackdrop.Visible = false
	UITheme.animateWindowClose(modalWrap, modalBox)
end)
modalBackdrop.Activated:Connect(function()
	modalBackdrop.Visible = false
	UITheme.animateWindowClose(modalWrap, modalBox)
	if shopWindow.Visible then
		closeShop()
	end
end)
btnNavFree.Activated:Connect(function()
	openModal("FREE")
end)
btnTopDaily.Activated:Connect(function()
	openModal("FREE")
end)
btnTopQuests.Activated:Connect(function()
	openModal("QUESTS")
end)
btnNavShop.Activated:Connect(function()
	openShop()
end)
btnNavSkins.Activated:Connect(function()
	openModal("SKINS")
end)
btnNavTitles.Activated:Connect(function()
	openModal("TITLES")
end)
btnNavIndex.Activated:Connect(function()
	openModal("INDEX")
end)
btnNavProfile.Activated:Connect(function()
	openModal("PROFILE")
end)
btnPromoStarter.Activated:Connect(function()
	openShop()
end)
btnPromoStreak.Activated:Connect(function()
	openShop()
end)
btnAddCash.Activated:Connect(function()
	openShop()
end)
btnTabDaily.Activated:Connect(function()
	openFreeTab("DAILY")
end)
btnTabGroup.Activated:Connect(function()
	openFreeTab("GROUP")
end)
btnTabPlaytime.Activated:Connect(function()
	openFreeTab("PLAYTIME")
end)

-- ============================================================
-- 2. MATCH OVERLAY UI (WAITING / INTRO / COUNTDOWN / BUILD / SHOWDOWN / WINNER)
-- ============================================================
local ATTR_ICONS: { [string]: string } = {
	SHO = "🎯",
	PAC = "⚡",
	DRI = "👟",
	PAS = "🧠",
	DEF = "🛡️",
	PHY = "💪",
}

local avatarCache: { [number]: string } = {}
local function getAvatarThumb(userId: number?): string
	local uid = if typeof(userId) == "number" and userId > 0 then userId else 1
	if avatarCache[uid] then
		return avatarCache[uid]
	end
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	local img = if ok and typeof(content) == "string" then content else ""
	avatarCache[uid] = img
	return img
end

local function makeLine(parent: Instance, color: Color3, thickness: number): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.Size = UDim2.fromOffset(0, thickness)
	f.Parent = parent
	return f
end

local function setLine(line: Frame, p1: Vector2, p2: Vector2, thickness: number)
	local delta = p2 - p1
	local mid = (p1 + p2) * 0.5
	line.Position = UDim2.fromOffset(mid.X, mid.Y)
	line.Size = UDim2.fromOffset(delta.Magnitude, thickness)
	line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end

local activeEndsAt = 0
local currentPhase = "Idle"
local currentSubPhase = ""
local currentPlacedThisRound = false
local rollingToken = 0
local showdownToken = 0
local cachedProfile: any = nil

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
overlay.BackgroundTransparency = 0.35
overlay.Visible = false
overlay.Parent = screenGui

local modeSubLabel = makeLabel(overlay, "DEFAULT MODE", UDim2.new(0.4, 0, 0, 20), UDim2.new(0.30, 0, 0, 8), Color3.new(1, 1, 1))
local headerLabel = makeLabel(overlay, "BUILD A FOOTBALLER", UDim2.new(0.6, 0, 0, 44), UDim2.new(0.2, 0, 0, 24), Color3.new(1, 1, 1))
local winnerNameLabel = makeLabel(overlay, "", UDim2.new(0.5, 0, 0, 42), UDim2.new(0.25, 0, 0, 64), Color3.new(1, 1, 1))
winnerNameLabel.Visible = false
local timerLabel = makeLabel(overlay, "15", UDim2.new(0.2, 0, 0, 42), UDim2.new(0.4, 0, 0, 66), Color3.new(1, 1, 1))

-- ============================================================
-- 2A. SEATED WAITING SCREEN ("INVITE FRIENDS", "LEAVE" + "FIGHT WITH AI -> PLAY!")
-- ============================================================
local waitingWrap = Instance.new("Frame")
waitingWrap.Name = "WaitingWrap"
waitingWrap.Size = UDim2.fromScale(1, 1)
waitingWrap.BackgroundTransparency = 1
waitingWrap.Visible = false
waitingWrap.Parent = overlay

local btnWaitInvite = makeButton(waitingWrap, "", UDim2.fromOffset(232, 48), UDim2.new(0.50, -116, 0.70, 0), Color3.fromHex("#FFD21F"))
do
	local ink = Color3.fromRGB(15, 17, 22)
	local iconWrap = Instance.new("Frame")
	iconWrap.Name = "UserPlusIcon"
	iconWrap.Size = UDim2.fromOffset(30, 26)
	iconWrap.Position = UDim2.new(0, 14, 0.5, -13)
	iconWrap.BackgroundTransparency = 1
	iconWrap.Parent = btnWaitInvite

	local headDot = Instance.new("Frame")
	headDot.Name = "Head"
	headDot.Size = UDim2.fromOffset(11, 11)
	headDot.Position = UDim2.fromOffset(5, 1)
	headDot.BackgroundColor3 = ink
	headDot.BorderSizePixel = 0
	headDot.Parent = iconWrap
	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(1, 0)
	hc.Parent = headDot

	local bodyClip = Instance.new("Frame")
	bodyClip.Name = "ShouldersClip"
	bodyClip.Size = UDim2.fromOffset(21, 12)
	bodyClip.Position = UDim2.fromOffset(0, 12)
	bodyClip.BackgroundTransparency = 1
	bodyClip.ClipsDescendants = true
	bodyClip.Parent = iconWrap

	local dome = Instance.new("Frame")
	dome.Name = "Shoulders"
	dome.Size = UDim2.fromOffset(21, 24)
	dome.Position = UDim2.fromOffset(0, 0)
	dome.BackgroundColor3 = ink
	dome.BorderSizePixel = 0
	dome.Parent = bodyClip
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dome

	local plusH = Instance.new("Frame")
	plusH.Name = "PlusH"
	plusH.Size = UDim2.fromOffset(11, 3)
	plusH.Position = UDim2.fromOffset(19, 12)
	plusH.BackgroundColor3 = ink
	plusH.BorderSizePixel = 0
	plusH.Parent = iconWrap
	local phc = Instance.new("UICorner")
	phc.CornerRadius = UDim.new(1, 0)
	phc.Parent = plusH

	local plusV = Instance.new("Frame")
	plusV.Name = "PlusV"
	plusV.Size = UDim2.fromOffset(3, 11)
	plusV.Position = UDim2.fromOffset(23, 8)
	plusV.BackgroundColor3 = ink
	plusV.BorderSizePixel = 0
	plusV.Parent = iconWrap
	local pvc = Instance.new("UICorner")
	pvc.CornerRadius = UDim.new(1, 0)
	pvc.Parent = plusV

	local inviteLbl = makeLabel(btnWaitInvite, "INVITE FRIENDS", UDim2.new(1, -62, 0, 28), UDim2.new(0, 50, 0.5, -14), Color3.new(1, 1, 1))
	inviteLbl.Name = "InviteLabel"
end
btnWaitInvite.Activated:Connect(function()
	pcall(function()
		SocialService:PromptGameInvite(localPlayer)
	end)
end)

local btnWaitLeave = makeButton(waitingWrap, "LEAVE", UDim2.fromOffset(232, 46), UDim2.new(0.50, -116, 0.785, 0), Color3.fromHex("#E5252A"))
btnWaitLeave.Activated:Connect(function()
	Remotes.MatchAction:FireServer("LeaveTable")
end)

local aiBox = Instance.new("Frame")
aiBox.Size = UDim2.fromOffset(190, 118)
aiBox.Position = UDim2.new(0.50, 130, 0.68, 0)
aiBox.BackgroundTransparency = 1
aiBox.Parent = waitingWrap

makeLabel(aiBox, "TIRED OF WAITING?", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), Color3.new(1, 1, 1))
makeLabel(aiBox, "FIGHT WITH AI", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 20), Color3.fromHex("#FFA500"))
local btnPlayBotNow = makeButton(aiBox, "PLAY!", UDim2.new(0.86, 0, 0, 52), UDim2.new(0.07, 0, 0, 52), Color3.fromHex("#22C55E"))
btnPlayBotNow.Activated:Connect(function()
	Remotes.MatchAction:FireServer("PlayBotNow")
end)

-- ============================================================
-- 2B. INTRO SCREEN ("<Player> VS <BOT> / DEFAULT MODE") & COUNTDOWN ("3, 2, 1, GO!")
-- ============================================================
local introWrap = Instance.new("Frame")
introWrap.Name = "IntroWrap"
introWrap.Size = UDim2.fromScale(1, 1)
introWrap.BackgroundTransparency = 1
introWrap.Visible = false
introWrap.Parent = overlay

local introMyName = makeLabel(introWrap, "Player", UDim2.new(0.6, 0, 0, 54), UDim2.new(0.2, 0, 0.34, 0), Color3.fromHex("#1E6FFF"))
local introVs = makeLabel(introWrap, "VS", UDim2.new(0.3, 0, 0, 48), UDim2.new(0.35, 0, 0.43, 0), Color3.fromHex("#FFA500"))
local introOppName = makeLabel(introWrap, "BOT", UDim2.new(0.6, 0, 0, 56), UDim2.new(0.2, 0, 0.51, 0), Color3.fromHex("#FF2E93"))
local introMode = makeLabel(introWrap, "DEFAULT MODE", UDim2.new(0.4, 0, 0, 32), UDim2.new(0.3, 0, 0.61, 0), Color3.new(1, 1, 1))

local countdownWrap = Instance.new("Frame")
countdownWrap.Name = "CountdownWrap"
countdownWrap.Size = UDim2.fromScale(1, 1)
countdownWrap.BackgroundTransparency = 1
countdownWrap.Visible = false
countdownWrap.Parent = overlay

local countdownBigLabel = makeLabel(countdownWrap, "3", UDim2.fromOffset(220, 140), UDim2.new(0.5, -110, 0.44, -70), Color3.new(1, 1, 1))

-- ============================================================
-- 2C. BUILD SCREEN (CENTER 3D CARDS + 6 LEFT/RIGHT SLOTS WITH 48x48 3D FACE SQUARES)
-- ============================================================
type ViewportMount = {
	model: Model?,
	modelId: string?,
}

local function mountViewportModel(viewport: ViewportFrame, mount: ViewportMount, cardId: string?)
	if mount.modelId == cardId and mount.model ~= nil then
		return
	end
	if mount.model then
		mount.model:Destroy()
		mount.model = nil
	end
	mount.modelId = cardId
	if cardId then
		local cloned = FootballerModelBuilder.cloneModel(cardId)
		if cloned then
			cloned.Parent = viewport
			mount.model = cloned
		end
	end
end

local function createFaceViewport(parent: Instance): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = "FaceViewport"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.LightColor = Color3.new(1, 1, 1)
	vp.Ambient = Color3.fromRGB(195, 202, 218)
	vp.LightDirection = Vector3.new(-0.35, -0.60, 0.72)
	vp.Parent = parent

	local cam = Instance.new("Camera")
	cam.FieldOfView = 33
	cam.CFrame = CFrame.lookAt(Vector3.new(0.22, 2.15, -3.10), Vector3.new(0, 2.12, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

local function createBuildCard(parent: Instance, posScale: UDim2)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(186, 214)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = posScale
	frame.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
	frame.ClipsDescendants = true
	addCorner(frame, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = frame
	frame.Parent = parent

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(75, 88, 115), Color3.fromRGB(22, 26, 36))
	grad.Rotation = 90
	grad.Parent = frame

	-- Real 3D Footballer Viewport inside the card (hair, face, skin, club shirt & club shorts)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ModelViewport"
	viewport.Size = UDim2.new(1, 0, 0.65, 0)
	viewport.Position = UDim2.new(0, 0, 0, 0)
	viewport.BackgroundTransparency = 1
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.Ambient = Color3.fromRGB(185, 192, 208)
	viewport.LightDirection = Vector3.new(-0.45, -0.75, 0.65)
	viewport.Parent = frame

	local vpCam = Instance.new("Camera")
	vpCam.FieldOfView = 36
	vpCam.CFrame = CFrame.lookAt(Vector3.new(0.90, 0.84, -7.75), Vector3.new(0, 0.66, 0))
	vpCam.Parent = viewport
	viewport.CurrentCamera = vpCam

	local posTag = makeLabel(frame, "ST", UDim2.fromOffset(36, 20), UDim2.fromOffset(8, 8), Color3.new(1, 1, 1))
	posTag.BackgroundTransparency = 0.25
	posTag.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	posTag.ZIndex = 4
	addCorner(posTag, 6)

	-- Bottom Dark Overlay (Real Full Name, Real Club - Real Country, Rarity)
	local bottomBox = Instance.new("Frame")
	bottomBox.Size = UDim2.new(1, 0, 0.38, 0)
	bottomBox.Position = UDim2.new(0, 0, 0.62, 0)
	bottomBox.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
	bottomBox.BackgroundTransparency = 0.10
	bottomBox.BorderSizePixel = 0
	bottomBox.ZIndex = 3
	bottomBox.Parent = frame

	local nameLbl = makeLabel(bottomBox, "William Saliba", UDim2.new(0.92, 0, 0, 26), UDim2.new(0.04, 0, 0, 4), Color3.new(1, 1, 1))
	nameLbl.ZIndex = 4
	local clubLbl = makeLabel(bottomBox, "Arsenal - France", UDim2.new(0.94, 0, 0, 19), UDim2.new(0.03, 0, 0, 31), Color3.fromRGB(205, 212, 225))
	clubLbl.ZIndex = 4
	local rarityLbl = makeLabel(bottomBox, "Legendary", UDim2.new(0.92, 0, 0, 22), UDim2.new(0.04, 0, 0, 52), GameConfig.RARITY_COLORS.Legendary)
	rarityLbl.ZIndex = 4

	local dimVeil = Instance.new("Frame")
	dimVeil.Size = UDim2.fromScale(1, 1)
	dimVeil.BackgroundColor3 = Color3.new(0, 0, 0)
	dimVeil.BackgroundTransparency = 0.42
	dimVeil.Visible = false
	dimVeil.ZIndex = 6
	dimVeil.Parent = frame

	return {
		frame = frame,
		stroke = stroke,
		viewport = viewport,
		mount = { model = nil, modelId = nil } :: ViewportMount,
		posTag = posTag,
		kitColor = Color3.fromHex("#1E6FFF"),
		nameLbl = nameLbl,
		clubLbl = clubLbl,
		rarityLbl = rarityLbl,
		dimVeil = dimVeil,
		lastId = nil :: string?,
	}
end

local function setCardSilhouette(widget: any, randomCard: any)
	widget.frame.Visible = true
	widget.dimVeil.Visible = false
	widget.viewport.ImageColor3 = Color3.fromRGB(8, 10, 16)
	widget.posTag.Text = "?"
	widget.stroke.Color = Color3.new(0, 0, 0)
	if randomCard then
		mountViewportModel(widget.viewport, widget.mount, randomCard.id)
		widget.nameLbl.Text = Footballers.getDisplayName(randomCard)
		widget.clubLbl.Text = `{randomCard.club} - {randomCard.country}`
		widget.rarityLbl.Text = randomCard.rarity
		widget.rarityLbl.TextColor3 = GameConfig.RARITY_COLORS[randomCard.rarity] or Color3.new(1, 1, 1)
	end
end

local function populateBuildCard(widget: any, card: any, isMine: boolean?, isDimmed: boolean?)
	if not card then
		widget.frame.Visible = false
		widget.lastId = nil
		return
	end
	widget.frame.Visible = true
	widget.dimVeil.Visible = isDimmed == true
	if widget.lastId ~= card.id then
		widget.lastId = card.id
		popGui(widget.frame, 0.84)
		if isMine then
			playSfx(if card.rarity == "Mythic" or card.rarity == "Legendary" then "rare" else "roll")
		end
	end
	local col = GameConfig.RARITY_COLORS[card.rarity] or Color3.new(1, 1, 1)
	mountViewportModel(widget.viewport, widget.mount, card.id)
	widget.viewport.ImageColor3 = Color3.new(1, 1, 1)
	widget.kitColor = Color3.fromHex(card.kitColor)
	widget.stroke.Color = Color3.new(0, 0, 0)
	widget.posTag.Text = card.pos
	widget.nameLbl.Text = Footballers.getDisplayName(card)
	widget.clubLbl.Text = `{card.club} - {card.country}`
	widget.rarityLbl.Text = card.rarity
	widget.rarityLbl.TextColor3 = col
end

local buildCenterWrap = Instance.new("Frame")
buildCenterWrap.Size = UDim2.fromScale(1, 1)
buildCenterWrap.BackgroundTransparency = 1
buildCenterWrap.Parent = overlay

local function createMiniAvatarBox(parent: Instance, pos: UDim2, _borderCol: Color3)
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromOffset(108, 108)
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = pos
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = parent
	return img
end

local buildMyAvatar = createMiniAvatarBox(buildCenterWrap, UDim2.fromScale(0.415, 0.21), Color3.fromHex("#1E6FFF"))
local buildOppAvatar = createMiniAvatarBox(buildCenterWrap, UDim2.fromScale(0.585, 0.21), Color3.fromHex("#E5252A"))

local myCardWidget = createBuildCard(buildCenterWrap, UDim2.fromScale(0.415, 0.46))
local oppCardWidget = createBuildCard(buildCenterWrap, UDim2.fromScale(0.585, 0.46))
local vsCenterLabel = makeLabel(buildCenterWrap, "VS", UDim2.fromOffset(52,]=]
print("Loaded c_4")

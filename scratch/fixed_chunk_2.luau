_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[3] = [=[ 3, Legendary = 4, Mythic = 5 }
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
local vsCenterLabel = makeLabel(buildCenterWrap, "VS", UDim2.fromOffset(52, 40), UDim2.new(0.5, -26, 0.46, -20), Color3.fromHex("#FFD21F"))

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
bottomRematchBtn.Activated]=]
print("Loaded fixed chunk 3")

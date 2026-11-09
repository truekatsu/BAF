_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[2] = [=[nta", 10)
btnCloseModal.ZIndex = modalHeader.ZIndex + 4
btnCloseModal.Parent = modalHeader

local modalBody = Instance.new("Frame")
modalBody.Name = "ModalBody"
modalBody.Size = UDim2.new(1, 0, 1, -74)
modalBody.Position = UDim2.new(0, 0, 0, 74)
modalBody.BackgroundTransparency = 1
modalBody.Parent = modalBox

-- Free Menu Shell Tab Row (touching bottom of Window_Daily at y = 484)
local freeTabsBar = Instance.new("Frame")
freeTabsBar.Name = "FreeTabsBar"
freeTabsBar.Size = UDim2.new(0, 574, 0, 56)
freeTabsBar.Position = UDim2.new(0.5, 0, 0, 484)
freeTabsBar.AnchorPoint = Vector2.new(0.5, 0)
freeTabsBar.BackgroundTransparency = 1
freeTabsBar.Visible = false
freeTabsBar.Parent = modalWrap

local function setTabActive(btn: TextButton, isActive: boolean, text: string)
	local innerGold = btn:FindFirstChild("InnerGoldStroke") :: UIStroke?
	if isActive then
		UITheme.styleButton(btn, "Lime", 6)
		if not innerGold then
			innerGold = Instance.new("UIStroke")
			innerGold.Name = "InnerGoldStroke"
			innerGold.Thickness = 3
			innerGold.Color = Color3.fromHex("#F5C518")
			innerGold.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			innerGold.Parent = btn
		else
			innerGold.Enabled = true
		end
	else
		UITheme.styleButton(btn, "TabInactive", 6)
		if innerGold then
			innerGold.Enabled = false
		end
	end
	btn.Text = ""
	local lbl = btn:FindFirstChild("BtnLabel") :: TextLabel?
	if not lbl then
		lbl = Instance.new("TextLabel")
		lbl.Name = "BtnLabel"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.Position = UDim2.fromScale(0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = UITheme.Fonts.Primary
		lbl.ZIndex = btn.ZIndex + 3
		lbl.TextScaled = true
		local sc = Instance.new("UITextSizeConstraint")
		sc.MinTextSize = 12
		sc.MaxTextSize = 22
		sc.Parent = lbl
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Color = UITheme.Colors.Black
		s.Parent = lbl
		lbl.Parent = btn
	end
	lbl.Text = text
	lbl.TextColor3 = if isActive then UITheme.Colors.White else UITheme.Colors.TabInactiveText
end

local btnTabDaily = makeButton(freeTabsBar, "", UDim2.new(0.31, 0, 1, 0), UDim2.new(0, 0, 0, 0), UITheme.Colors.LimeTop)
local btnTabGroup = makeButton(freeTabsBar, "", UDim2.new(0.31, 0, 1, 0), UDim2.new(0.345, 0, 0, 0), UITheme.Colors.TabInactiveTop)
local btnTabPlaytime = makeButton(freeTabsBar, "", UDim2.new(0.31, 0, 1, 0), UDim2.new(0.69, 0, 0, 0), UITheme.Colors.TabInactiveTop)
setTabActive(btnTabDaily, true, "📅 DAILY")
setTabActive(btnTabGroup, false, "👥 GROUP")
setTabActive(btnTabPlaytime, false, "⏰ PLAYTIME")

local dailyTabBadge = makeLabel(btnTabDaily, "0", UDim2.fromOffset(24, 24), UDim2.new(1, -12, 0, -8), Color3.new(1, 1, 1))
dailyTabBadge.BackgroundTransparency = 0
dailyTabBadge.BackgroundColor3 = Color3.fromHex("#E02424")
dailyTabBadge.Visible = false
UITheme.addCorner(dailyTabBadge, 6)
UITheme.applyStroke(dailyTabBadge, 2, UITheme.Colors.Black)

local groupTabBadge = makeLabel(btnTabGroup, "0", UDim2.fromOffset(24, 24), UDim2.new(1, -12, 0, -8), Color3.new(1, 1, 1))
groupTabBadge.BackgroundTransparency = 0
groupTabBadge.BackgroundColor3 = Color3.fromHex("#E02424")
groupTabBadge.Visible = false
UITheme.addCorner(groupTabBadge, 6)
UITheme.applyStroke(groupTabBadge, 2, UITheme.Colors.Black)

local playtimeTabBadge = makeLabel(btnTabPlaytime, "0", UDim2.fromOffset(24, 24), UDim2.new(1, -12, 0, -8), Color3.new(1, 1, 1))
playtimeTabBadge.BackgroundTransparency = 0
playtimeTabBadge.BackgroundColor3 = Color3.fromHex("#E02424")
playtimeTabBadge.Visible = false
UITheme.addCorner(playtimeTabBadge, 6)
UITheme.applyStroke(playtimeTabBadge, 2, UITheme.Colors.Black)

-- Pages inside modalBody
local pageFreeDaily = Instance.new("Frame")
pageFreeDaily.Size = UDim2.fromScale(1, 1)
pageFreeDaily.BackgroundTransparency = 1
pageFreeDaily.Parent = modalBody

local pageFreeGroup = Instance.new("Frame")
pageFreeGroup.Size = UDim2.fromScale(1, 1)
pageFreeGroup.BackgroundTransparency = 1
pageFreeGroup.Visible = false
pageFreeGroup.Parent = modalBody

local pageFreePlaytime = Instance.new("Frame")
pageFreePlaytime.Size = UDim2.fromScale(1, 1)
pageFreePlaytime.BackgroundTransparency = 1
pageFreePlaytime.Visible = false
pageFreePlaytime.Parent = modalBody

local pageQuests = Instance.new("Frame")
pageQuests.Size = UDim2.fromScale(1, 1)
pageQuests.BackgroundTransparency = 1
pageQuests.Visible = false
pageQuests.Parent = modalBody

local pageSkins = Instance.new("Frame")
pageSkins.Size = UDim2.fromScale(1, 1)
pageSkins.BackgroundTransparency = 1
pageSkins.Visible = false
pageSkins.Parent = modalBody

local pageTitles = Instance.new("Frame")
pageTitles.Size = UDim2.fromScale(1, 1)
pageTitles.BackgroundTransparency = 1
pageTitles.Visible = false
pageTitles.Parent = modalBody

local shopHandler = ShopDailyUI.initShop(screenGui, modalBackdrop, Remotes, UITheme)
local shopWindow = shopHandler.window
local pageIndex = Instance.new("Frame")
pageIndex.Size = UDim2.fromScale(1, 1)
pageIndex.BackgroundTransparency = 1
pageIndex.Visible = false
pageIndex.Parent = modalBody

local pageWheel = Instance.new("Frame")
pageWheel.Name = "PageWheel"
pageWheel.Size = UDim2.fromScale(1, 1)
pageWheel.BackgroundTransparency = 1
pageWheel.Visible = false
pageWheel.Parent = modalBody

local pageProfile = Instance.new("Frame")
pageProfile.Name = "PageProfile"
pageProfile.Size = UDim2.fromScale(1, 1)
pageProfile.BackgroundTransparency = 1
pageProfile.Visible = false
pageProfile.Parent = modalBody

-- ============================================================
-- Build Page 1A: DAILY REWARDS (Figma 03_Screens_Free_Menu_Shell_Daily_Tab node 25:4)
-- ============================================================
local dailyHandler = ShopDailyUI.initDaily(pageFreeDaily, Remotes, UITheme, GameConfig)
-- Build Page 1B: GROUP REWARD (Sunburst + Like + Join = Chest)
-- ============================================================
local btnClaimGroup: TextButton
do
local groupSunburst = Instance.new("Frame")
groupSunburst.Name = "GroupSunburst"
groupSunburst.Size = UDim2.fromScale(1, 1)
groupSunburst.BackgroundColor3 = UITheme.Colors.BlueTop
UITheme.addCorner(groupSunburst, 10)
UITheme.applyGradient(groupSunburst, Color3.fromHex("#38BDF8"), Color3.fromHex("#0284C7"), 90)
UITheme.addStuds(groupSunburst, 0.88, 24)
groupSunburst.Parent = pageFreeGroup

local groupSub = makeLabel(groupSunburst, "Like the game & join the group!", UDim2.new(0.94, 0, 0.14, 0), UDim2.new(0.03, 0, 0.04, 0), UITheme.Colors.White)
UITheme.styleText(groupSub, 24, 14, 3)

local likeCard = Instance.new("Frame")
likeCard.Size = UDim2.new(0.24, 0, 0.48, 0)
likeCard.Position = UDim2.new(0.05, 0, 0.20, 0)
likeCard.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(likeCard, 10)
UITheme.applyStroke(likeCard, 3, UITheme.Colors.Black)
UITheme.addBevel(likeCard, 10)
UITheme.addShadow(likeCard, 10, 3)
likeCard.Parent = groupSunburst

local likeIcon = makeLabel(likeCard, "👍", UDim2.fromScale(0.85, 0.55), UDim2.new(0.075, 0, 0.08, 0))
likeIcon.Name = "Icon_Like"
likeIcon.TextScaled = true

local likeLbl = makeLabel(likeCard, "LIKE", UDim2.new(0.88, 0, 0.26, 0), UDim2.new(0.06, 0, 0.66, 0), UITheme.Colors.NoticeYellow)
UITheme.styleText(likeLbl, 22, 12, 3, UITheme.Colors.NoticeYellow)

local plusLbl = makeLabel(groupSunburst, "+", UDim2.new(0.06, 0, 0.20, 0), UDim2.new(0.31, 0, 0.34, 0), UITheme.Colors.White)
UITheme.styleText(plusLbl, 36, 20, 3)

local joinCard = Instance.new("Frame")
joinCard.Size = UDim2.new(0.24, 0, 0.48, 0)
joinCard.Position = UDim2.new(0.39, 0, 0.20, 0)
joinCard.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(joinCard, 10)
UITheme.applyStroke(joinCard, 3, UITheme.Colors.Black)
UITheme.addBevel(joinCard, 10)
joinCard.Parent = groupSunburst

local joinIcon = makeLabel(joinCard, "👥", UDim2.fromScale(0.85, 0.55), UDim2.new(0.075, 0, 0.08, 0))
joinIcon.Name = "Icon_Group"
joinIcon.TextScaled = true

local joinLbl = makeLabel(joinCard, "JOIN", UDim2.new(0.88, 0, 0.26, 0), UDim2.new(0.06, 0, 0.66, 0), UITheme.Colors.NoticeYellow)
UITheme.styleText(joinLbl, 22, 12, 3, UITheme.Colors.NoticeYellow)

local equalsLbl = makeLabel(groupSunburst, "=", UDim2.new(0.06, 0, 0.20, 0), UDim2.new(0.65, 0, 0.34, 0), UITheme.Colors.White)
UITheme.styleText(equalsLbl, 36, 20, 3)

local rewardChestCard = Instance.new("Frame")
rewardChestCard.Size = UDim2.new(0.26, 0, 0.48, 0)
rewardChestCard.Position = UDim2.new(0.72, 0, 0.20, 0)
rewardChestCard.BackgroundTransparency = 1
rewardChestCard.Parent = groupSunburst

local groupCashIcon = Instance.new("ImageLabel")
groupCashIcon.Name = "Icon_Cash"
groupCashIcon.Size = UDim2.fromScale(0.90, 0.58)
groupCashIcon.AnchorPoint = Vector2.new(0.5, 0.5)
groupCashIcon.Position = UDim2.new(0.5, 0, 0.34, 0)
groupCashIcon.BackgroundTransparency = 1
groupCashIcon.Image = UITheme.Assets.CashStack
groupCashIcon.ScaleType = Enum.ScaleType.Fit
groupCashIcon.Parent = rewardChestCard

local rewardValLbl = makeLabel(rewardChestCard, "$250", UDim2.new(0.96, 0, 0.32, 0), UDim2.new(0.02, 0, 0.64, 0), UITheme.Colors.MoneyGreen)
UITheme.styleText(rewardValLbl, 28, 16, 3.5, UITheme.Colors.MoneyGreen)

btnClaimGroup = makeButton(groupSunburst, "", UDim2.new(0.46, 0, 0.20, 0), UDim2.new(0.27, 0, 0.74, 0), UITheme.Colors.LimeTop)
UITheme.styleButton(btnClaimGroup, "Lime", 10)
local claimGrpLbl = Instance.new("TextLabel")
claimGrpLbl.Name = "BtnLabel"
claimGrpLbl.Size = UDim2.fromScale(1, 1)
claimGrpLbl.Position = UDim2.fromScale(0, 0)
claimGrpLbl.BackgroundTransparency = 1
claimGrpLbl.Font = UITheme.Fonts.Primary
claimGrpLbl.Text = "CLAIM $250!"
claimGrpLbl.TextColor3 = UITheme.Colors.White
claimGrpLbl.TextScaled = true
claimGrpLbl.ZIndex = btnClaimGroup.ZIndex + 3
UITheme.styleText(claimGrpLbl, 26, 14, 3.5)
claimGrpLbl.Parent = btnClaimGroup
UITheme.addPulse(btnClaimGroup)
UITheme.addShineSweep(btnClaimGroup)
btnClaimGroup.Activated:Connect(function()
	Remotes.MetaAction:FireServer("ClaimGroup")
end)
end -- Page 1B Group block

-- ============================================================
-- Build Page 1C: PLAYTIME REWARDS (Prompt 4 / R6 Layout)
-- ============================================================

local ptRailFill: Frame
local playtimeNodes: { [string]: Frame } = {}
local playtimeNodeIcons: { [string]: TextLabel } = {}
local playtimeButtons: { [string]: TextButton } = {}
local playtimeInsetFrames: { [string]: Frame } = {}
local playtimeLockBadges: { [string]: ImageLabel } = {}
local playedElapsedLabel: TextLabel
do
local ptRail = Instance.new("Frame")
ptRail.Name = "MilestoneRail"
ptRail.Size = UDim2.new(0.80, 0, 0, 14)
ptRail.Position = UDim2.new(0.09, 0, 0.025, 0)
ptRail.BackgroundColor3 = Color3.fromHex("#1B1B1F")
UITheme.addCorner(ptRail, 4)
UITheme.applyStroke(ptRail, 2, UITheme.Colors.Black)
ptRail.Parent = pageFreePlaytime

local ptRailFill = Instance.new("Frame")
ptRailFill.Name = "RailFill"
ptRailFill.Size = UDim2.fromScale(0, 1)
ptRailFill.BackgroundColor3 = Color3.fromHex("#7CFF2B")
ptRailFill.BorderSizePixel = 0
UITheme.addCorner(ptRailFill, 3)
ptRailFill.Parent = ptRail

local playtimeNodes: { [string]: Frame } = {}
local playtimeNodeIcons: { [string]: TextLabel } = {}
local playtimeButtons: { [string]: TextButton } = {}
local playtimeCardFrames: { [string]: Frame } = {}
local playtimeInsetFrames: { [string]: Frame } = {}
local playtimeLockBadges: { [string]: ImageLabel } = {}

-- 6 Cards: cards 1..5 ~14.2% width, card 6 ~18.5% width (1.3x wider & ~3% taller)
local cardWidths = { 0.142, 0.142, 0.142, 0.142, 0.142, 0.185 }
local cardHeights = { 0.69, 0.69, 0.69, 0.69, 0.69, 0.72 }
local cardXPos = { 0.02, 0.174, 0.328, 0.482, 0.636, 0.790 }

for i, pt in GameConfig.PLAYTIME_REWARDS do
	-- Milestone Node centered directly above each card
	local nX = cardXPos[i] + cardWidths[i] * 0.5
	local node = Instance.new("Frame")
	node.Name = `Node_{pt.id}`
	node.Size = UDim2.fromOffset(22, 22)
	node.AnchorPoint = Vector2.new(0.5, 0.5)
	node.Position = UDim2.new((nX - 0.09) / 0.80, 0, 0.5, 0)
	node.BackgroundColor3 = Color3.fromHex("#3A3A40")
	UITheme.addCorner(node, 4)
	UITheme.applyStroke(node, 2, UITheme.Colors.Black)
	node.ZIndex = ptRail.ZIndex + 2
	node.Parent = ptRail

	local nodeLbl = makeLabel(node, "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(0, 0, 0))
	nodeLbl.Font = UITheme.Fonts.Titles
	nodeLbl.TextSize = 16
	nodeLbl.Parent = node
	playtimeNodes[pt.id] = node
	playtimeNodeIcons[pt.id] = nodeLbl

	-- Card Container
	local card = Instance.new("Frame")
	card.Name = `Card_{pt.id}`
	card.Size = UDim2.new(cardWidths[i], 0, cardHeights[i], 0)
	card.Position = UDim2.new(cardXPos[i], 0, if i == 6 then 0.075 else 0.09, 0)
	UITheme.addCorner(card, 6)
	UITheme.applyStroke(card, 3, UITheme.Colors.Black)
	card.Parent = pageFreePlaytime
	playtimeCardFrames[pt.id] = card

	if i <= 4 then
		UITheme.applyGradient(card, Color3.fromHex("#2F7FE6"), Color3.fromHex("#1A4DAA"), 90)
	elseif i == 5 then
		UITheme.applyGradient(card, Color3.fromHex("#7B3FDB"), Color3.fromHex("#4A1FA0"), 90)
		-- Ribbon +SPINS! tilted +12 deg
		local rib = makeLabel(card, "+SPINS!", UDim2.new(0.68, 0, 0.095, 0), UDim2.new(0.36, 0, -0.02, 0), UITheme.Colors.White)
		rib.BackgroundColor3 = Color3.fromHex("#E52F9B")
		rib.BackgroundTransparency = 0
		rib.Rotation = 12
		rib.ZIndex = card.ZIndex + 5
		UITheme.addCorner(rib, 3)
		UITheme.applyStroke(rib, 2, UITheme.Colors.Black)
	elseif i == 6 then
		UITheme.applyGradient(card, Color3.fromHex("#B86A1E"), Color3.fromHex("#6E3E10"), 90)
		-- Ribbon +CHAIR! tilted +12 deg
		local rib = makeLabel(card, "+CHAIR!", UDim2.new(0.64, 0, 0.092, 0), UDim2.new(0.40, 0, -0.02, 0), UITheme.Colors.White)
		rib.BackgroundColor3 = Color3.fromHex("#F2A41F")
		rib.BackgroundTransparency = 0
		rib.Rotation = 12
		rib.ZIndex = card.ZIndex + 5
		UITheme.addCorner(rib, 3)
		UITheme.applyStroke(rib, 2, UITheme.Colors.Black)
	end

	-- Inset Icon Frame (~86% width, ~40% height)
	local inset = Instance.new("Frame")
	inset.Name = "InsetFrame"
	inset.Size = UDim2.new(0.86, 0, 0.40, 0)
	inset.Position = UDim2.new(0.07, 0, 0.04, 0)
	inset.BackgroundColor3 = if i == 5 then Color3.fromHex("#6A2FC0") elseif i == 6 then Color3.fromHex("#C98A3A") else Color3.fromHex("#1E5CC0")
	UITheme.addCorner(inset, 5)
	UITheme.applyStroke(inset, 2, UITheme.Colors.Black)
	inset.Parent = card
	playtimeInsetFrames[pt.id] = inset

	-- Icon inside frame (~80% size)
	local iconObj: GuiObject
	if not pt.chair and i <= 3 then
		local cashImg = Instance.new("ImageLabel")
		cashImg.Name = "Icon_Cash"
		cashImg.Size = UDim2.fromScale(0.82, 0.82)
		cashImg.AnchorPoint = Vector2.new(0.5, 0.5)
		cashImg.Position = UDim2.fromScale(0.5, 0.5)
		cashImg.BackgroundTransparency = 1
		cashImg.Image = UITheme.Assets.CashStack
		cashImg.ScaleType = Enum.ScaleType.Fit
		cashImg.Parent = inset
		iconObj = cashImg
	else
		local iconTxt = if pt.chair then "🪑" elseif i == 5 then "📦" else "📦"
		local iconLbl = makeLabel(inset, iconTxt, UDim2.fromScale(0.82, 0.82), UDim2.fromScale(0.09, 0.09), UITheme.Colors.White)
		iconLbl.TextScaled = true
		iconObj = iconLbl
	end

	-- Orange Lock badge at bottom-right of inset frame (~28% width)
	local lockBadge = Instance.new("ImageLabel")
	lockBadge.Name = "Icon_Lock"
	lockBadge.Size = UDim2.fromOffset(22, 22)
	lockBadge.Position = UDim2.new(1, -22, 1, -22)
	lockBadge.BackgroundTransparency = 1
	lockBadge.Image = "rbxassetid://6031082533" -- Padlock icon
	lockBadge.ImageColor3 = Color3.fromHex("#F59E0B")
	lockBadge.ZIndex = inset.ZIndex + 3
	lockBadge.Parent = inset
	playtimeLockBadges[pt.id] = lockBadge

	-- Amount label ($200, $500, etc.) Lime #7CFF2B, Stroke 4
	local amtLbl = makeLabel(card, pt.rewardLabel, UDim2.new(0.96, 0, 0.12, 0), UDim2.new(0.02, 0, 0.46, 0), UITheme.Colors.MoneyLime)
	UITheme.styleText(amtLbl, 18, 11, 3.5, UITheme.Colors.MoneyLime)

	-- Time label (5 MIN, 10 MIN, etc.) White, Stroke 3
	local timeLbl = makeLabel(card, pt.timeLabel, UDim2.new(0.96, 0, 0.09, 0), UDim2.new(0.02, 0, 0.59, 0), UITheme.Colors.White)
	UITheme.styleText(timeLbl, 13, 9, 2.5, UITheme.Colors.White)

	-- Chip row on 1 HOUR card (Spin x2)
	if i == 5 then
		local chip = makeLabel(card, "🎡 x2", UDim2.new(0.90, 0, 0.08, 0), UDim2.new(0.05, 0, 0.69, 0), Color3.fromHex("#BFDBFE"))
		UITheme.styleText(chip, 12, 8, 2, Color3.fromHex("#BFDBFE"))
	end

	-- Bottom Control Pill / CLAIM button
	local cBtn = makeButton(card, "5:00", UDim2.new(0.92, 0, 0.12, 0), UDim2.new(0.04, 0, 0.84, 0), Color3.fromHex("#17181D"))
	UITheme.styleButton(cBtn, "Dark", 5)
	cBtn.TextWrapped = false

	-- Inner progress fill inside timer pill
	local progFill = Instance.new("Frame")
	progFill.Name = "ProgressFill"
	progFill.Size = UDim2.fromScale(0, 1)
	progFill.BackgroundColor3 = Color3.fromHex("#FFB830")
	progFill.BorderSizePixel = 0
	progFill.ZIndex = cBtn.ZIndex - 1
	UITheme.addCorner(progFill, 5)
	progFill.Parent = cBtn

	cBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("ClaimPlaytime", pt.id)
	end)
	playtimeButtons[pt.id] = cBtn
end

-- Bottom Row: Stopwatch + "M:SS played" (never clipped) & SKIP ALL button
local playedElapsedLabel = makeLabel(pageFreePlaytime, "⏱️ 0:00 played", UDim2.new(0.35, 0, 0.12, 0), UDim2.new(0.03, 0, 0.85, 0), UITheme.Colors.White)
playedElapsedLabel.TextXAlignment = Enum.TextXAlignment.Left
UITheme.styleText(playedElapsedLabel, 20, 11, 3)

local btnSkipAllPlaytime = makeButton(pageFreePlaytime, "", UDim2.new(0.28, 0, 0.12, 0), UDim2.new(0.36, 0, 0.85, 0), UITheme.Colors.GoldTop)
UITheme.styleButton(btnSkipAllPlaytime, "Gold", 6)
UITheme.createRobuxBadge(btnSkipAllPlaytime, 49, UDim2.fromOffset(54, 24), UDim2.new(1, -44, 0, -8))

local skipAllLbl = Instance.new("TextLabel")
skipAllLbl.Name = "BtnLabel"
skipAllLbl.Size = UDim2.new(1, -48, 1, 0)
skipAllLbl.Position = UDim2.new(0, 6, 0, 0)
skipAllLbl.BackgroundTransparency = 1
skipAllLbl.Font = UITheme.Fonts.Primary
skipAllLbl.Text = "⏩ SKIP ALL"
skipAllLbl.TextColor3 = UITheme.Colors.White
skipAllLbl.TextScaled = true
skipAllLbl.ZIndex = btnSkipAllPlaytime.ZIndex + 3
UITheme.styleText(skipAllLbl, 18, 10, 3)
skipAllLbl.Parent = btnSkipAllPlaytime

btnSkipAllPlaytime.Activated:Connect(function()
	Remotes.MetaAction:FireServer("BuyShopItem", "skip_all_playtime")
end)

end -- Page 1C Playtime

-- ============================================================
-- Build Page 2: DAILY QUESTS (3 Rows)
-- ============================================================

local questProgLabels: { [string]: TextLabel } = {}
local questClaimBtns: { [string]: TextButton } = {}
do
local questProgLabels: { [string]: TextLabel } = {}
local questClaimBtns: { [string]: TextButton } = {}
do
for i, q in GameConfig.QUESTS do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.98, 0, 0.30, 0)
	row.Position = UDim2.new(0.01, 0, (i - 1) * 0.33, 0)
	row.BackgroundColor3 = UITheme.Colors.CardBg
	UITheme.addCorner(row, 10)
	UITheme.applyStroke(row, 3, UITheme.Colors.Black)
	UITheme.addStuds(row, 0.90, 20)
	UITheme.addBevel(row, 10)
	UITheme.addShadow(row, 10, 3)
	row.Parent = pageQuests

	makeLabel(row, q.title, UDim2.new(0.60, 0, 0.46, 0), UDim2.new(0.03, 0, 0.06, 0), UITheme.Colors.White)
	makeLabel(row, `REWARD: {q.rewardLabel}`, UDim2.new(0.34, 0, 0.40, 0), UDim2.new(0.64, 0, 0.08, 0), UITheme.Colors.NoticeYellow)

	local progLbl = makeLabel(row, `0/{q.target}`, UDim2.new(0.56, 0, 0.36, 0), UDim2.new(0.03, 0, 0.56, 0), UITheme.Colors.White)
	progLbl.BackgroundTransparency = 0
	progLbl.BackgroundColor3 = UITheme.Colors.CardDark
	UITheme.addCorner(progLbl, 8)
	UITheme.applyStroke(progLbl, 2, UITheme.Colors.Black)
	questProgLabels[q.id] = progLbl

	local cBtn = makeButton(row, "CLAIM", UDim2.new(0.30, 0, 0.38, 0), UDim2.new(0.66, 0, 0.54, 0), UITheme.Colors.GrayTop)
	UITheme.styleButton(cBtn, "Gray", 6)
	cBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("ClaimQuest", q.id)
	end)
	questClaimBtns[q.id] = cBtn
end
end -- Page 2 Quests block

end -- Page 2 Quests

-- ============================================================
-- Build Page 3: CHAIR SKINS + LUCKY WHEEL SPIN + LUCK UPGRADE (Prompt 5 / R7)
-- ============================================================

local wheelSpinBtn: TextButton
local luckUpgradeBtn: TextButton
local skinActionBtns: { [string]: TextButton } = {}
do
pageSkins.Name = "PageSkins"
local wheelSpinBtn: TextButton
local luckUpgradeBtn: TextButton
local skinActionBtns: { [string]: TextButton } = {}
local skinNameLabels: { [string]: TextLabel } = {}

do
	-- Top Slim Action Row (above grid: Y=0.015, Height=0.09)
	local actionRow = Instance.new("Frame")
	actionRow.Name = "ActionRow"
	actionRow.Size = UDim2.new(0.92, 0, 0.09, 0)
	actionRow.Position = UDim2.new(0.04, 0, 0.015, 0)
	actionRow.BackgroundTransparency = 1
	actionRow.Parent = pageSkins

	-- Purple SPIN WHEEL button (Left)
	local wSpin = Instance.new("TextButton")
	wSpin.Name = "BtnSpinWheel"
	wSpin.Size = UDim2.new(0.485, 0, 1, 0)
	wSpin.Position = UDim2.new(0, 0, 0, 0)
	wSpin.Text = ""
	UITheme.styleButton(wSpin, "Purple", 8)
	UITheme.addPulse(wSpin, 1.0, 1.03, 1.5)

	local wheelIcon = Instance.new("ImageLabel")
	wheelIcon.Name = "Icon_Wheel"
	wheelIcon.Size = UDim2.fromOffset(28, 28)
	wheelIcon.Position = UDim2.new(0, 14, 0.5, 0)
	wheelIcon.AnchorPoint = Vector2.new(0, 0.5)
	wheelIcon.BackgroundTransparency = 1
	wheelIcon.Image = UITheme.Assets.Icon_Wheel ~= "rbxassetid://0" and UITheme.Assets.Icon_Wheel or UITheme.Assets.CashStack
	wheelIcon.ScaleType = Enum.ScaleType.Fit
	wheelIcon.ZIndex = wSpin.ZIndex + 3
	wheelIcon.Parent = wSpin

	local spinBtnLbl = Instance.new("TextLabel")
	spinBtnLbl.Name = "BtnLabel"
	spinBtnLbl.Size = UDim2.new(1, -50, 1, 0)
	spinBtnLbl.Position = UDim2.new(0, 46, 0, 0)
	spinBtnLbl.BackgroundTransparency = 1
	spinBtnLbl.Font = UITheme.Fonts.Primary
	spinBtnLbl.TextColor3 = UITheme.Colors.White
	spinBtnLbl.Text = "SPIN WHEEL (1)"
	spinBtnLbl.TextScaled = true
	UITheme.addTextConstraint(spinBtnLbl, 12, 18)
	UITheme.applyTextStroke(spinBtnLbl, 2.5, UITheme.Colors.Black)
	spinBtnLbl.ZIndex = wSpin.ZIndex + 3
	spinBtnLbl.Parent = wSpin
	wSpin.Parent = actionRow

	wSpin.Activated:Connect(function()
		openModal("WHEEL")
	end)
	wheelSpinBtn = wSpin

	-- Dark green LUCK upgrade pill button (Right)
	local lUp = Instance.new("TextButton")
	lUp.Name = "BtnLuckUpgrade"
	lUp.Size = UDim2.new(0.485, 0, 1, 0)
	lUp.Position = UDim2.new(0.515, 0, 0, 0)
	lUp.Text = ""
	UITheme.styleButton(lUp, "TabInactive", 8)

	local cloverIcon = Instance.new("ImageLabel")
	cloverIcon.Name = "Icon_Clover"
	cloverIcon.Size = UDim2.fromOffset(28, 28)
	cloverIcon.Position = UDim2.new(0, 14, 0.5, 0)
	cloverIcon.AnchorPoint = Vector2.new(0, 0.5)
	cloverIcon.BackgroundTransparency = 1
	cloverIcon.Image = UITheme.Assets.Icon_Luck ~= "rbxassetid://0" and UITheme.Assets.Icon_Luck or UITheme.Assets.CloverIcon
	cloverIcon.ScaleType = Enum.ScaleType.Fit
	cloverIcon.ZIndex = lUp.ZIndex + 3
	cloverIcon.Parent = lUp

	local luckBtnLbl = Instance.new("TextLabel")
	luckBtnLbl.Name = "BtnLabel"
	luckBtnLbl.Size = UDim2.new(1, -50, 1, 0)
	luckBtnLbl.Position = UDim2.new(0, 46, 0, 0)
	luckBtnLbl.BackgroundTransparency = 1
	luckBtnLbl.Font = UITheme.Fonts.Primary
	luckBtnLbl.TextColor3 = UITheme.Colors.White
	luckBtnLbl.Text = "LUCK: 1x -> 1.5x ($750)"
	luckBtnLbl.TextScaled = true
	UITheme.addTextConstraint(luckBtnLbl, 12, 18)
	UITheme.applyTextStroke(luckBtnLbl, 2.5, UITheme.Colors.Black)
	luckBtnLbl.ZIndex = lUp.ZIndex + 3
	luckBtnLbl.Parent = lUp
	lUp.Parent = actionRow

	lUp.Activated:Connect(function()
		Remotes.MetaAction:FireServer("UpgradeLuck")
	end)
	luckUpgradeBtn = lUp

	-- Card Grid: 3 columns x 2 rows (Y=0.13, Card width=0.29, gap=0.025, aspect ~1:1)
	local cardW = 0.29
	local cardGap = 0.025
	local leftPad = 0.04
	local rowH = 0.40
	local rowGap = 0.03
	local topPad = 0.13

	-- Rarity color mapping (ADAPTATION: CONFIG NAME_COLOR_BY_RARITY = true)
	local rarityColors = {
		wood = Color3.fromHex("#B47040"),       -- Common rustic brown
		stadium = Color3.fromHex("#38BDF8"),    -- Rare sky blue
		crimson = Color3.fromHex("#F87171"),    -- Epic crimson red
		emerald = Color3.fromHex("#4ADE80"),    -- Legendary emerald green
		cyber = Color3.fromHex("#C084FC"),      -- Mythic neon purple
		golden = Color3.fromHex("#FBBF24"),     -- Divine trophy gold
	}

	for i, skin in GameConfig.CHAIR_SKINS do
		local col = (i - 1) % 3
		local r = math.floor((i - 1) / 3)
		local posX = leftPad + col * (cardW + cardGap)
		local posY = topPad + r * (rowH + rowGap)

		local card = Instance.new("Frame")
		card.Name = `ChairCard_{skin.id}`
		card.Size = UDim2.new(cardW, 0, rowH, 0)
		card.Position = UDim2.new(posX, 0, posY, 0)
		card.BackgroundColor3 = Color3.fromHex("#0D0F14")
		card.BackgroundTransparency = 0.45
		card.BorderSizePixel = 0
		UITheme.addCorner(card, 10)
		UITheme.applyStroke(card, 3, Color3.new(0, 0, 0)) -- Black 3px stroke on ALL cards (R7)
		card.Parent = pageSkins

		-- Chair Name at top: Gold #FFC83D or rarity color, stroke 3, wrapped cleanly
		local displayName = if skin.id == "gol]=]
print("Loaded c_2")

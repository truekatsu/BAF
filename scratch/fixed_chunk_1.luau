_G.mc_chunks = _G.mc_chunks or {}
_G.mc_chunks[2] = [=[caled = true
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
		local displayName = if skin.id == "golden" then "Golden Ball" else skin.name
		local nameColor = if UITheme.CONFIG.NAME_COLOR_BY_RARITY ~= false and rarityColors[skin.id]
			then rarityColors[skin.id]
			else Color3.fromHex("#FFC83D")

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "SkinName"
		nameLbl.Size = UDim2.new(0.92, 0, 0.18, 0)
		nameLbl.Position = UDim2.new(0.04, 0, 0.04, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = UITheme.Fonts.Titles
		nameLbl.TextColor3 = nameColor
		nameLbl.Text = displayName
		nameLbl.TextScaled = true
		nameLbl.TextWrapped = true
		nameLbl.ZIndex = card.ZIndex + 3
		UITheme.addTextConstraint(nameLbl, 12, 17)
		UITheme.applyTextStroke(nameLbl, 3, Color3.new(0, 0, 0))
		nameLbl.Parent = card
		skinNameLabels[skin.id] = nameLbl

		-- 3D Chair Viewport or Image (~50% card height)
		local chairVp = Instance.new("ViewportFrame")
		chairVp.Name = "Icon_Chair"
		chairVp.Size = UDim2.new(0.88, 0, 0.50, 0)
		chairVp.Position = UDim2.new(0.06, 0, 0.22, 0)
		chairVp.BackgroundTransparency = 1
		chairVp.BorderSizePixel = 0
		chairVp.ZIndex = card.ZIndex + 2
		chairVp.Parent = card

		local cam = Instance.new("Camera")
		cam.FieldOfView = 24
		cam.CFrame = CFrame.new(Vector3.new(2.8, 2.3, 3.2), Vector3.new(0, 0.75, 0))
		cam.Parent = chairVp
		chairVp.CurrentCamera = cam
		chairVp.LightColor = Color3.fromRGB(255, 255, 255)
		chairVp.Ambient = Color3.fromRGB(240, 240, 250)
		chairVp.LightDirection = Vector3.new(-0.35, -0.60, 0.72)

		local chairModel = Instance.new("Model")
		chairModel.Name = "MiniChair"

		local seat = Instance.new("Part")
		seat.Name = "Seat"
		seat.Size = Vector3.new(1.4, 0.2, 1.4)
		seat.CFrame = CFrame.new(0, 0.8, 0)
		seat.Color = skin.color
		seat.Material = skin.mat
		seat.Anchored = true
		seat.Parent = chairModel

		local back = Instance.new("Part")
		back.Name = "Back"
		back.Size = Vector3.new(1.4, 1.3, 0.2)
		back.CFrame = CFrame.new(0, 1.5, -0.6)
		back.Color = skin.color
		back.Material = skin.mat
		back.Anchored = true
		back.Parent = chairModel

		for _, lx in { -0.55, 0.55 } do
			for _, lz in { -0.55, 0.55 } do
				local leg = Instance.new("Part")
				leg.Name = "Leg"
				leg.Size = Vector3.new(0.18, 0.8, 0.18)
				leg.CFrame = CFrame.new(lx, 0.4, lz)
				leg.Color = skin.color
				leg.Material = skin.mat
				leg.Anchored = true
				leg.Parent = chairModel
			end
		end
		chairModel.Parent = chairVp

		-- Action Button (~80% card width x ~17% height)
		local sBtn = Instance.new("TextButton")
		sBtn.Name = `BtnSkin_{skin.id}`
		sBtn.Size = UDim2.new(0.80, 0, 0.17, 0)
		sBtn.Position = UDim2.new(0.10, 0, 0.76, 0)
		sBtn.Parent = card

		UITheme.skinButton(sBtn, if skin.cost == 0 then "EQUIPPED" else "BUY", skin.cost, false)

		sBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyOrEquipChair", skin.id)
		end)
		skinActionBtns[skin.id] = sBtn
	end
end -- Page 3 Skins block

-- Build Page 4: TITLES (Wins Header + Rows + Robux Unlock Button)
-- ============================================================

local titlesWinsHeader: TextLabel
local titleActionBtns: { [string]: TextButton } = {}
do
local titlesWinsHeader: TextLabel
local titleActionBtns: { [string]: TextButton } = {}
do
local winsHeaderFrame = Instance.new("Frame")
winsHeaderFrame.Name = "WinsHeaderFrame"
winsHeaderFrame.Size = UDim2.new(0.5, 0, 0.10, 0)
winsHeaderFrame.Position = UDim2.new(0.25, 0, 0.015, 0)
winsHeaderFrame.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(winsHeaderFrame, 8)
UITheme.applyStroke(winsHeaderFrame, 2.5, UITheme.Colors.Black)
UITheme.addStuds(winsHeaderFrame, 0.88, 18)
UITheme.addBevel(winsHeaderFrame, 8)
winsHeaderFrame.Parent = pageTitles

local trophyImg = Instance.new("ImageLabel")
trophyImg.Name = "Icon_Trophy"
trophyImg.Size = UDim2.fromScale(0.75, 0.75)
trophyImg.AnchorPoint = Vector2.new(0, 0.5)
trophyImg.Position = UDim2.new(0.08, 0, 0.5, 0)
trophyImg.BackgroundTransparency = 1
trophyImg.Image = UITheme.Assets.TrophyIcon
trophyImg.ScaleType = Enum.ScaleType.Fit
trophyImg.ZIndex = winsHeaderFrame.ZIndex + 2
trophyImg.Parent = winsHeaderFrame

titlesWinsHeader = makeLabel(winsHeaderFrame, "WINS: 0", UDim2.new(0.70, 0, 0.80, 0), UDim2.new(0.25, 0, 0.10, 0), UITheme.Colors.NoticeYellow)
titlesWinsHeader.TextXAlignment = Enum.TextXAlignment.Center
titlesWinsHeader.ZIndex = winsHeaderFrame.ZIndex + 2
UITheme.styleText(titlesWinsHeader, 24, 16, 3, UITheme.Colors.NoticeYellow)
for i = #GameConfig.TITLES, 1, -1 do
	local rowIdx = (#GameConfig.TITLES - i) + 1
	local entry = GameConfig.TITLES[i]
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.96, 0, 0.16, 0)
	row.Position = UDim2.new(0.02, 0, 0.13 + (rowIdx - 1) * 0.172, 0)
	row.BackgroundColor3 = UITheme.Colors.CardBg
	UITheme.addCorner(row, 8)
	UITheme.applyStroke(row, 3, UITheme.Colors.Black)
	UITheme.addStuds(row, 0.90, 20)
	UITheme.addBevel(row, 8)
	UITheme.addShadow(row, 8, 3)
	row.Parent = pageTitles

	local nameLbl = makeLabel(row, entry.name, UDim2.new(0.50, 0, 0.8, 0), UDim2.new(0.04, 0, 0.1, 0), entry.color)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left

	local tBtn = makeButton(row, "LOCKED", UDim2.new(0.28, 0, 0.76, 0), UDim2.new(0.56, 0, 0.12, 0), UITheme.Colors.GrayTop)
	UITheme.styleButton(tBtn, "Gray", 6)
	tBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("EquipTitle", entry.name)
	end)
	titleActionBtns[entry.name] = tBtn

	-- Purple Robux Instant Unlock Button
	local robuxUnlockBtn = makeButton(row, "⬡", UDim2.new(0.12, 0, 0.76, 0), UDim2.new(0.86, 0, 0.12, 0), UITheme.Colors.PurpleTop)
	UITheme.styleButton(robuxUnlockBtn, "Purple", 6)
	robuxUnlockBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("BuyShopItem", "unlock_title_" .. string.lower(entry.name))
	end)
end
end -- Page 4 Titles block

end -- Page 4 Titles

-- ============================================================
-- Build Page 5: SHOP (Managed by ShopDailyUI)
-- ============================================================
-- Build Page 6: CARD INDEX / POKEDEX (152 Footballers sorted Mythic -> Common)
-- ============================================================

local indexProgressHeader: TextLabel
local indexCardCells: { [number]: { card: Frame, label: TextLabel, stroke: UIStroke } } = {}
do
local indexProgressHeader = makeLabel(pageIndex, "DISCOVERED: 0 / 152 (0%) • +$25–$250 PER NEW CARD!", UDim2.new(0.96, 0, 0.11, 0), UDim2.new(0.02, 0, 0, 0), UITheme.Colors.NoticeYellow)
local indexCardCells: { [string]: { frame: Frame, label: TextLabel, card: Footballers.Footballer } } = {}
do
local indexScroll = Instance.new("ScrollingFrame")
indexScroll.Size = UDim2.new(0.98, 0, 0.87, 0)
indexScroll.Position = UDim2.new(0.01, 0, 0.12, 0)
indexScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
indexScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
indexScroll.ScrollBarThickness = 8
indexScroll.ScrollBarImageColor3 = UITheme.Colors.LimeTop
indexScroll.BackgroundTransparency = 1
indexScroll.Parent = pageIndex

local indexGrid = Instance.new("UIGridLayout")
indexGrid.CellSize = UDim2.new(0.235, 0, 0, 74)
indexGrid.CellPadding = UDim2.new(0.015, 0, 0, 8)
indexGrid.SortOrder = Enum.SortOrder.LayoutOrder
indexGrid.Parent = indexScroll

local orderIdx = 0
for rIdx = #GameConfig.RARITY_ORDER, 1, -1 do
	local rarity = GameConfig.RARITY_ORDER[rIdx]
	local rCol = GameConfig.RARITY_COLORS[rarity]
	for _, card in Footballers.ByRarity[rarity] do
		orderIdx += 1
		local cell = Instance.new("Frame")
		cell.LayoutOrder = orderIdx
		cell.BackgroundColor3 = UITheme.Colors.CardBg
		UITheme.addCorner(cell, 8)
		UITheme.applyStroke(cell, 3, rCol)
		UITheme.addStuds(cell, 0.90, 18)
		UITheme.addBevel(cell, 8)
		cell.Parent = indexScroll

		local lbl = makeLabel(cell, `??? {card.pos}\nLOCKED\n{string.upper(rarity)}`, UDim2.new(0.92, 0, 0.88, 0), UDim2.new(0.04, 0, 0.06, 0), Color3.fromRGB(150, 155, 170))
		indexCardCells[card.id] = { frame = cell, label = lbl, card = card }
	end
end
end -- Page 6 Index block

-- Build Page 7: SPIN WHEEL VIEW (Auto-opened by stepping into Lobby SpinWheelStation ring)
local wheelSpinning = false
local wheelCurrentRot = 0
local lastHandledWheelSeq = (localPlayer:GetAttribute("WheelSpinSeq") :: number?) or 0

local wheelRotVal = Instance.new("NumberValue")
local wheelSpinsCountLbl: TextLabel
local spinBtnLabel: TextLabel
local refreshProfileGlobalRanks: () -> ()
local updateProfilePage: (p: any, elapsed: number, disc: { [string]: boolean }, discCount: number, pct: number) -> ()

do
	local wheelOuterRim = Instance.new("Frame")
wheelOuterRim.Name = "WheelOuterRim"
wheelOuterRim.Size = UDim2.fromOffset(258, 258)
wheelOuterRim.Position = UDim2.new(0.03, 0, 0.5, -129)
wheelOuterRim.BackgroundColor3 = Color3.fromRGB(36, 41, 54)
addCorner(wheelOuterRim, 129)
addStroke(wheelOuterRim, Color3.new(0, 0, 0), 4)
wheelOuterRim.Parent = pageWheel

local wheelDiscGui = Instance.new("Frame")
wheelDiscGui.Name = "WheelDisc"
wheelDiscGui.Size = UDim2.fromOffset(230, 230)
wheelDiscGui.AnchorPoint = Vector2.new(0.5, 0.5)
wheelDiscGui.Position = UDim2.fromScale(0.5, 0.5)
wheelDiscGui.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
wheelDiscGui.ClipsDescendants = true
addCorner(wheelDiscGui, 115)
wheelDiscGui.Parent = wheelOuterRim

local wheelVp = Instance.new("ViewportFrame")
wheelVp.Name = "WheelViewport"
wheelVp.Size = UDim2.fromScale(1, 1)
wheelVp.BackgroundTransparency = 1
wheelVp.Ambient = Color3.new(1, 1, 1)
wheelVp.LightColor = Color3.new(0, 0, 0)
wheelVp.ZIndex = 26
addCorner(wheelVp, 115)
wheelVp.Parent = wheelDiscGui

local wheelVpCam = Instance.new("Camera")
wheelVpCam.FieldOfView = 18
wheelVpCam.CFrame = CFrame.new(0, 0, 36.8)
wheelVpCam.Parent = wheelVp
wheelVp.CurrentCamera = wheelVpCam

local wheel3DModel = Instance.new("Model")
wheel3DModel.Name = "Wheel3D"
local wheelPivot = Instance.new("Part")
wheelPivot.Name = "Pivot"
wheelPivot.Size = Vector3.new(0.2, 0.2, 0.2)
wheelPivot.Transparency = 1
wheelPivot.Anchored = true
wheelPivot.CFrame = CFrame.new(0, 0, 0)
wheelPivot.Parent = wheel3DModel
wheel3DModel.PrimaryPart = wheelPivot
wheel3DModel.Parent = wheelVp

local wheelLabelsLayer = Instance.new("Frame")
wheelLabelsLayer.Name = "WheelLabelsLayer"
wheelLabelsLayer.Size = UDim2.fromOffset(230, 230)
wheelLabelsLayer.AnchorPoint = Vector2.new(0.5, 0.5)
wheelLabelsLayer.Position = UDim2.fromScale(0.5, 0.5)
wheelLabelsLayer.BackgroundTransparency = 1
wheelLabelsLayer.ZIndex = 27
wheelLabelsLayer.Parent = wheelOuterRim

do
	local vpRadius = 6.2
	local halfA = math.rad(22.5)
	local wH = vpRadius * math.cos(halfA)
	local wW = vpRadius * math.sin(halfA)
	for i, seg in GameConfig.WHEEL_SEGMENTS do
		local deg = (i - 1) * 45
		local sliceCF = CFrame.Angles(0, 0, -math.rad(deg))
		local segCol = Color3.fromHex(seg.color)
		for _, side in { -1, 1 } do
			local wp = Instance.new("WedgePart")
			wp.Size = Vector3.new(0.2, wH, wW)
			wp.CFrame = sliceCF
				* CFrame.fromMatrix(
					Vector3.new(side * wW * 0.5, wH * 0.5, 0),
					Vector3.new(0, 0, -side),
					Vector3.new(0, -1, 0),
					Vector3.new(-side, 0, 0)
				)
			wp.Anchored = true
			wp.Color = segCol
			wp.Material = Enum.Material.SmoothPlastic
			wp.Parent = wheel3DModel
		end
		local spoke = Instance.new("Part")
		spoke.Size = Vector3.new(0.14, vpRadius, 0.26)
		spoke.CFrame = CFrame.Angles(0, 0, -math.rad(deg + 22.5)) * CFrame.new(0, vpRadius * 0.5, 0.06)
		spoke.Anchored = true
		spoke.Color = Color3.fromRGB(22, 25, 34)
		spoke.Material = Enum.Material.SmoothPlastic
		spoke.Parent = wheel3DModel

		local lRad = math.rad(deg)
		local lx = 115 + math.sin(lRad) * 69
		local ly = 115 - math.cos(lRad) * 69
		local lblBox = Instance.new("Frame")
		lblBox.Name = `SliceLabel_{i}`
		lblBox.Size = UDim2.fromOffset(58, 52)
		lblBox.AnchorPoint = Vector2.new(0.5, 0.5)
		lblBox.Position = UDim2.fromOffset(lx, ly)
		lblBox.Rotation = deg
		lblBox.BackgroundTransparency = 1
		lblBox.ZIndex = 28
		lblBox.Parent = wheelLabelsLayer

		local pIcon = Instance.new("ImageLabel")
		pIcon.Name = "SliceIcon"
		pIcon.Size = UDim2.fromOffset(20, 20)
		pIcon.Position = UDim2.new(0.5, -10, 0, 2)
		pIcon.BackgroundTransparency = 1
		pIcon.Image = if seg.id == 4 then UITheme.Assets.CrownIcon else UITheme.Assets.CashStack
		pIcon.ScaleType = Enum.ScaleType.Fit
		pIcon.ZIndex = 29
		pIcon.Parent = lblBox

		local pTxt = Instance.new("TextLabel")
		pTxt.Name = "SliceText"
		pTxt.Size = UDim2.new(1, 0, 0, 26)
		pTxt.Position = UDim2.new(0, 0, 0, 24)
		pTxt.BackgroundTransparency = 1
		pTxt.Font = UITheme.Fonts.Primary
		pTxt.TextColor3 = if seg.id == 4 then UITheme.Colors.NoticeYellow else UITheme.Colors.White
		pTxt.Text = seg.label
		pTxt.TextScaled = true
		UITheme.addTextConstraint(pTxt, 10, 14)
		UITheme.applyTextStroke(pTxt, 2, UITheme.Colors.Black)
		pTxt.ZIndex = 29
		pTxt.Parent = lblBox

		local bulbRad = math.rad(deg + 22.5 - 90)
		local bx = 129 + math.cos(bulbRad) * 121
		local by = 129 + math.sin(bulbRad) * 121
		local bulb = Instance.new("Frame")
		bulb.Size = UDim2.fromOffset(10, 10)
		bulb.AnchorPoint = Vector2.new(0.5, 0.5)
		bulb.Position = UDim2.fromOffset(bx, by)
		bulb.BackgroundColor3 = Color3.fromRGB(255, 214, 58)
		bulb.BorderSizePixel = 0
		bulb.ZIndex = 30
		addCorner(bulb, 5)
		bulb.Parent = wheelOuterRim
	end
end

	wheelRotVal.Changed:Connect(function(v)
		wheelLabelsLayer.Rotation = v
		wheel3DModel:PivotTo(CFrame.Angles(0, 0, -math.rad(v)))
	end)

	local wheelHubCap = Instance.new("Frame")
	wheelHubCap.Size = UDim2.fromOffset(48, 48)
	wheelHubCap.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelHubCap.Position = UDim2.fromScale(0.5, 0.5)
	wheelHubCap.BackgroundColor3 = Color3.fromHex("#C81E2B")
	wheelHubCap.ZIndex = 31
	addCorner(wheelHubCap, 24)
	addStroke(wheelHubCap, Color3.fromRGB(32, 36, 48), 5)
	wheelHubCap.Parent = wheelOuterRim

	local pointerClip = Instance.new("Frame")
	pointerClip.Size = UDim2.fromOffset(38, 24)
	pointerClip.AnchorPoint = Vector2.new(0.5, 0)
	pointerClip.Position = UDim2.new(0.5, 0, 0, -6)
	pointerClip.BackgroundTransparency = 1
	pointerClip.ClipsDescendants = true
	pointerClip.ZIndex = 32
	pointerClip.Parent = wheelOuterRim

	local pointerDiamond = Instance.new("Frame")
	pointerDiamond.Size = UDim2.fromOffset(26, 26)
	pointerDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
	pointerDiamond.Position = UDim2.fromOffset(19, 2)
	pointerDiamond.Rotation = 45
	pointerDiamond.BackgroundColor3 = Color3.fromHex("#DC2626")
	pointerDiamond.ZIndex = 32
	addStroke(pointerDiamond, Color3.fromRGB(20, 22, 30), 2)
	pointerDiamond.Parent = pointerClip

	local wheelRightPane = Instance.new("Frame")
	wheelRightPane.Size = UDim2.new(0.50, 0, 0.94, 0)
	wheelRightPane.Position = UDim2.new(0.48, 0, 0.03, 0)
	wheelRightPane.BackgroundTransparency = 1
	wheelRightPane.Parent = pageWheel

	local wheelSpinsPlate = Instance.new("Frame")
	wheelSpinsPlate.Name = "WheelSpinsPlate"
	wheelSpinsPlate.Size = UDim2.new(1, 0, 0, 42)
	wheelSpinsPlate.Position = UDim2.new(0, 0, 0, 0)
	wheelSpinsPlate.BackgroundColor3 = UITheme.Colors.CardBg
	UITheme.addCorner(wheelSpinsPlate, 10)
	UITheme.applyStroke(wheelSpinsPlate, 3, UITheme.Colors.GoldBottom)
	UITheme.addStuds(wheelSpinsPlate, 0.90, 20)
	UITheme.addBevel(wheelSpinsPlate, 10)
	UITheme.addShadow(wheelSpinsPlate, 10, 3)
	wheelSpinsPlate.Parent = wheelRightPane

	wheelSpinsCountLbl = Instance.new("TextLabel")
	wheelSpinsCountLbl.Name = "SpinsCountText"
	wheelSpinsCountLbl.Size = UDim2.new(0.92, 0, 0.8, 0)
	wheelSpinsCountLbl.Position = UDim2.new(0.04, 0, 0.1, 0)
	wheelSpinsCountLbl.BackgroundTransparency = 1
	wheelSpinsCountLbl.Font = UITheme.Fonts.Titles
	wheelSpinsCountLbl.TextColor3 = UITheme.Colors.NoticeYellow
	wheelSpinsCountLbl.Text = "🎟️ AVAILABLE SPINS: 1"
	wheelSpinsCountLbl.TextScaled = true
	UITheme.applyTextStroke(wheelSpinsCountLbl, 2.5, UITheme.Colors.Black)
	wheelSpinsCountLbl.Parent = wheelSpinsPlate

	local wheelOddsList = {
		{ text = "$150 — 45%", col = Color3.fromHex("#1D7BF6"), icon = UITheme.Assets.CashStack },
		{ text = "$350 — 30%", col = Color3.fromHex("#22C55E"), icon = UITheme.Assets.CashStack },
		{ text = "$750 — 17%", col = Color3.fromHex("#F59E0B"), icon = UITheme.Assets.CashStack },
		{ text = "CYBER CHAIR + $500 — 8%", col = Color3.fromHex("#FF2E93"), icon = UITheme.Assets.CrownIcon },
	}
	for idx, item in wheelOddsList do
		local row = Instance.new("Frame")
		row.Name = `OddsRow_{idx}`
		row.Size = UDim2.new(1, 0, 0, 42)
		row.Position = UDim2.new(0, 0, 0, 48 + (idx - 1) * 46)
		row.BackgroundColor3 = UITheme.Colors.CardBg
		UITheme.addCorner(row, 8)
		UITheme.applyStroke(row, 3, item.col)
		UITheme.addStuds(row, 0.90, 20)
		UITheme.addBevel(row, 8)
		UITheme.addShadow(row, 8, 3)
		row.Parent = wheelRightPane

		local rIcon = Instance.new("ImageLabel")
		rIcon.Name = "RowIcon"
		rIcon.Size = UDim2.fromOffset(24, 24)
		rIcon.Position = UDim2.new(0, 10, 0.5, -12)
		rIcon.BackgroundTransparency = 1
		rIcon.Image = item.icon
		rIcon.ScaleType = Enum.ScaleType.Fit
		rIcon.ZIndex = row.ZIndex + 2
		rIcon.Parent = row

		local rTxt = Instance.new("TextLabel")
		rTxt.Name = "RowText"
		rTxt.Size = UDim2.new(1, -44, 0.8, 0)
		rTxt.Position = UDim2.new(0, 40, 0.1, 0)
		rTxt.BackgroundTransparency = 1
		rTxt.Font = UITheme.Fonts.Primary
		rTxt.TextColor3 = UITheme.Colors.White
		rTxt.TextXAlignment = Enum.TextXAlignment.Left
		rTxt.Text = item.text
		rTxt.TextScaled = true
		UITheme.addTextConstraint(rTxt, 11, 16)
		UITheme.applyTextStroke(rTxt, 2.5, UITheme.Colors.Black)
		rTxt.ZIndex = row.ZIndex + 2
		rTxt.Parent = row
	end

	local btnDoSpinWheel = Instance.new("TextButton")
	btnDoSpinWheel.Name = "BtnDoSpinWheel"
	btnDoSpinWheel.Size = UDim2.new(1, 0, 0, 56)
	btnDoSpinWheel.Position = UDim2.new(0, 0, 1, -58)
	btnDoSpinWheel.Text = ""
	UITheme.styleButton(btnDoSpinWheel, "Lime", 10)
	UITheme.addStuds(btnDoSpinWheel, 0.85, 20)
	UITheme.addPulse(btnDoSpinWheel, 1.0, 1.04, 1.2)
	UITheme.addShineSweep(btnDoSpinWheel, 3.0)

	spinBtnLabel = Instance.new("TextLabel")
	spinBtnLabel.Name = "BtnLabel"
	spinBtnLabel.Size = UDim2.new(0.92, 0, 0.8, 0)
	spinBtnLabel.Position = UDim2.new(0.04, 0, 0.1, 0)
	spinBtnLabel.BackgroundTransparency = 1
	spinBtnLabel.Font = UITheme.Fonts.Primary
	spinBtnLabel.TextColor3 = UITheme.Colors.White
	spinBtnLabel.Text = "🎡 SPIN WHEEL (1)"
	spinBtnLabel.TextScaled = true
	UITheme.addTextConstraint(spinBtnLabel, 14, 22)
	UITheme.applyTextStroke(spinBtnLabel, 3, UITheme.Colors.Black)
	spinBtnLabel.ZIndex = btnDoSpinWheel.ZIndex + 3
	spinBtnLabel.Parent = btnDoSpinWheel
	btnDoSpinWheel.Parent = wheelRightPane

	btnDoSpinWheel.Activated:Connect(function()
		if wheelSpinning then
			return
		end
		Remotes.MetaAction:FireServer("SpinWheel")
	end)

	-- ============================================================
	-- Build Page 8: PLAYER STATS TRACKER (1. Profil, 2. Pertandingan, 3. Koleksi Kartu)
	-- ============================================================
	local profileScroll = Instance.new("ScrollingFrame")
	profileScroll.Size = UDim2.new(1, -24, 1, -20)
	profileScroll.Position = UDim2.new(0, 12, 0, 10)
	profileScroll.BackgroundTransparency = 1
	profileScroll.BorderSizePixel = 0
	profileScroll.ScrollBarThickness = 6
	profileScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	profileScroll.CanvasSize = UDim2.fromScale(0, 0)
	profileScroll.ZIndex = 70
	profileScroll.Parent = pageProfile

	local profileScrollLayout = Instance.new("UIListLayout")
	profileScrollLayout.Padding = UDim.new(0, 12)
	profileScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	profileScrollLayout.Parent = profileScroll

	local function makeProfileSection(order: number, titleText: string, accentColor: Color3, heightPx: number): Frame
		local sec = Instance.new("Frame")
		sec.LayoutOrder = order
		sec.Size = UDim2.new(1, -8, 0, heightPx)
		sec.BackgroundColor3 = UITheme.Colors.CardDark
		sec.BorderSizePixel = 0
		sec.ZIndex = 71
		UITheme.addCorner(sec, 12)
		UITheme.applyStroke(sec, 2, accentColor)
		sec.Parent = profileScroll

		local hdr = Instance.new("TextLabel")
		hdr.Size = UDim2.new(1, -24, 0, 26)
		hdr.Position = UDim2.fromOffset(12, 8)
		hdr.BackgroundTransparency = 1
		hdr.Font = UITheme.Fonts.Primary
		hdr.TextColor3 = accentColor
		hdr.TextXAlignment = Enum.TextXAlignment.Left
		hdr.TextScaled = true
		hdr.Text = titleText
		hdr.ZIndex = 72
		UITheme.addTextConstraint(hdr, 12, 20)
		UITheme.applyTextStroke(hdr, 2, UITheme.Colors.Black)
		hdr.Parent = sec
		return sec
	end

	local function makeStatTile(parent: Instance, pos: UDim2, size: UDim2, labelText: string, accent: Color3?): TextLabel
		local tile = Instance.new("Frame")
		tile.Size = size
		tile.Position = pos
		tile.BackgroundColor3 = UITheme.Colors.CardBg
		tile.BorderSizePixel = 0
		tile.ZIndex = 72
		UITheme.addCorner(tile, 8)
		UITheme.applyStroke(tile, 1.5, accent or UITheme.Colors.GrayTop)
		tile.Parent = parent

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -12, 0.42, 0)
		lbl.Position = UDim2.fromOffset(6, 4)
		lbl.BackgroundTransparency = 1
		lbl.Font = UITheme.Fonts.Body
		lbl.TextColor3 = Color3.fromRGB(175, 190, 215)
		lbl.TextScaled = true
		lbl.Text = labelText
		lbl.ZIndex = 73
		UITheme.addTextConstraint(lbl, 9, 14)
		UITheme.applyTextStroke(lbl, 1.5, UITheme.Colors.Black)
		lbl.Parent = tile

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(1, -12, 0.5, 0)
		val.Position = UDim2.new(0, 6, 0.46, 0)
		val.BackgroundTransparency = 1
		val.Font = UITheme.Fonts.Primary
		val.TextColor3 = UITheme.Colors.White
		val.TextScaled = true
		val.Text = "-"
		val.ZIndex = 73
		UITheme.addTextConstraint(val, 11, 20)
		UITheme.applyTextStroke(val, 2, UITheme.Colors.Black)
		val.Parent = tile
		return val
	end

	-- 1. PROFIL
	local secProfil = makeProfileSection(1, "1. PROFIL PEMAIN", UITheme.Colors.CyanTop, 188)

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size = UDim2.fromOffset(88, 88)
	avatarImg.Position = UDim2.fromOffset(10, 34)
	avatarImg.BackgroundTransparency = 1
	avatarImg.ScaleType = Enum.ScaleType.Fit
	avatarImg.ZIndex = 73
	avatarImg.Parent = secProfil
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and content then
			avatarImg.Image = content
		end
	end)

	local profNameLabel = Instance.new("TextLabel")
	profNameLabel.Size = UDim2.new(0.42, -104, 0, 26)
	profNameLabel.Position = UDim2.fromOffset(102, 38)
	profNameLabel.BackgroundTransparency = 1
	profNameLabel.Font = UITheme.Fonts.Primary
	profNameLabel.TextColor3 = UITheme.Colors.White
	profNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	profNameLabel.TextScaled = true
	profNameLabel.Text = `{localPlayer.DisplayName} (@{localPlayer.Name})`
	profNameLabel.ZIndex = 73
	UITheme.addTextConstraint(profNameLabel, 11, 20)
	UITheme.applyTextStroke(profNameLabel, 2, UITheme.Colors.Black)
	profNameLabel.Parent = secProfil

	local profTitleBadge = Instance.new("TextLabel")
	profTitleBadge.Size = UDim2.new(0.42, -104, 0, 24)
	profTitleBadge.Position = UDim2.fromOffset(102, 66)
	profTitleBadge.BackgroundTransparency = 1
	profTitleBadge.Font = UITheme.Fonts.Primary
	profTitleBadge.TextColor3 = UITheme.Colors.GoldTop
	profTitleBadge.TextXAlignment = Enum.TextXAlignment.Left
	profTitleBadge.TextScaled = true
	profTitleBadge.Text = "🏷️ GELAR: BENCHWARMER"
	profTitleBadge.ZIndex = 73
	UITheme.addTextConstraint(profTitleBadge, 10, 17)
	UITheme.applyTextStroke(profTitleBadge, 2, UITheme.Colors.Black)
	profTitleBadge.Parent = secProfil

	local profFirstJoinVal = makeStatTile(secProfil, UDim2.new(0.43, 0, 0, 38), UDim2.new(0.275, -6, 0, 82), "PERTAMA MAIN", UITheme.Colors.CyanTop)
	local profPlaytimeVal = makeStatTile(secProfil, UDim2.new(0.715, 0, 0, 38), UDim2.new(0.285, -12, 0, 82), "TOTAL PLAYTIME", UITheme.Colors.CyanTop)

	local rankLabels: { [string]: TextLabel } = {}
	local rankBoards = {
		{ key = "Wins", title = "RANK WINS", color = UITheme.Colors.GoldTop },
		{ key = "Streak", title = "RANK STREAK", color = UITheme.Colors.OrangeTop },
		{ key = "Cash", title = "RANK CASH", color = UITheme.Colors.MoneyGreen },
		{ key = "Playtime", title = "RANK PLAYTIME", color = UITheme.Colors.CyanTop },
	}
	for idx, rb in rankBoards do
		local xScale = (idx - 1) * 0.25
		rankLabels[rb.key] = makeStatTile(
			secProfil,
			UDim2.new(xScale, if idx == 1 then 12 else 6, 0, 126),
			UDim2.new(0.25, if idx == 1 or idx == 4 then -18 else -12, 0, 52),
			rb.title,
			rb.color
		)
	end

	-- 2. PERTANDINGAN
	local secMatch = makeProfileSection(2, "2. PERTANDINGAN", UITheme.Colors.GoldTop, 166)
	local profTotalWinsVal = makeStatTile(secMatch, UDim2.new(0, 12, 0, 38), UDim2.new(0.333, -16, 0, 56), "TOTAL WINS", UITheme.Colors.GoldTop)
	local profBestStreakVal = makeStatTile(secMatch, UDim2.new(0.333, 4, 0, 38), UDim2.new(0.333, -8, 0, 56), "BEST STREAK", UITheme.Colors.OrangeTop)
	local profCurStreakVal = makeStatTile(secMatch, UDim2.new(0.666, 4, 0, 38), UDim2.new(0.334, -16, 0, 56), "STREAK SAAT INI", UITheme.Colors.OrangeTop)
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
		local rarityRankMap: { [string]: number } = { Common = 1, Rare = 2, Epic =]=]
print("Loaded fixed chunk 2")

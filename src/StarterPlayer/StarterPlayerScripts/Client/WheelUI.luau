--!strict
--[[
	WheelUI
	Responsibility: Modular Spin Wheel modal matching Figma BAF_Spin_Wheel_Master_v2 (Node 3:2)
	with crisp white typography + black UIStroke outlines across all labels.
	Location: StarterPlayer/StarterPlayerScripts/Client/WheelUI (ModuleScript)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WheelUI = {}

export type WheelHandler = {
	window: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	isSpinning: () -> boolean,
	update: (profile: any, now: number?) -> (),
	playSpinAnimation: (sliceIdx: number, onComplete: () -> ()) -> (),
}

local DESIGN_WIDTH = 1000
local DESIGN_HEIGHT = 640

local function isMobileViewport(vX: number, vY: number): boolean
	return UserInputService.TouchEnabled or vY <= 540 or vX <= 960
end

local function getWheelScale(): number
	local cam = Workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local vX = if vp.X > 0 then vp.X else 1280
	local vY = if vp.Y > 0 then vp.Y else 720
	local fitScale = math.min((vX - 24) / DESIGN_WIDTH, (vY - 64) / DESIGN_HEIGHT)
	if isMobileViewport(vX, vY) then
		fitScale *= 0.82
	end
	return math.clamp(fitScale, 0.32, 1.05)
end

local function makeStrokedLabel(
	parent: Instance,
	text: string,
	size: UDim2,
	pos: UDim2,
	UITheme: any,
	strokeThickness: number,
	minTextSize: number,
	maxTextSize: number,
	zIndex: number,
	align: Enum.TextXAlignment?
): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Size = size
	lbl.Position = pos
	lbl.BackgroundTransparency = 1
	lbl.Font = UITheme.CONFIG.Font
	lbl.TextColor3 = UITheme.Colors.White
	lbl.TextStrokeTransparency = 1
	lbl.Text = text
	lbl.TextScaled = true
	lbl.TextXAlignment = align or Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.ZIndex = zIndex
	-- Clamp MinTextSize so UIScale on small mobile viewports never prevents TextScaled from fitting
	UITheme.addTextConstraint(lbl, math.min(minTextSize, 4), maxTextSize)
	UITheme.applyTextStroke(lbl, strokeThickness, UITheme.Colors.Outline)
	lbl.Parent = parent
	return lbl
end

local function makeRobuxPill(parent: GuiObject, priceText: string, size: UDim2, pos: UDim2, anchor: Vector2, UITheme: any, zIndex: number): (Frame, TextLabel)
	local pill = Instance.new("Frame")
	pill.Name = "RobuxPill"
	pill.Size = size
	pill.Position = pos
	pill.AnchorPoint = anchor
	pill.BackgroundColor3 = Color3.fromHex("#48C90E")
	pill.BorderSizePixel = 0
	pill.ZIndex = zIndex
	UITheme.addCorner(pill, 14)
	UITheme.applyStroke(pill, 2, UITheme.Colors.Outline)

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = pill

	local icon = Instance.new("ImageLabel")
	icon.Name = "RobuxIcon"
	icon.LayoutOrder = 1
	icon.Size = UDim2.fromOffset(14, 14)
	icon.BackgroundTransparency = 1
	icon.Image = UITheme.Assets.Icon_Robux or UITheme.Assets.RobuxSmall
	icon.ImageColor3 = UITheme.Colors.White
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = zIndex + 1
	icon.Parent = pill

	local txt = makeStrokedLabel(pill, priceText, UDim2.new(0, 32, 0.9, 0), UDim2.new(), UITheme, 2, 10, 16, zIndex + 1)
	txt.Name = "PriceText"
	txt.LayoutOrder = 2
	txt.AutomaticSize = Enum.AutomaticSize.X
	txt.Size = UDim2.new(0, 0, 0.9, 0)

	pill.Parent = parent
	return pill, txt
end

local function makeSpinPackButton(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	w: number,
	h: number,
	variant: string,
	labelText: string,
	price: number,
	UITheme: any,
	onClick: () -> ()
): TextButton
	local wrap = Instance.new("Frame")
	wrap.Name = name .. "Wrap"
	wrap.Size = UDim2.fromOffset(w, h)
	wrap.Position = UDim2.fromOffset(x, y)
	wrap.BackgroundTransparency = 1
	wrap.ClipsDescendants = false
	wrap.ZIndex = 34
	wrap.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, h - 14)
	btn.Position = UDim2.fromOffset(0, 14)
	btn.Text = ""
	btn.ZIndex = 34
	UITheme.button(btn, variant, 10)
	btn.Parent = wrap

	local lbl = makeStrokedLabel(btn, labelText, UDim2.new(0.9, 0, 0.78, 0), UDim2.new(0.05, 0, 0.11, 0), UITheme, 2.5, 11, 18, btn.ZIndex + 3)
	lbl.Name = "BtnLabel"

	makeRobuxPill(wrap, tostring(price), UDim2.fromOffset(60, 22), UDim2.new(0.5, 0, 0, 0), Vector2.new(0.5, 0), UITheme, btn.ZIndex + 5)

	btn.Activated:Connect(onClick)
	return btn
end

local function getSliceStuds(segId: number, UITheme: any): (string, Color3)
	if segId == 1 or segId == 4 then
		return UITheme.Assets.Header_Studs_DailyQuest_Green, Color3.new(1, 1, 1)
	elseif segId == 2 then
		return UITheme.Assets.Header_Studs_ChairSkins_Yellow, Color3.new(1, 1, 1)
	elseif segId == 3 then
		return UITheme.Assets.Header_Studs_Shop_Red, Color3.new(1, 1, 1)
	elseif segId == 5 or segId == 8 then
		return UITheme.Assets.Header_Studs_Titles_Cyan, Color3.new(1, 1, 1)
	else
		return UITheme.Assets.Header_Studs_Shop_Red, Color3.fromHex("#C084FC")
	end
end

function WheelUI.init(
	screenGui: ScreenGui,
	modalBackdrop: GuiObject,
	Remotes: any,
	UITheme: any,
	GameConfig: any,
	playSfx: ((string) -> ())?
): WheelHandler
	local wheelSpinning = false
	local wheelCurrentRot = 0
	local spinAnimToken = 0
	local cachedSpins = 0
	local lastProfile: any = nil
	local lastSpinVariant = "lime"

	local wheelWindow = Instance.new("Frame")
	wheelWindow.Name = "WheelWindow"
	wheelWindow.Size = UDim2.fromOffset(DESIGN_WIDTH, DESIGN_HEIGHT)
	wheelWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelWindow.Position = UDim2.new(0.5, 0, 0.5, 18)
	wheelWindow.BackgroundTransparency = 1
	wheelWindow.BorderSizePixel = 0
	wheelWindow.ClipsDescendants = false
	wheelWindow.Visible = false
	wheelWindow.ZIndex = 26
	wheelWindow.Parent = screenGui

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = getWheelScale()
	uiScale.Parent = wheelWindow

	local cam = Workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if wheelWindow.Visible then
				uiScale.Scale = getWheelScale()
			end
		end)
	end

	-- Top-right Close Button
	local btnClose = Instance.new("TextButton")
	btnClose.Name = "CloseButton"
	btnClose.Size = UDim2.fromOffset(44, 44)
	btnClose.Position = UDim2.new(1, -22, 0, 20)
	btnClose.AnchorPoint = Vector2.new(1, 0)
	btnClose.Text = ""
	btnClose.ZIndex = 40
	UITheme.button(btnClose, "magenta", 10)
	local closeLbl = makeStrokedLabel(btnClose, "X", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1), UITheme, 3, 16, 26, btnClose.ZIndex + 3)
	closeLbl.Name = "BtnLabel"
	btnClose.Parent = wheelWindow

	-- Left Odds Panel (pink border + yellow top bar + 8 rarity rows)
	local oddsPanel = Instance.new("Frame")
	oddsPanel.Name = "OddsPanel"
	oddsPanel.Size = UDim2.fromOffset(270, 524)
	oddsPanel.Position = UDim2.fromOffset(34, 24)
	oddsPanel.BackgroundColor3 = Color3.fromHex("#141A26")
	oddsPanel.BackgroundTransparency = 0.02
	oddsPanel.BorderSizePixel = 0
	oddsPanel.ZIndex = 30
	UITheme.addCorner(oddsPanel, 12)
	UITheme.applyStroke(oddsPanel, 3.5, UITheme.Colors.CloseMagentaTop)
	oddsPanel.Parent = wheelWindow

	local oddsTopAccent = Instance.new("Frame")
	oddsTopAccent.Name = "TopAccent"
	oddsTopAccent.Size = UDim2.new(1, -16, 0, 4)
	oddsTopAccent.Position = UDim2.fromOffset(8, 5)
	oddsTopAccent.BackgroundColor3 = Color3.fromHex("#FFD21F")
	oddsTopAccent.BorderSizePixel = 0
	oddsTopAccent.ZIndex = 31
	UITheme.addCorner(oddsTopAccent, 2)
	oddsTopAccent.Parent = oddsPanel

	local oddsList = Instance.new("Frame")
	oddsList.Name = "OddsList"
	oddsList.Size = UDim2.new(1, -20, 1, -24)
	oddsList.Position = UDim2.fromOffset(10, 16)
	oddsList.BackgroundTransparency = 1
	oddsList.ZIndex = 31
	oddsList.Parent = oddsPanel

	local oddsLayout = Instance.new("UIListLayout")
	oddsLayout.FillDirection = Enum.FillDirection.Vertical
	oddsLayout.Padding = UDim.new(0, 7)
	oddsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	oddsLayout.Parent = oddsList

	local sortedOdds = table.clone(GameConfig.WHEEL_SEGMENTS)
	table.sort(sortedOdds, function(a: any, b: any)
		return (a.oddsOrder or a.id) < (b.oddsOrder or b.id)
	end)

	for _, seg in sortedOdds do
		local rowColor = Color3.fromHex(seg.strokeColor or seg.color)
		local row = Instance.new("Frame")
		row.Name = `OddsRow_{seg.id}`
		row.LayoutOrder = seg.oddsOrder or seg.id
		row.Size = UDim2.new(1, 0, 0, 55)
		row.BackgroundColor3 = Color3.fromHex("#1B2333")
		row.BorderSizePixel = 0
		row.ZIndex = 32
		UITheme.addCorner(row, 8)
		UITheme.applyStroke(row, 2.5, rowColor)
		row.Parent = oddsList

		local iconSlot = Instance.new("Frame")
		iconSlot.Size = UDim2.fromOffset(38, 38)
		iconSlot.Position = UDim2.new(0, 8, 0.5, 0)
		iconSlot.AnchorPoint = Vector2.new(0, 0.5)
		iconSlot.BackgroundColor3 = Color3.fromHex("#101622")
		iconSlot.BorderSizePixel = 0
		iconSlot.ZIndex = 33
		UITheme.addCorner(iconSlot, 6)
		iconSlot.Parent = row

		local rIcon = Instance.new("ImageLabel")
		rIcon.Size = UDim2.fromOffset(30, 30)
		rIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		rIcon.Position = UDim2.fromScale(0.5, 0.5)
		rIcon.BackgroundTransparency = 1
		rIcon.Image = UITheme.Assets[seg.assetKey] or UITheme.Assets.Icon_CashCube
		rIcon.ScaleType = Enum.ScaleType.Fit
		rIcon.ZIndex = 34
		rIcon.Parent = iconSlot

		local rName = makeStrokedLabel(
			row,
			seg.oddsName or seg.label,
			UDim2.new(1, -134, 0.84, 0),
			UDim2.new(0, 52, 0.08, 0),
			UITheme,
			2,
			10,
			15,
			33,
			Enum.TextXAlignment.Left
		)
		rName.Name = "RewardName"

		local pctPill = Instance.new("Frame")
		pctPill.Size = UDim2.fromOffset(70, 28)
		pctPill.Position = UDim2.new(1, -8, 0.5, 0)
		pctPill.AnchorPoint = Vector2.new(1, 0.5)
		pctPill.BackgroundColor3 = Color3.fromHex("#101622")
		pctPill.BorderSizePixel = 0
		pctPill.ZIndex = 33
		UITheme.addCorner(pctPill, 14)
		UITheme.applyStroke(pctPill, 2, rowColor)
		pctPill.Parent = row

		local pctLbl = makeStrokedLabel(
			pctPill,
			seg.oddsPct or `{seg.weight}%`,
			UDim2.new(0.88, 0, 0.84, 0),
			UDim2.new(0.06, 0, 0.08, 0),
			UITheme,
			2,
			10,
			14,
			34
		)
		pctLbl.Name = "PctLabel"
	end

	-- Center Spin Wheel (424x424 rim at center X=625, Y=258)
	local wheelOuterRim = Instance.new("Frame")
	wheelOuterRim.Name = "WheelOuterRim"
	wheelOuterRim.Size = UDim2.fromOffset(424, 424)
	wheelOuterRim.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelOuterRim.Position = UDim2.fromOffset(625, 258)
	wheelOuterRim.BackgroundColor3 = Color3.fromHex("#090B10")
	wheelOuterRim.BorderSizePixel = 0
	wheelOuterRim.ZIndex = 30
	UITheme.addCorner(wheelOuterRim, 212)
	UITheme.applyStroke(wheelOuterRim, 4, UITheme.Colors.Outline)
	wheelOuterRim.Parent = wheelWindow

	local wheelDisc = Instance.new("Frame")
	wheelDisc.Name = "WheelDisc"
	wheelDisc.Size = UDim2.fromOffset(404, 404)
	wheelDisc.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelDisc.Position = UDim2.fromScale(0.5, 0.5)
	wheelDisc.BackgroundColor3 = Color3.fromHex("#111622")
	wheelDisc.BorderSizePixel = 0
	wheelDisc.ZIndex = 31
	UITheme.addCorner(wheelDisc, 202)
	wheelDisc.Parent = wheelOuterRim

	-- Pure 2D Pie Slices (CanvasGroup + UIGradient half-plane masks + color-matched Lego Studs)
	local pieGroup = Instance.new("CanvasGroup")
	pieGroup.Name = "WheelPieSlices"
	pieGroup.Size = UDim2.fromScale(1, 1)
	pieGroup.AnchorPoint = Vector2.new(0.5, 0.5)
	pieGroup.Position = UDim2.fromScale(0.5, 0.5)
	pieGroup.BackgroundTransparency = 1
	pieGroup.BorderSizePixel = 0
	pieGroup.ZIndex = 32
	UITheme.addCorner(pieGroup, 202)
	pieGroup.Parent = wheelDisc

	local wheelLabelsLayer = Instance.new("Frame")
	wheelLabelsLayer.Name = "WheelLabelsLayer"
	wheelLabelsLayer.Size = UDim2.fromOffset(404, 404)
	wheelLabelsLayer.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelLabelsLayer.Position = UDim2.fromScale(0.5, 0.5)
	wheelLabelsLayer.BackgroundTransparency = 1
	wheelLabelsLayer.ZIndex = 34
	wheelLabelsLayer.Parent = wheelOuterRim

	-- 4 crisp black diameter spoke lines dividing the 8 slices (0, 45, 90, 135 deg)
	for s = 0, 3 do
		local spokeLine = Instance.new("Frame")
		spokeLine.Name = `SpokeLine_{s}`
		spokeLine.Size = UDim2.new(0, 3, 1, -2)
		spokeLine.AnchorPoint = Vector2.new(0.5, 0.5)
		spokeLine.Position = UDim2.fromScale(0.5, 0.5)
		spokeLine.Rotation = s * 45
		spokeLine.BackgroundColor3 = UITheme.Colors.Outline
		spokeLine.BorderSizePixel = 0
		spokeLine.ZIndex = 34
		spokeLine.Parent = wheelLabelsLayer
	end

	for i, seg in GameConfig.WHEEL_SEGMENTS do
		local startDeg = (i - 1) * 45
		local centerDeg = startDeg + 22.5

		-- Half-plane A clips [startDeg .. startDeg + 180]
		local halfA = Instance.new("CanvasGroup")
		halfA.Name = `Slice_{i}`
		halfA.Size = UDim2.fromScale(1, 1)
		halfA.BackgroundTransparency = 1
		halfA.BorderSizePixel = 0
		halfA.ZIndex = 32
		local gradA = Instance.new("UIGradient")
		gradA.Rotation = startDeg
		gradA.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.498, 1),
			NumberSequenceKeypoint.new(0.502, 0),
			NumberSequenceKeypoint.new(1, 0),
		})
		gradA.Parent = halfA
		halfA.Parent = pieGroup

		-- Half-plane B clips [startDeg - 135 .. startDeg + 45], yielding exact 45-deg wedge
		local halfB = Instance.new("Frame")
		halfB.Size = UDim2.fromScale(1, 1)
		halfB.BackgroundColor3 = Color3.fromHex(seg.color)
		halfB.BorderSizePixel = 0
		halfB.ZIndex = 32
		local gradB = Instance.new("UIGradient")
		gradB.Rotation = startDeg + 45
		gradB.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.498, 0),
			NumberSequenceKeypoint.new(0.502, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradB.Parent = halfB
		halfB.Parent = halfA

		local studsImg, studsTint = getSliceStuds(seg.id, UITheme)
		local sliceStuds = Instance.new("ImageLabel")
		sliceStuds.Name = "SliceStuds"
		sliceStuds.Size = UDim2.fromScale(1.2, 1.2)
		sliceStuds.AnchorPoint = Vector2.new(0.5, 0.5)
		sliceStuds.Position = UDim2.fromScale(0.5, 0.5)
		sliceStuds.BackgroundTransparency = 1
		sliceStuds.Image = studsImg
		sliceStuds.ImageColor3 = studsTint
		sliceStuds.ImageTransparency = 0.76
		sliceStuds.ScaleType = Enum.ScaleType.Crop
		sliceStuds.ZIndex = 33
		sliceStuds.Parent = halfB

		local rad = math.rad(centerDeg)
		local iconX = 202 + math.sin(rad) * 148
		local iconY = 202 - math.cos(rad) * 148
		local pIcon = Instance.new("ImageLabel")
		pIcon.Name = `SliceIcon_{i}`
		pIcon.Size = UDim2.fromOffset(44, 44)
		pIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		pIcon.Position = UDim2.fromOffset(iconX, iconY)
		pIcon.Rotation = centerDeg
		pIcon.BackgroundTransparency = 1
		pIcon.Image = UITheme.Assets[seg.assetKey] or UITheme.Assets.Icon_CashCube
		pIcon.ScaleType = Enum.ScaleType.Fit
		pIcon.ZIndex = 35
		pIcon.Parent = wheelLabelsLayer

		local txtX = 202 + math.sin(rad) * 96
		local txtY = 202 - math.cos(rad) * 96
		local pTxt = makeStrokedLabel(
			wheelLabelsLayer,
			seg.label,
			UDim2.fromOffset(92, 42),
			UDim2.fromOffset(txtX, txtY),
			UITheme,
			2.5,
			4,
			15,
			35
		)
		pTxt.Name = `SliceText_{i}`
		pTxt.AnchorPoint = Vector2.new(0.5, 0.5)
		pTxt.Rotation = centerDeg
		pTxt.TextWrapped = false
	end

	local wheelRotVal = Instance.new("NumberValue")
	wheelRotVal.Changed:Connect(function(v: number)
		pieGroup.Rotation = v
		wheelLabelsLayer.Rotation = v
	end)

	-- Concentric Hub Cap matching Figma target hub
	local function makeHubCircle(name: string, px: number, hexColor: string, zIndex: number, strokeSize: number?)
		local c = Instance.new("Frame")
		c.Name = name
		c.Size = UDim2.fromOffset(px, px)
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Position = UDim2.fromScale(0.5, 0.5)
		c.BackgroundColor3 = Color3.fromHex(hexColor)
		c.BorderSizePixel = 0
		c.ZIndex = zIndex
		UITheme.addCorner(c, px * 0.5)
		if strokeSize then
			UITheme.applyStroke(c, strokeSize, UITheme.Colors.Outline)
		end
		c.Parent = wheelOuterRim
	end
	makeHubCircle("HubOuter", 72, "#111622", 36, 3.5)
	makeHubCircle("HubLight", 54, "#E2E8F0", 37, 3)
	makeHubCircle("HubInner", 32, "#64748B", 38, 2.5)
	makeHubCircle("HubCore", 14, "#111622", 39, nil)

	-- Top Red Pointer
	local pointerClip = Instance.new("Frame")
	pointerClip.Name = "WheelPointer"
	pointerClip.Size = UDim2.fromOffset(38, 26)
	pointerClip.AnchorPoint = Vector2.new(0.5, 0)
	pointerClip.Position = UDim2.new(0.5, 0, 0, -10)
	pointerClip.BackgroundTransparency = 1
	pointerClip.ClipsDescendants = true
	pointerClip.ZIndex = 40
	pointerClip.Parent = wheelOuterRim

	local pointerTopBar = Instance.new("Frame")
	pointerTopBar.Size = UDim2.new(1, -6, 0, 3)
	pointerTopBar.Position = UDim2.fromOffset(3, 0)
	pointerTopBar.BackgroundColor3 = UITheme.Colors.Outline
	pointerTopBar.BorderSizePixel = 0
	pointerTopBar.ZIndex = 41
	pointerTopBar.Parent = pointerClip

	local pointerDiamond = Instance.new("Frame")
	pointerDiamond.Size = UDim2.fromOffset(26, 26)
	pointerDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
	pointerDiamond.Position = UDim2.fromOffset(19, 2)
	pointerDiamond.Rotation = 45
	pointerDiamond.BackgroundColor3 = Color3.fromHex("#EF4444")
	pointerDiamond.BorderSizePixel = 0
	pointerDiamond.ZIndex = 40
	UITheme.applyStroke(pointerDiamond, 3, UITheme.Colors.Outline)
	pointerDiamond.Parent = pointerClip

	-- Bottom Controls (+5 SPINS, SPIN (N), +10 SPINS, prompt text)
	local p5 = (GameConfig.MONETIZATION.spin_5 and GameConfig.MONETIZATION.spin_5.robux) or 23
	local p10 = (GameConfig.MONETIZATION.spin_10 and GameConfig.MONETIZATION.spin_10.robux) or 36
	local pFirst = (GameConfig.MONETIZATION.spin_first_offer and GameConfig.MONETIZATION.spin_first_offer.robux) or 2

	makeSpinPackButton(wheelWindow, "BtnBuy5Spins", 420, 492, 116, 62, "magenta", "+5 SPINS", p5, UITheme, function()
		if playSfx then playSfx("click") end
		Remotes.MetaAction:FireServer("BuyShopItem", "spin_5")
	end)

	local btnDoSpin = Instance.new("TextButton")
	btnDoSpin.Name = "BtnDoSpinWheel"
	btnDoSpin.Size = UDim2.fromOffset(154, 50)
	btnDoSpin.Position = UDim2.fromOffset(548, 504)
	btnDoSpin.Text = ""
	btnDoSpin.ZIndex = 34
	UITheme.button(btnDoSpin, "lime", 10)
	UITheme.addPulse(btnDoSpin, 1.0, 1.04, 1.2)
	UITheme.addShineSweep(btnDoSpin, 3.0)
	btnDoSpin.Parent = wheelWindow

	local spinBtnLabel = makeStrokedLabel(
		btnDoSpin,
		"SPIN (0)",
		UDim2.new(0.92, 0, 0.8, 0),
		UDim2.new(0.04, 0, 0.1, 0),
		UITheme,
		3,
		14,
		22,
		btnDoSpin.ZIndex + 3
	)
	spinBtnLabel.Name = "BtnLabel"

	makeSpinPackButton(wheelWindow, "BtnBuy10Spins", 714, 492, 118, 62, "blue", "+10 SPINS", p10, UITheme, function()
		if playSfx then playSfx("click") end
		Remotes.MetaAction:FireServer("BuyShopItem", "spin_10")
	end)

	local promptLabel = makeStrokedLabel(
		wheelWindow,
		"USE YOUR FREE SPIN NOW!",
		UDim2.fromOffset(420, 28),
		UDim2.fromOffset(415, 574),
		UITheme,
		2.5,
		12,
		20,
		34
	)
	promptLabel.Name = "PromptLabel"

	-- Bottom-Right Promo Card: FIRST SPIN OF DAY! / 83% OFF! (stacked lines for zero truncation)
	local promoBtn = Instance.new("TextButton")
	promoBtn.Name = "FirstSpinPromo"
	promoBtn.Size = UDim2.fromOffset(188, 76)
	promoBtn.Position = UDim2.fromOffset(796, 402)
	promoBtn.BackgroundColor3 = Color3.fromHex("#19202E")
	promoBtn.BorderSizePixel = 0
	promoBtn.Text = ""
	promoBtn.AutoButtonColor = false
	promoBtn.ZIndex = 34
	UITheme.addCorner(promoBtn, 10)
	UITheme.applyStroke(promoBtn, 2.5, UITheme.Colors.Outline)
	UITheme.setupButtonHover(promoBtn)
	promoBtn.Parent = wheelWindow

	local promoTitle = makeStrokedLabel(
		promoBtn,
		"FIRST SPIN OF DAY!",
		UDim2.new(1, -12, 0, 20),
		UDim2.fromOffset(6, 5),
		UITheme,
		2,
		9,
		13,
		35
	)
	promoTitle.Name = "PromoTitle"

	local promoPct = makeStrokedLabel(
		promoBtn,
		"83% OFF!",
		UDim2.new(1, -12, 0, 18),
		UDim2.fromOffset(6, 24),
		UITheme,
		2,
		9,
		12,
		35
	)
	promoPct.Name = "PromoPct"

	local promoPill, promoPillTxt = makeRobuxPill(
		promoBtn,
		tostring(pFirst),
		UDim2.fromOffset(102, 24),
		UDim2.new(0.5, 0, 1, -6),
		Vector2.new(0.5, 1),
		UITheme,
		35
	)

	btnDoSpin.Activated:Connect(function()
		if wheelSpinning then
			return
		end
		if playSfx then playSfx("click") end
		Remotes.MetaAction:FireServer("SpinWheel")
	end)

	promoBtn.Activated:Connect(function()
		if playSfx then playSfx("click") end
		Remotes.MetaAction:FireServer("BuyShopItem", "spin_first_offer")
	end)

	local function close()
		if not wheelWindow.Visible then
			return
		end
		modalBackdrop.Visible = false
		UITheme.animateWindowClose(wheelWindow, wheelWindow, nil, getWheelScale())
	end

	btnClose.Activated:Connect(close)

	local function setSpinVariant(variant: string)
		if variant ~= lastSpinVariant then
			lastSpinVariant = variant
			UITheme.styleButton(btnDoSpin, variant, 10)
		end
	end

	local function update(profile: any, _now: number?)
		if not profile then
			return
		end
		lastProfile = profile
		cachedSpins = profile.WheelSpins or 0
		spinBtnLabel.Text = if wheelSpinning then "SPINNING..." else `SPIN ({cachedSpins})`
		setSpinVariant(if wheelSpinning then "gray" else "lime")

		promptLabel.Text = if wheelSpinning
			then "GOOD LUCK!"
			elseif cachedSpins > 0 then "USE YOUR FREE SPIN NOW!"
			else "GET MORE SPINS OR PLAY MATCHES!"

		local todayKey = math.floor(os.time() / 86400)
		local claimedOfferToday = (profile.LastFirstSpinOfferDay or 0) == todayKey
		if claimedOfferToday then
			promoPill.BackgroundColor3 = Color3.fromHex("#64748B")
			promoPillTxt.Text = "CLAIMED"
		else
			promoPill.BackgroundColor3 = Color3.fromHex("#48C90E")
			promoPillTxt.Text = tostring(pFirst)
		end
	end

	local function open()
		if lastProfile then
			update(lastProfile)
		end
		uiScale.Scale = getWheelScale()
		modalBackdrop.Visible = true
		UITheme.animateWindowOpen(wheelWindow, wheelWindow, getWheelScale())
	end

	local function isOpen(): boolean
		return wheelWindow.Visible
	end

	local function isSpinning(): boolean
		return wheelSpinning
	end

	local function playSpinAnimation(sliceIdx: number, onComplete: () -> ())
		local idx = math.clamp(sliceIdx, 1, #GameConfig.WHEEL_SEGMENTS)
		local centerDeg = (idx - 1) * 45 + 22.5
		local targetMod = (360 - centerDeg) % 360
		local delta = (targetMod - (wheelCurrentRot % 360)) % 360
		wheelCurrentRot = wheelCurrentRot + 1440 + delta

		spinAnimToken += 1
		local myToken = spinAnimToken
		wheelSpinning = true
		spinBtnLabel.Text = "SPINNING..."
		setSpinVariant("gray")
		if playSfx then playSfx("roll") end

		local tw = TweenService:Create(wheelRotVal, TweenInfo.new(2.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Value = wheelCurrentRot,
		})
		tw:Play()

		task.delay(2.25, function()
			if spinAnimToken == myToken then
				wheelSpinning = false
			end
			onComplete()
		end)
	end

	return {
		window = wheelWindow,
		open = open,
		close = close,
		isOpen = isOpen,
		isSpinning = isSpinning,
		update = update,
		playSpinAnimation = playSpinAnimation,
	}
end

return WheelUI

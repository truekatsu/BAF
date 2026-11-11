--!strict
--[[
	ShopDailyUI
	Responsibility: Modular UI builder & controller for Figma Shop UI (Node 20:2) and Daily Rewards UI (Node 25:2)
	Extracted from MatchClient to respect Roblox Studio Script.Source 200k character limits.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local ChairModelBuilder = require(ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("ChairModelBuilder"))
local DAILY_COOLDOWN_SEC = 86400

local function formatHHMMSS(sec: number): string
	local s = math.max(0, math.floor(sec))
	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	local remS = s % 60
	return string.format("%02d:%02d:%02d", h, m, remS)
end

local function formatMMSS(sec: number): string
	local s = math.max(0, math.floor(sec))
	local m = math.floor(s / 60)
	local remS = s % 60
	return string.format("%d:%02d", m, remS)
end

local ShopDailyUI = {}

export type FreeRewardsStatus = {
	readyDaily: boolean,
	readyGroup: boolean,
	readyPlaytime: number,
	readyTotal: number,
}

export type FreeRewardsHandler = {
	window: Frame,
	open: (tab: ("DAILY" | "GROUP" | "PLAYTIME")?) -> (),
	close: () -> (),
	isOpen: () -> boolean,
	setTab: (tab: "DAILY" | "GROUP" | "PLAYTIME") -> (),
	update: (profile: any, now: number) -> FreeRewardsStatus,
}

export type ShopHandler = {
	window: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	updateGamepasses: (profile: any) -> (),
}

export type DailyHandler = FreeRewardsHandler

export type SkinsHandler = {
	window: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	update: (profile: any) -> (),
}

export type TitlesHandler = {
	window: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	update: (profile: any) -> (),
}

export type QuestsHandler = {
	window: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	update: (profile: any) -> number,
}

export type ProfileHandler = {
	window: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	update: (p: any, elapsed: number?, disc: { [string]: boolean }?, discCount: number?, pct: number?) -> (),
	refreshRanks: () -> (),
}

export type CardIndexHandler = {
	window: Frame,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	update: (profile: any) -> (number, number),
}

function ShopDailyUI.initShop(screenGui: ScreenGui, modalBackdrop: GuiObject, Remotes: any, UITheme: any): ShopHandler
	local shopWindowData = UITheme.window({
		name = "ShopWindow",
		title = "SHOP",
		headerColors = UITheme.CONFIG.Headers.Shop,
		closeStyle = "magenta",
		headerHeightOffset = 46,
		size = UDim2.new(0, 460, 0.48, 0),
		parent = screenGui,
		onClose = function()
			modalBackdrop.Visible = false
		end,
	})
	local shopWindow = shopWindowData.Window
	local shopSizeConstraint = Instance.new("UISizeConstraint")
	shopSizeConstraint.MaxSize = Vector2.new(490, 390)
	shopSizeConstraint.MinSize = Vector2.new(360, 320)
	shopSizeConstraint.Parent = shopWindow
	shopWindow.ZIndex = 26
	shopWindow.Visible = false

	-- Solid dark background matching mockup
	shopWindow.BackgroundColor3 = Color3.fromRGB(13, 14, 21)
	shopWindow.BackgroundTransparency = 0
	shopWindowData.Body.BackgroundColor3 = Color3.fromRGB(13, 14, 21)
	shopWindowData.Body.BackgroundTransparency = 0

	-- Header Customization: Pink/Magenta Lego Studs + Bold White Text
	local header = shopWindowData.Header
	local titleLbl = shopWindowData.Title
	if titleLbl then
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.Text = "SHOP"
		titleLbl.TextSize = 26
		titleLbl.TextScaled = false
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Position = UDim2.new(0, 18, 0.5, 0)
		titleLbl.AnchorPoint = Vector2.new(0, 0.5)
		titleLbl.Size = UDim2.new(0.65, 0, 0.8, 0)
		titleLbl.BackgroundTransparency = 1
		local stroke = titleLbl:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", titleLbl)
		stroke.Thickness = 3.5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		local tConstraint = titleLbl:FindFirstChildOfClass("UITextSizeConstraint")
		if tConstraint then tConstraint:Destroy() end
	end
	local studs = header:FindFirstChild("Studs") :: ImageLabel?
	if studs then
		studs.Image = if UITheme.Assets.Header_Studs_Shop_Red and UITheme.Assets.Header_Studs_Shop_Red ~= "rbxassetid://0" then UITheme.Assets.Header_Studs_Shop_Red else "rbxassetid://128225868192722"
		studs.ImageTransparency = 0
		studs.ScaleType = Enum.ScaleType.Crop
		studs.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end

	local pageShop = Instance.new("ScrollingFrame")
	pageShop.Name = "Body"
	pageShop.Size = UDim2.fromScale(1, 1)
	pageShop.CanvasSize = UDim2.new(0, 0, 0, 860)
	pageShop.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pageShop.ScrollingDirection = Enum.ScrollingDirection.Y
	pageShop.ScrollBarThickness = 6
	pageShop.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	pageShop.TopImage = "rbxasset://textures/ui/Scroll/scroll-top.png"
	pageShop.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	pageShop.BottomImage = "rbxasset://textures/ui/Scroll/scroll-bottom.png"
	pageShop.ScrollBarImageColor3 = Color3.fromRGB(120, 130, 160)
	pageShop.ScrollBarImageTransparency = 0.2
	pageShop.BackgroundTransparency = 1
	pageShop.Visible = true
	pageShop.Parent = shopWindowData.Body

	local shopGamepassCards: { [string]: { SetOwned: (boolean) -> () } } = {}
	do
	local shopPad = Instance.new("UIPadding")
	shopPad.PaddingLeft = UDim.new(0, 8)
	shopPad.PaddingRight = UDim.new(0, 8)
	shopPad.PaddingTop = UDim.new(0, 6)
	shopPad.PaddingBottom = UDim.new(0, 16)
	shopPad.Parent = pageShop

	local shopList = Instance.new("UIListLayout")
	shopList.FillDirection = Enum.FillDirection.Vertical
	shopList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	shopList.SortOrder = Enum.SortOrder.LayoutOrder
	shopList.Padding = UDim.new(0, 10)
	shopList.Parent = pageShop

	local function makeSectionHeader(text: string, order: number): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Section_" .. string.gsub(text, "[^%w]", "")
		lbl.Size = UDim2.new(1, 0, 0, 28)
		lbl.BackgroundTransparency = 1
		lbl.Font = UITheme.CONFIG.Font
		lbl.Text = text
		lbl.TextColor3 = UITheme.CONFIG.Colors.White
		lbl.TextScaled = false
		lbl.TextSize = 18
		lbl.LayoutOrder = order
		UITheme.applyTextStroke(lbl, 3, UITheme.CONFIG.Colors.Outline)
		lbl.Parent = pageShop
		return lbl
	end

	-- SECTION 1: - PACKS & CHAIRS -
	makeSectionHeader("- PACKS & CHAIRS -", 1)

	-- 1a) STARTER PACK (Solid dark background, 2px gold border #D4AF37)
	local starterBanner = Instance.new("Frame")
	starterBanner.Name = "PackBanner_StarterPack"
	starterBanner.Size = UDim2.new(1, 0, 0, 126)
	starterBanner.BackgroundColor3 = Color3.fromRGB(13, 14, 21)
	starterBanner.BackgroundTransparency = 0
	starterBanner.BorderSizePixel = 0
	starterBanner.LayoutOrder = 2
	UITheme.addCorner(starterBanner, UITheme.CONFIG.CARD_CORNER_RADIUS)
	UITheme.applyStroke(starterBanner, 2, Color3.fromHex("#D4AF37"))
	UITheme.attachCardHover(starterBanner, 1.03)
	starterBanner.Parent = pageShop

	local starterTitle = Instance.new("TextLabel")
	starterTitle.Name = "Title"
	starterTitle.Size = UDim2.fromScale(0.55, 0.22)
	starterTitle.Position = UDim2.fromScale(0.04, 0.08)
	starterTitle.BackgroundTransparency = 1
	starterTitle.Font = UITheme.CONFIG.Font
	starterTitle.Text = "STARTERPACK"
	starterTitle.TextScaled = false
	starterTitle.TextSize = 18
	starterTitle.TextXAlignment = Enum.TextXAlignment.Left
	starterTitle.ZIndex = starterBanner.ZIndex + 3
	UITheme.rainbowText(starterTitle)
	UITheme.applyTextStroke(starterTitle, 3, UITheme.CONFIG.Colors.Outline)
	starterTitle.Parent = starterBanner

	-- Left item row: 2 slots (500 BUX + CRIMSON CHAIR) centered with "+" between them
	local itemsRow = Instance.new("Frame")
	itemsRow.Name = "ItemsRow"
	itemsRow.Size = UDim2.fromScale(0.66, 0.72)
	itemsRow.Position = UDim2.fromScale(0.02, 0.26)
	itemsRow.BackgroundTransparency = 1
	itemsRow.ZIndex = starterBanner.ZIndex + 2
	itemsRow.Parent = starterBanner

	local itemsList = Instance.new("UIListLayout")
	itemsList.FillDirection = Enum.FillDirection.Horizontal
	itemsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	itemsList.VerticalAlignment = Enum.VerticalAlignment.Center
	itemsList.Padding = UDim.new(0.04, 0)
	itemsList.SortOrder = Enum.SortOrder.LayoutOrder
	itemsList.Parent = itemsRow

	-- Slot 1: 500 BUX + green sunburst
	local slotCash = Instance.new("Frame")
	slotCash.Name = "Slot_500Bux"
	slotCash.Size = UDim2.fromScale(0.38, 1)
	slotCash.BackgroundTransparency = 1
	slotCash.LayoutOrder = 1
	slotCash.Parent = itemsRow

	local sbCash = UITheme.sunburst(slotCash, Color3.fromHex("#68FF3B"), 0.15, 12)
	sbCash.Size = UDim2.fromScale(0.80, 0.80)

	local iconCashCube = Instance.new("ImageLabel")
	iconCashCube.Name = "Icon_CashCube"
	iconCashCube.Size = UDim2.fromScale(0.72, 0.58)
	iconCashCube.Position = UDim2.fromScale(0.5, 0.38)
	iconCashCube.AnchorPoint = Vector2.new(0.5, 0.5)
	iconCashCube.BackgroundTransparency = 1
	iconCashCube.Image = if UITheme.Assets.Icon_CashCube ~= "rbxassetid://0" then UITheme.Assets.Icon_CashCube else UITheme.Assets.CashStack
	iconCashCube.ScaleType = Enum.ScaleType.Fit
	iconCashCube.ZIndex = starterBanner.ZIndex + 3
	iconCashCube.Parent = slotCash

	local lbl500Bux = Instance.new("TextLabel")
	lbl500Bux.Name = "CashLabel"
	lbl500Bux.Size = UDim2.fromScale(1, 0.28)
	lbl500Bux.Position = UDim2.fromScale(0, 0.72)
	lbl500Bux.BackgroundTransparency = 1
	lbl500Bux.Font = UITheme.CONFIG.Font
	lbl500Bux.Text = "500 BUX"
	lbl500Bux.TextColor3 = UITheme.CONFIG.Colors.MoneyLime
	lbl500Bux.TextScaled = false
	lbl500Bux.TextSize = 13
	lbl500Bux.ZIndex = starterBanner.ZIndex + 4
	UITheme.applyTextStroke(lbl500Bux, 2.5, UITheme.CONFIG.Colors.Outline)
	lbl500Bux.Parent = slotCash

	-- White "+" separator
	local plusLbl = Instance.new("TextLabel")
	plusLbl.Name = "PlusSeparator"
	plusLbl.Size = UDim2.fromScale(0.10, 0.35)
	plusLbl.BackgroundTransparency = 1
	plusLbl.Font = UITheme.CONFIG.Font
	plusLbl.Text = "+"
	plusLbl.TextColor3 = UITheme.CONFIG.Colors.White
	plusLbl.TextScaled = false
	plusLbl.TextSize = 20
	plusLbl.LayoutOrder = 2
	plusLbl.ZIndex = starterBanner.ZIndex + 4
	UITheme.applyTextStroke(plusLbl, 3, UITheme.CONFIG.Colors.Outline)
	plusLbl.Parent = itemsRow

	-- Slot 2: Crimson Chair + red sunburst
	local slotChair = Instance.new("Frame")
	slotChair.Name = "Slot_CrimsonChair"
	slotChair.Size = UDim2.fromScale(0.40, 1)
	slotChair.BackgroundTransparency = 1
	slotChair.LayoutOrder = 3
	slotChair.Parent = itemsRow

	local sbChair = UITheme.sunburst(slotChair, Color3.fromHex("#FF3B30"), 0.15, 12)
	sbChair.Size = UDim2.fromScale(0.80, 0.80)

	local iconCrimsonChair = Instance.new("ImageLabel")
	iconCrimsonChair.Name = "Icon_Chair_CrimsonStriker"
	iconCrimsonChair.Size = UDim2.fromScale(0.72, 0.58)
	iconCrimsonChair.Position = UDim2.fromScale(0.5, 0.38)
	iconCrimsonChair.AnchorPoint = Vector2.new(0.5, 0.5)
	iconCrimsonChair.BackgroundTransparency = 1
	iconCrimsonChair.Image = if UITheme.Assets.Icon_Chair_CrimsonStriker ~= "rbxassetid://0" then UITheme.Assets.Icon_Chair_CrimsonStriker else "rbxassetid://102760649316701"
	iconCrimsonChair.ScaleType = Enum.ScaleType.Fit
	iconCrimsonChair.ZIndex = starterBanner.ZIndex + 3
	iconCrimsonChair.Parent = slotChair

	local lblCrimsonChair = Instance.new("TextLabel")
	lblCrimsonChair.Name = "ChairLabel"
	lblCrimsonChair.Size = UDim2.fromScale(1, 0.28)
	lblCrimsonChair.Position = UDim2.fromScale(0, 0.72)
	lblCrimsonChair.BackgroundTransparency = 1
	lblCrimsonChair.Font = UITheme.CONFIG.Font
	lblCrimsonChair.Text = "CRIMSON CHAIR"
	lblCrimsonChair.TextColor3 = UITheme.CONFIG.Colors.White
	lblCrimsonChair.TextScaled = false
	lblCrimsonChair.TextSize = 10
	lblCrimsonChair.ZIndex = starterBanner.ZIndex + 4
	UITheme.applyTextStroke(lblCrimsonChair, 2, UITheme.CONFIG.Colors.Outline)
	lblCrimsonChair.Parent = slotChair

	-- Strikethrough Value Tag: "140 VALUE" in gold-yellow with strike line, slight tilt
	local valueTag = Instance.new("TextLabel")
	valueTag.Name = "ValueTag"
	valueTag.Size = UDim2.new(0, 90, 0, 20)
	valueTag.Position = UDim2.fromScale(0.85, 0.44)
	valueTag.AnchorPoint = Vector2.new(0.5, 0.5)
	valueTag.Rotation = -8
	valueTag.BackgroundTransparency = 1
	valueTag.Font = UITheme.CONFIG.Font
	valueTag.Text = "140 VALUE"
	valueTag.TextColor3 = Color3.fromHex("#FFD21F")
	valueTag.TextSize = 13
	valueTag.ZIndex = starterBanner.ZIndex + 4
	UITheme.applyTextStroke(valueTag, 2.5, UITheme.Colors.Black)
	valueTag.Parent = starterBanner

	local strikeLine = Instance.new("Frame")
	strikeLine.Name = "StrikeLine"
	strikeLine.Size = UDim2.new(1.05, 0, 0, 2)
	strikeLine.Position = UDim2.fromScale(0.5, 0.5)
	strikeLine.AnchorPoint = Vector2.new(0.5, 0.5)
	strikeLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	strikeLine.BorderSizePixel = 0
	strikeLine.ZIndex = valueTag.ZIndex + 1
	strikeLine.Parent = valueTag

	-- Right: lime price button at bottom-right
	local btnBuyStarter = UITheme.priceButton(
		starterBanner,
		4,
		UDim2.new(0, 84, 0, 30),
		UDim2.fromScale(0.97, 0.88)
	)
	btnBuyStarter.AnchorPoint = Vector2.new(1, 1)
	btnBuyStarter.ZIndex = starterBanner.ZIndex + 4
	btnBuyStarter.Activated:Connect(function()
		Remotes.MetaAction:FireServer("BuyShopItem", "starter_pack")
	end)

	-- SECTION 2: - GAMEPASSES - (2-column grid)
	makeSectionHeader("- GAMEPASSES -", 4)

	local gpGridWrap = Instance.new("Frame")
	gpGridWrap.Name = "GamepassesGrid"
	gpGridWrap.Size = UDim2.new(1, 0, 0, 364)
	gpGridWrap.BackgroundTransparency = 1
	gpGridWrap.LayoutOrder = 5
	gpGridWrap.Parent = pageShop

	local gpGrid = Instance.new("UIGridLayout")
	gpGrid.CellSize = UDim2.new(0.5, -4, 0, 116)
	gpGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	gpGrid.SortOrder = Enum.SortOrder.LayoutOrder
	gpGrid.Parent = gpGridWrap

	local shopPasses = {
		{ id = "vip", name = "VIP", desc = "GOLDEN CHAIR\n+ 2X BUX", iconName = "Icon_Crown", sunburstColor = Color3.fromHex("#FFD21F"), asset = if UITheme.Assets.Icon_Crown ~= "rbxassetid://0" then UITheme.Assets.Icon_Crown else UITheme.Assets.VipIcon, price = 19 },
		{ id = "2x_bux", name = "2X BUX", desc = "DOUBLE BUX\nFROM GAMES", iconName = "Icon_CashCube", sunburstColor = Color3.fromHex("#68FF3B"), asset = if UITheme.Assets.Icon_CashCube ~= "rbxassetid://0" then UITheme.Assets.Icon_CashCube else UITheme.Assets.CashStack, price = 30 },
		{ id = "2x_wins", name = "2X WIN", desc = "DOUBLE\nWINS", iconName = "Icon_Trophy", sunburstColor = Color3.fromHex("#FFAE19"), asset = if UITheme.Assets.Icon_Trophy ~= "rbxassetid://0" then UITheme.Assets.Icon_Trophy else UITheme.Assets.TrophyIcon, price = 30 },
		{ id = "2x_streak", name = "2X STREAK", desc = "DOUBLE WIN\nSTREAK", iconName = "Icon_Flame", sunburstColor = Color3.fromHex("#FF4D2A"), asset = if UITheme.Assets.Icon_Flame ~= "rbxassetid://0" then UITheme.Assets.Icon_Flame else UITheme.Assets.FlameIcon, price = 30 },
		{ id = "2x_luck", name = "2X LUCK", desc = "2X LEGENDARY\nPLAYER LUCK", iconName = "Icon_Luck", sunburstColor = Color3.fromHex("#2EFF9E"), asset = if UITheme.Assets.Icon_Luck ~= "rbxassetid://0" then UITheme.Assets.Icon_Luck else UITheme.Assets.LuckIcon, price = 45 },
		{ id = "inf_rerolls", name = "INFINITY REROLLS", desc = "INFINITY FREE\nREROLLS", iconName = "Icon_InfRerolls", sunburstColor = Color3.fromHex("#52B4FF"), asset = if UITheme.Assets.Icon_InfRerolls ~= "rbxassetid://0" then UITheme.Assets.Icon_InfRerolls else UITheme.Assets.DiceIcon, price = 72 },
	}
	for idx, gp in shopPasses do
		local gpEntry = UITheme.gamepassCard({
			id = gp.id,
			name = gp.name,
			description = gp.desc,
			icon = gp.asset,
			iconName = gp.iconName,
			sunburstColor = gp.sunburstColor,
			price = gp.price,
			layoutOrder = idx,
			parent = gpGridWrap,
			onBuy = function()
				Remotes.MetaAction:FireServer("BuyShopItem", gp.id)
			end,
		})
		shopGamepassCards[gp.id] = gpEntry
	end

	-- SECTION 3: - BUXS - (2-column grid)
	makeSectionHeader("- BUXS -", 6)

	local buxGridWrap = Instance.new("Frame")
	buxGridWrap.Name = "BuxsGrid"
	buxGridWrap.Size = UDim2.new(1, 0, 0, 240)
	buxGridWrap.BackgroundTransparency = 1
	buxGridWrap.LayoutOrder = 7
	buxGridWrap.Parent = pageShop

	local buxGrid = Instance.new("UIGridLayout")
	buxGrid.CellSize = UDim2.new(0.5, -4, 0, 116)
	buxGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	buxGrid.SortOrder = Enum.SortOrder.LayoutOrder
	buxGrid.Parent = buxGridWrap

	local buxPacks = {
		{ id = "bux_300", name = "300 BUX", tag = nil, price = 20, icon = if UITheme.Assets.Icon_Bux300 and UITheme.Assets.Icon_Bux300 ~= "rbxassetid://0" then UITheme.Assets.Icon_Bux300 else UITheme.Assets.Icon_CashCube },
		{ id = "bux_1000", name = "1000 BUX", tag = nil, price = 35, icon = if UITheme.Assets.Icon_Bux1000 and UITheme.Assets.Icon_Bux1000 ~= "rbxassetid://0" then UITheme.Assets.Icon_Bux1000 else UITheme.Assets.Icon_CashCube },
		{ id = "bux_4000", name = "4000 BUX", tag = "MOST\nPOPULAR!", price = 99, icon = if UITheme.Assets.Icon_Bux4000 and UITheme.Assets.Icon_Bux4000 ~= "rbxassetid://0" then UITheme.Assets.Icon_Bux4000 else UITheme.Assets.Icon_CashCube },
		{ id = "bux_15000", name = "15000 BUX", tag = "BEST\nDEAL!", price = 249, icon = if UITheme.Assets.Icon_Bux15000 and UITheme.Assets.Icon_Bux15000 ~= "rbxassetid://0" then UITheme.Assets.Icon_Bux15000 else UITheme.Assets.Icon_CashCube },
	}
	for idx, bp in buxPacks do
		local card = Instance.new("Frame")
		card.Name = "BuxCard_" .. bp.id
		card.BackgroundColor3 = Color3.fromHex("#288832")
		card.BackgroundTransparency = 0
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.LayoutOrder = idx
		UITheme.addCorner(card, UITheme.CONFIG.CARD_CORNER_RADIUS)
		UITheme.applyStroke(card, 2, Color3.fromHex("#175C20"))
		card.Parent = buxGridWrap

		local sbWrap = Instance.new("Frame")
		sbWrap.Name = "SunburstWrap"
		sbWrap.Size = UDim2.fromScale(0.50, 0.85)
		sbWrap.Position = UDim2.fromScale(0.25, 0.56)
		sbWrap.AnchorPoint = Vector2.new(0.5, 0.5)
		sbWrap.BackgroundTransparency = 1
		sbWrap.ZIndex = card.ZIndex + 1
		sbWrap.Parent = card
		UITheme.sunburst(sbWrap, Color3.fromHex("#69D945"), 0.20)
		UITheme.attachCardHover(card, 1.04)

		local iconImg = Instance.new("ImageLabel")
		iconImg.Name = "BuxIcon"
		iconImg.Size = UDim2.fromScale(0.46, 0.64)
		iconImg.Position = UDim2.fromScale(0.25, 0.58)
		iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = bp.icon
		iconImg.ScaleType = Enum.ScaleType.Fit
		iconImg.ZIndex = card.ZIndex + 2
		iconImg.Parent = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "Title"
		nameLbl.Size = UDim2.fromScale(0.54, 0.22)
		nameLbl.Position = UDim2.fromScale(0.04, 0.06)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = UITheme.CONFIG.Font
		nameLbl.Text = bp.name
		nameLbl.TextColor3 = UITheme.CONFIG.Colors.MoneyLime
		nameLbl.TextScaled = false
		nameLbl.TextSize = 14
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.ZIndex = card.ZIndex + 4
		UITheme.applyTextStroke(nameLbl, 2.5, UITheme.CONFIG.Colors.Outline)
		nameLbl.Parent = card

		if bp.tag then
			local tagLbl = Instance.new("TextLabel")
			tagLbl.Name = "RibbonTag"
			tagLbl.Size = UDim2.fromScale(0.38, 0.28)
			tagLbl.Position = UDim2.fromScale(0.78, 0.20)
			tagLbl.AnchorPoint = Vector2.new(0.5, 0.5)
			tagLbl.Rotation = -12
			tagLbl.BackgroundTransparency = 1
			tagLbl.Font = UITheme.CONFIG.Font
			tagLbl.Text = bp.tag
			tagLbl.TextScaled = false
			tagLbl.TextSize = 11
			tagLbl.TextWrapped = true
			tagLbl.ZIndex = card.ZIndex + 4
			UITheme.rainbowText(tagLbl)
			UITheme.applyTextStroke(tagLbl, 2.5, UITheme.CONFIG.Colors.Outline)
			tagLbl.Parent = card
		end

		local priceBtn = UITheme.priceButton(
			card,
			bp.price,
			UDim2.new(0, 72, 0, 28),
			UDim2.new(1, -6, 1, -8)
		)
		priceBtn.AnchorPoint = Vector2.new(1, 1)
		priceBtn.ZIndex = card.ZIndex + 4
		priceBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyShopItem", bp.id)
		end)
	end

	local function updateGamepasses(p: any)
		if not p then return end
		if shopGamepassCards["vip"] then
			shopGamepassCards["vip"].SetOwned(p.DoubleBux == true and p.OwnedChairs ~= nil and p.OwnedChairs["golden"] == true)
		end
		if shopGamepassCards["2x_bux"] then
			shopGamepassCards["2x_bux"].SetOwned(p.DoubleBux == true)
		end
		if shopGamepassCards["2x_wins"] then
			shopGamepassCards["2x_wins"].SetOwned(p.DoubleWins == true)
		end
		if shopGamepassCards["2x_streak"] then
			shopGamepassCards["2x_streak"].SetOwned(p.DoubleStreak == true)
		end
		if shopGamepassCards["2x_luck"] then
			shopGamepassCards["2x_luck"].SetOwned(p.DoubleLuck == true)
		end
		if shopGamepassCards["inf_rerolls"] then
			shopGamepassCards["inf_rerolls"].SetOwned(p.InfRerolls == true)
		end
	end

	return {
		window = shopWindow,
		open = function()
			modalBackdrop.Visible = true
			UITheme.openWindow(shopWindow)
		end,
		close = function()
			modalBackdrop.Visible = false
			UITheme.closeWindow(shopWindow)
		end,
		isOpen = function()
			return shopWindow.Visible
		end,
		updateGamepasses = updateGamepasses,
	}
end
end

local CHAIR_DATA: { [string]: { name: string, color: Color3, legColor: Color3, mat: Enum.Material } } = {
	wood = { name = "Classic Wood", color = Color3.fromRGB(124, 71, 40), legColor = Color3.fromRGB(75, 42, 24), mat = Enum.Material.WoodPlanks },
	stadium = { name = "Stadium Blue", color = Color3.fromRGB(30, 111, 255), legColor = Color3.fromRGB(15, 60, 150), mat = Enum.Material.SmoothPlastic },
	cyber_core = { name = "Cyber Core Chair", color = Color3.fromRGB(18, 20, 32), legColor = Color3.fromRGB(18, 20, 32), mat = Enum.Material.Metal },
	crimson = { name = "Crimson Chair", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },
	emerald = { name = "Crimson Chair", color = Color3.fromRGB(150, 15, 25), legColor = Color3.fromRGB(110, 10, 20), mat = Enum.Material.WoodPlanks },
	frostbite = { name = "Frostbite Chair", color = Color3.fromRGB(120, 210, 255), legColor = Color3.fromRGB(60, 150, 230), mat = Enum.Material.Glass },
	cyber = { name = "Frostbite Chair", color = Color3.fromRGB(120, 210, 255), legColor = Color3.fromRGB(60, 150, 230), mat = Enum.Material.Glass },
	golden = { name = "Football Throne", color = Color3.fromRGB(255, 195, 30), legColor = Color3.fromRGB(205, 140, 10), mat = Enum.Material.SmoothPlastic },
	football_throne = { name = "Football Throne", color = Color3.fromRGB(255, 195, 30), legColor = Color3.fromRGB(205, 140, 10), mat = Enum.Material.SmoothPlastic },
}

local function buildChairModel(skinId: string): Model
	return ChairModelBuilder.buildChair(skinId)
end

local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = "ChairVP_" .. skinId
	vp.Size = UDim2.new(0.92, 0, 0.54, 0)
	vp.Position = UDim2.new(0.04, 0, 0.17, 0)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.ZIndex = parent.ZIndex + 2
	vp.Active = true
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.Ambient = Color3.fromRGB(240, 240, 245)
	vp.LightDirection = Vector3.new(-0.2, -0.4, -0.9)

	local model = ChairModelBuilder.buildChair(skinId)
	model.Parent = vp
	model.PrimaryPart = nil

	-- Exact bounding box center as pivot
	local bbCF, bbSize = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(bbCF.Position)
	local maxDim = math.max(bbSize.X, bbSize.Y, bbSize.Z)

	-- Default orientation: golden throne FBX has inverted forward, others face +Z
	local baseAngle = if skinId == "golden" or skinId == "royal" or skinId == "football_throne" or skinId == "footballthrone" or skinId == "royalfootballthrone" then math.pi else 0

	local cam = Instance.new("Camera")
	cam.FieldOfView = 24
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.35
	local camDir = Vector3.new(0.55, 0.32, 1.25).Unit
	cam.CFrame = CFrame.lookAt(camDir * dist, Vector3.new(0, 0, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam

	-- Interactive turntable rotation (cursor drag + hold, mobile touch drag + hold)
	local angle = 0
	local isHeld = false
	local isHovered = false
	local lastDragX: number? = nil

	local function updateModelCFrame()
		model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, baseAngle + angle, 0))
	end
	updateModelCFrame()

	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = true
			lastDragX = input.Position.X
		end
	end)

	vp.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = false
			lastDragX = nil
		end
	end)

	vp.InputChanged:Connect(function(input)
		if isHeld and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if lastDragX then
				local deltaX = input.Position.X - lastDragX
				angle += deltaX * 0.018
				lastDragX = input.Position.X
				updateModelCFrame()
			end
		end
	end)

	vp.MouseEnter:Connect(function()
		isHovered = true
	end)

	vp.MouseLeave:Connect(function()
		isHovered = false
	end)

	local globalEndConn: RBXScriptConnection?
	globalEndConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = false
			lastDragX = nil
		end
	end)

	local stepConn: RBXScriptConnection?
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if not vp:IsDescendantOf(game) then return end
		if isHeld then
			angle += 2.2 * dt
			updateModelCFrame()
		elseif isHovered then
			angle += 0.9 * dt
			updateModelCFrame()
		end
	end)

	vp.Destroying:Connect(function()
		if stepConn then
			stepConn:Disconnect()
			stepConn = nil
		end
		if globalEndConn then
			globalEndConn:Disconnect()
			globalEndConn = nil
		end
	end)

	vp.Parent = parent
	return vp
end

local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame
	if skinId then
		local vp = createChairViewport(skinId, parent)
		vp.Size = UDim2.fromScale(0.88, 0.76)
		vp.Position = UDim2.fromScale(0.5, 0.5)
		vp.AnchorPoint = Vector2.new(0.5, 0.5)
		return vp
	end
	local vp = Instance.new("ViewportFrame")
	vp.Name = "MiniChairVP"
	vp.Size = UDim2.fromScale(0.88, 0.76)
	vp.Position = UDim2.fromScale(0.5, 0.5)
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.ZIndex = parent.ZIndex + 2
	vp.Parent = parent

	local cam = Instance.new("Camera")
	cam.FieldOfView = 24
	cam.CFrame = CFrame.new(Vector3.new(2.8, 2.3, 3.2), Vector3.new(0, 0.75, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.Ambient = Color3.fromRGB(240, 240, 250)
	vp.LightDirection = Vector3.new(-0.35, -0.60, 0.72)

	local chairModel = Instance.new("Model")
	chairModel.Name = "MiniChair"

	local seat = Instance.new("Part")
	seat.Name = "Seat"
	seat.Size = Vector3.new(1.4, 0.2, 1.4)
	seat.CFrame = CFrame.new(0, 0.8, 0)
	seat.Color = chairColor
	seat.Material = mat
	seat.Anchored = true
	seat.Parent = chairModel

	local back = Instance.new("Part")
	back.Name = "Back"
	back.Size = Vector3.new(1.4, 1.3, 0.2)
	back.CFrame = CFrame.new(0, 1.5, -0.6)
	back.Color = chairColor
	back.Material = mat
	back.Anchored = true
	back.Parent = chairModel

	for _, lx in { -0.55, 0.55 } do
		for _, lz in { -0.55, 0.55 } do
			local leg = Instance.new("Part")
			leg.Name = "Leg"
			leg.Size = Vector3.new(0.18, 0.8, 0.18)
			leg.CFrame = CFrame.new(lx, 0.4, lz)
			leg.Color = chairColor
			leg.Material = mat
			leg.Anchored = true
			leg.Parent = chairModel
		end
	end
	chairModel.Parent = vp
	return vp
end

function ShopDailyUI.initFreeRewards(
	screenGui: ScreenGui,
	modalBackdrop: GuiObject,
	Remotes: any,
	UITheme: any,
	GameConfig: any
): FreeRewardsHandler
	local function getAsset(id: string?, fallback: string): string
		if not id or id == "" or id == "rbxassetid://0" then
			return fallback
		end
		return id
	end

	local freeRewardsWindowData = UITheme.window({
		name = "FreeRewardsWindow",
		title = "DAILY REWARDS",
		headerColors = UITheme.CONFIG.Headers.Daily,
		closeStyle = "magenta",
		headerHeightOffset = 50,
		size = UDim2.new(0, 680, 0, 460),
		parent = screenGui,
		onClose = function()
			modalBackdrop.Visible = false
		end,
	})
	local freeRewardsWindow = freeRewardsWindowData.Window
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(720, 500)
	sizeConstraint.MinSize = Vector2.new(520, 380)
	sizeConstraint.Parent = freeRewardsWindow
	freeRewardsWindow.ZIndex = 26
	freeRewardsWindow.Visible = false

	-- Header Customization: Orange Lego Studs + Bold White Text
	local header = freeRewardsWindowData.Header
	local titleLbl = freeRewardsWindowData.Title
	if titleLbl then
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.Text = "DAILY REWARDS"
		titleLbl.TextSize = 24
		titleLbl.TextScaled = false
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Position = UDim2.new(0, 18, 0.5, 0)
		titleLbl.AnchorPoint = Vector2.new(0, 0.5)
		titleLbl.Size = UDim2.new(0.65, 0, 0.8, 0)
		titleLbl.BackgroundTransparency = 1
		local stroke = titleLbl:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", titleLbl)
		stroke.Thickness = 3.5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		local tConstraint = titleLbl:FindFirstChildOfClass("UITextSizeConstraint")
		if tConstraint then tConstraint:Destroy() end
	end
	local studs = header:FindFirstChild("Studs") :: ImageLabel?
	if studs then
		studs.Image = getAsset(UITheme.Assets.Header_Studs_Daily_Orange, "rbxassetid://91925564826237")
		studs.ImageTransparency = 0
		studs.ScaleType = Enum.ScaleType.Crop
		studs.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end

	local body = freeRewardsWindowData.Body

	-- Container for Tab Pages (Daily, Group, Playtime)
	local pagesWrap = Instance.new("Frame")
	pagesWrap.Name = "PagesWrap"
	pagesWrap.Size = UDim2.new(1, 0, 1, -56)
	pagesWrap.Position = UDim2.new(0, 0, 0, 0)
	pagesWrap.BackgroundTransparency = 1
	pagesWrap.ZIndex = 27
	pagesWrap.Parent = body

	local pageDaily = Instance.new("Frame")
	pageDaily.Name = "PageDaily"
	pageDaily.Size = UDim2.fromScale(1, 1)
	pageDaily.BackgroundTransparency = 1
	pageDaily.ZIndex = 27
	pageDaily.Parent = pagesWrap

	local pageGroup = Instance.new("Frame")
	pageGroup.Name = "PageGroup"
	pageGroup.Size = UDim2.fromScale(1, 1)
	pageGroup.BackgroundTransparency = 1
	pageGroup.Visible = false
	pageGroup.ZIndex = 27
	pageGroup.Parent = pagesWrap

	local pagePlaytime = Instance.new("Frame")
	pagePlaytime.Name = "PagePlaytime"
	pagePlaytime.Size = UDim2.fromScale(1, 1)
	pagePlaytime.BackgroundTransparency = 1
	pagePlaytime.Visible = false
	pagePlaytime.ZIndex = 27
	pagePlaytime.Parent = pagesWrap

	-- ============================================================
	-- BOTTOM TABS BAR (DAILY, GROUP, PLAYTIME)
	-- ============================================================
	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "TabsBar"
	tabsBar.Size = UDim2.new(0, 540, 0, 44)
	tabsBar.Position = UDim2.new(0.5, 0, 1, -8)
	tabsBar.AnchorPoint = Vector2.new(0.5, 1)
	tabsBar.BackgroundTransparency = 1
	tabsBar.ZIndex = 28
	tabsBar.Parent = body

	local function createTabBtn(name: string, text: string, pos: UDim2, size: UDim2)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Position = pos
		btn.Size = size
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		UITheme.addCorner(btn, 8)
		UITheme.applyStroke(btn, 2.5, Color3.fromRGB(0, 0, 0))
		btn.ZIndex = tabsBar.ZIndex + 1
		btn.Parent = tabsBar

		local lbl = Instance.new("TextLabel")
		lbl.Name = "BtnLabel"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.Text = text
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.TextSize = 16
		lbl.ZIndex = btn.ZIndex + 2
		UITheme.applyTextStroke(lbl, 2.5, Color3.fromRGB(0, 0, 0))
		lbl.Parent = btn

		return btn, lbl
	end

	local btnTabDaily, lblTabDaily = createTabBtn("BtnTabDaily", "📅 DAILY", UDim2.new(0, 0, 0, 0), UDim2.new(0.31, 0, 1, 0))
	local btnTabGroup, lblTabGroup = createTabBtn("BtnTabGroup", "👥 GROUP", UDim2.new(0.345, 0, 0, 0), UDim2.new(0.31, 0, 1, 0))
	local btnTabPlaytime, lblTabPlaytime = createTabBtn("BtnTabPlaytime", "⏰ PLAYTIME", UDim2.new(0.69, 0, 0, 0), UDim2.new(0.31, 0, 1, 0))

	local function createBadge(parent: GuiObject): TextLabel
		local b = Instance.new("TextLabel")
		b.Name = "TabBadge"
		b.Size = UDim2.fromOffset(20, 20)
		b.Position = UDim2.new(1, -6, 0, -4)
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.BackgroundColor3 = Color3.fromHex("#E02424")
		b.BackgroundTransparency = 0
		b.Font = Enum.Font.FredokaOne
		b.Text = "1"
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.TextSize = 12
		b.Visible = false
		b.ZIndex = parent.ZIndex + 5
		UITheme.addCorner(b, 10)
		UITheme.applyStroke(b, 2, Color3.fromRGB(0, 0, 0))
		b.Parent = parent
		return b
	end

	local badgeDaily = createBadge(btnTabDaily)
	local badgeGroup = createBadge(btnTabGroup)
	local badgePlaytime = createBadge(btnTabPlaytime)

	local function styleTabButton(btn: TextButton, lbl: TextLabel, isActive: boolean)
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		if isActive then
			UITheme.applyGradient(btn, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			UITheme.applyButtonStuds(btn, "lime")
		else
			UITheme.applyGradient(btn, Color3.fromHex("#222838"), Color3.fromHex("#161A26"), 90)
			lbl.TextColor3 = Color3.fromHex("#94A3B8")
			UITheme.applyButtonStuds(btn, "tabInactive")
		end
	end

	local function setTab(tab: "DAILY" | "GROUP" | "PLAYTIME")
		pageDaily.Visible = (tab == "DAILY")
		pageGroup.Visible = (tab == "GROUP")
		pagePlaytime.Visible = (tab == "PLAYTIME")

		styleTabButton(btnTabDaily, lblTabDaily, tab == "DAILY")
		styleTabButton(btnTabGroup, lblTabGroup, tab == "GROUP")
		styleTabButton(btnTabPlaytime, lblTabPlaytime, tab == "PLAYTIME")

		if studs then
			if tab == "DAILY" then
				studs.Image = getAsset(UITheme.Assets.Header_Studs_Daily_Orange, "rbxassetid://91925564826237")
			elseif tab == "GROUP" then
				studs.Image = getAsset(UITheme.Assets.Header_Studs_Group_Gold, "rbxassetid://129278235187133")
			elseif tab == "PLAYTIME" then
				studs.Image = getAsset(UITheme.Assets.Header_Studs_Playtime_Blue, "rbxassetid://73760157351730")
			end
		end

		if titleLbl then
			if tab == "DAILY" then
				titleLbl.Text = "DAILY REWARDS"
			elseif tab == "GROUP" then
				titleLbl.Text = "GROUP REWARD"
			elseif tab == "PLAYTIME" then
				titleLbl.Text = "PLAYTIME REWARDS"
			end
		end
	end

	btnTabDaily.Activated:Connect(function() setTab("DAILY") end)
	btnTabGroup.Activated:Connect(function() setTab("GROUP") end)
	btnTabPlaytime.Activated:Connect(function() setTab("PLAYTIME") end)
	setTab("DAILY")

	-- ============================================================
	-- PAGE 1: DAILY REWARDS
	-- ============================================================
	local dailyCardFrames: { Frame } = {}
	local dailyDayLabels: { TextLabel } = {}
	local dailyRewardLabels: { TextLabel } = {}
	local dailyIconImages: { GuiObject } = {}
	local dailyCheckBadges: { Frame } = {}
	local dailyReadyBadges: { Frame } = {}
	local dailyGlowWraps: { Frame } = {}
	local dailyCountdownLabel: TextLabel
	local btnClaimAllDaily: TextButton
	local btnClaimDaily: TextButton
	local btnSkipDaily: TextButton
	local dailyCountdownPlate: Frame
	local dailyScrollFrame: ScrollingFrame
	local cachedProfileRef: any = nil

	local function createRobuxPillBadge(button: GuiObject, price: number): Frame
		local badge = Instance.new("Frame")
		badge.Name = "RobuxPillBadge"
		badge.Size = UDim2.fromOffset(58, 26)
		badge.Position = UDim2.new(1, 4, 0, -10)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.BackgroundColor3 = Color3.fromHex("#68FF3B")
		UITheme.applyGradient(badge, Color3.fromHex("#68FF3B"), Color3.fromHex("#38B018"), 90)
		UITheme.addCorner(badge, 13)
		UITheme.applyStroke(badge, 2, UITheme.CONFIG.Colors.Outline)
		badge.ZIndex = button.ZIndex + 4
		badge.Parent = button

		local icon = Instance.new("ImageLabel")
		icon.Name = "RobuxHexagon"
		icon.Size = UDim2.fromOffset(16, 16)
		icon.Position = UDim2.new(0, 6, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = UITheme.Assets.RobuxHexagon
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = badge.ZIndex + 1
		icon.Parent = badge

		local lbl = Instance.new("TextLabel")
		lbl.Name = "PriceText"
		lbl.Size = UDim2.new(1, -26, 1, 0)
		lbl.Position = UDim2.new(0, 24, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = UITheme.CONFIG.Font
		lbl.Text = tostring(price)
		lbl.TextColor3 = UITheme.CONFIG.Colors.White
		lbl.TextScaled = true
		lbl.ZIndex = badge.ZIndex + 1
		UITheme.applyTextStroke(lbl, 2, UITheme.CONFIG.Colors.Outline)
		lbl.Parent = badge

		return badge
	end

	do
		local sliderWrap = Instance.new("Frame")
		sliderWrap.Name = "DailyCards_SliderTrack"
		sliderWrap.Size = UDim2.new(1, -64, 0, 154)
		sliderWrap.Position = UDim2.new(0.5, 0, 0, 12)
		sliderWrap.AnchorPoint = Vector2.new(0.5, 0)
		sliderWrap.BackgroundTransparency = 1
		sliderWrap.ClipsDescendants = true
		sliderWrap.ZIndex = 28
		sliderWrap.Parent = pageDaily

		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name = "CardsScroll"
		scrollFrame.Size = UDim2.fromScale(1, 1)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.BorderSizePixel = 0
		scrollFrame.ScrollBarThickness = 0
		scrollFrame.ScrollingDirection = Enum.ScrollingDirection.X
		scrollFrame.ClipsDescendants = false
		scrollFrame.ZIndex = 28
		scrollFrame.Parent = sliderWrap
		dailyScrollFrame = scrollFrame

		local cardW = 112
		local cardH = 146
		local cardGap = 11
		local padLeft = 4
		local totalW = padLeft + #GameConfig.DAILY_REWARDS * (cardW + cardGap) + 12
		scrollFrame.CanvasSize = UDim2.new(0, totalW, 0, 0)

		-- Circular Blue Arrow Buttons (◀ and ▶)
		local function createArrowButton(name: string, text: string, pos: UDim2): TextButton
			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.Size = UDim2.fromOffset(30, 30)
			btn.Position = pos
			btn.AnchorPoint = Vector2.new(0.5, 0.5)
			btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			btn.AutoButtonColor = false
			btn.Text = ""
			btn.ZIndex = 30
			UITheme.applyGradient(btn, Color3.fromHex("#2494FF"), Color3.fromHex("#0070E0"), 90)
			UITheme.addCorner(btn, 15)
			UITheme.applyStroke(btn, 2.5, Color3.fromRGB(0, 0, 0))
			UITheme.setupButtonHover(btn)
			btn.Parent = pageDaily

			local lbl = Instance.new("TextLabel")
		lbl.Name = "BtnLabel"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.FredokaOne
			lbl.Text = text
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			lbl.TextSize = 14
			lbl.ZIndex = btn.ZIndex + 1
			UITheme.applyTextStroke(lbl, 2, Color3.fromRGB(0, 0, 0))
			lbl.Parent = btn

			return btn
		end

		local btnSlideLeft = createArrowButton("BtnSlideLeft", "◀", UDim2.new(0, 18, 0, 89))
		local btnSlideRight = createArrowButton("BtnSlideRight", "▶", UDim2.new(1, -18, 0, 89))

		btnSlideLeft.Activated:Connect(function()
			local cur = scrollFrame.CanvasPosition.X
			scrollFrame.CanvasPosition = Vector2.new(math.max(0, cur - (cardW + cardGap)), 0)
		end)

		btnSlideRight.Activated:Connect(function()
			local cur = scrollFrame.CanvasPosition.X
			local maxScroll = math.max(0, totalW - sliderWrap.AbsoluteSize.X)
			scrollFrame.CanvasPosition = Vector2.new(math.min(maxScroll, cur + (cardW + cardGap)), 0)
		end)

		-- Build 7 Daily Cards
		for i, reward in GameConfig.DAILY_REWARDS do
			local card = Instance.new("Frame")
			card.Name = `Card_Day{reward.day}`
			card.Size = UDim2.fromOffset(cardW, cardH)
			card.Position = UDim2.fromOffset(padLeft + (i - 1) * (cardW + cardGap), 2)
			card.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
			card.BorderSizePixel = 0
			card.ClipsDescendants = false
			card.ZIndex = 29
			UITheme.addCorner(card, 10)
			UITheme.applyStroke(card, 2.5, Color3.fromRGB(0, 0, 0))
			UITheme.studs(card, 0.92)
			UITheme.attachCardHover(card, 1.04)
			card.Parent = scrollFrame

			local cardClick = Instance.new("TextButton")
			cardClick.Name = "CardClick"
			cardClick.Size = UDim2.fromScale(1, 1)
			cardClick.BackgroundTransparency = 1
			cardClick.Text = ""
			cardClick.ZIndex = card.ZIndex + 5
			cardClick.Parent = card

			cardClick.Activated:Connect(function()
				if cachedProfileRef and i == cachedProfileRef.DailyDay then
					Remotes.MetaAction:FireServer("ClaimDaily")
				end
			end)

			local dayLbl = Instance.new("TextLabel")
			dayLbl.Name = "DayTitle"
			dayLbl.Size = UDim2.new(1, -28, 0, 20)
			dayLbl.Position = UDim2.new(0, 6, 0, 6)
			dayLbl.BackgroundTransparency = 1
			dayLbl.Font = Enum.Font.FredokaOne
			dayLbl.Text = `DAY {reward.day}`
			dayLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			dayLbl.TextScaled = true
			dayLbl.TextXAlignment = Enum.TextXAlignment.Center
			dayLbl.ZIndex = card.ZIndex + 3
			UITheme.applyTextStroke(dayLbl, 2.5, Color3.fromRGB(0, 0, 0))
			UITheme.addTextConstraint(dayLbl, 12, 18)
			dayLbl.Parent = card

			local checkBadge = Instance.new("Frame")
			checkBadge.Name = "CheckBadge"
			checkBadge.Size = UDim2.fromOffset(18, 18)
			checkBadge.Position = UDim2.new(1, -6, 0, 6)
			checkBadge.AnchorPoint = Vector2.new(1, 0)
			checkBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
			checkBadge.BorderSizePixel = 0
			checkBadge.Visible = false
			checkBadge.ZIndex = card.ZIndex + 4
			UITheme.addCorner(checkBadge, 4)
			UITheme.applyStroke(checkBadge, 1.5, Color3.fromRGB(0, 0, 0))
			checkBadge.Parent = card

			local checkGlyph = Instance.new("TextLabel")
			checkGlyph.Size = UDim2.fromScale(1, 1)
			checkGlyph.BackgroundTransparency = 1
			checkGlyph.Font = Enum.Font.FredokaOne
			checkGlyph.Text = "✓"
			checkGlyph.TextColor3 = Color3.fromHex("#52E5FF")
			checkGlyph.TextScaled = true
			checkGlyph.ZIndex = checkBadge.ZIndex + 1
			checkGlyph.Parent = checkBadge

			local readyBadge = Instance.new("Frame")
			readyBadge.Name = "ReadyBadge"
			readyBadge.Size = UDim2.fromOffset(40, 16)
			readyBadge.Position = UDim2.new(1, -6, 0, 6)
			readyBadge.AnchorPoint = Vector2.new(1, 0)
			readyBadge.BackgroundColor3 = Color3.fromHex("#FFC700")
			readyBadge.BorderSizePixel = 0
			readyBadge.Visible = false
			readyBadge.ZIndex = card.ZIndex + 4
			UITheme.applyGradient(readyBadge, Color3.fromHex("#FFD21F"), Color3.fromHex("#F5A623"), 90)
			UITheme.addCorner(readyBadge, 4)
			UITheme.applyStroke(readyBadge, 1.5, Color3.fromRGB(0, 0, 0))
			readyBadge.Parent = card

			local readyText = Instance.new("TextLabel")
			readyText.Size = UDim2.fromScale(1, 1)
			readyText.BackgroundTransparency = 1
			readyText.Font = Enum.Font.FredokaOne
			readyText.Text = "READY"
			readyText.TextColor3 = Color3.fromRGB(0, 0, 0)
			readyText.TextScaled = true
			readyText.ZIndex = readyBadge.ZIndex + 1
			readyText.Parent = readyBadge

			local iconWrap = Instance.new("Frame")
			iconWrap.Name = "IconWrap"
			iconWrap.Size = UDim2.fromOffset(68, 64)
			iconWrap.Position = UDim2.new(0.5, 0, 0.48, 0)
			iconWrap.AnchorPoint = Vector2.new(0.5, 0.5)
			iconWrap.BackgroundTransparency = 1
			iconWrap.ZIndex = card.ZIndex + 2
			iconWrap.Parent = card

			local glowWrap = Instance.new("Frame")
			glowWrap.Name = "GlowWrap"
			glowWrap.Size = UDim2.fromScale(1.15, 1.15)
			glowWrap.Position = UDim2.fromScale(0.5, 0.5)
			glowWrap.AnchorPoint = Vector2.new(0.5, 0.5)
			glowWrap.BackgroundTransparency = 1
			glowWrap.Visible = false
			glowWrap.ZIndex = card.ZIndex + 1
			glowWrap.Parent = iconWrap
			UITheme.sunburst(glowWrap, Color3.fromHex("#FFD21F"), 0.38, 12)

			local isCash = reward.bux > 0 and not reward.chair
			local iconObj: GuiObject

			if reward.chair == "stadium" then
				iconObj = createMiniChairModel(Color3.fromHex("#1E6FFF"), Enum.Material.SmoothPlastic, iconWrap, "stadium")
			elseif reward.chair == "golden" then
				iconObj = createMiniChairModel(Color3.fromHex("#FFD21F"), Enum.Material.Neon, iconWrap, "golden")
			elseif isCash then
				local cashImg = Instance.new("ImageLabel")
				cashImg.Name = "Icon_Cash"
				cashImg.Size = UDim2.fromScale(0.85, 0.72)
				cashImg.Position = UDim2.fromScale(0.5, 0.5)
				cashImg.AnchorPoint = Vector2.new(0.5, 0.5)
				cashImg.BackgroundTransparency = 1
				cashImg.Image = UITheme.Assets.CashStack
				cashImg.ScaleType = Enum.ScaleType.Fit
				cashImg.ZIndex = iconWrap.ZIndex + 1
				cashImg.Parent = iconWrap
				iconObj = cashImg
			else
				local wheelImg = Instance.new("ImageLabel")
				wheelImg.Name = "Icon_Wheel"
				wheelImg.Size = UDim2.fromScale(0.85, 0.85)
				wheelImg.Position = UDim2.fromScale(0.5, 0.5)
				wheelImg.AnchorPoint = Vector2.new(0.5, 0.5)
				wheelImg.BackgroundTransparency = 1
				wheelImg.Image = UITheme.Assets.WheelIcon
				wheelImg.ScaleType = Enum.ScaleType.Fit
				wheelImg.ZIndex = iconWrap.ZIndex + 1
				wheelImg.Parent = iconWrap
				iconObj = wheelImg
			end

			local rewardLbl = Instance.new("TextLabel")
			rewardLbl.Name = "RewardLabel"
			rewardLbl.Size = UDim2.new(1, -10, 0, 20)
			rewardLbl.Position = UDim2.new(0, 5, 1, -24)
			rewardLbl.BackgroundTransparency = 1
			rewardLbl.Font = Enum.Font.FredokaOne
			rewardLbl.Text = reward.label
			rewardLbl.TextColor3 = if isCash then UITheme.CONFIG.Colors.MoneyLime else Color3.fromRGB(255, 255, 255)
			rewardLbl.TextScaled = true
			rewardLbl.ZIndex = card.ZIndex + 3
			UITheme.applyTextStroke(rewardLbl, 2.5, Color3.fromRGB(0, 0, 0))
			UITheme.addTextConstraint(rewardLbl, 10, if isCash then 16 else 13)
			rewardLbl.Parent = card

			table.insert(dailyCardFrames, card)
			table.insert(dailyDayLabels, dayLbl)
			table.insert(dailyRewardLabels, rewardLbl)
			table.insert(dailyIconImages, iconObj)
			table.insert(dailyCheckBadges, checkBadge)
			table.insert(dailyReadyBadges, readyBadge)
			table.insert(dailyGlowWraps, glowWrap)
		end

		-- Scrollbar Progress Divider
		local scrollbarTrack = Instance.new("Frame")
		scrollbarTrack.Name = "Scrollbar_Track"
		scrollbarTrack.Size = UDim2.new(1, -64, 0, 5)
		scrollbarTrack.Position = UDim2.new(0.5, 0, 0, 172)
		scrollbarTrack.AnchorPoint = Vector2.new(0.5, 0)
		scrollbarTrack.BackgroundColor3 = Color3.fromRGB(34, 38, 56)
		scrollbarTrack.BorderSizePixel = 0
		scrollbarTrack.ZIndex = 28
		UITheme.addCorner(scrollbarTrack, 3)
		scrollbarTrack.Parent = pageDaily

		local scrollbarThumb = Instance.new("Frame")
		scrollbarThumb.Name = "Scrollbar_Thumb"
		scrollbarThumb.Size = UDim2.new(0, 280, 1, 0)
		scrollbarThumb.Position = UDim2.new(0, 0, 0, 0)
		scrollbarThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		scrollbarThumb.BorderSizePixel = 0
		scrollbarThumb.ZIndex = 29
		UITheme.addCorner(scrollbarThumb, 3)
		scrollbarThumb.Parent = scrollbarTrack

		scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			local maxScroll = math.max(1, totalW - sliderWrap.AbsoluteSize.X)
			local maxThumbX = scrollbarTrack.AbsoluteSize.X - scrollbarThumb.AbsoluteSize.X
			if maxThumbX > 0 then
				local alpha = math.clamp(scrollFrame.CanvasPosition.X / maxScroll, 0, 1)
				scrollbarThumb.Position = UDim2.new(0, math.floor(alpha * maxThumbX), 0, 0)
			end
		end)

		-- Action Row: SKIP DAY (left), Timer Plate / Claim Button (center), CLAIM ALL! (right)
		btnSkipDaily = Instance.new("TextButton")
		btnSkipDaily.Name = "Button_SkipDay"
		btnSkipDaily.Size = UDim2.fromOffset(164, 48)
		btnSkipDaily.Position = UDim2.new(0, 32, 0, 190)
		btnSkipDaily.Text = ""
		btnSkipDaily.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btnSkipDaily.AutoButtonColor = false
		btnSkipDaily.ZIndex = 29
		UITheme.applyGradient(btnSkipDaily, Color3.fromHex("#2494FF"), Color3.fromHex("#0070E0"), 90)
		UITheme.addCorner(btnSkipDaily, 10)
		UITheme.applyStroke(btnSkipDaily, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.setupButtonHover(btnSkipDaily)
		UITheme.applyButtonStuds(btnSkipDaily, "blue")
		createRobuxPillBadge(btnSkipDaily, 11)
		btnSkipDaily.Parent = pageDaily

		local skipDailyLbl = Instance.new("TextLabel")
		skipDailyLbl.Name = "BtnLabel"
		skipDailyLbl.Size = UDim2.fromScale(1, 1)
		skipDailyLbl.BackgroundTransparency = 1
		skipDailyLbl.Font = Enum.Font.FredokaOne
		skipDailyLbl.Text = "SKIP DAY"
		skipDailyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		skipDailyLbl.TextSize = 18
		skipDailyLbl.ZIndex = btnSkipDaily.ZIndex + 1
		UITheme.applyTextStroke(skipDailyLbl, 2.5, Color3.fromRGB(0, 0, 0))
		skipDailyLbl.Parent = btnSkipDaily

		dailyCountdownPlate = Instance.new("Frame")
		dailyCountdownPlate.Name = "TimerPlate"
		dailyCountdownPlate.Size = UDim2.fromOffset(210, 48)
		dailyCountdownPlate.Position = UDim2.new(0.5, 0, 0, 190)
		dailyCountdownPlate.AnchorPoint = Vector2.new(0.5, 0)
		dailyCountdownPlate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		dailyCountdownPlate.BorderSizePixel = 0
		dailyCountdownPlate.ZIndex = 29
		UITheme.applyGradient(dailyCountdownPlate, Color3.fromHex("#2B2D38"), Color3.fromHex("#1F2028"), 90)
		UITheme.addCorner(dailyCountdownPlate, 10)
		UITheme.applyStroke(dailyCountdownPlate, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.studs(dailyCountdownPlate, 0.92)
		dailyCountdownPlate.Parent = pageDaily

		dailyCountdownLabel = Instance.new("TextLabel")
		dailyCountdownLabel.Name = "TimerCountdown"
		dailyCountdownLabel.Size = UDim2.fromScale(0.94, 0.82)
		dailyCountdownLabel.Position = UDim2.fromScale(0.5, 0.5)
		dailyCountdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		dailyCountdownLabel.BackgroundTransparency = 1
		dailyCountdownLabel.Font = Enum.Font.FredokaOne
		dailyCountdownLabel.Text = "19:54:50"
		dailyCountdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		dailyCountdownLabel.TextSize = 22
		dailyCountdownLabel.ZIndex = dailyCountdownPlate.ZIndex + 1
		UITheme.applyTextStroke(dailyCountdownLabel, 2.5, Color3.fromRGB(0, 0, 0))
		dailyCountdownLabel.Parent = dailyCountdownPlate

		btnClaimDaily = Instance.new("TextButton")
		btnClaimDaily.Name = "Button_ClaimDaily"
		btnClaimDaily.Size = UDim2.fromOffset(210, 48)
		btnClaimDaily.Position = UDim2.new(0.5, 0, 0, 190)
		btnClaimDaily.AnchorPoint = Vector2.new(0.5, 0)
		btnClaimDaily.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btnClaimDaily.AutoButtonColor = false
		btnClaimDaily.Text = ""
		btnClaimDaily.Visible = false
		btnClaimDaily.ZIndex = 29
		UITheme.applyGradient(btnClaimDaily, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
		UITheme.addCorner(btnClaimDaily, 10)
		UITheme.applyStroke(btnClaimDaily, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.applyButtonStuds(btnClaimDaily, "lime")
		UITheme.addPulse(btnClaimDaily)
		btnClaimDaily.Parent = pageDaily

		local claimDailyLbl = Instance.new("TextLabel")
		claimDailyLbl.Name = "BtnLabel"
		claimDailyLbl.Size = UDim2.fromScale(1, 1)
		claimDailyLbl.BackgroundTransparency = 1
		claimDailyLbl.Font = Enum.Font.FredokaOne
		claimDailyLbl.Text = "CLAIM REWARD!"
		claimDailyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		claimDailyLbl.TextSize = 18
		claimDailyLbl.ZIndex = btnClaimDaily.ZIndex + 1
		UITheme.applyTextStroke(claimDailyLbl, 2.5, Color3.fromRGB(0, 0, 0))
		claimDailyLbl.Parent = btnClaimDaily

		btnClaimAllDaily = Instance.new("TextButton")
		btnClaimAllDaily.Name = "Button_ClaimAll"
		btnClaimAllDaily.Size = UDim2.fromOffset(164, 48)
		btnClaimAllDaily.Position = UDim2.new(1, -32, 0, 190)
		btnClaimAllDaily.AnchorPoint = Vector2.new(1, 0)
		btnClaimAllDaily.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btnClaimAllDaily.AutoButtonColor = false
		btnClaimAllDaily.Text = ""
		btnClaimAllDaily.ZIndex = 29
		UITheme.applyGradient(btnClaimAllDaily, Color3.fromHex("#FFA800"), Color3.fromHex("#D97706"), 90)
		UITheme.addCorner(btnClaimAllDaily, 10)
		UITheme.applyStroke(btnClaimAllDaily, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.setupButtonHover(btnClaimAllDaily)
		UITheme.applyButtonStuds(btnClaimAllDaily, "gold")
		createRobuxPillBadge(btnClaimAllDaily, 18)
		btnClaimAllDaily.Parent = pageDaily

		local claimAllLbl = Instance.new("TextLabel")
		claimAllLbl.Name = "BtnLabel"
		claimAllLbl.Size = UDim2.fromScale(1, 1)
		claimAllLbl.BackgroundTransparency = 1
		claimAllLbl.Font = Enum.Font.FredokaOne
		claimAllLbl.Text = "CLAIM ALL!"
		claimAllLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		claimAllLbl.TextSize = 18
		claimAllLbl.ZIndex = btnClaimAllDaily.ZIndex + 1
		UITheme.applyTextStroke(claimAllLbl, 2.5, Color3.fromRGB(0, 0, 0))
		claimAllLbl.Parent = btnClaimAllDaily

		btnClaimDaily.Activated:Connect(function()
			Remotes.MetaAction:FireServer("ClaimDaily")
		end)
		btnSkipDaily.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyShopItem", "skip_daily")
		end)
		btnClaimAllDaily.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyShopItem", "claim_all_daily")
		end)
	end

	-- ============================================================
	-- PAGE 2: GROUP REWARD
	-- ============================================================
	local btnClaimGroup: TextButton
	do
		local groupBanner = Instance.new("Frame")
		groupBanner.Name = "GroupBanner"
		groupBanner.Size = UDim2.new(0.92, 0, 0, 220)
		groupBanner.Position = UDim2.new(0.5, 0, 0, 14)
		groupBanner.AnchorPoint = Vector2.new(0.5, 0)
		groupBanner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		groupBanner.ZIndex = 28
		UITheme.applyGradient(groupBanner, Color3.fromHex("#38BDF8"), Color3.fromHex("#0284C7"), 90)
		UITheme.addCorner(groupBanner, 10)
		UITheme.applyStroke(groupBanner, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.studs(groupBanner, 0.90)
		groupBanner.Parent = pageGroup

		local groupSub = Instance.new("TextLabel")
		groupSub.Size = UDim2.new(0.94, 0, 0, 28)
		groupSub.Position = UDim2.new(0.03, 0, 0, 10)
		groupSub.BackgroundTransparency = 1
		groupSub.Font = Enum.Font.FredokaOne
		groupSub.Text = "Like the game & join the group!"
		groupSub.TextColor3 = Color3.fromRGB(255, 255, 255)
		groupSub.TextSize = 20
		groupSub.ZIndex = groupBanner.ZIndex + 1
		UITheme.applyTextStroke(groupSub, 2.5, Color3.fromRGB(0, 0, 0))
		groupSub.Parent = groupBanner

		local likeCard = Instance.new("Frame")
		likeCard.Size = UDim2.new(0.24, 0, 0.44, 0)
		likeCard.Position = UDim2.new(0.06, 0, 0.22, 0)
		likeCard.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
		likeCard.ZIndex = groupBanner.ZIndex + 1
		UITheme.addCorner(likeCard, 8)
		UITheme.applyStroke(likeCard, 2.5, Color3.fromRGB(0, 0, 0))
		likeCard.Parent = groupBanner

		local likeIcon = Instance.new("TextLabel")
		likeIcon.Size = UDim2.fromScale(1, 0.55)
		likeIcon.Position = UDim2.fromScale(0, 0.05)
		likeIcon.BackgroundTransparency = 1
		likeIcon.Text = "👍"
		likeIcon.TextScaled = true
		likeIcon.ZIndex = likeCard.ZIndex + 1
		likeIcon.Parent = likeCard

		local likeLbl = Instance.new("TextLabel")
		likeLbl.Size = UDim2.new(1, 0, 0.35, 0)
		likeLbl.Position = UDim2.new(0, 0, 0.60, 0)
		likeLbl.BackgroundTransparency = 1
		likeLbl.Font = Enum.Font.FredokaOne
		likeLbl.Text = "LIKE"
		likeLbl.TextColor3 = Color3.fromHex("#FFD21F")
		likeLbl.TextSize = 16
		likeLbl.ZIndex = likeCard.ZIndex + 1
		UITheme.applyTextStroke(likeLbl, 2, Color3.fromRGB(0, 0, 0))
		likeLbl.Parent = likeCard

		local plusLbl = Instance.new("TextLabel")
		plusLbl.Size = UDim2.new(0.06, 0, 0.20, 0)
		plusLbl.Position = UDim2.new(0.32, 0, 0.34, 0)
		plusLbl.BackgroundTransparency = 1
		plusLbl.Font = Enum.Font.FredokaOne
		plusLbl.Text = "+"
		plusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		plusLbl.TextSize = 28
		plusLbl.ZIndex = groupBanner.ZIndex + 1
		UITheme.applyTextStroke(plusLbl, 2.5, Color3.fromRGB(0, 0, 0))
		plusLbl.Parent = groupBanner

		local joinCard = Instance.new("Frame")
		joinCard.Size = UDim2.new(0.24, 0, 0.44, 0)
		joinCard.Position = UDim2.new(0.40, 0, 0.22, 0)
		joinCard.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
		joinCard.ZIndex = groupBanner.ZIndex + 1
		UITheme.addCorner(joinCard, 8)
		UITheme.applyStroke(joinCard, 2.5, Color3.fromRGB(0, 0, 0))
		joinCard.Parent = groupBanner

		local joinIcon = Instance.new("TextLabel")
		joinIcon.Size = UDim2.fromScale(1, 0.55)
		joinIcon.Position = UDim2.fromScale(0, 0.05)
		joinIcon.BackgroundTransparency = 1
		joinIcon.Text = "👥"
		joinIcon.TextScaled = true
		joinIcon.ZIndex = joinCard.ZIndex + 1
		joinIcon.Parent = joinCard

		local joinLbl = Instance.new("TextLabel")
		joinLbl.Size = UDim2.new(1, 0, 0.35, 0)
		joinLbl.Position = UDim2.new(0, 0, 0.60, 0)
		joinLbl.BackgroundTransparency = 1
		joinLbl.Font = Enum.Font.FredokaOne
		joinLbl.Text = "JOIN"
		joinLbl.TextColor3 = Color3.fromHex("#FFD21F")
		joinLbl.TextSize = 16
		joinLbl.ZIndex = joinCard.ZIndex + 1
		UITheme.applyTextStroke(joinLbl, 2, Color3.fromRGB(0, 0, 0))
		joinLbl.Parent = joinCard

		local equalsLbl = Instance.new("TextLabel")
		equalsLbl.Size = UDim2.new(0.06, 0, 0.20, 0)
		equalsLbl.Position = UDim2.new(0.66, 0, 0.34, 0)
		equalsLbl.BackgroundTransparency = 1
		equalsLbl.Font = Enum.Font.FredokaOne
		equalsLbl.Text = "="
		equalsLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		equalsLbl.TextSize = 28
		equalsLbl.ZIndex = groupBanner.ZIndex + 1
		UITheme.applyTextStroke(equalsLbl, 2.5, Color3.fromRGB(0, 0, 0))
		equalsLbl.Parent = groupBanner

		local rewardChestCard = Instance.new("Frame")
		rewardChestCard.Size = UDim2.new(0.24, 0, 0.44, 0)
		rewardChestCard.Position = UDim2.new(0.74, 0, 0.22, 0)
		rewardChestCard.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
		rewardChestCard.ZIndex = groupBanner.ZIndex + 1
		UITheme.addCorner(rewardChestCard, 8)
		UITheme.applyStroke(rewardChestCard, 2.5, Color3.fromRGB(0, 0, 0))
		rewardChestCard.Parent = groupBanner

		local groupCashIcon = Instance.new("ImageLabel")
		groupCashIcon.Name = "Icon_Cash"
		groupCashIcon.Size = UDim2.fromScale(0.85, 0.58)
		groupCashIcon.Position = UDim2.fromScale(0.5, 0.32)
		groupCashIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		groupCashIcon.BackgroundTransparency = 1
		groupCashIcon.Image = UITheme.Assets.CashStack
		groupCashIcon.ScaleType = Enum.ScaleType.Fit
		groupCashIcon.ZIndex = rewardChestCard.ZIndex + 1
		groupCashIcon.Parent = rewardChestCard

		local rewardValLbl = Instance.new("TextLabel")
		rewardValLbl.Size = UDim2.new(1, 0, 0.35, 0)
		rewardValLbl.Position = UDim2.new(0, 0, 0.60, 0)
		rewardValLbl.BackgroundTransparency = 1
		rewardValLbl.Font = Enum.Font.FredokaOne
		rewardValLbl.Text = `$250 BUX`
		rewardValLbl.TextColor3 = UITheme.CONFIG.Colors.MoneyLime
		rewardValLbl.TextSize = 16
		rewardValLbl.ZIndex = rewardChestCard.ZIndex + 1
		UITheme.applyTextStroke(rewardValLbl, 2, Color3.fromRGB(0, 0, 0))
		rewardValLbl.Parent = rewardChestCard

		btnClaimGroup = Instance.new("TextButton")
		btnClaimGroup.Name = "BtnClaimGroup"
		btnClaimGroup.Size = UDim2.new(0.44, 0, 0, 44)
		btnClaimGroup.Position = UDim2.new(0.5, 0, 1, -12)
		btnClaimGroup.AnchorPoint = Vector2.new(0.5, 1)
		btnClaimGroup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btnClaimGroup.AutoButtonColor = false
		btnClaimGroup.Text = ""
		btnClaimGroup.ZIndex = groupBanner.ZIndex + 2
		UITheme.applyGradient(btnClaimGroup, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
		UITheme.addCorner(btnClaimGroup, 8)
		UITheme.applyStroke(btnClaimGroup, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.applyButtonStuds(btnClaimGroup, "lime")
		UITheme.addPulse(btnClaimGroup)
		btnClaimGroup.Parent = groupBanner

		local claimGrpLbl = Instance.new("TextLabel")
		claimGrpLbl.Name = "BtnLabel"
		claimGrpLbl.Size = UDim2.fromScale(1, 1)
		claimGrpLbl.BackgroundTransparency = 1
		claimGrpLbl.Font = Enum.Font.FredokaOne
		claimGrpLbl.Text = "CLAIM $250!"
		claimGrpLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		claimGrpLbl.TextSize = 18
		claimGrpLbl.ZIndex = btnClaimGroup.ZIndex + 1
		UITheme.applyTextStroke(claimGrpLbl, 2.5, Color3.fromRGB(0, 0, 0))
		claimGrpLbl.Parent = btnClaimGroup

		btnClaimGroup.Activated:Connect(function()
			Remotes.MetaAction:FireServer("ClaimGroup")
		end)
	end

	-- ============================================================
	-- PAGE 3: PLAYTIME REWARDS
	-- ============================================================
	local ptRailFill: Frame
	local playtimeNodes: { [string]: Frame } = {}
	local playtimeNodeIcons: { [string]: TextLabel } = {}
	local playtimeButtons: { [string]: TextButton } = {}
	local playtimeCardFrames: { [string]: Frame } = {}
	local playtimeInsetFrames: { [string]: Frame } = {}
	local playtimeLockBadges: { [string]: ImageLabel } = {}
	local playedElapsedLabel: TextLabel

	do
		local ptRail = Instance.new("Frame")
		ptRail.Name = "MilestoneRail"
		ptRail.Size = UDim2.new(0.86, 0, 0, 10)
		ptRail.Position = UDim2.new(0.5, 0, 0, 12)
		ptRail.AnchorPoint = Vector2.new(0.5, 0)
		ptRail.BackgroundColor3 = Color3.fromHex("#1B1B1F")
		ptRail.ZIndex = 28
		UITheme.addCorner(ptRail, 4)
		UITheme.applyStroke(ptRail, 2, Color3.fromRGB(0, 0, 0))
		ptRail.Parent = pagePlaytime

		ptRailFill = Instance.new("Frame")
		ptRailFill.Name = "RailFill"
		ptRailFill.Size = UDim2.fromScale(0, 1)
		ptRailFill.BackgroundColor3 = Color3.fromHex("#7CFF2B")
		ptRailFill.BorderSizePixel = 0
		ptRailFill.ZIndex = ptRail.ZIndex + 1
		UITheme.addCorner(ptRailFill, 3)
		ptRailFill.Parent = ptRail

		local cardWidths = { 0.142, 0.142, 0.142, 0.142, 0.142, 0.185 }
		local cardHeights = { 0.68, 0.68, 0.68, 0.68, 0.68, 0.70 }
		local cardXPos = { 0.02, 0.174, 0.328, 0.482, 0.636, 0.790 }

		for i, pt in GameConfig.PLAYTIME_REWARDS do
			local nX = cardXPos[i] + cardWidths[i] * 0.5
			local node = Instance.new("Frame")
			node.Name = `Node_{pt.id}`
			node.Size = UDim2.fromOffset(20, 20)
			node.AnchorPoint = Vector2.new(0.5, 0.5)
			node.Position = UDim2.new(nX, 0, 0.5, 0)
			node.BackgroundColor3 = Color3.fromHex("#3A3A40")
			node.ZIndex = ptRail.ZIndex + 2
			UITheme.addCorner(node, 4)
			UITheme.applyStroke(node, 2, Color3.fromRGB(0, 0, 0))
			node.Parent = ptRail

			local nodeLbl = Instance.new("TextLabel")
			nodeLbl.Size = UDim2.fromScale(1, 1)
			nodeLbl.BackgroundTransparency = 1
			nodeLbl.Font = Enum.Font.FredokaOne
			nodeLbl.Text = ""
			nodeLbl.TextColor3 = Color3.fromRGB(0, 0, 0)
			nodeLbl.TextSize = 14
			nodeLbl.ZIndex = node.ZIndex + 1
			nodeLbl.Parent = node

			playtimeNodes[pt.id] = node
			playtimeNodeIcons[pt.id] = nodeLbl

			local card = Instance.new("Frame")
			card.Name = `Card_{pt.id}`
			card.Size = UDim2.new(cardWidths[i], 0, cardHeights[i], 0)
			card.Position = UDim2.new(cardXPos[i], 0, 0.11, 0)
			card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			card.ZIndex = 28
			UITheme.addCorner(card, 6)
			UITheme.applyStroke(card, 2.5, Color3.fromRGB(0, 0, 0))
			card.Parent = pagePlaytime
			playtimeCardFrames[pt.id] = card

			if i <= 4 then
				UITheme.applyGradient(card, Color3.fromHex("#2F7FE6"), Color3.fromHex("#1A4DAA"), 90)
			elseif i == 5 then
				UITheme.applyGradient(card, Color3.fromHex("#7B3FDB"), Color3.fromHex("#4A1FA0"), 90)
				local rib = Instance.new("TextLabel")
				rib.Size = UDim2.new(0.72, 0, 0.10, 0)
				rib.Position = UDim2.new(0.36, 0, -0.02, 0)
				rib.BackgroundColor3 = Color3.fromHex("#E52F9B")
				rib.Font = Enum.Font.FredokaOne
				rib.Text = "+SPINS!"
				rib.TextColor3 = Color3.fromRGB(255, 255, 255)
				rib.TextSize = 10
				rib.Rotation = 10
				rib.ZIndex = card.ZIndex + 5
				UITheme.addCorner(rib, 3)
				UITheme.applyStroke(rib, 2, Color3.fromRGB(0, 0, 0))
				rib.Parent = card
			elseif i == 6 then
				UITheme.applyGradient(card, Color3.fromHex("#B86A1E"), Color3.fromHex("#6E3E10"), 90)
				local rib = Instance.new("TextLabel")
				rib.Size = UDim2.new(0.70, 0, 0.10, 0)
				rib.Position = UDim2.new(0.40, 0, -0.02, 0)
				rib.BackgroundColor3 = Color3.fromHex("#F2A41F")
				rib.Font = Enum.Font.FredokaOne
				rib.Text = "+CHAIR!"
				rib.TextColor3 = Color3.fromRGB(255, 255, 255)
				rib.TextSize = 10
				rib.Rotation = 10
				rib.ZIndex = card.ZIndex + 5
				UITheme.addCorner(rib, 3)
				UITheme.applyStroke(rib, 2, Color3.fromRGB(0, 0, 0))
				rib.Parent = card
			end

			local inset = Instance.new("Frame")
			inset.Name = "InsetFrame"
			inset.Size = UDim2.new(0.86, 0, 0.38, 0)
			inset.Position = UDim2.new(0.07, 0, 0.04, 0)
			inset.BackgroundColor3 = if i == 5 then Color3.fromHex("#6A2FC0") elseif i == 6 then Color3.fromHex("#C98A3A") else Color3.fromHex("#1E5CC0")
			inset.ZIndex = card.ZIndex + 1
			UITheme.addCorner(inset, 5)
			UITheme.applyStroke(inset, 2, Color3.fromRGB(0, 0, 0))
			inset.Parent = card
			playtimeInsetFrames[pt.id] = inset

			if not pt.chair and i <= 3 then
				local cashImg = Instance.new("ImageLabel")
				cashImg.Name = "Icon_Cash"
				cashImg.Size = UDim2.fromScale(0.82, 0.82)
				cashImg.AnchorPoint = Vector2.new(0.5, 0.5)
				cashImg.Position = UDim2.fromScale(0.5, 0.5)
				cashImg.BackgroundTransparency = 1
				cashImg.Image = UITheme.Assets.CashStack
				cashImg.ScaleType = Enum.ScaleType.Fit
				cashImg.ZIndex = inset.ZIndex + 1
				cashImg.Parent = inset
			elseif i == 5 then
				local wheelImg = Instance.new("ImageLabel")
				wheelImg.Name = "Icon_Wheel"
				wheelImg.Size = UDim2.fromScale(0.82, 0.82)
				wheelImg.AnchorPoint = Vector2.new(0.5, 0.5)
				wheelImg.Position = UDim2.fromScale(0.5, 0.5)
				wheelImg.BackgroundTransparency = 1
				wheelImg.Image = UITheme.Assets.WheelIcon
				wheelImg.ScaleType = Enum.ScaleType.Fit
				wheelImg.ZIndex = inset.ZIndex + 1
				wheelImg.Parent = inset
			else
				local iconLbl = Instance.new("TextLabel")
				iconLbl.Size = UDim2.fromScale(0.82, 0.82)
				iconLbl.Position = UDim2.fromScale(0.09, 0.09)
				iconLbl.BackgroundTransparency = 1
				iconLbl.Font = Enum.Font.FredokaOne
				iconLbl.Text = if pt.chair then "🪑" else "📦"
				iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				iconLbl.TextScaled = true
				iconLbl.ZIndex = inset.ZIndex + 1
				iconLbl.Parent = inset
			end

			local lockBadge = Instance.new("ImageLabel")
			lockBadge.Name = "Icon_Lock"
			lockBadge.Size = UDim2.fromOffset(18, 18)
			lockBadge.Position = UDim2.new(1, -18, 1, -18)
			lockBadge.BackgroundTransparency = 1
			lockBadge.Image = "rbxassetid://6031082533"
			lockBadge.ImageColor3 = Color3.fromHex("#F59E0B")
			lockBadge.ZIndex = inset.ZIndex + 3
			lockBadge.Parent = inset
			playtimeLockBadges[pt.id] = lockBadge

			local amtLbl = Instance.new("TextLabel")
			amtLbl.Size = UDim2.new(0.96, 0, 0.12, 0)
			amtLbl.Position = UDim2.new(0.02, 0, 0.44, 0)
			amtLbl.BackgroundTransparency = 1
			amtLbl.Font = Enum.Font.FredokaOne
			amtLbl.Text = pt.rewardLabel
			amtLbl.TextColor3 = UITheme.CONFIG.Colors.MoneyLime
			amtLbl.TextScaled = true
			amtLbl.ZIndex = card.ZIndex + 2
			UITheme.applyTextStroke(amtLbl, 2.5, Color3.fromRGB(0, 0, 0))
			amtLbl.Parent = card

			local timeLbl = Instance.new("TextLabel")
			timeLbl.Size = UDim2.new(0.96, 0, 0.10, 0)
			timeLbl.Position = UDim2.new(0.02, 0, 0.58, 0)
			timeLbl.BackgroundTransparency = 1
			timeLbl.Font = Enum.Font.FredokaOne
			timeLbl.Text = pt.timeLabel
			timeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			timeLbl.TextScaled = true
			timeLbl.ZIndex = card.ZIndex + 2
			UITheme.applyTextStroke(timeLbl, 2, Color3.fromRGB(0, 0, 0))
			timeLbl.Parent = card

			local cBtn = Instance.new("TextButton")
			cBtn.Name = `BtnClaim_{pt.id}`
			cBtn.Size = UDim2.new(0.92, 0, 0.14, 0)
			cBtn.Position = UDim2.new(0.04, 0, 0.82, 0)
			cBtn.BackgroundColor3 = Color3.fromHex("#17181D")
			cBtn.AutoButtonColor = false
			cBtn.Text = ""
			cBtn.ZIndex = card.ZIndex + 3
			UITheme.addCorner(cBtn, 5)
			UITheme.applyStroke(cBtn, 2, Color3.fromRGB(0, 0, 0))
			UITheme.applyButtonStuds(cBtn, "lime")
			cBtn.Parent = card

			local progFill = Instance.new("Frame")
			progFill.Name = "ProgressFill"
			progFill.Size = UDim2.fromScale(0, 1)
			progFill.BackgroundColor3 = Color3.fromHex("#FFB830")
			progFill.BorderSizePixel = 0
			progFill.ZIndex = cBtn.ZIndex - 1
			UITheme.addCorner(progFill, 4)
			progFill.Parent = cBtn

			local cBtnLbl = Instance.new("TextLabel")
			cBtnLbl.Name = "BtnLabel"
			cBtnLbl.Size = UDim2.fromScale(1, 1)
			cBtnLbl.BackgroundTransparency = 1
			cBtnLbl.Font = Enum.Font.FredokaOne
			cBtnLbl.Text = "5:00"
			cBtnLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			cBtnLbl.TextScaled = true
			cBtnLbl.ZIndex = cBtn.ZIndex + 1
			UITheme.applyTextStroke(cBtnLbl, 2, Color3.fromRGB(0, 0, 0))
			cBtnLbl.Parent = cBtn

			cBtn.Activated:Connect(function()
				Remotes.MetaAction:FireServer("ClaimPlaytime", pt.id)
			end)
			playtimeButtons[pt.id] = cBtn
		end

		playedElapsedLabel = Instance.new("TextLabel")
		playedElapsedLabel.Name = "PlayedElapsedLabel"
		playedElapsedLabel.Size = UDim2.new(0.35, 0, 0, 28)
		playedElapsedLabel.Position = UDim2.new(0.03, 0, 0.86, 0)
		playedElapsedLabel.BackgroundTransparency = 1
		playedElapsedLabel.Font = Enum.Font.FredokaOne
		playedElapsedLabel.Text = "⏱️ 0:00 played"
		playedElapsedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		playedElapsedLabel.TextSize = 16
		playedElapsedLabel.TextXAlignment = Enum.TextXAlignment.Left
		playedElapsedLabel.ZIndex = 28
		UITheme.applyTextStroke(playedElapsedLabel, 2.5, Color3.fromRGB(0, 0, 0))
		playedElapsedLabel.Parent = pagePlaytime

		local btnSkipAllPlaytime = Instance.new("TextButton")
		btnSkipAllPlaytime.Name = "BtnSkipAllPlaytime"
		btnSkipAllPlaytime.Size = UDim2.new(0.32, 0, 0, 36)
		btnSkipAllPlaytime.Position = UDim2.new(0.50, 0, 0.84, 0)
		btnSkipAllPlaytime.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btnSkipAllPlaytime.AutoButtonColor = false
		btnSkipAllPlaytime.Text = ""
		btnSkipAllPlaytime.ZIndex = 28
		UITheme.applyGradient(btnSkipAllPlaytime, Color3.fromHex("#FFA800"), Color3.fromHex("#D97706"), 90)
		UITheme.addCorner(btnSkipAllPlaytime, 6)
		UITheme.applyStroke(btnSkipAllPlaytime, 2, Color3.fromRGB(0, 0, 0))
		UITheme.setupButtonHover(btnSkipAllPlaytime)
		UITheme.applyButtonStuds(btnSkipAllPlaytime, "gold")
		createRobuxPillBadge(btnSkipAllPlaytime, 49)
		btnSkipAllPlaytime.Parent = pagePlaytime

		local skipAllLbl = Instance.new("TextLabel")
		skipAllLbl.Name = "BtnLabel"
		skipAllLbl.Size = UDim2.new(1, -54, 1, 0)
		skipAllLbl.Position = UDim2.new(0, 6, 0, 0)
		skipAllLbl.BackgroundTransparency = 1
		skipAllLbl.Font = Enum.Font.FredokaOne
		skipAllLbl.Text = "⏩ SKIP ALL"
		skipAllLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		skipAllLbl.TextScaled = true
		skipAllLbl.ZIndex = btnSkipAllPlaytime.ZIndex + 1
		UITheme.applyTextStroke(skipAllLbl, 2, Color3.fromRGB(0, 0, 0))
		skipAllLbl.Parent = btnSkipAllPlaytime

		btnSkipAllPlaytime.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyShopItem", "skip_all_playtime")
		end)
	end

	local function open(tab: ("DAILY" | "GROUP" | "PLAYTIME")?)
		modalBackdrop.Visible = true
		setTab(tab or "DAILY")
		UITheme.openWindow(freeRewardsWindow)
		if cachedProfileRef and (tab == "DAILY" or not tab) then
			local activeDay = cachedProfileRef.DailyDay or 1
			if activeDay >= 4 then
				local targetX = math.min(260, (activeDay - 3) * (cardW + cardGap))
				dailyScrollFrame.CanvasPosition = Vector2.new(targetX, 0)
			else
				dailyScrollFrame.CanvasPosition = Vector2.new(0, 0)
			end
		end
	end

	local function close()
		UITheme.closeWindow(freeRewardsWindow, function()
			modalBackdrop.Visible = false
		end)
	end

	local function isOpen(): boolean
		return freeRewardsWindow.Visible
	end

	local function update(p: any, now: number): FreeRewardsStatus
		if not p then
			return { readyDaily = false, readyGroup = false, readyPlaytime = 0, readyTotal = 0 }
		end
		cachedProfileRef = p

		-- 1. Daily update
		local dailyRem = math.max(0, DAILY_COOLDOWN_SEC - (now - (p.LastDailyClaim or 0)))
		local canClaimDaily = dailyRem == 0
		if dailyCountdownLabel then
			dailyCountdownLabel.Text = formatHHMMSS(dailyRem)
		end

		for i, reward in GameConfig.DAILY_REWARDS do
			local card = dailyCardFrames[i]
			local dayLbl = dailyDayLabels[i]
			local rewLbl = dailyRewardLabels[i]
			local iconObj = dailyIconImages[i]
			local checkB = dailyCheckBadges[i]
			local readyB = dailyReadyBadges[i]
			local glowW = dailyGlowWraps[i]
			local isCash = reward.bux > 0 and not reward.chair
			if not card then continue end

			if i < p.DailyDay then
				-- CLAIMED: Charcoal silhouette + checkmark badge
				card.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
				UITheme.applyStroke(card, 2, Color3.fromRGB(26, 30, 42))
				if checkB then checkB.Visible = true end
				if readyB then readyB.Visible = false end
				if glowW then glowW.Visible = false end
				if dayLbl then dayLbl.TextColor3 = Color3.fromRGB(160, 168, 184) end
				if rewLbl then rewLbl.TextColor3 = if isCash then Color3.fromRGB(100, 170, 70) else Color3.fromRGB(160, 168, 184) end
				if iconObj then
					if iconObj:IsA("ImageLabel") then
						iconObj.ImageColor3 = Color3.fromRGB(35, 42, 58)
					elseif iconObj:IsA("ViewportFrame") then
						for _, part in iconObj:GetDescendants() do
							if part:IsA("BasePart") then
								part.Color = Color3.fromRGB(35, 42, 58)
							end
						end
					end
				end
			elseif i == p.DailyDay then
				if checkB then checkB.Visible = false end
				if canClaimDaily then
					-- READY: Warm gold background, 3.5px gold pulse border, READY badge, full vibrant color + sunburst glow
					card.BackgroundColor3 = Color3.fromRGB(34, 28, 16)
					UITheme.applyStroke(card, 3.5, Color3.fromHex("#FFD21F"))
					if readyB then readyB.Visible = true end
					if glowW then glowW.Visible = true end
				else
					card.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
					UITheme.applyStroke(card, 2.5, Color3.fromRGB(0, 0, 0))
					if readyB then readyB.Visible = false end
					if glowW then glowW.Visible = false end
				end
				if dayLbl then dayLbl.TextColor3 = Color3.fromRGB(255, 255, 255) end
				if rewLbl then rewLbl.TextColor3 = if isCash then UITheme.CONFIG.Colors.MoneyLime else Color3.fromRGB(255, 255, 255) end
				if iconObj then
					if iconObj:IsA("ImageLabel") then
						iconObj.ImageColor3 = Color3.new(1, 1, 1)
					elseif iconObj:IsA("ViewportFrame") then
						local chairCol = if reward.chair == "golden" then Color3.fromHex("#FFD21F") else Color3.fromHex("#1E6FFF")
						for _, part in iconObj:GetDescendants() do
							if part:IsA("BasePart") then
								part.Color = chairCol
							end
						end
					end
				end
			else
				-- UPCOMING: Clean dark card, full color
				card.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
				UITheme.applyStroke(card, 2.5, Color3.fromRGB(0, 0, 0))
				if checkB then checkB.Visible = false end
				if readyB then readyB.Visible = false end
				if glowW then glowW.Visible = false end
				if dayLbl then dayLbl.TextColor3 = Color3.fromRGB(255, 255, 255) end
				if rewLbl then rewLbl.TextColor3 = if isCash then UITheme.CONFIG.Colors.MoneyLime else Color3.fromRGB(255, 255, 255) end
				if iconObj then
					if iconObj:IsA("ImageLabel") then
						iconObj.ImageColor3 = Color3.new(1, 1, 1)
					elseif iconObj:IsA("ViewportFrame") then
						local chairCol = if reward.chair == "golden" then Color3.fromHex("#FFD21F") else Color3.fromHex("#1E6FFF")
						for _, part in iconObj:GetDescendants() do
							if part:IsA("BasePart") then
								part.Color = chairCol
							end
						end
					end
				end
			end
		end

		if canClaimDaily then
			dailyCountdownPlate.Visible = false
			btnClaimDaily.Visible = true
			local cLbl = btnClaimDaily:FindFirstChild("BtnLabel") :: TextLabel?
			if cLbl then
				cLbl.Text = `CLAIM DAY {p.DailyDay} REWARD!`
			end
		else
			dailyCountdownPlate.Visible = true
			btnClaimDaily.Visible = false
		end

		-- 2. Group update
		local grpLbl = btnClaimGroup:FindFirstChild("BtnLabel") :: TextLabel?
		if p.GroupClaimed then
			if grpLbl then grpLbl.Text = "✓ CLAIMED" end
			btnClaimGroup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			UITheme.applyGradient(btnClaimGroup, Color3.fromHex("#607085"), Color3.fromHex("#536277"), 90)
			UITheme.applyButtonStuds(btnClaimGroup, "gray")
			btnClaimGroup.AutoButtonColor = false
		else
			if grpLbl then grpLbl.Text = "CLAIM $250!" end
			btnClaimGroup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			UITheme.applyGradient(btnClaimGroup, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
			UITheme.applyButtonStuds(btnClaimGroup, "lime")
			btnClaimGroup.AutoButtonColor = true
		end

		-- 3. Playtime update
		local elapsed = math.max(0, now - (p.SessionJoinTime or now))
		playedElapsedLabel.Text = `⏱️ {formatMMSS(elapsed)} played`
		local readyPlaytimeCount = 0
		local pts = GameConfig.PLAYTIME_REWARDS
		local numPts = #pts

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
		ptRailFill.Size = UDim2.fromScale(railPct, 1)

		for i, pt in pts do
			local b = playtimeButtons[pt.id]
			local bLbl = b and b:FindFirstChild("BtnLabel") :: TextLabel?
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

			if node and nodeLbl then
				if claimed then
					node.BackgroundColor3 = Color3.fromHex("#7CFF2B")
					nodeLbl.Text = "✓"
				elseif isReady then
					node.BackgroundColor3 = Color3.fromHex("#FFD21F")
					nodeLbl.Text = "!"
				elseif elapsed >= pt.seconds then
					node.BackgroundColor3 = Color3.fromHex("#FFD21F")
					nodeLbl.Text = ""
				else
					node.BackgroundColor3 = Color3.fromHex("#3A3A40")
					nodeLbl.Text = ""
				end
			end

			if lock then
				lock.Visible = not claimed and not isReady
			end

			if b and bLbl then
				b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				if claimed then
					bLbl.Text = "✓ CLAIMED"
					UITheme.applyGradient(b, Color3.fromHex("#3A3A40"), Color3.fromHex("#26262A"), 90)
					UITheme.applyButtonStuds(b, "gray")
					bLbl.TextColor3 = Color3.fromHex("#94A3B8")
					if inset then inset.BackgroundColor3 = Color3.fromRGB(22, 28, 38) end
				elseif isReady then
					bLbl.Text = "CLAIM!"
					UITheme.applyGradient(b, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
					UITheme.applyButtonStuds(b, "lime")
					bLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
					readyPlaytimeCount += 1
					if inset then inset.BackgroundColor3 = Color3.fromHex("#FFB940") end
				else
					local rem = pt.seconds - elapsed
					bLbl.Text = `🔒 {formatMMSS(rem)}`
					UITheme.applyGradient(b, Color3.fromHex("#2B2D38"), Color3.fromHex("#1F2028"), 90)
					UITheme.applyButtonStuds(b, "gray")
					bLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end

		badgeDaily.Visible = canClaimDaily
		badgeGroup.Visible = not p.GroupClaimed
		badgePlaytime.Visible = readyPlaytimeCount > 0
		badgePlaytime.Text = tostring(readyPlaytimeCount)

		local freeReadyTotal = (if canClaimDaily then 1 else 0) + (if not p.GroupClaimed then 1 else 0) + readyPlaytimeCount

		return {
			readyDaily = canClaimDaily,
			readyGroup = not p.GroupClaimed,
			readyPlaytime = readyPlaytimeCount,
			readyTotal = freeReadyTotal,
		}
	end

	return {
		window = freeRewardsWindow,
		open = open,
		close = close,
		isOpen = isOpen,
		setTab = setTab,
		update = update,
	}
end

ShopDailyUI.initDaily = ShopDailyUI.initFreeRewards

function ShopDailyUI.initChairSkins(
	screenGui: ScreenGui,
	modalBackdrop: GuiObject,
	Remotes: any,
	UITheme: any,
	GameConfig: any,
	openWheelFn: () -> ()
): SkinsHandler
	local function getAsset(id: string?, fallback: string): string
		if not id or id == "" or id == "rbxassetid://0" then
			return fallback
		end
		return id
	end

	local skinsWindowData = UITheme.window({
		name = "SkinsWindow",
		title = "CHAIR SKINS",
		headerColors = UITheme.CONFIG.Headers.ChairSkins,
		closeStyle = "magenta",
		headerHeightOffset = 50,
		size = UDim2.new(0, 620, 0, 490),
		parent = screenGui,
		onClose = function()
			modalBackdrop.Visible = false
		end,
	})
	local skinsWindow = skinsWindowData.Window
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(650, 560)
	sizeConstraint.MinSize = Vector2.new(460, 360)
	sizeConstraint.Parent = skinsWindow
	skinsWindow.ZIndex = 26
	skinsWindow.Visible = false

	-- Header Customization to exactly match reference image
	local header = skinsWindowData.Header
	local titleLbl = skinsWindowData.Title
	if titleLbl then
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.Text = "CHAIR SKINS"
		titleLbl.TextSize = 26
		titleLbl.TextScaled = false
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Position = UDim2.new(0, 18, 0.5, 0)
		titleLbl.AnchorPoint = Vector2.new(0, 0.5)
		titleLbl.Size = UDim2.new(0.65, 0, 0.8, 0)
		titleLbl.BackgroundTransparency = 1
		local stroke = titleLbl:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", titleLbl)
		stroke.Thickness = 3.5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		local tConstraint = titleLbl:FindFirstChildOfClass("UITextSizeConstraint")
		if tConstraint then tConstraint:Destroy() end
	end
	local studs = header:FindFirstChild("Studs") :: ImageLabel?
	if studs then
		studs.Image = getAsset(UITheme.Assets.Header_Studs_ChairSkins_Yellow, "rbxassetid://122367808504188")
		studs.ImageTransparency = 0
		studs.ScaleType = Enum.ScaleType.Crop
		studs.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end

	local body = skinsWindowData.Body

	-- 1. Action Row (Spin Wheel + Luck Upgrade)
	local actionRow = Instance.new("Frame")
	actionRow.Name = "ActionRow"
	actionRow.Size = UDim2.new(0.95, 0, 0, 38)
	actionRow.Position = UDim2.new(0.025, 0, 0, 10)
	actionRow.BackgroundTransparency = 1
	actionRow.ZIndex = 27
	actionRow.Parent = body

	-- Purple SPIN WHEEL button
	local btnSpinWheel = Instance.new("TextButton")
	btnSpinWheel.Name = "BtnSpinWheel"
	btnSpinWheel.Size = UDim2.new(0.485, 0, 1, 0)
	btnSpinWheel.Position = UDim2.new(0, 0, 0, 0)
	btnSpinWheel.Text = ""
	btnSpinWheel.AutoButtonColor = true
	btnSpinWheel.BackgroundColor3 = Color3.fromHex("#8B2BE2")
	btnSpinWheel.ZIndex = 28
	UITheme.applyGradient(btnSpinWheel, Color3.fromHex("#9B30FF"), Color3.fromHex("#7B1FA2"), 90)
	UITheme.addCorner(btnSpinWheel, 8)
	UITheme.applyStroke(btnSpinWheel, 2.5, Color3.new(0, 0, 0))
	UITheme.applyButtonStuds(btnSpinWheel, "purple")
	btnSpinWheel.Parent = actionRow

	local wheelIcon = Instance.new("ImageLabel")
	wheelIcon.Name = "Icon_Wheel"
	wheelIcon.Size = UDim2.fromOffset(26, 26)
	wheelIcon.Position = UDim2.new(0, 12, 0.5, 0)
	wheelIcon.AnchorPoint = Vector2.new(0, 0.5)
	wheelIcon.BackgroundTransparency = 1
	wheelIcon.Image = getAsset(UITheme.Assets.Icon_Wheel, "rbxassetid://139467358174721")
	wheelIcon.ScaleType = Enum.ScaleType.Fit
	wheelIcon.ZIndex = btnSpinWheel.ZIndex + 2
	wheelIcon.Parent = btnSpinWheel

	local spinLbl = Instance.new("TextLabel")
	spinLbl.Name = "BtnLabel"
	spinLbl.Size = UDim2.new(1, -44, 1, 0)
	spinLbl.Position = UDim2.new(0, 42, 0, 0)
	spinLbl.BackgroundTransparency = 1
	spinLbl.Font = Enum.Font.FredokaOne
	spinLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	spinLbl.Text = "SPIN WHEEL (0)"
	spinLbl.TextSize = 15
	spinLbl.ZIndex = btnSpinWheel.ZIndex + 2
	UITheme.applyTextStroke(spinLbl, 2.5, Color3.new(0, 0, 0))
	spinLbl.Parent = btnSpinWheel

	btnSpinWheel.Activated:Connect(function()
		UITheme.closeWindow(skinsWindow, function()
			modalBackdrop.Visible = false
			if openWheelFn then openWheelFn() end
		end)
	end)

	-- Green pill LUCK UPGRADE button
	local btnLuckUpgrade = Instance.new("TextButton")
	btnLuckUpgrade.Name = "BtnLuckUpgrade"
	btnLuckUpgrade.Size = UDim2.new(0.485, 0, 1, 0)
	btnLuckUpgrade.Position = UDim2.new(0.515, 0, 0, 0)
	btnLuckUpgrade.Text = ""
	btnLuckUpgrade.AutoButtonColor = true
	btnLuckUpgrade.BackgroundColor3 = Color3.fromHex("#22C55E")
	btnLuckUpgrade.ZIndex = 28
	UITheme.applyGradient(btnLuckUpgrade, Color3.fromHex("#22C55E"), Color3.fromHex("#15803D"), 90)
	UITheme.addCorner(btnLuckUpgrade, 8)
	UITheme.applyStroke(btnLuckUpgrade, 2.5, Color3.new(0, 0, 0))
	UITheme.applyButtonStuds(btnLuckUpgrade, "lime")
	btnLuckUpgrade.Parent = actionRow

	local cloverIcon = Instance.new("ImageLabel")
	cloverIcon.Name = "Icon_Clover"
	cloverIcon.Size = UDim2.fromOffset(26, 26)
	cloverIcon.Position = UDim2.new(0, 12, 0.5, 0)
	cloverIcon.AnchorPoint = Vector2.new(0, 0.5)
	cloverIcon.BackgroundTransparency = 1
	cloverIcon.Image = getAsset(UITheme.Assets.Icon_Luck, "rbxassetid://136598227301423")
	cloverIcon.ScaleType = Enum.ScaleType.Fit
	cloverIcon.ZIndex = btnLuckUpgrade.ZIndex + 2
	cloverIcon.Parent = btnLuckUpgrade

	local luckLbl = Instance.new("TextLabel")
	luckLbl.Name = "BtnLabel"
	luckLbl.Size = UDim2.new(1, -44, 1, 0)
	luckLbl.Position = UDim2.new(0, 42, 0, 0)
	luckLbl.BackgroundTransparency = 1
	luckLbl.Font = Enum.Font.FredokaOne
	luckLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	luckLbl.Text = "LUCK: 1x -> 1.5x ($750)"
	luckLbl.TextSize = 14
	luckLbl.ZIndex = btnLuckUpgrade.ZIndex + 2
	UITheme.applyTextStroke(luckLbl, 2.5, Color3.new(0, 0, 0))
	luckLbl.Parent = btnLuckUpgrade

	btnLuckUpgrade.Activated:Connect(function()
		Remotes.MetaAction:FireServer("UpgradeLuck")
	end)

	-- 2. Card Grid (6 Chairs: 3 columns x 2 rows, scrollable)
	local gridFrame = Instance.new("ScrollingFrame")
	gridFrame.Name = "CardGrid"
	gridFrame.Size = UDim2.new(0.95, 0, 1, -56)
	gridFrame.Position = UDim2.new(0.025, 0, 0, 50)
	gridFrame.BackgroundTransparency = 1
	gridFrame.BorderSizePixel = 0
	gridFrame.ScrollBarThickness = 5
	gridFrame.ScrollBarImageColor3 = Color3.fromHex("#333D52")
	gridFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	gridFrame.ElasticBehavior = Enum.ElasticBehavior.Always
	gridFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gridFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	gridFrame.ZIndex = 27
	gridFrame.Parent = body

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 2)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = gridFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.315, 0, 0, 168)
	gridLayout.CellPadding = UDim2.new(0.027, 0, 0, 10)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridFrame

	local skinAssets = {
		wood = getAsset(UITheme.Assets.Icon_Chair_ClassicWood, "rbxassetid://129157353051496"),
		stadium = getAsset(UITheme.Assets.Icon_Chair_StadiumBlue, "rbxassetid://115654234159991"),
		crimson = getAsset(UITheme.Assets.Icon_Chair_CrimsonStriker, "rbxassetid://102760649316701"),
		emerald = getAsset(UITheme.Assets.Icon_Chair_EmeraldPitch, "rbxassetid://107415959866387"),
		cyber = getAsset(UITheme.Assets.Icon_Chair_NeonCyber, "rbxassetid://107277780753566"),
		golden = getAsset(UITheme.Assets.Icon_Chair_Golden, "rbxassetid://85258960888640"),
	}

	local function formatBux(n: number): string
		local s = tostring(math.floor(n))
		local formatted = s:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
		return "     $" .. formatted .. " BUX"
	end

	local skinActionBtns: { [string]: TextButton } = {}

	local function applySkinButton(btn: TextButton, state: "EQUIPPED" | "EQUIP" | "BUY", cost: number)
		local cashIcon = btn:FindFirstChild("CashIcon") :: ImageLabel?
		if not cashIcon then
			cashIcon = Instance.new("ImageLabel")
			cashIcon.Name = "CashIcon"
			cashIcon.Size = UDim2.fromOffset(20, 20)
			cashIcon.Position = UDim2.new(0, 14, 0.5, 0)
			cashIcon.AnchorPoint = Vector2.new(0, 0.5)
			cashIcon.BackgroundTransparency = 1
			cashIcon.Image = getAsset(UITheme.Assets.Icon_CashCube, "rbxassetid://81844774538667")
			cashIcon.ScaleType = Enum.ScaleType.Fit
			cashIcon.ZIndex = btn.ZIndex + 2
			cashIcon.Parent = btn
		end

		local btnLbl = btn:FindFirstChild("BtnLabel") :: TextLabel?
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

		if state == "EQUIPPED" then
			if btnLbl then btnLbl.Text = "EQUIPPED" end
			btn.AutoButtonColor = false
			UITheme.applyGradient(btn, Color3.fromHex("#79BE13"), Color3.fromHex("#578C0E"), 90)
			UITheme.applyButtonStuds(btn, "lime")
			cashIcon.Visible = false
		elseif state == "EQUIP" then
			if btnLbl then btnLbl.Text = "EQUIP" end
			btn.AutoButtonColor = true
			UITheme.applyGradient(btn, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
			UITheme.applyButtonStuds(btn, "lime")
			cashIcon.Visible = false
		else
			if btnLbl then btnLbl.Text = formatBux(cost) end
			btn.AutoButtonColor = true
			UITheme.applyGradient(btn, Color3.fromHex("#FF9E16"), Color3.fromHex("#F07800"), 90)
			UITheme.applyButtonStuds(btn, "gold")
			cashIcon.Visible = true
		end
	end

	for i, skin in GameConfig.CHAIR_SKINS do
		local card = Instance.new("Frame")
		card.Name = "ChairCard_" .. skin.id
		card.LayoutOrder = i
		card.BackgroundColor3 = Color3.fromHex("#10131A")
		card.BackgroundTransparency = 0
		card.BorderSizePixel = 0
		card.ZIndex = 28
		card.ClipsDescendants = true
		UITheme.addCorner(card, 10)
		UITheme.applyStroke(card, 2, Color3.fromHex("#1E2430"))
		card.Parent = gridFrame

		-- Chair Name at top (warm creamy yellow)
		local displayName = skin.name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "SkinName"
		nameLbl.Size = UDim2.new(1, 0, 0, 22)
		nameLbl.Position = UDim2.new(0, 0, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextColor3 = Color3.fromHex("#FFE380")
		nameLbl.Text = displayName
		nameLbl.TextSize = 15
		nameLbl.ZIndex = card.ZIndex + 3
		UITheme.applyTextStroke(nameLbl, 2, Color3.new(0, 0, 0))
		nameLbl.Parent = card

		-- Center 3D Chair Viewport Preview
		createChairViewport(skin.id, card)

		-- Bottom Action Button
		local sBtn = Instance.new("TextButton")
		sBtn.Name = "BtnSkin_" .. skin.id
		sBtn.Size = UDim2.new(0.86, 0, 0.20, 0)
		sBtn.Position = UDim2.new(0.07, 0, 0.73, 0)
		sBtn.Text = ""
		sBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		sBtn.ZIndex = card.ZIndex + 4
		UITheme.addCorner(sBtn, 8)
		UITheme.applyStroke(sBtn, 2, Color3.new(0, 0, 0))
		sBtn.Parent = card

		local sBtnLbl = Instance.new("TextLabel")
		sBtnLbl.Name = "BtnLabel"
		sBtnLbl.Size = UDim2.fromScale(1, 1)
		sBtnLbl.BackgroundTransparency = 1
		sBtnLbl.Font = Enum.Font.FredokaOne
		sBtnLbl.TextSize = 14
		sBtnLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		sBtnLbl.ZIndex = sBtn.ZIndex + 1
		UITheme.applyTextStroke(sBtnLbl, 2, Color3.new(0, 0, 0))
		sBtnLbl.Parent = sBtn

		applySkinButton(sBtn, if skin.cost == 0 then "EQUIPPED" else "BUY", skin.cost)

		sBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyOrEquipChair", skin.id)
		end)

		skinActionBtns[skin.id] = sBtn
	end

	-- 3. Handler Methods
	local function open()
		modalBackdrop.Visible = true
		UITheme.openWindow(skinsWindow)
	end

	local function close()
		modalBackdrop.Visible = false
		UITheme.closeWindow(skinsWindow)
	end

	local function isOpen(): boolean
		return skinsWindow.Visible
	end

	local function update(profile: any)
		if not profile then return end
		-- Update Luck
		local curLuck = profile.Luck or 1
		local nextLuck = GameConfig.getNextLuckTier(curLuck)
		if nextLuck then
			luckLbl.Text = "LUCK: " .. curLuck .. "x -> " .. nextLuck.luck .. "x ($" .. nextLuck.cost .. ")"
		else
			luckLbl.Text = "LUCK: " .. curLuck .. "x (MAX)"
		end

		-- Update Spins
		local spins = profile.WheelSpins or profile.Spins or 0
		spinLbl.Text = "SPIN WHEEL (" .. spins .. ")"

		-- Update Chairs
		for _, skin in GameConfig.CHAIR_SKINS do
			local b = skinActionBtns[skin.id]
			if b then
				local owned = profile.OwnedChairs and profile.OwnedChairs[skin.id]
				if profile.EquippedChair == skin.id then
					applySkinButton(b, "EQUIPPED", skin.cost)
				elseif owned then
					applySkinButton(b, "EQUIP", skin.cost)
				else
					applySkinButton(b, "BUY", skin.cost)
				end
			end
		end
	end

	return {
		window = skinsWindow,
		open = open,
		close = close,
		isOpen = isOpen,
		update = update,
	}
end


function ShopDailyUI.initTitles(
	screenGui: ScreenGui,
	modalBackdrop: GuiObject,
	Remotes: any,
	UITheme: any,
	GameConfig: any
): TitlesHandler
	local function getAsset(id: string?, fallback: string): string
		if not id or id == "" or id == "rbxassetid://0" then
			return fallback
		end
		return id
	end

	local titlesWindowData = UITheme.window({
		name = "TitlesWindow",
		title = "TITLES",
		headerColors = UITheme.CONFIG.Headers.Titles,
		closeStyle = "magenta",
		headerHeightOffset = 50,
		size = UDim2.new(0, 620, 0, 440),
		parent = screenGui,
		onClose = function()
			modalBackdrop.Visible = false
		end,
	})
	local titlesWindow = titlesWindowData.Window
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(650, 480)
	sizeConstraint.MinSize = Vector2.new(460, 360)
	sizeConstraint.Parent = titlesWindow
	titlesWindow.ZIndex = 26
	titlesWindow.Visible = false

	-- Header Customization: Cyan Lego Studs + Bold White Text
	local header = titlesWindowData.Header
	local titleLbl = titlesWindowData.Title
	if titleLbl then
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.Text = "TITLES"
		titleLbl.TextSize = 26
		titleLbl.TextScaled = false
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Position = UDim2.new(0, 18, 0.5, 0)
		titleLbl.AnchorPoint = Vector2.new(0, 0.5)
		titleLbl.Size = UDim2.new(0.65, 0, 0.8, 0)
		titleLbl.BackgroundTransparency = 1
		local stroke = titleLbl:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", titleLbl)
		stroke.Thickness = 3.5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		local tConstraint = titleLbl:FindFirstChildOfClass("UITextSizeConstraint")
		if tConstraint then tConstraint:Destroy() end
	end
	local studs = header:FindFirstChild("Studs") :: ImageLabel?
	if studs then
		studs.Image = getAsset(UITheme.Assets.Header_Studs_Titles_Cyan, "rbxassetid://107818334023728")
		studs.ImageTransparency = 0
		studs.ScaleType = Enum.ScaleType.Crop
		studs.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end

	local body = titlesWindowData.Body

	-- Top Subheader: WINS: N (Bold Gold Text)
	local winsLabel = Instance.new("TextLabel")
	winsLabel.Name = "WinsIndicator"
	winsLabel.Size = UDim2.new(1, 0, 0, 24)
	winsLabel.Position = UDim2.new(0, 0, 0, 8)
	winsLabel.BackgroundTransparency = 1
	winsLabel.Font = Enum.Font.FredokaOne
	winsLabel.Text = "WINS: 0"
	winsLabel.TextSize = 18
	winsLabel.TextColor3 = Color3.fromHex("#FFD23A")
	winsLabel.ZIndex = 27
	UITheme.applyTextStroke(winsLabel, 2.5, Color3.new(0, 0, 0))
	winsLabel.Parent = body

	-- Titles List (Vertical scroll list)
	local titlesScroll = Instance.new("ScrollingFrame")
	titlesScroll.Name = "TitlesScrollingList"
	titlesScroll.Size = UDim2.new(0.95, 0, 1, -40)
	titlesScroll.Position = UDim2.new(0.025, 0, 0, 34)
	titlesScroll.BackgroundTransparency = 1
	titlesScroll.BorderSizePixel = 0
	titlesScroll.ScrollBarThickness = 4
	titlesScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 115, 140)
	titlesScroll.CanvasSize = UDim2.new(0, 0, 0, #GameConfig.TITLES * 68)
	titlesScroll.ZIndex = 27
	titlesScroll.Parent = body

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Parent = titlesScroll

	-- Sorted titles: Benchwarmer (0), Rookie (10), Starter (15), Captain (50), Legend (100)
	local sortedTitles = table.clone(GameConfig.TITLES)
	table.sort(sortedTitles, function(a, b)
		return a.minWins < b.minWins
	end)

	local titleActionBtns: { [string]: TextButton } = {}
	local titleRobuxBtns: { [string]: TextButton } = {}

	for idx, entry in sortedTitles do
		local row = Instance.new("Frame")
		row.Name = `TitleRow_{entry.name}`
		row.Size = UDim2.new(0.98, 0, 0, 58)
		row.BackgroundColor3 = Color3.fromHex("#10131A")
		row.BackgroundTransparency = 0
		row.BorderSizePixel = 0
		row.LayoutOrder = idx
		row.ZIndex = 28
		UITheme.addCorner(row, 8)
		UITheme.applyStroke(row, 2, Color3.fromHex("#1E2430"))
		row.Parent = titlesScroll

		-- Title Name on left with rarity color
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "TitleName"
		nameLbl.Size = UDim2.new(0.48, 0, 0.8, 0)
		nameLbl.Position = UDim2.new(0, 16, 0.5, 0)
		nameLbl.AnchorPoint = Vector2.new(0, 0.5)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.Text = entry.name
		nameLbl.TextSize = 20
		nameLbl.TextColor3 = entry.color or Color3.new(1, 1, 1)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.ZIndex = row.ZIndex + 2
		UITheme.applyTextStroke(nameLbl, 2.5, Color3.new(0, 0, 0))
		nameLbl.Parent = row

		-- Action Button: EQUIPPED / EQUIP / LOCKED (N)
		local tBtn = Instance.new("TextButton")
		tBtn.Name = `BtnAction_{entry.name}`
		tBtn.Size = UDim2.new(0.40, 0, 0.68, 0)
		tBtn.Position = UDim2.new(1, -12, 0.5, 0)
		tBtn.AnchorPoint = Vector2.new(1, 0.5)
		tBtn.Text = ""
		tBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		tBtn.AutoButtonColor = true
		tBtn.ZIndex = row.ZIndex + 3
		UITheme.addCorner(tBtn, 6)
		UITheme.applyStroke(tBtn, 2, Color3.new(0, 0, 0))
		tBtn.Parent = row

		local tBtnLbl = Instance.new("TextLabel")
		tBtnLbl.Name = "BtnLabel"
		tBtnLbl.Size = UDim2.fromScale(1, 1)
		tBtnLbl.BackgroundTransparency = 1
		tBtnLbl.Font = Enum.Font.FredokaOne
		tBtnLbl.TextSize = 14
		tBtnLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		tBtnLbl.ZIndex = tBtn.ZIndex + 1
		UITheme.applyTextStroke(tBtnLbl, 2, Color3.new(0, 0, 0))
		tBtnLbl.Parent = tBtn

		tBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("EquipTitle", entry.name)
		end)
		titleActionBtns[entry.name] = tBtn

		-- Robux Instant Unlock Button
		local rBtn = Instance.new("TextButton")
		rBtn.Name = `BtnRobux_{entry.name}`
		rBtn.Size = UDim2.fromOffset(38, 38)
		rBtn.Position = UDim2.new(1, -12, 0.5, 0)
		rBtn.AnchorPoint = Vector2.new(1, 0.5)
		rBtn.Text = ""
		rBtn.AutoButtonColor = true
		rBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		rBtn.ZIndex = row.ZIndex + 3
		rBtn.Visible = false
		UITheme.applyGradient(rBtn, Color3.fromHex("#A14DF0"), Color3.fromHex("#852BD5"), 90)
		UITheme.addCorner(rBtn, 6)
		UITheme.applyStroke(rBtn, 2, Color3.new(0, 0, 0))
		UITheme.applyButtonStuds(rBtn, "purple")
		rBtn.Parent = row

		local robuxIcon = Instance.new("ImageLabel")
		robuxIcon.Name = "Icon_Robux"
		robuxIcon.Size = UDim2.fromOffset(22, 22)
		robuxIcon.Position = UDim2.fromScale(0.5, 0.5)
		robuxIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		robuxIcon.BackgroundTransparency = 1
		robuxIcon.Image = getAsset(UITheme.Assets.Icon_Robux, "rbxassetid://91983626575198")
		robuxIcon.ScaleType = Enum.ScaleType.Fit
		robuxIcon.ZIndex = rBtn.ZIndex + 1
		robuxIcon.Parent = rBtn

		rBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyShopItem", "unlock_title_" .. string.lower(entry.name))
		end)
		titleRobuxBtns[entry.name] = rBtn
	end

	local function open()
		modalBackdrop.Visible = true
		UITheme.openWindow(titlesWindow)
	end

	local function close()
		modalBackdrop.Visible = false
		UITheme.closeWindow(titlesWindow)
	end

	local function isOpen(): boolean
		return titlesWindow.Visible
	end

	local function update(profile: any)
		if not profile then return end
		winsLabel.Text = `WINS: {profile.Wins or 0}`

		for _, entry in GameConfig.TITLES do
			local b = titleActionBtns[entry.name]
			local rBtn = titleRobuxBtns[entry.name]
			if b then
				local bLbl = b:FindFirstChild("BtnLabel") :: TextLabel?
				b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				if profile.EquippedTitle == entry.name then
					if bLbl then bLbl.Text = "EQUIPPED" end
					b.Size = UDim2.new(0.40, 0, 0.68, 0)
					b.Position = UDim2.new(1, -12, 0.5, 0)
					b.AutoButtonColor = false
					UITheme.applyGradient(b, Color3.fromHex("#79BE13"), Color3.fromHex("#578C0E"), 90)
					UITheme.applyButtonStuds(b, "lime")
					if rBtn then rBtn.Visible = false end
				elseif (profile.Wins or 0) >= entry.minWins then
					if bLbl then bLbl.Text = "EQUIP" end
					b.Size = UDim2.new(0.40, 0, 0.68, 0)
					b.Position = UDim2.new(1, -12, 0.5, 0)
					b.AutoButtonColor = true
					UITheme.applyGradient(b, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
					UITheme.applyButtonStuds(b, "lime")
					if rBtn then rBtn.Visible = false end
				else
					if bLbl then bLbl.Text = `LOCKED ({entry.minWins})` end
					b.Size = UDim2.new(0.32, 0, 0.68, 0)
					b.Position = UDim2.new(1, -56, 0.5, 0)
					b.AutoButtonColor = true
					UITheme.applyGradient(b, Color3.fromHex("#607085"), Color3.fromHex("#536277"), 90)
					UITheme.applyButtonStuds(b, "gray")
					if rBtn then
						rBtn.Visible = true
						rBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						UITheme.applyGradient(rBtn, Color3.fromHex("#A14DF0"), Color3.fromHex("#852BD5"), 90)
						UITheme.applyButtonStuds(rBtn, "purple")
					end
				end
			end
		end
	end

	return {
		window = titlesWindow,
		open = open,
		close = close,
		isOpen = isOpen,
		update = update,
	}
end

function ShopDailyUI.initDailyQuest(
	screenGui: ScreenGui,
	modalBackdrop: GuiObject,
	Remotes: any,
	UITheme: any,
	GameConfig: any
): QuestsHandler
	local questWindowData = UITheme.window({
		name = "QuestsWindow",
		title = "DAILY QUEST",
		headerColors = UITheme.CONFIG.Headers.DailyQuest,
		closeStyle = "magenta",
		headerHeightOffset = 50,
		size = UDim2.new(0, 680, 0, 460),
		parent = screenGui,
		onClose = function()
			modalBackdrop.Visible = false
		end,
	})
	local questsWindow = questWindowData.Window
	questsWindow.BackgroundColor3 = Color3.fromRGB(15, 23, 19)
	questsWindow.BackgroundTransparency = 0
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(720, 500)
	sizeConstraint.MinSize = Vector2.new(520, 380)
	sizeConstraint.Parent = questsWindow
	questsWindow.ZIndex = 26
	questsWindow.Visible = false

	-- Header Customization: Green Lego Studs + Centered White Title (NO dark green plate)
	local header = questWindowData.Header
	local titleLbl = questWindowData.Title
	if titleLbl then
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.Text = "DAILY QUEST"
		titleLbl.TextSize = 24
		titleLbl.TextScaled = false
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.TextXAlignment = Enum.TextXAlignment.Center
		titleLbl.Position = UDim2.new(0.5, 0, 0.5, 0)
		titleLbl.AnchorPoint = Vector2.new(0.5, 0.5)
		titleLbl.Size = UDim2.new(0.65, 0, 0.8, 0)
		titleLbl.BackgroundTransparency = 1
		local stroke = titleLbl:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", titleLbl)
		stroke.Thickness = 3.5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		local tConstraint = titleLbl:FindFirstChildOfClass("UITextSizeConstraint")
		if tConstraint then tConstraint:Destroy() end
	end
	local studs = header:FindFirstChild("Studs") :: ImageLabel?
	if studs then
		local greenAsset = UITheme.Assets and UITheme.Assets.Header_Studs_DailyQuest_Green or "rbxassetid://88180889470659"
		studs.Image = greenAsset
		studs.ImageTransparency = 0
		studs.ScaleType = Enum.ScaleType.Crop
		studs.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end

	local body = questWindowData.Body
	body.BackgroundColor3 = Color3.fromRGB(15, 23, 19)
	body.BackgroundTransparency = 0

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "QuestsScroll"
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromHex("#94A3B8")
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 27
	scroll.Parent = body

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 20)
	pad.PaddingRight = UDim.new(0, 20)
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.Parent = scroll

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 12)
	listLayout.Parent = scroll

	local questFills: { [string]: Frame } = {}
	local questProgLabels: { [string]: TextLabel } = {}
	local questClaimBtns: { [string]: TextButton } = {}
	local questBtnLabels: { [string]: TextLabel } = {}

	for i, q in GameConfig.QUESTS do
		local card = Instance.new("Frame")
		card.Name = `Card_{q.id}`
		card.Size = UDim2.new(1, 0, 0, 104)
		card.BackgroundColor3 = Color3.fromRGB(14, 30, 18)
		card.BackgroundTransparency = 0
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.ZIndex = 28
		UITheme.addCorner(card, 10)
		UITheme.applyStroke(card, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.attachCardHover(card, 1.02)
		card.Parent = scroll

		-- LEFT SECTION: Title & Progress Bar
		local leftWrap = Instance.new("Frame")
		leftWrap.Name = "LeftSection"
		leftWrap.Size = UDim2.new(0.60, 0, 1, -12)
		leftWrap.Position = UDim2.new(0, 14, 0, 6)
		leftWrap.BackgroundTransparency = 1
		leftWrap.ZIndex = card.ZIndex + 1
		leftWrap.Parent = card

		local qTitleLbl = Instance.new("TextLabel")
		qTitleLbl.Name = "QuestTitle"
		qTitleLbl.Size = UDim2.new(1, 0, 0, 44)
		qTitleLbl.Position = UDim2.new(0, 0, 0, 2)
		qTitleLbl.BackgroundTransparency = 1
		qTitleLbl.Font = Enum.Font.FredokaOne
		qTitleLbl.Text = q.title
		qTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		qTitleLbl.TextSize = 16
		qTitleLbl.TextWrapped = true
		qTitleLbl.TextXAlignment = Enum.TextXAlignment.Center
		qTitleLbl.ZIndex = leftWrap.ZIndex + 1
		UITheme.applyTextStroke(qTitleLbl, 2.5, Color3.fromRGB(0, 0, 0))
		qTitleLbl.Parent = leftWrap

		local progRail = Instance.new("Frame")
		progRail.Name = "ProgressRail"
		progRail.Size = UDim2.new(1, -10, 0, 32)
		progRail.Position = UDim2.new(0.5, 0, 1, -2)
		progRail.AnchorPoint = Vector2.new(0.5, 1)
		progRail.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
		progRail.BorderSizePixel = 0
		progRail.ZIndex = leftWrap.ZIndex + 1
		UITheme.addCorner(progRail, 8)
		UITheme.applyStroke(progRail, 2, Color3.fromRGB(0, 0, 0))
		progRail.Parent = leftWrap

		local progFill = Instance.new("Frame")
		progFill.Name = "Fill"
		progFill.Size = UDim2.fromScale(0, 1)
		progFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		progFill.BorderSizePixel = 0
		progFill.ZIndex = progRail.ZIndex + 1
		UITheme.addCorner(progFill, 7)
		UITheme.applyGradient(progFill, Color3.fromHex("#84CC16"), Color3.fromHex("#4D7C0F"), 90)
		progFill.Parent = progRail
		questFills[q.id] = progFill

		local progLbl = Instance.new("TextLabel")
		progLbl.Name = "ProgLabel"
		progLbl.Size = UDim2.fromScale(1, 1)
		progLbl.BackgroundTransparency = 1
		progLbl.Font = Enum.Font.FredokaOne
		progLbl.Text = `0/{q.target}`
		progLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		progLbl.TextSize = 16
		progLbl.ZIndex = progRail.ZIndex + 2
		UITheme.applyTextStroke(progLbl, 2, Color3.fromRGB(0, 0, 0))
		progLbl.Parent = progRail
		questProgLabels[q.id] = progLbl

		-- RIGHT SECTION: 'REWARD', reward display, and CLAIM button
		local rightWrap = Instance.new("Frame")
		rightWrap.Name = "RightSection"
		rightWrap.Size = UDim2.new(0.36, 0, 1, -12)
		rightWrap.Position = UDim2.new(1, -14, 0, 6)
		rightWrap.AnchorPoint = Vector2.new(1, 0)
		rightWrap.BackgroundTransparency = 1
		rightWrap.ZIndex = card.ZIndex + 1
		rightWrap.Parent = card

		local rewardHeader = Instance.new("TextLabel")
		rewardHeader.Name = "RewardHeader"
		rewardHeader.Size = UDim2.new(1, 0, 0, 16)
		rewardHeader.Position = UDim2.new(0, 0, 0, 2)
		rewardHeader.BackgroundTransparency = 1
		rewardHeader.Font = Enum.Font.FredokaOne
		rewardHeader.Text = "REWARD"
		rewardHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
		rewardHeader.TextSize = 13
		rewardHeader.ZIndex = rightWrap.ZIndex + 1
		UITheme.applyTextStroke(rewardHeader, 2, Color3.fromRGB(0, 0, 0))
		rewardHeader.Parent = rightWrap

		local rewardItemsWrap = Instance.new("Frame")
		rewardItemsWrap.Name = "RewardItems"
		rewardItemsWrap.Size = UDim2.new(1, 0, 0, 22)
		rewardItemsWrap.Position = UDim2.new(0, 0, 0, 20)
		rewardItemsWrap.BackgroundTransparency = 1
		rewardItemsWrap.ZIndex = rightWrap.ZIndex + 1
		rewardItemsWrap.Parent = rightWrap

		local rList = Instance.new("UIListLayout")
	rList.FillDirection = Enum.FillDirection.Horizontal
	rList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rList.VerticalAlignment = Enum.VerticalAlignment.Center
	rList.SortOrder = Enum.SortOrder.LayoutOrder
	rList.Padding = UDim.new(0, 5)
	rList.Parent = rewardItemsWrap

		if q.spins and q.spins > 0 then
			local spinImg = Instance.new("ImageLabel")
			spinImg.Name = "SpinIcon"
			spinImg.Size = UDim2.fromOffset(22, 22)
			spinImg.BackgroundTransparency = 1
			spinImg.Image = UITheme.Assets.Icon_Wheel
			spinImg.ScaleType = Enum.ScaleType.Fit
			spinImg.LayoutOrder = 1
			spinImg.ZIndex = rewardItemsWrap.ZIndex + 1
			spinImg.Parent = rewardItemsWrap
		end

		if q.bux and q.bux > 0 then
			local cashImg = Instance.new("ImageLabel")
			cashImg.Name = "CashIcon"
			cashImg.Size = UDim2.fromOffset(24, 20)
			cashImg.BackgroundTransparency = 1
			cashImg.Image = UITheme.Assets.Icon_CashCube
			cashImg.ScaleType = Enum.ScaleType.Fit
			cashImg.LayoutOrder = 2
			cashImg.ZIndex = rewardItemsWrap.ZIndex + 1
			cashImg.Parent = rewardItemsWrap
		end

		local rText = Instance.new("TextLabel")
		rText.Name = "RewardText"
		rText.Size = UDim2.new(0, 0, 1, 0)
		rText.AutomaticSize = Enum.AutomaticSize.X
		rText.BackgroundTransparency = 1
		rText.Font = Enum.Font.FredokaOne
		rText.TextColor3 = Color3.fromRGB(255, 255, 255)
		rText.TextSize = 13
		rText.LayoutOrder = 3
		rText.ZIndex = rewardItemsWrap.ZIndex + 1
		UITheme.applyTextStroke(rText, 2, Color3.fromRGB(0, 0, 0))
		if (q.spins or 0) > 0 and (q.bux or 0) > 0 then
			rText.Text = `{q.spins} Spin + ${q.bux}`
		elseif (q.bux or 0) > 0 then
			rText.Text = `${q.bux} Bux`
		else
			rText.Text = q.rewardLabel or ""
		end
		rText.Parent = rewardItemsWrap

		-- CLAIM Button
		local cBtn = Instance.new("TextButton")
		cBtn.Name = `BtnClaim_{q.id}`
		cBtn.Size = UDim2.new(1, 0, 0, 36)
		cBtn.Position = UDim2.new(0.5, 0, 1, -2)
		cBtn.AnchorPoint = Vector2.new(0.5, 1)
		cBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		cBtn.AutoButtonColor = false
		cBtn.Text = ""
		cBtn.ZIndex = rightWrap.ZIndex + 2
		UITheme.addCorner(cBtn, 8)
		UITheme.applyStroke(cBtn, 2.5, Color3.fromRGB(0, 0, 0))
		UITheme.applyButtonStuds(cBtn, "brown")
		cBtn.Parent = rightWrap
		questClaimBtns[q.id] = cBtn

		local cBtnLbl = Instance.new("TextLabel")
		cBtnLbl.Name = "BtnLabel"
		cBtnLbl.Size = UDim2.fromScale(1, 1)
		cBtnLbl.BackgroundTransparency = 1
		cBtnLbl.Font = Enum.Font.FredokaOne
		cBtnLbl.Text = "CLAIM"
		cBtnLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		cBtnLbl.TextSize = 16
		cBtnLbl.ZIndex = cBtn.ZIndex + 1
		UITheme.applyTextStroke(cBtnLbl, 2.5, Color3.fromRGB(0, 0, 0))
		cBtnLbl.Parent = cBtn
		questBtnLabels[q.id] = cBtnLbl

		cBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("ClaimQuest", q.id)
		end)
	end

	local function open()
		modalBackdrop.Visible = true
		UITheme.openWindow(questsWindow)
	end

	local function close()
		UITheme.closeWindow(questsWindow, function()
			modalBackdrop.Visible = false
		end)
	end

	local function isOpen(): boolean
		return questsWindow.Visible
	end

	local function update(p: any): number
		local readyCount = 0
		if not p then return 0 end

		for _, q in GameConfig.QUESTS do
			local prog = math.min(q.target, (p.QuestProgress and p.QuestProgress[q.id]) or 0)
			local claimed = p.QuestClaimed and p.QuestClaimed[q.id]
			local isComplete = prog >= q.target

			local fill = questFills[q.id]
			local pLbl = questProgLabels[q.id]
			if fill then
				local frac = math.clamp(prog / q.target, 0, 1)
				fill.Size = UDim2.fromScale(frac, 1)
			end
			if pLbl then
				pLbl.Text = `{prog}/{q.target}`
			end

			local btn = questClaimBtns[q.id]
			local bLbl = questBtnLabels[q.id]
			if btn and bLbl then
				btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				if claimed then
					bLbl.Text = "✓ CLAIMED"
					bLbl.TextColor3 = Color3.fromHex("#CBD5E1")
					UITheme.applyGradient(btn, Color3.fromHex("#607085"), Color3.fromHex("#475569"), 90)
					UITheme.applyButtonStuds(btn, "gray")
					btn.AutoButtonColor = false
				elseif isComplete then
					bLbl.Text = "CLAIM!"
					bLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
					UITheme.applyGradient(btn, Color3.fromHex("#66D218"), Color3.fromHex("#48A80E"), 90)
					UITheme.applyButtonStuds(btn, "lime")
					btn.AutoButtonColor = true
					UITheme.addPulse(btn)
					readyCount += 1
				else
					bLbl.Text = "CLAIM"
					bLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
					UITheme.applyGradient(btn, Color3.fromHex("#8A4A15"), Color3.fromHex("#5C300A"), 90)
					UITheme.applyButtonStuds(btn, "brown")
					btn.AutoButtonColor = false
				end
			end
		end

		return readyCount
	end

	return {
		window = questsWindow,
		open = open,
		close = close,
		isOpen = isOpen,
		update = update,
	}
end

ShopDailyUI.initQuests = ShopDailyUI.initDailyQuest

function ShopDailyUI.initCardIndex(
	screenGui: ScreenGui,
	modalBackdrop: GuiObject,
	UITheme: any,
	GameConfig: any,
	Footballers: any,
	FootballerModelBuilder: any
): CardIndexHandler
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	local cfg = (UITheme.CONFIG and UITheme.CONFIG.CardIndex) or {
		SHOW_PROGRESS_BAR = false,
		CARD_ASPECT = 1.0,
		HOOK_FILTERS = false,
		SHOW_LOCKED_TEXT = false,
		SHIMMER_RARITIES = { Mythic = true, Legendary = true },
		RARITY_COLORS = {
			Mythic = Color3.fromHex("#F0408C"),
			Legendary = Color3.fromHex("#FFD21F"),
			Epic = Color3.fromHex("#A855F7"),
			Rare = Color3.fromHex("#34B6FF"),
			Common = Color3.fromHex("#A0A8B8"),
			Fallback = Color3.fromHex("#6B7A99"),
		},
	}

	local function getRarityColor(rarity: string): Color3
		return (cfg.RARITY_COLORS and cfg.RARITY_COLORS[rarity])
			or (GameConfig.RARITY_COLORS and GameConfig.RARITY_COLORS[rarity])
			or (cfg.RARITY_COLORS and cfg.RARITY_COLORS.Fallback)
			or Color3.fromHex("#6B7A99")
	end

	-- Read ordered cards from existing data (Mythic -> Common)
	local orderedCards: { any } = {}
	for rIdx = #GameConfig.RARITY_ORDER, 1, -1 do
		local rarity = GameConfig.RARITY_ORDER[rIdx]
		local bucket = Footballers.ByRarity and Footballers.ByRarity[rarity]
		if bucket then
			for _, card in bucket do
				table.insert(orderedCards, card)
			end
		end
	end
	local totalCards = #orderedCards

	-- Window: 1.65:1 aspect, pink-magenta header (#F2459A -> #C8186F) + studs, RED close button
	local winData = UITheme.window({
		name = "CardIndexWindow",
		title = `CARD INDEX ({totalCards} FOOTBALLERS)`,
		headerColors = (UITheme.CONFIG.Headers and UITheme.CONFIG.Headers.CardIndex) or {
			Top = Color3.fromHex("#F2459A"),
			Bottom = Color3.fromHex("#C8186F"),
		},
		closeStyle = "red",
		size = UDim2.fromScale(0.76, 0.78),
		aspect = 1.65,
		parent = screenGui,
		onClose = function()
			modalBackdrop.Visible = false
		end,
	})
	local indexWindow = winData.Window
	indexWindow.ZIndex = 26
	indexWindow.Visible = false
	winData.Header.ZIndex = 27
	winData.Title.ZIndex = 29
	winData.Title.Size = UDim2.new(0.84, 0, UITheme.CONFIG.HEADER_TITLE_HEIGHT_SCALE, 0)
	UITheme.addTextConstraint(winData.Title, 18, 36)
	winData.Close.ZIndex = 31
	local hStuds = winData.Header:FindFirstChild("Studs")
	if hStuds and hStuds:IsA("ImageLabel") then
		local studAsset = UITheme.Assets and (UITheme.Assets.Header_Studs_CardIndex_Pink or UITheme.Assets.Header_Studs_Shop_Red)
		hStuds.Image = if studAsset and studAsset ~= "" and studAsset ~= "rbxassetid://0" then studAsset else "rbxassetid://128225868192722"
		hStuds.ImageTransparency = 0
		hStuds.ScaleType = Enum.ScaleType.Crop
		hStuds.ImageColor3 = Color3.fromRGB(255, 255, 255)
		hStuds.ZIndex = 28
	end
	local hBorder = winData.Header:FindFirstChild("BottomBorder")
	if hBorder and hBorder:IsA("GuiObject") then hBorder.ZIndex = 30 end
	local cStuds = winData.Close:FindFirstChild("Studs")
	if cStuds and cStuds:IsA("ImageLabel") then
		cStuds.ZIndex = 31
		cStuds.ImageTransparency = 0.82
	end
	local closeLabel = Instance.new("TextLabel")
	closeLabel.Name = "XLabel"
	closeLabel.Size = UDim2.fromScale(0.82, 0.82)
	closeLabel.Position = UDim2.fromScale(0.5, 0.5)
	closeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	closeLabel.BackgroundTransparency = 1
	closeLabel.Font = UITheme.CONFIG.Font
	closeLabel.Text = "X"
	closeLabel.TextColor3 = UITheme.CONFIG.Colors.White
	closeLabel.TextScaled = true
	closeLabel.ZIndex = 33
	UITheme.applyTextStroke(closeLabel, UITheme.CONFIG.TEXT_STROKE_LARGE, UITheme.CONFIG.Colors.Outline)
	closeLabel.Parent = winData.Close
	winData.Close.Text = ""

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(420, 280)
	sizeConstraint.MaxSize = Vector2.new(960, 600)
	sizeConstraint.Parent = indexWindow

	local body = winData.Body
	body.ZIndex = 27
	local bStuds = body:FindFirstChild("Studs")
	if bStuds and bStuds:IsA("GuiObject") then bStuds.ZIndex = 27 end

	-- Subtitle strip directly under header (~8% of window height = ~9.4% of body height)
	local subBar = Instance.new("Frame")
	subBar.Name = "SubtitleStrip"
	subBar.Size = UDim2.fromScale(1, 0.094)
	subBar.Position = UDim2.fromScale(0, 0)
	subBar.BackgroundColor3 = Color3.fromHex("#090B10")
	subBar.BackgroundTransparency = 0.35
	subBar.BorderSizePixel = 0
	subBar.ZIndex = body.ZIndex + 1
	subBar.Parent = body

	local subBottomLine = Instance.new("Frame")
	subBottomLine.Name = "BottomDivider"
	subBottomLine.Size = UDim2.new(1, 0, 0, 2)
	subBottomLine.Position = UDim2.new(0, 0, 1, -2)
	subBottomLine.BackgroundColor3 = UITheme.CONFIG.Colors.Outline
	subBottomLine.BorderSizePixel = 0
	subBottomLine.ZIndex = subBar.ZIndex + 1
	subBottomLine.Parent = subBar

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "SubtitleText"
	subLabel.Size = UDim2.fromScale(0.94, 0.78)
	subLabel.Position = UDim2.fromScale(0.5, 0.5)
	subLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = UITheme.CONFIG.Font
	subLabel.Text = `DISCOVERED: 0 / {totalCards} (0%) • +$25–$250 PER NEW CARD!`
	subLabel.TextColor3 = Color3.fromHex("#FFD21F")
	subLabel.TextScaled = true
	subLabel.TextWrapped = false
	subLabel.ZIndex = subBar.ZIndex + 2
	UITheme.applyTextStroke(subLabel, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)
	UITheme.addTextConstraint(subLabel, 14, 24)
	subLabel.Parent = subBar

	local progBarObj: { Rail: Frame, Fill: Frame, Update: (number, number) -> () }? = nil
	local scrollTopScale = 0.105
	if cfg.SHOW_PROGRESS_BAR then
		progBarObj = UITheme.progressBar(
			body,
			0,
			totalCards,
			UDim2.fromScale(0.96, 0.032),
			UDim2.fromScale(0.02, 0.102),
			UITheme.CONFIG.Colors.LimeTop
		)
		scrollTopScale = 0.145
	end

	-- Virtualized Grid ScrollingFrame (Theme.scroll = thin light scrollbar)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "CardGridScroll"
	scroll.Size = UDim2.fromScale(0.98, 1 - scrollTopScale - 0.015)
	scroll.Position = UDim2.fromScale(0.01, scrollTopScale)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ZIndex = body.ZIndex + 2
	UITheme.scroll(scroll)
	scroll.Parent = body

	-- Virtualization state & pool
	local discoveredMap: { [string]: boolean } = {}
	local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

	type CardSlot = {
		outer: Frame,
		uiScale: UIScale,
		innerStroke: UIStroke,
		bottomTint: Frame,
		shimmerOverlay: Frame,
		shimmerGrad: UIGradient,
		posText: TextLabel,
		lockIcon: ImageLabel,
		lockedText: TextLabel,
		sunburst: ImageLabel,
		silImage: ImageLabel,
		viewport: ViewportFrame,
		vpModel: Model?,
		vpCardId: string?,
		nameLabel: TextLabel,
		rarityLabel: TextLabel,
		boundIndex: number?,
		isShimmering: boolean,
	}

	local slotPool: { CardSlot } = {}
	local activeByIndex: { [number]: CardSlot } = {}

	local function createSlot(poolId: number): CardSlot
		local outer = Instance.new("Frame")
		outer.Name = `CardSlot_{poolId}`
		outer.BackgroundColor3 = Color3.fromHex("#0D0F14")
		outer.BackgroundTransparency = 0.35
		outer.BorderSizePixel = 0
		outer.Visible = false
		outer.ZIndex = scroll.ZIndex + 1
		UITheme.addCorner(outer, UITheme.CONFIG.CARD_CORNER_RADIUS)
		UITheme.applyStroke(outer, UITheme.CONFIG.CARD_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)

		local uiScale = Instance.new("UIScale")
		uiScale.Scale = 1.0
		uiScale.Parent = outer

		-- Inner rarity frame: inset ~4%, 2px UIStroke in rarity color
		local inner = Instance.new("Frame")
		inner.Name = "InnerRarityFrame"
		inner.Size = UDim2.fromScale(0.92, 0.92)
		inner.Position = UDim2.fromScale(0.5, 0.5)
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.BackgroundTransparency = 1
		inner.ClipsDescendants = true
		inner.ZIndex = outer.ZIndex + 1
		UITheme.addCorner(inner, 3)
		local innerStroke = UITheme.applyStroke(inner, 2, Color3.fromHex("#6B7A99"))
		inner.Parent = outer

		-- Soft vertical rarity-tinted gradient at the bottom third (~25% opacity -> 0.75 transparency)
		local bottomTint = Instance.new("Frame")
		bottomTint.Name = "BottomRarityTint"
		bottomTint.Size = UDim2.fromScale(1, 0.36)
		bottomTint.Position = UDim2.fromScale(0, 0.64)
		bottomTint.BackgroundColor3 = Color3.fromHex("#FFFFFF")
		bottomTint.BorderSizePixel = 0
		bottomTint.ZIndex = inner.ZIndex
		local tintGrad = Instance.new("UIGradient")
		tintGrad.Rotation = 90
		tintGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.0),
			NumberSequenceKeypoint.new(1, 0.72),
		})
		tintGrad.Parent = bottomTint
		bottomTint.Parent = inner

		-- Shimmer overlay for discovered Mythic/Legendary cards
		local shimmerOverlay = Instance.new("Frame")
		shimmerOverlay.Name = "ShimmerSweep"
		shimmerOverlay.Size = UDim2.fromScale(1, 1)
		shimmerOverlay.BackgroundColor3 = Color3.fromHex("#FFFFFF")
		shimmerOverlay.BorderSizePixel = 0
		shimmerOverlay.Visible = false
		shimmerOverlay.ZIndex = inner.ZIndex + 6
		local shimmerGrad = Instance.new("UIGradient")
		shimmerGrad.Rotation = 35
		shimmerGrad.Offset = Vector2.new(-1.2, 0)
		shimmerGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.0),
			NumberSequenceKeypoint.new(0.42, 1.0),
			NumberSequenceKeypoint.new(0.50, 0.68),
			NumberSequenceKeypoint.new(0.58, 1.0),
			NumberSequenceKeypoint.new(1.00, 1.0),
		})
		shimmerGrad.Parent = shimmerOverlay
		shimmerOverlay.Parent = inner

		-- Position chip: top-left, small dark rounded rectangle (black 2px border), white bold text, stroke 2
		local posChip = Instance.new("Frame")
		posChip.Name = "PositionChip"
		posChip.Size = UDim2.fromScale(0.28, 0.16)
		posChip.Position = UDim2.fromScale(0.05, 0.05)
		posChip.BackgroundColor3 = Color3.fromHex("#12151E")
		posChip.BackgroundTransparency = 0.1
		posChip.BorderSizePixel = 0
		posChip.ZIndex = inner.ZIndex + 4
		UITheme.addCorner(posChip, 3)
		UITheme.applyStroke(posChip, 2, UITheme.CONFIG.Colors.Outline)
		posChip.Parent = inner

		local posText = Instance.new("TextLabel")
		posText.Name = "PosText"
		posText.Size = UDim2.fromScale(0.90, 0.86)
		posText.Position = UDim2.fromScale(0.5, 0.5)
		posText.AnchorPoint = Vector2.new(0.5, 0.5)
		posText.BackgroundTransparency = 1
		posText.Font = UITheme.CONFIG.Font
		posText.Text = "ST"
		posText.TextColor3 = UITheme.CONFIG.Colors.White
		posText.TextScaled = true
		posText.TextWrapped = false
		posText.ZIndex = posChip.ZIndex + 1
		UITheme.applyTextStroke(posText, UITheme.CONFIG.TEXT_STROKE_SMALL, UITheme.CONFIG.Colors.Outline)
		UITheme.addTextConstraint(posText, 11, 18)
		posText.Parent = posChip

		-- Top-right: Icon_Lock (orange padlock, ~16% of card width) when locked
		local lockIcon = Instance.new("ImageLabel")
		lockIcon.Name = "Icon_Lock"
		lockIcon.Size = UDim2.fromScale(0.16, 0.16)
		lockIcon.SizeConstraint = Enum.SizeConstraint.RelativeXX
		lockIcon.Position = UDim2.fromScale(0.95, 0.05)
		lockIcon.AnchorPoint = Vector2.new(1, 0)
		lockIcon.BackgroundTransparency = 1
		local lockAsset = UITheme.Assets.Icon_Lock
		if not lockAsset or lockAsset == "" or lockAsset == "rbxassetid://0" then
			lockAsset = "rbxassetid://6031082533"
		end
		lockIcon.Image = lockAsset
		lockIcon.ImageColor3 = Color3.fromHex("#FF9A1F")
		lockIcon.ScaleType = Enum.ScaleType.Fit
		lockIcon.ZIndex = inner.ZIndex + 4
		lockIcon.Parent = inner

		-- Optional SHOW_LOCKED_TEXT small gray line
		local lockedText = Instance.new("TextLabel")
		lockedText.Name = "LockedText"
		lockedText.Size = UDim2.fromScale(0.42, 0.10)
		lockedText.Position = UDim2.fromScale(0.95, 0.22)
		lockedText.AnchorPoint = Vector2.new(1, 0)
		lockedText.BackgroundTransparency = 1
		lockedText.Font = UITheme.CONFIG.Font
		lockedText.Text = "LOCKED"
		lockedText.TextColor3 = Color3.fromHex("#94A3B8")
		lockedText.TextScaled = true
		lockedText.TextWrapped = false
		lockedText.TextXAlignment = Enum.TextXAlignment.Right
		lockedText.Visible = false
		lockedText.ZIndex = inner.ZIndex + 4
		UITheme.applyTextStroke(lockedText, UITheme.CONFIG.TEXT_STROKE_SMALL, UITheme.CONFIG.Colors.Outline)
		UITheme.addTextConstraint(lockedText, 7, 12)
		lockedText.Parent = inner

		-- Center art area (~50% of card height)
		local artArea = Instance.new("Frame")
		artArea.Name = "ArtArea"
		artArea.Size = UDim2.fromScale(0.88, 0.50)
		artArea.Position = UDim2.fromScale(0.5, 0.18)
		artArea.AnchorPoint = Vector2.new(0.5, 0)
		artArea.BackgroundTransparency = 1
		artArea.ZIndex = inner.ZIndex + 1
		artArea.Parent = inner

		-- Soft rarity-colored glow behind art (STATIC sunburst, low alpha)
		local sunburst = Instance.new("ImageLabel")
		sunburst.Name = "Sunburst"
		sunburst.Size = UDim2.fromScale(0.95, 0.95)
		sunburst.Position = UDim2.fromScale(0.5, 0.5)
		sunburst.AnchorPoint = Vector2.new(0.5, 0.5)
		sunburst.BackgroundTransparency = 1
		sunburst.Image = UITheme.Assets.SunburstTexture
		sunburst.ImageTransparency = 0.62
		sunburst.ScaleType = Enum.ScaleType.Fit
		sunburst.ZIndex = artArea.ZIndex
		sunburst.Parent = artArea

		-- Optional 2D Icon_Silhouette slot if configured
		local silImage = Instance.new("ImageLabel")
		silImage.Name = "Icon_Silhouette"
		silImage.Size = UDim2.fromScale(0.82, 0.92)
		silImage.Position = UDim2.fromScale(0.5, 0.5)
		silImage.AnchorPoint = Vector2.new(0.5, 0.5)
		silImage.BackgroundTransparency = 1
		silImage.Image = UITheme.Assets.Icon_Silhouette or "rbxassetid://0"
		silImage.ImageColor3 = Color3.new(0, 0, 0)
		silImage.ScaleType = Enum.ScaleType.Fit
		silImage.Visible = false
		silImage.ZIndex = artArea.ZIndex + 2
		silImage.Parent = artArea

		-- 3D Blocky Footballer Viewport (renders flat black silhouette when LOCKED, full color when DISCOVERED)
		local viewport = Instance.new("ViewportFrame")
		viewport.Name = "CardArtViewport"
		viewport.Size = UDim2.fromScale(1, 1)
		viewport.Position = UDim2.fromScale(0.5, 0.5)
		viewport.AnchorPoint = Vector2.new(0.5, 0.5)
		viewport.BackgroundTransparency = 1
		viewport.LightColor = Color3.new(1, 1, 1)
		viewport.Ambient = Color3.fromRGB(190, 198, 212)
		viewport.LightDirection = Vector3.new(-0.4, -0.7, 0.65)
		viewport.ZIndex = artArea.ZIndex + 2
		viewport.Parent = artArea

		local vpCam = Instance.new("Camera")
		vpCam.FieldOfView = 35
		vpCam.CFrame = CFrame.lookAt(Vector3.new(0.65, 0.78, -7.2), Vector3.new(0, 0.60, 0))
		vpCam.Parent = viewport
		viewport.CurrentCamera = vpCam

		-- Name line: LOCKED "???", DISCOVERED footballer's name; white, black stroke 3, TextScaled, max 2 lines, ~16% height
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.fromScale(0.88, 0.16)
		nameLabel.Position = UDim2.fromScale(0.5, 0.69)
		nameLabel.AnchorPoint = Vector2.new(0.5, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = UITheme.CONFIG.Font
		nameLabel.Text = "???"
		nameLabel.TextColor3 = UITheme.CONFIG.Colors.White
		nameLabel.TextScaled = true
		nameLabel.TextWrapped = true
		nameLabel.ZIndex = inner.ZIndex + 3
		UITheme.applyTextStroke(nameLabel, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)
		UITheme.addTextConstraint(nameLabel, 11, 20)
		nameLabel.Parent = inner

		-- Rarity label at bottom: rarity name in rarity color, black stroke 3, uppercase, ~11% height
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Name = "RarityLabel"
		rarityLabel.Size = UDim2.fromScale(0.88, 0.11)
		rarityLabel.Position = UDim2.fromScale(0.5, 0.86)
		rarityLabel.AnchorPoint = Vector2.new(0.5, 0)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Font = UITheme.CONFIG.Font
		rarityLabel.Text = "MYTHIC"
		rarityLabel.TextScaled = true
		rarityLabel.TextWrapped = false
		rarityLabel.ZIndex = inner.ZIndex + 3
		UITheme.applyTextStroke(rarityLabel, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)
		UITheme.addTextConstraint(rarityLabel, 11, 17)
		rarityLabel.Parent = inner

		-- Hover/press: scale 1.04 / 0.96 on PC; touch no hover
		if not isTouchDevice then
			outer.MouseEnter:Connect(function()
				TweenService:Create(
					uiScale,
					TweenInfo.new(UITheme.CONFIG.HOVER_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Scale = UITheme.CONFIG.HOVER_SCALE }
				):Play()
			end)
			outer.MouseLeave:Connect(function()
				TweenService:Create(
					uiScale,
					TweenInfo.new(UITheme.CONFIG.HOVER_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Scale = 1.0 }
				):Play()
			end)
		end

		outer.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(
					uiScale,
					TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Scale = UITheme.CONFIG.PRESS_SCALE }
				):Play()
			end
		end)
		outer.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(
					uiScale,
					TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Scale = 1.0 }
				):Play()
			end
		end)

		outer.Parent = scroll

		return {
			outer = outer,
			uiScale = uiScale,
			innerStroke = innerStroke,
			bottomTint = bottomTint,
			shimmerOverlay = shimmerOverlay,
			shimmerGrad = shimmerGrad,
			posText = posText,
			lockIcon = lockIcon,
			lockedText = lockedText,
			sunburst = sunburst,
			silImage = silImage,
			viewport = viewport,
			vpModel = nil,
			vpCardId = nil,
			nameLabel = nameLabel,
			rarityLabel = rarityLabel,
			boundIndex = nil,
			isShimmering = false,
		}
	end

	local function bindSlotToCard(slot: CardSlot, idx: number, card: any)
		slot.boundIndex = idx
		local isDiscovered = discoveredMap[card.id] == true
		local rCol = getRarityColor(card.rarity)

		slot.innerStroke.Color = rCol
		slot.bottomTint.BackgroundColor3 = rCol
		slot.sunburst.ImageColor3 = rCol

		slot.posText.Text = card.pos
		slot.lockIcon.Visible = not isDiscovered
		slot.lockedText.Visible = (not isDiscovered) and (cfg.SHOW_LOCKED_TEXT == true)

		slot.nameLabel.Text = if isDiscovered then Footballers.getDisplayName(card) else "???"
		slot.rarityLabel.Text = string.upper(card.rarity)
		slot.rarityLabel.TextColor3 = rCol

		local use2DSil = (not isDiscovered)
			and UITheme.Assets.Icon_Silhouette
			and UITheme.Assets.Icon_Silhouette ~= ""
			and UITheme.Assets.Icon_Silhouette ~= "rbxassetid://0"

		if use2DSil then
			slot.silImage.Image = UITheme.Assets.Icon_Silhouette
			slot.silImage.Visible = true
			slot.viewport.Visible = false
		else
			slot.silImage.Visible = false
			slot.viewport.Visible = true
			if slot.vpCardId ~= card.id or not slot.vpModel then
				if slot.vpModel then
					slot.vpModel:Destroy()
					slot.vpModel = nil
				end
				slot.vpCardId = card.id
				if FootballerModelBuilder and FootballerModelBuilder.cloneModel then
					local m = FootballerModelBuilder.cloneModel(card.id)
					if m then
						m.Parent = slot.viewport
						slot.vpModel = m
					end
				end
			end
			if isDiscovered then
				slot.viewport.ImageColor3 = Color3.new(1, 1, 1)
				slot.viewport.Ambient = Color3.fromRGB(190, 198, 212)
				slot.viewport.LightColor = Color3.new(1, 1, 1)
			else
				-- Flat black silhouette of the blocky footballer
				slot.viewport.ImageColor3 = Color3.new(0, 0, 0)
				slot.viewport.Ambient = Color3.new(0, 0, 0)
				slot.viewport.LightColor = Color3.new(0, 0, 0)
			end
		end

		local canShimmer = isDiscovered and cfg.SHIMMER_RARITIES and cfg.SHIMMER_RARITIES[card.rarity] == true
		slot.isShimmering = canShimmer
		slot.shimmerOverlay.Visible = canShimmer
	end

	local function refreshVirtualGrid(forceRebind: boolean?)
		local absW = scroll.AbsoluteSize.X
		local absH = scroll.AbsoluteSize.Y
		if absW <= 10 or absH <= 10 then
			return
		end

		-- Narrow screen check (viewport aspect < 1.3 -> 3 columns, otherwise 4 columns)
		local cam = workspace.CurrentCamera
		local vpSize = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		local vpAspect = vpSize.X / math.max(1, vpSize.Y)
		local cols = if vpAspect < 1.3 then 3 else 4

		local sidePadPx = math.floor(absW * 0.02)
		local gapPx = math.max(6, math.floor(absW * 0.015))
		local usableW = math.max(100, absW - sidePadPx * 2 - 10)
		local cellW = math.floor((usableW - gapPx * (cols - 1)) / cols)
		local cardAspect = cfg.CARD_ASPECT or 1.0
		local cellH = math.max(80, math.floor(cellW / math.max(0.4, cardAspect)))

		local totalRows = math.ceil(totalCards / cols)
		local totalCanvasH = sidePadPx * 2 + totalRows * cellH + math.max(0, totalRows - 1) * gapPx
		scroll.CanvasSize = UDim2.fromOffset(0, totalCanvasH)

		local scrollY = scroll.CanvasPosition.Y
		local rowStride = cellH + gapPx
		local firstVisibleRow = math.floor(math.max(0, scrollY - sidePadPx) / rowStride) + 1
		local visibleRowCount = math.ceil(absH / rowStride) + 1

		-- Create/recycle only rows in view + 2 buffer rows
		local startRow = math.max(1, firstVisibleRow - 1)
		local endRow = math.min(totalRows, firstVisibleRow + visibleRowCount)

		local startIdx = (startRow - 1) * cols + 1
		local endIdx = math.min(totalCards, endRow * cols)

		local maxSlotsNeeded = (visibleRowCount + 3) * cols
		while #slotPool < maxSlotsNeeded do
			table.insert(slotPool, createSlot(#slotPool + 1))
		end

		-- Release out-of-range slots
		local freeSlots: { CardSlot } = {}
		for _, slot in slotPool do
			local bIdx = slot.boundIndex
			if bIdx and (bIdx < startIdx or bIdx > endIdx) then
				activeByIndex[bIdx] = nil
				slot.boundIndex = nil
				slot.outer.Visible = false
				slot.isShimmering = false
				table.insert(freeSlots, slot)
			elseif not bIdx then
				table.insert(freeSlots, slot)
			end
		end

		-- Bind and position visible slots
		for idx = startIdx, endIdx do
			local slot = activeByIndex[idx]
			local needsBind = forceRebind == true
			if not slot then
				slot = table.remove(freeSlots)
				if not slot then
					slot = createSlot(#slotPool + 1)
					table.insert(slotPool, slot)
				end
				activeByIndex[idx] = slot
				needsBind = true
			end

			local r = math.floor((idx - 1) / cols)
			local c = (idx - 1) % cols
			local xPx = sidePadPx + c * (cellW + gapPx)
			local yPx = sidePadPx + r * (cellH + gapPx)

			slot.outer.Size = UDim2.fromOffset(cellW, cellH)
			slot.outer.Position = UDim2.fromOffset(xPx, yPx)
			slot.outer.Visible = true

			if needsBind then
				bindSlotToCard(slot, idx, orderedCards[idx])
			end
		end
	end

	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		refreshVirtualGrid(false)
	end)
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		refreshVirtualGrid(false)
	end)

	-- ONE shared shimmer loop for all visible Mythic/Legendary cards every ~4 seconds
	RunService.Heartbeat:Connect(function()
		if not indexWindow.Visible then
			return
		end
		local cycle = os.clock() % 4.0
		local offset = if cycle < 1.1 then -1.2 + (cycle / 1.1) * 2.4 else 1.2
		local vec = Vector2.new(offset, 0)
		for _, slot in slotPool do
			if slot.outer.Visible and slot.isShimmering then
				slot.shimmerGrad.Offset = vec
			end
		end
	end)

	local function open()
		modalBackdrop.Visible = true
		UITheme.openWindow(indexWindow)
		task.defer(function()
			refreshVirtualGrid(true)
		end)
	end

	local function close()
		UITheme.closeWindow(indexWindow, function()
			modalBackdrop.Visible = false
		end)
	end

	local function isOpen(): boolean
		return indexWindow.Visible
	end

	local function update(p: any): (number, number)
		discoveredMap = (p and p.DiscoveredCards) or {}
		local discCount = 0
		for _, card in orderedCards do
			if discoveredMap[card.id] then
				discCount += 1
			end
		end
		local pct = math.round((discCount / math.max(1, totalCards)) * 100)
		subLabel.Text = `DISCOVERED: {discCount} / {totalCards} ({pct}%) • +$25–$250 PER NEW CARD!`
		if progBarObj then
			progBarObj.Update(discCount, totalCards)
		end
		if indexWindow.Visible then
			refreshVirtualGrid(true)
		end
		return discCount, pct
	end

	return {
		window = indexWindow,
		open = open,
		close = close,
		isOpen = isOpen,
		update = update,
	}
end

--------------------------------------------------------------------------------
-- PROMPT 9: PLAYER PROFILE & STATS TRACKER WINDOW
--------------------------------------------------------------------------------
local STRINGS_PROFILE = {
	en = {
		TITLE = "PLAYER PROFILE & STATS TRACKER",
		SEC_PROFILE = "1. PLAYER PROFILE",
		SEC_MATCHES = "2. MATCHES",
		SEC_CARDS = "3. CARD COLLECTION",
		FIRST_PLAYED = "FIRST PLAYED",
		TOTAL_PLAYTIME = "TOTAL PLAYTIME",
		TITLE_PREFIX = "TITLE: ",
		RANK_WINS = "RANK WINS",
		RANK_STREAK = "RANK STREAK",
		RANK_CASH = "RANK CASH",
		RANK_PLAYTIME = "RANK PLAYTIME",
		TOTAL_WINS = "TOTAL WINS",
		BEST_STREAK = "BEST STREAK",
		CURRENT_STREAK = "CURRENT STREAK",
		TOTAL_CASH_EARNED = "TOTAL CASH EARNED",
		WINS_TODAY = "WINS TODAY",
		WINS_THIS_WEEK = "WINS THIS WEEK",
		CARD_PROGRESS = "CARD INDEX PROGRESS: %d/%d (%d%%)",
		COMMON = "COMMON",
		RARE = "RARE",
		EPIC = "EPIC",
		LEGENDARY = "LEGENDARY",
		MYTHIC = "MYTHIC",
		TOTAL_SPINS_MYTHICS = "TOTAL SPINS & MYTHICS",
		TOTAL_SPINS_MYTHICS_FMT = "%d SPINS • %d MYTHIC",
		PITY = "SPINS W/O MYTHIC (MAX / CUR)",
		PITY_FMT = "%d MAX (CUR: %d)",
		RAREST_CARD = "RAREST CARD",
		LATEST_CARD = "LATEST CARD",
	},
	id = {
		TITLE = "PROFIL PEMAIN & STATISTIK",
		SEC_PROFILE = "1. PROFIL PEMAIN",
		SEC_MATCHES = "2. PERTANDINGAN",
		SEC_CARDS = "3. KOLEKSI KARTU",
		FIRST_PLAYED = "PERTAMA MAIN",
		TOTAL_PLAYTIME = "TOTAL PLAYTIME",
		TITLE_PREFIX = "GELAR: ",
		RANK_WINS = "RANK WINS",
		RANK_STREAK = "RANK STREAK",
		RANK_CASH = "RANK CASH",
		RANK_PLAYTIME = "RANK PLAYTIME",
		TOTAL_WINS = "TOTAL WINS",
		BEST_STREAK = "BEST STREAK",
		CURRENT_STREAK = "STREAK SAAT INI",
		TOTAL_CASH_EARNED = "TOTAL CASH DIDAPAT",
		WINS_TODAY = "WINS HARI INI",
		WINS_THIS_WEEK = "WINS MINGGU INI",
		CARD_PROGRESS = "PROGRES CARD INDEX: %d/%d (%d%%)",
		COMMON = "COMMON",
		RARE = "RARE",
		EPIC = "EPIC",
		LEGENDARY = "LEGENDARY",
		MYTHIC = "MYTHIC",
		TOTAL_SPINS_MYTHICS = "TOTAL SPIN & MYTHIC DIDAPAT",
		TOTAL_SPINS_MYTHICS_FMT = "%d SPIN • %d MYTHIC",
		PITY = "SPIN TANPA MYTHIC (MAX / SKRG)",
		PITY_FMT = "%d MAX (SKRG: %d)",
		RAREST_CARD = "KARTU TERLANGKA",
		LATEST_CARD = "KARTU TERBARU",
	},
}

local function formatNumber(val: number): string
	if val < 1000 then
		return tostring(val)
	elseif val < 1000000 then
		local s = tostring(math.floor(val))
		local k
		while true do
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
		end
		return s
	elseif val < 1000000000 then
		local m = val / 1000000
		local s = if m >= 100 then string.format("%dM", math.floor(m)) else string.format("%.1fM", m)
		return string.gsub(s, "%.0M$", "M")
	else
		local b = val / 1000000000
		local s = string.format("%.1fB", b)
		return string.gsub(s, "%.0B$", "B")
	end
end

local function formatMoney(val: number): string
	return "$" .. formatNumber(val)
end

function ShopDailyUI.initProfile(
	screenGui: ScreenGui,
	modalBackdrop: GuiObject,
	Remotes: any,
	UITheme: any,
	GameConfig: any,
	Footballers: any
): ProfileHandler
	local lang = (UITheme.CONFIG.Profile and UITheme.CONFIG.Profile.LANGUAGE) or "en"
	local S = STRINGS_PROFILE[lang] or STRINGS_PROFILE.en

	local profileWinData = UITheme.window({
		name = "ProfileWindow",
		title = S.TITLE,
		headerColors = UITheme.CONFIG.Headers.Profile,
		closeStyle = "magenta",
		headerHeightOffset = 46,
		size = UDim2.new(0, 680, 0.72, 0),
		parent = screenGui,
		onClose = function()
			modalBackdrop.Visible = false
		end,
	})
	local profileWindow = profileWinData.Window
	profileWindow.ZIndex = 26
	profileWindow.Visible = false

	local aspectConstraint = Instance.new("UIAspectRatioConstraint")
	aspectConstraint.AspectRatio = (UITheme.CONFIG.Profile and UITheme.CONFIG.Profile.WINDOW_ASPECT) or 1.65
	aspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	aspectConstraint.Parent = profileWindow

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(820, 520)
	sizeConstraint.MinSize = Vector2.new(460, 280)
	sizeConstraint.Parent = profileWindow

	profileWindow.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
	profileWindow.BackgroundTransparency = 0.35
	profileWinData.Body.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
	profileWinData.Body.BackgroundTransparency = 0.35

	profileWinData.Header.ZIndex = 27
	if profileWinData.Title and profileWinData.Title:IsA("GuiObject") then
		profileWinData.Title.ZIndex = 30
	end
	if profileWinData.Close and profileWinData.Close:IsA("GuiObject") then
		profileWinData.Close.ZIndex = 31
		local cStuds = profileWinData.Close:FindFirstChild("Studs")
		if cStuds and cStuds:IsA("ImageLabel") then
			cStuds.ZIndex = 31
			cStuds.ImageTransparency = 0.82
		end
		local xLabel = profileWinData.Close:FindFirstChild("XLabel")
		if not xLabel then
			xLabel = Instance.new("TextLabel")
			xLabel.Name = "XLabel"
			xLabel.Size = UDim2.fromScale(0.82, 0.82)
			xLabel.Position = UDim2.fromScale(0.5, 0.5)
			xLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			xLabel.BackgroundTransparency = 1
			xLabel.Font = UITheme.CONFIG.Font
			xLabel.Text = "X"
			xLabel.TextColor3 = UITheme.CONFIG.Colors.White
			xLabel.TextScaled = true
			xLabel.ZIndex = 33
			UITheme.applyTextStroke(xLabel, 3, UITheme.CONFIG.Colors.Black)
			xLabel.Parent = profileWinData.Close
		end
	end
	local hStuds = profileWinData.Header:FindFirstChild("Studs")
	if hStuds and hStuds:IsA("ImageLabel") then
		local studAsset = (UITheme.Assets and UITheme.Assets.Header_Studs_Profile_Indigo) or "rbxassetid://73760157351730"
		hStuds.Image = studAsset
		hStuds.ImageTransparency = 0.12
		hStuds.ScaleType = Enum.ScaleType.Crop
		hStuds.ImageColor3 = Color3.fromHex("#5B6CFF")
		hStuds.ZIndex = 28
	end
	local hBorder = profileWinData.Header:FindFirstChild("BottomBorder")
	if hBorder and hBorder:IsA("GuiObject") then
		hBorder.ZIndex = 30
	end

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ProfileScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -16)
	scrollFrame.Position = UDim2.new(0, 10, 0, 8)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 140, 180)
	scrollFrame.ScrollBarImageTransparency = 0.3
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.CanvasSize = UDim2.fromScale(0, 0)
	scrollFrame.ZIndex = 27
	scrollFrame.Parent = profileWinData.Body

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.Padding = UDim.new(0, 20)
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	scrollLayout.Parent = scrollFrame

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingLeft = UDim.new(0, 10)
	scrollPadding.PaddingRight = UDim.new(0, 10)
	scrollPadding.PaddingTop = UDim.new(0, 6)
	scrollPadding.PaddingBottom = UDim.new(0, 12)
	scrollPadding.Parent = scrollFrame

	local sectionColors = (UITheme.CONFIG.Profile and UITheme.CONFIG.Profile.SECTION_COLORS) or {
		Color3.fromHex("#22C8EE"), -- Cyan
		Color3.fromHex("#FFC21A"), -- Gold
		Color3.fromHex("#F0509F"), -- Pink
		Color3.fromHex("#7CFF2B"), -- Green
		Color3.fromHex("#A855F7"), -- Purple
	}

	local function makeSection(order: number, titleText: string, heightPx: number): (Frame, Frame)
		local accent = sectionColors[((order - 1) % #sectionColors) + 1]

		local sec = Instance.new("Frame")
		sec.Name = "Section_" .. tostring(order)
		sec.LayoutOrder = order
		sec.Size = UDim2.new(1, -8, 0, heightPx)
		sec.BackgroundColor3 = Color3.fromHex("#0F1219")
		sec.BackgroundTransparency = 0.35
		sec.BorderSizePixel = 0
		sec.ZIndex = 28
		sec.ClipsDescendants = true
		UITheme.addCorner(sec, 4)
		UITheme.applyStroke(sec, 2, accent)
		sec.Parent = scrollFrame

		local hdrBtn = Instance.new("TextButton")
		hdrBtn.Name = "Header"
		hdrBtn.Size = UDim2.new(1, -16, 0, 26)
		hdrBtn.Position = UDim2.fromOffset(8, 6)
		hdrBtn.BackgroundTransparency = 1
		hdrBtn.Font = UITheme.Fonts.Primary
		hdrBtn.TextColor3 = accent
		hdrBtn.TextXAlignment = Enum.TextXAlignment.Left
		hdrBtn.TextScaled = true
		hdrBtn.Text = titleText
		hdrBtn.ZIndex = 29
		UITheme.addTextConstraint(hdrBtn, 12, 18)
		UITheme.applyTextStroke(hdrBtn, 3, UITheme.Colors.Black)
		hdrBtn.Parent = sec

		local contentFrame = Instance.new("Frame")
		contentFrame.Name = "Content"
		contentFrame.Size = UDim2.new(1, -16, 1, -36)
		contentFrame.Position = UDim2.fromOffset(8, 32)
		contentFrame.BackgroundTransparency = 1
		contentFrame.BorderSizePixel = 0
		contentFrame.ZIndex = 29
		contentFrame.Parent = sec

		if UITheme.CONFIG.Profile and UITheme.CONFIG.Profile.COLLAPSIBLE_SECTIONS then
			local collapsed = false
			hdrBtn.Activated:Connect(function()
				collapsed = not collapsed
				contentFrame.Visible = not collapsed
				sec.Size = if collapsed then UDim2.new(1, -8, 0, 36) else UDim2.new(1, -8, 0, heightPx)
			end)
		end

		return sec, contentFrame
	end

	local function makeStatTile(parent: Instance, pos: UDim2, size: UDim2, labelText: string, accentColor: Color3, valColor: Color3?): (Frame, TextLabel, TextLabel)
		local tile = Instance.new("Frame")
		tile.Size = size
		tile.Position = pos
		tile.BackgroundColor3 = Color3.fromHex("#0D0F14")
		tile.BackgroundTransparency = 0.35
		tile.BorderSizePixel = 0
		tile.ZIndex = 30
		UITheme.addCorner(tile, 4)
		UITheme.applyStroke(tile, 2, accentColor)
		tile.Parent = parent

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.Size = UDim2.new(1, -8, 0.36, 0)
		lbl.Position = UDim2.new(0, 4, 0.06, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = UITheme.Fonts.Body
		lbl.TextColor3 = Color3.fromHex("#D8DCE6")
		lbl.TextScaled = true
		lbl.Text = string.upper(labelText)
		lbl.ZIndex = 31
		UITheme.addTextConstraint(lbl, 9, 13)
		UITheme.applyTextStroke(lbl, 2, UITheme.Colors.Black)
		lbl.Parent = tile

		local val = Instance.new("TextLabel")
		val.Name = "Value"
		val.Size = UDim2.new(1, -8, 0.52, 0)
		val.Position = UDim2.new(0, 4, 0.44, 0)
		val.BackgroundTransparency = 1
		val.Font = UITheme.Fonts.Primary
		val.TextColor3 = valColor or UITheme.Colors.White
		val.TextScaled = true
		val.Text = "-"
		val.ZIndex = 31
		UITheme.addTextConstraint(val, 11, 20)
		UITheme.applyTextStroke(val, 3, UITheme.Colors.Black)
		val.Parent = tile

		return tile, lbl, val
	end

	-- SECTION 1: PLAYER PROFILE
	local sec1, c1 = makeSection(1, S.SEC_PROFILE, 178)

	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.fromOffset(76, 76)
	avatarFrame.Position = UDim2.fromOffset(4, 2)
	avatarFrame.BackgroundColor3 = Color3.fromHex("#0D0F14")
	avatarFrame.BackgroundTransparency = 0.35
	avatarFrame.BorderSizePixel = 0
	avatarFrame.ZIndex = 30
	UITheme.addCorner(avatarFrame, 4)
	UITheme.applyStroke(avatarFrame, 3, UITheme.Colors.Black)
	avatarFrame.Parent = c1

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "AvatarImage"
	avatarImg.Size = UDim2.fromScale(1, 1)
	avatarImg.BackgroundTransparency = 1
	avatarImg.ScaleType = Enum.ScaleType.Fit
	avatarImg.ZIndex = 31
	UITheme.addCorner(avatarImg, 4)
	avatarImg.Image = `rbxthumb://type=AvatarBust&id={localPlayer.UserId}&w=150&h=150`
	avatarImg.Parent = avatarFrame

	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and content and content ~= "" then
			avatarImg.Image = content
		end
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(0.42, -92, 0, 24)
	nameLabel.Position = UDim2.fromOffset(88, 6)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = UITheme.Fonts.Primary
	nameLabel.TextColor3 = UITheme.Colors.White
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextScaled = true
	nameLabel.Text = `{localPlayer.DisplayName} (@{localPlayer.Name})`
	nameLabel.ZIndex = 30
	UITheme.addTextConstraint(nameLabel, 11, 18)
	UITheme.applyTextStroke(nameLabel, 3, UITheme.Colors.Black)
	nameLabel.Parent = c1

	local titleChip = Instance.new("Frame")
	titleChip.Name = "TitleChip"
	titleChip.Size = UDim2.new(0.42, -92, 0, 22)
	titleChip.Position = UDim2.fromOffset(88, 34)
	titleChip.BackgroundTransparency = 1
	titleChip.ZIndex = 30
	titleChip.Parent = c1

	local titleIcon = Instance.new("ImageLabel")
	titleIcon.Name = "TagIcon"
	titleIcon.Size = UDim2.fromOffset(16, 16)
	titleIcon.Position = UDim2.new(0, 0, 0.5, -8)
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = UITheme.Assets.Icon_Tag or "rbxassetid://6031075938"
	titleIcon.ImageColor3 = UITheme.Colors.GoldTop
	titleIcon.ZIndex = 31
	titleIcon.Parent = titleChip

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -22, 1, 0)
	titleLabel.Position = UDim2.fromOffset(22, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = UITheme.Fonts.Primary
	titleLabel.TextColor3 = UITheme.Colors.GoldTop
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextScaled = true
	titleLabel.Text = S.TITLE_PREFIX .. "BENCHWARMER"
	titleLabel.ZIndex = 31
	UITheme.addTextConstraint(titleLabel, 10, 16)
	UITheme.applyTextStroke(titleLabel, 2, UITheme.Colors.Black)
	titleLabel.Parent = titleChip

	local _, _, valFirstPlayed = makeStatTile(c1, UDim2.new(0.44, 4, 0, 2), UDim2.new(0.28, -6, 0, 76), S.FIRST_PLAYED, Color3.fromHex("#22C8EE"))
	local _, _, valPlaytime = makeStatTile(c1, UDim2.new(0.72, 4, 0, 2), UDim2.new(0.28, -8, 0, 76), S.TOTAL_PLAYTIME, Color3.fromHex("#22C8EE"))

	local rankBoards = {
		{ key = "Wins", title = S.RANK_WINS, color = Color3.fromHex("#FFC21A") },
		{ key = "Streak", title = S.RANK_STREAK, color = Color3.fromHex("#FF9A1F") },
		{ key = "Cash", title = S.RANK_CASH, color = Color3.fromHex("#7CFF2B") },
		{ key = "Playtime", title = S.RANK_PLAYTIME, color = Color3.fromHex("#22C8EE") },
	}
	local rankLabels: { [string]: TextLabel } = {}
	for idx, rb in rankBoards do
		local xPos = (idx - 1) * 0.25
		local _, _, rVal = makeStatTile(c1, UDim2.new(xPos, 2, 0, 80), UDim2.new(0.25, -4, 0, 56), rb.title, rb.color)
		rankLabels[rb.key] = rVal
	end

	-- SECTION 2: MATCHES
	local sec2, c2 = makeSection(2, S.SEC_MATCHES, 154)
	local _, _, valTotalWins = makeStatTile(c2, UDim2.new(0, 2, 0, 4), UDim2.new(0.333, -4, 0, 52), S.TOTAL_WINS, Color3.fromHex("#FFC21A"))
	local _, _, valBestStreak = makeStatTile(c2, UDim2.new(0.333, 2, 0, 4), UDim2.new(0.333, -4, 0, 52), S.BEST_STREAK, Color3.fromHex("#FF9A1F"), Color3.fromHex("#FF9A1F"))
	local _, _, valCurStreak = makeStatTile(c2, UDim2.new(0.666, 2, 0, 4), UDim2.new(0.334, -4, 0, 52), S.CURRENT_STREAK, Color3.fromHex("#FF9A1F"), Color3.fromHex("#FF9A1F"))

	local _, _, valTotalCash = makeStatTile(c2, UDim2.new(0, 2, 0, 62), UDim2.new(0.333, -4, 0, 52), S.TOTAL_CASH_EARNED, Color3.fromHex("#7CFF2B"), Color3.fromHex("#7CFF2B"))
	local _, _, valWinsToday = makeStatTile(c2, UDim2.new(0.333, 2, 0, 62), UDim2.new(0.333, -4, 0, 52), S.WINS_TODAY, Color3.fromHex("#22C8EE"))
	local _, _, valWinsWeek = makeStatTile(c2, UDim2.new(0.666, 2, 0, 62), UDim2.new(0.334, -4, 0, 52), S.WINS_THIS_WEEK, Color3.fromHex("#22C8EE"))

	-- SECTION 3: CARD COLLECTION
	local sec3, c3 = makeSection(3, S.SEC_CARDS, 236)

	local progBarBg = Instance.new("Frame")
	progBarBg.Name = "ProgressBarBg"
	progBarBg.Size = UDim2.new(1, -4, 0, 26)
	progBarBg.Position = UDim2.fromOffset(2, 4)
	progBarBg.BackgroundColor3 = Color3.fromHex("#0D0F14")
	progBarBg.BackgroundTransparency = 0.35
	progBarBg.BorderSizePixel = 0
	progBarBg.ZIndex = 30
	UITheme.addCorner(progBarBg, 4)
	UITheme.applyStroke(progBarBg, 2, Color3.fromHex("#F0509F"))
	progBarBg.Parent = c3

	local progBarFill = Instance.new("Frame")
	progBarFill.Name = "Fill"
	progBarFill.Size = UDim2.fromScale(0, 1)
	progBarFill.BackgroundColor3 = Color3.fromHex("#D237BE")
	progBarFill.BorderSizePixel = 0
	progBarFill.ZIndex = 31
	UITheme.addCorner(progBarFill, 4)
	progBarFill.Parent = progBarBg

	local progBarText = Instance.new("TextLabel")
	progBarText.Name = "ProgressLabel"
	progBarText.Size = UDim2.fromScale(1, 1)
	progBarText.BackgroundTransparency = 1
	progBarText.Font = UITheme.Fonts.Primary
	progBarText.TextColor3 = UITheme.Colors.White
	progBarText.TextScaled = true
	progBarText.Text = string.format(S.CARD_PROGRESS, 0, 152, 0)
	progBarText.ZIndex = 32
	UITheme.addTextConstraint(progBarText, 11, 16)
	UITheme.applyTextStroke(progBarText, 2, UITheme.Colors.Black)
	progBarText.Parent = progBarBg

	local rarityOrder = {
		{ name = "Common", label = S.COMMON, color = Color3.fromHex("#A0A8B8") },
		{ name = "Rare", label = S.RARE, color = Color3.fromHex("#34B6FF") },
		{ name = "Epic", label = S.EPIC, color = Color3.fromHex("#A855F7") },
		{ name = "Legendary", label = S.LEGENDARY, color = Color3.fromHex("#FFD21F") },
		{ name = "Mythic", label = S.MYTHIC, color = Color3.fromHex("#F0408C") },
	}
	local rarityVals: { [string]: TextLabel } = {}
	for idx, r in rarityOrder do
		local xPos = (idx - 1) * 0.2
		local _, _, rVal = makeStatTile(c3, UDim2.new(xPos, 2, 0, 36), UDim2.new(0.2, -4, 0, 48), r.label, r.color)
		rarityVals[r.name] = rVal
	end

	local _, _, valTotalSpins = makeStatTile(c3, UDim2.new(0, 2, 0, 90), UDim2.new(0.5, -4, 0, 48), S.TOTAL_SPINS_MYTHICS, Color3.fromHex("#F0408C"))
	local _, _, valPity = makeStatTile(c3, UDim2.new(0.5, 2, 0, 90), UDim2.new(0.5, -4, 0, 48), S.PITY, Color3.fromHex("#FFD21F"))
	local _, _, valRarest = makeStatTile(c3, UDim2.new(0, 2, 0, 144), UDim2.new(0.5, -4, 0, 48), S.RAREST_CARD, Color3.fromHex("#F0408C"))
	local _, _, valLatest = makeStatTile(c3, UDim2.new(0.5, 2, 0, 144), UDim2.new(0.5, -4, 0, 48), S.LATEST_CARD, Color3.fromHex("#22C8EE"))

	local lastRankFetchAt = 0
	local function refreshRanks()
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
						if rank <= 3 then
							lbl.TextColor3 = Color3.fromHex("#FFC21A")
						else
							lbl.TextColor3 = UITheme.Colors.White
						end
					else
						lbl.Text = "-"
						lbl.TextColor3 = UITheme.Colors.White
					end
				end)
			end
		end
	end

	local function update(p: any, elapsed: number?, disc: { [string]: boolean }?, discCount: number?, pct: number?)
		if not p then return end
		local el = elapsed or 0

		local eqTitle = p.EquippedTitle or "Benchwarmer"
		titleLabel.Text = S.TITLE_PREFIX .. string.upper(eqTitle)
		local tColor = if GameConfig and GameConfig.getTitleColor then GameConfig.getTitleColor(eqTitle) else UITheme.Colors.GoldTop
		titleLabel.TextColor3 = tColor
		titleIcon.ImageColor3 = tColor

		local firstJoin = p.FirstJoinedAt or 0
		valFirstPlayed.Text = if firstJoin > 0 then os.date("%d %b %Y", firstJoin) else "-"

		local totalPtSec = (p.PlaytimeSeconds or 0) + el
		valPlaytime.Text = if GameConfig and GameConfig.formatPlaytime then GameConfig.formatPlaytime(totalPtSec) else formatMMSS(totalPtSec)

		if profileWindow.Visible then
			refreshRanks()
		end

		local wins = p.Wins or 0
		local curStreak = p.Streak or 0
		local bestStreak = math.max(p.BestStreak or 0, curStreak)
		local totalCash = math.max(p.TotalCashEarned or 0, p.Bux or 0)

		valTotalWins.Text = formatNumber(wins)
		valBestStreak.Text = formatNumber(bestStreak)
		valCurStreak.Text = formatNumber(curStreak)
		valTotalCash.Text = formatMoney(totalCash)
		valWinsToday.Text = formatNumber(p.WinsToday or 0)
		valWinsWeek.Text = formatNumber(p.WinsThisWeek or p.WinsWeek or 0)

		local allCards = (Footballers and Footballers.All) or {}
		local totalCardsCount = math.max(1, #allCards)
		local dMap = disc or p.DiscoveredCards or {}
		local dCount = discCount or 0
		if not discCount then
			for _, card in allCards do
				if dMap[card.id] then
					dCount += 1
				end
			end
		end
		local pPct = pct or math.round((dCount / totalCardsCount) * 100)

		progBarFill.Size = UDim2.fromScale(math.clamp(dCount / totalCardsCount, 0, 1), 1)
		progBarText.Text = string.format(S.CARD_PROGRESS, dCount, totalCardsCount, pPct)

		local rCounts: { [string]: number } = { Common = 0, Rare = 0, Epic = 0, Legendary = 0, Mythic = 0 }
		local rTotal: { [string]: number } = { Common = 0, Rare = 0, Epic = 0, Legendary = 0, Mythic = 0 }
		local rarityRankMap: { [string]: number } = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
		local fallbackRarest: any = nil

		for _, card in allCards do
			rTotal[card.rarity] = (rTotal[card.rarity] or 0) + 1
			if dMap[card.id] then
				rCounts[card.rarity] = (rCounts[card.rarity] or 0) + 1
				if not fallbackRarest then
					fallbackRarest = card
				else
					local rCand = rarityRankMap[card.rarity] or 0
					local rCur = rarityRankMap[fallbackRarest.rarity] or 0
					if rCand > rCur or (rCand == rCur and card.ovr > fallbackRarest.ovr) then
						fallbackRarest = card
					end
				end
			end
		end

		for rName, lbl in rarityVals do
			lbl.Text = `{rCounts[rName] or 0}/{rTotal[rName] or 0}`
		end

		local totalSpins = p.TotalCardSpins or 0
		local mythicsPulled = p.MythicsPulled or 0
		local hasSpinHistory = totalSpins > 0 or (p.MatchesPlayed or 0) == 0
		valTotalSpins.Text = if hasSpinHistory then string.format(S.TOTAL_SPINS_MYTHICS_FMT, totalSpins, mythicsPulled) else "-"
		valPity.Text = if hasSpinHistory then string.format(S.PITY_FMT, p.MaxSpinsWithoutMythic or 0, p.SpinsSinceMythic or 0) else "-"

		local byId = (Footballers and Footballers.ById) or {}
		local rarestCard = if p.RarestCardId and p.RarestCardId ~= "" then byId[p.RarestCardId] else fallbackRarest
		if rarestCard then
			local dName = if Footballers and Footballers.getDisplayName then Footballers.getDisplayName(rarestCard) else rarestCard.name
			valRarest.Text = `{dName} ({rarestCard.rarity} {rarestCard.ovr})`
			valRarest.TextColor3 = (GameConfig and GameConfig.RARITY_COLORS and GameConfig.RARITY_COLORS[rarestCard.rarity]) or UITheme.Colors.White
		else
			valRarest.Text = "-"
			valRarest.TextColor3 = UITheme.Colors.White
		end

		local latestCard = if p.LatestCardId and p.LatestCardId ~= "" then byId[p.LatestCardId] else nil
		if latestCard then
			local dName = if Footballers and Footballers.getDisplayName then Footballers.getDisplayName(latestCard) else latestCard.name
			valLatest.Text = `{dName} ({latestCard.rarity} {latestCard.ovr})`
			valLatest.TextColor3 = (GameConfig and GameConfig.RARITY_COLORS and GameConfig.RARITY_COLORS[latestCard.rarity]) or UITheme.Colors.White
		else
			valLatest.Text = "-"
			valLatest.TextColor3 = UITheme.Colors.White
		end
	end

	local function open()
		modalBackdrop.Visible = true
		UITheme.openWindow(profileWindow)
		refreshRanks()
	end

	local function close()
		UITheme.closeWindow(profileWindow, function()
			modalBackdrop.Visible = false
		end)
	end

	local function isOpen(): boolean
		return profileWindow.Visible
	end

	return {
		window = profileWindow,
		open = open,
		close = close,
		isOpen = isOpen,
		update = update,
		refreshRanks = refreshRanks,
	}
end


return ShopDailyUI

import json

# Read current source from Studio via Luau script or test runner
# Let's write the luau code that will do the replacement safely in Studio
luau_updater = '''
local clientScript = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Client"):FindFirstChild("MatchClient")
local src = clientScript.Source

-- 1. ScreenInsets
local old_inset = [[screenGui.DisplayOrder = 50
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui]]

local new_inset = [[screenGui.DisplayOrder = 50
screenGui.IgnoreGuiInset = false
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screenGui.Parent = playerGui]]

local s1, e1 = string.find(src, old_inset, 1, true)
if not s1 then
    return "FAILED: old_inset not found"
end
src = string.sub(src, 1, s1 - 1) .. new_inset .. string.sub(src, e1 + 1)

-- 2. Left Nav Group & FREE tag & Index Badge
local old_left_nav = [[-- Left Vertical Nav Column (FREE, SHOP, SKINS, TITLES, INDEX, PROFILE)
local btnNavFree: TextButton
local btnNavShop: TextButton
local btnNavSkins: TextButton
local btnNavTitles: TextButton
local btnNavIndex: TextButton
local btnNavProfile: TextButton
do
	local NAV_BTN_SIZE = 64
	local NAV_BTN_STEP = 74

	local function makeNavButton(name: string, imageId: string, index: number, scaleX: number, scaleY: number, anchorX: number, anchorY: number): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.fromOffset(NAV_BTN_SIZE, NAV_BTN_SIZE)
		btn.Position = UDim2.new(0, 16, 0.5, -242 + (index - 1) * NAV_BTN_STEP)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = lobbyHud
		UITheme.setupButtonHover(btn, 1.06, 0)

		local img = Instance.new("ImageLabel")
		img.Name = "NavIcon"
		img.Size = UDim2.fromScale(scaleX, scaleY)
		img.AnchorPoint = Vector2.new(anchorX, anchorY)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.BackgroundTransparency = 1
		img.Image = imageId
		img.ScaleType = Enum.ScaleType.Stretch
		img.ZIndex = btn.ZIndex + 1
		img.Parent = btn
		return btn
	end

	-- Compensate per-PNG transparent padding (557x557 canvas) so every icon frame renders at the exact 84x84 button size
	btnNavFree = makeNavButton("BtnNavFree", UITheme.Assets.NavFreeIcon, 1, 557 / 444, 557 / 449, 277.5 / 557, 266.0 / 557)
	btnNavShop = makeNavButton("BtnNavShop", UITheme.Assets.NavShopIcon, 2, 557 / 496, 557 / 506, 278.5 / 557, 282.5 / 557)
	btnNavSkins = makeNavButton("BtnNavSkins", UITheme.Assets.NavSkinsIcon, 3, 557 / 477, 557 / 489, 278.0 / 557, 284.0 / 557)
	btnNavTitles = makeNavButton("BtnNavTitles", UITheme.Assets.NavTitlesIcon, 4, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
	btnNavIndex = makeNavButton("BtnNavIndex", UITheme.Assets.NavIndexIcon, 5, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
	btnNavProfile = makeNavButton("BtnNavProfile", UITheme.Assets.NavProfileIcon, 6, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)

	local badge = makeLabel(btnNavIndex, "0/152", UDim2.fromOffset(52, 20), UDim2.new(1, -40, 0, -6), Color3.new(1, 1, 1))
	badge.Name = "IndexBadge"
	badge.BackgroundTransparency = 0
	badge.BackgroundColor3 = Color3.fromHex("#E5252A")
	badge.ZIndex = btnNavIndex.ZIndex + 4
	badge.TextSize = 11
	badge.Font = UITheme.Fonts.Body
	UITheme.addCorner(badge, 10)
	UITheme.applyStroke(badge, 2, UITheme.Colors.Black)
end

local freeBadge = makeLabel(btnNavFree, "1", UDim2.fromOffset(26, 26), UDim2.new(1, -18, 0, -6), Color3.new(1, 1, 1))
freeBadge.BackgroundTransparency = 0
freeBadge.BackgroundColor3 = Color3.fromHex("#E5252A")
freeBadge.ZIndex = btnNavFree.ZIndex + 4
UITheme.addCorner(freeBadge, 13)
UITheme.applyStroke(freeBadge, 2.5, UITheme.Colors.Black)]]

local new_left_nav = [[-- Left Nav Group (Shop, Skins, Titles, Index, Profile in 2 columns + attached FREE tag)
local leftNavGroup = Instance.new("Frame")
leftNavGroup.Name = "LeftNavGroup"
leftNavGroup.AnchorPoint = Vector2.new(0, 0)
leftNavGroup.Position = UDim2.new(0.01, 0, 0.10, 0)
leftNavGroup.Size = UDim2.new(1, 0, 1, 0)
leftNavGroup.BackgroundTransparency = 1
leftNavGroup.ZIndex = 15
leftNavGroup.Parent = lobbyHud

local leftNavGrid = Instance.new("UIGridLayout")
leftNavGrid.Name = "UIGridLayout"
leftNavGrid.CellSize = UDim2.new(0.06, 0, 0.10, 0)
leftNavGrid.CellPadding = UDim2.new(0, 4, 0, 4)
leftNavGrid.FillDirectionMaxCells = 2
leftNavGrid.SortOrder = Enum.SortOrder.LayoutOrder
leftNavGrid.Parent = leftNavGroup

local btnNavFree: TextButton
local btnNavShop: TextButton
local btnNavSkins: TextButton
local btnNavTitles: TextButton
local btnNavIndex: TextButton
local btnNavProfile: TextButton
local freeBadge: TextLabel

do
	local function makeNavButton(name: string, imageId: string, order: number, scaleX: number, scaleY: number, anchorX: number, anchorY: number): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.LayoutOrder = order
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 16
		btn.Parent = leftNavGroup

		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1.0
		aspect.Parent = btn

		UITheme.setupButtonHover(btn, 1.06, 0)

		local img = Instance.new("ImageLabel")
		img.Name = "NavIcon"
		img.Size = UDim2.fromScale(scaleX, scaleY)
		img.AnchorPoint = Vector2.new(anchorX, anchorY)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.BackgroundTransparency = 1
		img.Image = imageId
		img.ScaleType = Enum.ScaleType.Stretch
		img.ZIndex = btn.ZIndex + 1
		img.Parent = btn
		return btn
	end

	btnNavShop = makeNavButton("BtnNavShop", UITheme.Assets.NavShopIcon, 1, 557 / 496, 557 / 506, 278.5 / 557, 282.5 / 557)
	btnNavSkins = makeNavButton("BtnNavSkins", UITheme.Assets.NavSkinsIcon, 2, 557 / 477, 557 / 489, 278.0 / 557, 284.0 / 557)
	btnNavTitles = makeNavButton("BtnNavTitles", UITheme.Assets.NavTitlesIcon, 3, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
	btnNavIndex = makeNavButton("BtnNavIndex", UITheme.Assets.NavIndexIcon, 4, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
	btnNavProfile = makeNavButton("BtnNavProfile", UITheme.Assets.NavProfileIcon, 5, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)

	-- FREE Tag attached to Shop button (not a separate overlapping element in the grid)
	btnNavFree = Instance.new("TextButton")
	btnNavFree.Name = "BtnNavFree"
	btnNavFree.AnchorPoint = Vector2.new(0.5, 0.5)
	btnNavFree.Position = UDim2.new(0.5, 0, 0, 0)
	btnNavFree.Size = UDim2.new(0.78, 0, 0.32, 0)
	btnNavFree.BackgroundTransparency = 1
	btnNavFree.Text = ""
	btnNavFree.ZIndex = btnNavShop.ZIndex + 5
	btnNavFree.Parent = btnNavShop

	local freeImg = Instance.new("ImageLabel")
	freeImg.Name = "NavIcon"
	freeImg.Size = UDim2.fromScale(557 / 444, 557 / 449)
	freeImg.AnchorPoint = Vector2.new(277.5 / 557, 266.0 / 557)
	freeImg.Position = UDim2.fromScale(0.5, 0.5)
	freeImg.BackgroundTransparency = 1
	freeImg.Image = UITheme.Assets.NavFreeIcon
	freeImg.ScaleType = Enum.ScaleType.Stretch
	freeImg.ZIndex = btnNavFree.ZIndex + 1
	freeImg.Parent = btnNavFree

	freeBadge = makeLabel(btnNavFree, "1", UDim2.new(0.40, 0, 0.80, 0), UDim2.new(1, -2, 0, 0), Color3.new(1, 1, 1))
	freeBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	freeBadge.BackgroundTransparency = 0
	freeBadge.BackgroundColor3 = Color3.fromHex("#E5252A")
	freeBadge.ZIndex = btnNavFree.ZIndex + 4
	freeBadge.TextScaled = true
	local freeBadgeAspect = Instance.new("UIAspectRatioConstraint")
	freeBadgeAspect.AspectRatio = 1.0
	freeBadgeAspect.Parent = freeBadge
	UITheme.addCorner(freeBadge, 8)
	UITheme.applyStroke(freeBadge, 1.5, UITheme.Colors.Black)

	-- Index Badge moved to top-right corner of Index button, smaller, TextScaled, Max 14
	local badge = makeLabel(btnNavIndex, "0/152", UDim2.new(0.55, 0, 0.28, 0), UDim2.new(1, 0, 0, 0), Color3.new(1, 1, 1))
	badge.Name = "IndexBadge"
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.BackgroundTransparency = 0
	badge.BackgroundColor3 = Color3.fromHex("#E5252A")
	badge.ZIndex = btnNavIndex.ZIndex + 4
	badge.TextScaled = true
	badge.Font = UITheme.Fonts.Body
	local badgeTextConstraint = Instance.new("UITextSizeConstraint")
	badgeTextConstraint.MinTextSize = 8
	badgeTextConstraint.MaxTextSize = 14
	badgeTextConstraint.Parent = badge
	UITheme.addCorner(badge, 6)
	UITheme.applyStroke(badge, 1.5, UITheme.Colors.Black)
end]]

local s2, e2 = string.find(src, old_left_nav, 1, true)
if not s2 then
    return "FAILED: old_left_nav not found"
end
src = string.sub(src, 1, s2 - 1) .. new_left_nav .. string.sub(src, e2 + 1)

-- 3. Right Promo Group (Starter Pack & INF REROLLS stacked with UIListLayout)
local old_right_promo = [[local function createFloatingOfferSlot(parent: GuiObject, pos: UDim2, initialOfferIndex: number): FloatingOfferSlot
	local container = Instance.new("ImageButton")
	container.Name = "FloatingOfferSlot"
	container.Size = UDim2.fromOffset(104, 122)
	container.Position = pos
	container.AnchorPoint = Vector2.new(1, 0.5)
	container.BackgroundTransparency = 1
	container.AutoButtonColor = false
	container.ZIndex = 15
	container.Parent = parent

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = container

	local rays = Instance.new("ImageLabel")
	rays.Name = "SunburstRays"
	rays.Size = UDim2.fromOffset(104, 104)
	rays.Position = UDim2.new(0.5, 0, 0.5, 2)
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.BackgroundTransparency = 1
	rays.Image = UITheme.Assets.SunburstTexture
	rays.ImageTransparency = 0.15
	rays.ScaleType = Enum.ScaleType.Fit
	rays.ZIndex = container.ZIndex + 1
	rays.Parent = container

	local icon = Instance.new("ImageLabel")
	icon.Name = "OfferIcon"
	icon.Size = UDim2.fromOffset(76, 76)
	icon.Position = UDim2.new(0.5, 0, 0.5, 2)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = container.ZIndex + 2
	icon.Parent = container

		local valLbl = Instance.new("TextLabel")
	valLbl.Name = "ValueTag"
	valLbl.Size = UDim2.fromOffset(72, 18)
	valLbl.Position = UDim2.new(0.82, 0, 0.08, 0)
	valLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = UITheme.Fonts.Primary
	valLbl.Text = "149 VALUE"
	valLbl.TextColor3 = Color3.fromHex("#FFD700")
	valLbl.TextSize = 13
	valLbl.Visible = false
	valLbl.ZIndex = icon.ZIndex + 3
	UITheme.applyTextStroke(valLbl, 2, UITheme.Colors.Black)
	valLbl.Parent = icon

	local strikeLine = Instance.new("Frame")
	strikeLine.Name = "StrikeLine"
	strikeLine.Size = UDim2.new(0.92, 0, 0, 2)
	strikeLine.Position = UDim2.new(0.04, 0, 0.5, -1)
	strikeLine.BackgroundColor3 = Color3.fromHex("#FFFFFF")
	strikeLine.BorderSizePixel = 0
	strikeLine.Rotation = -8
	strikeLine.ZIndex = valLbl.ZIndex + 1
	UITheme.applyStroke(strikeLine, 1, UITheme.Colors.Black)
	strikeLine.Parent = valLbl
	local pillBadge = Instance.new("Frame")
	pillBadge.Name = "RobuxPill"
	pillBadge.Size = UDim2.fromOffset(58, 24)
	pillBadge.Position = UDim2.new(0.5, 0, 0, -4)
	pillBadge.AnchorPoint = Vector2.new(0.5, 0)
	pillBadge.BackgroundColor3 = Color3.fromHex("#48C90E")
	pillBadge.ZIndex = container.ZIndex + 5
	UITheme.addCorner(pillBadge, 11)
	UITheme.applyStroke(pillBadge, 2, UITheme.Colors.Black)
	pillBadge.Parent = container

	local robuxIcon = Instance.new("ImageLabel")
	robuxIcon.Name = "RobuxIcon"
	robuxIcon.Size = UDim2.fromOffset(14, 14)
	robuxIcon.Position = UDim2.new(0, 6, 0.5, 0)
	robuxIcon.AnchorPoint = Vector2.new(0, 0.5)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Image = UITheme.Assets.Icon_Robux
	robuxIcon.ZIndex = pillBadge.ZIndex + 1
	robuxIcon.Parent = pillBadge

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name = "PriceLabel"
	priceLbl.Size = UDim2.new(1, -22, 1, 0)
	priceLbl.Position = UDim2.new(0, 20, 0, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font = UITheme.Fonts.Primary
	priceLbl.TextColor3 = UITheme.Colors.White
	priceLbl.Text = "4"
	priceLbl.TextScaled = true
	priceLbl.ZIndex = pillBadge.ZIndex + 1
	UITheme.addTextConstraint(priceLbl, 10, 14)
	UITheme.applyTextStroke(priceLbl, 2, UITheme.Colors.Black)
	priceLbl.Parent = pillBadge

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "TitleLabel"
	titleLbl.Size = UDim2.new(1, 14, 0, 30)
	titleLbl.Position = UDim2.new(0.5, 0, 1, 6)
	titleLbl.AnchorPoint = Vector2.new(0.5, 1)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = UITheme.Fonts.Primary
	titleLbl.TextColor3 = UITheme.Colors.White
	titleLbl.Text = "STARTER\nPACK"
	titleLbl.TextScaled = true
	titleLbl.ZIndex = container.ZIndex + 3
	UITheme.addTextConstraint(titleLbl, 11, 14)
	UITheme.applyTextStroke(titleLbl, 2.5, UITheme.Colors.Black)
	titleLbl.Parent = container

	local currentOffer = HUD_OFFERS[initialOfferIndex]

	local function applyOffer(offer: any)
		currentOffer = offer
		rays.ImageColor3 = offer.color
		icon.Image = offer.icon
		priceLbl.Text = tostring(offer.price)
		titleLbl.Text = offer.title
		valLbl.Visible = (offer.value ~= nil)
		if offer.value then
			valLbl.Text = offer.value
		end
	end

	applyOffer(currentOffer)

	container.Activated:Connect(function()
		local tDown = TweenService:Create(uiScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.9 })
		tDown:Play()
		tDown.Completed:Once(function()
			local tUp = TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 })
			tUp:Play()
		end)
		Remotes.MetaAction:FireServer("BuyShopItem", currentOffer.id)
	end)

	return {
		container = container,
		rays = rays,
		icon = icon,
		uiScale = uiScale,
		applyOffer = applyOffer,
		getOffer = function() return currentOffer end,
	}
end

local promoSlotTop = createFloatingOfferSlot(lobbyHud, UDim2.new(1, -16, 0.60, -66), 1)
local promoSlotBottom = createFloatingOfferSlot(lobbyHud, UDim2.new(1, -16, 0.60, 68), 2)]]

local new_right_promo = [[local rightPromoGroup = Instance.new("Frame")
rightPromoGroup.Name = "RightPromoGroup"
rightPromoGroup.AnchorPoint = Vector2.new(1, 0.5)
rightPromoGroup.Position = UDim2.new(0.99, 0, 0.55, 0)
rightPromoGroup.Size = UDim2.new(0.12, 0, 0.32, 10)
rightPromoGroup.BackgroundTransparency = 1
rightPromoGroup.ZIndex = 15
rightPromoGroup.Parent = lobbyHud

local rightPromoLayout = Instance.new("UIListLayout")
rightPromoLayout.Name = "UIListLayout"
rightPromoLayout.FillDirection = Enum.FillDirection.Vertical
rightPromoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightPromoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rightPromoLayout.Padding = UDim.new(0, 10)
rightPromoLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightPromoLayout.Parent = rightPromoGroup

local function createFloatingOfferSlot(parent: GuiObject, order: number, initialOfferIndex: number): FloatingOfferSlot
	local container = Instance.new("ImageButton")
	container.Name = "FloatingOfferSlot"
	container.Size = UDim2.new(1, 0, 0.46, 0)
	container.LayoutOrder = order
	container.BackgroundTransparency = 1
	container.AutoButtonColor = false
	container.ZIndex = 15
	container.Parent = parent

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.0
	aspect.Parent = container

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = container

	local rays = Instance.new("ImageLabel")
	rays.Name = "SunburstRays"
	rays.Size = UDim2.fromScale(1, 1)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.BackgroundTransparency = 1
	rays.Image = UITheme.Assets.SunburstTexture
	rays.ImageTransparency = 0.15
	rays.ScaleType = Enum.ScaleType.Fit
	rays.ZIndex = container.ZIndex + 1
	rays.Parent = container

	local icon = Instance.new("ImageLabel")
	icon.Name = "OfferIcon"
	icon.Size = UDim2.fromScale(0.72, 0.72)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = container.ZIndex + 2
	icon.Parent = container

	local valLbl = Instance.new("TextLabel")
	valLbl.Name = "ValueTag"
	valLbl.Size = UDim2.new(0.85, 0, 0.22, 0)
	valLbl.Position = UDim2.new(0.82, 0, 0.08, 0)
	valLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = UITheme.Fonts.Primary
	valLbl.Text = "149 VALUE"
	valLbl.TextColor3 = Color3.fromHex("#FFD700")
	valLbl.TextScaled = true
	valLbl.Visible = false
	valLbl.ZIndex = icon.ZIndex + 3
	UITheme.addTextConstraint(valLbl, 9, 13)
	UITheme.applyTextStroke(valLbl, 2, UITheme.Colors.Black)
	valLbl.Parent = icon

	local strikeLine = Instance.new("Frame")
	strikeLine.Name = "StrikeLine"
	strikeLine.Size = UDim2.new(0.92, 0, 0, 2)
	strikeLine.Position = UDim2.new(0.04, 0, 0.5, -1)
	strikeLine.BackgroundColor3 = Color3.fromHex("#FFFFFF")
	strikeLine.BorderSizePixel = 0
	strikeLine.Rotation = -8
	strikeLine.ZIndex = valLbl.ZIndex + 1
	UITheme.applyStroke(strikeLine, 1, UITheme.Colors.Black)
	strikeLine.Parent = valLbl

	local pillBadge = Instance.new("Frame")
	pillBadge.Name = "RobuxPill"
	pillBadge.Size = UDim2.new(0.65, 0, 0.24, 0)
	pillBadge.Position = UDim2.new(0.5, 0, 0, -4)
	pillBadge.AnchorPoint = Vector2.new(0.5, 0)
	pillBadge.BackgroundColor3 = Color3.fromHex("#48C90E")
	pillBadge.ZIndex = container.ZIndex + 5
	UITheme.addCorner(pillBadge, 11)
	UITheme.applyStroke(pillBadge, 2, UITheme.Colors.Black)
	pillBadge.Parent = container

	local robuxIcon = Instance.new("ImageLabel")
	robuxIcon.Name = "RobuxIcon"
	robuxIcon.Size = UDim2.new(0.24, 0, 0.70, 0)
	robuxIcon.Position = UDim2.new(0, 4, 0.5, 0)
	robuxIcon.AnchorPoint = Vector2.new(0, 0.5)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Image = UITheme.Assets.Icon_Robux
	local robuxAspect = Instance.new("UIAspectRatioConstraint")
	robuxAspect.AspectRatio = 1.0
	robuxAspect.Parent = robuxIcon
	robuxIcon.ZIndex = pillBadge.ZIndex + 1
	robuxIcon.Parent = pillBadge

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name = "PriceLabel"
	priceLbl.Size = UDim2.new(0.70, 0, 1, 0)
	priceLbl.Position = UDim2.new(0.30, 0, 0, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font = UITheme.Fonts.Primary
	priceLbl.TextColor3 = UITheme.Colors.White
	priceLbl.Text = "4"
	priceLbl.TextScaled = true
	priceLbl.ZIndex = pillBadge.ZIndex + 1
	UITheme.addTextConstraint(priceLbl, 9, 14)
	UITheme.applyTextStroke(priceLbl, 2, UITheme.Colors.Black)
	priceLbl.Parent = pillBadge

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "TitleLabel"
	titleLbl.Size = UDim2.new(1.1, 0, 0.32, 0)
	titleLbl.Position = UDim2.new(0.5, 0, 1, 4)
	titleLbl.AnchorPoint = Vector2.new(0.5, 1)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = UITheme.Fonts.Primary
	titleLbl.TextColor3 = UITheme.Colors.White
	titleLbl.Text = "STARTER\nPACK"
	titleLbl.TextScaled = true
	titleLbl.ZIndex = container.ZIndex + 3
	UITheme.addTextConstraint(titleLbl, 10, 14)
	UITheme.applyTextStroke(titleLbl, 2.5, UITheme.Colors.Black)
	titleLbl.Parent = container

	local currentOffer = HUD_OFFERS[initialOfferIndex]

	local function applyOffer(offer: any)
		currentOffer = offer
		rays.ImageColor3 = offer.color
		icon.Image = offer.icon
		priceLbl.Text = tostring(offer.price)
		titleLbl.Text = offer.title
		valLbl.Visible = (offer.value ~= nil)
		if offer.value then
			valLbl.Text = offer.value
		end
	end

	applyOffer(currentOffer)

	container.Activated:Connect(function()
		local tDown = TweenService:Create(uiScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.9 })
		tDown:Play()
		tDown.Completed:Once(function()
			local tUp = TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 })
			tUp:Play()
		end)
		Remotes.MetaAction:FireServer("BuyShopItem", currentOffer.id)
	end)

	return {
		container = container,
		rays = rays,
		icon = icon,
		uiScale = uiScale,
		applyOffer = applyOffer,
		getOffer = function() return currentOffer end,
	}
end

local promoSlotTop = createFloatingOfferSlot(rightPromoGroup, 1, 1)
local promoSlotBottom = createFloatingOfferSlot(rightPromoGroup, 2, 2)]]

local s3, e3 = string.find(src, old_right_promo, 1, true)
if not s3 then
    return "FAILED: old_right_promo not found"
end
src = string.sub(src, 1, s3 - 1) .. new_right_promo .. string.sub(src, e3 + 1)

-- 4. CurrencyGroup (AnchorPoint (0, 1), Position {0.01, 0}, {0.98, 0}, proportional cash icon and plus buttons)
local old_currency = [[	local currencyGroup = Instance.new("Frame")
	currencyGroup.Name = "CurrencyGroup"
	currencyGroup.Size = UDim2.new(0.24, 0, 0.11, 0)
	currencyGroup.AnchorPoint = Vector2.new(0, 1)
	currencyGroup.Position = UDim2.new(0.014, 0, 0.980, 0)
	currencyGroup.BackgroundTransparency = 1
	currencyGroup.ZIndex = 15
	currencyGroup.Parent = lobbyHud

	local hudSizeConstraint = Instance.new("UISizeConstraint")
	hudSizeConstraint.MinSize = Vector2.new(220, 56)
	hudSizeConstraint.MaxSize = Vector2.new(460, 110)
	hudSizeConstraint.Parent = currencyGroup

	-- Row 1: Friends Boost
	local rowFriends = Instance.new("Frame")
	rowFriends.Name = "Row_FriendsBoost"
	rowFriends.Size = UDim2.new(1, 0, 0.44, 0)
	rowFriends.Position = UDim2.new(0, 0, 0, 0)
	rowFriends.BackgroundTransparency = 1
	rowFriends.ZIndex = 16
	rowFriends.Parent = currencyGroup

	friendsLabel = Instance.new("TextLabel")
	friendsLabel.Name = "FriendsLabel"
	friendsLabel.Size = UDim2.new(0.80, 0, 0.90, 0)
	friendsLabel.Position = UDim2.new(0, 0, 0.5, 0)
	friendsLabel.AnchorPoint = Vector2.new(0, 0.5)
	friendsLabel.BackgroundTransparency = 1
	friendsLabel.Font = Enum.Font.FredokaOne
	friendsLabel.Text = "FRIENDS BOOST: +0%"
	friendsLabel.TextScaled = true
	friendsLabel.TextXAlignment = Enum.TextXAlignment.Left
	friendsLabel.TextColor3 = Color3.fromRGB(255, 210, 31)
	friendsLabel.ZIndex = 17

	local friendsSizeConstraint = Instance.new("UITextSizeConstraint")
	friendsSizeConstraint.MinTextSize = 14
	friendsSizeConstraint.MaxTextSize = 36
	friendsSizeConstraint.Parent = friendsLabel

	local friendsGradient = Instance.new("UIGradient")
	friendsGradient.Color = ColorSequence.new(Color3.fromRGB(255, 235, 80), Color3.fromRGB(255, 180, 0))
	friendsGradient.Rotation = 90
	friendsGradient.Parent = friendsLabel

	local friendsStroke = Instance.new("UIStroke")
	friendsStroke.Thickness = 3
	friendsStroke.Color = Color3.fromRGB(70, 40, 0)
	friendsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	friendsStroke.LineJoinMode = Enum.LineJoinMode.Round
	friendsStroke.Parent = friendsLabel

	local friendsScale = Instance.new("UIScale")
	friendsScale.Scale = 1
	friendsScale.Parent = friendsLabel
	friendsLabel.Parent = rowFriends

	-- Yellow Plus Button (next to Friends Boost)
	local btnAddFriend = Instance.new("TextButton")
	btnAddFriend.Name = "BtnAddFriend"
	btnAddFriend.Size = UDim2.new(0.18, 0, 1.30, 0)
	btnAddFriend.Position = UDim2.new(0.82, 0, 0.5, 0)
	btnAddFriend.AnchorPoint = Vector2.new(0, 0.5)
	btnAddFriend.BackgroundColor3 = Color3.fromRGB(255, 225, 60)
	btnAddFriend.AutoButtonColor = false
	btnAddFriend.Active = true
	btnAddFriend.Text = ""
	btnAddFriend.ZIndex = 18

	local friendBtnCorner = Instance.new("UICorner")
	friendBtnCorner.CornerRadius = UDim.new(0.2, 0)
	friendBtnCorner.Parent = btnAddFriend

	local friendBtnAspect = Instance.new("UIAspectRatioConstraint")
	friendBtnAspect.AspectRatio = 1.0
	friendBtnAspect.Parent = btnAddFriend

	local friendBtnGradient = Instance.new("UIGradient")
	friendBtnGradient.Color = ColorSequence.new(Color3.fromRGB(255, 225, 60), Color3.fromRGB(255, 175, 0))
	friendBtnGradient.Rotation = 90
	friendBtnGradient.Parent = btnAddFriend

	local friendBtnStroke = Instance.new("UIStroke")
	friendBtnStroke.Thickness = 3
	friendBtnStroke.Color = Color3.fromRGB(70, 40, 0)
	friendBtnStroke.LineJoinMode = Enum.LineJoinMode.Round
	friendBtnStroke.Parent = btnAddFriend

	local friendBtnHighlight = Instance.new("Frame")
	friendBtnHighlight.Name = "Highlight"
	friendBtnHighlight.Size = UDim2.new(0.76, 0, 0.14, 0)
	friendBtnHighlight.Position = UDim2.new(0.5, 0, 0.08, 0)
	friendBtnHighlight.AnchorPoint = Vector2.new(0.5, 0)
	friendBtnHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	friendBtnHighlight.BackgroundTransparency = 0.45
	friendBtnHighlight.BorderSizePixel = 0
	friendBtnHighlight.ZIndex = 19
	local friendHighlightCorner = Instance.new("UICorner")
	friendHighlightCorner.CornerRadius = UDim.new(0.5, 0)
	friendHighlightCorner.Parent = friendBtnHighlight
	friendBtnHighlight.Parent = btnAddFriend

	local friendBtnPlus = Instance.new("TextLabel")
	friendBtnPlus.Name = "PlusIcon"
	friendBtnPlus.Size = UDim2.fromScale(1, 1)
	friendBtnPlus.BackgroundTransparency = 1
	friendBtnPlus.Text = "+"
	friendBtnPlus.Font = Enum.Font.FredokaOne
	friendBtnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
	friendBtnPlus.TextScaled = true
	friendBtnPlus.ZIndex = 20
	local friendPlusStroke = Instance.new("UIStroke")
	friendPlusStroke.Thickness = 2
	friendPlusStroke.Color = Color3.fromRGB(70, 40, 0)
	friendPlusStroke.Parent = friendBtnPlus
	friendBtnPlus.Parent = btnAddFriend

	btnAddFriend.Parent = rowFriends

	btnAddFriend.Activated:Connect(function()
		pcall(function()
			SocialService:PromptGameInvite(localPlayer)
		end)
	end)

	-- Row 2: Cash Display (Original object name: CashPill, transparent background)
	local cashPill = Instance.new("Frame")
	cashPill.Name = "CashPill"
	cashPill.Size = UDim2.new(1, 0, 0.52, 0)
	cashPill.Position = UDim2.new(0, 0, 0.48, 0)
	cashPill.BackgroundTransparency = 1
	cashPill.ZIndex = 16
	cashPill.Parent = currencyGroup

	local cashIconImg = Instance.new("ImageLabel")
	cashIconImg.Name = "CashIcon"
	cashIconImg.Size = UDim2.new(0.24, 0, 1.30, 0)
	cashIconImg.Position = UDim2.new(0, 0, 0.5, 0)
	cashIconImg.AnchorPoint = Vector2.new(0, 0.5)
	cashIconImg.BackgroundTransparency = 1
	cashIconImg.Image = UITheme.Assets.CashStack
	cashIconImg.ScaleType = Enum.ScaleType.Fit
	cashIconImg.ZIndex = cashPill.ZIndex + 2

	local cashIconAspect = Instance.new("UIAspectRatioConstraint")
	cashIconAspect.AspectRatio = 1.32
	cashIconAspect.Parent = cashIconImg

	local cashIconStroke = Instance.new("UIStroke")
	cashIconStroke.Thickness = 2
	cashIconStroke.Color = Color3.fromRGB(20, 70, 10)
	cashIconStroke.Parent = cashIconImg

	cashIconImg.Parent = cashPill

	cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "CashLabel"
	cashLabel.Size = UDim2.new(0.56, 0, 0.95, 0)
	cashLabel.Position = UDim2.new(0.23, 4, 0.5, 0)
	cashLabel.AnchorPoint = Vector2.new(0, 0.5)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Font = Enum.Font.FredokaOne
	cashLabel.Text = "$0"
	cashLabel.TextScaled = true
	cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	cashLabel.TextColor3 = Color3.fromRGB(120, 255, 30)
	cashLabel.ZIndex = cashPill.ZIndex + 3

	local cashSizeConstraint = Instance.new("UITextSizeConstraint")
	cashSizeConstraint.MinTextSize = 18
	cashSizeConstraint.MaxTextSize = 48
	cashSizeConstraint.Parent = cashLabel

	local cashGradient = Instance.new("UIGradient")
	cashGradient.Color = ColorSequence.new(Color3.fromRGB(170, 255, 60), Color3.fromRGB(60, 210, 0))
	cashGradient.Rotation = 90
	cashGradient.Parent = cashLabel

	local cashStroke = Instance.new("UIStroke")
	cashStroke.Thickness = 4
	cashStroke.Color = Color3.fromRGB(15, 60, 10)
	cashStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	cashStroke.LineJoinMode = Enum.LineJoinMode.Round
	cashStroke.Parent = cashLabel

	local cashShadow = Instance.new("TextLabel")
	cashShadow.Name = "CashShadow"
	cashShadow.Size = UDim2.fromScale(1, 1)
	cashShadow.Position = UDim2.fromOffset(0, 3)
	cashShadow.BackgroundTransparency = 1
	cashShadow.Font = Enum.Font.FredokaOne
	cashShadow.Text = "$0"
	cashShadow.TextScaled = true
	cashShadow.TextXAlignment = Enum.TextXAlignment.Left
	cashShadow.TextColor3 = Color3.fromRGB(15, 60, 10)
	cashShadow.TextTransparency = 0.5
	cashShadow.ZIndex = cashLabel.ZIndex - 1
	cashShadow.Parent = cashLabel

	local cashScale = Instance.new("UIScale")
	cashScale.Scale = 1
	cashScale.Parent = cashLabel

	cashLabel.Parent = cashPill

	-- Green Plus Button (next to money, slightly lower than yellow button)
	btnAddCash = Instance.new("TextButton")
	btnAddCash.Name = "BtnAddCash"
	btnAddCash.Size = UDim2.new(0.18, 0, 1.20, 0)
	btnAddCash.Position = UDim2.new(0.82, 0, 0.58, 0)
	btnAddCash.AnchorPoint = Vector2.new(0, 0.5)
	btnAddCash.BackgroundColor3 = Color3.fromRGB(90, 255, 40)
	btnAddCash.AutoButtonColor = false
	btnAddCash.Active = true
	btnAddCash.Text = ""
	btnAddCash.ZIndex = cashPill.ZIndex + 4

	local cashBtnCorner = Instance.new("UICorner")
	cashBtnCorner.CornerRadius = UDim.new(0.2, 0)
	cashBtnCorner.Parent = btnAddCash

	local cashBtnAspect = Instance.new("UIAspectRatioConstraint")
	cashBtnAspect.AspectRatio = 1.0
	cashBtnAspect.Parent = btnAddCash

	local cashBtnGradient = Instance.new("UIGradient")
	cashBtnGradient.Color = ColorSequence.new(Color3.fromRGB(90, 255, 40), Color3.fromRGB(20, 190, 0))
	cashBtnGradient.Rotation = 90
	cashBtnGradient.Parent = btnAddCash

	local cashBtnStroke = Instance.new("UIStroke")
	cashBtnStroke.Thickness = 3
	cashBtnStroke.Color = Color3.fromRGB(15, 70, 10)
	cashBtnStroke.LineJoinMode = Enum.LineJoinMode.Round
	cashBtnStroke.Parent = btnAddCash

	local cashBtnHighlight = Instance.new("Frame")
	cashBtnHighlight.Name = "Highlight"
	cashBtnHighlight.Size = UDim2.new(0.76, 0, 0.14, 0)
	cashBtnHighlight.Position = UDim2.new(0.5, 0, 0.08, 0)
	cashBtnHighlight.AnchorPoint = Vector2.new(0.5, 0)
	cashBtnHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cashBtnHighlight.BackgroundTransparency = 0.45
	cashBtnHighlight.BorderSizePixel = 0
	cashBtnHighlight.ZIndex = btnAddCash.ZIndex + 1
	local cashHighlightCorner = Instance.new("UICorner")
	cashHighlightCorner.CornerRadius = UDim.new(0.5, 0)
	cashHighlightCorner.Parent = cashBtnHighlight
	cashBtnHighlight.Parent = btnAddCash

	local cashBtnPlus = Instance.new("TextLabel")
	cashBtnPlus.Name = "PlusIcon"
	cashBtnPlus.Size = UDim2.fromScale(1, 1)
	cashBtnPlus.BackgroundTransparency = 1
	cashBtnPlus.Text = "+"
	cashBtnPlus.Font = Enum.Font.FredokaOne
	cashBtnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
	cashBtnPlus.TextScaled = true
	cashBtnPlus.ZIndex = btnAddCash.ZIndex + 2
	local cashPlusStroke = Instance.new("UIStroke")
	cashPlusStroke.Thickness = 2
	cashPlusStroke.Color = Color3.fromRGB(15, 70, 10)
	cashPlusStroke.Parent = cashBtnPlus
	cashBtnPlus.Parent = btnAddCash

	btnAddCash.Parent = cashPill

	-- Dynamic Hugging Layout
	local function updateLayoutPositions()
		if rowFriends.AbsoluteSize.X > 0 and friendsLabel.TextBounds.X > 0 then
			local gap = 8
			local btnW = btnAddFriend.AbsoluteSize.X
			local targetX = friendsLabel.TextBounds.X + gap
			local maxX = rowFriends.AbsoluteSize.X - btnW
			btnAddFriend.Position = UDim2.new(0, math.clamp(targetX, 40, math.max(40, maxX)), 0.5, 0)
		end
		if cashPill.AbsoluteSize.X > 0 and cashLabel.TextBounds.X > 0 then
			local iconW = cashIconImg.AbsoluteSize.X
			local gap = 8
			local btnW = btnAddCash.AbsoluteSize.X
			local targetX = iconW + cashLabel.TextBounds.X + gap
			local maxX = cashPill.AbsoluteSize.X - btnW
			btnAddCash.Position = UDim2.new(0, math.clamp(targetX, iconW + 40, math.max(iconW + 40, maxX)), 0.58, 0)
		end
	end]]

local new_currency = [[	local currencyGroup = Instance.new("Frame")
	currencyGroup.Name = "CurrencyGroup"
	currencyGroup.Size = UDim2.new(0.20, 0, 0.12, 0)
	currencyGroup.AnchorPoint = Vector2.new(0, 1)
	currencyGroup.Position = UDim2.new(0.01, 0, 0.98, 0)
	currencyGroup.BackgroundTransparency = 1
	currencyGroup.ZIndex = 15
	currencyGroup.Parent = lobbyHud

	local hudSizeConstraint = Instance.new("UISizeConstraint")
	hudSizeConstraint.MinSize = Vector2.new(160, 36)
	hudSizeConstraint.MaxSize = Vector2.new(460, 110)
	hudSizeConstraint.Parent = currencyGroup

	-- Row 1: Friends Boost
	local rowFriends = Instance.new("Frame")
	rowFriends.Name = "Row_FriendsBoost"
	rowFriends.Size = UDim2.new(1, 0, 0.46, 0)
	rowFriends.Position = UDim2.new(0, 0, 0, 0)
	rowFriends.BackgroundTransparency = 1
	rowFriends.ZIndex = 16
	rowFriends.Parent = currencyGroup

	friendsLabel = Instance.new("TextLabel")
	friendsLabel.Name = "FriendsLabel"
	friendsLabel.Size = UDim2.new(0.78, 0, 0.85, 0)
	friendsLabel.Position = UDim2.new(0, 0, 0.5, 0)
	friendsLabel.AnchorPoint = Vector2.new(0, 0.5)
	friendsLabel.BackgroundTransparency = 1
	friendsLabel.Font = Enum.Font.FredokaOne
	friendsLabel.Text = "FRIENDS BOOST: +0%"
	friendsLabel.TextScaled = true
	friendsLabel.TextXAlignment = Enum.TextXAlignment.Left
	friendsLabel.TextColor3 = Color3.fromRGB(255, 210, 31)
	friendsLabel.ZIndex = 17

	local friendsSizeConstraint = Instance.new("UITextSizeConstraint")
	friendsSizeConstraint.MinTextSize = 12
	friendsSizeConstraint.MaxTextSize = 36
	friendsSizeConstraint.Parent = friendsLabel

	local friendsGradient = Instance.new("UIGradient")
	friendsGradient.Color = ColorSequence.new(Color3.fromRGB(255, 235, 80), Color3.fromRGB(255, 180, 0))
	friendsGradient.Rotation = 90
	friendsGradient.Parent = friendsLabel

	local friendsStroke = Instance.new("UIStroke")
	friendsStroke.Thickness = 3
	friendsStroke.Color = Color3.fromRGB(70, 40, 0)
	friendsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	friendsStroke.LineJoinMode = Enum.LineJoinMode.Round
	friendsStroke.Parent = friendsLabel

	local friendsScale = Instance.new("UIScale")
	friendsScale.Scale = 1
	friendsScale.Parent = friendsLabel
	friendsLabel.Parent = rowFriends

	-- Yellow Plus Button (next to Friends Boost)
	local btnAddFriend = Instance.new("TextButton")
	btnAddFriend.Name = "BtnAddFriend"
	btnAddFriend.Size = UDim2.new(0.18, 0, 0.85, 0)
	btnAddFriend.Position = UDim2.new(0.80, 0, 0.5, 0)
	btnAddFriend.AnchorPoint = Vector2.new(0, 0.5)
	btnAddFriend.BackgroundColor3 = Color3.fromRGB(255, 225, 60)
	btnAddFriend.AutoButtonColor = false
	btnAddFriend.Active = true
	btnAddFriend.Text = ""
	btnAddFriend.ZIndex = 18

	local friendBtnCorner = Instance.new("UICorner")
	friendBtnCorner.CornerRadius = UDim.new(0.2, 0)
	friendBtnCorner.Parent = btnAddFriend

	local friendBtnAspect = Instance.new("UIAspectRatioConstraint")
	friendBtnAspect.AspectRatio = 1.0
	friendBtnAspect.Parent = btnAddFriend

	local friendBtnGradient = Instance.new("UIGradient")
	friendBtnGradient.Color = ColorSequence.new(Color3.fromRGB(255, 225, 60), Color3.fromRGB(255, 175, 0))
	friendBtnGradient.Rotation = 90
	friendBtnGradient.Parent = btnAddFriend

	local friendBtnStroke = Instance.new("UIStroke")
	friendBtnStroke.Thickness = 3
	friendBtnStroke.Color = Color3.fromRGB(70, 40, 0)
	friendBtnStroke.LineJoinMode = Enum.LineJoinMode.Round
	friendBtnStroke.Parent = btnAddFriend

	local friendBtnHighlight = Instance.new("Frame")
	friendBtnHighlight.Name = "Highlight"
	friendBtnHighlight.Size = UDim2.new(0.76, 0, 0.14, 0)
	friendBtnHighlight.Position = UDim2.new(0.5, 0, 0.08, 0)
	friendBtnHighlight.AnchorPoint = Vector2.new(0.5, 0)
	friendBtnHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	friendBtnHighlight.BackgroundTransparency = 0.45
	friendBtnHighlight.BorderSizePixel = 0
	friendBtnHighlight.ZIndex = 19
	local friendHighlightCorner = Instance.new("UICorner")
	friendHighlightCorner.CornerRadius = UDim.new(0.5, 0)
	friendHighlightCorner.Parent = friendBtnHighlight
	friendBtnHighlight.Parent = btnAddFriend

	local friendBtnPlus = Instance.new("TextLabel")
	friendBtnPlus.Name = "PlusIcon"
	friendBtnPlus.Size = UDim2.fromScale(1, 1)
	friendBtnPlus.BackgroundTransparency = 1
	friendBtnPlus.Text = "+"
	friendBtnPlus.Font = Enum.Font.FredokaOne
	friendBtnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
	friendBtnPlus.TextScaled = true
	friendBtnPlus.ZIndex = 20
	local friendPlusStroke = Instance.new("UIStroke")
	friendPlusStroke.Thickness = 2
	friendPlusStroke.Color = Color3.fromRGB(70, 40, 0)
	friendPlusStroke.Parent = friendBtnPlus
	friendBtnPlus.Parent = btnAddFriend

	btnAddFriend.Parent = rowFriends

	btnAddFriend.Activated:Connect(function()
		pcall(function()
			SocialService:PromptGameInvite(localPlayer)
		end)
	end)

	-- Row 2: Cash Display (Original object name: CashPill, transparent background)
	local cashPill = Instance.new("Frame")
	cashPill.Name = "CashPill"
	cashPill.Size = UDim2.new(1, 0, 0.48, 0)
	cashPill.Position = UDim2.new(0, 0, 0.52, 0)
	cashPill.BackgroundTransparency = 1
	cashPill.ZIndex = 16
	cashPill.Parent = currencyGroup

	local cashIconImg = Instance.new("ImageLabel")
	cashIconImg.Name = "CashIcon"
	cashIconImg.Size = UDim2.new(0.20, 0, 0.85, 0)
	cashIconImg.Position = UDim2.new(0, 0, 0.5, 0)
	cashIconImg.AnchorPoint = Vector2.new(0, 0.5)
	cashIconImg.BackgroundTransparency = 1
	cashIconImg.Image = UITheme.Assets.CashStack
	cashIconImg.ScaleType = Enum.ScaleType.Fit
	cashIconImg.ZIndex = cashPill.ZIndex + 2

	local cashIconAspect = Instance.new("UIAspectRatioConstraint")
	cashIconAspect.AspectRatio = 1.32
	cashIconAspect.Parent = cashIconImg

	local cashIconStroke = Instance.new("UIStroke")
	cashIconStroke.Thickness = 2
	cashIconStroke.Color = Color3.fromRGB(20, 70, 10)
	cashIconStroke.Parent = cashIconImg

	cashIconImg.Parent = cashPill

	cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "CashLabel"
	cashLabel.Size = UDim2.new(0.58, 0, 0.85, 0)
	cashLabel.Position = UDim2.new(0.20, 4, 0.5, 0)
	cashLabel.AnchorPoint = Vector2.new(0, 0.5)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Font = Enum.Font.FredokaOne
	cashLabel.Text = "$0"
	cashLabel.TextScaled = true
	cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	cashLabel.TextColor3 = Color3.fromRGB(120, 255, 30)
	cashLabel.ZIndex = cashPill.ZIndex + 3

	local cashSizeConstraint = Instance.new("UITextSizeConstraint")
	cashSizeConstraint.MinTextSize = 14
	cashSizeConstraint.MaxTextSize = 48
	cashSizeConstraint.Parent = cashLabel

	local cashGradient = Instance.new("UIGradient")
	cashGradient.Color = ColorSequence.new(Color3.fromRGB(170, 255, 60), Color3.fromRGB(60, 210, 0))
	cashGradient.Rotation = 90
	cashGradient.Parent = cashLabel

	local cashStroke = Instance.new("UIStroke")
	cashStroke.Thickness = 4
	cashStroke.Color = Color3.fromRGB(15, 60, 10)
	cashStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	cashStroke.LineJoinMode = Enum.LineJoinMode.Round
	cashStroke.Parent = cashLabel

	local cashShadow = Instance.new("TextLabel")
	cashShadow.Name = "CashShadow"
	cashShadow.Size = UDim2.fromScale(1, 1)
	cashShadow.Position = UDim2.fromOffset(0, 3)
	cashShadow.BackgroundTransparency = 1
	cashShadow.Font = Enum.Font.FredokaOne
	cashShadow.Text = "$0"
	cashShadow.TextScaled = true
	cashShadow.TextXAlignment = Enum.TextXAlignment.Left
	cashShadow.TextColor3 = Color3.fromRGB(15, 60, 10)
	cashShadow.TextTransparency = 0.5
	cashShadow.ZIndex = cashLabel.ZIndex - 1
	cashShadow.Parent = cashLabel

	local cashScale = Instance.new("UIScale")
	cashScale.Scale = 1
	cashScale.Parent = cashLabel

	cashLabel.Parent = cashPill

	-- Green Plus Button (proportional to text row, UIAspectRatioConstraint 1:1)
	btnAddCash = Instance.new("TextButton")
	btnAddCash.Name = "BtnAddCash"
	btnAddCash.Size = UDim2.new(0.18, 0, 0.85, 0)
	btnAddCash.Position = UDim2.new(0.80, 0, 0.5, 0)
	btnAddCash.AnchorPoint = Vector2.new(0, 0.5)
	btnAddCash.BackgroundColor3 = Color3.fromRGB(90, 255, 40)
	btnAddCash.AutoButtonColor = false
	btnAddCash.Active = true
	btnAddCash.Text = ""
	btnAddCash.ZIndex = cashPill.ZIndex + 4

	local cashBtnCorner = Instance.new("UICorner")
	cashBtnCorner.CornerRadius = UDim.new(0.2, 0)
	cashBtnCorner.Parent = btnAddCash

	local cashBtnAspect = Instance.new("UIAspectRatioConstraint")
	cashBtnAspect.AspectRatio = 1.0
	cashBtnAspect.Parent = btnAddCash

	local cashBtnGradient = Instance.new("UIGradient")
	cashBtnGradient.Color = ColorSequence.new(Color3.fromRGB(90, 255, 40), Color3.fromRGB(20, 190, 0))
	cashBtnGradient.Rotation = 90
	cashBtnGradient.Parent = btnAddCash

	local cashBtnStroke = Instance.new("UIStroke")
	cashBtnStroke.Thickness = 3
	cashBtnStroke.Color = Color3.fromRGB(15, 70, 10)
	cashBtnStroke.LineJoinMode = Enum.LineJoinMode.Round
	cashBtnStroke.Parent = btnAddCash

	local cashBtnHighlight = Instance.new("Frame")
	cashBtnHighlight.Name = "Highlight"
	cashBtnHighlight.Size = UDim2.new(0.76, 0, 0.14, 0)
	cashBtnHighlight.Position = UDim2.new(0.5, 0, 0.08, 0)
	cashBtnHighlight.AnchorPoint = Vector2.new(0.5, 0)
	cashBtnHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cashBtnHighlight.BackgroundTransparency = 0.45
	cashBtnHighlight.BorderSizePixel = 0
	cashBtnHighlight.ZIndex = btnAddCash.ZIndex + 1
	local cashHighlightCorner = Instance.new("UICorner")
	cashHighlightCorner.CornerRadius = UDim.new(0.5, 0)
	cashHighlightCorner.Parent = cashBtnHighlight
	cashBtnHighlight.Parent = btnAddCash

	local cashBtnPlus = Instance.new("TextLabel")
	cashBtnPlus.Name = "PlusIcon"
	cashBtnPlus.Size = UDim2.fromScale(1, 1)
	cashBtnPlus.BackgroundTransparency = 1
	cashBtnPlus.Text = "+"
	cashBtnPlus.Font = Enum.Font.FredokaOne
	cashBtnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
	cashBtnPlus.TextScaled = true
	cashBtnPlus.ZIndex = btnAddCash.ZIndex + 2
	local cashPlusStroke = Instance.new("UIStroke")
	cashPlusStroke.Thickness = 2
	cashPlusStroke.Color = Color3.fromRGB(15, 70, 10)
	cashPlusStroke.Parent = cashBtnPlus
	cashBtnPlus.Parent = btnAddCash

	btnAddCash.Parent = cashPill

	-- Dynamic Hugging Layout
	local function updateLayoutPositions()
		if rowFriends.AbsoluteSize.X > 0 and friendsLabel.TextBounds.X > 0 then
			local gap = 6
			local btnW = btnAddFriend.AbsoluteSize.X
			local targetX = friendsLabel.TextBounds.X + gap
			local maxX = rowFriends.AbsoluteSize.X - btnW
			btnAddFriend.Position = UDim2.new(0, math.clamp(targetX, 30, math.max(30, maxX)), 0.5, 0)
		end
		if cashPill.AbsoluteSize.X > 0 and cashLabel.TextBounds.X > 0 then
			local iconW = cashIconImg.AbsoluteSize.X
			local gap = 6
			local btnW = btnAddCash.AbsoluteSize.X
			local targetX = iconW + cashLabel.TextBounds.X + gap
			local maxX = cashPill.AbsoluteSize.X - btnW
			btnAddCash.Position = UDim2.new(0, math.clamp(targetX, iconW + 30, math.max(iconW + 30, maxX)), 0.5, 0)
		end
	end]]

local s4, e4 = string.find(src, old_currency, 1, true)
if not s4 then
    return "FAILED: old_currency not found"
end
src = string.sub(src, 1, s4 - 1) .. new_currency .. string.sub(src, e4 + 1)

-- 5. Add Responsive UIScale hook across all HUD groups
local old_scale_hook = [[updateCashDisplay(p.Bux or 0)]]
local new_scale_hook = [[-- Responsive UIScale across all HUD groups (clamp(vpH / 1080, 0.6, 1.0) * 0.85 on touch)
local hudGroupScales: { UIScale } = {}

local function registerHudGroupScale(frame: GuiObject): UIScale
	local sc = frame:FindFirstChild("GroupUIScale") :: UIScale?
	if not sc then
		sc = Instance.new("UIScale")
		sc.Name = "GroupUIScale"
		sc.Parent = frame
	end
	table.insert(hudGroupScales, sc)
	return sc
end

registerHudGroupScale(currencyGroup)
registerHudGroupScale(leftNavGroup)
registerHudGroupScale(rightPromoGroup)
registerHudGroupScale(topRightBar)

local function updateAllHudScales()
	local cam = Workspace.CurrentCamera
	local vpH = if cam then cam.ViewportSize.Y else 1080
	local baseScale = math.clamp(vpH / 1080, 0.6, 1.0)
	local isMobileTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local finalScale = if isMobileTouch then baseScale * 0.85 else baseScale
	for _, sc in ipairs(hudGroupScales) do
		sc.Scale = finalScale
	end
end

if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAllHudScales)
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAllHudScales)
		updateAllHudScales()
	end
end)
updateAllHudScales()

	updateCashDisplay(p.Bux or 0)]]

local s5, e5 = string.find(src, old_scale_hook, 1, true)
if not s5 then
    return "FAILED: old_scale_hook not found"
end
src = string.sub(src, 1, s5 - 1) .. new_scale_hook .. string.sub(src, e5 + 1)

clientScript.Source = src
return "SUCCESS! MatchClient updated in Studio. New length: " .. #src
'''

with open("scratch/run_update_hud.luau", "w", encoding="utf-8") as f:
    f.write(luau_updater)

print("Generated scratch/run_update_hud.luau")

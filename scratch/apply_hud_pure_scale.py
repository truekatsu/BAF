import re

with open(r"d:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau", "r", encoding="utf-8") as f:
    src = f.read()

# 1. Replace LeftNavGroup & Buttons up to end of makeNavButton
p_left_start = src.find('-- Left Nav Group (Shop, Skins, Titles, Index, Profile')
p_left_end = src.find('-- Right Side: Starter Pack & INF REROLLS stacked with UIListLayout')
if p_left_start == -1 or p_left_end == -1:
    raise Exception(f"Could not find LeftNavGroup section: start={p_left_start}, end={p_left_end}")

new_left_nav = """-- Left Nav Group (Shop, Skins, Titles, Index, Profile in 1 straight vertical column + attached FREE tag)
local leftNavGroup = Instance.new("Frame")
leftNavGroup.Name = "LeftNavGroup"
leftNavGroup.AnchorPoint = Vector2.new(0, 0)
leftNavGroup.Position = UDim2.new(0.01, 0, 0.11, 0)
leftNavGroup.Size = UDim2.new(0.12, 0, 0.64, 0)
leftNavGroup.BackgroundTransparency = 1
leftNavGroup.ZIndex = 15
leftNavGroup.Parent = lobbyHud

local leftNavLayout = Instance.new("UIListLayout")
leftNavLayout.Name = "UIListLayout"
leftNavLayout.FillDirection = Enum.FillDirection.Vertical
leftNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
leftNavLayout.VerticalAlignment = Enum.VerticalAlignment.Top
leftNavLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftNavLayout.Padding = UDim.new(0.012, 0)
leftNavLayout.Parent = leftNavGroup

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
		btn.Size = UDim2.new(1, 0, 0.18, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 16
		btn.Parent = leftNavGroup

		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1.0
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = btn

		local btnSizeConstraint = Instance.new("UISizeConstraint")
		btnSizeConstraint.MinSize = Vector2.new(44, 44)
		btnSizeConstraint.Parent = btn

		local textConstraint = Instance.new("UITextSizeConstraint")
		textConstraint.MinTextSize = 10
		textConstraint.MaxTextSize = 24
		textConstraint.Parent = btn

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

	-- FREE Tag attached to Shop button (child of Shop, anchored to its top)
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

	-- Index Badge moved to top-right corner of Index button, small, TextScaled, Max 12, ZIndex above button
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
	badgeTextConstraint.MaxTextSize = 12
	badgeTextConstraint.Parent = badge
	UITheme.addCorner(badge, 6)
	UITheme.applyStroke(badge, 1.5, UITheme.Colors.Black)
end
"""

src = src[:p_left_start] + new_left_nav + src[p_left_end:]

# 2. Replace RightPromoGroup & FloatingOfferSlot
p_right_start = src.find('-- Right Side: Starter Pack & INF REROLLS stacked with UIListLayout')
p_right_end = src.find('-- Top-Left Currency & Friends Boost HUD (Modern Cartoon Style)')
if p_right_start == -1 or p_right_end == -1:
    raise Exception(f"Could not find RightPromo section: start={p_right_start}, end={p_right_end}")

new_right_promo = """-- Right Side: Starter Pack, 2X WIN, 2X, INF REROLLS stacked with UIListLayout
local rightPromoGroup = Instance.new("Frame")
rightPromoGroup.Name = "RightPromoGroup"
rightPromoGroup.AnchorPoint = Vector2.new(1, 0.5)
rightPromoGroup.Position = UDim2.new(0.99, 0, 0.5, 0)
rightPromoGroup.Size = UDim2.new(0.14, 0, 0.30, 0)
rightPromoGroup.BackgroundTransparency = 1
rightPromoGroup.ZIndex = 15
rightPromoGroup.Parent = lobbyHud

local rightPromoLayout = Instance.new("UIListLayout")
rightPromoLayout.Name = "UIListLayout"
rightPromoLayout.FillDirection = Enum.FillDirection.Vertical
rightPromoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightPromoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rightPromoLayout.Padding = UDim.new(0.02, 0)
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
	aspect.DominantAxis = Enum.DominantAxis.Height
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

	-- Robux Price Badge Pill (Centered above product icon, ClipsDescendants = true)
	local pillBadge = Instance.new("Frame")
	pillBadge.Name = "RobuxPill"
	pillBadge.Size = UDim2.new(0.8, 0, 0.24, 0)
	pillBadge.Position = UDim2.new(0.5, 0, 0.04, 0)
	pillBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	pillBadge.BackgroundColor3 = Color3.fromHex("#48C90E")
	pillBadge.ClipsDescendants = true
	pillBadge.ZIndex = container.ZIndex + 5
	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(0.5, 0)
	pillCorner.Parent = pillBadge
	UITheme.applyStroke(pillBadge, 2, UITheme.Colors.Black)
	pillBadge.Parent = container

	local pillPad = Instance.new("UIPadding")
	pillPad.PaddingLeft = UDim.new(0.08, 0)
	pillPad.PaddingRight = UDim.new(0.08, 0)
	pillPad.PaddingTop = UDim.new(0, 0)
	pillPad.PaddingBottom = UDim.new(0, 0)
	pillPad.Parent = pillBadge

	local pillList = Instance.new("UIListLayout")
	pillList.FillDirection = Enum.FillDirection.Horizontal
	pillList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pillList.VerticalAlignment = Enum.VerticalAlignment.Center
	pillList.Padding = UDim.new(0.06, 0)
	pillList.SortOrder = Enum.SortOrder.LayoutOrder
	pillList.Parent = pillBadge

	local robuxIcon = Instance.new("ImageLabel")
	robuxIcon.Name = "RobuxIcon"
	robuxIcon.LayoutOrder = 1
	robuxIcon.Size = UDim2.new(1, 0, 0.75, 0)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Image = UITheme.Assets.Icon_Robux
	local robuxAspect = Instance.new("UIAspectRatioConstraint")
	robuxAspect.AspectRatio = 1.0
	robuxAspect.DominantAxis = Enum.DominantAxis.Height
	robuxAspect.Parent = robuxIcon
	robuxIcon.ZIndex = pillBadge.ZIndex + 1
	robuxIcon.Parent = pillBadge

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name = "PriceLabel"
	priceLbl.LayoutOrder = 2
	priceLbl.Size = UDim2.new(0.55, 0, 0.85, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font = UITheme.Fonts.Primary
	priceLbl.TextColor3 = UITheme.Colors.White
	priceLbl.Text = "4"
	priceLbl.TextScaled = true
	priceLbl.RichText = false
	priceLbl.TextXAlignment = Enum.TextXAlignment.Center
	priceLbl.TextYAlignment = Enum.TextYAlignment.Center
	priceLbl.ZIndex = pillBadge.ZIndex + 1
	local priceConstraint = Instance.new("UITextSizeConstraint")
	priceConstraint.MinTextSize = 10
	priceConstraint.MaxTextSize = 26
	priceConstraint.Parent = priceLbl
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
	titleLbl.Text = "STARTER\\nPACK"
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
local promoSlotBottom = createFloatingOfferSlot(rightPromoGroup, 2, 2)
local btnPromoStarter = promoSlotTop.container
local btnPromoStreak = promoSlotBottom.container
"""

src = src[:p_right_start] + new_right_promo + src[p_right_end:]

# 3. Replace CurrencyGroup
p_curr_start = src.find('do\n\tlocal currencyGroup = Instance.new("Frame")')
p_curr_end = src.find('-- Opponent Needed Notification Banner (3s wait broadcast to idle players)')
if p_curr_start == -1 or p_curr_end == -1:
    raise Exception(f"Could not find CurrencyGroup section: start={p_curr_start}, end={p_curr_end}")

new_currency = """do
	local currencyGroup = Instance.new("Frame")
	currencyGroup.Name = "CurrencyGroup"
	currencyGroup.Size = UDim2.new(0.26, 0, 0.20, 0)
	currencyGroup.AnchorPoint = Vector2.new(0, 1)
	currencyGroup.Position = UDim2.new(0.01, 0, 0.98, 0)
	currencyGroup.BackgroundTransparency = 1
	currencyGroup.ZIndex = 15
	currencyGroup.Parent = lobbyHud

	local curLayout = Instance.new("UIListLayout")
	curLayout.Name = "CurLayout"
	curLayout.FillDirection = Enum.FillDirection.Vertical
	curLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	curLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	curLayout.Padding = UDim.new(0.04, 0)
	curLayout.SortOrder = Enum.SortOrder.LayoutOrder
	curLayout.Parent = currencyGroup

	-- Row A: Friends Boost
	local rowFriends = Instance.new("Frame")
	rowFriends.Name = "Row_FriendsBoost"
	rowFriends.Size = UDim2.new(1, 0, 0.42, 0)
	rowFriends.LayoutOrder = 1
	rowFriends.BackgroundTransparency = 1
	rowFriends.ZIndex = 16
	rowFriends.Parent = currencyGroup

	local rowALayout = Instance.new("UIListLayout")
	rowALayout.FillDirection = Enum.FillDirection.Horizontal
	rowALayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowALayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowALayout.Padding = UDim.new(0.02, 0)
	rowALayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowALayout.Parent = rowFriends

	friendsLabel = Instance.new("TextLabel")
	friendsLabel.Name = "FriendsLabel"
	friendsLabel.LayoutOrder = 1
	friendsLabel.Size = UDim2.new(0.78, 0, 1, 0)
	friendsLabel.BackgroundTransparency = 1
	friendsLabel.Font = Enum.Font.FredokaOne
	friendsLabel.Text = "FRIENDS BOOST: +0%"
	friendsLabel.TextScaled = true
	friendsLabel.TextXAlignment = Enum.TextXAlignment.Left
	friendsLabel.TextYAlignment = Enum.TextYAlignment.Center
	friendsLabel.TextColor3 = Color3.fromRGB(255, 210, 31)
	friendsLabel.ZIndex = 17

	local friendsSizeConstraint = Instance.new("UITextSizeConstraint")
	friendsSizeConstraint.MinTextSize = 12
	friendsSizeConstraint.MaxTextSize = 30
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

	friendsLabel.Parent = rowFriends

	-- Yellow Plus Button (next to Friends Boost)
	local btnAddFriend = Instance.new("TextButton")
	btnAddFriend.Name = "BtnAddFriend"
	btnAddFriend.LayoutOrder = 2
	btnAddFriend.Size = UDim2.new(0.2, 0, 1, 0)
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
	friendBtnAspect.DominantAxis = Enum.DominantAxis.Height
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

	-- Row B: Cash Display (Original object name: CashPill, transparent background)
	local cashPill = Instance.new("Frame")
	cashPill.Name = "CashPill"
	cashPill.Size = UDim2.new(1, 0, 0.54, 0)
	cashPill.LayoutOrder = 2
	cashPill.BackgroundTransparency = 1
	cashPill.ZIndex = 16
	cashPill.Parent = currencyGroup

	local rowBLayout = Instance.new("UIListLayout")
	rowBLayout.FillDirection = Enum.FillDirection.Horizontal
	rowBLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowBLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowBLayout.Padding = UDim.new(0.03, 0)
	rowBLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowBLayout.Parent = cashPill

	local cashIconImg = Instance.new("ImageLabel")
	cashIconImg.Name = "CashIcon"
	cashIconImg.LayoutOrder = 1
	cashIconImg.Size = UDim2.new(1, 0, 1, 0)
	cashIconImg.BackgroundTransparency = 1
	cashIconImg.Image = UITheme.Assets.CashStack
	cashIconImg.ScaleType = Enum.ScaleType.Fit
	cashIconImg.ZIndex = cashPill.ZIndex + 2

	local cashIconAspect = Instance.new("UIAspectRatioConstraint")
	cashIconAspect.AspectRatio = 1.0
	cashIconAspect.DominantAxis = Enum.DominantAxis.Height
	cashIconAspect.Parent = cashIconImg

	local cashIconStroke = Instance.new("UIStroke")
	cashIconStroke.Thickness = 2
	cashIconStroke.Color = Color3.fromRGB(20, 70, 10)
	cashIconStroke.Parent = cashIconImg

	cashIconImg.Parent = cashPill

	cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "CashLabel"
	cashLabel.LayoutOrder = 2
	cashLabel.Size = UDim2.new(0.5, 0, 1, 0)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Font = Enum.Font.FredokaOne
	cashLabel.Text = "$0"
	cashLabel.TextScaled = true
	cashLabel.TextTruncate = Enum.TextTruncate.None
	cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	cashLabel.TextYAlignment = Enum.TextYAlignment.Center
	cashLabel.TextColor3 = Color3.fromRGB(120, 255, 30)
	cashLabel.ZIndex = cashPill.ZIndex + 3

	local cashSizeConstraint = Instance.new("UITextSizeConstraint")
	cashSizeConstraint.MinTextSize = 16
	cashSizeConstraint.MaxTextSize = 44
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

	cashLabel.Parent = cashPill

	-- Green Plus Button (next to money)
	btnAddCash = Instance.new("TextButton")
	btnAddCash.Name = "BtnAddCash"
	btnAddCash.LayoutOrder = 3
	btnAddCash.Size = UDim2.new(1, 0, 0.8, 0)
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
	cashBtnAspect.DominantAxis = Enum.DominantAxis.Height
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

	cashLabel:GetPropertyChangedSignal("Text"):Connect(function()
		if cashShadow and cashShadow.Text ~= cashLabel.Text then
			cashShadow.Text = cashLabel.Text
		end
	end)

	-- Button Hover & Press Animation
	local function setupHudButtonAnim(btn: TextButton)
		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn

		local isHovered = false
		local isPressed = false

		btn.MouseEnter:Connect(function()
			isHovered = true
			if not isPressed then
				TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.1 }):Play()
			end
		end)

		btn.MouseLeave:Connect(function()
			isHovered = false
			if not isPressed then
				TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
			end
		end)

		btn.MouseButton1Down:Connect(function()
			isPressed = true
			TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
		end)

		btn.MouseButton1Up:Connect(function()
			isPressed = false
			local target = if isHovered then 1.1 else 1.0
			TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
		end)
	end

	setupHudButtonAnim(btnAddFriend)
	setupHudButtonAnim(btnAddCash)

	-- Value Pop & Count-Up Tween Animations
	local lastObservedCash: number? = nil
	local lastObservedBoost: number? = nil

	local function popCashText()
		local origColor = cashLabel.TextColor3
		cashLabel.TextColor3 = Color3.fromRGB(220, 255, 180)
		task.delay(0.12, function()
			if cashLabel then cashLabel.TextColor3 = origColor end
		end)
	end

	local function popFriendsText()
		local origColor = friendsLabel.TextColor3
		friendsLabel.TextColor3 = Color3.fromRGB(255, 255, 180)
		task.delay(0.12, function()
			if friendsLabel then friendsLabel.TextColor3 = origColor end
		end)
	end

	local activeCashTweenVal: NumberValue? = nil
	HUD.updateCash = function(targetBux: number)
		if lastObservedCash == nil then
			lastObservedCash = targetBux
			cashLabel.Text = `$` .. tostring(targetBux)
			if cashShadow then cashShadow.Text = cashLabel.Text end
			return
		end

		if lastObservedCash ~= targetBux then
			local startBux = lastObservedCash
			lastObservedCash = targetBux
			popCashText()

			if activeCashTweenVal then
				activeCashTweenVal:Destroy()
				activeCashTweenVal = nil
			end

			local valObj = Instance.new("NumberValue")
			valObj.Value = startBux
			activeCashTweenVal = valObj

			local tw = TweenService:Create(valObj, TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = targetBux })
			valObj.Changed:Connect(function(v)
				local rounded = math.floor(v)
				cashLabel.Text = `$` .. tostring(rounded)
				if cashShadow then cashShadow.Text = cashLabel.Text end
			end)
			tw:Play()
			tw.Completed:Connect(function()
				cashLabel.Text = `$` .. tostring(targetBux)
				if cashShadow then cashShadow.Text = cashLabel.Text end
				valObj:Destroy()
				if activeCashTweenVal == valObj then
					activeCashTweenVal = nil
				end
			end)
		end
	end

	HUD.updateFriends = function(targetBoost: number)
		if lastObservedBoost == nil then
			lastObservedBoost = targetBoost
			friendsLabel.Text = `FRIENDS BOOST: +{targetBoost}%`
			return
		end

		if lastObservedBoost ~= targetBoost then
			lastObservedBoost = targetBoost
			popFriendsText()
			friendsLabel.Text = `FRIENDS BOOST: +{targetBoost}%`
		end
	end
end
"""

src = src[:p_curr_start] + new_currency + src[p_curr_end:]

# 4. Remove updateAllHudScales block (lines 1515-1573)
p_scale_start = src.find('-- Responsive UIScale across all HUD groups')
p_scale_end = src.find('opponentAlertBanner.Parent = lobbyHud')
if p_scale_start == -1 or p_scale_end == -1:
    raise Exception(f"Could not find UIScale block: start={p_scale_start}, end={p_scale_end}")

src = src[:p_scale_start] + src[p_scale_end:]

with open(r"d:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau", "w", encoding="utf-8") as f:
    f.write(src)

print("MatchClient.client.luau successfully patched!")

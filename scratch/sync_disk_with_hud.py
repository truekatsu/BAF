import re

with open('src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    src = f.read()

# 1. ScreenInsets
old_inset = '''screenGui.DisplayOrder = 50

screenGui.IgnoreGuiInset = true

screenGui.Parent = playerGui'''

new_inset = '''screenGui.DisplayOrder = 50

screenGui.IgnoreGuiInset = false

screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets

screenGui.Parent = playerGui'''

if old_inset in src:
    src = src.replace(old_inset, new_inset)
    print("Step 1 (ScreenInsets) applied to disk")
else:
    print("Warning: Step 1 old_inset not matched directly, checking normalized...")
    # try normalized
    src = src.replace("screenGui.IgnoreGuiInset = true", "screenGui.IgnoreGuiInset = false\n\nscreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets")
    print("Applied normalized Step 1")

# 2. Left Nav
old_left_nav_pattern = r'-- Left Vertical Nav Column \(FREE, SHOP, SKINS, TITLES, INDEX, PROFILE\).*?UITheme\.applyStroke\(freeBadge, 2\.5, UITheme\.Colors\.Black\)'
new_left_nav = '''-- Left Nav Group (Shop, Skins, Titles, Index, Profile in 2 columns + attached FREE tag)
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
end'''

src, count2 = re.subn(old_left_nav_pattern, new_left_nav, src, flags=re.DOTALL)
print(f"Step 2 (Left Nav) applied to disk: {count2} matches")

# 3. Right Promo
old_right_promo_pattern = r'-- Right Promo Column \(Starter Pack & 2x Streak\).*?btnPromoStreak = bStreak\s*end'
new_right_promo = '''-- Right Side: Starter Pack & INF REROLLS stacked with UIListLayout
local rightPromoGroup = Instance.new("Frame")
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
local btnPromoStreak = promoSlotBottom.container'''

src, count3 = re.subn(old_right_promo_pattern, new_right_promo, src, flags=re.DOTALL)
print(f"Step 3 (Right Promo) applied to disk: {count3} matches")

# 4. CurrencyGroup
src = src.replace('currencyGroup.Size = UDim2.new(0.24, 0, 0.11, 0)', 'currencyGroup.Size = UDim2.new(0.20, 0, 0.12, 0)')
src = src.replace('currencyGroup.Position = UDim2.new(0.014, 0, 0.980, 0)', 'currencyGroup.Position = UDim2.new(0.01, 0, 0.98, 0)')
src = src.replace('hudSizeConstraint.MinSize = Vector2.new(220, 56)', 'hudSizeConstraint.MinSize = Vector2.new(160, 36)')
src = src.replace('rowFriends.Size = UDim2.new(1, 0, 0.44, 0)', 'rowFriends.Size = UDim2.new(1, 0, 0.46, 0)')
src = src.replace('friendsLabel.Size = UDim2.new(0.80, 0, 0.90, 0)', 'friendsLabel.Size = UDim2.new(0.78, 0, 0.85, 0)')
src = src.replace('btnAddFriend.Size = UDim2.new(0.18, 0, 1.30, 0)', 'btnAddFriend.Size = UDim2.new(0.18, 0, 0.85, 0)')
src = src.replace('btnAddFriend.Position = UDim2.new(0.82, 0, 0.5, 0)', 'btnAddFriend.Position = UDim2.new(0.80, 0, 0.5, 0)')
src = src.replace('cashPill.Size = UDim2.new(1, 0, 0.52, 0)', 'cashPill.Size = UDim2.new(1, 0, 0.48, 0)')
src = src.replace('cashPill.Position = UDim2.new(0, 0, 0.48, 0)', 'cashPill.Position = UDim2.new(0, 0, 0.52, 0)')
src = src.replace('cashIconImg.Size = UDim2.new(0.24, 0, 1.30, 0)', 'cashIconImg.Size = UDim2.new(0.20, 0, 0.85, 0)')
src = src.replace('cashLabel.Size = UDim2.new(0.56, 0, 0.95, 0)', 'cashLabel.Size = UDim2.new(0.58, 0, 0.85, 0)')
src = src.replace('cashLabel.Position = UDim2.new(0.23, 4, 0.5, 0)', 'cashLabel.Position = UDim2.new(0.20, 4, 0.5, 0)')
src = src.replace('btnAddCash.Size = UDim2.new(0.18, 0, 1.20, 0)', 'btnAddCash.Size = UDim2.new(0.18, 0, 0.85, 0)')
src = src.replace('btnAddCash.Position = UDim2.new(0.82, 0, 0.58, 0)', 'btnAddCash.Position = UDim2.new(0.80, 0, 0.5, 0)')

# 5. Responsive UIScale hook
scale_hook = '''-- Responsive UIScale across all HUD groups (clamp(vpH / 1080, 0.6, 1.0) * 0.85 on touch)
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

'''

if "opponentAlertBanner.Parent = lobbyHud" in src and "hudGroupScales" not in src:
    src = src.replace("opponentAlertBanner.Parent = lobbyHud", scale_hook + "opponentAlertBanner.Parent = lobbyHud")
    print("Step 5 (UIScale Hook) applied to disk")

with open('src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'w', encoding='utf-8') as f:
    f.write(src)

print("Disk file updated successfully!")

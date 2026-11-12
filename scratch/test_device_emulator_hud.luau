-- scratch/test_device_emulator_hud.luau
local HttpService = game:GetService("HttpService")

local function doBoxOverlap(a, b)
	return (a.x0 < b.x1 and a.x1 > b.x0 and a.y0 < b.y1 and a.y1 > b.y0)
end

local function makeBox(guiObj)
	local pos = guiObj.AbsolutePosition
	local size = guiObj.AbsoluteSize
	return {
		name = guiObj.Name,
		x0 = pos.X,
		y0 = pos.Y,
		x1 = pos.X + size.X,
		y1 = pos.Y + size.Y,
		w = size.X,
		h = size.Y,
	}
end

local devices = {
	{ name = "iPhone SE Landscape", w = 667, h = 375, touch = true },
	{ name = "iPhone SE Portrait", w = 375, h = 667, touch = true },
	{ name = "iPhone 14 Landscape", w = 844, h = 390, touch = true },
	{ name = "iPhone 14 Portrait", w = 390, h = 844, touch = true },
	{ name = "Small Android Landscape", w = 640, h = 360, touch = true },
	{ name = "Small Android Portrait", w = 360, h = 640, touch = true },
	{ name = "Desktop 1080p", w = 1920, h = 1080, touch = false },
}

local report = {}

for _, dev in ipairs(devices) do
	-- Root screen frame representing device viewport
	local screen = Instance.new("Frame")
	screen.Size = UDim2.fromOffset(dev.w, dev.h)
	
	local lobbyHud = Instance.new("Frame")
	lobbyHud.Name = "LobbyHUD"
	lobbyHud.Size = UDim2.fromScale(1, 1)
	lobbyHud.Parent = screen
	
	-- 1. Left Nav Group
	local leftNavGroup = Instance.new("Frame")
	leftNavGroup.Name = "LeftNavGroup"
	leftNavGroup.AnchorPoint = Vector2.new(0, 0)
	leftNavGroup.Position = UDim2.new(0.01, 0, 0.10, 0)
	leftNavGroup.Size = UDim2.new(1, 0, 1, 0)
	leftNavGroup.BackgroundTransparency = 1
	leftNavGroup.Parent = lobbyHud
	
	local leftNavGrid = Instance.new("UIGridLayout")
	leftNavGrid.CellSize = UDim2.new(0.06, 0, 0.10, 0)
	leftNavGrid.CellPadding = UDim2.new(0, 4, 0, 4)
	leftNavGrid.FillDirectionMaxCells = 2
	leftNavGrid.SortOrder = Enum.SortOrder.LayoutOrder
	leftNavGrid.Parent = leftNavGroup
	
	local buttons = { "Shop", "Skins", "Titles", "Index", "Profile" }
	local navBtns = {}
	for i, name in ipairs(buttons) do
		local btn = Instance.new("TextButton")
		btn.Name = "BtnNav" .. name
		btn.LayoutOrder = i
		btn.Parent = leftNavGroup
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1.0
		aspect.Parent = btn
		navBtns[name] = btn
	end
	
	-- FREE tag attached to Shop
	local freeTag = Instance.new("TextButton")
	freeTag.Name = "BtnNavFree"
	freeTag.AnchorPoint = Vector2.new(0.5, 0.5)
	freeTag.Position = UDim2.new(0.5, 0, 0, 0)
	freeTag.Size = UDim2.new(0.78, 0, 0.32, 0)
	freeTag.Parent = navBtns["Shop"]
	
	-- Index Badge inside Index button
	local indexBadge = Instance.new("TextLabel")
	indexBadge.Name = "IndexBadge"
	indexBadge.AnchorPoint = Vector2.new(1, 0)
	indexBadge.Position = UDim2.new(1, 0, 0, 0)
	indexBadge.Size = UDim2.new(0.55, 0, 0.28, 0)
	indexBadge.Parent = navBtns["Index"]
	
	-- 2. Currency Group
	local currencyGroup = Instance.new("Frame")
	currencyGroup.Name = "CurrencyGroup"
	currencyGroup.Size = UDim2.new(0.20, 0, 0.12, 0)
	currencyGroup.AnchorPoint = Vector2.new(0, 1)
	currencyGroup.Position = UDim2.new(0.01, 0, 0.98, 0)
	currencyGroup.Parent = lobbyHud
	
	local hudSizeConstraint = Instance.new("UISizeConstraint")
	hudSizeConstraint.MinSize = Vector2.new(160, 36)
	hudSizeConstraint.MaxSize = Vector2.new(460, 110)
	hudSizeConstraint.Parent = currencyGroup
	
	local rowFriends = Instance.new("Frame")
	rowFriends.Name = "Row_FriendsBoost"
	rowFriends.Size = UDim2.new(1, 0, 0.46, 0)
	rowFriends.Parent = currencyGroup
	
	local friendsLabel = Instance.new("TextLabel")
	friendsLabel.Size = UDim2.new(0.78, 0, 0.85, 0)
	friendsLabel.AnchorPoint = Vector2.new(0, 0.5)
	friendsLabel.Position = UDim2.new(0, 0, 0.5, 0)
	friendsLabel.Parent = rowFriends
	
	local btnAddFriend = Instance.new("TextButton")
	btnAddFriend.Size = UDim2.new(0.18, 0, 0.85, 0)
	btnAddFriend.AnchorPoint = Vector2.new(0, 0.5)
	btnAddFriend.Position = UDim2.new(0.80, 0, 0.5, 0)
	local bafAspect = Instance.new("UIAspectRatioConstraint")
	bafAspect.AspectRatio = 1.0
	bafAspect.Parent = btnAddFriend
	btnAddFriend.Parent = rowFriends
	
	local cashPill = Instance.new("Frame")
	cashPill.Name = "CashPill"
	cashPill.Size = UDim2.new(1, 0, 0.48, 0)
	cashPill.Position = UDim2.new(0, 0, 0.52, 0)
	cashPill.Parent = currencyGroup
	
	local cashIconImg = Instance.new("ImageLabel")
	cashIconImg.Size = UDim2.new(0.20, 0, 0.85, 0)
	cashIconImg.AnchorPoint = Vector2.new(0, 0.5)
	cashIconImg.Position = UDim2.new(0, 0, 0.5, 0)
	cashIconImg.Parent = cashPill
	
	local cashLabel = Instance.new("TextLabel")
	cashLabel.Size = UDim2.new(0.58, 0, 0.85, 0)
	cashLabel.AnchorPoint = Vector2.new(0, 0.5)
	cashLabel.Position = UDim2.new(0.20, 4, 0.5, 0)
	cashLabel.Parent = cashPill
	
	local btnAddCash = Instance.new("TextButton")
	btnAddCash.Size = UDim2.new(0.18, 0, 0.85, 0)
	btnAddCash.AnchorPoint = Vector2.new(0, 0.5)
	btnAddCash.Position = UDim2.new(0.80, 0, 0.5, 0)
	local bacAspect = Instance.new("UIAspectRatioConstraint")
	bacAspect.AspectRatio = 1.0
	bacAspect.Parent = btnAddCash
	btnAddCash.Parent = cashPill
	
	-- 3. Right Promo Group
	local rightPromoGroup = Instance.new("Frame")
	rightPromoGroup.Name = "RightPromoGroup"
	rightPromoGroup.AnchorPoint = Vector2.new(1, 0.5)
	rightPromoGroup.Position = UDim2.new(0.99, 0, 0.55, 0)
	rightPromoGroup.Size = UDim2.new(0.12, 0, 0.32, 10)
	rightPromoGroup.Parent = lobbyHud
	
	local rightPromoLayout = Instance.new("UIListLayout")
	rightPromoLayout.FillDirection = Enum.FillDirection.Vertical
	rightPromoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rightPromoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rightPromoLayout.Padding = UDim.new(0, 10)
	rightPromoLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightPromoLayout.Parent = rightPromoGroup
	
	local promo1 = Instance.new("ImageButton")
	promo1.Name = "StarterPackSlot"
	promo1.LayoutOrder = 1
	promo1.Size = UDim2.new(1, 0, 0.46, 0)
	local p1Aspect = Instance.new("UIAspectRatioConstraint")
	p1Aspect.AspectRatio = 1.0
	p1Aspect.Parent = promo1
	promo1.Parent = rightPromoGroup
	
	local promo2 = Instance.new("ImageButton")
	promo2.Name = "InfRerollsSlot"
	promo2.LayoutOrder = 2
	promo2.Size = UDim2.new(1, 0, 0.46, 0)
	local p2Aspect = Instance.new("UIAspectRatioConstraint")
	p2Aspect.AspectRatio = 1.0
	p2Aspect.Parent = promo2
	promo2.Parent = rightPromoGroup
	
	-- 4. TopRightBar
	local topRightBar = Instance.new("Frame")
	topRightBar.Name = "TopRightBar"
	topRightBar.Size = UDim2.new(0, 300, 0, 42)
	topRightBar.Position = UDim2.new(1, -16, 0, 14)
	topRightBar.AnchorPoint = Vector2.new(1, 0)
	topRightBar.Parent = screen
	
	-- 5. Apply UIScale
	local baseScale = math.clamp(dev.h / 1080, 0.6, 1.0)
	local finalScale = if dev.touch then baseScale * 0.85 else baseScale
	
	local function addScale(f)
		local sc = Instance.new("UIScale")
		sc.Scale = finalScale
		sc.Parent = f
	end
	addScale(leftNavGroup)
	addScale(currencyGroup)
	addScale(rightPromoGroup)
	addScale(topRightBar)
	
	-- Measure bounding boxes
	local boxCurr = makeBox(currencyGroup)
	local boxShop = makeBox(navBtns["Shop"])
	local boxSkins = makeBox(navBtns["Skins"])
	local boxTitles = makeBox(navBtns["Titles"])
	local boxIndex = makeBox(navBtns["Index"])
	local boxProfile = makeBox(navBtns["Profile"])
	local boxBadge = makeBox(indexBadge)
	local boxPromo = makeBox(rightPromoGroup)
	local boxPromo2 = makeBox(promo2)
	local boxTopRight = makeBox(topRightBar)
	
	-- Simulated jump button on mobile: bottom-right (X: W - 90 to W - 10, Y: H - 90 to H - 10)
	local jumpBox = {
		name = "MobileJumpButton",
		x0 = dev.w - 90,
		y0 = dev.h - 90,
		x1 = dev.w - 10,
		y1 = dev.h - 10,
		w = 80,
		h = 80
	}
	
	-- Checks:
	-- A. Currency zone starts at 0.86 * dev.h (bottom 14%)
	local currencyZoneTopY = dev.h * (1.0 - 0.14)
	
	-- B. Highest Y reached by left column group
	local leftColBottomY = math.max(boxShop.y1, boxSkins.y1, boxTitles.y1, boxIndex.y1, boxProfile.y1)
	local leftColEndYRel = leftColBottomY / dev.h
	
	-- C. Overlap checks
	local overlaps = {}
	if doBoxOverlap(boxCurr, boxProfile) then table.insert(overlaps, "CurrencyGroup overlaps Profile") end
	if doBoxOverlap(boxCurr, boxIndex) then table.insert(overlaps, "CurrencyGroup overlaps Index") end
	if doBoxOverlap(boxCurr, boxTitles) then table.insert(overlaps, "CurrencyGroup overlaps Titles") end
	if doBoxOverlap(boxBadge, boxSkins) then table.insert(overlaps, "IndexBadge overlaps Skins") end
	if doBoxOverlap(boxBadge, boxTitles) then table.insert(overlaps, "IndexBadge overlaps Titles") end
	if doBoxOverlap(boxPromo, boxTopRight) then table.insert(overlaps, "RightPromo overlaps TopRightBar") end
	if dev.touch and doBoxOverlap(boxPromo, jumpBox) then table.insert(overlaps, "RightPromo overlaps JumpButton") end
	
	local passColHeight = (leftColEndYRel <= 0.82)
	local passCurrencyZone = (leftColBottomY < currencyZoneTopY)
	local passNoOverlaps = (#overlaps == 0)
	
	table.insert(report, {
		device = dev.name,
		resolution = `{dev.w}x{dev.h}`,
		scale = finalScale,
		leftColEndYRel = string.format("%.2f", leftColEndYRel),
		leftColEndsAbove082 = passColHeight,
		leftColOutsideCurrencyZone = passCurrencyZone,
		currencyGroupTopY = math.round(boxCurr.y0),
		currencyGroupHeight = math.round(boxCurr.h),
		rightPromoBottomY = math.round(boxPromo2.y1),
		jumpButtonTopY = jumpBox.y0,
		clearOfJumpButton = (boxPromo2.y1 < jumpBox.y0),
		overlapCount = #overlaps,
		overlaps = overlaps,
		status = if (passColHeight and passCurrencyZone and passNoOverlaps) then "PASS" else "FAIL"
	})
end

return HttpService:JSONEncode(report)

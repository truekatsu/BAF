--!strict
--[[
	UITheme.luau
	Responsibility: Global Design Tokens, Gradients, Bevels, Brick Studs, Button Styling, 
	and Chunky Cartoon Animations for Build A Footballer (BAF).
	Location: ReplicatedStorage/Shared/UITheme (ModuleScript)
]]

local TweenService = game:GetService("TweenService")

export type ButtonVariant = "Lime" | "Purple" | "Orange" | "Blue" | "Pink" | "Gold" | "Cyan" | "Gray" | "Red" | "Dark" | "TabInactive"

local UITheme = {}

-- 1. FONTS & TEXT SETTINGS
UITheme.Fonts = {
	Primary = Enum.Font.GothamBlack,
	Titles = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamBold,
}

-- 2. COLOR PALETTE (Chunky Brick Cartoon)
UITheme.Colors = {
	-- Action & Buy buttons
	LimeTop = Color3.fromHex("#9BE82A"),
	LimeBottom = Color3.fromHex("#5DB510"),
	LimeStroke = Color3.fromHex("#1B3A00"),

	-- Headers & Modals
	OrangeTop = Color3.fromHex("#FF8A1F"),
	OrangeBottom = Color3.fromHex("#D45500"),

	BlueTop = Color3.fromHex("#3FB0FF"),
	BlueBottom = Color3.fromHex("#1B6FE0"),

	PinkTop = Color3.fromHex("#FF4D6D"),
	PinkBottom = Color3.fromHex("#C2185B"),

	MagentaTop = Color3.fromHex("#F0509F"),
	MagentaBottom = Color3.fromHex("#B81E70"),

	GoldTop = Color3.fromHex("#FFC933"),
	GoldBottom = Color3.fromHex("#F09A00"),

	CyanTop = Color3.fromHex("#22C8EE"),
	CyanBottom = Color3.fromHex("#0E9CC4"),

	PurpleTop = Color3.fromHex("#A855FF"),
	PurpleBottom = Color3.fromHex("#5B21B6"),

	RedTop = Color3.fromHex("#FF4D4D"),
	RedBottom = Color3.fromHex("#C21F1F"),

	GrayTop = Color3.fromHex("#6B6F78"),
	GrayBottom = Color3.fromHex("#3D4047"),

	TabInactiveTop = Color3.fromHex("#4A4F59"),
	TabInactiveBottom = Color3.fromHex("#2B2F36"),
	TabInactiveText = Color3.fromHex("#E6E6E6"),

	-- Windows & Cards
	WindowBody = Color3.fromHex("#262C3A"),
	CardBg = Color3.fromHex("#30384A"),
	CardDark = Color3.fromHex("#232936"),

	-- Text Accents
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	MoneyGreen = Color3.fromHex("#7CFF2B"),
	NoticeYellow = Color3.fromHex("#FFD21F"),
}

-- 3. ASSET IDS (Built-in / Recommended Fallbacks)
-- shortcut: Temporary Roblox stock asset IDs; replace with custom 256x256 cartoon illustrated PNGs before production release
UITheme.Assets = {
	StudsTexture = "rbxassetid://10849912195",
	RobuxHexagon = "rbxassetid://9721498877",
	RobuxSmall = "rbxasset://textures/ui/common/robux_small.png",
	CashStack = "rbxassetid://87776454581651",
	CashIcon = "rbxassetid://87776454581651",
	TreasureChest = "rbxassetid://13589994500",
	CrownIcon = "rbxassetid://75361055155810",
	VipIcon = "rbxassetid://75361055155810",
	TrophyIcon = "rbxassetid://86591655180223",
	WinIcon = "rbxassetid://86591655180223",
	FlameIcon = "rbxassetid://138765021620763",
	NavFreeIcon = "rbxassetid://133237770323627",
	NavShopIcon = "rbxassetid://78010625491811",
	NavSkinsIcon = "rbxassetid://83535029342218",
	NavTitlesIcon = "rbxassetid://97397535087012",
	NavIndexIcon = "rbxassetid://92343630156093",
	CloverIcon = "rbxassetid://87802541186816",
	LuckIcon = "rbxassetid://87802541186816",
	WheelIcon = "rbxassetid://13589998500",
	PadlockIcon = "rbxassetid://13589999500",
	ClockIcon = "rbxassetid://13590000500",
	SunburstBg = "rbxassetid://13590001500",
}

-- 4. BASIC STYLING HELPERS
function UITheme.addCorner(parent: Instance, radius: number): UICorner
	local existing = parent:FindFirstChildOfClass("UICorner")
	if existing then
		existing.CornerRadius = UDim.new(0, radius)
		return existing
	end
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

function UITheme.applyStroke(parent: Instance, thickness: number, color: Color3?): UIStroke
	local existing = parent:FindFirstChildOfClass("UIStroke")
	if existing then
		existing.Thickness = thickness
		existing.Color = color or UITheme.Colors.Black
		existing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		return existing
	end
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or UITheme.Colors.Black
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UITheme.applyTextStroke(label: Instance, thickness: number?, color: Color3?): UIStroke
	local existing = label:FindFirstChildOfClass("UIStroke")
	if existing then
		existing.Thickness = thickness or 2.5
		existing.Color = color or UITheme.Colors.Black
		existing.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		return existing
	end
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2.5
	s.Color = color or UITheme.Colors.Black
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = label
	return s
end

-- Inner glossy bevel highlight (top 40% highlight + bottom 12% shade for plastic toy feel)
function UITheme.addBevel(parent: Instance, radius: number?)
	if not parent:IsA("GuiObject") then
		return
	end
	local rad = radius or 8
	local highlight = parent:FindFirstChild("Highlight") :: Frame?
	if not highlight then
		highlight = Instance.new("Frame")
		highlight.Name = "Highlight"
		highlight.Size = UDim2.new(1, 0, 0.40, 0)
		highlight.Position = UDim2.new(0, 0, 0, 0)
		highlight.BackgroundColor3 = UITheme.Colors.White
		highlight.BackgroundTransparency = 0.85
		highlight.BorderSizePixel = 0
		highlight.ZIndex = parent.ZIndex + 1
		UITheme.addCorner(highlight, rad)
		highlight.Parent = parent
	end
end

-- Offset drop shadow underneath cards and main windows (Buttons omitted for seamless scaling)
function UITheme.addShadow(parent: Instance, cornerRadius: number, offset: number?): Frame?
	if not parent:IsA("GuiObject") or not parent.Parent then
		return nil
	end
	if parent:IsA("GuiButton") or parent.Parent:FindFirstChildOfClass("UILayout") then
		return nil
	end
	local off = offset or 4
	local shadowName = (parent.Name ~= "" and parent.Name ~= "Frame" and parent.Name ~= "TextButton") and (parent.Name .. "_Shadow") or "Shadow"
	local existing = parent.Parent:FindFirstChild(shadowName) :: Frame?
	if existing then
		existing.Size = parent.Size
		existing.Position = parent.Position + UDim2.fromOffset(0, off)
		return existing
	end
	local shadow = Instance.new("Frame")
	shadow.Name = shadowName
	shadow.Size = parent.Size
	shadow.Position = parent.Position + UDim2.fromOffset(0, off)
	shadow.AnchorPoint = parent.AnchorPoint
	shadow.BackgroundColor3 = UITheme.Colors.Black
	shadow.BackgroundTransparency = 0.60
	shadow.BorderSizePixel = 0
	shadow.ZIndex = math.max(1, parent.ZIndex - 1)
	UITheme.addCorner(shadow, cornerRadius)
	shadow.Parent = parent.Parent
	return shadow
end

-- Tiled Lego Stud pattern overlay
function UITheme.addStuds(parent: Instance, opacity: number?, tileSize: number?): ImageLabel
	local existing = parent:FindFirstChild("StudsOverlay")
	if existing and existing:IsA("ImageLabel") then
		return existing
	end
	local studs = Instance.new("ImageLabel")
	studs.Name = "StudsOverlay"
	studs.Size = UDim2.fromScale(1, 1)
	studs.Position = UDim2.fromScale(0, 0)
	studs.BackgroundTransparency = 1
	studs.Image = UITheme.Assets.StudsTexture
	studs.ImageTransparency = opacity or 0.88
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(tileSize or 24, tileSize or 24)
	studs.ZIndex = (parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
	UITheme.addCorner(studs, (parent:FindFirstChildOfClass("UICorner") and parent:FindFirstChildOfClass("UICorner").CornerRadius.Offset) or 8)
	studs.Parent = parent
	return studs
end

-- Gradient Presets
function UITheme.applyGradient(guiObj: GuiObject, topColor: Color3, bottomColor: Color3, rotation: number?): UIGradient
	local existing = guiObj:FindFirstChildOfClass("UIGradient")
	local grad = existing or Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	grad.Rotation = rotation or 90
	grad.Parent = guiObj
	return grad
end

function UITheme.getPresetColors(variant: ButtonVariant): (Color3, Color3, Color3)
	if variant == "Lime" then
		return UITheme.Colors.LimeTop, UITheme.Colors.LimeBottom, UITheme.Colors.LimeStroke
	elseif variant == "Purple" then
		return UITheme.Colors.PurpleTop, UITheme.Colors.PurpleBottom, UITheme.Colors.Black
	elseif variant == "Orange" then
		return UITheme.Colors.OrangeTop, UITheme.Colors.OrangeBottom, UITheme.Colors.Black
	elseif variant == "Blue" then
		return UITheme.Colors.BlueTop, UITheme.Colors.BlueBottom, UITheme.Colors.Black
	elseif variant == "Pink" then
		return UITheme.Colors.PinkTop, UITheme.Colors.PinkBottom, UITheme.Colors.Black
	elseif variant == "Gold" then
		return UITheme.Colors.GoldTop, UITheme.Colors.GoldBottom, UITheme.Colors.Black
	elseif variant == "Cyan" then
		return UITheme.Colors.CyanTop, UITheme.Colors.CyanBottom, UITheme.Colors.Black
	elseif variant == "Red" then
		return UITheme.Colors.RedTop, UITheme.Colors.RedBottom, UITheme.Colors.Black
	elseif variant == "Gray" then
		return UITheme.Colors.GrayTop, UITheme.Colors.GrayBottom, UITheme.Colors.Black
	elseif variant == "TabInactive" then
		return UITheme.Colors.TabInactiveTop, UITheme.Colors.TabInactiveBottom, UITheme.Colors.Black
	else
		return UITheme.Colors.CardBg, UITheme.Colors.CardDark, UITheme.Colors.Black
	end
end

-- Style text label: TextScaled, UITextSizeConstraint, white text + black stroke
function UITheme.styleText(
	label: TextLabel | TextButton,
	maxSize: number?,
	minSize: number?,
	strokeThickness: number?,
	color: Color3?
): UIStroke
	label.TextScaled = true
	if color then
		label.TextColor3 = color
	end
	local sc = label:FindFirstChildOfClass("UITextSizeConstraint")
	if not sc then
		sc = Instance.new("UITextSizeConstraint")
		sc.Parent = label
	end
	sc.MinTextSize = minSize or 10
	sc.MaxTextSize = maxSize or 28

	local existingStroke = label:FindFirstChildOfClass("UIStroke")
	if existingStroke then
		existingStroke.Thickness = strokeThickness or 2.5
		existingStroke.Color = UITheme.Colors.Black
		existingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		return existingStroke
	end
	local s = Instance.new("UIStroke")
	s.Thickness = strokeThickness or 2.5
	s.Color = UITheme.Colors.Black
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = label
	return s
end

function UITheme.addTextConstraint(parent: Instance, minSize: number?, maxSize: number?): UITextSizeConstraint
	local existing = parent:FindFirstChildOfClass("UITextSizeConstraint")
	if existing then
		if minSize then existing.MinTextSize = minSize end
		if maxSize then existing.MaxTextSize = maxSize end
		return existing
	end
	local sc = Instance.new("UITextSizeConstraint")
	sc.MinTextSize = minSize or 10
	sc.MaxTextSize = maxSize or 28
	sc.Parent = parent
	return sc
end

-- Style a button into a Chunky Brick Button
function UITheme.styleButton(btn: TextButton, variant: ButtonVariant, cornerRadius: number?)
	local rad = cornerRadius or 8
	local topCol, botCol, strokeCol = UITheme.getPresetColors(variant)

	btn.BackgroundColor3 = topCol
	btn.Font = UITheme.Fonts.Primary
	btn.TextColor3 = if variant == "TabInactive" then UITheme.Colors.TabInactiveText else UITheme.Colors.White
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = UITheme.Colors.Black
	btn.TextScaled = true
	btn.TextWrapped = false
	btn.AutoButtonColor = false

	local sc = btn:FindFirstChildOfClass("UITextSizeConstraint")
	if not sc then
		sc = Instance.new("UITextSizeConstraint")
		sc.Parent = btn
	end
	sc.MinTextSize = 10
	sc.MaxTextSize = 28

	UITheme.addCorner(btn, rad)
	UITheme.applyStroke(btn, 3, strokeCol)
	UITheme.applyGradient(btn, topCol, botCol, 90)
	UITheme.addBevel(btn, rad)
	UITheme.setupButtonHover(btn)
end

-- Dedicated Price Button with separate ImageLabel (no unicode boxes)
function UITheme.priceButton(
	button: TextButton,
	price: number | string,
	currency: ("Robux" | "Cash" | "Bux")?,
	variant: ButtonVariant?
): TextButton
	local cur = currency or "Robux"
	local var = variant or (cur == "Cash" and "Gold" or "Lime")
	UITheme.styleButton(button, var, 8)
	button.Text = "" -- Ensure no unicode glyphs on button itself

	local contentWrap = button:FindFirstChild("ContentWrap") :: Frame?
	if not contentWrap then
		contentWrap = Instance.new("Frame")
		contentWrap.Name = "ContentWrap"
		contentWrap.Size = UDim2.fromScale(1, 1)
		contentWrap.Position = UDim2.fromScale(0, 0)
		contentWrap.BackgroundTransparency = 1
		contentWrap.ZIndex = button.ZIndex + 2
		contentWrap.Parent = button

		local list = Instance.new("UIListLayout")
		list.Name = "PriceLayout"
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, 4)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = contentWrap
	end

	local icon = contentWrap:FindFirstChild("RobuxIcon") or contentWrap:FindFirstChild("CashIcon") :: ImageLabel?
	if not icon then
		icon = Instance.new("ImageLabel")
		icon.Parent = contentWrap
	end
	icon.Name = cur == "Cash" and "CashIcon" or "RobuxIcon"
	icon.Size = UDim2.fromOffset(20, 20)
	icon.BackgroundTransparency = 1
	icon.Image = cur == "Cash" and UITheme.Assets.CashStack or UITheme.Assets.RobuxSmall
	icon.ScaleType = Enum.ScaleType.Fit
	icon.LayoutOrder = 1
	icon.ZIndex = contentWrap.ZIndex + 1

	local priceLbl = contentWrap:FindFirstChild("PriceText") :: TextLabel?
	if not priceLbl then
		priceLbl = Instance.new("TextLabel")
		priceLbl.Name = "PriceText"
		priceLbl.BackgroundTransparency = 1
		priceLbl.Font = UITheme.Fonts.Primary
		priceLbl.LayoutOrder = 2
		priceLbl.ZIndex = contentWrap.ZIndex + 1
		priceLbl.Parent = contentWrap
	end
	priceLbl.TextColor3 = if var == "Gray" then Color3.fromHex("#D0D4DC") else UITheme.Colors.White
	priceLbl.Size = UDim2.new(0, 0, 1, 0)
	priceLbl.AutomaticSize = Enum.AutomaticSize.X
	priceLbl.Text = if cur == "Cash" and not string.find(tostring(price), "%$") then "$" .. tostring(price) else tostring(price)
	UITheme.styleText(priceLbl, 24, 10, 2.5)

	return button
end

-- Style chair skin action/price button
function UITheme.skinButton(
	button: TextButton,
	state: "EQUIPPED" | "EQUIP" | "BUY",
	price: number?,
	canAfford: boolean?
): TextButton
	local contentWrap = button:FindFirstChild("ContentWrap") :: Frame?
	if not contentWrap then
		contentWrap = Instance.new("Frame")
		contentWrap.Name = "ContentWrap"
		contentWrap.Size = UDim2.fromScale(1, 1)
		contentWrap.BackgroundTransparency = 1
		contentWrap.ZIndex = button.ZIndex + 3
		contentWrap.Parent = button

		local list = Instance.new("UIListLayout")
		list.Name = "SkinBtnLayout"
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, 4)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = contentWrap
	end

	local icon = contentWrap:FindFirstChild("CashIcon") :: ImageLabel?
	if not icon then
		icon = Instance.new("ImageLabel")
		icon.Name = "CashIcon"
		icon.Size = UDim2.fromOffset(18, 18)
		icon.BackgroundTransparency = 1
		icon.Image = UITheme.Assets.CashStack
		icon.ScaleType = Enum.ScaleType.Fit
		icon.LayoutOrder = 1
		icon.ZIndex = contentWrap.ZIndex + 1
		icon.Parent = contentWrap
	end

	local label = contentWrap:FindFirstChild("SkinBtnLabel") :: TextLabel?
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "SkinBtnLabel"
		label.BackgroundTransparency = 1
		label.Font = UITheme.Fonts.Primary
		label.LayoutOrder = 2
		label.ZIndex = contentWrap.ZIndex + 1
		label.Parent = contentWrap
		UITheme.applyTextStroke(label, 2.5, UITheme.Colors.Black)
	end
	label.Size = UDim2.new(0, 0, 1, 0)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.TextScaled = false
	label.TextSize = 14

	button.Text = ""

	if state == "EQUIPPED" then
		icon.Visible = false
		label.Text = "EQUIPPED"
		label.TextColor3 = UITheme.Colors.White
		UITheme.styleButton(button, "Lime", 8)
	elseif state == "EQUIP" then
		icon.Visible = false
		label.Text = "EQUIP"
		label.TextColor3 = UITheme.Colors.White
		UITheme.styleButton(button, "Blue", 8)
	else
		icon.Visible = true
		local costVal = price or 0
		label.Text = "$" .. tostring(costVal)
		if canAfford then
			label.TextColor3 = UITheme.Colors.White
			UITheme.styleButton(button, "Gold", 8)
		else
			label.TextColor3 = Color3.fromHex("#D0D4DC")
			UITheme.styleButton(button, "Gray", 8)
		end
	end

	return button
end

-- Style modal window frame with thick 4px border stroke, corner, shadow and padding
function UITheme.styleWindow(window: Frame, headerColor: ButtonVariant?)
	window.BackgroundColor3 = UITheme.Colors.WindowBody
	window.BackgroundTransparency = 0
	UITheme.addCorner(window, 14)
	UITheme.applyStroke(window, 4, UITheme.Colors.Black)
	UITheme.addStuds(window, 0.88, 24)
	UITheme.addShadow(window, 14, 6)

	local pad = window:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 10)
		pad.PaddingBottom = UDim.new(0, 10)
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.Parent = window
	end
end

-- Style standard modal header
function UITheme.styleHeader(headerFrame: Frame, variant: ButtonVariant, titleText: string, subtitleText: string?): TextLabel
	local topCol, botCol, strokeCol = UITheme.getPresetColors(variant)
	headerFrame.BackgroundColor3 = topCol
	UITheme.addCorner(headerFrame, 14)
	UITheme.applyStroke(headerFrame, 4, UITheme.Colors.Black)
	UITheme.applyGradient(headerFrame, topCol, botCol, 90)
	UITheme.addStuds(headerFrame, 0.85, 22)
	UITheme.addBevel(headerFrame, 14)

	local titleLbl = headerFrame:FindFirstChild("HeaderTitle") :: TextLabel?
	if not titleLbl then
		titleLbl = Instance.new("TextLabel")
		titleLbl.Name = "HeaderTitle"
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = UITheme.Fonts.Titles
		titleLbl.TextColor3 = UITheme.Colors.White
		titleLbl.TextStrokeTransparency = 0
		titleLbl.TextStrokeColor3 = UITheme.Colors.Black
		titleLbl.TextScaled = true
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.ZIndex = headerFrame.ZIndex + 2
		titleLbl.Parent = headerFrame
	end

	if subtitleText and subtitleText ~= "" then
		titleLbl.Size = UDim2.new(0.78, 0, 0.58, 0)
		titleLbl.Position = UDim2.new(0.03, 0, 0.08, 0)
		titleLbl.Text = string.upper(titleText)

		local subLbl = headerFrame:FindFirstChild("HeaderSubtitle") :: TextLabel?
		if not subLbl then
			subLbl = Instance.new("TextLabel")
			subLbl.Name = "HeaderSubtitle"
			subLbl.BackgroundTransparency = 1
			subLbl.Font = UITheme.Fonts.Body
			subLbl.TextColor3 = UITheme.Colors.NoticeYellow
			subLbl.TextStrokeTransparency = 0
			subLbl.TextStrokeColor3 = UITheme.Colors.Black
			subLbl.TextScaled = true
			subLbl.TextXAlignment = Enum.TextXAlignment.Left
			subLbl.ZIndex = headerFrame.ZIndex + 2
			subLbl.Parent = headerFrame
		end
		subLbl.Size = UDim2.new(0.78, 0, 0.30, 0)
		subLbl.Position = UDim2.new(0.03, 0, 0.64, 0)
		subLbl.Text = subtitleText
	else
		titleLbl.Size = UDim2.new(0.82, 0, 0.78, 0)
		titleLbl.Position = UDim2.new(0.03, 0, 0.11, 0)
		titleLbl.Text = string.upper(titleText)
		local subLbl = headerFrame:FindFirstChild("HeaderSubtitle")
		if subLbl then
			subLbl:Destroy()
		end
	end

	return titleLbl
end

-- Robux Price Badge (hexagon icon + bold price text)
function UITheme.createRobuxBadge(parent: GuiObject, price: number, size: UDim2?, pos: UDim2?): Frame
	local badge = Instance.new("Frame")
	badge.Name = "RobuxBadge"
	badge.Size = size or UDim2.fromOffset(68, 28)
	badge.Position = pos or UDim2.new(1, -74, 0, -10)
	badge.BackgroundColor3 = UITheme.Colors.LimeTop
	badge.ZIndex = parent.ZIndex + 3
	UITheme.addCorner(badge, 6)
	UITheme.applyStroke(badge, 2.5, UITheme.Colors.Black)
	UITheme.applyGradient(badge, UITheme.Colors.LimeTop, UITheme.Colors.LimeBottom, 90)

	local icon = Instance.new("ImageLabel")
	icon.Name = "RobuxIcon"
	icon.Size = UDim2.fromOffset(18, 18)
	icon.Position = UDim2.new(0, 4, 0.5, -9)
	icon.BackgroundTransparency = 1
	icon.Image = UITheme.Assets.RobuxSmall
	icon.ZIndex = badge.ZIndex + 1
	icon.Parent = badge

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name = "PriceText"
	priceLbl.Size = UDim2.new(1, -26, 1, 0)
	priceLbl.Position = UDim2.new(0, 24, 0, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font = UITheme.Fonts.Primary
	priceLbl.TextColor3 = UITheme.Colors.White
	priceLbl.TextStrokeTransparency = 0
	priceLbl.TextStrokeColor3 = UITheme.Colors.Black
	priceLbl.TextScaled = true
	priceLbl.Text = tostring(price)
	priceLbl.ZIndex = badge.ZIndex + 1
	priceLbl.Parent = badge

	badge.Parent = parent
	return badge
end

-- 5. ANIMATIONS & POLISH

-- Button Hover & Press Animation
function UITheme.setupButtonHover(btn: GuiObject, baseScale: number?, hoverAngle: number?)
	local startScale = baseScale or 1.0
	local angle = hoverAngle or 0

	local uiScale = btn:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = startScale
		uiScale.Parent = btn
	end

	local btnObj = if btn:IsA("GuiButton") then btn else btn:FindFirstChildWhichIsA("GuiButton", true)
	if not btnObj then
		return
	end

	local isHovered = false
	local isPressed = false

	btnObj.MouseEnter:Connect(function()
		isHovered = true
		if not isPressed then
			TweenService:Create(uiScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = startScale * 1.06,
			}):Play()
			if angle ~= 0 then
				TweenService:Create(btn, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Rotation = angle,
				}):Play()
			end
		end
	end)

	btnObj.MouseLeave:Connect(function()
		isHovered = false
		isPressed = false
		TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = startScale,
		}):Play()
		if angle ~= 0 then
			TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = 0,
			}):Play()
		end
	end)

	btnObj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isPressed = true
			TweenService:Create(uiScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = startScale * 0.94,
			}):Play()
		end
	end)

	btnObj.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isPressed = false
			local targetScale = if isHovered then startScale * 1.06 else startScale
			TweenService:Create(uiScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = targetScale,
			}):Play()
		end
	end)
end

-- Window Open/Close Animation (Pop with Back easing + Smooth Backdrop Fade)
function UITheme.animateWindowOpen(modalWrap: GuiObject, modalBox: GuiObject)
	modalWrap.Visible = true
	local uiScale = modalBox:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = modalBox
	end

	uiScale.Scale = 0.80
	TweenService:Create(uiScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0,
	}):Play()

	local backdrop = modalWrap:FindFirstChild("ModalBackdrop") or (modalWrap.Parent and modalWrap.Parent:FindFirstChild("ModalBackdrop"))
	if backdrop and backdrop:IsA("GuiObject") then
		backdrop.Visible = true
		backdrop.BackgroundTransparency = 1.0
	end
end

function UITheme.animateWindowClose(modalWrap: GuiObject, modalBox: GuiObject, onComplete: (() -> ())?)
	local backdrop = modalWrap:FindFirstChild("ModalBackdrop") or (modalWrap.Parent and modalWrap.Parent:FindFirstChild("ModalBackdrop"))
	if backdrop and backdrop:IsA("GuiObject") then
		backdrop.Visible = false
	end

	local uiScale = modalBox:FindFirstChildOfClass("UIScale")
	if not uiScale then
		modalWrap.Visible = false
		if onComplete then onComplete() end
		return
	end

	local tw = TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.80,
	})
	tw:Play()
	tw.Completed:Connect(function()
		modalWrap.Visible = false
		uiScale.Scale = 1.0
		if onComplete then onComplete() end
	end)
end

-- Claimable Glow & Shine Sweep Animation
function UITheme.addShineSweep(guiObj: GuiObject)
	local shine = Instance.new("Frame")
	shine.Name = "ShineSweep"
	shine.Size = UDim2.new(0.4, 0, 2, 0)
	shine.Position = UDim2.new(-0.6, 0, -0.5, 0)
	shine.BackgroundColor3 = UITheme.Colors.White
	shine.BackgroundTransparency = 0.7
	shine.BorderSizePixel = 0
	shine.Rotation = 25
	shine.ZIndex = (guiObj.ZIndex or 1) + 2

	local grad = Instance.new("UIGradient")
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	grad.Parent = shine
	shine.Parent = guiObj

	task.spawn(function()
		while guiObj and guiObj.Parent do
			shine.Position = UDim2.new(-0.6, 0, -0.5, 0)
			local tw = TweenService:Create(shine, TweenInfo.new(0.95, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
				Position = UDim2.new(1.4, 0, -0.5, 0),
			})
			tw:Play()
			task.wait(3.5)
		end
	end)
end

-- Pulsing scale loop for promo buttons
function UITheme.addPulse(guiObj: GuiObject, minScale: number?, maxScale: number?, duration: number?)
	local uiScale = guiObj:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = guiObj
	end

	local minS = minScale or 1.0
	local maxS = maxScale or 1.05
	local dur = duration or 2.0

	task.spawn(function()
		while guiObj and guiObj.Parent do
			local twUp = TweenService:Create(uiScale, TweenInfo.new(dur / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Scale = maxS,
			})
			twUp:Play()
			twUp.Completed:Wait()

			local twDn = TweenService:Create(uiScale, TweenInfo.new(dur / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Scale = minS,
			})
			twDn:Play()
			twDn.Completed:Wait()
		end
	end)
end

return UITheme

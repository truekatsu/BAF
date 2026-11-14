--!strict



--[[



	UITheme.luau



	Responsibility: Global Design Tokens, Gradients, Reusable Builders, and Chunky Cartoon Styling for BAF.



	Location: ReplicatedStorage/Shared/UITheme (ModuleScript)



]]



local TweenService = game:GetService("TweenService")



local Lighting = game:GetService("Lighting")



local Players = game:GetService("Players")



local UITheme = {}



--------------------------------------------------------------------------------



-- 1. GLOBAL CONFIG & DESIGN TOKENS



-- All numbers, colors, and layout metrics live here for single-source editing.



--------------------------------------------------------------------------------



UITheme.CONFIG = {



	-- Font Token: Single source font across titles and buttons



	Font = Enum.Font.FredokaOne, -- Closest built-ins: FredokaOne, LuckiestGuy, GothamBlack



	-- Background Blur Toggle (Shop or window open)



	USE_BACKGROUND_BLUR = false,



	BLUR_SIZE = 8,



	-- Strokes & Corners (Blocky, NOT pill-shaped)



	WINDOW_STROKE_THICKNESS = 4,



	WINDOW_CORNER_RADIUS = 6,



	CARD_STROKE_THICKNESS = 3,



	CARD_CORNER_RADIUS = 4,



	BUTTON_STROKE_THICKNESS = 3,



	BUTTON_CORNER_RADIUS = 5,



	TEXT_STROKE_SMALL = 2,



	TEXT_STROKE_MEDIUM = 3,



	TEXT_STROKE_LARGE = 4,



	-- Window Layout Ratios



	HEADER_HEIGHT_SCALE = 0.15,        -- ~15% of window height



	HEADER_TITLE_HEIGHT_SCALE = 0.55,  -- ~55% of header height



	HEADER_TITLE_PADDING_SCALE = 0.03, -- ~3% left padding



	CLOSE_BUTTON_HEIGHT_SCALE = 0.78,  -- ~78% of header height



	CLOSE_BUTTON_MARGIN_SCALE = 0.015, -- ~1.5% margin



	-- Studs Texture



	STUDS_TILE_SIZE = 28,



	STUDS_HEADER_TRANSPARENCY = 0.28, -- Crisp 3D studs texture pop



	STUDS_PANEL_TRANSPARENCY = 0.88,



	-- Interaction & Animations



	HOVER_SCALE = 1.04,



	PRESS_SCALE = 0.96,



	HOVER_TWEEN_TIME = 0.10,



	WINDOW_OPEN_SCALE = 0.92,



	WINDOW_OPEN_TWEEN_TIME = 0.15,



	-- Scrollbar



	SCROLLBAR_THICKNESS = 8,



	SCROLLBAR_COLOR = Color3.fromHex("#E6E6E6"),



	SCROLLBAR_TRANSPARENCY = 0.15,



	-- Design Token Colors (Gradients are Top -> Bottom)



	Colors = {



		Outline = Color3.fromHex("#000000"),



		DarkPanel = Color3.fromHex("#0F1219"),



		DarkPanelTransparency = 0.35,



		-- Text Accents



		White = Color3.fromHex("#FFFFFF"),



		Black = Color3.fromHex("#000000"),



		MoneyLime = Color3.fromHex("#7CFF2B"),



		DescriptionGold = Color3.fromHex("#FFD21F"),



		-- Button Gradients (Top, Bottom, Inner Rim Hue)



		LimeTop = Color3.fromHex("#A8EF2E"),



		LimeBottom = Color3.fromHex("#5FB812"),



		LimeInner = Color3.fromHex("#3F7C0C"),



		GoldTop = Color3.fromHex("#FFD23A"),



		GoldBottom = Color3.fromHex("#F29A00"),



		GoldInner = Color3.fromHex("#AA6800"),



		BlueTop = Color3.fromHex("#34B6FF"),



		BlueBottom = Color3.fromHex("#0E78E8"),



		BlueInner = Color3.fromHex("#084C94"),



		GrayTop = Color3.fromHex("#A0A0A0"),



		GrayBottom = Color3.fromHex("#5A5A5A"),



		GrayInner = Color3.fromHex("#3E3E3E"),



		PurpleTop = Color3.fromHex("#9B25E0"),



		PurpleBottom = Color3.fromHex("#6B12B3"),



		PurpleInner = Color3.fromHex("#4A0C7D"),



		BrownTop = Color3.fromHex("#93521A"),



		BrownBottom = Color3.fromHex("#5C300A"),



		BrownInner = Color3.fromHex("#3A1C04"),



		TabInactiveTop = Color3.fromHex("#2A8038"),



		TabInactiveBottom = Color3.fromHex("#134E1E"),



		TabInactiveInner = Color3.fromHex("#0D3414"),



		CloseRedTop = Color3.fromHex("#E83030"),



		CloseRedBottom = Color3.fromHex("#B01414"),



		CloseRedInner = Color3.fromHex("#730D0D"),



		CloseMagentaTop = Color3.fromHex("#EE2A92"),



		CloseMagentaBottom = Color3.fromHex("#B9106B"),



		CloseMagentaInner = Color3.fromHex("#7A0A45"),



		-- Backward compatibility aliases



		WindowBody = Color3.fromHex("#0F1219"),



		CardBg = Color3.fromHex("#1E2430"),



		CardDark = Color3.fromHex("#121620"),



		MoneyGreen = Color3.fromHex("#7CFF2B"),



		NoticeYellow = Color3.fromHex("#FFD21F"),



		TabInactiveText = Color3.fromHex("#A0D09B"),



		OrangeTop = Color3.fromHex("#FF8A1F"),



		OrangeBottom = Color3.fromHex("#F0501E"),



		CyanTop = Color3.fromHex("#28CBF2"),



		CyanBottom = Color3.fromHex("#0C9CC8"),



		MagentaTop = Color3.fromHex("#EE2A92"),



		MagentaBottom = Color3.fromHex("#B9106B"),



		RedTop = Color3.fromHex("#E83030"),



		RedBottom = Color3.fromHex("#B01414"),



		LimeStroke = Color3.fromHex("#1B3A00"),



	},



	-- Screen Header Gradients (Top -> Bottom)



	Headers = {



		Shop = { Top = Color3.fromHex("#F2335F"), Bottom = Color3.fromHex("#D31F4D") },



		Daily = { Top = Color3.fromHex("#FF8A1F"), Bottom = Color3.fromHex("#F0501E") },



		Group = { Top = Color3.fromHex("#F7B52A"), Bottom = Color3.fromHex("#E8890C") },



		Playtime = { Top = Color3.fromHex("#35A5FF"), Bottom = Color3.fromHex("#1C6FE0") },



		ChairSkins = { Top = Color3.fromHex("#F5D21E"), Bottom = Color3.fromHex("#D4A000") },



		Titles = { Top = Color3.fromHex("#28CBF2"), Bottom = Color3.fromHex("#0C9CC8") },



		DailyQuest = { Top = Color3.fromHex("#44CC3C"), Bottom = Color3.fromHex("#1F9B26") },



	},



	-- Rainbow Text Sequence (STARTER PACK, MOST POPULAR!, BEST DEAL!)



	RainbowSequence = ColorSequence.new({



		ColorSequenceKeypoint.new(0.000, Color3.fromHex("#8A3CFF")),



		ColorSequenceKeypoint.new(0.166, Color3.fromHex("#3F6BFF")),



		ColorSequenceKeypoint.new(0.333, Color3.fromHex("#FF3B30")),



		ColorSequenceKeypoint.new(0.500, Color3.fromHex("#FF9A1F")),



		ColorSequenceKeypoint.new(0.666, Color3.fromHex("#FFE02E")),



		ColorSequenceKeypoint.new(0.833, Color3.fromHex("#3FE05A")),



		ColorSequenceKeypoint.new(1.000, Color3.fromHex("#19D4E8")),



	}),



}



-- Fast module-level aliases



UITheme.Font = UITheme.CONFIG.Font



UITheme.Fonts = {



	Primary = UITheme.CONFIG.Font,



	Titles = UITheme.CONFIG.Font,



	Body = UITheme.CONFIG.Font,



}



UITheme.Colors = UITheme.CONFIG.Colors



UITheme.Headers = UITheme.CONFIG.Headers



--------------------------------------------------------------------------------



-- 2. ASSET SLOTS



-- Defined placeholder slots with "rbxassetid://0", plus working stock fallbacks.



--------------------------------------------------------------------------------



UITheme.Assets = {
	Header_Studs_Shop_Red = "rbxassetid://128225868192722",
	Header_Studs_Daily_Orange = "rbxassetid://91925564826237",
	Header_Studs_Group_Gold = "rbxassetid://129278235187133",
	Header_Studs_Playtime_Blue = "rbxassetid://73760157351730",
	Header_Studs_ChairSkins_Yellow = "rbxassetid://122367808504188",
	Header_Studs_Titles_Cyan = "rbxassetid://107818334023728",
	Header_Studs_DailyQuest_Green = "rbxassetid://88180889470659",
	Icon_Luck = "rbxassetid://136598227301423",
	Icon_InfRerolls = "rbxassetid://137476810013709",



	-- Textures



	StudsTexture = "rbxassetid://10849912195", -- Verified working tiled Roblox studs



	SunburstTexture = "rbxassetid://116185617616292", -- Transparent radial rays texture with faded circle
	Icon_Bux300 = "rbxassetid://81024265406276",
	Icon_Bux1000 = "rbxassetid://108299948496912",
	Icon_Bux4000 = "rbxassetid://111348184447248",
	Icon_Bux15000 = "rbxassetid://95774170379414",



	-- Icons (256x256 PNG cartoon slots)



	Icon_CashCube = "rbxassetid://81844774538667",



	Icon_CashStack1 = "rbxassetid://81844774538667",



	Icon_CashStack2 = "rbxassetid://81844774538667",



	Icon_CashStack3 = "rbxassetid://81844774538667",



	Icon_Bux_1 = "rbxassetid://81844774538667",



	Icon_Bux_2 = "rbxassetid://81844774538667",



	Icon_Bux_3 = "rbxassetid://81844774538667",



	Icon_Bux_4 = "rbxassetid://81844774538667",



	Icon_Chest = "rbxassetid://106079886709129",



	Icon_ChestCash = "rbxassetid://0",



	Icon_Crown = "rbxassetid://79280655941472",



	Icon_Trophy = "rbxassetid://74469072540412",



	Icon_Flame = "rbxassetid://71311731449306",



	Icon_Wheel = "rbxassetid://139467358174721",



	Icon_Luck = "rbxassetid://136598227301423",



	Icon_InfRerolls = "rbxassetid://137476810013709",



	Icon_Chair_ClassicWood = "rbxassetid://129157353051496",



	Icon_Chair_StadiumBlue = "rbxassetid://115654234159991",



	Icon_Chair_CrimsonStriker = "rbxassetid://102760649316701",



	Icon_Chair_EmeraldPitch = "rbxassetid://107415959866387",



	Icon_Chair_NeonCyber = "rbxassetid://107277780753566",



	Icon_Chair_Golden = "rbxassetid://85258960888640",



	Icon_Calendar = "rbxassetid://0",



	Icon_Group = "rbxassetid://0",



	Icon_Join = "rbxassetid://0",



	Icon_Clock = "rbxassetid://0",



	Icon_Stopwatch = "rbxassetid://0",



	Icon_Lock = "rbxassetid://0",



	Icon_FastForward = "rbxassetid://0",



	Icon_Robux = "rbxasset://textures/ui/common/robux_small.png",



	Icon_Check = "rbxassetid://0",



	Icon_Like = "rbxassetid://0",



	Icon_Spin = "rbxassetid://0",



	-- Backward-compatibility aliases for existing codebase



	RobuxHexagon = "rbxassetid://9721498877",



	RobuxSmall = "rbxasset://textures/ui/common/robux_small.png",



	CashStack = "rbxassetid://87776454581651",



	CashIcon = "rbxassetid://87776454581651",



	TreasureChest = "rbxassetid://13589994500",



	CrownIcon = "rbxassetid://109923054925143",



	VipIcon = "rbxassetid://109923054925143",



	TrophyIcon = "rbxassetid://86591655180223",



	WinIcon = "rbxassetid://86591655180223",



	FlameIcon = "rbxassetid://138765021620763",



	NavFreeIcon = "rbxassetid://133237770323627",



	NavShopIcon = "rbxassetid://87281761389093",



	NavSkinsIcon = "rbxassetid://83535029342218",



	NavTitlesIcon = "rbxassetid://97397535087012",



	NavIndexIcon = "rbxassetid://92343630156093",



	NavProfileIcon = "rbxassetid://131416435227145",



	CloverIcon = "rbxassetid://87802541186816",



	LuckIcon = "rbxassetid://87802541186816",



	DiceIcon = "rbxassetid://13589998500",



	WheelIcon = "rbxassetid://13589998500",



	PadlockIcon = "rbxassetid://13589999500",



	ClockIcon = "rbxassetid://13590000500",



	SunburstBg = "rbxassetid://13590001500",



	BtnDaily = "rbxassetid://81124135771305",



	BtnQuests = "rbxassetid://96573707360537",



}



--------------------------------------------------------------------------------



-- 3. CORE PRIMITIVE HELPERS



--------------------------------------------------------------------------------



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



		existing.Color = color or UITheme.CONFIG.Colors.Outline



		existing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border



		return existing



	end



	local s = Instance.new("UIStroke")



	s.Thickness = thickness



	s.Color = color or UITheme.CONFIG.Colors.Outline



	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border



	s.Parent = parent



	return s



end



function UITheme.applyTextStroke(label: Instance, thickness: number?, color: Color3?): UIStroke



	local existing = label:FindFirstChildOfClass("UIStroke")



	if existing then



		existing.Thickness = thickness or UITheme.CONFIG.TEXT_STROKE_MEDIUM



		existing.Color = color or UITheme.CONFIG.Colors.Outline



		existing.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual



		return existing



	end



	local s = Instance.new("UIStroke")



	s.Thickness = thickness or UITheme.CONFIG.TEXT_STROKE_MEDIUM



	s.Color = color or UITheme.CONFIG.Colors.Outline



	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual



	s.Parent = label



	return s



end



function UITheme.applyGradient(guiObj: GuiObject, topColor: Color3, bottomColor: Color3, rotation: number?): UIGradient



	local grad = guiObj:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")



	grad.Color = ColorSequence.new({



		ColorSequenceKeypoint.new(0, topColor),



		ColorSequenceKeypoint.new(1, bottomColor),



	})



	grad.Rotation = rotation or 90 -- 90 deg = top to bottom



	grad.Parent = guiObj



	return grad



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



--------------------------------------------------------------------------------



-- 4. TEXTURES (STUDS & SUNBURST)



--------------------------------------------------------------------------------



-- Tiled Studs overlay: ScaleType Tile, TileSize 32x32 px



function UITheme.studs(frame: GuiObject, transparency: number?, tintColor: Color3?): ImageLabel

	local resolvedTint = tintColor

	if not resolvedTint and frame:IsA("Frame") and frame.BackgroundColor3 then

		resolvedTint = frame.BackgroundColor3

	end



	local existing = frame:FindFirstChild("Studs")

	if existing and existing:IsA("ImageLabel") then

		existing.ImageTransparency = transparency or UITheme.CONFIG.STUDS_HEADER_TRANSPARENCY

		if resolvedTint then

			existing.ImageColor3 = resolvedTint

		end

		return existing

	end



	local studs = Instance.new("ImageLabel")

	studs.Name = "Studs"

	studs.Size = UDim2.fromScale(1, 1)

	studs.Position = UDim2.fromScale(0, 0)

	studs.BackgroundTransparency = 1

	studs.Image = UITheme.Assets.StudsTexture

	studs.ImageTransparency = transparency or UITheme.CONFIG.STUDS_HEADER_TRANSPARENCY

	studs.ScaleType = Enum.ScaleType.Tile

	studs.TileSize = UDim2.fromOffset(UITheme.CONFIG.STUDS_TILE_SIZE, UITheme.CONFIG.STUDS_TILE_SIZE)

	if resolvedTint then

		studs.ImageColor3 = resolvedTint

	end

	studs.ZIndex = math.max(1, frame.ZIndex + 1)

	studs.Parent = frame

	return studs

end



-- Backward compatibility alias



UITheme.addStuds = function(parent: Instance, opacity: number?, tileSize: number?)



	if not parent:IsA("GuiObject") then return nil end



	local studs = UITheme.studs(parent, opacity)



	if tileSize then



		studs.TileSize = UDim2.fromOffset(tileSize, tileSize)



	end



	return studs



end

-- 3D Relief Studs for Buttons (sampled from reference relief texture, color-matched per variant)
function UITheme.applyButtonStuds(btn: GuiObject, variant: (VariantName | string)?, customTint: Color3?, customTrans: number?): ImageLabel
	local v = string.lower(tostring(variant or "lime"))
	local assetId = UITheme.Assets.Header_Studs_Shop_Red or "rbxassetid://128225868192722"
	local tint = customTint or Color3.new(1, 1, 1)
	local trans = customTrans or 0.18

	if v == "lime" or v == "green" or v == "equipped" or v == "equip" then
		assetId = UITheme.Assets.Header_Studs_DailyQuest_Green or "rbxassetid://88180889470659"
		trans = customTrans or 0.20
	elseif v == "gold" or v == "orange" or v == "yellow" or v == "buy" then
		assetId = UITheme.Assets.Header_Studs_Daily_Orange or "rbxassetid://91925564826237"
		trans = customTrans or 0.20
	elseif v == "blue" or v == "cyan" or v == "skip" then
		assetId = UITheme.Assets.Header_Studs_Playtime_Blue or "rbxassetid://73760157351730"
		trans = customTrans or 0.20
	elseif v == "purple" then
		assetId = UITheme.Assets.Header_Studs_Shop_Red or "rbxassetid://128225868192722"
		tint = customTint or Color3.fromHex("#852BD5")
		trans = customTrans or 0.20
	elseif v == "gray" or v == "dark" or v == "locked" or v == "claimed" then
		assetId = UITheme.Assets.Header_Studs_Playtime_Blue or "rbxassetid://73760157351730"
		tint = customTint or Color3.fromHex("#8895A5")
		trans = customTrans or 0.35
	elseif v == "brown" or v == "quest_pending" then
		assetId = UITheme.Assets.Header_Studs_Daily_Orange or "rbxassetid://91925564826237"
		tint = customTint or Color3.fromHex("#7A3E10")
		trans = customTrans or 0.25
	elseif v == "red" or v == "magenta" then
		assetId = UITheme.Assets.Header_Studs_Shop_Red or "rbxassetid://128225868192722"
		trans = customTrans or 0.20
	elseif v == "tabinactive" or v == "tab_inactive" then
		assetId = UITheme.Assets.Header_Studs_Playtime_Blue or "rbxassetid://73760157351730"
		tint = customTint or Color3.fromHex("#3A4456")
		trans = customTrans or 0.38
	end

	local studs = btn:FindFirstChild("ButtonStuds") or btn:FindFirstChild("Studs")
	if not studs or not studs:IsA("ImageLabel") then
		studs = Instance.new("ImageLabel")
		studs.Name = "ButtonStuds"
		studs.Size = UDim2.new(1.3, 0, 1.8, 0)
		studs.Position = UDim2.fromScale(0.5, 0.5)
		studs.AnchorPoint = Vector2.new(0.5, 0.5)
		studs.BackgroundTransparency = 1
		studs.ScaleType = Enum.ScaleType.Crop
		studs.Parent = btn
	end

	studs.Image = assetId
	studs.ImageColor3 = tint
	studs.ImageTransparency = trans
	studs.ZIndex = btn.ZIndex + 1

	if btn:IsA("GuiObject") then
		btn.ClipsDescendants = true
		local btnCorner = btn:FindFirstChildOfClass("UICorner")
		if btnCorner then
			local studsCorner = studs:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
			studsCorner.CornerRadius = btnCorner.CornerRadius
			studsCorner.Parent = studs
		end
	end

	for _, child in ipairs(btn:GetChildren()) do
		if child ~= studs and child.Name ~= "InnerRim" and child:IsA("GuiObject") then
			if child.ZIndex <= studs.ZIndex then
				child.ZIndex = studs.ZIndex + 2
			end
		end
	end

	return studs :: ImageLabel
end




-- Rotating sunburst rays behind icons (color-matched to icon + continuous 360 spin)



function UITheme.sunburst(parent: GuiObject, tintColor: Color3?, transparency: number?, spinDuration: number?): ImageLabel



	local existing = parent:FindFirstChild("Sunburst")



	if existing and existing:IsA("ImageLabel") then



		if tintColor then



			existing.ImageColor3 = tintColor



		end



		return existing



	end



	local sb = Instance.new("ImageLabel")



	sb.Name = "Sunburst"



	sb.Size = UDim2.fromScale(1, 1)



	sb.Position = UDim2.fromScale(0.5, 0.5)



	sb.AnchorPoint = Vector2.new(0.5, 0.5)



	sb.BackgroundTransparency = 1



	sb.Image = UITheme.Assets.SunburstTexture



	sb.ImageColor3 = tintColor or UITheme.CONFIG.Colors.White



	sb.ImageTransparency = transparency or 0.38



	sb.ScaleType = Enum.ScaleType.Fit



	sb.ZIndex = math.max(1, parent.ZIndex)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = sb

	sb.Parent = parent



	-- Continuous 360-degree rotation animation



	local dur = spinDuration or 12



	sb.Rotation = 0



	TweenService:Create(



		sb,



		TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),



		{ Rotation = 360 }



	):Play()



	return sb



end



-- Hover scale animation for cards/banners (scales up when cursor enters)



function UITheme.attachCardHover(card: GuiObject, hoverScale: number?)



	local targetScale = hoverScale or 1.045



	local uiScale = card:FindFirstChildOfClass("UIScale")



	if not uiScale then



		uiScale = Instance.new("UIScale")



		uiScale.Scale = 1.0



		uiScale.Parent = card



	end



	local baseZ = card.ZIndex



	card.MouseEnter:Connect(function()



		card.ZIndex = baseZ + 2



		TweenService:Create(



			uiScale,



			TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),



			{ Scale = targetScale }



		):Play()



	end)



	card.MouseLeave:Connect(function()



		card.ZIndex = baseZ



		TweenService:Create(



			uiScale,



			TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),



			{ Scale = 1.0 }



		):Play()



	end)



end



--------------------------------------------------------------------------------



-- 5. INTERACTION & ANIMATION HELPERS



--------------------------------------------------------------------------------



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



	if not btnObj then return end



	local isHovered = false



	local isPressed = false



	btnObj.MouseEnter:Connect(function()



		isHovered = true



		if not isPressed then



			TweenService:Create(uiScale, TweenInfo.new(UITheme.CONFIG.HOVER_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {



				Scale = startScale * UITheme.CONFIG.HOVER_SCALE,



			}):Play()



			if angle ~= 0 then



				TweenService:Create(btn, TweenInfo.new(UITheme.CONFIG.HOVER_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {



					Rotation = angle,



				}):Play()



			end



		end



	end)



	btnObj.MouseLeave:Connect(function()



		isHovered = false



		isPressed = false



		TweenService:Create(uiScale, TweenInfo.new(UITheme.CONFIG.HOVER_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {



			Scale = startScale,



		}):Play()



		if angle ~= 0 then



			TweenService:Create(btn, TweenInfo.new(UITheme.CONFIG.HOVER_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {



				Rotation = 0,



			}):Play()



		end



	end)



	btnObj.InputBegan:Connect(function(input)



		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then



			isPressed = true



			TweenService:Create(uiScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {



				Scale = startScale * UITheme.CONFIG.PRESS_SCALE,



			}):Play()



		end



	end)



	btnObj.InputEnded:Connect(function(input)



		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then



			isPressed = false



			local targetScale = if isHovered then startScale * UITheme.CONFIG.HOVER_SCALE else startScale



			TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {



				Scale = targetScale,



			}):Play()



		end



	end)



end



local function setGlobalBlur(enabled: boolean)



	local blur = Lighting:FindFirstChild("UIThemeBlur") :: BlurEffect?



	if UITheme.CONFIG.USE_BACKGROUND_BLUR then



		if enabled then



			if not blur then



				blur = Instance.new("BlurEffect")



				blur.Name = "UIThemeBlur"



				blur.Size = UITheme.CONFIG.BLUR_SIZE



				blur.Parent = Lighting



			end



			blur.Enabled = true



		elseif blur then



			blur.Enabled = false



		end



	elseif blur then



		blur.Enabled = false



	end



end



function UITheme.getModalScale(): number
	local camera = workspace.CurrentCamera
	local vY = if camera then camera.ViewportSize.Y else 720
	if vY <= 0 then vY = 720 end
	if vY <= 500 then
		return math.clamp(vY / 750, 0.44, 0.53)
	else
		return math.clamp(vY / 750, 0.55, 1.0)
	end
end

function UITheme.openWindow(win: GuiObject)
	local token = ((win:GetAttribute("WindowTweenToken") :: number?) or 0) + 1
	win:SetAttribute("WindowTweenToken", token)
	local now = os.clock()
	win:SetAttribute("OpenedAt", now)
	win.Visible = true

	local backdrop = win.Parent and win.Parent:FindFirstChild("ModalBackdrop")
	if backdrop and backdrop:IsA("GuiObject") then
		backdrop:SetAttribute("OpenedAt", now)
		backdrop:SetAttribute("OpenToken", ((backdrop:GetAttribute("OpenToken") :: number?) or 0) + 1)
	end

	local uiScale = win:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = win
	end

	local targetScale = UITheme.getModalScale()
	uiScale.Scale = UITheme.CONFIG.WINDOW_OPEN_SCALE * targetScale

	TweenService:Create(uiScale, TweenInfo.new(UITheme.CONFIG.WINDOW_OPEN_TWEEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = targetScale,
	}):Play()

	setGlobalBlur(true)
end

function UITheme.closeWindow(win: GuiObject, onComplete: (() -> ())?)
	local token = ((win:GetAttribute("WindowTweenToken") :: number?) or 0) + 1
	win:SetAttribute("WindowTweenToken", token)
	local backdrop = win.Parent and win.Parent:FindFirstChild("ModalBackdrop")
	local backdropOpenToken = if backdrop then backdrop:GetAttribute("OpenToken") else nil

	local uiScale = win:FindFirstChildOfClass("UIScale")
	if not uiScale then
		win.Visible = false
		if not backdrop or backdrop:GetAttribute("OpenToken") == backdropOpenToken then
			setGlobalBlur(false)
			if onComplete then onComplete() end
		end
		return
	end

	local targetScale = UITheme.getModalScale()
	local tw = TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = UITheme.CONFIG.WINDOW_OPEN_SCALE * targetScale,
	})
	tw:Play()
	tw.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed or win:GetAttribute("WindowTweenToken") ~= token then
			return
		end
		win.Visible = false
		uiScale.Scale = targetScale
		if not backdrop or backdrop:GetAttribute("OpenToken") == backdropOpenToken then
			setGlobalBlur(false)
			if onComplete then onComplete() end
		end
	end)
end



--------------------------------------------------------------------------------




function UITheme.animateWindowOpen(modalWrap: GuiObject, modalBox: GuiObject, targetScaleOverride: number?)
	local token = ((modalWrap:GetAttribute("WindowTweenToken") :: number?) or 0) + 1
	modalWrap:SetAttribute("WindowTweenToken", token)
	local now = os.clock()
	modalWrap:SetAttribute("OpenedAt", now)
	modalWrap.Visible = true
	if modalBox then
		modalBox.Visible = true
	end

	local backdrop = modalWrap:FindFirstChild("ModalBackdrop") or (modalWrap.Parent and modalWrap.Parent:FindFirstChild("ModalBackdrop"))
	if backdrop and backdrop:IsA("GuiObject") then
		backdrop:SetAttribute("OpenedAt", now)
		backdrop:SetAttribute("OpenToken", ((backdrop:GetAttribute("OpenToken") :: number?) or 0) + 1)
		backdrop.Visible = true
		backdrop.BackgroundTransparency = 1.0
		TweenService:Create(backdrop, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.50,
		}):Play()
	end

	local uiScale = modalWrap:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = modalWrap
	end

	local targetScale = targetScaleOverride or UITheme.getModalScale()
	uiScale.Scale = 0.55 * targetScale
	TweenService:Create(uiScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = targetScale,
	}):Play()
end

function UITheme.animateWindowClose(modalWrap: GuiObject, modalBox: GuiObject, onComplete: (() -> ())?, targetScaleOverride: number?)
	local token = ((modalWrap:GetAttribute("WindowTweenToken") :: number?) or 0) + 1
	modalWrap:SetAttribute("WindowTweenToken", token)
	local backdrop = modalWrap:FindFirstChild("ModalBackdrop") or (modalWrap.Parent and modalWrap.Parent:FindFirstChild("ModalBackdrop"))
	local backdropOpenToken = if backdrop then backdrop:GetAttribute("OpenToken") else nil
	if backdrop and backdrop:IsA("GuiObject") and backdrop:GetAttribute("OpenToken") == backdropOpenToken then
		TweenService:Create(backdrop, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1.0,
		}):Play()
	end

	local uiScale = modalWrap:FindFirstChildOfClass("UIScale") or (modalBox and modalBox:FindFirstChildOfClass("UIScale"))
	if not uiScale then
		modalWrap.Visible = false
		if modalBox then modalBox.Visible = false end
		if backdrop and backdrop:IsA("GuiObject") and backdrop:GetAttribute("OpenToken") == backdropOpenToken then
			backdrop.Visible = false
		end
		if onComplete then onComplete() end
		return
	end

	local targetScale = targetScaleOverride or (uiScale and uiScale.Scale) or UITheme.getModalScale()
	uiScale.Scale = targetScale
	local tw = TweenService:Create(uiScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Scale = 0.45 * targetScale,
	})
	tw:Play()
	tw.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed or modalWrap:GetAttribute("WindowTweenToken") ~= token then
			return
		end
		modalWrap.Visible = false
		if modalBox then modalBox.Visible = false end
		if backdrop and backdrop:IsA("GuiObject") and backdrop:GetAttribute("OpenToken") == backdropOpenToken then
			backdrop.Visible = false
		end
		uiScale.Scale = targetScale
		if onComplete then onComplete() end
	end)
end


-- 6. REUSABLE BUILDERS



--------------------------------------------------------------------------------



export type VariantName = "lime" | "gold" | "blue" | "gray" | "purple" | "brown" | "red" | "tabInactive" | string



function UITheme.getVariantColors(variant: VariantName): (Color3, Color3, Color3)



	local v = string.lower(variant or "lime")



	local c = UITheme.CONFIG.Colors



	if v == "lime" then



		return c.LimeTop, c.LimeBottom, c.LimeInner



	elseif v == "gold" then



		return c.GoldTop, c.GoldBottom, c.GoldInner



	elseif v == "blue" then



		return c.BlueTop, c.BlueBottom, c.BlueInner



	elseif v == "gray" or v == "dark" then



		return c.GrayTop, c.GrayBottom, c.GrayInner



	elseif v == "purple" then



		return c.PurpleTop, c.PurpleBottom, c.PurpleInner



	elseif v == "brown" then



		return c.BrownTop, c.BrownBottom, c.BrownInner



	elseif v == "tabinactive" or v == "tab_inactive" then



		return c.TabInactiveTop, c.TabInactiveBottom, c.TabInactiveInner



	elseif v == "red" then



		return c.CloseRedTop, c.CloseRedBottom, c.CloseRedInner



	elseif v == "magenta" then



		return c.CloseMagentaTop, c.CloseMagentaBottom, c.CloseMagentaInner



	else



		return c.LimeTop, c.LimeBottom, c.LimeInner



	end



end



-- Backward compatibility for getPresetColors



UITheme.getPresetColors = function(variant: any)



	local top, bot, inner = UITheme.getVariantColors(tostring(variant))



	return top, bot, UITheme.CONFIG.Colors.Outline



end



-- Button Builder



-- Theme.button{text, variant="lime|gold|blue|gray|purple|brown|red", size, pos, anchorPoint, parent, onClick}



export type ButtonProps = {



	text: string?,



	variant: VariantName?,



	size: UDim2?,



	pos: UDim2?,



	anchorPoint: Vector2?,



	parent: Instance?,



	wrap: boolean?,



	maxTextSize: number?,



	minTextSize: number?,



	onClick: (() -> ())?,



}



function UITheme.button(props: ButtonProps | TextButton, variantParam: VariantName?, radiusParam: number?): TextButton



	-- Support calling as UITheme.button(btn, "lime") for legacy styleButton compatibility



	if typeof(props) == "Instance" and props:IsA("TextButton") then



		local btn = props :: TextButton



		local variant = variantParam or "lime"



		local rad = radiusParam or UITheme.CONFIG.BUTTON_CORNER_RADIUS



		local topCol, botCol, innerCol = UITheme.getVariantColors(variant)



		btn.BackgroundColor3 = topCol



		btn.Font = UITheme.CONFIG.Font



		btn.TextColor3 = UITheme.CONFIG.Colors.White



		btn.TextStrokeTransparency = 1



		btn.TextScaled = true



		btn.TextWrapped = false



		btn.AutoButtonColor = false



		btn.ZIndex = math.max(2, btn.ZIndex)



		UITheme.addCorner(btn, rad)



		UITheme.applyStroke(btn, UITheme.CONFIG.BUTTON_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)



		UITheme.applyTextStroke(btn, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



		UITheme.applyGradient(btn, topCol, botCol, 90)



		UITheme.addTextConstraint(btn, 10, 28)
		UITheme.applyButtonStuds(btn, variant)



		-- Subtle darker inner edge rim frame



		local innerEdge = btn:FindFirstChild("InnerRim") :: Frame?



		if not innerEdge then



			innerEdge = Instance.new("Frame")



			innerEdge.Name = "InnerRim"



			innerEdge.Size = UDim2.new(1, 0, 0, 3)



			innerEdge.Position = UDim2.new(0, 0, 1, -3)



			innerEdge.BackgroundColor3 = innerCol



			innerEdge.BorderSizePixel = 0



			innerEdge.ZIndex = btn.ZIndex



			UITheme.addCorner(innerEdge, math.max(1, rad - 2))



			innerEdge.Parent = btn



		else



			innerEdge.BackgroundColor3 = innerCol



		end



		UITheme.setupButtonHover(btn)



		return btn



	end



	-- Table props call



	local p = (props or {}) :: ButtonProps



	local btn = Instance.new("TextButton")



	btn.Name = "Button_" .. string.gsub(p.text or "Action", "%s+", "")



	btn.Size = p.size or UDim2.new(0, 140, 0, 42)



	btn.Position = p.pos or UDim2.fromScale(0, 0)



	btn.AnchorPoint = p.anchorPoint or Vector2.new(0, 0)



	btn.Text = string.upper(p.text or "")



	btn.Parent = p.parent



	UITheme.button(btn, p.variant or "lime", UITheme.CONFIG.BUTTON_CORNER_RADIUS)



	if p.wrap ~= nil then



		btn.TextWrapped = p.wrap



	end



	if p.maxTextSize or p.minTextSize then



		UITheme.addTextConstraint(btn, p.minTextSize or 10, p.maxTextSize or 28)



	end



	if p.onClick then



		btn.MouseButton1Click:Connect(p.onClick)



	end



	return btn



end



-- Backward compatibility for styleButton



UITheme.styleButton = function(btn: TextButton, variant: any, cornerRadius: number?)



	return UITheme.button(btn, tostring(variant), cornerRadius)



end



-- Window Builder



-- Returns { Window = window, Header = header, Title = titleLbl, Close = closeBtn, Body = body }



export type WindowProps = {



	name: string?,



	title: string,



	subtitle: string?,



	titleIcon: string?,



	headerColors: { Top: Color3, Bottom: Color3 } | string?,



	closeStyle: ("magenta" | "red")?,



	size: UDim2?,



	aspect: number?,



	parent: Instance?,



	headerHeightOffset: number?,



	onClose: (() -> ())?,



}



function UITheme.window(props: WindowProps): {



	Window: Frame,



	Header: Frame,



	Title: TextLabel,



	Close: TextButton,



	Body: Frame,



}



	local p = props or {}



	local winName = p.name or "Window"



	-- Main Window Frame



	local window = Instance.new("Frame")



	window.Name = winName



	window.Size = p.size or UDim2.fromScale(0.68, 0.76)



	window.Position = UDim2.fromScale(0.5, 0.5)



	window.AnchorPoint = Vector2.new(0.5, 0.5)



	window.BackgroundColor3 = UITheme.CONFIG.Colors.DarkPanel



	window.BackgroundTransparency = UITheme.CONFIG.Colors.DarkPanelTransparency



	window.BorderSizePixel = 0



	window.ClipsDescendants = true



	window.ZIndex = 5



	UITheme.addCorner(window, UITheme.CONFIG.WINDOW_CORNER_RADIUS)



	UITheme.applyStroke(window, UITheme.CONFIG.WINDOW_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)



	if p.aspect then



		local aspect = Instance.new("UIAspectRatioConstraint")



		aspect.AspectRatio = p.aspect



		aspect.AspectType = Enum.AspectType.FitWithinMaxSize



		aspect.DominantAxis = Enum.DominantAxis.Width



		aspect.Parent = window



	end



	local uiScale = Instance.new("UIScale")
	uiScale.Scale = UITheme.getModalScale()
	uiScale.Parent = window

	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if window.Visible then
				uiScale.Scale = UITheme.getModalScale()
			end
		end)
	end



	-- Header (~15% height)



	local header = Instance.new("Frame")



	header.Name = "Header"



	local headerHeightScale = if p.headerHeightOffset then 0 else UITheme.CONFIG.HEADER_HEIGHT_SCALE



	local headerHeightOffset = p.headerHeightOffset or 0



	header.Size = UDim2.new(1, 0, headerHeightScale, headerHeightOffset)



	header.Position = UDim2.fromScale(0, 0)



	header.BorderSizePixel = 0



	header.ZIndex = window.ZIndex + 1



	header.Parent = window



	-- Header Colors



	local topCol = UITheme.CONFIG.Headers.Shop.Top



	local botCol = UITheme.CONFIG.Headers.Shop.Bottom



	if typeof(p.headerColors) == "string" then



		local h = UITheme.CONFIG.Headers[p.headerColors]



		if h then



			topCol = h.Top



			botCol = h.Bottom



		end



	elseif typeof(p.headerColors) == "table" and p.headerColors.Top and p.headerColors.Bottom then



		topCol = p.headerColors.Top



		botCol = p.headerColors.Bottom



	end



	header.BackgroundColor3 = topCol



	UITheme.applyGradient(header, topCol, botCol, 90)



	UITheme.studs(header, UITheme.CONFIG.STUDS_HEADER_TRANSPARENCY, topCol)



	-- Black bottom border on header



	local headerBottomBorder = Instance.new("Frame")



	headerBottomBorder.Name = "BottomBorder"



	headerBottomBorder.Size = UDim2.new(1, 0, 0, 3)



	headerBottomBorder.Position = UDim2.new(0, 0, 1, -3)



	headerBottomBorder.BackgroundColor3 = UITheme.CONFIG.Colors.Outline



	headerBottomBorder.BorderSizePixel = 0



	headerBottomBorder.ZIndex = header.ZIndex + 3



	headerBottomBorder.Parent = header



	-- Header Title (Left-aligned, ~3% padding, ~55% height)



	local titleStartOffset = UITheme.CONFIG.HEADER_TITLE_PADDING_SCALE



	if p.titleIcon and p.titleIcon ~= "" then



		local iconImg = Instance.new("ImageLabel")



		iconImg.Name = "TitleIcon"



		iconImg.Size = UDim2.new(0.65, 0, 0.65, 0)



		iconImg.SizeConstraint = Enum.SizeConstraint.RelativeYY



		iconImg.Position = UDim2.new(titleStartOffset, 0, 0.5, 0)



		iconImg.AnchorPoint = Vector2.new(0, 0.5)



		iconImg.BackgroundTransparency = 1



		iconImg.Image = p.titleIcon



		iconImg.ScaleType = Enum.ScaleType.Fit



		iconImg.ZIndex = header.ZIndex + 2



		iconImg.Parent = header



		titleStartOffset = titleStartOffset + 0.06



	end



	local titleLbl = Instance.new("TextLabel")



	titleLbl.Name = "Title"



	titleLbl.Size = UDim2.new(0.70, 0, UITheme.CONFIG.HEADER_TITLE_HEIGHT_SCALE, 0)



	titleLbl.Position = UDim2.new(titleStartOffset, 0, 0.5, 0)



	titleLbl.AnchorPoint = Vector2.new(0, 0.5)



	titleLbl.BackgroundTransparency = 1



	titleLbl.Font = UITheme.CONFIG.Font



	titleLbl.Text = string.upper(p.title or "")



	titleLbl.TextColor3 = UITheme.CONFIG.Colors.White



	titleLbl.TextScaled = true



	titleLbl.TextWrapped = false



	titleLbl.TextXAlignment = Enum.TextXAlignment.Left



	titleLbl.ZIndex = header.ZIndex + 2



	UITheme.applyTextStroke(titleLbl, UITheme.CONFIG.TEXT_STROKE_LARGE, UITheme.CONFIG.Colors.Outline)



	UITheme.addTextConstraint(titleLbl, 14, 38)



	titleLbl.Parent = header



	if p.subtitle and p.subtitle ~= "" then



		titleLbl.Size = UDim2.new(0.70, 0, 0.45, 0)



		titleLbl.Position = UDim2.new(titleStartOffset, 0, 0.32, 0)



		local subLbl = Instance.new("TextLabel")



		subLbl.Name = "Subtitle"



		subLbl.Size = UDim2.new(0.70, 0, 0.28, 0)



		subLbl.Position = UDim2.new(titleStartOffset, 0, 0.72, 0)



		subLbl.AnchorPoint = Vector2.new(0, 0.5)



		subLbl.BackgroundTransparency = 1



		subLbl.Font = UITheme.CONFIG.Font



		subLbl.Text = p.subtitle



		subLbl.TextColor3 = UITheme.CONFIG.Colors.DescriptionGold



		subLbl.TextScaled = true



		subLbl.TextWrapped = false



		subLbl.TextXAlignment = Enum.TextXAlignment.Left



		subLbl.ZIndex = header.ZIndex + 2



		UITheme.applyTextStroke(subLbl, UITheme.CONFIG.TEXT_STROKE_SMALL, UITheme.CONFIG.Colors.Outline)



		UITheme.addTextConstraint(subLbl, 10, 18)



		subLbl.Parent = header



	end



	-- Close Button: square at right (~78% header height, ~1.5% margin)



	local closeBtn = Instance.new("TextButton")



	closeBtn.Name = "CloseButton"



	closeBtn.Size = UDim2.new(UITheme.CONFIG.CLOSE_BUTTON_HEIGHT_SCALE, 0, UITheme.CONFIG.CLOSE_BUTTON_HEIGHT_SCALE, 0)



	closeBtn.SizeConstraint = Enum.SizeConstraint.RelativeYY



	closeBtn.Position = UDim2.new(1 - UITheme.CONFIG.CLOSE_BUTTON_MARGIN_SCALE, 0, 0.5, 0)



	closeBtn.AnchorPoint = Vector2.new(1, 0.5)



	closeBtn.Text = "X"



	closeBtn.Font = UITheme.CONFIG.Font



	closeBtn.TextColor3 = UITheme.CONFIG.Colors.White



	closeBtn.TextScaled = true



	closeBtn.AutoButtonColor = false



	closeBtn.ZIndex = header.ZIndex + 4



	local closeVariant = (p.closeStyle == "red") and "red" or "magenta"



	local cTop, cBot = UITheme.getVariantColors(closeVariant)



	closeBtn.BackgroundColor3 = cTop



	UITheme.applyGradient(closeBtn, cTop, cBot, 90)



	UITheme.addCorner(closeBtn, UITheme.CONFIG.BUTTON_CORNER_RADIUS)



	UITheme.applyStroke(closeBtn, UITheme.CONFIG.BUTTON_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)



	UITheme.applyTextStroke(closeBtn, UITheme.CONFIG.TEXT_STROKE_LARGE, UITheme.CONFIG.Colors.Outline)



	UITheme.applyButtonStuds(closeBtn, closeVariant)



	UITheme.setupButtonHover(closeBtn)



	local function handleClose()
		UITheme.closeWindow(window, p.onClose)
	end
	closeBtn.MouseButton1Click:Connect(handleClose)
	closeBtn.Activated:Connect(handleClose)



	closeBtn.Parent = header



	-- Window Body (Translucent panel)



	local body = Instance.new("Frame")



	body.Name = "Body"



	body.Size = UDim2.new(1, 0, 1 - headerHeightScale, -headerHeightOffset)



	body.Position = UDim2.new(0, 0, headerHeightScale, headerHeightOffset)



	body.BackgroundColor3 = UITheme.CONFIG.Colors.DarkPanel



	body.BackgroundTransparency = UITheme.CONFIG.Colors.DarkPanelTransparency



	body.BorderSizePixel = 0



	body.ZIndex = window.ZIndex + 1



	UITheme.studs(body, UITheme.CONFIG.STUDS_PANEL_TRANSPARENCY)



	body.Parent = window



	if p.parent then



		window.Parent = p.parent



	end



	return {



		Window = window,



		Header = header,



		Title = titleLbl,



		Close = closeBtn,



		Body = body,



	}



end



-- Dedicated Price Button (Robux ImageLabel LEFT ~6%, price number CENTERED, white + stroke, no text glyph)



function UITheme.priceButton(target: Instance, price: number | string, arg3: any?, arg4: any?): TextButton



	local btn: TextButton



	if target:IsA("GuiButton") then



		btn = target :: TextButton



		local variant = if typeof(arg4) == "string" then string.lower(arg4) else "lime"



		btn.Text = ""



		UITheme.button(btn, variant, UITheme.CONFIG.BUTTON_CORNER_RADIUS)



	else



		btn = Instance.new("TextButton")



		btn.Name = "PriceButton"



		btn.Size = if typeof(arg3) == "UDim2" then arg3 else UDim2.new(0, 120, 0, 36)



		btn.Position = if typeof(arg4) == "UDim2" then arg4 else UDim2.fromScale(0, 0)



		btn.Text = ""



		btn.Parent = target



		UITheme.button(btn, "lime", UITheme.CONFIG.BUTTON_CORNER_RADIUS)



	end



	-- Robux Icon anchored LEFT (~6% padding, ~58% height)



	local robuxIcon = Instance.new("ImageLabel")



	robuxIcon.Name = "RobuxIcon"



	robuxIcon.Size = UDim2.new(0.58, 0, 0.58, 0)



	robuxIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY



	robuxIcon.Position = UDim2.new(0.06, 0, 0.5, 0)



	robuxIcon.AnchorPoint = Vector2.new(0, 0.5)



	robuxIcon.BackgroundTransparency = 1



	robuxIcon.Image = UITheme.Assets.Icon_Robux



	robuxIcon.ScaleType = Enum.ScaleType.Fit



	robuxIcon.ZIndex = btn.ZIndex + 3



	robuxIcon.Parent = btn



	-- Price number CENTERED cleanly in the button



	local priceLbl = Instance.new("TextLabel")



	priceLbl.Name = "PriceNumber"



	priceLbl.Size = UDim2.fromScale(0.68, 0.84)



	priceLbl.Position = UDim2.fromScale(0.58, 0.5)



	priceLbl.AnchorPoint = Vector2.new(0.5, 0.5)



	priceLbl.TextXAlignment = Enum.TextXAlignment.Center



	priceLbl.TextYAlignment = Enum.TextYAlignment.Center



	priceLbl.BackgroundTransparency = 1



	priceLbl.Font = UITheme.CONFIG.Font



	priceLbl.Text = tostring(price) -- Number only, never "R$"



	priceLbl.TextColor3 = UITheme.CONFIG.Colors.White



	priceLbl.TextScaled = true



	priceLbl.TextWrapped = false



	priceLbl.ZIndex = btn.ZIndex + 3



	UITheme.applyTextStroke(priceLbl, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



	UITheme.addTextConstraint(priceLbl, 12, 24)



	priceLbl.Parent = btn



	return btn



end



-- Floating Price Badge: Robux hexagon icon + lime number with black stroke, floating top-right, NO background plate



function UITheme.priceBadge(button: GuiObject, price: number | string): Frame
	local badge = Instance.new("Frame")
	badge.Name = "PriceBadge"
	badge.Size = UDim2.fromOffset(64, 26)
	badge.Position = UDim2.new(1, -4, 0, -6)
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.BackgroundColor3 = Color3.fromHex("#48C90E")
	badge.BackgroundTransparency = 0
	badge.ClipsDescendants = true
	badge.ZIndex = button.ZIndex + 3

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = badge

	UITheme.applyStroke(badge, 2, UITheme.CONFIG.Colors.Outline)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.08, 0)
	pad.PaddingRight = UDim.new(0.08, 0)
	pad.PaddingTop = UDim.new(0, 0)
	pad.PaddingBottom = UDim.new(0, 0)
	pad.Parent = badge

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0.06, 0)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = badge

	local icon = Instance.new("ImageLabel")
	icon.Name = "RobuxIcon"
	icon.LayoutOrder = 1
	icon.Size = UDim2.new(1, 0, 0.75, 0)
	icon.BackgroundTransparency = 1
	icon.Image = UITheme.Assets.RobuxHexagon
	icon.ImageColor3 = UITheme.CONFIG.Colors.White
	icon.ScaleType = Enum.ScaleType.Fit
	local iconAspect = Instance.new("UIAspectRatioConstraint")
	iconAspect.AspectRatio = 1.0
	iconAspect.DominantAxis = Enum.DominantAxis.Height
	iconAspect.Parent = icon
	icon.ZIndex = badge.ZIndex + 1
	icon.Parent = badge

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name = "PriceNumber"
	priceLbl.LayoutOrder = 2
	priceLbl.Size = UDim2.new(0.55, 0, 0.85, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font = UITheme.CONFIG.Font
	priceLbl.Text = tostring(price)
	priceLbl.TextColor3 = UITheme.CONFIG.Colors.White
	priceLbl.TextScaled = true
	priceLbl.RichText = false
	priceLbl.TextXAlignment = Enum.TextXAlignment.Center
	priceLbl.TextYAlignment = Enum.TextYAlignment.Center
	priceLbl.ZIndex = badge.ZIndex + 1
	local tc = Instance.new("UITextSizeConstraint")
	tc.MinTextSize = 10
	tc.MaxTextSize = 26
	tc.Parent = priceLbl
	UITheme.applyTextStroke(priceLbl, 2, UITheme.CONFIG.Colors.Outline)
	priceLbl.Parent = badge

	badge.Parent = button
	return badge
end

-- Rainbow Text: ColorSequence gradient overlay



function UITheme.rainbowText(label: TextLabel): UIGradient



	label.TextColor3 = UITheme.CONFIG.Colors.White



	local grad = label:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")



	grad.Name = "RainbowGradient"



	grad.Color = UITheme.CONFIG.RainbowSequence



	grad.Rotation = 0



	grad.Parent = label



	UITheme.applyTextStroke(label, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



	return grad



end



-- Ribbon: Angled corner banner



function UITheme.ribbon(parent: GuiObject, text: string, color: Color3?, angle: number?): Frame



	local ribWrap = Instance.new("Frame")



	ribWrap.Name = "RibbonWrap"



	ribWrap.Size = UDim2.fromOffset(90, 26)



	ribWrap.Position = UDim2.new(0, -6, 0, 8)



	ribWrap.AnchorPoint = Vector2.new(0, 0)



	ribWrap.Rotation = angle or -24



	ribWrap.BackgroundColor3 = color or UITheme.CONFIG.Colors.CloseRedTop



	ribWrap.BorderSizePixel = 0



	ribWrap.ZIndex = parent.ZIndex + 4



	UITheme.addCorner(ribWrap, UITheme.CONFIG.CARD_CORNER_RADIUS)



	UITheme.applyStroke(ribWrap, 2.5, UITheme.CONFIG.Colors.Outline)



	UITheme.applyGradient(ribWrap, color or UITheme.CONFIG.Colors.CloseRedTop, UITheme.CONFIG.Colors.CloseRedBottom, 90)



	local ribText = Instance.new("TextLabel")



	ribText.Name = "RibbonText"



	ribText.Size = UDim2.fromScale(1, 1)



	ribText.BackgroundTransparency = 1



	ribText.Font = UITheme.CONFIG.Font



	ribText.Text = string.upper(text)



	ribText.TextColor3 = UITheme.CONFIG.Colors.White



	ribText.TextScaled = true



	ribText.ZIndex = ribWrap.ZIndex + 1



	UITheme.applyTextStroke(ribText, UITheme.CONFIG.TEXT_STROKE_SMALL, UITheme.CONFIG.Colors.Outline)



	UITheme.addTextConstraint(ribText, 9, 13)



	ribText.Parent = ribWrap



	ribWrap.Parent = parent



	return ribWrap



end



-- Progress Bar



function UITheme.progressBar(



	parent: Instance,



	current: number,



	maxVal: number,



	size: UDim2?,



	pos: UDim2?,



	fillColor: Color3?



): { Rail: Frame, Fill: Frame, Update: (number, number) -> () }



	local rail = Instance.new("Frame")



	rail.Name = "ProgressBarRail"



	rail.Size = size or UDim2.new(1, 0, 0, 16)



	rail.Position = pos or UDim2.fromScale(0, 0)



	rail.BackgroundColor3 = UITheme.CONFIG.Colors.DarkPanel



	rail.BorderSizePixel = 0



	rail.ClipsDescendants = true



	rail.ZIndex = 4



	UITheme.addCorner(rail, UITheme.CONFIG.CARD_CORNER_RADIUS)



	UITheme.applyStroke(rail, 2.5, UITheme.CONFIG.Colors.Outline)



	local fill = Instance.new("Frame")



	fill.Name = "Fill"



	local frac = math.clamp(current / math.max(maxVal, 1), 0, 1)



	fill.Size = UDim2.new(frac, 0, 1, 0)



	fill.Position = UDim2.fromScale(0, 0)



	local topCol = fillColor or UITheme.CONFIG.Colors.LimeTop



	local botCol = UITheme.CONFIG.Colors.LimeBottom



	fill.BackgroundColor3 = topCol



	fill.BorderSizePixel = 0



	fill.ZIndex = rail.ZIndex + 1



	UITheme.addCorner(fill, UITheme.CONFIG.CARD_CORNER_RADIUS)



	UITheme.applyGradient(fill, topCol, botCol, 90)



	fill.Parent = rail



	rail.Parent = parent



	local function update(curr: number, mx: number)



		local newFrac = math.clamp(curr / math.max(mx, 1), 0, 1)



		TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {



			Size = UDim2.new(newFrac, 0, 1, 0),



		}):Play()



	end



	return { Rail = rail, Fill = fill, Update = update }



end



-- ScrollBar Formatter: thickness 8, color #E6E6E6, transparency 0.15, no track



function UITheme.scroll(scrollingFrame: ScrollingFrame)



	scrollingFrame.ScrollBarThickness = UITheme.CONFIG.SCROLLBAR_THICKNESS



	scrollingFrame.ScrollBarImageColor3 = UITheme.CONFIG.SCROLLBAR_COLOR



	scrollingFrame.ScrollBarImageTransparency = UITheme.CONFIG.SCROLLBAR_TRANSPARENCY



	scrollingFrame.BorderSizePixel = 0



	scrollingFrame.TopImage = ""



	scrollingFrame.MidImage = ""



	scrollingFrame.BottomImage = ""



end



-- Reusable Gamepass Card Builder (Prompt 1 Section 2)



export type GamepassCardProps = {



	id: string,



	name: string,



	description: string,



	icon: string?,



	iconName: string?,



	sunburstColor: Color3?,



	price: number | string,



	owned: boolean?,



	size: UDim2?,



	pos: UDim2?,



	layoutOrder: number?,



	parent: Instance?,



	onBuy: (() -> ())?,



}



function UITheme.gamepassCard(props: GamepassCardProps): {



	Card: Frame,



	PriceButton: TextButton,



	OwnedButton: TextButton,



	SetOwned: (owned: boolean) -> (),



}



	local card = Instance.new("Frame")



	card.Name = "GamepassCard_" .. props.id



	card.Size = props.size or UDim2.new(0.4925, 0, 0, 148)



	card.Position = props.pos or UDim2.fromScale(0, 0)



	card.BackgroundColor3 = Color3.fromHex("#4E44A7")
	card.BackgroundTransparency = 0
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	if props.layoutOrder then
		card.LayoutOrder = props.layoutOrder
	end
	UITheme.addCorner(card, UITheme.CONFIG.CARD_CORNER_RADIUS)
	UITheme.applyStroke(card, 2, Color3.fromHex("#332A7A"))



	-- Sunburst behind the icon: warm yellow-white, ~50% transparent, centered on the icon



	local sbWrap = Instance.new("Frame")



	sbWrap.Name = "SunburstWrap"



	sbWrap.Size = UDim2.fromScale(0.56, 0.96)



	sbWrap.Position = UDim2.fromScale(0.25, 0.56)



	sbWrap.AnchorPoint = Vector2.new(0.5, 0.5)



	sbWrap.BackgroundTransparency = 1



	sbWrap.ZIndex = card.ZIndex + 1



	sbWrap.Parent = card



	UITheme.sunburst(sbWrap, props.sunburstColor or Color3.fromHex("#FFD21F"), 0.35)



	UITheme.attachCardHover(card, 1.045)



	-- Icon: left, centered at ~25% of card width, ~64% of card height, slightly below center



	local iconImg = Instance.new("ImageLabel")



	iconImg.Name = props.iconName or ("Icon_" .. props.id)



	iconImg.Size = UDim2.fromScale(0.38, 0.64)



	iconImg.Position = UDim2.fromScale(0.25, 0.58)



	iconImg.AnchorPoint = Vector2.new(0.5, 0.5)



	iconImg.BackgroundTransparency = 1



	iconImg.Image = props.icon or UITheme.Assets.Icon_Crown



	iconImg.ScaleType = Enum.ScaleType.Fit



	iconImg.ZIndex = card.ZIndex + 2



	iconImg.Parent = card



	-- Name: top-left (2%-45% width), white, black stroke 4, ~28% of card height, drawn ABOVE the icon



	local isTwoLineName = string.len(props.name) >= 9



	local nameLbl = Instance.new("TextLabel")



	nameLbl.Name = "Title"



	nameLbl.Size = UDim2.fromScale(0.44, if isTwoLineName then 0.36 else 0.28)



	nameLbl.Position = UDim2.fromScale(0.02, 0.04)



	nameLbl.BackgroundTransparency = 1



	nameLbl.Font = UITheme.CONFIG.Font



	nameLbl.Text = string.upper(props.name)



	nameLbl.TextColor3 = UITheme.CONFIG.Colors.White



	nameLbl.TextScaled = true



	nameLbl.TextWrapped = true



	nameLbl.TextXAlignment = Enum.TextXAlignment.Center



	nameLbl.ZIndex = card.ZIndex + 4



	UITheme.applyTextStroke(nameLbl, UITheme.CONFIG.TEXT_STROKE_LARGE, UITheme.CONFIG.Colors.Outline)



	UITheme.addTextConstraint(nameLbl, 12, if isTwoLineName then 24 else 32)



	nameLbl.Parent = card



	-- Description: right half (50%-97% width, 12%-60% height), gold-yellow #FFD21F, stroke 3, centered, uppercase, up to 3 lines



	local descLbl = Instance.new("TextLabel")



	descLbl.Name = "Description"



	descLbl.Size = UDim2.fromScale(0.47, 0.48)



	descLbl.Position = UDim2.fromScale(0.50, 0.12)



	descLbl.BackgroundTransparency = 1



	descLbl.Font = UITheme.CONFIG.Font



	descLbl.Text = string.upper(props.description)



	descLbl.TextColor3 = UITheme.CONFIG.Colors.DescriptionGold



	descLbl.TextScaled = true



	descLbl.TextWrapped = true



	descLbl.TextXAlignment = Enum.TextXAlignment.Center



	descLbl.TextYAlignment = Enum.TextYAlignment.Center



	descLbl.ZIndex = card.ZIndex + 3



	UITheme.applyTextStroke(descLbl, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



	UITheme.addTextConstraint(descLbl, 10, 22)



	descLbl.Parent = card



	-- Price button: bottom-right, 44% x 25% of card, margins 3.5% right and 5% bottom



	local priceBtn = UITheme.priceButton(



		card,



		props.price,



		UDim2.fromScale(0.44, 0.25),



		UDim2.fromScale(1 - 0.035, 1 - 0.05)



	)



	priceBtn.AnchorPoint = Vector2.new(1, 1)



	priceBtn.ZIndex = card.ZIndex + 4



	-- OWNED (ADAPTATION): gray "OWNED" button with Icon_Check, same size



	local ownedBtn = UITheme.button({



		text = "   OWNED",



		variant = "gray",



		size = UDim2.fromScale(0.44, 0.25),



		pos = UDim2.fromScale(1 - 0.035, 1 - 0.05),



		anchorPoint = Vector2.new(1, 1),



		parent = card,



	})



	ownedBtn.Name = "OwnedButton"



	ownedBtn.Visible = false



	ownedBtn.ZIndex = card.ZIndex + 4



	local checkIcon = Instance.new("ImageLabel")



	checkIcon.Name = "Icon_Check"



	checkIcon.Size = UDim2.new(0.54, 0, 0.54, 0)



	checkIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY



	checkIcon.Position = UDim2.new(0.06, 0, 0.5, 0)



	checkIcon.AnchorPoint = Vector2.new(0, 0.5)



	checkIcon.BackgroundTransparency = 1



	checkIcon.Image = UITheme.Assets.Icon_Check



	checkIcon.ScaleType = Enum.ScaleType.Fit



	checkIcon.ZIndex = ownedBtn.ZIndex + 2



	checkIcon.Parent = ownedBtn



	if UITheme.Assets.Icon_Check == "rbxassetid://0" then



		checkIcon.Visible = false



		local checkLbl = Instance.new("TextLabel")



		checkLbl.Name = "CheckGlyph"



		checkLbl.Size = UDim2.new(0.30, 0, 0.80, 0)



		checkLbl.Position = UDim2.new(0.06, 0, 0.5, 0)



		checkLbl.AnchorPoint = Vector2.new(0, 0.5)



		checkLbl.BackgroundTransparency = 1



		checkLbl.Font = UITheme.CONFIG.Font



		checkLbl.Text = "✓"



		checkLbl.TextColor3 = UITheme.CONFIG.Colors.White



		checkLbl.TextScaled = true



		checkLbl.ZIndex = ownedBtn.ZIndex + 2



		UITheme.applyTextStroke(checkLbl, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



		checkLbl.Parent = ownedBtn



	end



	local function setOwned(isOwned: boolean)



		priceBtn.Visible = not isOwned



		ownedBtn.Visible = isOwned



	end



	if props.owned then



		setOwned(true)



	end



	if props.onBuy then



		priceBtn.Activated:Connect(props.onBuy)



	end



	if props.parent then



		card.Parent = props.parent



	end



	return {



		Card = card,



		PriceButton = priceBtn,



		OwnedButton = ownedBtn,



		SetOwned = setOwned,



	}



end



--------------------------------------------------------------------------------



-- 7. BACKWARD-COMPATIBILITY ADAPTERS FOR EXISTING CODEBASE



--------------------------------------------------------------------------------



UITheme.styleText = function(label: TextLabel | TextButton, maxSize: number?, minSize: number?, strokeThickness: number?, color: Color3?)



	label.TextScaled = true



	if color then label.TextColor3 = color end



	UITheme.addTextConstraint(label, minSize or 10, maxSize or 28)



	return UITheme.applyTextStroke(label, strokeThickness or UITheme.CONFIG.TEXT_STROKE_MEDIUM)



end



UITheme.styleWindow = function(window: Frame, headerColor: any)



	window.BackgroundColor3 = UITheme.CONFIG.Colors.DarkPanel



	window.BackgroundTransparency = UITheme.CONFIG.Colors.DarkPanelTransparency



	UITheme.addCorner(window, UITheme.CONFIG.WINDOW_CORNER_RADIUS)



	UITheme.applyStroke(window, UITheme.CONFIG.WINDOW_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)



	UITheme.studs(window, UITheme.CONFIG.STUDS_PANEL_TRANSPARENCY)



end



UITheme.styleHeader = function(headerFrame: Frame, variant: any, titleText: string, subtitleText: string?): TextLabel



	local vStr = tostring(variant or "Shop")



	local hEntry = UITheme.CONFIG.Headers[vStr]



	local topCol, botCol



	if hEntry then



		topCol, botCol = hEntry.Top, hEntry.Bottom



	else



		topCol, botCol = UITheme.getVariantColors(vStr)



	end



	headerFrame.BackgroundColor3 = topCol



	UITheme.addCorner(headerFrame, UITheme.CONFIG.WINDOW_CORNER_RADIUS)



	UITheme.applyStroke(headerFrame, UITheme.CONFIG.WINDOW_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)



	UITheme.applyGradient(headerFrame, topCol, botCol, 90)



	UITheme.studs(headerFrame, UITheme.CONFIG.STUDS_HEADER_TRANSPARENCY, topCol)



	local titleLbl = headerFrame:FindFirstChild("HeaderTitle") :: TextLabel?



	if not titleLbl then



		titleLbl = Instance.new("TextLabel")



		titleLbl.Name = "HeaderTitle"



		titleLbl.BackgroundTransparency = 1



		titleLbl.Font = UITheme.CONFIG.Font



		titleLbl.TextColor3 = UITheme.CONFIG.Colors.White



		titleLbl.TextScaled = true



		titleLbl.TextXAlignment = Enum.TextXAlignment.Left



		titleLbl.ZIndex = headerFrame.ZIndex + 2



		titleLbl.Parent = headerFrame



		UITheme.applyTextStroke(titleLbl, UITheme.CONFIG.TEXT_STROKE_LARGE, UITheme.CONFIG.Colors.Outline)



	end



	titleLbl.Text = string.upper(titleText or "")



	titleLbl.Size = UDim2.new(0.80, 0, UITheme.CONFIG.HEADER_TITLE_HEIGHT_SCALE, 0)



	titleLbl.Position = UDim2.new(UITheme.CONFIG.HEADER_TITLE_PADDING_SCALE, 0, 0.5, 0)



	titleLbl.AnchorPoint = Vector2.new(0, 0.5)



	return titleLbl



end



UITheme.createRobuxBadge = function(parent: GuiObject, price: number, size: UDim2?, pos: UDim2?): Frame



	return UITheme.priceBadge(parent, price)



end



UITheme.skinButton = function(button: TextButton, state: "EQUIPPED" | "EQUIP" | "BUY", price: number?, canAfford: boolean?): TextButton



	local cashIcon = button:FindFirstChild("BtnCashIcon") :: ImageLabel?



	if state == "EQUIPPED" then



		button.Text = "EQUIPPED"



		button.Active = false



		button.AutoButtonColor = false



		button.TextColor3 = UITheme.CONFIG.Colors.White



		UITheme.button(button, "lime", 8)



		UITheme.applyGradient(button, Color3.fromHex("#6FB81F"), Color3.fromHex("#4A8A10"), 90)



		if cashIcon then cashIcon.Visible = false end



	elseif state == "EQUIP" then



		button.Text = "EQUIP"



		button.Active = true



		button.AutoButtonColor = true



		button.TextColor3 = UITheme.CONFIG.Colors.White



		UITheme.button(button, "lime", 8)



		UITheme.applyGradient(button, Color3.fromHex("#84CC16"), Color3.fromHex("#4D7C0F"), 90)



		if cashIcon then cashIcon.Visible = false end



	else



		button.Text = if price and price > 0 then `   ${price} BUX` else "BUY"



		button.Active = true



		button.AutoButtonColor = true



		button.TextColor3 = UITheme.CONFIG.Colors.White



		if canAfford ~= false then



			UITheme.button(button, "gold", 8)



			UITheme.applyGradient(button, Color3.fromHex("#FBBF24"), Color3.fromHex("#D97706"), 90)



		else



			UITheme.button(button, "gray", 8)



			UITheme.applyGradient(button, Color3.fromHex("#4B5563"), Color3.fromHex("#374151"), 90)



		end



		if not cashIcon then



			cashIcon = Instance.new("ImageLabel")



			cashIcon.Name = "BtnCashIcon"



			cashIcon.Size = UDim2.fromOffset(24, 24)



			cashIcon.Position = UDim2.new(0, 14, 0.5, 0)



			cashIcon.AnchorPoint = Vector2.new(0, 0.5)



			cashIcon.BackgroundTransparency = 1



			cashIcon.Image = UITheme.Assets.CashStack



			cashIcon.ScaleType = Enum.ScaleType.Fit



			cashIcon.ZIndex = button.ZIndex + 2



			cashIcon.Parent = button



		end



		cashIcon.Visible = true



	end



	return button



end







UITheme.addShineSweep = function(guiObj: GuiObject) end



UITheme.addBevel = function(parent: Instance, radius: number?) end



UITheme.addShadow = function(parent: Instance, cornerRadius: number, offset: number?) return nil end



UITheme.addPulse = function(guiObj: GuiObject, minScale: number?, maxScale: number?, duration: number?)



	local uiScale = guiObj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", guiObj)



	local minS = minScale or 1.0



	local maxS = maxScale or 1.05



	local dur = duration or 2.0



	task.spawn(function()



		while guiObj and guiObj.Parent do



			local twUp = TweenService:Create(uiScale, TweenInfo.new(dur / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = maxS })



			twUp:Play()



			twUp.Completed:Wait()



			local twDn = TweenService:Create(uiScale, TweenInfo.new(dur / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = minS })



			twDn:Play()



			twDn.Completed:Wait()



		end



	end)



end



--------------------------------------------------------------------------------



-- 8. PREVIEW TOOL (/themepreview)



-- Creates an interactive showcase of all components, tokens, and candidate fonts.



--------------------------------------------------------------------------------



function UITheme.preview(targetGui: Instance?)



	local parentGui = targetGui



	if not parentGui then



		local lp = Players.LocalPlayer



		if lp then



			parentGui = lp:WaitForChild("PlayerGui")



		end



	end



	if not parentGui then return end



	local existing = parentGui:FindFirstChild("ThemePreviewGui")



	if existing then



		existing:Destroy()



	end



	local screenGui = Instance.new("ScreenGui")



	screenGui.Name = "ThemePreviewGui"



	screenGui.ResetOnSpawn = false



	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling



	local winData = UITheme.window({



		name = "PreviewWindow",



		title = "UI THEME PREVIEW TOOL",



		subtitle = "Design Tokens, Buttons, Badges, Gradients & Font Comparison",



		headerColors = UITheme.CONFIG.Headers.Shop,



		closeStyle = "magenta",



		size = UDim2.fromScale(0.85, 0.88),



		aspect = 1.35,



		parent = screenGui,



	})



	local scroll = Instance.new("ScrollingFrame")



	scroll.Name = "ShowcaseScroll"



	scroll.Size = UDim2.new(1, -20, 1, -20)



	scroll.Position = UDim2.fromOffset(10, 10)



	scroll.BackgroundTransparency = 1



	scroll.CanvasSize = UDim2.new(0, 0, 0, 1420)



	UITheme.scroll(scroll)



	scroll.Parent = winData.Body



	local layout = Instance.new("UIListLayout")



	layout.Padding = UDim.new(0, 14)



	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center



	layout.SortOrder = Enum.SortOrder.LayoutOrder



	layout.Parent = scroll



	local function makeSection(title: string, height: number, order: number): Frame



		local sec = Instance.new("Frame")



		sec.Name = "Section_" .. title



		sec.Size = UDim2.new(0.96, 0, 0, height)



		sec.BackgroundColor3 = UITheme.CONFIG.Colors.DarkPanel



		sec.BackgroundTransparency = 0.5



		sec.LayoutOrder = order



		UITheme.addCorner(sec, UITheme.CONFIG.CARD_CORNER_RADIUS)



		UITheme.applyStroke(sec, UITheme.CONFIG.CARD_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)



		local secTitle = Instance.new("TextLabel")



		secTitle.Size = UDim2.new(1, -20, 0, 24)



		secTitle.Position = UDim2.fromOffset(10, 4)



		secTitle.BackgroundTransparency = 1



		secTitle.Font = UITheme.CONFIG.Font



		secTitle.Text = string.upper(title)



		secTitle.TextColor3 = UITheme.CONFIG.Colors.DescriptionGold



		secTitle.TextScaled = false



		secTitle.TextSize = 16



		secTitle.TextXAlignment = Enum.TextXAlignment.Left



		UITheme.applyTextStroke(secTitle, UITheme.CONFIG.TEXT_STROKE_SMALL, UITheme.CONFIG.Colors.Outline)



		secTitle.Parent = sec



		sec.Parent = scroll



		return sec



	end



	-- SECTION 1: CANDIDATE FONTS COMPARISON



	local secFonts = makeSection("1. Candidate Fonts (Pick One for UITheme.CONFIG.Font)", 130, 1)



	local fontList = {



		{ name = "FredokaOne (Default)", font = Enum.Font.FredokaOne },



		{ name = "LuckiestGuy", font = Enum.Font.LuckiestGuy },



		{ name = "GothamBlack", font = Enum.Font.GothamBlack },



	}



	for i, fInfo in ipairs(fontList) do



		local row = Instance.new("Frame")



		row.Size = UDim2.new(0.96, 0, 0, 28)



		row.Position = UDim2.new(0.02, 0, 0, 28 + (i - 1) * 32)



		row.BackgroundTransparency = 1



		row.Parent = secFonts



		local fLabel = Instance.new("TextLabel")



		fLabel.Size = UDim2.new(0.35, 0, 1, 0)



		fLabel.BackgroundTransparency = 1



		fLabel.Font = Enum.Font.GothamBold



		fLabel.TextColor3 = UITheme.CONFIG.Colors.White



		fLabel.TextSize = 13



		fLabel.TextXAlignment = Enum.TextXAlignment.Left



		fLabel.Text = fInfo.name .. ":"



		fLabel.Parent = row



		local fSample = Instance.new("TextLabel")



		fSample.Size = UDim2.new(0.65, 0, 1, 0)



		fSample.Position = UDim2.new(0.35, 0, 0, 0)



		fSample.BackgroundTransparency = 1



		fSample.Font = fInfo.font



		fSample.TextColor3 = UITheme.CONFIG.Colors.MoneyLime



		fSample.TextScaled = true



		fSample.Text = "CLAIM REWARDS • 500 BUX • STARTER PACK"



		UITheme.applyTextStroke(fSample, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



		fSample.Parent = row



	end



	-- SECTION 2: SCREEN HEADER GRADIENTS



	local secHeaders = makeSection("2. Seven Screen Header Gradients", 160, 2)



	local headerKeys = { "Shop", "Daily", "Group", "Playtime", "ChairSkins", "Titles", "DailyQuest" }



	local gridH = Instance.new("UIGridLayout")



	gridH.CellSize = UDim2.new(0.23, 0, 0, 48)



	gridH.CellPadding = UDim2.new(0.02, 0, 0, 10)



	gridH.HorizontalAlignment = Enum.HorizontalAlignment.Center



	gridH.Parent = secHeaders



	gridH.Position = UDim2.fromOffset(0, 32)



	local headerContainer = Instance.new("Frame")



	headerContainer.Size = UDim2.new(0.96, 0, 1, -36)



	headerContainer.Position = UDim2.fromOffset(12, 32)



	headerContainer.BackgroundTransparency = 1



	headerContainer.Parent = secHeaders



	gridH.Parent = headerContainer



	for _, hKey in ipairs(headerKeys) do



		local hData = UITheme.CONFIG.Headers[hKey]



		local hBox = Instance.new("Frame")



		hBox.Name = "Header_" .. hKey



		hBox.BackgroundColor3 = hData.Top



		UITheme.addCorner(hBox, UITheme.CONFIG.BUTTON_CORNER_RADIUS)



		UITheme.applyStroke(hBox, 2, UITheme.CONFIG.Colors.Outline)



		UITheme.applyGradient(hBox, hData.Top, hData.Bottom, 90)



		UITheme.studs(hBox, UITheme.CONFIG.STUDS_HEADER_TRANSPARENCY)



		local hLbl = Instance.new("TextLabel")



		hLbl.Size = UDim2.fromScale(1, 1)



		hLbl.BackgroundTransparency = 1



		hLbl.Font = UITheme.CONFIG.Font



		hLbl.Text = string.upper(hKey)



		hLbl.TextColor3 = UITheme.CONFIG.Colors.White



		hLbl.TextScaled = true



		UITheme.applyTextStroke(hLbl, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



		UITheme.addTextConstraint(hLbl, 11, 16)



		hLbl.Parent = hBox



		hBox.Parent = headerContainer



	end



	-- SECTION 3: BUTTON VARIANTS



	local secButtons = makeSection("3. Chunky Cartoon Button Variants (Hover / Press Enabled)", 150, 3)



	local btnVariants = { "lime", "gold", "blue", "gray", "purple", "brown", "red", "tabInactive" }



	local btnContainer = Instance.new("Frame")



	btnContainer.Size = UDim2.new(0.96, 0, 1, -36)



	btnContainer.Position = UDim2.fromOffset(12, 32)



	btnContainer.BackgroundTransparency = 1



	btnContainer.Parent = secButtons



	local gridB = Instance.new("UIGridLayout")



	gridB.CellSize = UDim2.new(0.23, 0, 0, 42)



	gridB.CellPadding = UDim2.new(0.02, 0, 0, 10)



	gridB.Parent = btnContainer



	for _, var in ipairs(btnVariants) do



		UITheme.button({



			text = var,



			variant = var,



			parent = btnContainer,



		})



	end



	-- SECTION 4: PRICE BUTTONS & PRICE BADGES



	local secPrices = makeSection("4. Price Button & Floating Price Badge (No Unicode Glyphs)", 110, 4)



	local pRow = Instance.new("Frame")



	pRow.Size = UDim2.new(0.96, 0, 0, 50)



	pRow.Position = UDim2.new(0.02, 0, 0, 36)



	pRow.BackgroundTransparency = 1



	pRow.Parent = secPrices



	local pList = Instance.new("UIListLayout")



	pList.FillDirection = Enum.FillDirection.Horizontal



	pList.HorizontalAlignment = Enum.HorizontalAlignment.Center



	pList.Padding = UDim.new(0, 30)



	pList.Parent = pRow



	-- Price Button 1 (Small)



	UITheme.priceButton(pRow, "250", UDim2.fromOffset(130, 40))



	-- Price Button 2 (Large)



	UITheme.priceButton(pRow, "1,499", UDim2.fromOffset(150, 40))



	-- Button with Floating Price Badge



	local testCardBtn = UITheme.button({



		text = "SPECIAL PACK",



		variant = "gold",



		size = UDim2.fromOffset(160, 40),



		parent = pRow,



	})



	UITheme.priceBadge(testCardBtn, "350")



	-- SECTION 5: RAINBOW TEXT & RIBBONS



	local secRainbow = makeSection("5. Rainbow Text Sequence & Angled Ribbons", 110, 5)



	local rRow = Instance.new("Frame")



	rRow.Size = UDim2.new(0.96, 0, 0, 56)



	rRow.Position = UDim2.new(0.02, 0, 0, 36)



	rRow.BackgroundTransparency = 1



	rRow.Parent = secRainbow



	local rList = Instance.new("UIListLayout")



	rList.FillDirection = Enum.FillDirection.Horizontal



	rList.HorizontalAlignment = Enum.HorizontalAlignment.SpaceAround



	rList.VerticalAlignment = Enum.VerticalAlignment.Center



	rList.Parent = rRow



	local rLabel1 = Instance.new("TextLabel")



	rLabel1.Size = UDim2.fromOffset(200, 36)



	rLabel1.BackgroundTransparency = 1



	rLabel1.Font = UITheme.CONFIG.Font



	rLabel1.Text = "STARTER PACK"



	rLabel1.TextScaled = true



	UITheme.rainbowText(rLabel1)



	rLabel1.Parent = rRow



	local rLabel2 = Instance.new("TextLabel")



	rLabel2.Size = UDim2.fromOffset(200, 36)



	rLabel2.BackgroundTransparency = 1



	rLabel2.Font = UITheme.CONFIG.Font



	rLabel2.Text = "MOST POPULAR!"



	rLabel2.TextScaled = true



	UITheme.rainbowText(rLabel2)



	rLabel2.Parent = rRow



	local ribbonCard = Instance.new("Frame")



	ribbonCard.Size = UDim2.fromOffset(120, 50)



	ribbonCard.BackgroundColor3 = UITheme.CONFIG.Colors.DarkPanel



	UITheme.addCorner(ribbonCard, UITheme.CONFIG.CARD_CORNER_RADIUS)



	UITheme.applyStroke(ribbonCard, 2, UITheme.CONFIG.Colors.Outline)



	UITheme.ribbon(ribbonCard, "BEST DEAL!", UITheme.CONFIG.Colors.CloseRedTop, -20)



	ribbonCard.Parent = rRow



	-- SECTION 6: PROGRESS BAR & TEXTURES



	local secProgress = makeSection("6. Progress Bar & Texture Previews", 130, 6)



	local progRow = Instance.new("Frame")



	progRow.Size = UDim2.new(0.96, 0, 0, 70)



	progRow.Position = UDim2.new(0.02, 0, 0, 36)



	progRow.BackgroundTransparency = 1



	progRow.Parent = secProgress



	local pCol1 = Instance.new("Frame")



	pCol1.Size = UDim2.new(0.48, 0, 1, 0)



	pCol1.BackgroundTransparency = 1



	pCol1.Parent = progRow



	local progLabel = Instance.new("TextLabel")



	progLabel.Size = UDim2.new(1, 0, 0, 20)



	progLabel.BackgroundTransparency = 1



	progLabel.Font = UITheme.CONFIG.Font



	progLabel.Text = "QUEST PROGRESS: 4 / 5"



	progLabel.TextColor3 = UITheme.CONFIG.Colors.White



	progLabel.TextSize = 14



	progLabel.TextXAlignment = Enum.TextXAlignment.Left



	UITheme.applyTextStroke(progLabel, UITheme.CONFIG.TEXT_STROKE_SMALL, UITheme.CONFIG.Colors.Outline)



	progLabel.Parent = pCol1



	local pBar = UITheme.progressBar(pCol1, 4, 5, UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 26))



	local pCol2 = Instance.new("Frame")



	pCol2.Size = UDim2.new(0.48, 0, 1, 0)



	pCol2.Position = UDim2.new(0.52, 0, 0, 0)



	pCol2.BackgroundTransparency = 1



	pCol2.Parent = progRow



	local textureDemo = Instance.new("Frame")



	textureDemo.Size = UDim2.new(1, 0, 0, 48)



	textureDemo.Position = UDim2.fromOffset(0, 6)



	textureDemo.BackgroundColor3 = UITheme.CONFIG.Colors.BlueTop



	UITheme.addCorner(textureDemo, UITheme.CONFIG.CARD_CORNER_RADIUS)



	UITheme.applyStroke(textureDemo, 2, UITheme.CONFIG.Colors.Outline)



	UITheme.studs(textureDemo, 0.82)



	UITheme.sunburst(textureDemo, UITheme.CONFIG.Colors.White, 0.65)



	local texLbl = Instance.new("TextLabel")



	texLbl.Size = UDim2.fromScale(1, 1)



	texLbl.BackgroundTransparency = 1



	texLbl.Font = UITheme.CONFIG.Font



	texLbl.Text = "STUDS + SUNBURST OVERLAY"



	texLbl.TextColor3 = UITheme.CONFIG.Colors.White



	texLbl.TextScaled = true



	texLbl.ZIndex = textureDemo.ZIndex + 2



	UITheme.applyTextStroke(texLbl, UITheme.CONFIG.TEXT_STROKE_MEDIUM, UITheme.CONFIG.Colors.Outline)



	UITheme.addTextConstraint(texLbl, 12, 18)



	texLbl.Parent = textureDemo



	textureDemo.Parent = pCol2



	-- SECTION 7: CLOSE BUTTONS COMPARISON (Magenta vs Red)



	local secClose = makeSection("7. Close Buttons (Magenta 'X' vs Red 'X')", 90, 7)



	local closeRow = Instance.new("Frame")



	closeRow.Size = UDim2.new(0.96, 0, 0, 46)



	closeRow.Position = UDim2.new(0.02, 0, 0, 32)



	closeRow.BackgroundTransparency = 1



	closeRow.Parent = secClose



	local cList = Instance.new("UIListLayout")



	cList.FillDirection = Enum.FillDirection.Horizontal



	cList.HorizontalAlignment = Enum.HorizontalAlignment.Center



	cList.Padding = UDim.new(0, 40)



	cList.Parent = closeRow



	local btnMag = UITheme.button({



		text = "X (MAGENTA)",



		variant = "magenta",



		size = UDim2.fromOffset(140, 36),



		parent = closeRow,



	})



	local btnRed = UITheme.button({



		text = "X (RED)",



		variant = "red",



		size = UDim2.fromOffset(140, 36),



		parent = closeRow,



	})



	screenGui.Parent = parentGui



	UITheme.openWindow(winData.Window)



	return screenGui



end



return UITheme




# scratch/apply_do_block.py
import re
import json

with open("scratch/apply_hud_revision.py", "r", encoding="utf-8") as f:
    text = f.read()

# Replace with the do ... end version
do_hud_code = """-- Top-Left Currency & Friends Boost HUD (Modern Cartoon Style)
local friendsLabel: TextLabel
local btnAddFriend: TextButton
local cashPill: Frame
local cashIconImg: ImageLabel
local cashLabel: TextLabel
local btnAddCash: TextButton
local updateCashDisplay: (targetBux: number) -> ()
local updateFriendsDisplay: (targetBoost: number) -> ()

do
	local currencyGroup = Instance.new("Frame")
	currencyGroup.Name = "CurrencyGroup"
	currencyGroup.Size = UDim2.new(0.24, 0, 0.11, 0)
	currencyGroup.Position = UDim2.new(0.012, 0, 0.014, 0)
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
	btnAddFriend = Instance.new("TextButton")
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
	cashPill = Instance.new("Frame")
	cashPill.Name = "CashPill"
	cashPill.Size = UDim2.new(1, 0, 0.52, 0)
	cashPill.Position = UDim2.new(0, 0, 0.48, 0)
	cashPill.BackgroundTransparency = 1
	cashPill.ZIndex = 16
	cashPill.Parent = currencyGroup

	cashIconImg = Instance.new("ImageLabel")
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
	end

	friendsLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateLayoutPositions)
	cashLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateLayoutPositions)
	currencyGroup:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayoutPositions)

	cashLabel:GetPropertyChangedSignal("Text"):Connect(function()
		if cashShadow and cashShadow.Text ~= cashLabel.Text then
			cashShadow.Text = cashLabel.Text
		end
		updateLayoutPositions()
	end)

	friendsLabel:GetPropertyChangedSignal("Text"):Connect(function()
		updateLayoutPositions()
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

		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isPressed = true
				TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.92 }):Play()
			end
		end)

		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isPressed = false
				local targetScale = if isHovered then 1.1 else 1.0
				TweenService:Create(scale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = targetScale }):Play()
			end
		end)
	end

	setupHudButtonAnim(btnAddFriend)
	setupHudButtonAnim(btnAddCash)

	-- Diagonal Shine Sweep Animation (every 4 seconds)
	local function setupShineSweep(btn: TextButton)
		local shineOverlay = Instance.new("Frame")
		shineOverlay.Name = "ShineOverlay"
		shineOverlay.Size = UDim2.fromScale(1, 1)
		shineOverlay.BackgroundTransparency = 1
		shineOverlay.ClipsDescendants = true
		shineOverlay.ZIndex = btn.ZIndex + 3
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = shineOverlay

		local shineBar = Instance.new("Frame")
		shineBar.Name = "ShineBar"
		shineBar.Size = UDim2.fromScale(1, 1)
		shineBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		shineBar.BorderSizePixel = 0
		shineBar.ZIndex = shineOverlay.ZIndex

		local grad = Instance.new("UIGradient")
		grad.Rotation = -45
		grad.Offset = Vector2.new(-1, 0)
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 1),
			NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(0.65, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = shineBar
		shineBar.Parent = shineOverlay
		shineOverlay.Parent = btn

		task.spawn(function()
			while btn.Parent do
				task.wait(4.0)
				if not btn.Parent then break end
				grad.Offset = Vector2.new(-1, 0)
				local tw = TweenService:Create(grad, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Offset = Vector2.new(1, 0)
				})
				tw:Play()
				tw.Completed:Wait()
				grad.Offset = Vector2.new(-1, 0)
			end
		end)
	end

	setupShineSweep(btnAddFriend)
	setupShineSweep(btnAddCash)

	-- Value Pop & Count-Up Tween Animations
	local lastObservedCash: number? = nil
	local lastObservedBoost: number? = nil

	local function popCashText()
		cashScale.Scale = 1.0
		local twPop = TweenService:Create(cashScale, TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.15 })
		twPop:Play()
		twPop.Completed:Connect(function()
			TweenService:Create(cashScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
		end)
		local origColor = cashLabel.TextColor3
		cashLabel.TextColor3 = Color3.fromRGB(220, 255, 180)
		task.delay(0.12, function()
			if cashLabel then cashLabel.TextColor3 = origColor end
		end)
	end

	local function popFriendsText()
		friendsScale.Scale = 1.0
		local twPop = TweenService:Create(friendsScale, TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.15 })
		twPop:Play()
		twPop.Completed:Connect(function()
			TweenService:Create(friendsScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
		end)
		local origColor = friendsLabel.TextColor3
		friendsLabel.TextColor3 = Color3.fromRGB(255, 255, 180)
		task.delay(0.12, function()
			if friendsLabel then friendsLabel.TextColor3 = origColor end
		end)
	end

	local activeCashTweenVal: NumberValue? = nil
	function updateCashDisplay(targetBux: number)
		if lastObservedCash == nil then
			lastObservedCash = targetBux
			cashLabel.Text = `$` .. tostring(targetBux)
			if cashShadow then cashShadow.Text = cashLabel.Text end
			updateLayoutPositions()
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
				updateLayoutPositions()
			end)
			tw:Play()
			tw.Completed:Connect(function()
				cashLabel.Text = `$` .. tostring(targetBux)
				if cashShadow then cashShadow.Text = cashLabel.Text end
				updateLayoutPositions()
				valObj:Destroy()
				if activeCashTweenVal == valObj then
					activeCashTweenVal = nil
				end
			end)
		end
	end

	function updateFriendsDisplay(targetBoost: number)
		if lastObservedBoost == nil then
			lastObservedBoost = targetBoost
			friendsLabel.Text = `FRIENDS BOOST: +{targetBoost}%`
			updateLayoutPositions()
			return
		end

		if lastObservedBoost ~= targetBoost then
			lastObservedBoost = targetBoost
			popFriendsText()
			friendsLabel.Text = `FRIENDS BOOST: +{targetBoost}%`
			updateLayoutPositions()
		end
	end
end
"""

# Update workspace file
ws_file = "src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau"
with open(ws_file, "r", encoding="utf-8") as f:
    ws_content = f.read()

pattern_replace = re.compile(
    r"-- Top-Left Currency & Friends Boost HUD \(Modern Cartoon Style\).*?"
    r"end\s*\nend\s*\n",
    re.DOTALL
)

if pattern_replace.search(ws_content):
    ws_updated = pattern_replace.sub(lambda m: do_hud_code + "\n", ws_content, count=1)
    with open(ws_file, "w", encoding="utf-8") as f:
        f.write(ws_updated)
    print("Workspace file updated with do ... end structure!")
else:
    print("WARNING: Pattern not matched in workspace file!")

with open("scratch/do_hud_code.txt", "w", encoding="utf-8") as f:
    f.write(do_hud_code)

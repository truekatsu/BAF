--!strict

--[[

	MatchClient

	Responsibility: Responsive Lobby HUD + Modals (FREE: Daily/Group/Playtime, Quests, Skins, Titles, Shop) and Match UI (Waiting, Build 6-slot, FIFA Card preview, Showdown reveal, Result & Victory popup).

	Loop step: action | reward | reinvestment | progression

	Location: StarterPlayer/StarterPlayerScripts/Client/MatchClient (LocalScript)

]]

local Lighting = game:GetService("Lighting")

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local SocialService = game:GetService("SocialService")

local SoundService = game:GetService("SoundService")

local TweenService = game:GetService("TweenService")

local UserInputService = game:GetService("UserInputService")

local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Footballers = require(Shared:WaitForChild("Footballers"))

local FootballerModelBuilder = require(Shared:WaitForChild("FootballerModelBuilder"))

local Remotes = require(Shared:WaitForChild("Remotes"))

local UITheme = require(Shared:WaitForChild("UITheme"))

local VoteConfig = require(Shared:WaitForChild("VoteConfig"))

local ShopDailyUI = require(script.Parent:WaitForChild("ShopDailyUI"))
local WheelUI = require(script.Parent:WaitForChild("WheelUI"))

local DAILY_COOLDOWN_SEC = 86400

-- Built-in Engine SFX & UI Tween Helpers

local playSfx: (kind: string) -> ()

do

	local sfxFolder = Instance.new("Folder")

	sfxFolder.Name = "BAF_SFX"

	sfxFolder.Parent = SoundService

	local function createSound(name: string, soundId: string, speed: number, vol: number): Sound

		local s = Instance.new("Sound")

		s.Name = name

		s.SoundId = soundId

		s.PlaybackSpeed = speed

		s.Volume = vol

		s.Parent = sfxFolder

		return s

	end

	local sfxMap: { [string]: Sound } = {

		click = createSound("Click", "rbxasset://sounds/button.wav", 1.25, 0.45),

		roll = createSound("Roll", "rbxasset://sounds/swoosh.wav", 1.15, 0.55),

		rare = createSound("Rare", "rbxasset://sounds/electronicpingshort.wav", 1.45, 0.7),

		reveal = createSound("Reveal", "rbxasset://sounds/electronicpingshort.wav", 1.05, 0.6),

		win = createSound("Win", "rbxasset://sounds/electronicpingshort.wav", 1.65, 0.8),

		lose = createSound("Lose", "rbxasset://sounds/swoosh.wav", 0.65, 0.65),

	}

	function playSfx(kind: string)

		local s = sfxMap[kind]

		if s then

			SoundService:PlayLocalSound(s)

		end

	end

end

-- Phase-adaptive Background Music (Lobby Samba/Brass, Build Liquid DnB, Showdown Stadium Drumline)

local setBgmPhase: (phase: string) -> ()

do

local function createBgm(name: string, soundId: string): Sound

	local s = Instance.new("Sound")

	s.Name = name

	s.SoundId = soundId

	s.Volume = 0

	s.Looped = true

	s.Parent = sfxFolder

	return s

end

local bgmTracks: { [string]: { sound: Sound, targetVol: number } } = {

	lobby = { sound = createBgm("BGM_Lobby", "rbxassetid://1838601519"), targetVol = 0.11 }, -- Samba E Futebol (Perc & Brass)

	build = { sound = createBgm("BGM_Build", "rbxassetid://103016391217295"), targetVol = 0.11 }, -- Stellar Drift (Liquid Drum & Bass)

	showdown = { sound = createBgm("BGM_Showdown", "rbxassetid://1846418124"), targetVol = 0.125 }, -- Swagger March B (Stadium Drumline)

}

local activeBgmKey = ""

function setBgmPhase(phase: string)

	local targetKey = if phase == "Idle"

		then "lobby"

		elseif phase == "Showdown" or phase == "Result" then "showdown"

		else "build"

	if activeBgmKey == targetKey then

		return

	end

	activeBgmKey = targetKey

	for key, entry in bgmTracks do

		if key == targetKey then

			if not entry.sound.IsPlaying then

				entry.sound.TimePosition = 0

				pcall(function()

					entry.sound:Play()

				end)

			end

			TweenService:Create(entry.sound, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {

				Volume = entry.targetVol,

			}):Play()

		else

			local tw = TweenService:Create(entry.sound, TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {

				Volume = 0,

			})

			tw:Play()

			tw.Completed:Connect(function()

				if activeBgmKey ~= key and entry.sound.Volume <= 0.01 then

					entry.sound:Stop()

				end

			end)

		end

	end

end

task.defer(setBgmPhase, "Idle")

end

local function popGui(guiObj: GuiObject, startScale: number?)

	local sc = guiObj:FindFirstChildOfClass("UIScale")

	if not sc then

		sc = Instance.new("UIScale")

		sc.Parent = guiObj

	end

	(sc :: UIScale).Scale = startScale or 0.84

	TweenService:Create(sc :: UIScale, TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

		Scale = 1,

	}):Play()

end

local setMatchBlur: (enabled: boolean) -> ()

do

local matchBlur = Lighting:FindFirstChild("BAF_MatchBlur") :: BlurEffect?

if not matchBlur then

	local b = Instance.new("BlurEffect")

	b.Name = "BAF_MatchBlur"

	b.Size = 0

	b.Parent = Lighting

	matchBlur = b

end

function setMatchBlur(enabled: boolean)

	if matchBlur then

		TweenService:Create(matchBlur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {

			Size = if enabled then 24 else 0,

		}):Play()

	end

end

end

local lastCamTableCF: CFrame? = nil

local function focusTableCamera(tablePos: Vector3?, mode: "Idle" | "Build" | "Showdown" | "Result")

	local cam = Workspace.CurrentCamera

	if not cam then

		return

	end

	if mode == "Idle" then

		lastCamTableCF = nil

		cam.CameraType = Enum.CameraType.Custom

		local hum = if localPlayer.Character then localPlayer.Character:FindFirstChildOfClass("Humanoid") else nil

		if hum then

			cam.CameraSubject = hum

		end

		return

	end

	local center = tablePos

	local tableCF: CFrame? = nil

	local char = localPlayer.Character

	local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil

	local seat = if hum then hum.SeatPart else nil

	if seat and seat.Parent and seat.Parent:IsA("Model") then

		tableCF = seat.Parent:GetPivot()

	elseif center then

		tableCF = CFrame.new(center + Vector3.new(0, 2.8, 0))

	else

		tableCF = lastCamTableCF

	end

	if not tableCF then

		return

	end

	lastCamTableCF = tableCF

	cam.CameraType = Enum.CameraType.Scriptable

	-- Side camera: player on the left, opponent on the right

	local isSeatB = seat ~= nil and seat.Name == "SeatB"

	local sideX = if isSeatB then -1 else 1

	local distX = if mode == "Showdown" then 7.8 elseif mode == "Result" then 8.4 else 8.8

	local eyePos = (tableCF * CFrame.new(sideX * distX, 2.7, 0)).Position

	local lookPos = (tableCF * CFrame.new(0, 0.4, 0)).Position

	local targetCF = CFrame.lookAt(eyePos, lookPos)

	TweenService:Create(cam, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {

		CFrame = targetCF,

	}):Play()

end

-- UI Construction Helpers

local function addCorner(parent: Instance, radius: number)

	local c = Instance.new("UICorner")

	c.CornerRadius = UDim.new(0, radius)

	c.Parent = parent

end

local function addStroke(parent: Instance, color: Color3, thickness: number)

	local s = Instance.new("UIStroke")

	s.Color = color

	s.Thickness = thickness

	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	s.Parent = parent

end

local function makeLabel(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3?): TextLabel

	local lbl = Instance.new("TextLabel")

	lbl.Size = size

	lbl.Position = pos

	lbl.BackgroundTransparency = 1

	lbl.Font = UITheme.Fonts.Primary

	lbl.TextColor3 = color or UITheme.Colors.White

	lbl.TextStrokeTransparency = 0

	lbl.TextStrokeColor3 = UITheme.Colors.Black

	lbl.TextScaled = true

	lbl.Text = text

	local sc = Instance.new("UITextSizeConstraint")

	sc.MinTextSize = 10

	sc.MaxTextSize = 42

	sc.Parent = lbl

	lbl.Parent = parent

	return lbl

end

local function makeButton(parent: Instance, text: string, size: UDim2, pos: UDim2, bg: Color3): TextButton

	local btn = Instance.new("TextButton")

	btn.Size = size

	btn.Position = pos

	btn.BackgroundColor3 = bg

	btn.Font = UITheme.Fonts.Primary

	btn.TextColor3 = UITheme.Colors.White

	btn.TextStrokeTransparency = 0

	btn.TextStrokeColor3 = UITheme.Colors.Black

	btn.TextScaled = true

	btn.AutoButtonColor = false

	btn.Text = text

	UITheme.addCorner(btn, 8)

	UITheme.applyStroke(btn, 3, UITheme.Colors.Black)

	UITheme.addBevel(btn, 8)

	UITheme.setupButtonHover(btn)

	local sc = Instance.new("UITextSizeConstraint")

	sc.MinTextSize = 10

	sc.MaxTextSize = 36

	sc.Parent = btn

	btn.Parent = parent

	btn.Activated:Connect(function()

		playSfx("click")

		popGui(btn, 0.93)

	end)

	return btn

end

local function formatMMSS(totalSec: number): string

	local sec = math.max(0, math.floor(totalSec))

	local m = math.floor(sec / 60)

	local s = sec % 60

	return string.format("%d:%02d", m, s)

end

local function formatHHMMSS(totalSec: number): string

	local sec = math.max(0, math.ceil(totalSec))

	local h = math.floor(sec / 3600)

	local m = math.floor((sec % 3600) / 60)

	local s = sec % 60

	return string.format("%02d:%02d:%02d", h, m, s)

end

-- Root ScreenGui

do

	local oldGui = playerGui:FindFirstChild("BAF_MainUI")

	if oldGui then

		oldGui:Destroy()

	end

end

local screenGui = Instance.new("ScreenGui")

screenGui.Name = "BAF_MainUI"

screenGui.ResetOnSpawn = false

screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

screenGui.DisplayOrder = 50

screenGui.IgnoreGuiInset = false

screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets

screenGui.Parent = playerGui

-- ============================================================

-- 1. LOBBY HUD & RETENTION MODALS

-- ============================================================

local lobbyHud = Instance.new("Frame")
lobbyHud.Name = "LobbyHUD"
lobbyHud.Size = UDim2.fromScale(1, 1)
lobbyHud.BackgroundTransparency = 1
lobbyHud.ZIndex = 1
lobbyHud.Parent = screenGui

-- Toast Notification Banner (parented to screenGui so it is visible in both Lobby and Match)

local showToast: (msg: string) -> ()

do

local toastBanner = makeLabel(screenGui, "", UDim2.new(0.44, 0, 0, 38), UDim2.new(0.28, 0, 0, 68), Color3.fromHex("#FFD21F"))

toastBanner.BackgroundTransparency = 0.15

toastBanner.BackgroundColor3 = GameConfig.UI_COLORS.PanelDark

toastBanner.ZIndex = 30

toastBanner.Visible = false

addCorner(toastBanner, 10)

addStroke(toastBanner, Color3.fromHex("#FFD21F"), 2)

local toastToken = 0

function showToast(msg: string)

	toastToken += 1

	local myToken = toastToken

	toastBanner.Text = msg

	toastBanner.Visible = true

	playSfx("rare")

	popGui(toastBanner, 0.88)

	task.delay(3, function()

		if toastToken == myToken then

			toastBanner.Visible = false

		end

	end)

end

end

-- Top-Right Container for Daily Rewards & Quests (parented to lobbyHud so it hides during ingame match phases)
local btnTopDaily: ImageButton
local btnTopQuests: ImageButton
local questBadge: TextLabel
do
	local topRightBar = Instance.new("Frame")
	topRightBar.Name = "TopRightBar"
	topRightBar.Size = UDim2.fromScale(1, 1)
	topRightBar.Position = UDim2.fromScale(0.99, 0.02)
	topRightBar.AnchorPoint = Vector2.new(1, 0)
	topRightBar.BackgroundTransparency = 1
	topRightBar.Active = false
	topRightBar.ZIndex = 20
	topRightBar.Parent = lobbyHud

	local topRightLayout = Instance.new("UIListLayout")
	topRightLayout.FillDirection = Enum.FillDirection.Horizontal
	topRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	topRightLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	topRightLayout.Padding = UDim.new(0.008, 0)
	topRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topRightLayout.Parent = topRightBar

	local function makeTopButton(name: string, imageId: string, size: UDim2, layoutOrder: number): ImageButton
		local btn = Instance.new("ImageButton")
		btn.Name = name
		btn.Size = size
		btn.BackgroundTransparency = 1
		btn.Image = imageId
		btn.ScaleType = Enum.ScaleType.Fit
		btn.LayoutOrder = layoutOrder
		btn.ZIndex = 20
		btn.Parent = topRightBar

		btn.Activated:Connect(function()
			playSfx("click")
		end)

		return btn
	end

	btnTopDaily = makeTopButton("BtnTopDaily", UITheme.Assets.BtnDaily, UDim2.fromScale(0.1, 0.06), 1)
	btnTopQuests = makeTopButton("BtnTopQuests", UITheme.Assets.BtnQuests, UDim2.fromScale(0.1, 0.06), 2)

	questBadge = Instance.new("TextLabel")
	questBadge.Size = UDim2.fromScale(0.24, 0.65)
	questBadge.Position = UDim2.fromScale(0.94, 0.12)
	questBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	questBadge.BackgroundTransparency = 0
	questBadge.BackgroundColor3 = Color3.fromHex("#E5252A")
	questBadge.Font = UITheme.Fonts.Primary
	questBadge.TextColor3 = Color3.new(1, 1, 1)
	questBadge.TextStrokeTransparency = 0
	questBadge.TextStrokeColor3 = UITheme.Colors.Black
	questBadge.TextWrapped = false
	questBadge.TextScaled = true
	questBadge.Text = "0"
	questBadge.ZIndex = 25
	questBadge.Visible = false
	questBadge.Parent = btnTopQuests

	local qbAspect = Instance.new("UIAspectRatioConstraint")
	qbAspect.AspectRatio = 1.0
	qbAspect.DominantAxis = Enum.DominantAxis.Height
	qbAspect.Parent = questBadge

	local qbTextConstraint = Instance.new("UITextSizeConstraint")
	qbTextConstraint.MinTextSize = 6
	qbTextConstraint.MaxTextSize = 14
	qbTextConstraint.Parent = questBadge

	local qbCorner = Instance.new("UICorner")
	qbCorner.CornerRadius = UDim.new(0.5, 0)
	qbCorner.Parent = questBadge

	UITheme.applyStroke(questBadge, 1.5, UITheme.Colors.Black)
end

-- Left Nav Group (FREE, SHOP, SKINS, TITLES, INDEX, PROFILE in 1 straight vertical column)
local leftNavGroup = Instance.new("Frame")
leftNavGroup.Name = "LeftNavGroup"
leftNavGroup.AnchorPoint = Vector2.new(0, 0)
leftNavGroup.Position = UDim2.new(0.01, 0, 0.02, 58)
leftNavGroup.Size = UDim2.new(0.12, 0, 0.56, 0)
leftNavGroup.BackgroundTransparency = 1
leftNavGroup.ZIndex = 15
leftNavGroup.Parent = lobbyHud

local leftNavLayout = Instance.new("UIListLayout")
leftNavLayout.Name = "UIListLayout"
leftNavLayout.FillDirection = Enum.FillDirection.Vertical
leftNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
leftNavLayout.VerticalAlignment = Enum.VerticalAlignment.Top
leftNavLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftNavLayout.Padding = UDim.new(0.010, 0)
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
		btn.Size = UDim2.new(1, 0, 0.15, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 16
		btn.Parent = leftNavGroup

		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1.0
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = btn

		local btnSizeConstraint = Instance.new("UISizeConstraint")
		btnSizeConstraint.MinSize = Vector2.new(31, 31)
		btnSizeConstraint.Parent = btn

		local textConstraint = Instance.new("UITextSizeConstraint")
		textConstraint.MinTextSize = 9
		textConstraint.MaxTextSize = 22
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

	btnNavFree = makeNavButton("BtnNavFree", UITheme.Assets.NavFreeIcon, 1, 557 / 444, 557 / 449, 277.5 / 557, 266.0 / 557)
	btnNavShop = makeNavButton("BtnNavShop", UITheme.Assets.NavShopIcon, 2, 557 / 496, 557 / 506, 278.5 / 557, 282.5 / 557)
	btnNavSkins = makeNavButton("BtnNavSkins", UITheme.Assets.NavSkinsIcon, 3, 557 / 477, 557 / 489, 278.0 / 557, 284.0 / 557)
	btnNavTitles = makeNavButton("BtnNavTitles", UITheme.Assets.NavTitlesIcon, 4, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
	btnNavIndex = makeNavButton("BtnNavIndex", UITheme.Assets.NavIndexIcon, 5, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
	btnNavProfile = makeNavButton("BtnNavProfile", UITheme.Assets.NavProfileIcon, 6, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)

	-- Free Badge attached to top-right of BtnNavFree
	freeBadge = makeLabel(btnNavFree, "1", UDim2.new(0.40, 0, 0.40, 0), UDim2.new(1, 0, 0, 0), Color3.new(1, 1, 1))
	freeBadge.AnchorPoint = Vector2.new(1, 0)
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
-- Right Side: Starter Pack, 2X WIN, 2X, INF REROLLS stacked with UIListLayout
local rightPromoGroup = Instance.new("Frame")
rightPromoGroup.Name = "RightPromoGroup"
rightPromoGroup.AnchorPoint = Vector2.new(1, 0)
rightPromoGroup.Position = UDim2.new(0.99, 0, 0.37, 0)
rightPromoGroup.Size = UDim2.new(0.14, 0, 0.34, 0)
rightPromoGroup.BackgroundTransparency = 1
rightPromoGroup.ZIndex = 15
rightPromoGroup.Parent = lobbyHud

local rightPromoLayout = Instance.new("UIListLayout")
rightPromoLayout.Name = "UIListLayout"
rightPromoLayout.FillDirection = Enum.FillDirection.Vertical
rightPromoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightPromoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rightPromoLayout.Padding = UDim.new(0.14, 0)
rightPromoLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightPromoLayout.Parent = rightPromoGroup

local function createFloatingOfferSlot(parent: GuiObject, order: number, initialOfferIndex: number): FloatingOfferSlot
	local container = Instance.new("ImageButton")
	container.Name = "FloatingOfferSlot"
	container.Size = UDim2.new(1, 0, 0.41, 0)
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
	icon.ZIndex = container.ZIndex + 5
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
	pillBadge.Position = UDim2.new(0.5, 0, 0.06, 0)
	pillBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	pillBadge.BackgroundColor3 = Color3.fromHex("#48C90E")
	pillBadge.ClipsDescendants = true
	pillBadge.ZIndex = container.ZIndex + 2
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
	titleLbl.Size = UDim2.new(1.1, 0, 0.28, 0)
	titleLbl.Position = UDim2.new(0.5, 0, 0.98, 0)
	titleLbl.AnchorPoint = Vector2.new(0.5, 1)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = UITheme.Fonts.Primary
	titleLbl.TextColor3 = UITheme.Colors.White
	titleLbl.Text = "STARTER\nPACK"
	titleLbl.TextScaled = true
	titleLbl.ZIndex = container.ZIndex + 6
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
-- Top-Left Currency & Friends Boost HUD (Modern Cartoon Style)
local HUD: { [string]: any } = {}
local friendsLabel: TextLabel
local cashLabel: TextLabel
local btnAddCash: TextButton

do
	local currencyGroup = Instance.new("Frame")
	currencyGroup.Name = "CurrencyGroup"
	currencyGroup.Size = UDim2.new(0.20, 0, 0.15, 0)
	currencyGroup.AnchorPoint = Vector2.new(0, 1)
	currencyGroup.Position = UDim2.new(0.01, 0, 0.98, 0)
	currencyGroup.BackgroundTransparency = 1
	currencyGroup.ZIndex = 15
	currencyGroup.Parent = lobbyHud

	local curScale = Instance.new("UIScale")
	curScale.Scale = 0.75
	curScale.Parent = currencyGroup

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
	friendsSizeConstraint.MinTextSize = 6
	friendsSizeConstraint.MaxTextSize = 22
	friendsSizeConstraint.Parent = friendsLabel

	local friendsGradient = Instance.new("UIGradient")
	friendsGradient.Color = ColorSequence.new(Color3.fromRGB(255, 235, 80), Color3.fromRGB(255, 180, 0))
	friendsGradient.Rotation = 90
	friendsGradient.Parent = friendsLabel

	local friendsStroke = Instance.new("UIStroke")
	friendsStroke.Thickness = 2.5
	friendsStroke.Color = Color3.fromRGB(70, 40, 0)
	friendsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	friendsStroke.LineJoinMode = Enum.LineJoinMode.Round
	friendsStroke.Parent = friendsLabel

	friendsLabel.Parent = rowFriends

	-- Yellow Plus Button (next to Friends Boost)
	local btnAddFriend = Instance.new("TextButton")
	btnAddFriend.Name = "BtnAddFriend"
	btnAddFriend.LayoutOrder = 2
	btnAddFriend.Size = UDim2.new(0.2, 0, 0.85, 0)
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
	friendBtnStroke.Thickness = 2.5
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
	cashIconImg.Size = UDim2.new(1, 0, 0.85, 0)
	cashIconImg.BackgroundTransparency = 1
	cashIconImg.Image = UITheme.Assets.CashStack
	cashIconImg.ScaleType = Enum.ScaleType.Fit
	cashIconImg.ZIndex = cashPill.ZIndex + 2

	local cashIconAspect = Instance.new("UIAspectRatioConstraint")
	cashIconAspect.AspectRatio = 1.0
	cashIconAspect.DominantAxis = Enum.DominantAxis.Height
	cashIconAspect.Parent = cashIconImg

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
	cashSizeConstraint.MinTextSize = 8
	cashSizeConstraint.MaxTextSize = 32
	cashSizeConstraint.Parent = cashLabel

	local cashGradient = Instance.new("UIGradient")
	cashGradient.Color = ColorSequence.new(Color3.fromRGB(170, 255, 60), Color3.fromRGB(60, 210, 0))
	cashGradient.Rotation = 90
	cashGradient.Parent = cashLabel

	local cashStroke = Instance.new("UIStroke")
	cashStroke.Thickness = 3
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
	cashSizeConstraint:Clone().Parent = cashShadow
	cashShadow.Parent = cashLabel

	cashLabel.Parent = cashPill

	-- Green Plus Button (next to money)
	btnAddCash = Instance.new("TextButton")
	btnAddCash.Name = "BtnAddCash"
	btnAddCash.LayoutOrder = 3
	btnAddCash.Size = UDim2.new(1, 0, 0.75, 0)
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
-- Opponent Needed Notification Banner (3s wait broadcast to idle players)

local activeAlertTableId: string? = nil

local opponentAlertBanner = Instance.new("Frame")

opponentAlertBanner.Name = "OpponentAlertBanner"

opponentAlertBanner.Size = UDim2.fromOffset(416, 92)

opponentAlertBanner.AnchorPoint = Vector2.new(0.5, 0)

opponentAlertBanner.Position = UDim2.new(0.5, 0, 1, -108)

opponentAlertBanner.BackgroundColor3 = UITheme.Colors.CardDark

opponentAlertBanner.ClipsDescendants = true

opponentAlertBanner.ZIndex = 28

opponentAlertBanner.Visible = false

UITheme.addCorner(opponentAlertBanner, 8)

UITheme.applyStroke(opponentAlertBanner, 3.5, UITheme.Colors.Black)

UITheme.addStuds(opponentAlertBanner, 0.88, 20)

UITheme.addBevel(opponentAlertBanner, 8)

opponentAlertBanner.Parent = lobbyHud

local alertAvatarImg = Instance.new("ImageLabel")

alertAvatarImg.Name = "HostAvatar"

alertAvatarImg.Size = UDim2.fromOffset(80, 80)

alertAvatarImg.Position = UDim2.fromOffset(8, 6)

alertAvatarImg.BackgroundTransparency = 1

alertAvatarImg.ZIndex = 29

alertAvatarImg.Parent = opponentAlertBanner

local alertTitleLbl = makeLabel(opponentAlertBanner, "Player needs an opponent...", UDim2.new(1, -104, 0, 30), UDim2.fromOffset(96, 6), UITheme.Colors.White)

alertTitleLbl.Name = "AlertTitle"

alertTitleLbl.ZIndex = 29

local btnAlertJoin = Instance.new("TextButton")

btnAlertJoin.Name = "JoinBtn"

btnAlertJoin.Size = UDim2.fromOffset(148, 44)

btnAlertJoin.Position = UDim2.fromOffset(98, 40)

btnAlertJoin.BackgroundColor3 = UITheme.Colors.LimeTop

btnAlertJoin.Font = UITheme.Fonts.Primary

btnAlertJoin.TextColor3 = UITheme.Colors.White

btnAlertJoin.TextStrokeTransparency = 0

btnAlertJoin.TextScaled = true

btnAlertJoin.Text = "Join"

btnAlertJoin.ZIndex = 29

UITheme.styleButton(btnAlertJoin, "Lime", 6)

btnAlertJoin.Parent = opponentAlertBanner

local btnAlertDismiss = Instance.new("TextButton")

btnAlertDismiss.Name = "DismissBtn"

btnAlertDismiss.Size = UDim2.fromOffset(148, 44)

btnAlertDismiss.Position = UDim2.fromOffset(256, 40)

btnAlertDismiss.BackgroundColor3 = UITheme.Colors.RedTop

btnAlertDismiss.Font = UITheme.Fonts.Primary

btnAlertDismiss.TextColor3 = UITheme.Colors.White

btnAlertDismiss.TextStrokeTransparency = 0

btnAlertDismiss.TextScaled = true

btnAlertDismiss.Text = "Dismiss"

btnAlertDismiss.ZIndex = 29

UITheme.styleButton(btnAlertDismiss, "Red", 6)

btnAlertDismiss.Parent = opponentAlertBanner

btnAlertJoin.Activated:Connect(function()

	playSfx("click")

	local targetId = activeAlertTableId

	opponentAlertBanner.Visible = false

	activeAlertTableId = nil

	if targetId then

		Remotes.MatchAction:FireServer("JoinWaitingTable", targetId)

	end

end)

btnAlertDismiss.Activated:Connect(function()

	playSfx("click")

	opponentAlertBanner.Visible = false

	activeAlertTableId = nil

end)

-- Central Modal Window (parented to screenGui so Top-Right pills work at any time)

local modalBackdrop = Instance.new("TextButton")

modalBackdrop.Name = "ModalBackdrop"

modalBackdrop.Size = UDim2.fromScale(1, 1)

modalBackdrop.Position = UDim2.fromScale(0, 0)

modalBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)

modalBackdrop.BackgroundTransparency = 1.0

modalBackdrop.BorderSizePixel = 0

modalBackdrop.ZIndex = 24

modalBackdrop.AutoButtonColor = false

modalBackdrop.Text = ""

modalBackdrop.Visible = false

modalBackdrop.Parent = screenGui

local modalWrap = Instance.new("Frame")
modalWrap.Name = "ModalWrap"
modalWrap.Size = UDim2.fromOffset(760, 480)
modalWrap.AnchorPoint = Vector2.new(0.5, 0.5)
modalWrap.Position = UDim2.fromScale(0.5, 0.5)
modalWrap.BackgroundTransparency = 1
modalWrap.ZIndex = 25
modalWrap.Visible = false
modalWrap.Parent = screenGui

do
	local modalWrapScale = Instance.new("UIScale")
	modalWrapScale.Scale = UITheme.getModalScale()
	modalWrapScale.Parent = modalWrap

	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if modalWrap.Visible then
				modalWrapScale.Scale = UITheme.getModalScale()
			end
		end)
	end
end

local modalBox = Instance.new("Frame")

modalBox.Name = "ModalBox"

modalBox.Size = UDim2.fromScale(1, 1)

modalBox.BackgroundColor3 = Color3.fromHex("#10111A")

modalBox.BackgroundTransparency = 0.08

UITheme.addCorner(modalBox, UITheme.CONFIG.WINDOW_CORNER_RADIUS)

UITheme.applyStroke(modalBox, UITheme.CONFIG.WINDOW_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)

UITheme.studs(modalBox, UITheme.CONFIG.STUDS_PANEL_TRANSPARENCY)

UITheme.addShadow(modalBox, 14, 6)

modalBox.Parent = modalWrap

local modalHeader = Instance.new("Frame")

modalHeader.Name = "ModalHeader"

modalHeader.Size = UDim2.new(1, 0, 0, 74)

modalHeader.BackgroundColor3 = UITheme.CONFIG.Headers.Daily.Top

UITheme.applyGradient(modalHeader, UITheme.CONFIG.Headers.Daily.Top, UITheme.CONFIG.Headers.Daily.Bottom, 90)

UITheme.studs(modalHeader, UITheme.CONFIG.STUDS_HEADER_TRANSPARENCY)

modalHeader.Parent = modalBox

local modalHeaderBorder = Instance.new("Frame")

modalHeaderBorder.Name = "HeaderBottomBorder"

modalHeaderBorder.Size = UDim2.new(1, 0, 0, 4)

modalHeaderBorder.Position = UDim2.new(0, 0, 1, -4)

modalHeaderBorder.BackgroundColor3 = UITheme.CONFIG.Colors.Outline

modalHeaderBorder.BorderSizePixel = 0

modalHeaderBorder.ZIndex = modalHeader.ZIndex + 2

modalHeaderBorder.Parent = modalHeader

local modalTitle = Instance.new("TextLabel")

modalTitle.Name = "HeaderTitle"

modalTitle.Size = UDim2.new(0.70, 0, 0.65, 0)

modalTitle.Position = UDim2.new(0.03, 0, 0.5, 0)

modalTitle.AnchorPoint = Vector2.new(0, 0.5)

modalTitle.BackgroundTransparency = 1

modalTitle.Font = UITheme.CONFIG.Font

modalTitle.TextColor3 = UITheme.CONFIG.Colors.White

modalTitle.TextScaled = true

modalTitle.TextWrapped = false

modalTitle.TextXAlignment = Enum.TextXAlignment.Left

modalTitle.Text = "DAILY REWARDS"

modalTitle.ZIndex = modalHeader.ZIndex + 3

UITheme.applyTextStroke(modalTitle, UITheme.CONFIG.TEXT_STROKE_LARGE, UITheme.CONFIG.Colors.Outline)

UITheme.addTextConstraint(modalTitle, 16, 38)

modalTitle.Parent = modalHeader

local btnCloseModal = Instance.new("TextButton")

btnCloseModal.Name = "CloseButton"

btnCloseModal.Size = UDim2.fromOffset(56, 56)

btnCloseModal.Position = UDim2.new(1, -10, 0.5, 0)

btnCloseModal.AnchorPoint = Vector2.new(1, 0.5)

btnCloseModal.Text = "X"

btnCloseModal.Font = UITheme.CONFIG.Font

btnCloseModal.TextColor3 = UITheme.CONFIG.Colors.White

btnCloseModal.TextScaled = true

btnCloseModal.AutoButtonColor = false

UITheme.styleButton(btnCloseModal, "Magenta", 10)

btnCloseModal.ZIndex = modalHeader.ZIndex + 4

btnCloseModal.Parent = modalHeader

local modalBody = Instance.new("Frame")

modalBody.Name = "ModalBody"

modalBody.Size = UDim2.new(1, 0, 1, -74)

modalBody.Position = UDim2.new(0, 0, 0, 74)

modalBody.BackgroundTransparency = 1

modalBody.Parent = modalBox

local freeRewardsHandler: any
freeRewardsHandler = ShopDailyUI.initFreeRewards(screenGui, modalBackdrop, Remotes, UITheme, GameConfig)
local freeRewardsWindow = freeRewardsHandler.window

local shopHandler = ShopDailyUI.initShop(screenGui, modalBackdrop, Remotes, UITheme)
local shopWindow = shopHandler.window

local skinsHandler: any
skinsHandler = ShopDailyUI.initChairSkins(screenGui, modalBackdrop, Remotes, UITheme, GameConfig, function()
	openModal("WHEEL")
end)
local skinsWindow = skinsHandler.window

local titlesHandler: any
titlesHandler = ShopDailyUI.initTitles(screenGui, modalBackdrop, Remotes, UITheme, GameConfig)
local titlesWindow = titlesHandler.window

local questsHandler: any
questsHandler = ShopDailyUI.initDailyQuest(screenGui, modalBackdrop, Remotes, UITheme, GameConfig)
local questsWindow = questsHandler.window

local wheelHandler = WheelUI.init(screenGui, modalBackdrop, Remotes, UITheme, GameConfig, playSfx)

local pageIndex = Instance.new("Frame")

pageIndex.Name = "PageIndex"

pageIndex.Size = UDim2.fromScale(1, 1)

pageIndex.BackgroundTransparency = 1

pageIndex.Visible = false

pageIndex.Parent = modalBody

local pageProfile = Instance.new("Frame")

pageProfile.Name = "PageProfile"

pageProfile.Size = UDim2.fromScale(1, 1)

pageProfile.BackgroundTransparency = 1

pageProfile.Visible = false

pageProfile.Parent = modalBody

-- ============================================================

-- Build Page 2: DAILY QUESTS (R9 Reference Layout & UITheme)

-- ============================================================

local SHOW_REFRESH = false -- shortcut: set true if server adds QuestRefresh remote; widens title plate when false

-- ============================================================

-- Page 3: Chair Skins moved to dedicated SkinsWindow via ShopDailyUI.initChairSkins
local luckUpgradeBtn: TextButton? = nil
local skinActionBtns: { [string]: TextButton } = {}
local skinNameLabels: { [string]: TextLabel } = {}

-- Build Page 4: TITLES (Wins Header + Scrolling Rows + Instant Unlock)

-- ============================================================

-- ============================================================

-- Build Page 5: SHOP (Managed by ShopDailyUI)

-- ============================================================

-- Build Page 6: CARD INDEX / POKEDEX (152 Footballers sorted Mythic -> Common)

-- ============================================================

local indexProgressHeader: TextLabel

local indexCardCells: { [string]: { frame: Frame, label: TextLabel, card: Footballers.Footballer } } = {}

do

indexProgressHeader = makeLabel(pageIndex, "DISCOVERED: 0 / 152 (0%) • +$25–$250 PER NEW CARD!", UDim2.new(0.96, 0, 0.11, 0), UDim2.new(0.02, 0, 0, 0), UITheme.Colors.NoticeYellow)

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

local lastHandledWheelSeq = (localPlayer:GetAttribute("WheelSpinSeq") :: number?) or 0

local refreshProfileGlobalRanks: () -> ()

local updateProfilePage: (p: any, elapsed: number, disc: { [string]: boolean }, discCount: number, pct: number) -> ()

do

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

		local rarityRankMap: { [string]: number } = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }

		local fallbackRarestCard: any = nil

		for _, card in Footballers.All do

			rTotal[card.rarity] = (rTotal[card.rarity] or 0) + 1

			if disc[card.id] then

				rCounts[card.rarity] = (rCounts[card.rarity] or 0) + 1

				if not fallbackRarestCard then

					fallbackRarestCard = card

				else

					local rCand = rarityRankMap[card.rarity] or 0

					local rCur = rarityRankMap[fallbackRarestCard.rarity] or 0

					if rCand > rCur or (rCand == rCur and card.ovr > fallbackRarestCard.ovr) then

						fallbackRarestCard = card

					end

				end

			end

		end

		for rName, lbl in profRarityVals do

			lbl.Text = `{rCounts[rName] or 0}/{rTotal[rName] or 0}`

		end

		local totalSpins = p.TotalCardSpins or 0

		local mythicsPulled = p.MythicsPulled or 0

		local hasSpinHistory = totalSpins > 0 or (p.MatchesPlayed or 0) == 0

		profTotalSpinsVal.Text = if hasSpinHistory then `{totalSpins} SPIN • {mythicsPulled} MYTHIC` else "-"

		profPityVal.Text = if hasSpinHistory then `{p.MaxSpinsWithoutMythic or 0} MAX (SKRG: {p.SpinsSinceMythic or 0})` else "-"

		local rarestCard = if p.RarestCardId and p.RarestCardId ~= "" then Footballers.ById[p.RarestCardId] else fallbackRarestCard

		if rarestCard then

			profRarestCardVal.Text = `{Footballers.getDisplayName(rarestCard)} ({rarestCard.rarity} {rarestCard.ovr})`

			profRarestCardVal.TextColor3 = GameConfig.RARITY_COLORS[rarestCard.rarity] or UITheme.Colors.White

		else

			profRarestCardVal.Text = "-"

			profRarestCardVal.TextColor3 = UITheme.Colors.White

		end

		local latestCard = if p.LatestCardId and p.LatestCardId ~= "" then Footballers.ById[p.LatestCardId] else nil

		if latestCard then

			profLatestCardVal.Text = `{Footballers.getDisplayName(latestCard)} ({latestCard.rarity} {latestCard.ovr})`

			profLatestCardVal.TextColor3 = GameConfig.RARITY_COLORS[latestCard.rarity] or UITheme.Colors.White

		else

			profLatestCardVal.Text = "-"

			profLatestCardVal.TextColor3 = UITheme.Colors.White

		end

	end

end

-- Modal Navigation Logic

local function closeAllModals(except: string?)
	if except ~= "SHOP" and shopWindow.Visible then
		shopWindow.Visible = false
	end
	if except ~= "SKINS" and skinsWindow and skinsWindow.Visible then
		skinsWindow.Visible = false
	end
	if except ~= "TITLES" and titlesWindow and titlesWindow.Visible then
		titlesWindow.Visible = false
	end
	if except ~= "QUESTS" and questsWindow and questsWindow.Visible then
		questsWindow.Visible = false
	end
	if except ~= "FREE" and freeRewardsWindow and freeRewardsWindow.Visible then
		freeRewardsWindow.Visible = false
	end
	if except ~= "WHEEL" and wheelHandler.isOpen() then
		wheelHandler.window.Visible = false
	end
	if except ~= "WRAP" and modalWrap.Visible then
		modalWrap.Visible = false
	end
end

local function openWheel()
	closeAllModals("WHEEL")
	modalBackdrop.Visible = true
	wheelHandler.open()
end

local function openShop()
	closeAllModals("SHOP")
	modalBackdrop.Visible = true
	shopHandler.open()
end

local function closeShop()
	modalBackdrop.Visible = false
	shopHandler.close()
end

local function openSkins()
	closeAllModals("SKINS")
	modalBackdrop.Visible = true
	skinsHandler.open()
end

local function closeSkins()
	modalBackdrop.Visible = false
	skinsHandler.close()
end

local function openTitles()
	closeAllModals("TITLES")
	modalBackdrop.Visible = true
	titlesHandler.open()
end

local function closeTitles()
	modalBackdrop.Visible = false
	titlesHandler.close()
end

local function openQuests()
	closeAllModals("QUESTS")
	modalBackdrop.Visible = true
	questsHandler.open()
end

local function closeQuests()
	modalBackdrop.Visible = false
	questsHandler.close()
end

local function openFreeTab(tab: ("DAILY" | "GROUP" | "PLAYTIME")?)
	closeAllModals("FREE")
	modalBackdrop.Visible = true
	if freeRewardsHandler then
		freeRewardsHandler.open(tab or "DAILY")
	end
end

local function closeFreeRewards()
	modalBackdrop.Visible = false
	if freeRewardsHandler then
		freeRewardsHandler.close()
	end
end

local function openModal(kind: "FREE" | "QUESTS" | "SKINS" | "TITLES" | "SHOP" | "INDEX" | "WHEEL" | "PROFILE")
	if kind == "SHOP" then
		openShop()
		return
	elseif kind == "SKINS" then
		openSkins()
		return
	elseif kind == "TITLES" then
		openTitles()
		return
	elseif kind == "QUESTS" then
		openQuests()
		return
	elseif kind == "FREE" then
		openFreeTab("DAILY")
		return
	elseif kind == "WHEEL" then
		openWheel()
		return
	end

	closeAllModals("WRAP")
	pageIndex.Visible = (kind == "INDEX")
	pageProfile.Visible = (kind == "PROFILE")

	local targetScale = UITheme.getModalScale()

	modalBackdrop.Visible = true
	modalBox.Visible = true
	modalWrap.Visible = true
	UITheme.animateWindowOpen(modalWrap, modalBox, targetScale)

	if kind == "INDEX" then
		UITheme.styleHeader(modalHeader, "Magenta", "CARD INDEX (152 FOOTBALLERS)")
	elseif kind == "PROFILE" then
		UITheme.styleHeader(modalHeader, "Blue", "PLAYER PROFILE & STATS TRACKER")
		refreshProfileGlobalRanks()
	end
end

btnCloseModal.Activated:Connect(function()
	modalBackdrop.Visible = false
	UITheme.animateWindowClose(modalWrap, modalBox)
end)

modalBackdrop.Activated:Connect(function()
	if wheelHandler.isSpinning() then
		return
	end
	local openedAt = math.max(
		(modalWrap:GetAttribute("OpenedAt") :: number?) or 0,
		(wheelHandler.window:GetAttribute("OpenedAt") :: number?) or 0
	)
	if os.clock() - openedAt < 0.25 then
		return
	end
	modalBackdrop.Visible = false
	if modalWrap.Visible then
		UITheme.animateWindowClose(modalWrap, modalBox)
	end
	if wheelHandler.isOpen() then
		wheelHandler.close()
	end
	if shopWindow.Visible then
		closeShop()
	end
	if skinsHandler and skinsHandler.isOpen() then
		closeSkins()
	end
	if titlesHandler and titlesHandler.isOpen() then
		closeTitles()
	end
	if freeRewardsHandler and freeRewardsHandler.isOpen() then
		closeFreeRewards()
	end
	if questsHandler and questsHandler.isOpen() then
		closeQuests()
	end
end)

local function bindNav(btn: GuiButton, callback: () -> ())
	local lastAt = 0
	local function trigger()
		local now = os.clock()
		if now - lastAt < 0.25 then return end
		lastAt = now
		callback()
	end
	btn.Activated:Connect(trigger)
	btn.MouseButton1Click:Connect(trigger)
end

bindNav(btnNavFree, function()
	openModal("FREE")
end)

bindNav(btnTopDaily, function()
	openModal("FREE")
end)

bindNav(btnTopQuests, function()
	openModal("QUESTS")
end)

bindNav(btnNavShop, function()
	openShop()
end)

bindNav(btnNavSkins, function()
	openModal("SKINS")
end)

bindNav(btnNavTitles, function()
	openModal("TITLES")
end)

bindNav(btnNavIndex, function()
	openModal("INDEX")
end)

bindNav(btnNavProfile, function()
	openModal("PROFILE")
end)

btnPromoStarter.Activated:Connect(function()

	openShop()

end)

btnPromoStreak.Activated:Connect(function()

	openShop()

end)

btnAddCash.Activated:Connect(function()

	openShop()

end)


-- ============================================================

-- 2. MATCH OVERLAY UI (WAITING / INTRO / COUNTDOWN / BUILD / SHOWDOWN / WINNER)

-- ============================================================

local ATTR_ICONS: { [string]: string } = {

	SHO = "🎯",

	PAC = "⚡",

	DRI = "👟",

	PAS = "🧠",

	DEF = "🛡️",

	PHY = "💪",

}

local avatarCache: { [number]: string } = {}

local function getAvatarThumb(userId: number?): string

	local uid = if typeof(userId) == "number" and userId > 0 then userId else 1

	if avatarCache[uid] then

		return avatarCache[uid]

	end

	local ok, content = pcall(function()

		return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

	end)

	local img = if ok and typeof(content) == "string" then content else ""

	avatarCache[uid] = img

	return img

end

local function makeLine(parent: Instance, color: Color3, thickness: number): Frame

	local f = Instance.new("Frame")

	f.AnchorPoint = Vector2.new(0.5, 0.5)

	f.BorderSizePixel = 0

	f.BackgroundColor3 = color

	f.Size = UDim2.fromOffset(0, thickness)

	f.Parent = parent

	return f

end

local function setLine(line: Frame, p1: Vector2, p2: Vector2, thickness: number)

	local delta = p2 - p1

	local mid = (p1 + p2) * 0.5

	line.Position = UDim2.fromOffset(mid.X, mid.Y)

	line.Size = UDim2.fromOffset(delta.Magnitude, thickness)

	line.Rotation = math.deg(math.atan2(delta.Y, delta.X))

end

local activeEndsAt = 0

local currentPhase = "Idle"

local currentSubPhase = ""

local currentPlacedThisRound = false

local rollingToken = 0

local showdownToken = 0

local cachedProfile: any = nil

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
overlay.BackgroundTransparency = 0.35
overlay.ZIndex = 1
overlay.Visible = false
overlay.Parent = screenGui

-- Fixed 16:9 (886x496) Design Root for the Build a Footballer screen
local layoutRoot = Instance.new("Frame")
layoutRoot.Name = "LayoutRoot"
layoutRoot.AnchorPoint = Vector2.new(0.5, 0.5)
layoutRoot.Position = UDim2.fromScale(0.5, 0.5)
layoutRoot.Size = UDim2.fromScale(1, 1)
layoutRoot.BackgroundTransparency = 1
layoutRoot.ClipsDescendants = false
layoutRoot.ZIndex = 2
layoutRoot.Parent = overlay

do
	local layoutAspect = Instance.new("UIAspectRatioConstraint")
	layoutAspect.AspectRatio = 1.786
	layoutAspect.AspectType = Enum.AspectType.FitWithinMaxSize
	layoutAspect.DominantAxis = Enum.DominantAxis.Width
	layoutAspect.Parent = layoutRoot
end

local MatchUi = {}

function MatchUi.label(parent: Instance, text: string, size: UDim2, pos: UDim2?, color: Color3?, maxTextSize: number, strokeThickness: number, zIdx: number): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Size = size
	if pos then
		lbl.Position = pos
	end
	lbl.BackgroundTransparency = 1
	lbl.Font = UITheme.Fonts.Primary
	lbl.TextColor3 = color or UITheme.Colors.White
	lbl.TextStrokeTransparency = 1
	lbl.TextWrapped = false
	lbl.TextScaled = true
	lbl.Text = text
	lbl.ZIndex = zIdx

	local sc = Instance.new("UITextSizeConstraint")
	sc.MinTextSize = 6
	sc.MaxTextSize = maxTextSize
	sc.Parent = lbl

	local st = Instance.new("UIStroke")
	st.Color = UITheme.Colors.Black
	st.Thickness = strokeThickness
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.Parent = lbl

	lbl.Parent = parent
	return lbl
end

function MatchUi.corner(parent: Instance, scaleRadius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scaleRadius, 0)
	c.Parent = parent
	return c
end

local modeSubLabel: TextLabel
local headerLabel: TextLabel
local timerLabel: TextLabel
do
	local titleGroup = Instance.new("Frame")
	titleGroup.Name = "TitleGroup"
	titleGroup.AnchorPoint = Vector2.new(0.5, 0)
	titleGroup.Position = UDim2.fromScale(0.5, 0)
	titleGroup.Size = UDim2.fromScale(0.40, 0.14)
	titleGroup.BackgroundTransparency = 1
	titleGroup.ZIndex = 10
	titleGroup.Parent = layoutRoot

	local titleList = Instance.new("UIListLayout")
	titleList.FillDirection = Enum.FillDirection.Vertical
	titleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	titleList.VerticalAlignment = Enum.VerticalAlignment.Top
	titleList.SortOrder = Enum.SortOrder.LayoutOrder
	titleList.Padding = UDim.new(0, 0)
	titleList.Parent = titleGroup

	modeSubLabel = MatchUi.label(titleGroup, "DEFAULT MODE", UDim2.fromScale(1, 0.25), nil, Color3.new(1, 1, 1), 18, 1.5, 10)
	modeSubLabel.LayoutOrder = 1
	headerLabel = MatchUi.label(titleGroup, "BUILD A FOOTBALLER", UDim2.fromScale(1, 0.45), nil, Color3.new(1, 1, 1), 36, 2, 10)
	headerLabel.LayoutOrder = 2
	timerLabel = MatchUi.label(titleGroup, "15", UDim2.fromScale(1, 0.30), nil, Color3.new(1, 1, 1), 28, 2, 10)
	timerLabel.LayoutOrder = 3
end

local winnerNameLabel = MatchUi.label(layoutRoot, "", UDim2.fromScale(0.50, 0.07), UDim2.fromScale(0.50, 0.14), Color3.new(1, 1, 1), 28, 2, 10)
winnerNameLabel.AnchorPoint = Vector2.new(0.5, 0)
winnerNameLabel.Visible = false

-- ============================================================
-- 2A. SEATED WAITING SCREEN ("INVITE FRIENDS", "LEAVE" + "FIGHT WITH AI -> PLAY!")
-- ============================================================
local waitingWrap = Instance.new("Frame")
waitingWrap.Name = "WaitingWrap"
waitingWrap.Size = UDim2.fromScale(1, 1)
waitingWrap.BackgroundTransparency = 1
waitingWrap.Visible = false
waitingWrap.Parent = layoutRoot

do
	local queueButtons = Instance.new("Frame")
	queueButtons.Name = "QueueButtons"
	queueButtons.BackgroundTransparency = 1
	queueButtons.AnchorPoint = Vector2.new(0.5, 1)
	queueButtons.Position = UDim2.fromScale(0.5, 0.97)
	-- Step 4: raised from 0.34 to 0.40 so mobile buttons maximize tap area without enlarging text
	queueButtons.Size = UDim2.fromScale(0.40, 0)
	queueButtons.ZIndex = 5
	queueButtons.Parent = waitingWrap

	local qbAspect = Instance.new("UIAspectRatioConstraint")
	qbAspect.AspectRatio = 2.83
	qbAspect.AspectType = Enum.AspectType.ScaleWithParentSize
	qbAspect.DominantAxis = Enum.DominantAxis.Width
	qbAspect.Parent = queueButtons

	local qbSize = Instance.new("UISizeConstraint")
	qbSize.MinSize = Vector2.new(220, 78)
	qbSize.MaxSize = Vector2.new(420, 150)
	qbSize.Parent = queueButtons

	local function makeQueueLabel(parent: Instance, text: string, size: UDim2, pos: UDim2?, color: Color3, minSz: number, maxSz: number): TextLabel
		local lbl = MatchUi.label(parent, text, size, pos, color, maxSz, 1.5, 8)
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		local tc = lbl:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint?
		if tc then tc.MinTextSize = minSz end
		return lbl
	end

	local function makeQueueBtn(text: string, pos: UDim2, size: UDim2, bg: Color3, maxTextSz: number): TextButton
		local btn = Instance.new("TextButton")
		btn.Position = pos
		btn.Size = size
		btn.BackgroundColor3 = bg
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Active = true
		btn.Font = UITheme.Fonts.Primary
		btn.Text = text
		btn.TextColor3 = UITheme.Colors.White
		btn.TextTransparency = 1
		btn.TextStrokeTransparency = 1
		btn.TextWrapped = false
		btn.TextScaled = true
		btn.ZIndex = 6
		MatchUi.corner(btn, 0.2)
		UITheme.applyStroke(btn, 2, UITheme.Colors.Black)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0.06, 0)
		pad.PaddingRight = UDim.new(0.06, 0)
		pad.Parent = btn

		local tc = Instance.new("UITextSizeConstraint")
		tc.MinTextSize = 8
		tc.MaxTextSize = maxTextSz
		tc.Parent = btn

		if text ~= "" then
			local lbl = makeQueueLabel(btn, text, UDim2.fromScale(1, 1), nil, Color3.new(1, 1, 1), 8, maxTextSz)
			btn:GetPropertyChangedSignal("Text"):Connect(function()
				lbl.Text = btn.Text
			end)
		end

		btn.Activated:Connect(function()
			playSfx("click")
		end)
		btn.Parent = queueButtons
		return btn
	end

	local btnWaitInvite = makeQueueBtn("", UDim2.fromScale(0, 0.23), UDim2.fromScale(0.54, 0.35), Color3.fromHex("#FFD21F"), 16)
	do
		local btnList = Instance.new("UIListLayout")
		btnList.FillDirection = Enum.FillDirection.Horizontal
		btnList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		btnList.VerticalAlignment = Enum.VerticalAlignment.Center
		btnList.SortOrder = Enum.SortOrder.LayoutOrder
		btnList.Padding = UDim.new(0.04, 0)
		btnList.Parent = btnWaitInvite

		local ink = Color3.fromRGB(15, 17, 22)
		local iconWrap = Instance.new("Frame")
		iconWrap.Name = "UserPlusIcon"
		iconWrap.LayoutOrder = 1
		iconWrap.Size = UDim2.fromScale(0.22, 0.70)
		iconWrap.BackgroundTransparency = 1
		iconWrap.ZIndex = 7
		iconWrap.Parent = btnWaitInvite

		local iconAspect = Instance.new("UIAspectRatioConstraint")
		iconAspect.AspectRatio = 1
		iconAspect.AspectType = Enum.AspectType.FitWithinMaxSize
		iconAspect.DominantAxis = Enum.DominantAxis.Height
		iconAspect.Parent = iconWrap

		local function makeIconPart(parent: Instance, name: string, size: UDim2, pos: UDim2, rounded: boolean, transparent: boolean?): Frame
			local f = Instance.new("Frame")
			f.Name = name
			f.Size = size
			f.Position = pos
			f.BackgroundColor3 = ink
			f.BackgroundTransparency = if transparent then 1 else 0
			f.BorderSizePixel = 0
			f.ZIndex = 7
			f.Parent = parent
			if rounded then
				MatchUi.corner(f, 1)
			end
			return f
		end

		makeIconPart(iconWrap, "Head", UDim2.fromScale(0.367, 0.367), UDim2.fromScale(0.167, 0.10), true)
		local bodyClip = makeIconPart(iconWrap, "ShouldersClip", UDim2.fromScale(0.70, 0.40), UDim2.fromScale(0, 0.467), false, true)
		bodyClip.ClipsDescendants = true
		makeIconPart(bodyClip, "Shoulders", UDim2.fromScale(1, 2), UDim2.fromScale(0, 0), true)
		makeIconPart(iconWrap, "PlusH", UDim2.fromScale(0.367, 0.10), UDim2.fromScale(0.633, 0.467), true)
		makeIconPart(iconWrap, "PlusV", UDim2.fromScale(0.10, 0.367), UDim2.fromScale(0.767, 0.333), true)

		local inviteLbl = makeQueueLabel(btnWaitInvite, "INVITE FRIENDS", UDim2.fromScale(0.78, 0.80), nil, Color3.new(1, 1, 1), 8, 16)
		inviteLbl.Name = "InviteLabel"
		inviteLbl.LayoutOrder = 2
	end
	btnWaitInvite.Activated:Connect(function()
		pcall(function()
			SocialService:PromptGameInvite(localPlayer)
		end)
	end)

	local btnWaitLeave = makeQueueBtn("LEAVE", UDim2.fromScale(0, 0.70), UDim2.fromScale(0.54, 0.30), Color3.fromHex("#E5252A"), 16)
	btnWaitLeave.Activated:Connect(function()
		Remotes.MatchAction:FireServer("LeaveTable")
	end)

	makeQueueLabel(queueButtons, "TIRED OF WAITING?", UDim2.fromScale(0.40, 0.15), UDim2.fromScale(0.60, 0), Color3.new(1, 1, 1), 7, 12)
	makeQueueLabel(queueButtons, "FIGHT WITH AI", UDim2.fromScale(0.40, 0.16), UDim2.fromScale(0.60, 0.15), Color3.fromHex("#FFA500"), 7, 13)
	local btnPlayBotNow = makeQueueBtn("PLAY!", UDim2.fromScale(0.60, 0.475), UDim2.fromScale(0.40, 0.36), Color3.fromHex("#22C55E"), 20)
	btnPlayBotNow.Activated:Connect(function()
		Remotes.MatchAction:FireServer("PlayBotNow")
	end)
end

-- ============================================================
-- 2B. INTRO SCREEN ("<Player> VS <BOT> / DEFAULT MODE") & COUNTDOWN ("3, 2, 1, GO!")
-- ============================================================
local introWrap = Instance.new("Frame")
introWrap.Name = "IntroWrap"
introWrap.Size = UDim2.fromScale(1, 1)
introWrap.BackgroundTransparency = 1
introWrap.Visible = false
introWrap.Parent = layoutRoot

local function makeIntroLabel(text: string, size: UDim2, centerY: number, color: Color3, maxText: number, strokeThick: number): TextLabel
	local lbl = MatchUi.label(introWrap, text, size, UDim2.fromScale(0.5, centerY), color, maxText, strokeThick, 4)
	lbl.AnchorPoint = Vector2.new(0.5, 0.5)
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	local tc = lbl:FindFirstChildOfClass("UITextSizeConstraint") :: UITextSizeConstraint?
	if tc then tc.MinTextSize = 8 end
	return lbl
end

local introMyName = makeIntroLabel("Player", UDim2.fromScale(0.65, 0.085), 0.3455, Color3.fromHex("#1E6FFF"), 72, 2.5)
local introVs = makeIntroLabel("VS", UDim2.fromScale(0.35, 0.070), 0.451, Color3.fromHex("#FFA500"), 60, 2.5)
local introOppName = makeIntroLabel("BOT", UDim2.fromScale(0.65, 0.085), 0.5565, Color3.fromHex("#FF2E93"), 72, 2.5)
local introMode = makeIntroLabel("DEFAULT MODE", UDim2.fromScale(0.55, 0.050), 0.652, Color3.new(1, 1, 1), 42, 2)

local countdownWrap = Instance.new("Frame")
countdownWrap.Name = "CountdownWrap"
countdownWrap.Size = UDim2.fromScale(1, 1)
countdownWrap.BackgroundTransparency = 1
countdownWrap.Visible = false
countdownWrap.Parent = layoutRoot

local countdownBigLabel = makeLabel(countdownWrap, "3", UDim2.fromOffset(220, 140), UDim2.new(0.5, -110, 0.44, -70), Color3.new(1, 1, 1))

-- ============================================================

-- 2C. BUILD SCREEN (CENTER 3D CARDS + 6 LEFT/RIGHT SLOTS WITH 48x48 3D FACE SQUARES)

-- ============================================================

type ViewportMount = {

	model: Model?,

	modelId: string?,

}

local function mountViewportModel(viewport: ViewportFrame, mount: ViewportMount, cardId: string?)

	if mount.modelId == cardId and mount.model ~= nil then

		return

	end

	if mount.model then

		mount.model:Destroy()

		mount.model = nil

	end

	mount.modelId = cardId

	if cardId then

		local cloned = FootballerModelBuilder.cloneModel(cardId)

		if cloned then

			cloned.Parent = viewport

			mount.model = cloned

		end

	end

end

local function createFaceViewport(parent: Instance): ViewportFrame

	local vp = Instance.new("ViewportFrame")

	vp.Name = "FaceViewport"

	vp.Size = UDim2.fromScale(1, 1)

	vp.BackgroundTransparency = 1

	vp.LightColor = Color3.new(1, 1, 1)

	vp.Ambient = Color3.fromRGB(195, 202, 218)

	vp.LightDirection = Vector3.new(-0.35, -0.60, 0.72)

	vp.Parent = parent

	local cam = Instance.new("Camera")

	cam.FieldOfView = 33

	cam.CFrame = CFrame.lookAt(Vector3.new(0.22, 2.15, -3.10), Vector3.new(0, 2.12, 0))

	cam.Parent = vp

	vp.CurrentCamera = cam

	return vp

end

function MatchUi.createCard(parent: Instance, posScale: UDim2)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.139, 0.29)
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Position = posScale
	frame.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
	frame.ClipsDescendants = true
	frame.ZIndex = 6
	MatchUi.corner(frame, 0.08)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.new(0, 0, 0)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	frame.Parent = parent

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(75, 88, 115)),
		ColorSequenceKeypoint.new(0.58, Color3.fromRGB(22, 26, 36)),
		ColorSequenceKeypoint.new(0.62, Color3.fromRGB(10, 12, 18)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10, 12, 18)),
	})
	grad.Rotation = 90
	grad.Parent = frame

	local cardContent = Instance.new("Frame")
	cardContent.Name = "CardContent"
	cardContent.Size = UDim2.fromScale(1, 1)
	cardContent.BackgroundTransparency = 1
	cardContent.ZIndex = 7
	cardContent.Parent = frame

	local cardPad = Instance.new("UIPadding")
	cardPad.PaddingTop = UDim.new(0.03, 0)
	cardPad.PaddingBottom = UDim.new(0.03, 0)
	cardPad.PaddingLeft = UDim.new(0.04, 0)
	cardPad.PaddingRight = UDim.new(0.04, 0)
	cardPad.Parent = cardContent

	local cardList = Instance.new("UIListLayout")
	cardList.FillDirection = Enum.FillDirection.Vertical
	cardList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardList.VerticalAlignment = Enum.VerticalAlignment.Top
	cardList.SortOrder = Enum.SortOrder.LayoutOrder
	cardList.Padding = UDim.new(0.01, 0)
	cardList.Parent = cardContent

	local posHeader = Instance.new("Frame")
	posHeader.Name = "PosHeader"
	posHeader.LayoutOrder = 1
	posHeader.Size = UDim2.fromScale(1, 0.11)
	posHeader.BackgroundTransparency = 1
	posHeader.ZIndex = 7
	posHeader.Parent = cardContent

	local posTag = MatchUi.label(posHeader, "ST", UDim2.fromScale(0.30, 1), UDim2.fromScale(0, 0), Color3.new(1, 1, 1), 14, 1.5, 8)
	posTag.BackgroundTransparency = 0.25
	posTag.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	MatchUi.corner(posTag, 0.25)

	-- Real 3D Footballer Viewport inside the card (hair, face, skin, club shirt & club shorts)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ModelViewport"
	viewport.LayoutOrder = 2
	viewport.Size = UDim2.fromScale(0.95, 0.50)
	viewport.BackgroundTransparency = 1
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.Ambient = Color3.fromRGB(185, 192, 208)
	viewport.LightDirection = Vector3.new(-0.45, -0.75, 0.65)
	viewport.ZIndex = 7
	viewport.Parent = cardContent

	local vpCam = Instance.new("Camera")
	vpCam.FieldOfView = 36
	vpCam.CFrame = CFrame.lookAt(Vector3.new(0.90, 0.84, -7.75), Vector3.new(0, 0.66, 0))
	vpCam.Parent = viewport
	viewport.CurrentCamera = vpCam

	-- Real Full Name, Real Club - Real Country, Rarity
	local nameLbl = MatchUi.label(cardContent, "William Saliba", UDim2.fromScale(0.96, 0.14), nil, Color3.new(1, 1, 1), 20, 2, 8)
	nameLbl.LayoutOrder = 3
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local clubLbl = MatchUi.label(cardContent, "Arsenal - France", UDim2.fromScale(0.96, 0.10), nil, Color3.fromRGB(205, 212, 225), 13, 1.5, 8)
	clubLbl.LayoutOrder = 4
	clubLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local rarityLbl = MatchUi.label(cardContent, "Legendary", UDim2.fromScale(0.96, 0.11), nil, GameConfig.RARITY_COLORS.Legendary, 15, 1.5, 8)
	rarityLbl.LayoutOrder = 5

	local dimVeil = Instance.new("Frame")
	dimVeil.Size = UDim2.fromScale(1, 1)
	dimVeil.BackgroundColor3 = Color3.new(0, 0, 0)
	dimVeil.BackgroundTransparency = 0.42
	dimVeil.Visible = false
	dimVeil.ZIndex = 9
	dimVeil.Parent = frame

	return {
		frame = frame,
		stroke = stroke,
		viewport = viewport,
		mount = { model = nil, modelId = nil } :: ViewportMount,
		posTag = posTag,
		kitColor = Color3.fromHex("#1E6FFF"),
		nameLbl = nameLbl,
		clubLbl = clubLbl,
		rarityLbl = rarityLbl,
		dimVeil = dimVeil,
		lastId = nil :: string?,
	}
end

function MatchUi.setSilhouette(widget: any, randomCard: any)
	widget.frame.Visible = true
	widget.dimVeil.Visible = false
	widget.viewport.ImageColor3 = Color3.fromRGB(8, 10, 16)
	widget.posTag.Text = "?"
	widget.stroke.Color = Color3.new(0, 0, 0)
	if randomCard then
		mountViewportModel(widget.viewport, widget.mount, randomCard.id)
		widget.nameLbl.Text = Footballers.getDisplayName(randomCard)
		widget.clubLbl.Text = `{randomCard.club} - {randomCard.country}`
		widget.rarityLbl.Text = randomCard.rarity
		widget.rarityLbl.TextColor3 = GameConfig.RARITY_COLORS[randomCard.rarity] or Color3.new(1, 1, 1)
	end
end

function MatchUi.populateCard(widget: any, card: any, isMine: boolean?, isDimmed: boolean?)
	if not card then
		widget.frame.Visible = false
		widget.lastId = nil
		return
	end
	widget.frame.Visible = true
	widget.dimVeil.Visible = isDimmed == true
	if widget.lastId ~= card.id then
		widget.lastId = card.id
		if isMine then
			playSfx(if card.rarity == "Mythic" or card.rarity == "Legendary" then "rare" else "roll")
		end
	end
	local col = GameConfig.RARITY_COLORS[card.rarity] or Color3.new(1, 1, 1)
	mountViewportModel(widget.viewport, widget.mount, card.id)
	widget.viewport.ImageColor3 = Color3.new(1, 1, 1)
	widget.kitColor = Color3.fromHex(card.kitColor)
	widget.stroke.Color = Color3.new(0, 0, 0)
	widget.posTag.Text = card.pos
	widget.nameLbl.Text = Footballers.getDisplayName(card)
	widget.clubLbl.Text = `{card.club} - {card.country}`
	widget.rarityLbl.Text = card.rarity
	widget.rarityLbl.TextColor3 = col
end

local buildCenterWrap = Instance.new("Frame")
buildCenterWrap.Size = UDim2.fromScale(1, 1)
buildCenterWrap.BackgroundTransparency = 1
buildCenterWrap.ZIndex = 3
buildCenterWrap.Parent = layoutRoot

local buildMyAvatar: ImageLabel
local buildOppAvatar: ImageLabel
do
	local function createMiniAvatarBox(parent: Instance, pos: UDim2, size: UDim2, _borderCol: Color3)
		local img = Instance.new("ImageLabel")
		img.Size = size
		img.AnchorPoint = Vector2.new(0, 0)
		img.Position = pos
		img.BackgroundTransparency = 1
		img.ScaleType = Enum.ScaleType.Fit
		img.ZIndex = 4
		img.Parent = parent
		return img
	end

	buildMyAvatar = createMiniAvatarBox(buildCenterWrap, UDim2.fromScale(0.38, 0.17), UDim2.fromScale(0.077, 0.10), Color3.fromHex("#1E6FFF"))
	buildOppAvatar = createMiniAvatarBox(buildCenterWrap, UDim2.fromScale(0.55, 0.17), UDim2.fromScale(0.08, 0.10), Color3.fromHex("#E5252A"))
end

local myCardWidget = MatchUi.createCard(buildCenterWrap, UDim2.fromScale(0.35, 0.31))
local oppCardWidget = MatchUi.createCard(buildCenterWrap, UDim2.fromScale(0.519, 0.31))
local vsCenterLabel = MatchUi.label(buildCenterWrap, "VS", UDim2.fromScale(0.050, 0.075), UDim2.fromScale(0.505, 0.455), Color3.fromHex("#FFD21F"), 32, 2, 10)
vsCenterLabel.AnchorPoint = Vector2.new(0.5, 0.5)

local rolledInfoLabel = MatchUi.label(layoutRoot, "ROLLING...", UDim2.fromScale(0.30, 0.06), UDim2.fromScale(0.5, 0.665), Color3.new(1, 1, 1), 26, 2, 10)
rolledInfoLabel.AnchorPoint = Vector2.new(0.5, 0)
rolledInfoLabel.TextTruncate = Enum.TextTruncate.AtEnd

local luckBtn = Instance.new("TextButton")
luckBtn.Size = UDim2.fromScale(0.155, 0.04)
luckBtn.AnchorPoint = Vector2.new(0.5, 0)
luckBtn.Position = UDim2.fromScale(0.5, 0.74)
luckBtn.BackgroundColor3 = UITheme.Colors.LimeTop
luckBtn.Font = UITheme.Fonts.Primary
luckBtn.TextColor3 = Color3.new(1, 1, 1)
luckBtn.TextTransparency = 1
luckBtn.TextStrokeTransparency = 1
luckBtn.TextWrapped = false
luckBtn.TextScaled = true
luckBtn.AutoButtonColor = false
luckBtn.ClipsDescendants = true
luckBtn.Text = "      LUCK: 1x [→1.5x $750]"
luckBtn.ZIndex = 12
MatchUi.corner(luckBtn, 0.25)
UITheme.applyStroke(luckBtn, 2, UITheme.Colors.Black)
UITheme.applyGradient(luckBtn, UITheme.Colors.LimeTop, UITheme.Colors.LimeBottom, 90)
luckBtn.Parent = buildCenterWrap

do
	local luckStuds = Instance.new("ImageLabel")
	luckStuds.Name = "Studs"
	luckStuds.Size = UDim2.fromScale(1, 1)
	luckStuds.BackgroundTransparency = 1
	luckStuds.Image = UITheme.Assets.StudsTexture
	luckStuds.ImageTransparency = 0.88
	luckStuds.ImageColor3 = UITheme.Colors.LimeTop
	luckStuds.ScaleType = Enum.ScaleType.Tile
	luckStuds.TileSize = UDim2.fromScale(0.08, 0.80)
	luckStuds.ZIndex = 12
	luckStuds.Parent = luckBtn

	local matchClover = Instance.new("ImageLabel")
	matchClover.Name = "Icon_Clover"
	matchClover.Size = UDim2.fromScale(0.14, 0.85)
	matchClover.AnchorPoint = Vector2.new(0, 0.5)
	matchClover.Position = UDim2.fromScale(0.03, 0.5)
	matchClover.BackgroundTransparency = 1
	matchClover.Image = UITheme.Assets.CloverIcon
	matchClover.ScaleType = Enum.ScaleType.Fit
	matchClover.ZIndex = 14
	local cloverAspect = Instance.new("UIAspectRatioConstraint")
	cloverAspect.AspectRatio = 1.0
	cloverAspect.DominantAxis = Enum.DominantAxis.Height
	cloverAspect.Parent = matchClover
	matchClover.Parent = luckBtn

	local luckTextLbl = MatchUi.label(luckBtn, "LUCK: 1x [→1.5x $750]", UDim2.fromScale(0.81, 0.90), UDim2.fromScale(0.98, 0.5), Color3.new(1, 1, 1), 14, 1.5, 14)
	luckTextLbl.Name = "LuckLabel"
	luckTextLbl.AnchorPoint = Vector2.new(1, 0.5)

	local function syncLuckText()
		luckTextLbl.Text = string.gsub(luckBtn.Text, "^%s+", "")
	end
	syncLuckText()
	luckBtn:GetPropertyChangedSignal("Text"):Connect(syncLuckText)
end
luckBtn.Activated:Connect(function()
	playSfx("click")
	Remotes.MatchAction:FireServer("UpgradeLuck")
end)

-- Left (My 6 Attribute Slots) & Right (Opponent 6 Attribute Slots) matching Section 7.2 & 7.3
type SlotRow = {
	rowFrame: Frame,
	squareBtn: TextButton,
	plusLabel: TextLabel,
	miniPortrait: Frame,
	faceViewport: ViewportFrame,
	faceMount: ViewportMount,
	titleLabel: TextLabel,
	subLabel: TextLabel,
	scoreBadge: TextLabel,
	stealTag: TextButton?,
}
local mySlotRows: { [string]: SlotRow } = {}
local oppSlotRows: { [string]: SlotRow } = {}

local leftStatPanel = Instance.new("Frame")
leftStatPanel.Name = "LeftStatPanel"
leftStatPanel.Position = UDim2.fromScale(0.12, 0.16)
leftStatPanel.Size = UDim2.fromScale(0.19, 0.58)
leftStatPanel.BackgroundTransparency = 1
leftStatPanel.ClipsDescendants = false
leftStatPanel.ZIndex = 8
leftStatPanel.Parent = layoutRoot

do
	local leftList = Instance.new("UIListLayout")
	leftList.FillDirection = Enum.FillDirection.Vertical
	leftList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	leftList.VerticalAlignment = Enum.VerticalAlignment.Top
	leftList.SortOrder = Enum.SortOrder.LayoutOrder
	leftList.Padding = UDim.new(0.01, 0)
	leftList.Parent = leftStatPanel
end

local rightStatPanel = Instance.new("Frame")
rightStatPanel.Name = "RightStatPanel"
rightStatPanel.Position = UDim2.fromScale(0.70, 0.16)
rightStatPanel.Size = UDim2.fromScale(0.19, 0.58)
rightStatPanel.BackgroundTransparency = 1
rightStatPanel.ClipsDescendants = false
rightStatPanel.ZIndex = 8
rightStatPanel.Parent = layoutRoot

do
	local rightList = Instance.new("UIListLayout")
	rightList.FillDirection = Enum.FillDirection.Vertical
	rightList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rightList.VerticalAlignment = Enum.VerticalAlignment.Top
	rightList.SortOrder = Enum.SortOrder.LayoutOrder
	rightList.Padding = UDim.new(0.01, 0)
	rightList.Parent = rightStatPanel
end

do
	local leftHeader = MatchUi.label(layoutRoot, "YOU", UDim2.fromScale(0.26, 0.05), UDim2.fromScale(0.03, 0.14), Color3.fromHex("#1E6FFF"), 22, 2, 10)
	leftHeader.Visible = false
	local rightHeader = MatchUi.label(layoutRoot, "OPPONENT", UDim2.fromScale(0.26, 0.05), UDim2.fromScale(0.71, 0.14), Color3.fromHex("#E5252A"), 22, 2, 10)
	rightHeader.Visible = false
end

function MatchUi.flyToSlot(targetSquare: GuiObject)
	if not myCardWidget.frame.Visible then
		return
	end
	local clone = Instance.new("Frame")
	clone.Size = myCardWidget.frame.Size
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Position = UDim2.fromScale(
		myCardWidget.frame.Position.X.Scale + myCardWidget.frame.Size.X.Scale * 0.5,
		myCardWidget.frame.Position.Y.Scale + myCardWidget.frame.Size.Y.Scale * 0.5
	)
	clone.BackgroundColor3 = myCardWidget.kitColor
	clone.ZIndex = 25
	MatchUi.corner(clone, 0.08)
	addStroke(clone, Color3.new(1, 1, 1), 3)
	clone.Parent = layoutRoot

	local absPos = targetSquare.AbsolutePosition
	local absSize = targetSquare.AbsoluteSize
	local rootPos = layoutRoot.AbsolutePosition
	local rootSize = layoutRoot.AbsoluteSize
	local targetCenter = absPos + absSize * 0.5 - rootPos
	local destScale = if rootSize.X > 0 and rootSize.Y > 0
		then UDim2.fromScale(targetCenter.X / rootSize.X, targetCenter.Y / rootSize.Y)
		else UDim2.fromScale(0.28, 0.40)
	local destSize = if rootSize.X > 0 and rootSize.Y > 0
		then UDim2.fromScale(absSize.X / rootSize.X, absSize.Y / rootSize.Y)
		else UDim2.fromScale(0.045, 0.08)

	local tw = TweenService:Create(clone, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = destScale,
		Size = destSize,
		BackgroundTransparency = 0.2,
	})
	tw:Play()
	tw.Completed:Connect(function()
		clone:Destroy()
	end)
end

for idx, attr in GameConfig.ATTRIBUTES do
	local icon = ATTR_ICONS[attr] or ""
	local fullLabel = GameConfig.ATTRIBUTE_LABELS[attr] or attr

	-- LEFT ROW (YOUR SLOTS): Right-aligned [TextBlock] + [Square Slot Button]
	local myWrap = Instance.new("Frame")
	myWrap.LayoutOrder = idx
	myWrap.Size = UDim2.fromScale(1, 0.16)
	myWrap.BackgroundTransparency = 1
	myWrap.ClipsDescendants = false
	myWrap.ZIndex = 8
	myWrap.Parent = leftStatPanel

	local myRowLayout = Instance.new("UIListLayout")
	myRowLayout.FillDirection = Enum.FillDirection.Horizontal
	myRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	myRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	myRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	myRowLayout.Padding = UDim.new(0.035, 0)
	myRowLayout.Parent = myWrap

	local myTextBlock = Instance.new("TextButton")
	myTextBlock.LayoutOrder = 1
	myTextBlock.Size = UDim2.fromScale(0.75, 1)
	myTextBlock.BackgroundTransparency = 1
	myTextBlock.Text = ""
	myTextBlock.AutoButtonColor = false
	myTextBlock.ZIndex = 8
	myTextBlock.Parent = myWrap

	local myTextLayout = Instance.new("UIListLayout")
	myTextLayout.FillDirection = Enum.FillDirection.Vertical
	myTextLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	myTextLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	myTextLayout.SortOrder = Enum.SortOrder.LayoutOrder
	myTextLayout.Padding = UDim.new(0, 0)
	myTextLayout.Parent = myTextBlock

	local myTitle = MatchUi.label(myTextBlock, `{fullLabel} {icon}`, UDim2.fromScale(1, 0.55), nil, Color3.new(1, 1, 1), 22, 2, 9)
	myTitle.LayoutOrder = 1
	myTitle.TextXAlignment = Enum.TextXAlignment.Right

	local mySub = MatchUi.label(myTextBlock, "Please Select...", UDim2.fromScale(1, 0.45), nil, Color3.fromRGB(200, 208, 222), 15, 1.5, 9)
	mySub.LayoutOrder = 2
	mySub.TextXAlignment = Enum.TextXAlignment.Right
	mySub.TextTruncate = Enum.TextTruncate.AtEnd

	local mySq = Instance.new("TextButton")
	mySq.LayoutOrder = 2
	mySq.Size = UDim2.fromScale(0.25, 0.80)
	mySq.BackgroundColor3 = GameConfig.UI_COLORS.SlotSquare
	mySq.BackgroundTransparency = 0.25
	mySq.Text = ""
	mySq.AutoButtonColor = false
	mySq.ClipsDescendants = false
	mySq.ZIndex = 9
	MatchUi.corner(mySq, 0.18)
	UITheme.applyStroke(mySq, 2, UITheme.Colors.Black)
	local mySqAspect = Instance.new("UIAspectRatioConstraint")
	mySqAspect.AspectRatio = 1.0
	mySqAspect.DominantAxis = Enum.DominantAxis.Height
	mySqAspect.Parent = mySq
	mySq.Parent = myWrap

	local myPlus = MatchUi.label(mySq, "+", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1), Color3.new(1, 1, 1), 28, 2, 10)

	local myMini = Instance.new("Frame")
	myMini.Size = UDim2.fromScale(0.86, 0.86)
	myMini.AnchorPoint = Vector2.new(0.5, 0.5)
	myMini.Position = UDim2.fromScale(0.5, 0.5)
	myMini.BackgroundColor3 = Color3.fromHex("#1E6FFF")
	myMini.ClipsDescendants = true
	myMini.Visible = false
	myMini.ZIndex = 10
	MatchUi.corner(myMini, 0.16)
	myMini.Parent = mySq
	local myFaceVp = createFaceViewport(myMini)
	myFaceVp.ZIndex = 11
	MatchUi.corner(myFaceVp, 0.16)

	local myBadge = MatchUi.label(mySq, "84", UDim2.fromScale(0.65, 0.48), UDim2.fromScale(0.95, 0.88), Color3.fromHex("#FFD21F"), 18, 1.5, 12)
	myBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	myBadge.BackgroundTransparency = 0
	myBadge.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	myBadge.Visible = false
	MatchUi.corner(myBadge, 0.25)

	local function triggerPlace()
		if currentPhase == "Build" and currentSubPhase == "Selecting" and not currentPlacedThisRound and myPlus.Visible then
			playSfx("click")
			currentPlacedThisRound = true
			MatchUi.flyToSlot(mySq)
			Remotes.MatchAction:FireServer("PlaceSlot", attr)
		end
	end
	mySq.Activated:Connect(triggerPlace)
	myTextBlock.Activated:Connect(triggerPlace)

	mySlotRows[attr] = {
		rowFrame = myWrap,
		squareBtn = mySq,
		plusLabel = myPlus,
		miniPortrait = myMini,
		faceViewport = myFaceVp,
		faceMount = { model = nil, modelId = nil },
		titleLabel = myTitle,
		subLabel = mySub,
		scoreBadge = myBadge,
		stealTag = nil,
	}

	-- RIGHT ROW (OPPONENT SLOTS): Mirrored! [Square Slot Button] on left, Left-aligned [TextBlock] on right
	local oppWrap = Instance.new("Frame")
	oppWrap.LayoutOrder = idx
	oppWrap.Size = UDim2.fromScale(1, 0.16)
	oppWrap.BackgroundTransparency = 1
	oppWrap.ClipsDescendants = false
	oppWrap.ZIndex = 8
	oppWrap.Parent = rightStatPanel

	local oppRowLayout = Instance.new("UIListLayout")
	oppRowLayout.FillDirection = Enum.FillDirection.Horizontal
	oppRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	oppRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	oppRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	oppRowLayout.Padding = UDim.new(0.035, 0)
	oppRowLayout.Parent = oppWrap

	local oppSq = Instance.new("TextButton")
	oppSq.LayoutOrder = 1
	oppSq.Size = UDim2.fromScale(0.25, 0.80)
	oppSq.BackgroundColor3 = GameConfig.UI_COLORS.SlotSquare
	oppSq.BackgroundTransparency = 0.25
	oppSq.Text = ""
	oppSq.AutoButtonColor = false
	oppSq.ClipsDescendants = false
	oppSq.ZIndex = 9
	MatchUi.corner(oppSq, 0.18)
	UITheme.applyStroke(oppSq, 2, UITheme.Colors.Black)
	local oppSqAspect = Instance.new("UIAspectRatioConstraint")
	oppSqAspect.AspectRatio = 1.0
	oppSqAspect.DominantAxis = Enum.DominantAxis.Height
	oppSqAspect.Parent = oppSq
	oppSq.Parent = oppWrap

	local oppPlus = MatchUi.label(oppSq, "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(1, 1, 1), 24, 2, 10)

	local oppMini = Instance.new("Frame")
	oppMini.Size = UDim2.fromScale(0.86, 0.86)
	oppMini.AnchorPoint = Vector2.new(0.5, 0.5)
	oppMini.Position = UDim2.fromScale(0.5, 0.5)
	oppMini.BackgroundColor3 = Color3.fromHex("#E5252A")
	oppMini.ClipsDescendants = true
	oppMini.Visible = false
	oppMini.ZIndex = 10
	MatchUi.corner(oppMini, 0.16)
	oppMini.Parent = oppSq
	local oppFaceVp = createFaceViewport(oppMini)
	oppFaceVp.ZIndex = 11
	MatchUi.corner(oppFaceVp, 0.16)

	local oppBadge = MatchUi.label(oppSq, "80", UDim2.fromScale(0.65, 0.48), UDim2.fromScale(0.05, 0.88), Color3.fromHex("#FFD21F"), 18, 1.5, 12)
	oppBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	oppBadge.BackgroundTransparency = 0
	oppBadge.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	oppBadge.Visible = false
	MatchUi.corner(oppBadge, 0.25)

	local stealTag = Instance.new("TextButton")
	stealTag.Size = UDim2.fromScale(1.16, 0.44)
	stealTag.AnchorPoint = Vector2.new(0.5, 0.5)
	stealTag.Position = UDim2.fromScale(0.5, 0.88)
	stealTag.BackgroundColor3 = GameConfig.UI_COLORS.Steal
	stealTag.Font = UITheme.Fonts.Primary
	stealTag.TextColor3 = Color3.new(1, 1, 1)
	stealTag.TextStrokeTransparency = 0
	stealTag.TextStrokeColor3 = UITheme.Colors.Black
	stealTag.TextWrapped = false
	stealTag.TextScaled = true
	stealTag.AutoButtonColor = false
	stealTag.Text = "STEAL"
	stealTag.ZIndex = 12
	stealTag.Visible = false
	MatchUi.corner(stealTag, 0.25)
	UITheme.applyStroke(stealTag, 1.5, UITheme.Colors.Black)
	local stealTagTextConstraint = Instance.new("UITextSizeConstraint")
	stealTagTextConstraint.MinTextSize = 6
	stealTagTextConstraint.MaxTextSize = 13
	stealTagTextConstraint.Parent = stealTag
	stealTag.Parent = oppSq

	stealTag.Activated:Connect(function()
		playSfx("click")
		Remotes.MatchAction:FireServer("Steal", attr, attr)
	end)
	oppSq.Activated:Connect(function()
		if stealTag.Visible then
			playSfx("click")
			Remotes.MatchAction:FireServer("Steal", attr, attr)
		end
	end)

	local oppTextBlock = Instance.new("Frame")
	oppTextBlock.LayoutOrder = 2
	oppTextBlock.Size = UDim2.fromScale(0.75, 1)
	oppTextBlock.BackgroundTransparency = 1
	oppTextBlock.ZIndex = 8
	oppTextBlock.Parent = oppWrap

	local oppTextLayout = Instance.new("UIListLayout")
	oppTextLayout.FillDirection = Enum.FillDirection.Vertical
	oppTextLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	oppTextLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	oppTextLayout.SortOrder = Enum.SortOrder.LayoutOrder
	oppTextLayout.Padding = UDim.new(0, 0)
	oppTextLayout.Parent = oppTextBlock

	local oppTitle = MatchUi.label(oppTextBlock, `{icon} {fullLabel}`, UDim2.fromScale(1, 0.55), nil, Color3.new(1, 1, 1), 22, 2, 9)
	oppTitle.LayoutOrder = 1
	oppTitle.TextXAlignment = Enum.TextXAlignment.Left

	local oppSub = MatchUi.label(oppTextBlock, "Selecting...", UDim2.fromScale(1, 0.45), nil, Color3.fromRGB(200, 208, 222), 15, 1.5, 9)
	oppSub.LayoutOrder = 2
	oppSub.TextXAlignment = Enum.TextXAlignment.Left
	oppSub.TextTruncate = Enum.TextTruncate.AtEnd

	oppSlotRows[attr] = {
		rowFrame = oppWrap,
		squareBtn = oppSq,
		plusLabel = oppPlus,
		miniPortrait = oppMini,
		faceViewport = oppFaceVp,
		faceMount = { model = nil, modelId = nil },
		titleLabel = oppTitle,
		subLabel = oppSub,
		scoreBadge = oppBadge,
		stealTag = stealTag,
	}
end

-- 5 Bottom Action Buttons (Build phase)
local actionBar = Instance.new("Frame")
actionBar.AnchorPoint = Vector2.new(0.5, 0)
actionBar.Position = UDim2.fromScale(0.5, 0.82)
actionBar.Size = UDim2.fromScale(0.77, 0.09)
actionBar.BackgroundTransparency = 1
actionBar.ZIndex = 12
actionBar.Parent = layoutRoot

local btnReroll: TextButton
local btnSteal: TextButton
do
	local actionList = Instance.new("UIListLayout")
	actionList.FillDirection = Enum.FillDirection.Horizontal
	actionList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionList.VerticalAlignment = Enum.VerticalAlignment.Center
	actionList.SortOrder = Enum.SortOrder.LayoutOrder
	actionList.Padding = UDim.new(0.022, 0)
	actionList.Parent = actionBar

	local function makeActionButton(text: string, layoutOrder: number, bg: Color3): TextButton
		local btn = Instance.new("TextButton")
		btn.LayoutOrder = layoutOrder
		btn.Size = UDim2.fromScale(0.18, 1)
		btn.BackgroundColor3 = bg
		btn.Font = UITheme.Fonts.Primary
		btn.TextColor3 = UITheme.Colors.White
		btn.TextTransparency = 1
		btn.TextStrokeTransparency = 1
		btn.TextWrapped = false
		btn.TextScaled = true
		btn.AutoButtonColor = false
		btn.Text = text
		btn.ZIndex = 12
		MatchUi.corner(btn, 0.18)
		UITheme.applyStroke(btn, 2.5, UITheme.Colors.Black)

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.04, 0)
		pad.PaddingBottom = UDim.new(0.04, 0)
		pad.PaddingLeft = UDim.new(0.04, 0)
		pad.PaddingRight = UDim.new(0.04, 0)
		pad.Parent = btn

		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 0)
		list.Parent = btn

		local line1 = MatchUi.label(btn, "", UDim2.fromScale(1, 0.55), nil, UITheme.Colors.White, 22, 2, 13)
		line1.Name = "ActionName"
		line1.LayoutOrder = 1

		local line2 = MatchUi.label(btn, "", UDim2.fromScale(1, 0.45), nil, UITheme.Colors.White, 18, 1.5, 13)
		line2.Name = "ActionPrice"
		line2.LayoutOrder = 2

		local function syncButtonLines()
			local parts = string.split(btn.Text, "\n")
			line1.Text = parts[1] or ""
			line2.Text = parts[2] or ""
		end
		syncButtonLines()
		btn:GetPropertyChangedSignal("Text"):Connect(syncButtonLines)

		btn.Activated:Connect(function()
			playSfx("click")
		end)
		btn.Parent = actionBar
		return btn
	end

	local btnRevealAll = makeActionButton("👁️ REVEAL ALL\nR$29", 1, GameConfig.UI_COLORS.RevealAll)
	local btnSeeBest = makeActionButton("🔍 SEE BEST\nR$9", 2, GameConfig.UI_COLORS.SeeBest)
	btnReroll = makeActionButton("🎲 REROLL (2)\nR$19", 3, GameConfig.UI_COLORS.Reroll)
	btnSteal = makeActionButton("😈 STEAL (1)\nR$39", 4, GameConfig.UI_COLORS.Steal)
	local btnShuffle = makeActionButton("🔀 SHUFFLE\nFREE", 5, GameConfig.UI_COLORS.Shuffle)

	btnRevealAll.Activated:Connect(function()
		Remotes.MatchAction:FireServer("RevealAll")
	end)
	btnSeeBest.Activated:Connect(function()
		Remotes.MatchAction:FireServer("SeeBest")
	end)
	btnReroll.Activated:Connect(function()
		Remotes.MatchAction:FireServer("Reroll")
	end)
	btnShuffle.Activated:Connect(function()
		Remotes.MatchAction:FireServer("Shuffle")
	end)
	btnSteal.Activated:Connect(function()
		for _, attr in GameConfig.ATTRIBUTES do
			local sBtn = oppSlotRows[attr].stealTag
			if sBtn and sBtn.Visible then
				Remotes.MatchAction:FireServer("Steal", attr, attr)
				break
			end
		end
	end)
end

-- ============================================================

-- 2D. SHOWDOWN SCREEN (COUNTDOWN 5..1..FIGHT!, SLIDE-IN CLASH, LOSER KNOCKOUT)

-- ============================================================

local showdownWrap = Instance.new("Frame")

showdownWrap.Size = UDim2.fromScale(1, 1)

showdownWrap.BackgroundTransparency = 1

showdownWrap.Visible = false

showdownWrap.Parent = layoutRoot

local function createPortraitCard(parent: Instance, pos: UDim2, _bgCol: Color3)

	local card = Instance.new("Frame")

	card.Size = UDim2.fromOffset(180, 196)

	card.AnchorPoint = Vector2.new(0.5, 0.5)

	card.Position = pos

	card.BackgroundTransparency = 1

	card.Parent = parent

	local img = Instance.new("ImageLabel")

	img.Size = UDim2.fromOffset(168, 168)

	img.Position = UDim2.fromOffset(6, 0)

	img.BackgroundTransparency = 1

	img.ScaleType = Enum.ScaleType.Fit

	img.Parent = card

	local nameLbl = makeLabel(card, "Player", UDim2.new(0.92, 0, 0, 24), UDim2.new(0.04, 0, 1, -26), Color3.new(1, 1, 1))

	return card, img, nameLbl

end

local sdMyCard, sdMyImg, sdMyName = createPortraitCard(showdownWrap, UDim2.fromScale(0.35, 0.34), Color3.fromHex("#1E6FFF"))

local sdOppCard, sdOppImg, sdOppName = createPortraitCard(showdownWrap, UDim2.fromScale(0.65, 0.34), Color3.fromHex("#D61F1F"))

local sdVsLabel = makeLabel(showdownWrap, "VS", UDim2.fromOffset(64, 48), UDim2.new(0.5, -32, 0.34, -24), Color3.fromHex("#FFD21F"))

local sdCountdownLbl = makeLabel(showdownWrap, "5", UDim2.fromOffset(180, 74), UDim2.new(0.5, -90, 0.14, 0), Color3.new(1, 1, 1))

local sdClashSpark = makeLabel(showdownWrap, "⚽", UDim2.fromOffset(72, 72), UDim2.new(0.5, -36, 0.45, -36), Color3.new(1, 1, 1))

sdClashSpark.Visible = false

local function createAvgScoreBox(parent: Instance, pos: UDim2, bgCol: Color3)

	local box = Instance.new("Frame")

	box.Size = UDim2.fromOffset(132, 70)

	box.AnchorPoint = Vector2.new(0.5, 0.5)

	box.Position = pos

	box.BackgroundColor3 = bgCol

	addCorner(box, 10)

	addStroke(box, Color3.new(0, 0, 0), 3)

	box.Parent = parent

	makeLabel(box, "AVG SCORE", UDim2.new(0.9, 0, 0, 20), UDim2.new(0.05, 0, 0, 6), Color3.new(1, 1, 1))

	local valLbl = makeLabel(box, "0.0", UDim2.new(0.9, 0, 0, 38), UDim2.new(0.05, 0, 0, 26), Color3.fromHex("#FFD21F"))

	return box, valLbl

end

local sdMyAvgBox, sdMyAvgLbl = createAvgScoreBox(showdownWrap, UDim2.fromScale(0.35, 0.80), GameConfig.UI_COLORS.BlueAvgBox)

local sdOppAvgBox, sdOppAvgLbl = createAvgScoreBox(showdownWrap, UDim2.fromScale(0.65, 0.80), GameConfig.UI_COLORS.RedAvgBox)

-- ============================================================

-- 2E. WINNER SCREEN + GRADE SLAM + RADAR CHART + FLIP + SUMMARY POPUP

-- ============================================================

local winnerWrap = Instance.new("Frame")

winnerWrap.Size = UDim2.fromScale(1, 1)

winnerWrap.BackgroundTransparency = 1

winnerWrap.Visible = false

winnerWrap.Parent = layoutRoot

local winPortraitCard, winPortraitImg, winPortraitName = createPortraitCard(winnerWrap, UDim2.fromScale(0.50, 0.36), Color3.fromHex("#1E6FFF"))

local winCrownLabel = Instance.new("ImageLabel")

winCrownLabel.Name = "WinCrown"

winCrownLabel.Size = UDim2.fromOffset(52, 52)

winCrownLabel.Position = UDim2.new(0.5, -26, 0, -36)

winCrownLabel.BackgroundTransparency = 1

winCrownLabel.Image = UITheme.Assets.CrownIcon

winCrownLabel.ScaleType = Enum.ScaleType.Fit

winCrownLabel.ZIndex = winPortraitCard.ZIndex + 5

winCrownLabel.Parent = winPortraitCard

local winGradeBadge = makeLabel(winPortraitCard, "B", UDim2.fromOffset(42, 42), UDim2.new(1, -22, 1, -24), Color3.fromHex("#22C55E"))

winGradeBadge.BackgroundTransparency = 0

winGradeBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 34)

winGradeBadge.ZIndex = 8

addCorner(winGradeBadge, 10)

addStroke(winGradeBadge, Color3.new(0, 0, 0), 3)

local winAvgBox, winAvgValLbl = createAvgScoreBox(winnerWrap, UDim2.fromScale(0.50, 0.56), GameConfig.UI_COLORS.BlueAvgBox)

local btnFlipBoard = makeButton(winnerWrap, "", UDim2.fromOffset(70, 58), UDim2.new(0.59, 0, 0.36, -29), Color3.fromHex("#FFA500"))

do

	local ink = Color3.fromRGB(22, 24, 28)

	local icon = Instance.new("Frame")

	icon.Name = "RefreshIcon"

	icon.Size = UDim2.fromOffset(28, 26)

	icon.AnchorPoint = Vector2.new(0.5, 0)

	icon.Position = UDim2.new(0.5, 0, 0, 5)

	icon.BackgroundTransparency = 1

	icon.Parent = btnFlipBoard

	local topClip = Instance.new("Frame")

	topClip.Name = "TopArcClip"

	topClip.Size = UDim2.fromOffset(24, 10)

	topClip.Position = UDim2.fromOffset(2, 2)

	topClip.BackgroundTransparency = 1

	topClip.ClipsDescendants = true

	topClip.Parent = icon

	local topRing = Instance.new("Frame")

	topRing.Size = UDim2.fromOffset(20, 20)

	topRing.Position = UDim2.fromOffset(2, 1)

	topRing.BackgroundTransparency = 1

	topRing.Parent = topClip

	addCorner(topRing, 10)

	addStroke(topRing, ink, 3.6)

	local botClip = Instance.new("Frame")

	botClip.Name = "BotArcClip"

	botClip.Size = UDim2.fromOffset(24, 10)

	botClip.Position = UDim2.fromOffset(2, 14)

	botClip.BackgroundTransparency = 1

	botClip.ClipsDescendants = true

	botClip.Parent = icon

	local botRing = Instance.new("Frame")

	botRing.Size = UDim2.fromOffset(20, 20)

	botRing.Position = UDim2.fromOffset(2, -11)

	botRing.BackgroundTransparency = 1

	botRing.Parent = botClip

	addCorner(botRing, 10)

	addStroke(botRing, ink, 3.6)

	local function makeWing(name: string, w: number, h: number, anchor: Vector2, pos: UDim2, rot: number)

		local wing = Instance.new("Frame")

		wing.Name = name

		wing.Size = UDim2.fromOffset(w, h)

		wing.AnchorPoint = anchor

		wing.Position = pos

		wing.Rotation = rot

		wing.BackgroundColor3 = ink

		wing.BorderSizePixel = 0

		wing.Parent = icon

		local wc = Instance.new("UICorner")

		wc.CornerRadius = UDim.new(1, 0)

		wc.Parent = wing

	end

	-- Top-right clockwise arrowhead

	makeWing("ArrowTR_V", 4, 10, Vector2.new(0.5, 0.5), UDim2.fromOffset(23, 7), -14)

	makeWing("ArrowTR_H", 10, 4, Vector2.new(0.5, 0.5), UDim2.fromOffset(20, 11), 14)

	-- Bottom-left clockwise arrowhead

	makeWing("ArrowBL_V", 4, 10, Vector2.new(0.5, 0.5), UDim2.fromOffset(5, 19), -14)

	makeWing("ArrowBL_H", 10, 4, Vector2.new(0.5, 0.5), UDim2.fromOffset(8, 15), 14)

	local flipLbl = makeLabel(btnFlipBoard, "FLIP", UDim2.new(0.92, 0, 0, 22), UDim2.new(0.04, 0, 1, -24), Color3.new(1, 1, 1))

	flipLbl.Name = "FlipLabel"

end

-- Bottom-Right Roblox Badge Awarded Toast on Winner Screen

local badgeToast = Instance.new("Frame")

badgeToast.Size = UDim2.fromOffset(230, 58)

badgeToast.Position = UDim2.new(1, -246, 1, -74)

badgeToast.BackgroundColor3 = Color3.fromRGB(22, 26, 36)

badgeToast.BackgroundTransparency = 0.12

addCorner(badgeToast, 10)

addStroke(badgeToast, Color3.fromHex("#FFD21F"), 2)

badgeToast.Parent = winnerWrap

makeLabel(badgeToast, "🏅", UDim2.fromOffset(42, 42), UDim2.fromOffset(8, 8), Color3.fromHex("#FFD21F"))

local badgeToastTitle = makeLabel(badgeToast, "Badge Awarded!", UDim2.new(1, -58, 0, 22), UDim2.fromOffset(52, 6), Color3.fromHex("#FFD21F"))

badgeToastTitle.TextXAlignment = Enum.TextXAlignment.Left

local badgeToastSub = makeLabel(badgeToast, "First Match Complete!", UDim2.new(1, -58, 0, 20), UDim2.fromOffset(52, 28), Color3.new(1, 1, 1))

badgeToastSub.TextXAlignment = Enum.TextXAlignment.Left

-- 6-Axis Hexagon Radar Chart (Right side of Winner Screen)

local RADAR_SIZE = 246

local RADAR_CENTER = Vector2.new(RADAR_SIZE * 0.5, RADAR_SIZE * 0.5)

local RADAR_RADIUS = 86

local radarPanel = Instance.new("Frame")

radarPanel.Size = UDim2.fromOffset(RADAR_SIZE, RADAR_SIZE)

radarPanel.AnchorPoint = Vector2.new(0.5, 0.5)

radarPanel.Position = UDim2.fromScale(0.81, 0.45)

radarPanel.BackgroundColor3 = Color3.fromRGB(16, 20, 30)

radarPanel.BackgroundTransparency = 0.15

addCorner(radarPanel, 14)

addStroke(radarPanel, Color3.new(0, 0, 0), 3)

radarPanel.Parent = winnerWrap

local function getRadarPoint(idx: number, ratio: number): Vector2

	local angle = math.rad(-90 + (idx - 1) * 60)

	local r = RADAR_RADIUS * math.clamp(ratio, 0.08, 1)

	return RADAR_CENTER + Vector2.new(math.cos(angle) * r, math.sin(angle) * r)

end

for i = 1, 6 do

	local pOuter = getRadarPoint(i, 1)

	local pNext = getRadarPoint((i % 6) + 1, 1)

	local pMid = getRadarPoint(i, 0.55)

	local pMidNext = getRadarPoint((i % 6) + 1, 0.55)

	local axisLine = makeLine(radarPanel, Color3.fromRGB(75, 85, 110), 1)

	setLine(axisLine, RADAR_CENTER, pOuter, 1)

	local outerEdge = makeLine(radarPanel, Color3.fromRGB(95, 110, 140), 2)

	setLine(outerEdge, pOuter, pNext, 2)

	local midEdge = makeLine(radarPanel, Color3.fromRGB(60, 70, 92), 1)

	setLine(midEdge, pMid, pMidNext, 1)

	local lblPos = getRadarPoint(i, 1.24)

	local attrLbl = makeLabel(radarPanel, GameConfig.ATTRIBUTES[i], UDim2.fromOffset(42, 20), UDim2.fromOffset(lblPos.X - 21, lblPos.Y - 10), Color3.new(1, 1, 1))

	attrLbl.ZIndex = 3

end

local radarPolyEdges: { Frame } = {}

local radarSpokeLines: { Frame } = {}

local radarVertexDots: { Frame } = {}

for i = 1, 6 do

	local spoke = makeLine(radarPanel, Color3.fromHex("#F59E0B"), 2)

	spoke.ZIndex = 4

	table.insert(radarSpokeLines, spoke)

	local edge = makeLine(radarPanel, Color3.fromHex("#FFFFFF"), 3)

	edge.ZIndex = 5

	table.insert(radarPolyEdges, edge)

	local dot = Instance.new("Frame")

	dot.Size = UDim2.fromOffset(8, 8)

	dot.AnchorPoint = Vector2.new(0.5, 0.5)

	dot.BackgroundColor3 = Color3.new(1, 1, 1)

	dot.ZIndex = 6

	addCorner(dot, 4)

	dot.Parent = radarPanel

	table.insert(radarVertexDots, dot)

end

local radarAnimToken = 0

local function updateRadarChart(slotScores: { [string]: number }?, isSelf: boolean)

	radarAnimToken += 1

	local myToken = radarAnimToken

	local edgeCol = Color3.new(1, 1, 1)

	local spokeCol = if isSelf then Color3.fromHex("#F59E0B") else Color3.fromHex("#F43F5E")

	task.spawn(function()

		local steps = 12

		for step = 1, steps do

			if radarAnimToken ~= myToken then

				return

			end

			local alpha = step / steps

			local pts: { Vector2 } = {}

			for i, attr in GameConfig.ATTRIBUTES do

				local sc = if slotScores and slotScores[attr] then slotScores[attr] else 50

				pts[i] = getRadarPoint(i, (sc / 99) * alpha)

			end

			for i = 1, 6 do

				local p1 = pts[i]

				local p2 = pts[(i % 6) + 1]

				radarPolyEdges[i].BackgroundColor3 = edgeCol

				setLine(radarPolyEdges[i], p1, p2, 3)

				radarSpokeLines[i].BackgroundColor3 = spokeCol

				setLine(radarSpokeLines[i], RADAR_CENTER, p1, 2)

				radarVertexDots[i].Position = UDim2.fromOffset(p1.X, p1.Y)

			end

			task.wait(0.025)

		end

	end)

end

local rematchStatusLbl = makeLabel(winnerWrap, "0/1 - 30s", UDim2.fromOffset(180, 24), UDim2.new(0.5, -166, 0.80, 0), Color3.new(1, 1, 1))

local bottomRematchBtn = makeButton(winnerWrap, "REMATCH", UDim2.fromOffset(180, 48), UDim2.new(0.5, -166, 0.84, 0), Color3.fromHex("#FFA500"))

local rematchVoted = false

bottomRematchBtn.Activated:Connect(function()

	rematchVoted = true

	Remotes.MatchAction:FireServer("Rematch")

end)

local bottomLeaveBtn = makeButton(winnerWrap, "LEAVE", UDim2.fromOffset(140, 48), UDim2.new(0.5, 26, 0.84, 0), GameConfig.UI_COLORS.Steal)

bottomLeaveBtn.Activated:Connect(function()

	Remotes.MatchAction:FireServer("LeaveTable")

end)

-- Post-Match VICTORY! (3s) Summary Modal Popup (parented to screenGui so it displays cleanly on return to Lobby or on demand)

local lastDidWin = true

local pendingSummaryPopup = false

local summaryUI = ShopDailyUI.initSummaryPopup(screenGui, Remotes, UITheme, playSfx)

-- Helper to populate a slot row in Build, Showdown, or Winner mode

local function populateSlotRow(row: SlotRow, card: any, defaultSub: string, showScore: boolean, scoreVal: number?)

	if card then

		row.plusLabel.Visible = false

		row.miniPortrait.Visible = true

		row.miniPortrait.BackgroundColor3 = Color3.fromHex(card.kitColor):Lerp(Color3.fromRGB(36, 44, 62), 0.32)

		mountViewportModel(row.faceViewport, row.faceMount, card.id)

		row.subLabel.Text = Footballers.getDisplayName(card)

		row.subLabel.TextColor3 = Color3.new(1, 1, 1)

		row.squareBtn.BackgroundColor3 = GameConfig.UI_COLORS.SlotSquare

	else

		row.plusLabel.Visible = true

		row.miniPortrait.Visible = false

		mountViewportModel(row.faceViewport, row.faceMount, nil)

		row.subLabel.Text = defaultSub

		row.subLabel.TextColor3 = Color3.fromRGB(200, 208, 222)

		row.squareBtn.BackgroundColor3 = GameConfig.UI_COLORS.SlotSquare

	end

	row.scoreBadge.Visible = showScore

	if showScore and scoreVal then

		row.scoreBadge.Text = tostring(scoreVal)

	end

end

-- Winner Screen Inspection State (supports FLIP button)

local lastResultState: any = nil

local inspectingSelf = true

local function refreshWinnerInspection(animateSlam: boolean?)

	local st = lastResultState

	if not st then

		return

	end

	local isSelf = inspectingSelf

	local board = if isSelf then st.myBoard else st.oppBoard

	local eval = if isSelf then st.myEval else st.oppEval

	local name = if isSelf then (st.myName or "YOU") else (st.oppName or "OPPONENT")

	local uid = if isSelf then st.myUserId else st.oppUserId

	local isThisWinner = (isSelf and st.didWin) or (not isSelf and not st.didWin)

	modeSubLabel.Visible = true

	if st.didWin then

		modeSubLabel.Text = "🏆 VICTORY!"

		modeSubLabel.TextColor3 = Color3.fromHex("#3DDC3D")

	else

		modeSubLabel.Text = `DEFEAT • WINNER: {st.oppName or "BOT"}`

		modeSubLabel.TextColor3 = Color3.fromHex("#FFD21F")

	end

	headerLabel.Text = if isSelf then "YOUR RESULT" else "OPPONENT RESULT"

	headerLabel.TextColor3 = if isSelf then Color3.fromHex("#FFD21F") else Color3.fromHex("#FF6B6B")

	winnerNameLabel.Visible = true

	winnerNameLabel.Text = name

	winPortraitImg.Image = getAvatarThumb(uid)

	winPortraitName.Text = name

	winCrownLabel.Visible = isThisWinner

	local grade = if eval then eval.grade else "C"

	winGradeBadge.Text = grade

	winGradeBadge.TextColor3 = if grade == "S" or grade == "A" then Color3.fromHex("#22C55E") else Color3.fromHex("#FFD21F")

	winAvgBox.BackgroundColor3 = if isSelf then GameConfig.UI_COLORS.BlueAvgBox else GameConfig.UI_COLORS.RedAvgBox

	winAvgValLbl.Text = if eval then tostring(eval.avgScore) else "0.0"

	leftStatPanel.Visible = true
	for idx, attr in GameConfig.ATTRIBUTES do
		local row = mySlotRows[attr]

		row.rowFrame.Visible = true

		local card = if board and board.slots then board.slots[attr] else nil

		local score = if eval and eval.slotScores then eval.slotScores[attr] else 0

		populateSlotRow(row, card, "-", true, score)

		if animateSlam then

			row.scoreBadge.Visible = false

			task.delay(0.1 * idx, function()

				if currentPhase == "Result" then

					row.scoreBadge.Visible = true

					popGui(row.scoreBadge, 0.45)

				end

			end)

		end

	end

	updateRadarChart(if eval then eval.slotScores else nil, isSelf)

	popGui(winPortraitCard, 0.85)

	if animateSlam then

		popGui(winGradeBadge, 2.4)

	else

		popGui(winGradeBadge, 1.35)

	end

end

btnFlipBoard.Activated:Connect(function()

	inspectingSelf = not inspectingSelf

	refreshWinnerInspection(false)

end)

-- ============================================================

-- 3. STATE SYNC & LIVE TIMERS

-- ============================================================

local function setMyColumnVisible(vis: boolean)
	leftStatPanel.Visible = vis
	for _, attr in GameConfig.ATTRIBUTES do
		mySlotRows[attr].rowFrame.Visible = vis
	end
end

local function setOppColumnVisible(vis: boolean)
	rightStatPanel.Visible = vis
	for _, attr in GameConfig.ATTRIBUTES do
		oppSlotRows[attr].rowFrame.Visible = vis
		if not vis and oppSlotRows[attr].stealTag then
			oppSlotRows[attr].stealTag.Visible = false
		end
	end
end

local function refreshObbyPrompt(now: number)

	local lobby = Workspace:FindFirstChild("Lobby")

	local obby = if lobby then lobby:FindFirstChild("AgilityObby") else nil

	local finish = if obby then obby:FindFirstChild("ObbyFinish") else nil

	if not finish then

		return

	end

	local nextAt = (localPlayer:GetAttribute("ObbyNextClaimAt") :: number?) or 0

	if nextAt <= 0 and cachedProfile and (cachedProfile.LastObbyClaim or 0) > 0 then

		nextAt = cachedProfile.LastObbyClaim + GameConfig.OBBY_COOLDOWN_SEC

	end

	local rem = nextAt - now

	local prompt = finish:FindFirstChildOfClass("ProximityPrompt")

	local bb = finish:FindFirstChildOfClass("BillboardGui")

	local lbl = if bb then bb:FindFirstChildOfClass("TextLabel") else nil

	if rem > 0 then

		local cd = formatHHMMSS(rem)

		if prompt then

			prompt.ActionText = `Cooldown {cd}`

		end

		if lbl then

			lbl.Text = `⏳ COOLDOWN\n{cd}`

			lbl.TextColor3 = Color3.fromHex("#FFD21F")

		end

	else

		if prompt then

			prompt.ActionText = `Claim +${GameConfig.OBBY_REWARD_BUX}!`

		end

		if lbl then

			lbl.Text = `🎁 FREE GIFT!\n+${GameConfig.OBBY_REWARD_BUX}`

			lbl.TextColor3 = Color3.fromHex("#3DDC3D")

		end

	end

end

local function refreshMetaUI()

	local now = Workspace:GetServerTimeNow()

	refreshObbyPrompt(now)

	local p = cachedProfile

	if not p then

		return

	end

	if HUD.updateCash then HUD.updateCash(p.Bux or 0) else cashLabel.Text = `$` .. tostring(p.Bux) end

	local boostPct = (localPlayer:GetAttribute("FriendsBoostPct") :: number?) or 0

	if HUD.updateFriends then HUD.updateFriends(boostPct) else friendsLabel.Text = `FRIENDS BOOST: +{boostPct}%` end

	wheelHandler.update(p, now)

	if luckUpgradeBtn then
		local curLuck = p.Luck or 1
		local nextLuck = GameConfig.getNextLuckTier(curLuck)
		local luckLbl = luckUpgradeBtn:FindFirstChild("BtnLabel") :: TextLabel?
		if nextLuck then
			local txt = `LUCK: {curLuck}x → {nextLuck.luck}x (${nextLuck.cost})`
			if luckLbl then luckLbl.Text = txt else luckUpgradeBtn.Text = txt end
			UITheme.styleButton(luckUpgradeBtn, if p.Bux >= nextLuck.cost then "Lime" else "Gray", 8)
		else
			local txt = `LUCK: {curLuck}x (MAX)`
			if luckLbl then luckLbl.Text = txt else luckUpgradeBtn.Text = txt end
			UITheme.styleButton(luckUpgradeBtn, "Gold", 8)
		end
	end

	local elapsed = math.max(0, now - (p.SessionJoinTime or now))
	local readyPlaytimeCount = 0
	local nextPtRem = 0
	for _, pt in GameConfig.PLAYTIME_REWARDS do
		local claimed = p.PlaytimeClaimed and p.PlaytimeClaimed[pt.id]
		if not claimed then
			if elapsed >= pt.seconds then
				readyPlaytimeCount += 1
			elseif nextPtRem == 0 then
				nextPtRem = pt.seconds - elapsed
			end
		end
	end

	-- 1. Free Rewards (Daily, Group, Playtime)
	local freeStatus = freeRewardsHandler and freeRewardsHandler.update(p, now)
	if freeStatus then
		freeBadge.Visible = freeStatus.readyTotal > 0
		freeBadge.Text = tostring(freeStatus.readyTotal)
	end

		-- 4. Quests
	local readyQuests = 0
	if questsHandler then
		readyQuests = questsHandler.update(p)
	end
	questBadge.Visible = readyQuests > 0
	questBadge.Text = tostring(readyQuests)

	-- 5. Skins
	if skinsHandler then
		skinsHandler.update(p)
	end

	local nextSkinNeeded = 0

	for _, skin in GameConfig.CHAIR_SKINS do

		local b = skinActionBtns[skin.id]

		if b then

			local owned = p.OwnedChairs and p.OwnedChairs[skin.id]

			if not owned and skin.cost > 0 and nextSkinNeeded == 0 then

				nextSkinNeeded = math.max(0, skin.cost - p.Bux)

			end

			if p.EquippedChair == skin.id then

				UITheme.skinButton(b, "EQUIPPED", skin.cost, true)

			elseif owned then

				UITheme.skinButton(b, "EQUIP", skin.cost, true)

			else

				local canAfford = (p.Bux >= skin.cost)

				UITheme.skinButton(b, "BUY", skin.cost, canAfford)

			end

		end

	end

	-- 5b. Shop Gamepass Ownership (Reactive OWNED badges)

	shopHandler.updateGamepasses(p)

	if titlesHandler then
		titlesHandler.update(p)
	end

	-- 7. Card Index (152 Footballers)

	local disc = p.DiscoveredCards or {}

	local discCount = 0

	for cardId, cellInfo in indexCardCells do

		local c = cellInfo.card

		if disc[cardId] then

			discCount += 1

			cellInfo.frame.BackgroundColor3 = Color3.fromRGB(32, 42, 60)

			cellInfo.label.TextColor3 = GameConfig.RARITY_COLORS[c.rarity]

			cellInfo.label.Text = `{c.ovr} {c.pos}\n{Footballers.getDisplayName(c)}\n{string.upper(c.rarity)}`

		else

			cellInfo.frame.BackgroundColor3 = UITheme.Colors.CardBg

			cellInfo.label.TextColor3 = Color3.fromRGB(140, 145, 160)

			cellInfo.label.Text = `??? {c.pos}\nLOCKED\n{string.upper(c.rarity)}`

		end

	end

	local pct = math.round((discCount / #Footballers.All) * 100)

	indexProgressHeader.Text = `DISCOVERED: {discCount} / {#Footballers.All} ({pct}%) • +$25–$250 PER NEW CARD!`

	local ib = btnNavIndex:FindFirstChild("IndexBadge") :: TextLabel?

	if ib then

		ib.Text = `{discCount}/{#Footballers.All}`

	end

	-- 8. Player Profile & Stats Tracker

	updateProfilePage(p, elapsed, disc, discCount, pct)

	local minsPlayed = math.min(30, math.floor(elapsed / 60))

	summaryUI.sumPlay30Val.Text = tostring(minsPlayed) .. "/30 MIN"

	summaryUI.sumPlay30Fill.Size = UDim2.fromScale(math.clamp(elapsed / 1800, 0, 1), 1)

	local ptReady = readyPlaytimeCount > 0

	summaryUI.sumNextPtVal.Text = if ptReady then "READY TO CLAIM!" else formatMMSS(nextPtRem) .. " LEFT"

	summaryUI.sumNextPtVal.TextColor3 = if ptReady then UITheme.CONFIG.Colors.MoneyLime else UITheme.CONFIG.Colors.DescriptionGold

	local skinReady = nextSkinNeeded <= 0

	summaryUI.sumNextSkinVal.Text = if not skinReady then "$" .. tostring(nextSkinNeeded) .. " MORE" else "READY / UNLOCKED!"

	summaryUI.sumNextSkinVal.TextColor3 = if skinReady then UITheme.CONFIG.Colors.MoneyLime else UITheme.CONFIG.Colors.DescriptionGold

	summaryUI.sumFooterLabel.Text = tostring(p.MatchesPlayed or 1) .. " MATCH PLAYED \u{2022} " .. tostring(p.Wins or 0) .. " WON"

end

local refreshMythicalVoteUI: () -> ()

do

local function setupMythicalVoteUI()

	-- Backdrop (click outside to close)

	local voteBackdrop = Instance.new("TextButton")

	voteBackdrop.Name = "VoteLockedBackdrop"

	voteBackdrop.Size = UDim2.fromScale(1, 1)

	voteBackdrop.Position = UDim2.fromScale(0, 0)

	voteBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)

	voteBackdrop.BackgroundTransparency = 0.55

	voteBackdrop.Text = ""

	voteBackdrop.AutoButtonColor = false

	voteBackdrop.ZIndex = 48

	voteBackdrop.Visible = false

	voteBackdrop.Parent = screenGui

	local voteLockedModal = Instance.new("Frame")

	voteLockedModal.Name = "VoteLockedModal"

	voteLockedModal.Size = UDim2.fromOffset(480, 360)

	voteLockedModal.AnchorPoint = Vector2.new(0.5, 0.5)

	voteLockedModal.Position = UDim2.fromScale(0.5, 0.5)

	voteLockedModal.BackgroundColor3 = UITheme.Colors.WindowBody

	voteLockedModal.ZIndex = 50

	voteLockedModal.Visible = false

	UITheme.addCorner(voteLockedModal, 16)

	UITheme.applyStroke(voteLockedModal, 4, UITheme.Colors.Black)

	UITheme.addStuds(voteLockedModal, 0.90, 24)

	voteLockedModal.Parent = screenGui

	local modalScale = Instance.new("UIScale")

	modalScale.Scale = 1

	modalScale.Parent = voteLockedModal

	local header = Instance.new("Frame")

	header.Name = "Header"

	header.Size = UDim2.new(1, 0, 0, 56)

	header.ZIndex = 51

	UITheme.styleHeader(header, "Orange", "VOTE LOCKED", "Play 5 minutes to unlock your vote")

	header.Parent = voteLockedModal

	local btnCloseVote = Instance.new("TextButton")

	btnCloseVote.Name = "CloseBtn"

	btnCloseVote.Size = UDim2.fromOffset(40, 40)

	btnCloseVote.Position = UDim2.new(1, -48, 0, 8)

	btnCloseVote.Text = "✕"

	btnCloseVote.ZIndex = 52

	UITheme.styleButton(btnCloseVote, "Red", 8)

	btnCloseVote.Parent = header

	local candidateLbl = makeLabel(voteLockedModal, "Voting for: ⚽ LIONEL MESSI", UDim2.new(0.92, 0, 0, 26), UDim2.new(0.04, 0, 0, 66), Color3.fromHex("#38BDF8"))

	candidateLbl.ZIndex = 51

	local clockIcon = Instance.new("ImageLabel")

	clockIcon.Name = "ClockIcon"

	clockIcon.Size = UDim2.fromOffset(36, 36)

	clockIcon.Position = UDim2.new(0.24, 0, 0, 100)

	clockIcon.BackgroundTransparency = 1

	clockIcon.Image = UITheme.Assets.ClockIcon

	clockIcon.ZIndex = 51

	clockIcon.Parent = voteLockedModal

	local countdownLbl = Instance.new("TextLabel")

	countdownLbl.Name = "CountdownLabel"

	countdownLbl.Size = UDim2.new(0.44, 0, 0, 40)

	countdownLbl.Position = UDim2.new(0.34, 0, 0, 98)

	countdownLbl.BackgroundTransparency = 1

	countdownLbl.Font = UITheme.Fonts.Titles

	countdownLbl.TextColor3 = UITheme.Colors.White

	countdownLbl.TextScaled = true

	countdownLbl.Text = "05:00"

	countdownLbl.ZIndex = 51

	UITheme.applyTextStroke(countdownLbl, 3, UITheme.Colors.Black)

	countdownLbl.Parent = voteLockedModal

	local progressRail = Instance.new("Frame")

	progressRail.Name = "ProgressRail"

	progressRail.Size = UDim2.new(0.88, 0, 0, 20)

	progressRail.Position = UDim2.new(0.06, 0, 0, 148)

	progressRail.BackgroundColor3 = Color3.fromRGB(24, 28, 38)

	progressRail.ZIndex = 51

	progressRail.ClipsDescendants = true

	UITheme.addCorner(progressRail, 10)

	UITheme.applyStroke(progressRail, 2.5, UITheme.Colors.Black)

	progressRail.Parent = voteLockedModal

	local progressFill = Instance.new("Frame")

	progressFill.Name = "ProgressFill"

	progressFill.Size = UDim2.new(0, 0, 1, 0)

	progressFill.BackgroundColor3 = UITheme.Colors.LimeTop

	progressFill.ZIndex = 52

	UITheme.addCorner(progressFill, 10)

	UITheme.applyGradient(progressFill, UITheme.Colors.LimeTop, UITheme.Colors.LimeBottom, 90)

	progressFill.Parent = progressRail

	local descLbl = Instance.new("TextLabel")

	descLbl.Name = "DescLabel"

	descLbl.Size = UDim2.new(0.88, 0, 0, 36)

	descLbl.Position = UDim2.new(0.06, 0, 0, 176)

	descLbl.BackgroundTransparency = 1

	descLbl.Font = UITheme.Fonts.Body

	descLbl.TextSize = 14

	descLbl.TextColor3 = Color3.fromRGB(210, 218, 235)

	descLbl.TextWrapped = true

	descLbl.Text = "You can vote once you've played for 5 minutes in this server. Keep playing!"

	descLbl.ZIndex = 51

	UITheme.applyTextStroke(descLbl, 1.5, UITheme.Colors.Black)

	descLbl.Parent = voteLockedModal

	local btnVoteAction = Instance.new("TextButton")

	btnVoteAction.Name = "VoteActionButton"

	btnVoteAction.Size = UDim2.new(0.88, 0, 0, 52)

	btnVoteAction.Position = UDim2.new(0.06, 0, 0, 220)

	btnVoteAction.ZIndex = 51

	UITheme.styleButton(btnVoteAction, "Gray", 10)

	btnVoteAction.Text = "VOTE (05:00)"

	btnVoteAction.Parent = voteLockedModal

	local friendlyFooter = Instance.new("TextLabel")

	friendlyFooter.Name = "FriendlyFooter"

	friendlyFooter.Size = UDim2.new(0.92, 0, 0, 22)

	friendlyFooter.Position = UDim2.new(0.04, 0, 0, 286)

	friendlyFooter.BackgroundTransparency = 1

	friendlyFooter.Font = UITheme.Fonts.Body

	friendlyFooter.TextSize = 12

	friendlyFooter.TextColor3 = Color3.fromRGB(156, 163, 175)

	friendlyFooter.Text = "👍 Enjoying the game? Tap the thumbs-up on the game page!"

	friendlyFooter.ZIndex = 51

	UITheme.applyTextStroke(friendlyFooter, 1.5, UITheme.Colors.Black)

	friendlyFooter.Parent = voteLockedModal

	local pendingVoteChoice = "A"

	local isUnlocked = false

	local voteClickDebounce = false

	local countdownThreadToken = 0

	local function closeVoteModal()

		countdownThreadToken += 1

		voteLockedModal.Visible = false

		voteBackdrop.Visible = false

	end

	local function openVoteLockedPopup(payload: any)

		local choice = if type(payload) == "table" then tostring(payload.candidateId or "A") else tostring(payload or "A")

		pendingVoteChoice = if (choice == "A" or choice == "Messi") then "A" else "B"

		local name = if pendingVoteChoice == "A" then "⚽ LIONEL MESSI" else "⚽ CRISTIANO RONALDO"

		local col = if pendingVoteChoice == "A" then Color3.fromHex("#38BDF8") else Color3.fromHex("#FBBF24")

		candidateLbl.Text = `Voting for: {name}`

		candidateLbl.TextColor3 = col

		voteBackdrop.Visible = true

		voteLockedModal.Visible = true

		modalScale.Scale = 0.85

		TweenService:Create(modalScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

			Scale = 1,

		}):Play()

		countdownThreadToken += 1

		local myToken = countdownThreadToken

		task.spawn(function()

			while voteLockedModal.Visible and countdownThreadToken == myToken do

				local sessionStart = (localPlayer:GetAttribute("SessionStart") :: number?) or Workspace:GetServerTimeNow()

				local elapsed = math.max(0, math.floor(Workspace:GetServerTimeNow() - sessionStart))

				local remaining = math.max(0, math.ceil(VoteConfig.MIN_SESSION_SECONDS - elapsed))

				local mm = math.floor(remaining / 60)

				local ss = remaining % 60

				local timeStr = string.format("%02d:%02d", mm, ss)

				countdownLbl.Text = timeStr

				local progress = math.clamp(elapsed / VoteConfig.MIN_SESSION_SECONDS, 0, 1)

				progressFill.Size = UDim2.fromScale(progress, 1)

				if remaining <= 0 then

					if not isUnlocked then

						isUnlocked = true

						UITheme.styleButton(btnVoteAction, "Lime", 10)

						btnVoteAction.Text = "VOTE NOW!"

						UITheme.addPulse(btnVoteAction, 1.0, 1.04, 0.8)

					end

				else

					isUnlocked = false

					btnVoteAction.Text = `VOTE ({timeStr})`

				end

				task.wait(1)

			end

		end)

	end

	btnCloseVote.Activated:Connect(closeVoteModal)

	voteBackdrop.Activated:Connect(closeVoteModal)

	btnVoteAction.Activated:Connect(function()

		if not isUnlocked then

			return

		end

		if voteClickDebounce then

			return

		end

		voteClickDebounce = true

		task.delay(1.5, function()

			voteClickDebounce = false

		end)

		closeVoteModal()

		Remotes.RequestVote:FireServer(pendingVoteChoice)

		Remotes.MetaAction:FireServer("VoteMythical", pendingVoteChoice)

		playSfx("win")

	end)

	UserInputService.InputBegan:Connect(function(input, processed)

		if processed then return end

		if input.KeyCode == Enum.KeyCode.Escape and voteLockedModal.Visible then

			closeVoteModal()

		end

	end)

	localPlayer.CharacterAdded:Connect(function()

		closeVoteModal()

	end)

	Remotes.OpenVoteLockedPopup.OnClientEvent:Connect(function(payload)

		openVoteLockedPopup(payload)

	end)

	Remotes.MetaAction.OnClientEvent:Connect(function(action, arg)

		if action == "RequireLikeToVote" or action == "OpenVoteLockedPopup" then

			openVoteLockedPopup(tostring(arg or "A"))

		elseif action == "Toast" and typeof(arg) == "string" then

			showToast(arg)

		end

	end)

	-- Session 5-minute unlock global toast notification

	if VoteConfig.NOTIFY_WHEN_UNLOCKED then

		task.spawn(function()

			local hasNotifiedUnlock = false

			while not hasNotifiedUnlock do

				local start = localPlayer:GetAttribute("SessionStart") :: number?

				if start then

					local elapsed = Workspace:GetServerTimeNow() - start

					if elapsed >= VoteConfig.MIN_SESSION_SECONDS then

						hasNotifiedUnlock = true

						showToast("You can now vote!")

						break

					end

				end

				task.wait(2)

			end

		end)

	end

	-- Optional anti-AFK activity ping (client throttled to at most once per 10s)

	if VoteConfig.COUNT_ONLY_ACTIVE_TIME then

		local lastPingSent = 0

		local function reportActivity()

			local now = Workspace:GetServerTimeNow()

			if now - lastPingSent >= 10 then

				lastPingSent = now

				Remotes.ActivityPing:FireServer()

			end

		end

		UserInputService.InputBegan:Connect(function(_input, _processed)

			reportActivity()

		end)

	end

	refreshMythicalVoteUI = function()

		local lobby = Workspace:FindFirstChild("Lobby")

		local voteModel = if lobby then (lobby:FindFirstChild("NextMythicalVote") or (lobby:FindFirstChild("Zones") and lobby.Zones:FindFirstChild("NextMythicalVote"))) else nil

		if not voteModel then

			return

		end

		local myVote = localPlayer:GetAttribute("MythicalVote") :: string?

		local function syncPad(padName: string, voteKey: string)

			local pad = voteModel:FindFirstChild(padName)

			if not pad then

				return

			end

			local bb = pad:FindFirstChild("VotePadBillboard")

			local tag = if bb then bb:FindFirstChild("YourVoteTag") :: TextLabel? else nil

			if tag then

				tag.Visible = (myVote == voteKey)

			end

			local prompt = pad:FindFirstChildOfClass("ProximityPrompt")

			if prompt then

				prompt.ActionText = if myVote == voteKey then "Already Voted" else "Vote"

			end

		end

		syncPad("VotePadA", "Messi")

		syncPad("VotePadB", "Ronaldo")

		local board = voteModel:FindFirstChild("VoteBoard")

		local sg = if board then board:FindFirstChild("VoteBoardGui") else nil

		if sg then

			local statusLbl = sg:FindFirstChild("PlayerVoteStatus", true) :: TextLabel?

			if statusLbl then

				if myVote == "Messi" then

					statusLbl.Text = "(YOUR VOTE: LIONEL MESSI)"

					statusLbl.TextColor3 = Color3.fromHex("#38BDF8")

				elseif myVote == "Ronaldo" then

					statusLbl.Text = "(YOUR VOTE: CRISTIANO RONALDO)"

					statusLbl.TextColor3 = Color3.fromHex("#FBBF24")

				else

					statusLbl.Text = "(STEP ON A PAD OR PRESS [E] TO VOTE!)"

					statusLbl.TextColor3 = Color3.new(1, 1, 1)

				end

			end

		end

	end

	localPlayer:GetAttributeChangedSignal("MythicalVote"):Connect(refreshMythicalVoteUI)

	localPlayer:GetAttributeChangedSignal("LikedGame"):Connect(refreshMythicalVoteUI)

	task.defer(refreshMythicalVoteUI)

end

setupMythicalVoteUI()

end -- setupMythicalVoteUI

local lastTick = 0

local lastCountdownText = ""

do

local function setupWheelZone()

	local insideWheelZone = false

	local cachedSpinCenter: BasePart? = nil

	local function getSpinCenter(): BasePart?

		if cachedSpinCenter and cachedSpinCenter.Parent then

			return cachedSpinCenter

		end

		local lobby = Workspace:FindFirstChild("Lobby")

		cachedSpinCenter = if lobby then (lobby:FindFirstChild("SpinTriggerCenter", true) :: BasePart?) else (Workspace:FindFirstChild("SpinTriggerCenter", true) :: BasePart?)

		return cachedSpinCenter

	end

	local PPS = game:GetService("ProximityPromptService")

	PPS.PromptTriggered:Connect(function(prompt, player)

		if player == localPlayer and prompt.Name == "SpinPrompt" then

			openModal("WHEEL")

		end

	end)

	local function checkWheelZone()

		if currentPhase ~= "Idle" then return end

		local centerPart = getSpinCenter()

		local hrp = if localPlayer.Character then localPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

		if centerPart and hrp then

			local radius = math.max((centerPart:GetAttribute("Radius") :: number?) or 4.6, 5.5)

			local dx = hrp.Position.X - centerPart.Position.X

			local dz = hrp.Position.Z - centerPart.Position.Z

			local distXZ = math.sqrt(dx * dx + dz * dz)

			if not insideWheelZone and distXZ <= radius then

				insideWheelZone = true

				openModal("WHEEL")

			elseif insideWheelZone and distXZ > radius + 2.0 then

				insideWheelZone = false

				if wheelHandler.isOpen() and not wheelHandler.isSpinning() then

					wheelHandler.close()

				end

			end

		end

	end

	RunService.Heartbeat:Connect(checkWheelZone)

end

setupWheelZone()

end -- setupWheelZone

RunService.Heartbeat:Connect(function()

	local now = Workspace:GetServerTimeNow()

	if currentPhase ~= "Idle" then

		if opponentAlertBanner.Visible then

			opponentAlertBanner.Visible = false

		end

	end

	if currentPhase ~= "Idle" and activeEndsAt > 0 then

		local remFloat = math.max(0, activeEndsAt - now)

		local rem = math.ceil(remFloat)

		if currentPhase == "Build" and currentSubPhase == "Rolling" then

			-- Timer stays frozen during ROLLING... subPhase

		else

			timerLabel.Text = `{rem}`

		end

		if currentPhase == "Countdown" then

			local cdText = if remFloat > 2.4

				then "3"

				elseif remFloat > 1.5 then "2"

				elseif remFloat > 0.6 then "1"

				else "GO!"

			if cdText ~= lastCountdownText then

				lastCountdownText = cdText

				countdownBigLabel.Text = cdText

				countdownBigLabel.TextColor3 = if cdText == "GO!" then Color3.fromHex("#3DDC3D") else Color3.new(1, 1, 1)

				popGui(countdownBigLabel, 1.55)

				playSfx("reveal")

			end

		elseif currentPhase == "Result" then

			local prefix = if rematchVoted then `1/1 - {rem}s` else `0/1 - {rem}s`

			rematchStatusLbl.Text = prefix

		end

	end

	if now - lastTick >= 1 then

		lastTick = now

		refreshMetaUI()

		refreshMythicalVoteUI()

	end

end)

Remotes.ProfileUpdate.OnClientEvent:Connect(function(profile: any, _title: string, toast: string?)

	cachedProfile = profile

	local seq = (localPlayer:GetAttribute("WheelSpinSeq") :: number?) or 0

	if seq > lastHandledWheelSeq then

		lastHandledWheelSeq = seq

		local sliceIdx = (localPlayer:GetAttribute("LastWheelSlice") :: number?) or 1

		wheelHandler.playSpinAnimation(sliceIdx, function()

			refreshMetaUI()

			if toast and #toast > 0 then

				showToast(toast)

			end

		end)

		refreshMetaUI()

		return

	end

	refreshMetaUI()

	if toast and #toast > 0 then

		showToast(toast)

	end

end)

Remotes.OpponentAlert.OnClientEvent:Connect(function(payload: any)

	if typeof(payload) ~= "table" then

		return

	end

	if payload.active == true and typeof(payload.tableId) == "string" then

		if currentPhase ~= "Idle" then

			return

		end

		activeAlertTableId = payload.tableId

		alertTitleLbl.Text = `{payload.hostName or "Player"} needs an opponent...`

		alertAvatarImg.Image = getAvatarThumb(payload.hostUserId)

		opponentAlertBanner.Visible = true

		popGui(opponentAlertBanner, 0.90)

		playSfx("rare")

	elseif payload.active == false then

		if payload.tableId == nil or payload.tableId == activeAlertTableId then

			opponentAlertBanner.Visible = false

			activeAlertTableId = nil

		end

	end

end)

local refreshAllSpectateBillboards: () -> () = function() end

local closeFeedbackModal: () -> () = function() end

local openFeedbackModal: () -> () = function() end

Remotes.MatchState.OnClientEvent:Connect(function(state: any)

	local prevPhase = currentPhase

	currentPhase = state.phase

	currentSubPhase = state.subPhase or ""

	setBgmPhase(state.phase)

	game:GetService("ProximityPromptService").Enabled = (state.phase == "Idle")

	refreshAllSpectateBillboards()

	if state.phase == "Idle" then

		currentPlacedThisRound = false

		overlay.Visible = false

		lobbyHud.Visible = true

		activeEndsAt = 0

		rollingToken += 1

		showdownToken += 1

		setMatchBlur(false)

		focusTableCamera(nil, "Idle")

		if prevPhase == "Result" and pendingSummaryPopup then

			pendingSummaryPopup = false

			summaryUI.show(lastDidWin)

		end

		return

	end

	overlay.Visible = true

	modalWrap.Visible = false

	shopWindow.Visible = false

	closeFeedbackModal()

	if typeof(state.endsAt) == "number" and state.endsAt > 0 then

		activeEndsAt = state.endsAt

	elseif typeof(state.rematchEndsAt) == "number" and state.rematchEndsAt > 0 then

		activeEndsAt = state.rematchEndsAt

	end

	-- 1. SEATED WAITING SCREEN

	if state.phase == "Waiting" then

		setMatchBlur(false)

		overlay.BackgroundTransparency = 0.55

		lobbyHud.Visible = false

		modeSubLabel.Visible = true

		modeSubLabel.Text = "MEJA PERTANDINGAN"

		headerLabel.Visible = true

		headerLabel.Text = "MENUNGGU LAWAN... (BOT MASUK DALAM 3 DETIK)"

		winnerNameLabel.Visible = false

		timerLabel.Visible = false

		waitingWrap.Visible = true

		introWrap.Visible = false

		countdownWrap.Visible = false

		buildCenterWrap.Visible = false

		showdownWrap.Visible = false

		winnerWrap.Visible = false

		actionBar.Visible = false

		rolledInfoLabel.Visible = false

		setMyColumnVisible(false)

		setOppColumnVisible(false)

		focusTableCamera(state.tablePos, "Build")

		return

	end

	waitingWrap.Visible = false

	-- 2. MATCH INTRO ("<PlayerA> VS <PlayerB/BOT> / DEFAULT MODE")

	if state.phase == "Intro" then

		setMatchBlur(false)

		overlay.BackgroundTransparency = 1

		lobbyHud.Visible = false

		modeSubLabel.Visible = false

		headerLabel.Visible = false

		winnerNameLabel.Visible = false

		timerLabel.Visible = false

		introWrap.Visible = true

		countdownWrap.Visible = false

		buildCenterWrap.Visible = false

		showdownWrap.Visible = false

		winnerWrap.Visible = false

		actionBar.Visible = false

		rolledInfoLabel.Visible = false

		setMyColumnVisible(false)

		setOppColumnVisible(false)

		focusTableCamera(state.tablePos, "Build")

		introMyName.Text = state.myName or localPlayer.Name

		introOppName.Text = state.oppName or "BOT"

		introOppName.TextColor3 = if state.oppName == "BOT" then Color3.fromHex("#FF2E93") else Color3.fromHex("#D61F1F")

		introMyName.Visible = true

		introVs.Visible = false

		introOppName.Visible = false

		introMode.Visible = false

		popGui(introMyName, 0.3)

		playSfx("reveal")

		task.delay(0.32, function()

			if currentPhase == "Intro" then

				introVs.Visible = true

				popGui(introVs, 0.3)

			end

		end)

		task.delay(0.64, function()

			if currentPhase == "Intro" then

				introOppName.Visible = true

				popGui(introOppName, 0.3)

				playSfx("reveal")

			end

		end)

		task.delay(0.96, function()

			if currentPhase == "Intro" then

				introMode.Visible = true

				popGui(introMode, 0.4)

			end

		end)

		return

	end

	introWrap.Visible = false

	-- 3. COUNTDOWN SCREEN ("3, 2, 1, GO!" with strong BlurEffect)

	if state.phase == "Countdown" then

		setMatchBlur(true)

		overlay.BackgroundTransparency = 0.35

		lobbyHud.Visible = false

		modeSubLabel.Visible = true

		modeSubLabel.Text = "DEFAULT MODE"

		modeSubLabel.TextColor3 = Color3.new(1, 1, 1)

		headerLabel.Visible = true

		headerLabel.Text = "BUILD A FOOTBALLER"

		headerLabel.TextColor3 = Color3.new(1, 1, 1)

		winnerNameLabel.Visible = false

		timerLabel.Visible = false

		countdownWrap.Visible = true

		buildCenterWrap.Visible = false

		showdownWrap.Visible = false

		winnerWrap.Visible = false

		actionBar.Visible = false

		rolledInfoLabel.Visible = false

		setMyColumnVisible(false)

		setOppColumnVisible(false)

		lastCountdownText = ""

		focusTableCamera(state.tablePos, "Build")

		return

	end

	countdownWrap.Visible = false

	setMatchBlur(true)

	overlay.BackgroundTransparency = 0.35

	lobbyHud.Visible = false

	-- 4. BUILD SCREEN (6-ROUND ROLLING -> SELECTING)

	if state.phase == "Build" then

		focusTableCamera(state.tablePos, "Build")

		modeSubLabel.Visible = true

		modeSubLabel.Text = "DEFAULT MODE"

		modeSubLabel.TextColor3 = Color3.new(1, 1, 1)

		headerLabel.Visible = true

		headerLabel.Text = "BUILD A FOOTBALLER"

		headerLabel.TextColor3 = Color3.new(1, 1, 1)

		winnerNameLabel.Visible = false

		timerLabel.Visible = true

		buildCenterWrap.Visible = true

		showdownWrap.Visible = false

		winnerWrap.Visible = false

		actionBar.Visible = true

		rolledInfoLabel.Visible = true

		setMyColumnVisible(true)

		setOppColumnVisible(true)

		buildMyAvatar.Image = getAvatarThumb(state.myUserId or localPlayer.UserId)

		buildOppAvatar.Image = getAvatarThumb(state.oppUserId or 0)

		local myB = state.myBoard

		local oppB = state.oppBoard

		currentPlacedThisRound = if myB then myB.placedThisRound == true else false

		vsCenterLabel.Visible = true

		if state.subPhase == "Rolling" then

			timerLabel.Text = tostring(state.frozenTimer or 15)

			rolledInfoLabel.Text = "ROLLING..."

			rollingToken += 1

			local myRollToken = rollingToken

			playSfx("roll")

			task.spawn(function()

				while currentPhase == "Build" and currentSubPhase == "Rolling" and rollingToken == myRollToken do

					local rA = Footballers.All[math.random(1, #Footballers.All)]

					local rB = Footballers.All[math.random(1, #Footballers.All)]

					MatchUi.setSilhouette(myCardWidget, rA)

					MatchUi.setSilhouette(oppCardWidget, rB)

					task.wait(0.12)

				end

			end)

		else

			rollingToken += 1

			MatchUi.populateCard(myCardWidget, myB.currentRoll, true, myB.placedThisRound == true)

			MatchUi.populateCard(oppCardWidget, oppB.currentRoll, false, oppB.placedThisRound == true)

			if myB.placedThisRound then

				rolledInfoLabel.Text = "WAITING FOR OPPONENT..."

			elseif myB.currentRoll then

				rolledInfoLabel.Text = `YOU ROLLED {string.upper(Footballers.getDisplayName(myB.currentRoll))}`

			else

				rolledInfoLabel.Text = "ALL SLOTS FILLED - WAITING FOR SHOWDOWN..."

			end

		end

		local curLuck = myB.luck or 1

		local nextLuck = GameConfig.getNextLuckTier(curLuck)

		luckBtn.Text = if nextLuck then `      LUCK: {curLuck}x [→{nextLuck.luck}x ${nextLuck.cost}]` else `      LUCK: {curLuck}x [MAX]`

		btnReroll.Text = if myB.infRerolls then "🎲 REROLL (INF)\nFREE" else if myB.rerollsLeft > 0 then `🎲 REROLL ({myB.rerollsLeft})\nFREE` else "🎲 REROLL (0)\nLOCKED"

		btnSteal.Text = `😈 STEAL ({myB.stealsLeft})\nR$39`

		for _, attr in GameConfig.ATTRIBUTES do

			local myCard = myB.slots[attr]

			local myRow = mySlotRows[attr]

			if myCard then

				populateSlotRow(myRow, myCard, "Please Select...", myB.revealedAll == true, myCard.stats[attr])

			else

				local isBest = myB.bestHint == attr

				populateSlotRow(myRow, nil, if isBest then "★ BEST SLOT ★" else "Please Select...", false, nil)

				if isBest then

					myRow.subLabel.TextColor3 = Color3.fromHex("#FFD21F")

					myRow.squareBtn.BackgroundColor3 = Color3.fromHex("#B8860B")

				end

			end

			local oppCard = oppB.slots[attr]

			local oppRow = oppSlotRows[attr]

			if oppCard then

				populateSlotRow(oppRow, oppCard, "Selecting...", false, nil)

				if oppRow.stealTag then

					oppRow.stealTag.Visible = (state.subPhase == "Selecting" and myB.stealsLeft > 0 and not myB.placedThisRound and myCard == nil)

				end

			else

				populateSlotRow(oppRow, nil, "Selecting...", false, nil)

				if oppRow.stealTag then

					oppRow.stealTag.Visible = false

				end

			end

		end

		return

	end

	rollingToken += 1

	-- 5. SHOWDOWN SCREEN (COUNTDOWN 5..1..FIGHT!, SLIDE-IN CLASH, LOSER KNOCKOUT)

	if state.phase == "Showdown" then

		focusTableCamera(state.tablePos, "Showdown")

		modeSubLabel.Visible = false

		headerLabel.Visible = true

		headerLabel.Text = "SHOWDOWN"

		headerLabel.TextColor3 = Color3.fromHex("#FFD21F")

		winnerNameLabel.Visible = false

		timerLabel.Visible = false

		buildCenterWrap.Visible = false

		showdownWrap.Visible = true

		winnerWrap.Visible = false

		actionBar.Visible = false

		rolledInfoLabel.Visible = false

		setMyColumnVisible(true)

		setOppColumnVisible(true)

		-- Reset Showdown card positions & rotation

		sdMyCard.Position = UDim2.fromScale(0.35, 0.34)

		sdMyCard.Rotation = 0

		sdOppCard.Position = UDim2.fromScale(0.65, 0.34)

		sdOppCard.Rotation = 0

		sdMyAvgBox.Position = UDim2.fromScale(0.35, 0.80)

		sdOppAvgBox.Position = UDim2.fromScale(0.65, 0.80)

		sdOppAvgBox.Visible = true

		sdMyAvgBox.Visible = true

		sdVsLabel.Visible = true

		sdCountdownLbl.Visible = true

		sdClashSpark.Visible = false

		sdMyImg.Image = getAvatarThumb(state.myUserId or localPlayer.UserId)

		sdMyName.Text = state.myName or "YOU"

		sdOppImg.Image = getAvatarThumb(state.oppUserId or 0)

		sdOppName.Text = state.oppName or "BOT"

		sdMyAvgLbl.Text = "0.0"

		sdOppAvgLbl.Text = "0.0"

		for _, attr in GameConfig.ATTRIBUTES do

			local myCard = state.myBoard.slots[attr]

			local oppCard = state.oppBoard.slots[attr]

			populateSlotRow(mySlotRows[attr], myCard, "-", false, nil)

			populateSlotRow(oppSlotRows[attr], oppCard, "-", false, nil)

			if oppSlotRows[attr].stealTag then

				oppSlotRows[attr].stealTag.Visible = false

			end

		end

		showdownToken += 1

		local mySdToken = showdownToken

		task.spawn(function()

			-- Rapid 5..4..3..2..1..FIGHT! countdown

			local steps = { "5", "4", "3", "2", "1", "FIGHT!" }

			for _, txt in steps do

				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then

					return

				end

				sdCountdownLbl.Text = txt

				sdCountdownLbl.TextColor3 = if txt == "FIGHT!" then Color3.fromHex("#FFD21F") else Color3.new(1, 1, 1)

				popGui(sdCountdownLbl, 1.45)

				playSfx("reveal")

				task.wait(0.38)

			end

			if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then

				return

			end

			-- Slide both cards & AVG SCORE boxes inward toward center

			sdVsLabel.Visible = false

			sdCountdownLbl.Visible = false

			TweenService:Create(sdMyCard, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

				Position = UDim2.fromScale(0.42, 0.34),

			}):Play()

			TweenService:Create(sdOppCard, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

				Position = UDim2.fromScale(0.58, 0.34),

			}):Play()

			TweenService:Create(sdMyAvgBox, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

				Position = UDim2.fromScale(0.42, 0.80),

			}):Play()

			TweenService:Create(sdOppAvgBox, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

				Position = UDim2.fromScale(0.58, 0.80),

			}):Play()

			task.wait(0.32)

			local sumMy = 0

			local sumOpp = 0

			for idx, attr in GameConfig.ATTRIBUTES do

				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then

					return

				end

				local myScore = state.myEval.slotScores[attr]

				local oppScore = state.oppEval.slotScores[attr]

				sumMy += myScore

				sumOpp += oppScore

				local myRow = mySlotRows[attr]

				local oppRow = oppSlotRows[attr]

				myRow.scoreBadge.Text = tostring(myScore)

				myRow.scoreBadge.Visible = true

				popGui(myRow.scoreBadge, 0.45)

				oppRow.scoreBadge.Text = tostring(oppScore)

				oppRow.scoreBadge.Visible = true

				popGui(oppRow.scoreBadge, 0.45)

				-- Reset soccer ball to center at each stat row, then animate toward the loser

				local yPos = 0.16 + (idx - 1) * 0.098

				sdClashSpark.Rotation = 0

				sdClashSpark.Position = UDim2.new(0.5, -36, yPos, -10)

				sdClashSpark.Visible = true

				popGui(sdClashSpark, 0.4)

				playSfx("reveal")

				sdMyAvgLbl.Text = string.format("%.1f", sumMy / idx)

				sdOppAvgLbl.Text = string.format("%.1f", sumOpp / idx)

				popGui(sdMyAvgLbl, 1.25)

				popGui(sdOppAvgLbl, 1.25)

				task.wait(0.15)

				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then

					return

				end

				if myScore ~= oppScore then

					local targetX = if myScore > oppScore then 0.72 else 0.28

					local spinDeg = if myScore > oppScore then 360 else -360

					TweenService:Create(sdClashSpark, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {

						Position = UDim2.new(targetX, -36, yPos, -10),

						Rotation = spinDeg,

					}):Play()

				end

				task.wait(0.30)

				if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then

					return

				end

				-- Knock away the losing row in this attribute clash

				if myScore < oppScore then

					myRow.rowFrame.Visible = false

				elseif oppScore < myScore then

					oppRow.rowFrame.Visible = false

				end

				task.wait(0.60)

			end

			if currentPhase ~= "Showdown" or showdownToken ~= mySdToken then

				return

			end

			sdClashSpark.Visible = false

			sdMyAvgLbl.Text = tostring(state.myEval.avgScore)

			sdOppAvgLbl.Text = tostring(state.oppEval.avgScore)

			-- Loser card tilts 18° and flies off-screen to bottom-right; Winner card slides to center x = 0.50

			local loserCard = if state.didWin then sdOppCard else sdMyCard

			local winnerCard = if state.didWin then sdMyCard else sdOppCard

			local loserAvg = if state.didWin then sdOppAvgBox else sdMyAvgBox

			local winnerAvg = if state.didWin then sdMyAvgBox else sdOppAvgBox

			loserAvg.Visible = false

			TweenService:Create(loserCard, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In), {

				Position = UDim2.fromScale(1.15, 1.15),

				Rotation = 18,

			}):Play()

			TweenService:Create(winnerCard, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {

				Position = UDim2.fromScale(0.50, 0.36),

			}):Play()

			TweenService:Create(winnerAvg, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {

				Position = UDim2.fromScale(0.50, 0.56),

			}):Play()

		end)

		return

	end

	showdownToken += 1

	-- 6. RESULT SCREEN (Defaults to Player's Own Result; FLIP toggles Opponent)

	if state.phase == "Result" then

		focusTableCamera(state.tablePos, "Result")

		playSfx(if state.didWin then "win" else "lose")

		headerLabel.Visible = true

		timerLabel.Visible = false

		buildCenterWrap.Visible = false

		showdownWrap.Visible = false

		winnerWrap.Visible = true

		actionBar.Visible = false

		rolledInfoLabel.Visible = false

		setOppColumnVisible(false)

		rematchVoted = false

		lastResultState = state

		lastDidWin = state.didWin == true

		pendingSummaryPopup = true

		inspectingSelf = true

		refreshWinnerInspection(true)

		-- Slide in Bottom-Right Badge Awarded Toast

		badgeToast.Position = UDim2.new(1, 20, 1, -74)

		badgeToastSub.Text = if state.didWin then "Match Victory!" else "Match Completed!"

		TweenService:Create(badgeToast, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

			Position = UDim2.new(1, -246, 1, -74),

		}):Play()

		-- Populate Post-Match Summary Popup values (shown with 3s countdown when returning to Lobby)

		local r = state.reward

		summaryUI.setReward(

			if r then (r.buxEarned or 0) else 25,

			if r then (r.winsEarned or 0) else 0,

			if r then (r.newStreak or 0) else 0

		)

		summaryUI.setQuestClaimState(true)

		refreshMetaUI()

	end

end)

-- ============================================================

-- 7. LIVE TABLE SPECTATOR DISPLAY (PvP / PlayerA VS PlayerB / Turn X/6 + 6v6 3D SLOTS)

-- ============================================================

do

local function setupSpectatorDisplay()

type SpectateSlotWidget = {

	box: Frame,

	stroke: UIStroke,

	viewport: ViewportFrame,

	mount: ViewportMount,

	nameLbl: TextLabel,

}

local spectateRefreshers: { [Instance]: () -> () } = {}

local function escapeRichText(raw: string): string

	local s = string.gsub(raw, "&", "&amp;")

	s = string.gsub(s, "<", "&lt;")

	s = string.gsub(s, ">", "&gt;")

	s = string.gsub(s, '"', "&quot;")

	return s

end

local function buildClashBolt(parent: Instance)

	local wrap = Instance.new("Frame")

	wrap.Name = "ClashBolt"

	wrap.Size = UDim2.fromScale(0.08, 0.78)

	wrap.AnchorPoint = Vector2.new(0.5, 0.5)

	wrap.Position = UDim2.fromScale(0.5, 0.47)

	wrap.BackgroundTransparency = 1

	wrap.Parent = parent

	local aspect = Instance.new("UIAspectRatioConstraint")

	aspect.AspectRatio = 0.62

	aspect.Parent = wrap

	local function makeSeg(name: string, size: UDim2, pos: UDim2, rot: number, col: Color3, zIdx: number): Frame

		local f = Instance.new("Frame")

		f.Name = name

		f.Size = size

		f.AnchorPoint = Vector2.new(0.5, 0.5)

		f.Position = pos

		f.Rotation = rot

		f.BackgroundColor3 = col

		f.BorderSizePixel = 0

		f.ZIndex = zIdx

		f.Parent = wrap

		local c = Instance.new("UICorner")

		c.CornerRadius = UDim.new(0.22, 0)

		c.Parent = f

		return f

	end

	-- Black outline backing segments (seamless, no crossing internal stroke)

	makeSeg("BackTop", UDim2.fromScale(0.46, 0.64), UDim2.fromScale(0.44, 0.34), 20, Color3.new(0, 0, 0), 1)

	makeSeg("BackMid", UDim2.fromScale(0.68, 0.22), UDim2.fromScale(0.50, 0.50), -8, Color3.new(0, 0, 0), 1)

	makeSeg("BackBot", UDim2.fromScale(0.46, 0.64), UDim2.fromScale(0.56, 0.66), 20, Color3.new(0, 0, 0), 1)

	-- Crisp white-to-silver front segments

	local frontCols = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 214, 228))

	for _, seg in {

		makeSeg("FrontTop", UDim2.fromScale(0.32, 0.56), UDim2.fromScale(0.44, 0.34), 20, Color3.new(1, 1, 1), 2),

		makeSeg("FrontMid", UDim2.fromScale(0.54, 0.14), UDim2.fromScale(0.50, 0.50), -8, Color3.new(1, 1, 1), 2),

		makeSeg("FrontBot", UDim2.fromScale(0.32, 0.56), UDim2.fromScale(0.56, 0.66), 20, Color3.new(1, 1, 1), 2),

	} do

		local g = Instance.new("UIGradient")

		g.Color = frontCols

		g.Rotation = 90

		g.Parent = seg

	end

end

local function createSpectateSideSlots(parent: Instance, sideName: string, posX: number): { [string]: SpectateSlotWidget }

	local sideFrame = Instance.new("Frame")

	sideFrame.Name = sideName

	sideFrame.Size = UDim2.fromScale(0.455, 1)

	sideFrame.Position = UDim2.fromScale(posX, 0)

	sideFrame.BackgroundTransparency = 1

	sideFrame.Parent = parent

	local map: { [string]: SpectateSlotWidget } = {}

	local colW = 1 / #GameConfig.ATTRIBUTES

	for idx, attr in GameConfig.ATTRIBUTES do

		local col = Instance.new("Frame")

		col.Name = attr

		col.Size = UDim2.fromScale(colW, 1)

		col.Position = UDim2.fromScale((idx - 1) * colW, 0)

		col.BackgroundTransparency = 1

		col.Parent = sideFrame

		local iconLbl = Instance.new("TextLabel")

		iconLbl.Name = "AttrIcon"

		iconLbl.Size = UDim2.fromScale(1, 0.24)

		iconLbl.Position = UDim2.fromScale(0, 0)

		iconLbl.BackgroundTransparency = 1

		iconLbl.Font = Enum.Font.FredokaOne

		iconLbl.TextColor3 = Color3.new(1, 1, 1)

		iconLbl.TextScaled = true

		iconLbl.Text = ATTR_ICONS[attr] or ""

		iconLbl.Parent = col

		local box = Instance.new("Frame")

		box.Name = "PortraitBox"

		box.Size = UDim2.fromScale(0.86, 0.50)

		box.AnchorPoint = Vector2.new(0.5, 0.5)

		box.Position = UDim2.fromScale(0.5, 0.50)

		box.BackgroundColor3 = Color3.fromRGB(24, 28, 36)

		box.BackgroundTransparency = 0.32

		box.ClipsDescendants = true

		box.Parent = col

		local aspect = Instance.new("UIAspectRatioConstraint")

		aspect.AspectRatio = 1

		aspect.Parent = box

		local corner = Instance.new("UICorner")

		corner.CornerRadius = UDim.new(0.18, 0)

		corner.Parent = box

		local stroke = Instance.new("UIStroke")

		stroke.Color = Color3.fromRGB(175, 184, 198)

		stroke.Thickness = 2

		stroke.Transparency = 0.18

		stroke.Parent = box

		local vp = createFaceViewport(box)

		vp.Visible = false

		local vpCorner = Instance.new("UICorner")

		vpCorner.CornerRadius = UDim.new(0.18, 0)

		vpCorner.Parent = vp

		local nameLbl = Instance.new("TextLabel")

		nameLbl.Name = "PlayerCardName"

		nameLbl.Size = UDim2.fromScale(1.06, 0.25)

		nameLbl.AnchorPoint = Vector2.new(0.5, 0)

		nameLbl.Position = UDim2.fromScale(0.5, 0.76)

		nameLbl.BackgroundTransparency = 1

		nameLbl.Font = Enum.Font.FredokaOne

		nameLbl.TextColor3 = Color3.new(1, 1, 1)

		nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)

		nameLbl.TextStrokeTransparency = 0

		nameLbl.TextWrapped = true

		nameLbl.TextScaled = true

		nameLbl.Visible = false

		nameLbl.Text = ""

		nameLbl.Parent = col

		map[attr] = {

			box = box,

			stroke = stroke,

			viewport = vp,

			mount = { model = nil, modelId = nil },

			nameLbl = nameLbl,

		}

	end

	return map

end

local function updateSpectateSlot(slot: SpectateSlotWidget, cardId: string)

	local card = if #cardId > 0 then Footballers.ById[cardId] else nil

	if card then

		slot.box.BackgroundColor3 = Color3.fromHex(card.kitColor)

		slot.box.BackgroundTransparency = 0.04

		slot.stroke.Color = Color3.fromRGB(238, 244, 255)

		slot.stroke.Thickness = 2.5

		slot.stroke.Transparency = 0

		slot.viewport.Visible = true

		mountViewportModel(slot.viewport, slot.mount, card.id)

		slot.nameLbl.Text = Footballers.getDisplayName(card)

		slot.nameLbl.Visible = true

	else

		slot.box.BackgroundColor3 = Color3.fromRGB(24, 28, 36)

		slot.box.BackgroundTransparency = 0.32

		slot.stroke.Color = Color3.fromRGB(175, 184, 198)

		slot.stroke.Thickness = 2

		slot.stroke.Transparency = 0.18

		slot.viewport.Visible = false

		mountViewportModel(slot.viewport, slot.mount, nil)

		slot.nameLbl.Text = ""

		slot.nameLbl.Visible = false

	end

end

local function bindSpectateTable(tableModel: Instance)

	if not tableModel:IsA("Model") or spectateRefreshers[tableModel] then

		return

	end

	local tableTop = tableModel:WaitForChild("TableTop", 5)

	if not tableTop or not tableTop:IsA("BasePart") or spectateRefreshers[tableModel] then

		return

	end

	local bb = Instance.new("BillboardGui")

	bb.Name = `BAF_Spectate_{tableModel.Name}`

	bb.Size = UDim2.fromScale(22.5, 8.8)

	bb.StudsOffset = Vector3.new(0, 6.2, 0)

	bb.MaxDistance = 95

	bb.AlwaysOnTop = true

	bb.LightInfluence = 0

	bb.Enabled = false

	bb.Adornee = tableTop

	bb.Parent = playerGui

	local function makeSpectateText(name: string, size: UDim2, pos: UDim2, strokeThick: number): TextLabel

		local lbl = Instance.new("TextLabel")

		lbl.Name = name

		lbl.Size = size

		lbl.Position = pos

		lbl.BackgroundTransparency = 1

		lbl.Font = Enum.Font.FredokaOne

		lbl.TextColor3 = Color3.new(1, 1, 1)

		lbl.TextScaled = true

		lbl.Parent = bb

		local st = Instance.new("UIStroke")

		st.Color = Color3.new(0, 0, 0)

		st.Thickness = strokeThick

		st.Parent = lbl

		return lbl

	end

	local pvpHeader = makeSpectateText("PvPHeader", UDim2.fromScale(1, 0.14), UDim2.fromScale(0, 0), 2.5)

	pvpHeader.Text = "PvP"

	local namesRow = makeSpectateText("NamesRow", UDim2.fromScale(1, 0.19), UDim2.fromScale(0, 0.13), 3)

	namesRow.RichText = true

	local turnRow = makeSpectateText("TurnRow", UDim2.fromScale(1, 0.13), UDim2.fromScale(0, 0.32), 2.5)

	turnRow.Text = "Turn 1/6"

	local slotsArea = Instance.new("Frame")

	slotsArea.Name = "SlotsArea"

	slotsArea.Size = UDim2.fromScale(1, 0.54)

	slotsArea.Position = UDim2.fromScale(0, 0.46)

	slotsArea.BackgroundTransparency = 1

	slotsArea.Parent = bb

	local sideASlots = createSpectateSideSlots(slotsArea, "SideA", 0)

	buildClashBolt(slotsArea)

	local sideBSlots = createSpectateSideSlots(slotsArea, "SideB", 0.545)

	local function refreshThisTable()

		local active = tableModel:GetAttribute("MatchActive") == true

		bb.Enabled = active and (currentPhase == "Idle")

		if not active then

			return

		end

		local nameA = tostring(tableModel:GetAttribute("NameA") or "Player 1")

		local nameB = tostring(tableModel:GetAttribute("NameB") or "BOT")

		local turn = tonumber(tableModel:GetAttribute("Turn")) or 1

		local maxTurns = #GameConfig.ATTRIBUTES

		pvpHeader.Text = "PvP"

		namesRow.Text = string.format(

			'<font color="#22D3EE">%s</font>  <font color="#FFD21F">VS</font>  <font color="#EF4444">%s</font>',

			escapeRichText(nameA),

			escapeRichText(nameB)

		)

		turnRow.Text = `Turn {math.clamp(turn, 1, maxTurns)}/{maxTurns}`

		for _, attr in GameConfig.ATTRIBUTES do

			local idA = tostring(tableModel:GetAttribute(`SlotA_{attr}`) or "")

			local idB = tostring(tableModel:GetAttribute(`SlotB_{attr}`) or "")

			updateSpectateSlot(sideASlots[attr], idA)

			updateSpectateSlot(sideBSlots[attr], idB)

		end

	end

	spectateRefreshers[tableModel] = refreshThisTable

	local attrConn = tableModel.AttributeChanged:Connect(refreshThisTable)

	tableModel.Destroying:Connect(function()

		attrConn:Disconnect()

		spectateRefreshers[tableModel] = nil

		bb:Destroy()

	end)

	refreshThisTable()

end

refreshAllSpectateBillboards = function()

	for _, fn in spectateRefreshers do

		fn()

	end

end

task.spawn(function()

	local lobby = Workspace:WaitForChild("Lobby", 5)

	local tablesFolder = (lobby and lobby:WaitForChild("Tables", 5)) or Workspace:WaitForChild("Tables", 15)

	if not tablesFolder then

		return

	end

	for _, child in tablesFolder:GetChildren() do

		task.spawn(bindSpectateTable, child)

	end

	tablesFolder.ChildAdded:Connect(function(child)

		task.spawn(bindSpectateTable, child)

	end)

end)

end -- setupSpectatorDisplay

setupSpectatorDisplay()

end -- spectator display

-- ============================================================

-- 8. SHARE YOUR FEEDBACK MODAL + PRIVATE OWNER feedback.txt VIEWER

-- ============================================================

do

local function setupFeedbackModal()

local feedbackModal = Instance.new("Frame")

feedbackModal.Name = "FeedbackModal"

feedbackModal.Size = UDim2.fromOffset(480, 360)

feedbackModal.AnchorPoint = Vector2.new(0.5, 0.5)

feedbackModal.Position = UDim2.fromScale(0.5, 0.5)

feedbackModal.BackgroundColor3 = Color3.fromRGB(35, 37, 41)

feedbackModal.BorderSizePixel = 0

feedbackModal.ZIndex = 32

feedbackModal.Visible = false

feedbackModal.Parent = screenGui

addCorner(feedbackModal, 14)

addStroke(feedbackModal, Color3.fromRGB(60, 63, 70), 1)

local fbCloseBtn = Instance.new("TextButton")

fbCloseBtn.Name = "CloseBtn"

fbCloseBtn.Size = UDim2.fromOffset(44, 40)

fbCloseBtn.Position = UDim2.fromOffset(22, 10)

fbCloseBtn.BackgroundColor3 = Color3.fromRGB(35, 37, 41)

fbCloseBtn.Text = ""

fbCloseBtn.ZIndex = 33

fbCloseBtn.Parent = feedbackModal

addCorner(fbCloseBtn, 10)

addStroke(fbCloseBtn, Color3.new(1, 1, 1), 2.5)

for _, rot in { 45, -45 } do

	local bar = Instance.new("Frame")

	bar.Size = UDim2.fromOffset(18, 2)

	bar.AnchorPoint = Vector2.new(0.5, 0.5)

	bar.Position = UDim2.fromScale(0.5, 0.5)

	bar.Rotation = rot

	bar.BackgroundColor3 = Color3.new(1, 1, 1)

	bar.BorderSizePixel = 0

	bar.ZIndex = 34

	bar.Parent = fbCloseBtn

end

local fbTitle = Instance.new("TextLabel")

fbTitle.Name = "Title"

fbTitle.Size = UDim2.new(1, -180, 0, 40)

fbTitle.Position = UDim2.fromOffset(90, 10)

fbTitle.BackgroundTransparency = 1

fbTitle.Font = Enum.Font.GothamBold

fbTitle.TextSize = 21

fbTitle.TextColor3 = Color3.new(1, 1, 1)

fbTitle.Text = "Share Your Feedback"

fbTitle.ZIndex = 33

fbTitle.Parent = feedbackModal

local isLikelyOwner = RunService:IsStudio()

	or (game.CreatorType == Enum.CreatorType.User and localPlayer.UserId == game.CreatorId)

local fbOwnerBtn = Instance.new("TextButton")

fbOwnerBtn.Name = "OwnerTxtBtn"

fbOwnerBtn.Size = UDim2.fromOffset(96, 30)

fbOwnerBtn.Position = UDim2.new(1, -116, 0, 15)

fbOwnerBtn.BackgroundColor3 = Color3.fromRGB(54, 58, 66)

fbOwnerBtn.Font = Enum.Font.GothamBold

fbOwnerBtn.TextSize = 12

fbOwnerBtn.TextColor3 = Color3.fromRGB(220, 228, 245)

fbOwnerBtn.Text = "📄 feedback.txt"

fbOwnerBtn.Visible = isLikelyOwner

fbOwnerBtn.ZIndex = 33

fbOwnerBtn.Parent = feedbackModal

addCorner(fbOwnerBtn, 8)

addStroke(fbOwnerBtn, Color3.fromRGB(95, 102, 115), 1)

local fbDivider = Instance.new("Frame")

fbDivider.Name = "Divider"

fbDivider.Size = UDim2.new(1, -48, 0, 1)

fbDivider.Position = UDim2.fromOffset(24, 58)

fbDivider.BackgroundColor3 = Color3.fromRGB(72, 75, 82)

fbDivider.BorderSizePixel = 0

fbDivider.ZIndex = 33

fbDivider.Parent = feedbackModal

-- Compose Pane (matches Image 5)

local fbComposePane = Instance.new("Frame")

fbComposePane.Name = "ComposePane"

fbComposePane.Size = UDim2.new(1, -48, 1, -74)

fbComposePane.Position = UDim2.fromOffset(24, 68)

fbComposePane.BackgroundTransparency = 1

fbComposePane.ZIndex = 33

fbComposePane.Parent = feedbackModal

local fbPromptLbl = Instance.new("TextLabel")

fbPromptLbl.Name = "PromptLabel"

fbPromptLbl.Size = UDim2.new(1, 0, 0, 24)

fbPromptLbl.Position = UDim2.fromOffset(0, 6)

fbPromptLbl.BackgroundTransparency = 1

fbPromptLbl.Font = Enum.Font.GothamMedium

fbPromptLbl.TextSize = 17

fbPromptLbl.TextColor3 = Color3.fromRGB(238, 240, 245)

fbPromptLbl.TextXAlignment = Enum.TextXAlignment.Left

fbPromptLbl.Text = "Tell us about your experience."

fbPromptLbl.ZIndex = 33

fbPromptLbl.Parent = fbComposePane

local fbInputWrap = Instance.new("Frame")

fbInputWrap.Name = "InputWrap"

fbInputWrap.Size = UDim2.new(1, 0, 0, 112)

fbInputWrap.Position = UDim2.fromOffset(0, 42)

fbInputWrap.BackgroundColor3 = Color3.fromRGB(45, 48, 53)

fbInputWrap.BorderSizePixel = 0

fbInputWrap.ZIndex = 33

fbInputWrap.Parent = fbComposePane

addCorner(fbInputWrap, 10)

local fbInput = Instance.new("TextBox")

fbInput.Name = "FeedbackInput"

fbInput.Size = UDim2.new(1, -28, 1, -24)

fbInput.Position = UDim2.fromOffset(14, 12)

fbInput.BackgroundTransparency = 1

fbInput.Font = Enum.Font.Gotham

fbInput.TextSize = 16

fbInput.TextColor3 = Color3.fromRGB(245, 247, 250)

fbInput.PlaceholderColor3 = Color3.fromRGB(162, 166, 174)

fbInput.PlaceholderText = "Tell us what you think..."

fbInput.Text = ""

fbInput.MultiLine = true

fbInput.ClearTextOnFocus = false

fbInput.TextWrapped = true

fbInput.TextXAlignment = Enum.TextXAlignment.Left

fbInput.TextYAlignment = Enum.TextYAlignment.Top

fbInput.ZIndex = 34

fbInput.Parent = fbInputWrap

local fbSubmitBtn = Instance.new("TextButton")

fbSubmitBtn.Name = "SubmitBtn"

fbSubmitBtn.Size = UDim2.new(1, 0, 0, 42)

fbSubmitBtn.Position = UDim2.fromOffset(0, 178)

fbSubmitBtn.BackgroundColor3 = Color3.fromRGB(43, 56, 99)

fbSubmitBtn.BorderSizePixel = 0

fbSubmitBtn.Font = Enum.Font.GothamMedium

fbSubmitBtn.TextSize = 16

fbSubmitBtn.TextColor3 = Color3.fromRGB(155, 163, 181)

fbSubmitBtn.Text = "Submit"

fbSubmitBtn.ZIndex = 33

fbSubmitBtn.Parent = fbComposePane

addCorner(fbSubmitBtn, 8)

local fbFooter = Instance.new("TextLabel")

fbFooter.Name = "FooterDisclaimer"

fbFooter.Size = UDim2.new(1, 0, 0, 38)

fbFooter.Position = UDim2.fromOffset(0, 234)

fbFooter.BackgroundTransparency = 1

fbFooter.Font = Enum.Font.Gotham

fbFooter.TextSize = 13

fbFooter.TextColor3 = Color3.fromRGB(178, 182, 190)

fbFooter.TextXAlignment = Enum.TextXAlignment.Left

fbFooter.TextYAlignment = Enum.TextYAlignment.Top

fbFooter.TextWrapped = true

fbFooter.RichText = true

fbFooter.Text = "Responses are shared anonymously and constitute\nfeedback per the <u>Roblox Terms of Use</u>."

fbFooter.ZIndex = 33

fbFooter.Parent = fbComposePane

-- Owner-only Private .txt Log Pane (read-only & selectable so owner can copy into player_feedback.txt)

local fbOwnerPane = Instance.new("Frame")

fbOwnerPane.Name = "OwnerTxtPane"

fbOwnerPane.Size = UDim2.new(1, -48, 1, -74)

fbOwnerPane.Position = UDim2.fromOffset(24, 68)

fbOwnerPane.BackgroundTransparency = 1

fbOwnerPane.Visible = false

fbOwnerPane.ZIndex = 33

fbOwnerPane.Parent = feedbackModal

local fbOwnerHint = Instance.new("TextLabel")

fbOwnerHint.Size = UDim2.new(1, 0, 0, 22)

fbOwnerHint.Position = UDim2.fromOffset(0, 2)

fbOwnerHint.BackgroundTransparency = 1

fbOwnerHint.Font = Enum.Font.GothamMedium

fbOwnerHint.TextSize = 13

fbOwnerHint.TextColor3 = Color3.fromRGB(165, 220, 185)

fbOwnerHint.TextXAlignment = Enum.TextXAlignment.Left

fbOwnerHint.Text = "Owner Private Log (player_feedback.txt) — Select & Ctrl+C to copy:"

fbOwnerHint.ZIndex = 33

fbOwnerHint.Parent = fbOwnerPane

local fbOwnerScroll = Instance.new("ScrollingFrame")

fbOwnerScroll.Name = "TxtScroll"

fbOwnerScroll.Size = UDim2.new(1, 0, 1, -30)

fbOwnerScroll.Position = UDim2.fromOffset(0, 26)

fbOwnerScroll.BackgroundColor3 = Color3.fromRGB(24, 26, 30)

fbOwnerScroll.BorderSizePixel = 0

fbOwnerScroll.ScrollBarThickness = 6

fbOwnerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

fbOwnerScroll.CanvasSize = UDim2.new()

fbOwnerScroll.ZIndex = 33

fbOwnerScroll.Parent = fbOwnerPane

addCorner(fbOwnerScroll, 8)

addStroke(fbOwnerScroll, Color3.fromRGB(64, 68, 76), 1)

local fbOwnerTxtBox = Instance.new("TextBox")

fbOwnerTxtBox.Name = "OwnerTxtBox"

fbOwnerTxtBox.Size = UDim2.new(1, -20, 0, 0)

fbOwnerTxtBox.Position = UDim2.fromOffset(10, 10)

fbOwnerTxtBox.AutomaticSize = Enum.AutomaticSize.Y

fbOwnerTxtBox.BackgroundTransparency = 1

fbOwnerTxtBox.Font = Enum.Font.Code

fbOwnerTxtBox.TextSize = 13

fbOwnerTxtBox.TextColor3 = Color3.fromRGB(228, 232, 240)

fbOwnerTxtBox.TextXAlignment = Enum.TextXAlignment.Left

fbOwnerTxtBox.TextYAlignment = Enum.TextYAlignment.Top

fbOwnerTxtBox.TextWrapped = true

fbOwnerTxtBox.TextEditable = false

fbOwnerTxtBox.ClearTextOnFocus = false

fbOwnerTxtBox.Text = "Loading player_feedback.txt..."

fbOwnerTxtBox.ZIndex = 34

fbOwnerTxtBox.Parent = fbOwnerScroll

local function updateSubmitButtonVisual()

	local trimmed = string.match(fbInput.Text, "^%s*(.-)%s*$") or ""

	local canSend = #trimmed >= 2

	fbSubmitBtn.BackgroundColor3 = if canSend then Color3.fromRGB(56, 92, 214) else Color3.fromRGB(43, 56, 99)

	fbSubmitBtn.TextColor3 = if canSend then Color3.new(1, 1, 1) else Color3.fromRGB(155, 163, 181)

end

fbInput:GetPropertyChangedSignal("Text"):Connect(function()

	if #fbInput.Text > 500 then

		fbInput.Text = string.sub(fbInput.Text, 1, 500)

	end

	updateSubmitButtonVisual()

end)

closeFeedbackModal = function()

	feedbackModal.Visible = false

end

fbCloseBtn.Activated:Connect(function()

	playSfx("click")

	feedbackModal.Visible = false

end)

fbOwnerBtn.Activated:Connect(function()

	playSfx("click")

	local showingLog = not fbOwnerPane.Visible

	fbOwnerPane.Visible = showingLog

	fbComposePane.Visible = not showingLog

	fbOwnerBtn.Text = if showingLog then "✏️ Compose" else "📄 feedback.txt"

	if showingLog then

		Remotes.MetaAction:FireServer("GetOwnerFeedbackTxt")

	end

end)

fbSubmitBtn.Activated:Connect(function()

	local trimmed = string.match(fbInput.Text, "^%s*(.-)%s*$") or ""

	if #trimmed < 2 then

		return

	end

	playSfx("click")

	popGui(fbSubmitBtn, 0.96)

	Remotes.MetaAction:FireServer("SubmitFeedback", trimmed)

end)

openFeedbackModal = function()

	if currentPhase ~= "Idle" then

		return

	end

	modalWrap.Visible = false

	shopWindow.Visible = false

	fbOwnerPane.Visible = false

	fbComposePane.Visible = true

	fbOwnerBtn.Text = "📄 feedback.txt"

	updateSubmitButtonVisual()

	feedbackModal.Visible = true

	popGui(feedbackModal, 0.92)

	playSfx("click")

end

Remotes.FeedbackSync.OnClientEvent:Connect(function(payload: any)

	if typeof(payload) ~= "table" then

		return

	end

	if payload.kind == "Open" then

		openFeedbackModal()

	elseif payload.kind == "Submitted" then

		fbInput.Text = ""

		updateSubmitButtonVisual()

		feedbackModal.Visible = false

		playSfx("rare")

	elseif payload.kind == "Log" and typeof(payload.txt) == "string" then

		fbOwnerBtn.Visible = true

		fbOwnerTxtBox.Text = payload.txt

	end

end)

end -- setupFeedbackModal

setupFeedbackModal()

end -- feedback modal
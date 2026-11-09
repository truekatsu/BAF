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

local DAILY_COOLDOWN_SEC = 86400

-- Built-in Engine SFX & UI Tween Helpers
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

local function playSfx(kind: string)
	local s = sfxMap[kind]
	if s then
		SoundService:PlayLocalSound(s)
	end
end

-- Phase-adaptive Background Music (Lobby Samba/Brass, Build Liquid DnB, Showdown Stadium Drumline)
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

local function setBgmPhase(phase: string)
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

local matchBlur = Lighting:FindFirstChild("BAF_MatchBlur") :: BlurEffect?
if not matchBlur then
	local b = Instance.new("BlurEffect")
	b.Name = "BAF_MatchBlur"
	b.Size = 0
	b.Parent = Lighting
	matchBlur = b
end

local function setMatchBlur(enabled: boolean)
	if matchBlur then
		TweenService:Create(matchBlur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = if enabled then 24 else 0,
		}):Play()
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
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ============================================================
-- 1. LOBBY HUD & RETENTION MODALS
-- ============================================================
local lobbyHud = Instance.new("Frame")
lobbyHud.Name = "LobbyHUD"
lobbyHud.Size = UDim2.fromScale(1, 1)
lobbyHud.BackgroundTransparency = 1
lobbyHud.Parent = screenGui

-- Toast Notification Banner (parented to screenGui so it is visible in both Lobby and Match)
local toastBanner = makeLabel(screenGui, "", UDim2.new(0.44, 0, 0, 38), UDim2.new(0.28, 0, 0, 68), Color3.fromHex("#FFD21F"))
toastBanner.BackgroundTransparency = 0.15
toastBanner.BackgroundColor3 = GameConfig.UI_COLORS.PanelDark
toastBanner.ZIndex = 30
toastBanner.Visible = false
addCorner(toastBanner, 10)
addStroke(toastBanner, Color3.fromHex("#FFD21F"), 2)
local toastToken = 0

local function showToast(msg: string)
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


-- Top-Right Container for Daily Rewards & Quests (parented to screenGui so they remain visible on all screens)
local topRightBar = Instance.new("Frame")
topRightBar.Name = "TopRightBar"
topRightBar.Size = UDim2.new(0, 300, 0, 42)
topRightBar.Position = UDim2.new(1, -16, 0, 14)
topRightBar.AnchorPoint = Vector2.new(1, 0)
topRightBar.BackgroundTransparency = 1
topRightBar.ZIndex = 20
topRightBar.Parent = screenGui

local topRightLayout = Instance.new("UIListLayout")
topRightLayout.FillDirection = Enum.FillDirection.Horizontal
topRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
topRightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topRightLayout.Padding = UDim.new(0, 10)
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

	UITheme.setupButtonHover(btn, 1.05, 0)
	btn.Activated:Connect(function()
		playSfx("click")
		popGui(btn, 0.93)
	end)

	return btn
end

local btnTopDaily = makeTopButton("BtnTopDaily", UITheme.Assets.BtnDaily, UDim2.fromOffset(144, 42), 1)
local btnTopQuests = makeTopButton("BtnTopQuests", UITheme.Assets.BtnQuests, UDim2.fromOffset(136, 42), 2)

local questBadge = makeLabel(btnTopQuests, "0", UDim2.fromOffset(22, 22), UDim2.new(1, -6, 0, 2), Color3.new(1, 1, 1))
questBadge.AnchorPoint = Vector2.new(0.5, 0.5)
questBadge.BackgroundTransparency = 0
questBadge.BackgroundColor3 = Color3.fromHex("#E5252A")
questBadge.ZIndex = 25
questBadge.Visible = false
UITheme.addCorner(questBadge, 11)
UITheme.applyStroke(questBadge, 2, UITheme.Colors.Black)

-- Left Vertical Nav Column (FREE, SHOP, SKINS, TITLES, INDEX, PROFILE)
local NAV_BTN_SIZE = 84
local NAV_BTN_STEP = 90

local function makeNavButton(name: string, imageId: string, index: number, scaleX: number, scaleY: number, anchorX: number, anchorY: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.fromOffset(NAV_BTN_SIZE, NAV_BTN_SIZE)
	btn.Position = UDim2.new(0, 16, 0.085, (index - 1) * NAV_BTN_STEP)
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
local btnNavFree = makeNavButton("BtnNavFree", UITheme.Assets.NavFreeIcon, 1, 557 / 444, 557 / 449, 277.5 / 557, 266.0 / 557)
local btnNavShop = makeNavButton("BtnNavShop", UITheme.Assets.NavShopIcon, 2, 557 / 496, 557 / 506, 278.5 / 557, 282.5 / 557)
local btnNavSkins = makeNavButton("BtnNavSkins", UITheme.Assets.NavSkinsIcon, 3, 557 / 477, 557 / 489, 278.0 / 557, 284.0 / 557)
local btnNavTitles = makeNavButton("BtnNavTitles", UITheme.Assets.NavTitlesIcon, 4, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
local btnNavIndex = makeNavButton("BtnNavIndex", UITheme.Assets.NavIndexIcon, 5, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
local btnNavProfile = makeNavButton("BtnNavProfile", UITheme.Assets.NavProfileIcon, 6, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)

do
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
UITheme.applyStroke(freeBadge, 2.5, UITheme.Colors.Black)

-- Right Promo Column (Starter Pack & 2x Streak)
local btnPromoStarter: TextButton
local btnPromoStreak: TextButton
do
	local bStarter = makeButton(lobbyHud, "", UDim2.fromOffset(88, 82), UDim2.new(1, -104, 0.48, 0), UITheme.Colors.LimeTop)
	UITheme.styleButton(bStarter, "Lime", 10)
	UITheme.addStuds(bStarter, 0.88, 20)
	UITheme.createRobuxBadge(bStarter, 4, UDim2.fromOffset(58, 24), UDim2.new(0.5, -29, 0, -10))
	UITheme.addPulse(bStarter, 1.0, 1.05, 1.2)

	local sIcon = Instance.new("ImageLabel")
	sIcon.Name = "StarterIcon"
	sIcon.Size = UDim2.fromOffset(36, 36)
	sIcon.Position = UDim2.new(0.5, -18, 0, 14)
	sIcon.BackgroundTransparency = 1
	sIcon.Image = UITheme.Assets.CashStack
	sIcon.ScaleType = Enum.ScaleType.Fit
	sIcon.ZIndex = bStarter.ZIndex + 3
	sIcon.Parent = bStarter

	local sLbl = Instance.new("TextLabel")
	sLbl.Name = "BtnLabel"
	sLbl.Size = UDim2.new(1, 0, 0, 26)
	sLbl.Position = UDim2.new(0, 0, 1, -28)
	sLbl.BackgroundTransparency = 1
	sLbl.Font = UITheme.Fonts.Primary
	sLbl.TextColor3 = UITheme.Colors.White
	sLbl.Text = "STARTER PACK"
	sLbl.TextScaled = true
	UITheme.addTextConstraint(sLbl, 10, 13)
	UITheme.applyTextStroke(sLbl, 2.5, UITheme.Colors.Black)
	sLbl.ZIndex = bStarter.ZIndex + 3
	sLbl.Parent = bStarter
	btnPromoStarter = bStarter

	local bStreak = makeButton(lobbyHud, "", UDim2.fromOffset(88, 82), UDim2.new(1, -104, 0.48, 96), UITheme.Colors.RedTop)
	UITheme.styleButton(bStreak, "Red", 10)
	UITheme.addStuds(bStreak, 0.88, 20)
	UITheme.createRobuxBadge(bStreak, 30, UDim2.fromOffset(58, 24), UDim2.new(0.5, -29, 0, -10))
	UITheme.addPulse(bStreak, 1.0, 1.05, 1.2)

	local stIcon = Instance.new("ImageLabel")
	stIcon.Name = "StreakIcon"
	stIcon.Size = UDim2.fromOffset(36, 36)
	stIcon.Position = UDim2.new(0.5, -18, 0, 14)
	stIcon.BackgroundTransparency = 1
	stIcon.Image = UITheme.Assets.FlameIcon
	stIcon.ScaleType = Enum.ScaleType.Fit
	stIcon.ZIndex = bStreak.ZIndex + 3
	stIcon.Parent = bStreak

	local stLbl = Instance.new("TextLabel")
	stLbl.Name = "BtnLabel"
	stLbl.Size = UDim2.new(1, 0, 0, 26)
	stLbl.Position = UDim2.new(0, 0, 1, -28)
	stLbl.BackgroundTransparency = 1
	stLbl.Font = UITheme.Fonts.Primary
	stLbl.TextColor3 = UITheme.Colors.White
	stLbl.Text = "2X STREAK"
	stLbl.TextScaled = true
	UITheme.addTextConstraint(stLbl, 10, 14)
	UITheme.applyTextStroke(stLbl, 2.5, UITheme.Colors.Black)
	stLbl.ZIndex = bStreak.ZIndex + 3
	stLbl.Parent = bStreak
	btnPromoStreak = bStreak
end

-- Bottom-Left Friends Boost + Cash Display
local friendsLabel = makeLabel(lobbyHud, "FRIENDS BOOST: +0%", UDim2.fromOffset(210, 28), UDim2.new(0, 16, 1, -100), UITheme.Colors.NoticeYellow)
friendsLabel.TextXAlignment = Enum.TextXAlignment.Left
local btnAddFriend = makeButton(lobbyHud, "+", UDim2.fromOffset(28, 28), UDim2.new(0, 230, 1, -100), UITheme.Colors.NoticeYellow)
UITheme.styleButton(btnAddFriend, "Gold", 6)
btnAddFriend.Activated:Connect(function()
	pcall(function()
		SocialService:PromptGameInvite(localPlayer)
	end)
end)

local cashPill = Instance.new("Frame")
cashPill.Name = "CashPill"
cashPill.Size = UDim2.fromOffset(210, 46)
cashPill.Position = UDim2.new(0, 16, 1, -64)
cashPill.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(cashPill, 10)
UITheme.applyStroke(cashPill, 3, UITheme.Colors.Black)
UITheme.addStuds(cashPill, 0.88, 20)
UITheme.addShadow(cashPill, 10, 4)
cashPill.Parent = lobbyHud

local cashIconImg = Instance.new("ImageLabel")
cashIconImg.Name = "CashIcon"
cashIconImg.Size = UDim2.fromOffset(32, 32)
cashIconImg.Position = UDim2.new(0, 8, 0.5, -16)
cashIconImg.BackgroundTransparency = 1
cashIconImg.Image = UITheme.Assets.CashStack
cashIconImg.ScaleType = Enum.ScaleType.Fit
cashIconImg.ZIndex = cashPill.ZIndex + 2
cashIconImg.Parent = cashPill

local cashLabel = makeLabel(cashPill, "$0", UDim2.new(1, -90, 1, 0), UDim2.new(0, 46, 0, 0), UITheme.Colors.MoneyGreen)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left

local btnAddCash = makeButton(cashPill, "+", UDim2.fromOffset(36, 36), UDim2.new(1, -40, 0.5, -18), UITheme.Colors.LimeTop)
UITheme.styleButton(btnAddCash, "Lime", 8)

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
modalWrap.Size = UDim2.fromOffset(800, 546)
modalWrap.AnchorPoint = Vector2.new(0.5, 0.5)
modalWrap.Position = UDim2.fromScale(0.5, 0.50)
modalWrap.BackgroundTransparency = 1
modalWrap.ZIndex = 25
modalWrap.Visible = false
modalWrap.Parent = screenGui

local modalBox = Instance.new("Frame")
modalBox.Name = "ModalBox"
modalBox.Size = UDim2.new(1, 0, 0, 480)
modalBox.BackgroundColor3 = Color3.fromHex("#10111A")
modalBox.BackgroundTransparency = 0.08
UITheme.addCorner(modalBox, UITheme.CONFIG.WINDOW_CORNER_RADIUS)
UITheme.applyStroke(modalBox, UITheme.CONFIG.WINDOW_STROKE_THICKNESS, UITheme.CONFIG.Colors.Outline)
UITheme.studs(modalBox, UITheme.CONFIG.STUDS_PANEL_TRANSPARENCY)
UITheme.addShadow(modalBox, 14, 6)

local modalBoxScale = Instance.new("UIScale")
modalBoxScale.Scale = 1.0
modalBoxScale.Parent = modalBox
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

-- Free Menu Shell Tab Row (touching bottom of Window_Daily at y = 484)
local freeTabsBar = Instance.new("Frame")
freeTabsBar.Name = "FreeTabsBar"
freeTabsBar.Size = UDim2.new(0, 574, 0, 56)
freeTabsBar.Position = UDim2.new(0.5, 0, 0, 484)
freeTabsBar.AnchorPoint = Vector2.new(0.5, 0)
freeTabsBar.BackgroundTransparency = 1
freeTabsBar.Visible = false
freeTabsBar.Parent = modalWrap

local function setTabActive(btn: TextButton, isActive: boolean, text: string)
	local innerGold = btn:FindFirstChild("InnerGoldStroke") :: UIStroke?
	if isActive then
		UITheme.styleButton(btn, "Lime", 6)
		if not innerGold then
			innerGold = Instance.new("UIStroke")
			innerGold.Name = "InnerGoldStroke"
			innerGold.Thickness = 3
			innerGold.Color = Color3.fromHex("#F5C518")
			innerGold.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			innerGold.Parent = btn
		else
			innerGold.Enabled = true
		end
	else
		UITheme.styleButton(btn, "TabInactive", 6)
		if innerGold then
			innerGold.Enabled = false
		end
	end
	btn.Text = ""
	local lbl = btn:FindFirstChild("BtnLabel") :: TextLabel?
	if not lbl then
		lbl = Instance.new("TextLabel")
		lbl.Name = "BtnLabel"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.Position = UDim2.fromScale(0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = UITheme.Fonts.Primary
		lbl.ZIndex = btn.ZIndex + 3
		lbl.TextScaled = true
		local sc = Instance.new("UITextSizeConstraint")
		sc.MinTextSize = 12
		sc.MaxTextSize = 22
		sc.Parent = lbl
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Color = UITheme.Colors.Black
		s.Parent = lbl
		lbl.Parent = btn
	end
	lbl.Text = text
	lbl.TextColor3 = if isActive then UITheme.Colors.White else UITheme.Colors.TabInactiveText
end

local btnTabDaily = makeButton(freeTabsBar, "", UDim2.new(0.31, 0, 1, 0), UDim2.new(0, 0, 0, 0), UITheme.Colors.LimeTop)
local btnTabGroup = makeButton(freeTabsBar, "", UDim2.new(0.31, 0, 1, 0), UDim2.new(0.345, 0, 0, 0), UITheme.Colors.TabInactiveTop)
local btnTabPlaytime = makeButton(freeTabsBar, "", UDim2.new(0.31, 0, 1, 0), UDim2.new(0.69, 0, 0, 0), UITheme.Colors.TabInactiveTop)
setTabActive(btnTabDaily, true, "📅 DAILY")
setTabActive(btnTabGroup, false, "👥 GROUP")
setTabActive(btnTabPlaytime, false, "⏰ PLAYTIME")

local dailyTabBadge = makeLabel(btnTabDaily, "0", UDim2.fromOffset(24, 24), UDim2.new(1, -12, 0, -8), Color3.new(1, 1, 1))
dailyTabBadge.BackgroundTransparency = 0
dailyTabBadge.BackgroundColor3 = Color3.fromHex("#E02424")
dailyTabBadge.Visible = false
UITheme.addCorner(dailyTabBadge, 6)
UITheme.applyStroke(dailyTabBadge, 2, UITheme.Colors.Black)

local groupTabBadge = makeLabel(btnTabGroup, "0", UDim2.fromOffset(24, 24), UDim2.new(1, -12, 0, -8), Color3.new(1, 1, 1))
groupTabBadge.BackgroundTransparency = 0
groupTabBadge.BackgroundColor3 = Color3.fromHex("#E02424")
groupTabBadge.Visible = false
UITheme.addCorner(groupTabBadge, 6)
UITheme.applyStroke(groupTabBadge, 2, UITheme.Colors.Black)

local playtimeTabBadge = makeLabel(btnTabPlaytime, "0", UDim2.fromOffset(24, 24), UDim2.new(1, -12, 0, -8), Color3.new(1, 1, 1))
playtimeTabBadge.BackgroundTransparency = 0
playtimeTabBadge.BackgroundColor3 = Color3.fromHex("#E02424")
playtimeTabBadge.Visible = false
UITheme.addCorner(playtimeTabBadge, 6)
UITheme.applyStroke(playtimeTabBadge, 2, UITheme.Colors.Black)

-- Pages inside modalBody
local pageFreeDaily = Instance.new("Frame")
pageFreeDaily.Size = UDim2.fromScale(1, 1)
pageFreeDaily.BackgroundTransparency = 1
pageFreeDaily.Parent = modalBody

local pageFreeGroup = Instance.new("Frame")
pageFreeGroup.Size = UDim2.fromScale(1, 1)
pageFreeGroup.BackgroundTransparency = 1
pageFreeGroup.Visible = false
pageFreeGroup.Parent = modalBody

local pageFreePlaytime = Instance.new("Frame")
pageFreePlaytime.Size = UDim2.fromScale(1, 1)
pageFreePlaytime.BackgroundTransparency = 1
pageFreePlaytime.Visible = false
pageFreePlaytime.Parent = modalBody

local pageQuests = Instance.new("Frame")
pageQuests.Size = UDim2.fromScale(1, 1)
pageQuests.BackgroundTransparency = 1
pageQuests.Visible = false
pageQuests.Parent = modalBody

local pageSkins = Instance.new("Frame")
pageSkins.Size = UDim2.fromScale(1, 1)
pageSkins.BackgroundTransparency = 1
pageSkins.Visible = false
pageSkins.Parent = modalBody

local pageTitles = Instance.new("Frame")
pageTitles.Size = UDim2.fromScale(1, 1)
pageTitles.BackgroundTransparency = 1
pageTitles.Visible = false
pageTitles.Parent = modalBody

local shopHandler = ShopDailyUI.initShop(screenGui, modalBackdrop, Remotes, UITheme)
local shopWindow = shopHandler.window
local pageIndex = Instance.new("Frame")
pageIndex.Size = UDim2.fromScale(1, 1)
pageIndex.BackgroundTransparency = 1
pageIndex.Visible = false
pageIndex.Parent = modalBody

local pageWheel = Instance.new("Frame")
pageWheel.Name = "PageWheel"
pageWheel.Size = UDim2.fromScale(1, 1)
pageWheel.BackgroundTransparency = 1
pageWheel.Visible = false
pageWheel.Parent = modalBody

local pageProfile = Instance.new("Frame")
pageProfile.Name = "PageProfile"
pageProfile.Size = UDim2.fromScale(1, 1)
pageProfile.BackgroundTransparency = 1
pageProfile.Visible = false
pageProfile.Parent = modalBody

-- ============================================================
-- Build Page 1A: DAILY REWARDS (Figma 03_Screens_Free_Menu_Shell_Daily_Tab node 25:4)
-- ============================================================
local dailyHandler = ShopDailyUI.initDaily(pageFreeDaily, Remotes, UITheme, GameConfig)
-- Build Page 1B: GROUP REWARD (Sunburst + Like + Join = Chest)
-- ============================================================
local btnClaimGroup: TextButton
do
local groupSunburst = Instance.new("Frame")
groupSunburst.Name = "GroupSunburst"
groupSunburst.Size = UDim2.fromScale(1, 1)
groupSunburst.BackgroundColor3 = UITheme.Colors.BlueTop
UITheme.addCorner(groupSunburst, 10)
UITheme.applyGradient(groupSunburst, Color3.fromHex("#38BDF8"), Color3.fromHex("#0284C7"), 90)
UITheme.addStuds(groupSunburst, 0.88, 24)
groupSunburst.Parent = pageFreeGroup

local groupSub = makeLabel(groupSunburst, "Like the game & join the group!", UDim2.new(0.94, 0, 0.14, 0), UDim2.new(0.03, 0, 0.04, 0), UITheme.Colors.White)
UITheme.styleText(groupSub, 24, 14, 3)

local likeCard = Instance.new("Frame")
likeCard.Size = UDim2.new(0.24, 0, 0.48, 0)
likeCard.Position = UDim2.new(0.05, 0, 0.20, 0)
likeCard.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(likeCard, 10)
UITheme.applyStroke(likeCard, 3, UITheme.Colors.Black)
UITheme.addBevel(likeCard, 10)
UITheme.addShadow(likeCard, 10, 3)
likeCard.Parent = groupSunburst

local likeIcon = makeLabel(likeCard, "👍", UDim2.fromScale(0.85, 0.55), UDim2.new(0.075, 0, 0.08, 0))
likeIcon.Name = "Icon_Like"
likeIcon.TextScaled = true

local likeLbl = makeLabel(likeCard, "LIKE", UDim2.new(0.88, 0, 0.26, 0), UDim2.new(0.06, 0, 0.66, 0), UITheme.Colors.NoticeYellow)
UITheme.styleText(likeLbl, 22, 12, 3, UITheme.Colors.NoticeYellow)

local plusLbl = makeLabel(groupSunburst, "+", UDim2.new(0.06, 0, 0.20, 0), UDim2.new(0.31, 0, 0.34, 0), UITheme.Colors.White)
UITheme.styleText(plusLbl, 36, 20, 3)

local joinCard = Instance.new("Frame")
joinCard.Size = UDim2.new(0.24, 0, 0.48, 0)
joinCard.Position = UDim2.new(0.39, 0, 0.20, 0)
joinCard.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(joinCard, 10)
UITheme.applyStroke(joinCard, 3, UITheme.Colors.Black)
UITheme.addBevel(joinCard, 10)
joinCard.Parent = groupSunburst

local joinIcon = makeLabel(joinCard, "👥", UDim2.fromScale(0.85, 0.55), UDim2.new(0.075, 0, 0.08, 0))
joinIcon.Name = "Icon_Group"
joinIcon.TextScaled = true

local joinLbl = makeLabel(joinCard, "JOIN", UDim2.new(0.88, 0, 0.26, 0), UDim2.new(0.06, 0, 0.66, 0), UITheme.Colors.NoticeYellow)
UITheme.styleText(joinLbl, 22, 12, 3, UITheme.Colors.NoticeYellow)

local equalsLbl = makeLabel(groupSunburst, "=", UDim2.new(0.06, 0, 0.20, 0), UDim2.new(0.65, 0, 0.34, 0), UITheme.Colors.White)
UITheme.styleText(equalsLbl, 36, 20, 3)

local rewardChestCard = Instance.new("Frame")
rewardChestCard.Size = UDim2.new(0.26, 0, 0.48, 0)
rewardChestCard.Position = UDim2.new(0.72, 0, 0.20, 0)
rewardChestCard.BackgroundTransparency = 1
rewardChestCard.Parent = groupSunburst

local groupCashIcon = Instance.new("ImageLabel")
groupCashIcon.Name = "Icon_Cash"
groupCashIcon.Size = UDim2.fromScale(0.90, 0.58)
groupCashIcon.AnchorPoint = Vector2.new(0.5, 0.5)
groupCashIcon.Position = UDim2.new(0.5, 0, 0.34, 0)
groupCashIcon.BackgroundTransparency = 1
groupCashIcon.Image = UITheme.Assets.CashStack
groupCashIcon.ScaleType = Enum.ScaleType.Fit
groupCashIcon.Parent = rewardChestCard

local rewardValLbl = makeLabel(rewardChestCard, "$250", UDim2.new(0.96, 0, 0.32, 0), UDim2.new(0.02, 0, 0.64, 0), UITheme.Colors.MoneyGreen)
UITheme.styleText(rewardValLbl, 28, 16, 3.5, UITheme.Colors.MoneyGreen)

btnClaimGroup = makeButton(groupSunburst, "", UDim2.new(0.46, 0, 0.20, 0), UDim2.new(0.27, 0, 0.74, 0), UITheme.Colors.LimeTop)
UITheme.styleButton(btnClaimGroup, "Lime", 10)
local claimGrpLbl = Instance.new("TextLabel")
claimGrpLbl.Name = "BtnLabel"
claimGrpLbl.Size = UDim2.fromScale(1, 1)
claimGrpLbl.Position = UDim2.fromScale(0, 0)
claimGrpLbl.BackgroundTransparency = 1
claimGrpLbl.Font = UITheme.Fonts.Primary
claimGrpLbl.Text = "CLAIM $250!"
claimGrpLbl.TextColor3 = UITheme.Colors.White
claimGrpLbl.TextScaled = true
claimGrpLbl.ZIndex = btnClaimGroup.ZIndex + 3
UITheme.styleText(claimGrpLbl, 26, 14, 3.5)
claimGrpLbl.Parent = btnClaimGroup
UITheme.addPulse(btnClaimGroup)
UITheme.addShineSweep(btnClaimGroup)
btnClaimGroup.Activated:Connect(function()
	Remotes.MetaAction:FireServer("ClaimGroup")
end)
end -- Page 1B Group block

-- ============================================================
-- Build Page 1C: PLAYTIME REWARDS (Prompt 4 / R6 Layout)
-- ============================================================
local ptRail = Instance.new("Frame")
ptRail.Name = "MilestoneRail"
ptRail.Size = UDim2.new(0.80, 0, 0, 14)
ptRail.Position = UDim2.new(0.09, 0, 0.025, 0)
ptRail.BackgroundColor3 = Color3.fromHex("#1B1B1F")
UITheme.addCorner(ptRail, 4)
UITheme.applyStroke(ptRail, 2, UITheme.Colors.Black)
ptRail.Parent = pageFreePlaytime

local ptRailFill = Instance.new("Frame")
ptRailFill.Name = "RailFill"
ptRailFill.Size = UDim2.fromScale(0, 1)
ptRailFill.BackgroundColor3 = Color3.fromHex("#7CFF2B")
ptRailFill.BorderSizePixel = 0
UITheme.addCorner(ptRailFill, 3)
ptRailFill.Parent = ptRail

local playtimeNodes: { [string]: Frame } = {}
local playtimeNodeIcons: { [string]: TextLabel } = {}
local playtimeButtons: { [string]: TextButton } = {}
local playtimeCardFrames: { [string]: Frame } = {}
local playtimeInsetFrames: { [string]: Frame } = {}
local playtimeLockBadges: { [string]: ImageLabel } = {}

-- 6 Cards: cards 1..5 ~14.2% width, card 6 ~18.5% width (1.3x wider & ~3% taller)
local cardWidths = { 0.142, 0.142, 0.142, 0.142, 0.142, 0.185 }
local cardHeights = { 0.69, 0.69, 0.69, 0.69, 0.69, 0.72 }
local cardXPos = { 0.02, 0.174, 0.328, 0.482, 0.636, 0.790 }

for i, pt in GameConfig.PLAYTIME_REWARDS do
	-- Milestone Node centered directly above each card
	local nX = cardXPos[i] + cardWidths[i] * 0.5
	local node = Instance.new("Frame")
	node.Name = `Node_{pt.id}`
	node.Size = UDim2.fromOffset(22, 22)
	node.AnchorPoint = Vector2.new(0.5, 0.5)
	node.Position = UDim2.new((nX - 0.09) / 0.80, 0, 0.5, 0)
	node.BackgroundColor3 = Color3.fromHex("#3A3A40")
	UITheme.addCorner(node, 4)
	UITheme.applyStroke(node, 2, UITheme.Colors.Black)
	node.ZIndex = ptRail.ZIndex + 2
	node.Parent = ptRail

	local nodeLbl = makeLabel(node, "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(0, 0, 0))
	nodeLbl.Font = UITheme.Fonts.Titles
	nodeLbl.TextSize = 16
	nodeLbl.Parent = node
	playtimeNodes[pt.id] = node
	playtimeNodeIcons[pt.id] = nodeLbl

	-- Card Container
	local card = Instance.new("Frame")
	card.Name = `Card_{pt.id}`
	card.Size = UDim2.new(cardWidths[i], 0, cardHeights[i], 0)
	card.Position = UDim2.new(cardXPos[i], 0, if i == 6 then 0.075 else 0.09, 0)
	UITheme.addCorner(card, 6)
	UITheme.applyStroke(card, 3, UITheme.Colors.Black)
	card.Parent = pageFreePlaytime
	playtimeCardFrames[pt.id] = card

	if i <= 4 then
		UITheme.applyGradient(card, Color3.fromHex("#2F7FE6"), Color3.fromHex("#1A4DAA"), 90)
	elseif i == 5 then
		UITheme.applyGradient(card, Color3.fromHex("#7B3FDB"), Color3.fromHex("#4A1FA0"), 90)
		-- Ribbon +SPINS! tilted +12 deg
		local rib = makeLabel(card, "+SPINS!", UDim2.new(0.68, 0, 0.095, 0), UDim2.new(0.36, 0, -0.02, 0), UITheme.Colors.White)
		rib.BackgroundColor3 = Color3.fromHex("#E52F9B")
		rib.BackgroundTransparency = 0
		rib.Rotation = 12
		rib.ZIndex = card.ZIndex + 5
		UITheme.addCorner(rib, 3)
		UITheme.applyStroke(rib, 2, UITheme.Colors.Black)
	elseif i == 6 then
		UITheme.applyGradient(card, Color3.fromHex("#B86A1E"), Color3.fromHex("#6E3E10"), 90)
		-- Ribbon +CHAIR! tilted +12 deg
		local rib = makeLabel(card, "+CHAIR!", UDim2.new(0.64, 0, 0.092, 0), UDim2.new(0.40, 0, -0.02, 0), UITheme.Colors.White)
		rib.BackgroundColor3 = Color3.fromHex("#F2A41F")
		rib.BackgroundTransparency = 0
		rib.Rotation = 12
		rib.ZIndex = card.ZIndex + 5
		UITheme.addCorner(rib, 3)
		UITheme.applyStroke(rib, 2, UITheme.Colors.Black)
	end

	-- Inset Icon Frame (~86% width, ~40% height)
	local inset = Instance.new("Frame")
	inset.Name = "InsetFrame"
	inset.Size = UDim2.new(0.86, 0, 0.40, 0)
	inset.Position = UDim2.new(0.07, 0, 0.04, 0)
	inset.BackgroundColor3 = if i == 5 then Color3.fromHex("#6A2FC0") elseif i == 6 then Color3.fromHex("#C98A3A") else Color3.fromHex("#1E5CC0")
	UITheme.addCorner(inset, 5)
	UITheme.applyStroke(inset, 2, UITheme.Colors.Black)
	inset.Parent = card
	playtimeInsetFrames[pt.id] = inset

	-- Icon inside frame (~80% size)
	local iconObj: GuiObject
	if not pt.chair and i <= 3 then
		local cashImg = Instance.new("ImageLabel")
		cashImg.Name = "Icon_Cash"
		cashImg.Size = UDim2.fromScale(0.82, 0.82)
		cashImg.AnchorPoint = Vector2.new(0.5, 0.5)
		cashImg.Position = UDim2.fromScale(0.5, 0.5)
		cashImg.BackgroundTransparency = 1
		cashImg.Image = UITheme.Assets.CashStack
		cashImg.ScaleType = Enum.ScaleType.Fit
		cashImg.Parent = inset
		iconObj = cashImg
	else
		local iconTxt = if pt.chair then "🪑" elseif i == 5 then "📦" else "📦"
		local iconLbl = makeLabel(inset, iconTxt, UDim2.fromScale(0.82, 0.82), UDim2.fromScale(0.09, 0.09), UITheme.Colors.White)
		iconLbl.TextScaled = true
		iconObj = iconLbl
	end

	-- Orange Lock badge at bottom-right of inset frame (~28% width)
	local lockBadge = Instance.new("ImageLabel")
	lockBadge.Name = "Icon_Lock"
	lockBadge.Size = UDim2.fromOffset(22, 22)
	lockBadge.Position = UDim2.new(1, -22, 1, -22)
	lockBadge.BackgroundTransparency = 1
	lockBadge.Image = "rbxassetid://6031082533" -- Padlock icon
	lockBadge.ImageColor3 = Color3.fromHex("#F59E0B")
	lockBadge.ZIndex = inset.ZIndex + 3
	lockBadge.Parent = inset
	playtimeLockBadges[pt.id] = lockBadge

	-- Amount label ($200, $500, etc.) Lime #7CFF2B, Stroke 4
	local amtLbl = makeLabel(card, pt.rewardLabel, UDim2.new(0.96, 0, 0.12, 0), UDim2.new(0.02, 0, 0.46, 0), UITheme.Colors.MoneyLime)
	UITheme.styleText(amtLbl, 18, 11, 3.5, UITheme.Colors.MoneyLime)

	-- Time label (5 MIN, 10 MIN, etc.) White, Stroke 3
	local timeLbl = makeLabel(card, pt.timeLabel, UDim2.new(0.96, 0, 0.09, 0), UDim2.new(0.02, 0, 0.59, 0), UITheme.Colors.White)
	UITheme.styleText(timeLbl, 13, 9, 2.5, UITheme.Colors.White)

	-- Chip row on 1 HOUR card (Spin x2)
	if i == 5 then
		local chip = makeLabel(card, "🎡 x2", UDim2.new(0.90, 0, 0.08, 0), UDim2.new(0.05, 0, 0.69, 0), Color3.fromHex("#BFDBFE"))
		UITheme.styleText(chip, 12, 8, 2, Color3.fromHex("#BFDBFE"))
	end

	-- Bottom Control Pill / CLAIM button
	local cBtn = makeButton(card, "5:00", UDim2.new(0.92, 0, 0.12, 0), UDim2.new(0.04, 0, 0.84, 0), Color3.fromHex("#17181D"))
	UITheme.styleButton(cBtn, "Dark", 5)
	cBtn.TextWrapped = false

	-- Inner progress fill inside timer pill
	local progFill = Instance.new("Frame")
	progFill.Name = "ProgressFill"
	progFill.Size = UDim2.fromScale(0, 1)
	progFill.BackgroundColor3 = Color3.fromHex("#FFB830")
	progFill.BorderSizePixel = 0
	progFill.ZIndex = cBtn.ZIndex - 1
	UITheme.addCorner(progFill, 5)
	progFill.Parent = cBtn

	cBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("ClaimPlaytime", pt.id)
	end)
	playtimeButtons[pt.id] = cBtn
end

-- Bottom Row: Stopwatch + "M:SS played" (never clipped) & SKIP ALL button
local playedElapsedLabel = makeLabel(pageFreePlaytime, "⏱️ 0:00 played", UDim2.new(0.35, 0, 0.12, 0), UDim2.new(0.03, 0, 0.85, 0), UITheme.Colors.White)
playedElapsedLabel.TextXAlignment = Enum.TextXAlignment.Left
UITheme.styleText(playedElapsedLabel, 20, 11, 3)

local btnSkipAllPlaytime = makeButton(pageFreePlaytime, "", UDim2.new(0.28, 0, 0.12, 0), UDim2.new(0.36, 0, 0.85, 0), UITheme.Colors.GoldTop)
UITheme.styleButton(btnSkipAllPlaytime, "Gold", 6)
UITheme.createRobuxBadge(btnSkipAllPlaytime, 49, UDim2.fromOffset(54, 24), UDim2.new(1, -44, 0, -8))

local skipAllLbl = Instance.new("TextLabel")
skipAllLbl.Name = "BtnLabel"
skipAllLbl.Size = UDim2.new(1, -48, 1, 0)
skipAllLbl.Position = UDim2.new(0, 6, 0, 0)
skipAllLbl.BackgroundTransparency = 1
skipAllLbl.Font = UITheme.Fonts.Primary
skipAllLbl.Text = "⏩ SKIP ALL"
skipAllLbl.TextColor3 = UITheme.Colors.White
skipAllLbl.TextScaled = true
skipAllLbl.ZIndex = btnSkipAllPlaytime.ZIndex + 3
UITheme.styleText(skipAllLbl, 18, 10, 3)
skipAllLbl.Parent = btnSkipAllPlaytime

btnSkipAllPlaytime.Activated:Connect(function()
	Remotes.MetaAction:FireServer("BuyShopItem", "skip_all_playtime")
end)

-- ============================================================
-- Build Page 2: DAILY QUESTS (3 Rows)
-- ============================================================
local questProgLabels: { [string]: TextLabel } = {}
local questClaimBtns: { [string]: TextButton } = {}
do
for i, q in GameConfig.QUESTS do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.98, 0, 0.30, 0)
	row.Position = UDim2.new(0.01, 0, (i - 1) * 0.33, 0)
	row.BackgroundColor3 = UITheme.Colors.CardBg
	UITheme.addCorner(row, 10)
	UITheme.applyStroke(row, 3, UITheme.Colors.Black)
	UITheme.addStuds(row, 0.90, 20)
	UITheme.addBevel(row, 10)
	UITheme.addShadow(row, 10, 3)
	row.Parent = pageQuests

	makeLabel(row, q.title, UDim2.new(0.60, 0, 0.46, 0), UDim2.new(0.03, 0, 0.06, 0), UITheme.Colors.White)
	makeLabel(row, `REWARD: {q.rewardLabel}`, UDim2.new(0.34, 0, 0.40, 0), UDim2.new(0.64, 0, 0.08, 0), UITheme.Colors.NoticeYellow)

	local progLbl = makeLabel(row, `0/{q.target}`, UDim2.new(0.56, 0, 0.36, 0), UDim2.new(0.03, 0, 0.56, 0), UITheme.Colors.White)
	progLbl.BackgroundTransparency = 0
	progLbl.BackgroundColor3 = UITheme.Colors.CardDark
	UITheme.addCorner(progLbl, 8)
	UITheme.applyStroke(progLbl, 2, UITheme.Colors.Black)
	questProgLabels[q.id] = progLbl

	local cBtn = makeButton(row, "CLAIM", UDim2.new(0.30, 0, 0.38, 0), UDim2.new(0.66, 0, 0.54, 0), UITheme.Colors.GrayTop)
	UITheme.styleButton(cBtn, "Gray", 6)
	cBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("ClaimQuest", q.id)
	end)
	questClaimBtns[q.id] = cBtn
end
end -- Page 2 Quests block

-- ============================================================
-- Build Page 3: CHAIR SKINS + LUCKY WHEEL SPIN + LUCK UPGRADE (Prompt 5 / R7)
-- ============================================================
pageSkins.Name = "PageSkins"
local wheelSpinBtn: TextButton
local luckUpgradeBtn: TextButton
local skinActionBtns: { [string]: TextButton } = {}
local skinNameLabels: { [string]: TextLabel } = {}

do
	-- Top Slim Action Row (above grid: Y=0.015, Height=0.09)
	local actionRow = Instance.new("Frame")
	actionRow.Name = "ActionRow"
	actionRow.Size = UDim2.new(0.92, 0, 0.09, 0)
	actionRow.Position = UDim2.new(0.04, 0, 0.015, 0)
	actionRow.BackgroundTransparency = 1
	actionRow.Parent = pageSkins

	-- Purple SPIN WHEEL button (Left)
	local wSpin = Instance.new("TextButton")
	wSpin.Name = "BtnSpinWheel"
	wSpin.Size = UDim2.new(0.485, 0, 1, 0)
	wSpin.Position = UDim2.new(0, 0, 0, 0)
	wSpin.Text = ""
	UITheme.styleButton(wSpin, "Purple", 8)
	UITheme.addPulse(wSpin, 1.0, 1.03, 1.5)

	local wheelIcon = Instance.new("ImageLabel")
	wheelIcon.Name = "Icon_Wheel"
	wheelIcon.Size = UDim2.fromOffset(28, 28)
	wheelIcon.Position = UDim2.new(0, 14, 0.5, 0)
	wheelIcon.AnchorPoint = Vector2.new(0, 0.5)
	wheelIcon.BackgroundTransparency = 1
	wheelIcon.Image = UITheme.Assets.Icon_Wheel ~= "rbxassetid://0" and UITheme.Assets.Icon_Wheel or UITheme.Assets.CashStack
	wheelIcon.ScaleType = Enum.ScaleType.Fit
	wheelIcon.ZIndex = wSpin.ZIndex + 3
	wheelIcon.Parent = wSpin

	local spinBtnLbl = Instance.new("TextLabel")
	spinBtnLbl.Name = "BtnLabel"
	spinBtnLbl.Size = UDim2.new(1, -50, 1, 0)
	spinBtnLbl.Position = UDim2.new(0, 46, 0, 0)
	spinBtnLbl.BackgroundTransparency = 1
	spinBtnLbl.Font = UITheme.Fonts.Primary
	spinBtnLbl.TextColor3 = UITheme.Colors.White
	spinBtnLbl.Text = "SPIN WHEEL (1)"
	spinBtnLbl.TextScaled = true
	UITheme.addTextConstraint(spinBtnLbl, 12, 18)
	UITheme.applyTextStroke(spinBtnLbl, 2.5, UITheme.Colors.Black)
	spinBtnLbl.ZIndex = wSpin.ZIndex + 3
	spinBtnLbl.Parent = wSpin
	wSpin.Parent = actionRow

	wSpin.Activated:Connect(function()
		openModal("WHEEL")
	end)
	wheelSpinBtn = wSpin

	-- Dark green LUCK upgrade pill button (Right)
	local lUp = Instance.new("TextButton")
	lUp.Name = "BtnLuckUpgrade"
	lUp.Size = UDim2.new(0.485, 0, 1, 0)
	lUp.Position = UDim2.new(0.515, 0, 0, 0)
	lUp.Text = ""
	UITheme.styleButton(lUp, "TabInactive", 8)

	local cloverIcon = Instance.new("ImageLabel")
	cloverIcon.Name = "Icon_Clover"
	cloverIcon.Size = UDim2.fromOffset(28, 28)
	cloverIcon.Position = UDim2.new(0, 14, 0.5, 0)
	cloverIcon.AnchorPoint = Vector2.new(0, 0.5)
	cloverIcon.BackgroundTransparency = 1
	cloverIcon.Image = UITheme.Assets.Icon_Luck ~= "rbxassetid://0" and UITheme.Assets.Icon_Luck or UITheme.Assets.CloverIcon
	cloverIcon.ScaleType = Enum.ScaleType.Fit
	cloverIcon.ZIndex = lUp.ZIndex + 3
	cloverIcon.Parent = lUp

	local luckBtnLbl = Instance.new("TextLabel")
	luckBtnLbl.Name = "BtnLabel"
	luckBtnLbl.Size = UDim2.new(1, -50, 1, 0)
	luckBtnLbl.Position = UDim2.new(0, 46, 0, 0)
	luckBtnLbl.BackgroundTransparency = 1
	luckBtnLbl.Font = UITheme.Fonts.Primary
	luckBtnLbl.TextColor3 = UITheme.Colors.White
	luckBtnLbl.Text = "LUCK: 1x -> 1.5x ($750)"
	luckBtnLbl.TextScaled = true
	UITheme.addTextConstraint(luckBtnLbl, 12, 18)
	UITheme.applyTextStroke(luckBtnLbl, 2.5, UITheme.Colors.Black)
	luckBtnLbl.ZIndex = lUp.ZIndex + 3
	luckBtnLbl.Parent = lUp
	lUp.Parent = actionRow

	lUp.Activated:Connect(function()
		Remotes.MetaAction:FireServer("UpgradeLuck")
	end)
	luckUpgradeBtn = lUp

	-- Card Grid: 3 columns x 2 rows (Y=0.13, Card width=0.29, gap=0.025, aspect ~1:1)
	local cardW = 0.29
	local cardGap = 0.025
	local leftPad = 0.04
	local rowH = 0.40
	local rowGap = 0.03
	local topPad = 0.13

	-- Rarity color mapping (ADAPTATION: CONFIG NAME_COLOR_BY_RARITY = true)
	local rarityColors = {
		wood = Color3.fromHex("#B47040"),       -- Common rustic brown
		stadium = Color3.fromHex("#38BDF8"),    -- Rare sky blue
		crimson = Color3.fromHex("#F87171"),    -- Epic crimson red
		emerald = Color3.fromHex("#4ADE80"),    -- Legendary emerald green
		cyber = Color3.fromHex("#C084FC"),      -- Mythic neon purple
		golden = Color3.fromHex("#FBBF24"),     -- Divine trophy gold
	}

	for i, skin in GameConfig.CHAIR_SKINS do
		local col = (i - 1) % 3
		local r = math.floor((i - 1) / 3)
		local posX = leftPad + col * (cardW + cardGap)
		local posY = topPad + r * (rowH + rowGap)

		local card = Instance.new("Frame")
		card.Name = `ChairCard_{skin.id}`
		card.Size = UDim2.new(cardW, 0, rowH, 0)
		card.Position = UDim2.new(posX, 0, posY, 0)
		card.BackgroundColor3 = Color3.fromHex("#0D0F14")
		card.BackgroundTransparency = 0.45
		card.BorderSizePixel = 0
		UITheme.addCorner(card, 10)
		UITheme.applyStroke(card, 3, Color3.new(0, 0, 0)) -- Black 3px stroke on ALL cards (R7)
		card.Parent = pageSkins

		-- Chair Name at top: Gold #FFC83D or rarity color, stroke 3, wrapped cleanly
		local displayName = if skin.id == "golden" then "Golden Ball" else skin.name
		local nameColor = if UITheme.CONFIG.NAME_COLOR_BY_RARITY ~= false and rarityColors[skin.id]
			then rarityColors[skin.id]
			else Color3.fromHex("#FFC83D")

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "SkinName"
		nameLbl.Size = UDim2.new(0.92, 0, 0.18, 0)
		nameLbl.Position = UDim2.new(0.04, 0, 0.04, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = UITheme.Fonts.Titles
		nameLbl.TextColor3 = nameColor
		nameLbl.Text = displayName
		nameLbl.TextScaled = true
		nameLbl.TextWrapped = true
		nameLbl.ZIndex = card.ZIndex + 3
		UITheme.addTextConstraint(nameLbl, 12, 17)
		UITheme.applyTextStroke(nameLbl, 3, Color3.new(0, 0, 0))
		nameLbl.Parent = card
		skinNameLabels[skin.id] = nameLbl

		-- 3D Chair Viewport or Image (~50% card height)
		local chairVp = Instance.new("ViewportFrame")
		chairVp.Name = "Icon_Chair"
		chairVp.Size = UDim2.new(0.88, 0, 0.50, 0)
		chairVp.Position = UDim2.new(0.06, 0, 0.22, 0)
		chairVp.BackgroundTransparency = 1
		chairVp.BorderSizePixel = 0
		chairVp.ZIndex = card.ZIndex + 2
		chairVp.Parent = card

		local cam = Instance.new("Camera")
		cam.FieldOfView = 24
		cam.CFrame = CFrame.new(Vector3.new(2.8, 2.3, 3.2), Vector3.new(0, 0.75, 0))
		cam.Parent = chairVp
		chairVp.CurrentCamera = cam
		chairVp.LightColor = Color3.fromRGB(255, 255, 255)
		chairVp.Ambient = Color3.fromRGB(240, 240, 250)
		chairVp.LightDirection = Vector3.new(-0.35, -0.60, 0.72)

		local chairModel = Instance.new("Model")
		chairModel.Name = "MiniChair"

		local seat = Instance.new("Part")
		seat.Name = "Seat"
		seat.Size = Vector3.new(1.4, 0.2, 1.4)
		seat.CFrame = CFrame.new(0, 0.8, 0)
		seat.Color = skin.color
		seat.Material = skin.mat
		seat.Anchored = true
		seat.Parent = chairModel

		local back = Instance.new("Part")
		back.Name = "Back"
		back.Size = Vector3.new(1.4, 1.3, 0.2)
		back.CFrame = CFrame.new(0, 1.5, -0.6)
		back.Color = skin.color
		back.Material = skin.mat
		back.Anchored = true
		back.Parent = chairModel

		for _, lx in { -0.55, 0.55 } do
			for _, lz in { -0.55, 0.55 } do
				local leg = Instance.new("Part")
				leg.Name = "Leg"
				leg.Size = Vector3.new(0.18, 0.8, 0.18)
				leg.CFrame = CFrame.new(lx, 0.4, lz)
				leg.Color = skin.color
				leg.Material = skin.mat
				leg.Anchored = true
				leg.Parent = chairModel
			end
		end
		chairModel.Parent = chairVp

		-- Action Button (~80% card width x ~17% height)
		local sBtn = Instance.new("TextButton")
		sBtn.Name = `BtnSkin_{skin.id}`
		sBtn.Size = UDim2.new(0.80, 0, 0.17, 0)
		sBtn.Position = UDim2.new(0.10, 0, 0.76, 0)
		sBtn.Parent = card

		UITheme.skinButton(sBtn, if skin.cost == 0 then "EQUIPPED" else "BUY", skin.cost, false)

		sBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyOrEquipChair", skin.id)
		end)
		skinActionBtns[skin.id] = sBtn
	end
end -- Page 3 Skins block

-- Build Page 4: TITLES (Wins Header + Rows + Robux Unlock Button)
-- ============================================================
local titlesWinsHeader: TextLabel
local titleActionBtns: { [string]: TextButton } = {}
do
local winsHeaderFrame = Instance.new("Frame")
winsHeaderFrame.Name = "WinsHeaderFrame"
winsHeaderFrame.Size = UDim2.new(0.5, 0, 0.10, 0)
winsHeaderFrame.Position = UDim2.new(0.25, 0, 0.015, 0)
winsHeaderFrame.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(winsHeaderFrame, 8)
UITheme.applyStroke(winsHeaderFrame, 2.5, UITheme.Colors.Black)
UITheme.addStuds(winsHeaderFrame, 0.88, 18)
UITheme.addBevel(winsHeaderFrame, 8)
winsHeaderFrame.Parent = pageTitles

local trophyImg = Instance.new("ImageLabel")
trophyImg.Name = "Icon_Trophy"
trophyImg.Size = UDim2.fromScale(0.75, 0.75)
trophyImg.AnchorPoint = Vector2.new(0, 0.5)
trophyImg.Position = UDim2.new(0.08, 0, 0.5, 0)
trophyImg.BackgroundTransparency = 1
trophyImg.Image = UITheme.Assets.TrophyIcon
trophyImg.ScaleType = Enum.ScaleType.Fit
trophyImg.ZIndex = winsHeaderFrame.ZIndex + 2
trophyImg.Parent = winsHeaderFrame

titlesWinsHeader = makeLabel(winsHeaderFrame, "WINS: 0", UDim2.new(0.70, 0, 0.80, 0), UDim2.new(0.25, 0, 0.10, 0), UITheme.Colors.NoticeYellow)
titlesWinsHeader.TextXAlignment = Enum.TextXAlignment.Center
titlesWinsHeader.ZIndex = winsHeaderFrame.ZIndex + 2
UITheme.styleText(titlesWinsHeader, 24, 16, 3, UITheme.Colors.NoticeYellow)
for i = #GameConfig.TITLES, 1, -1 do
	local rowIdx = (#GameConfig.TITLES - i) + 1
	local entry = GameConfig.TITLES[i]
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.96, 0, 0.16, 0)
	row.Position = UDim2.new(0.02, 0, 0.13 + (rowIdx - 1) * 0.172, 0)
	row.BackgroundColor3 = UITheme.Colors.CardBg
	UITheme.addCorner(row, 8)
	UITheme.applyStroke(row, 3, UITheme.Colors.Black)
	UITheme.addStuds(row, 0.90, 20)
	UITheme.addBevel(row, 8)
	UITheme.addShadow(row, 8, 3)
	row.Parent = pageTitles

	local nameLbl = makeLabel(row, entry.name, UDim2.new(0.50, 0, 0.8, 0), UDim2.new(0.04, 0, 0.1, 0), entry.color)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left

	local tBtn = makeButton(row, "LOCKED", UDim2.new(0.28, 0, 0.76, 0), UDim2.new(0.56, 0, 0.12, 0), UITheme.Colors.GrayTop)
	UITheme.styleButton(tBtn, "Gray", 6)
	tBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("EquipTitle", entry.name)
	end)
	titleActionBtns[entry.name] = tBtn

	-- Purple Robux Instant Unlock Button
	local robuxUnlockBtn = makeButton(row, "⬡", UDim2.new(0.12, 0, 0.76, 0), UDim2.new(0.86, 0, 0.12, 0), UITheme.Colors.PurpleTop)
	UITheme.styleButton(robuxUnlockBtn, "Purple", 6)
	robuxUnlockBtn.Activated:Connect(function()
		Remotes.MetaAction:FireServer("BuyShopItem", "unlock_title_" .. string.lower(entry.name))
	end)
end
end -- Page 4 Titles block

-- ============================================================
-- Build Page 5: SHOP (Managed by ShopDailyUI)
-- ============================================================
-- Build Page 6: CARD INDEX / POKEDEX (152 Footballers sorted Mythic -> Common)
-- ============================================================
local indexProgressHeader = makeLabel(pageIndex, "DISCOVERED: 0 / 152 (0%) • +$25–$250 PER NEW CARD!", UDim2.new(0.96, 0, 0.11, 0), UDim2.new(0.02, 0, 0, 0), UITheme.Colors.NoticeYellow)
local indexCardCells: { [string]: { frame: Frame, label: TextLabel, card: Footballers.Footballer } } = {}
do
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

-- Build Page 7: SPIN WHEEL VIEW (Auto-opened by stepping into Lobby SpinWheelStation ring)
local wheelSpinning = false
local wheelCurrentRot = 0
local lastHandledWheelSeq = (localPlayer:GetAttribute("WheelSpinSeq") :: number?) or 0

local wheelRotVal = Instance.new("NumberValue")
local wheelSpinsCountLbl: TextLabel
local spinBtnLabel: TextLabel
local refreshProfileGlobalRanks: () -> ()
local updateProfilePage: (p: any, elapsed: number, disc: { [string]: boolean }, discCount: number, pct: number) -> ()

do
	local wheelOuterRim = Instance.new("Frame")
wheelOuterRim.Name = "WheelOuterRim"
wheelOuterRim.Size = UDim2.fromOffset(258, 258)
wheelOuterRim.Position = UDim2.new(0.03, 0, 0.5, -129)
wheelOuterRim.BackgroundColor3 = Color3.fromRGB(36, 41, 54)
addCorner(wheelOuterRim, 129)
addStroke(wheelOuterRim, Color3.new(0, 0, 0), 4)
wheelOuterRim.Parent = pageWheel

local wheelDiscGui = Instance.new("Frame")
wheelDiscGui.Name = "WheelDisc"
wheelDiscGui.Size = UDim2.fromOffset(230, 230)
wheelDiscGui.AnchorPoint = Vector2.new(0.5, 0.5)
wheelDiscGui.Position = UDim2.fromScale(0.5, 0.5)
wheelDiscGui.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
wheelDiscGui.ClipsDescendants = true
addCorner(wheelDiscGui, 115)
wheelDiscGui.Parent = wheelOuterRim

local wheelVp = Instance.new("ViewportFrame")
wheelVp.Name = "WheelViewport"
wheelVp.Size = UDim2.fromScale(1, 1)
wheelVp.BackgroundTransparency = 1
wheelVp.Ambient = Color3.new(1, 1, 1)
wheelVp.LightColor = Color3.new(0, 0, 0)
wheelVp.ZIndex = 26
addCorner(wheelVp, 115)
wheelVp.Parent = wheelDiscGui

local wheelVpCam = Instance.new("Camera")
wheelVpCam.FieldOfView = 18
wheelVpCam.CFrame = CFrame.new(0, 0, 36.8)
wheelVpCam.Parent = wheelVp
wheelVp.CurrentCamera = wheelVpCam

local wheel3DModel = Instance.new("Model")
wheel3DModel.Name = "Wheel3D"
local wheelPivot = Instance.new("Part")
wheelPivot.Name = "Pivot"
wheelPivot.Size = Vector3.new(0.2, 0.2, 0.2)
wheelPivot.Transparency = 1
wheelPivot.Anchored = true
wheelPivot.CFrame = CFrame.new(0, 0, 0)
wheelPivot.Parent = wheel3DModel
wheel3DModel.PrimaryPart = wheelPivot
wheel3DModel.Parent = wheelVp

local wheelLabelsLayer = Instance.new("Frame")
wheelLabelsLayer.Name = "WheelLabelsLayer"
wheelLabelsLayer.Size = UDim2.fromOffset(230, 230)
wheelLabelsLayer.AnchorPoint = Vector2.new(0.5, 0.5)
wheelLabelsLayer.Position = UDim2.fromScale(0.5, 0.5)
wheelLabelsLayer.BackgroundTransparency = 1
wheelLabelsLayer.ZIndex = 27
wheelLabelsLayer.Parent = wheelOuterRim

do
	local vpRadius = 6.2
	local halfA = math.rad(22.5)
	local wH = vpRadius * math.cos(halfA)
	local wW = vpRadius * math.sin(halfA)
	for i, seg in GameConfig.WHEEL_SEGMENTS do
		local deg = (i - 1) * 45
		local sliceCF = CFrame.Angles(0, 0, -math.rad(deg))
		local segCol = Color3.fromHex(seg.color)
		for _, side in { -1, 1 } do
			local wp = Instance.new("WedgePart")
			wp.Size = Vector3.new(0.2, wH, wW)
			wp.CFrame = sliceCF
				* CFrame.fromMatrix(
					Vector3.new(side * wW * 0.5, wH * 0.5, 0),
					Vector3.new(0, 0, -side),
					Vector3.new(0, -1, 0),
					Vector3.new(-side, 0, 0)
				)
			wp.Anchored = true
			wp.Color = segCol
			wp.Material = Enum.Material.SmoothPlastic
			wp.Parent = wheel3DModel
		end
		local spoke = Instance.new("Part")
		spoke.Size = Vector3.new(0.14, vpRadius, 0.26)
		spoke.CFrame = CFrame.Angles(0, 0, -math.rad(deg + 22.5)) * CFrame.new(0, vpRadius * 0.5, 0.06)
		spoke.Anchored = true
		spoke.Color = Color3.fromRGB(22, 25, 34)
		spoke.Material = Enum.Material.SmoothPlastic
		spoke.Parent = wheel3DModel

		local lRad = math.rad(deg)
		local lx = 115 + math.sin(lRad) * 69
		local ly = 115 - math.cos(lRad) * 69
		local lblBox = Instance.new("Frame")
		lblBox.Name = `SliceLabel_{i}`
		lblBox.Size = UDim2.fromOffset(58, 52)
		lblBox.AnchorPoint = Vector2.new(0.5, 0.5)
		lblBox.Position = UDim2.fromOffset(lx, ly)
		lblBox.Rotation = deg
		lblBox.BackgroundTransparency = 1
		lblBox.ZIndex = 28
		lblBox.Parent = wheelLabelsLayer

		local pIcon = Instance.new("ImageLabel")
		pIcon.Name = "SliceIcon"
		pIcon.Size = UDim2.fromOffset(20, 20)
		pIcon.Position = UDim2.new(0.5, -10, 0, 2)
		pIcon.BackgroundTransparency = 1
		pIcon.Image = if seg.id == 4 then UITheme.Assets.CrownIcon else UITheme.Assets.CashStack
		pIcon.ScaleType = Enum.ScaleType.Fit
		pIcon.ZIndex = 29
		pIcon.Parent = lblBox

		local pTxt = Instance.new("TextLabel")
		pTxt.Name = "SliceText"
		pTxt.Size = UDim2.new(1, 0, 0, 26)
		pTxt.Position = UDim2.new(0, 0, 0, 24)
		pTxt.BackgroundTransparency = 1
		pTxt.Font = UITheme.Fonts.Primary
		pTxt.TextColor3 = if seg.id == 4 then UITheme.Colors.NoticeYellow else UITheme.Colors.White
		pTxt.Text = seg.label
		pTxt.TextScaled = true
		UITheme.addTextConstraint(pTxt, 10, 14)
		UITheme.applyTextStroke(pTxt, 2, UITheme.Colors.Black)
		pTxt.ZIndex = 29
		pTxt.Parent = lblBox

		local bulbRad = math.rad(deg + 22.5 - 90)
		local bx = 129 + math.cos(bulbRad) * 121
		local by = 129 + math.sin(bulbRad) * 121
		local bulb = Instance.new("Frame")
		bulb.Size = UDim2.fromOffset(10, 10)
		bulb.AnchorPoint = Vector2.new(0.5, 0.5)
		bulb.Position = UDim2.fromOffset(bx, by)
		bulb.BackgroundColor3 = Color3.fromRGB(255, 214, 58)
		bulb.BorderSizePixel = 0
		bulb.ZIndex = 30
		addCorner(bulb, 5)
		bulb.Parent = wheelOuterRim
	end
end

	wheelRotVal.Changed:Connect(function(v)
		wheelLabelsLayer.Rotation = v
		wheel3DModel:PivotTo(CFrame.Angles(0, 0, -math.rad(v)))
	end)

	local wheelHubCap = Instance.new("Frame")
	wheelHubCap.Size = UDim2.fromOffset(48, 48)
	wheelHubCap.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelHubCap.Position = UDim2.fromScale(0.5, 0.5)
	wheelHubCap.BackgroundColor3 = Color3.fromHex("#C81E2B")
	wheelHubCap.ZIndex = 31
	addCorner(wheelHubCap, 24)
	addStroke(wheelHubCap, Color3.fromRGB(32, 36, 48), 5)
	wheelHubCap.Parent = wheelOuterRim

	local pointerClip = Instance.new("Frame")
	pointerClip.Size = UDim2.fromOffset(38, 24)
	pointerClip.AnchorPoint = Vector2.new(0.5, 0)
	pointerClip.Position = UDim2.new(0.5, 0, 0, -6)
	pointerClip.BackgroundTransparency = 1
	pointerClip.ClipsDescendants = true
	pointerClip.ZIndex = 32
	pointerClip.Parent = wheelOuterRim

	local pointerDiamond = Instance.new("Frame")
	pointerDiamond.Size = UDim2.fromOffset(26, 26)
	pointerDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
	pointerDiamond.Position = UDim2.fromOffset(19, 2)
	pointerDiamond.Rotation = 45
	pointerDiamond.BackgroundColor3 = Color3.fromHex("#DC2626")
	pointerDiamond.ZIndex = 32
	addStroke(pointerDiamond, Color3.fromRGB(20, 22, 30), 2)
	pointerDiamond.Parent = pointerClip

	local wheelRightPane = Instance.new("Frame")
	wheelRightPane.Size = UDim2.new(0.50, 0, 0.94, 0)
	wheelRightPane.Position = UDim2.new(0.48, 0, 0.03, 0)
	wheelRightPane.BackgroundTransparency = 1
	wheelRightPane.Parent = pageWheel

	local wheelSpinsPlate = Instance.new("Frame")
	wheelSpinsPlate.Name = "WheelSpinsPlate"
	wheelSpinsPlate.Size = UDim2.new(1, 0, 0, 42)
	wheelSpinsPlate.Position = UDim2.new(0, 0, 0, 0)
	wheelSpinsPlate.BackgroundColor3 = UITheme.Colors.CardBg
	UITheme.addCorner(wheelSpinsPlate, 10)
	UITheme.applyStroke(wheelSpinsPlate, 3, UITheme.Colors.GoldBottom)
	UITheme.addStuds(wheelSpinsPlate, 0.90, 20)
	UITheme.addBevel(wheelSpinsPlate, 10)
	UITheme.addShadow(wheelSpinsPlate, 10, 3)
	wheelSpinsPlate.Parent = wheelRightPane

	wheelSpinsCountLbl = Instance.new("TextLabel")
	wheelSpinsCountLbl.Name = "SpinsCountText"
	wheelSpinsCountLbl.Size = UDim2.new(0.92, 0, 0.8, 0)
	wheelSpinsCountLbl.Position = UDim2.new(0.04, 0, 0.1, 0)
	wheelSpinsCountLbl.BackgroundTransparency = 1
	wheelSpinsCountLbl.Font = UITheme.Fonts.Titles
	wheelSpinsCountLbl.TextColor3 = UITheme.Colors.NoticeYellow
	wheelSpinsCountLbl.Text = "🎟️ AVAILABLE SPINS: 1"
	wheelSpinsCountLbl.TextScaled = true
	UITheme.applyTextStroke(wheelSpinsCountLbl, 2.5, UITheme.Colors.Black)
	wheelSpinsCountLbl.Parent = wheelSpinsPlate

	local wheelOddsList = {
		{ text = "$150 — 45%", col = Color3.fromHex("#1D7BF6"), icon = UITheme.Assets.CashStack },
		{ text = "$350 — 30%", col = Color3.fromHex("#22C55E"), icon = UITheme.Assets.CashStack },
		{ text = "$750 — 17%", col = Color3.fromHex("#F59E0B"), icon = UITheme.Assets.CashStack },
		{ text = "CYBER CHAIR + $500 — 8%", col = Color3.fromHex("#FF2E93"), icon = UITheme.Assets.CrownIcon },
	}
	for idx, item in wheelOddsList do
		local row = Instance.new("Frame")
		row.Name = `OddsRow_{idx}`
		row.Size = UDim2.new(1, 0, 0, 42)
		row.Position = UDim2.new(0, 0, 0, 48 + (idx - 1) * 46)
		row.BackgroundColor3 = UITheme.Colors.CardBg
		UITheme.addCorner(row, 8)
		UITheme.applyStroke(row, 3, item.col)
		UITheme.addStuds(row, 0.90, 20)
		UITheme.addBevel(row, 8)
		UITheme.addShadow(row, 8, 3)
		row.Parent = wheelRightPane

		local rIcon = Instance.new("ImageLabel")
		rIcon.Name = "RowIcon"
		rIcon.Size = UDim2.fromOffset(24, 24)
		rIcon.Position = UDim2.new(0, 10, 0.5, -12)
		rIcon.BackgroundTransparency = 1
		rIcon.Image = item.icon
		rIcon.ScaleType = Enum.ScaleType.Fit
		rIcon.ZIndex = row.ZIndex + 2
		rIcon.Parent = row

		local rTxt = Instance.new("TextLabel")
		rTxt.Name = "RowText"
		rTxt.Size = UDim2.new(1, -44, 0.8, 0)
		rTxt.Position = UDim2.new(0, 40, 0.1, 0)
		rTxt.BackgroundTransparency = 1
		rTxt.Font = UITheme.Fonts.Primary
		rTxt.TextColor3 = UITheme.Colors.White
		rTxt.TextXAlignment = Enum.TextXAlignment.Left
		rTxt.Text = item.text
		rTxt.TextScaled = true
		UITheme.addTextConstraint(rTxt, 11, 16)
		UITheme.applyTextStroke(rTxt, 2.5, UITheme.Colors.Black)
		rTxt.ZIndex = row.ZIndex + 2
		rTxt.Parent = row
	end

	local btnDoSpinWheel = Instance.new("TextButton")
	btnDoSpinWheel.Name = "BtnDoSpinWheel"
	btnDoSpinWheel.Size = UDim2.new(1, 0, 0, 56)
	btnDoSpinWheel.Position = UDim2.new(0, 0, 1, -58)
	btnDoSpinWheel.Text = ""
	UITheme.styleButton(btnDoSpinWheel, "Lime", 10)
	UITheme.addStuds(btnDoSpinWheel, 0.85, 20)
	UITheme.addPulse(btnDoSpinWheel, 1.0, 1.04, 1.2)
	UITheme.addShineSweep(btnDoSpinWheel, 3.0)

	spinBtnLabel = Instance.new("TextLabel")
	spinBtnLabel.Name = "BtnLabel"
	spinBtnLabel.Size = UDim2.new(0.92, 0, 0.8, 0)
	spinBtnLabel.Position = UDim2.new(0.04, 0, 0.1, 0)
	spinBtnLabel.BackgroundTransparency = 1
	spinBtnLabel.Font = UITheme.Fonts.Primary
	spinBtnLabel.TextColor3 = UITheme.Colors.White
	spinBtnLabel.Text = "🎡 SPIN WHEEL (1)"
	spinBtnLabel.TextScaled = true
	UITheme.addTextConstraint(spinBtnLabel, 14, 22)
	UITheme.applyTextStroke(spinBtnLabel, 3, UITheme.Colors.Black)
	spinBtnLabel.ZIndex = btnDoSpinWheel.ZIndex + 3
	spinBtnLabel.Parent = btnDoSpinWheel
	btnDoSpinWheel.Parent = wheelRightPane

	btnDoSpinWheel.Activated:Connect(function()
		if wheelSpinning then
			return
		end
		Remotes.MetaAction:FireServer("SpinWheel")
	end)

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
local function hideAllModalPages()
	pageFreeDaily.Visible = false
	pageFreeGroup.Visible = false
	pageFreePlaytime.Visible = false
	pageQuests.Visible = false
	pageSkins.Visible = false
	pageTitles.Visible = false
	pageShop.Visible = false
	pageIndex.Visible = false
	pageWheel.Visible = false
	pageProfile.Visible = false
	freeTabsBar.Visible = false
end

local function openShop()
	if modalWrap.Visible then
		modalWrap.Visible = false
	end
	modalBackdrop.Visible = true
	shopHandler.open()
end

local function closeShop()
	modalBackdrop.Visible = false
	shopHandler.close()
end

local function openFreeTab(tab: "DAILY" | "GROUP" | "PLAYTIME")
	if shopWindow.Visible then
		shopWindow.Visible = false
	end
	modalBackdrop.Visible = true
	UITheme.animateWindowOpen(modalWrap, modalBox)
	hideAllModalPages()
	freeTabsBar.Visible = true

	setTabActive(btnTabDaily, tab == "DAILY", "📅 DAILY")
	setTabActive(btnTabGroup, tab == "GROUP", "👥 GROUP")
	setTabActive(btnTabPlaytime, tab == "PLAYTIME", "⏰ PLAYTIME")

	if tab == "DAILY" then
		UITheme.styleHeader(modalHeader, "Daily", "DAILY REWARDS")
		pageFreeDaily.Visible = true
		if cachedProfile then
			local activeDay = cachedProfile.DailyDay or 1
			if activeDay >= 4 then
			dailyHandler.scrollToActiveDay(activeDay)
			else
			end
		end
	elseif tab == "GROUP" then
		UITheme.styleHeader(modalHeader, "Gold", "GROUP REWARD", "Like + Join = free cash!")
		pageFreeGroup.Visible = true
	else
		UITheme.styleHeader(modalHeader, "Blue", "PLAYTIME REWARDS", "Resets in 18:39:12")
		UITheme.styleButton(btnCloseModal, "Red", 6)
		pageFreePlaytime.Visible = true
	end
end

local function openModal(kind: "FREE" | "QUESTS" | "SKINS" | "TITLES" | "SHOP" | "INDEX" | "WHEEL" | "PROFILE")
	if kind == "SHOP" then
		openShop()
		return
	end
	if shopWindow.Visible then
		shopWindow.Visible = false
	end
	if kind == "FREE" then
		openFreeTab("DAILY")
		return
	end
	modalBackdrop.Visible = true
	UITheme.animateWindowOpen(modalWrap, modalBox)
	hideAllModalPages()

	if kind == "QUESTS" then
		UITheme.styleHeader(modalHeader, "Lime", "DAILY QUESTS")
		pageQuests.Visible = true
	elseif kind == "SKINS" then
		UITheme.styleHeader(modalHeader, "ChairSkins", "CHAIR SKINS")
		UITheme.styleButton(btnCloseModal, "Magenta", 10)
		pageSkins.Visible = true
	elseif kind == "TITLES" then
		UITheme.styleHeader(modalHeader, "Cyan", "TITLES")
		pageTitles.Visible = true
	elseif kind == "INDEX" then
		UITheme.styleHeader(modalHeader, "Magenta", "CARD INDEX (152 FOOTBALLERS)")
		pageIndex.Visible = true
	elseif kind == "WHEEL" then
		UITheme.styleHeader(modalHeader, "Purple", "PRIZE SPIN WHEEL")
		pageWheel.Visible = true
	elseif kind == "PROFILE" then
		UITheme.styleHeader(modalHeader, "Blue", "PLAYER PROFILE & STATS TRACKER")
		pageProfile.Visible = true
		refreshProfileGlobalRanks()
	end
end

btnCloseModal.Activated:Connect(function()
	modalBackdrop.Visible = false
	UITheme.animateWindowClose(modalWrap, modalBox)
end)
modalBackdrop.Activated:Connect(function()
	modalBackdrop.Visible = false
	UITheme.animateWindowClose(modalWrap, modalBox)
	if shopWindow.Visible then
		closeShop()
	end
end)
btnNavFree.Activated:Connect(function()
	openModal("FREE")
end)
btnTopDaily.Activated:Connect(function()
	openModal("FREE")
end)
btnTopQuests.Activated:Connect(function()
	openModal("QUESTS")
end)
btnNavShop.Activated:Connect(function()
	openShop()
end)
btnNavSkins.Activated:Connect(function()
	openModal("SKINS")
end)
btnNavTitles.Activated:Connect(function()
	openModal("TITLES")
end)
btnNavIndex.Activated:Connect(function()
	openModal("INDEX")
end)
btnNavProfile.Activated:Connect(function()
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
btnTabDaily.Activated:Connect(function()
	openFreeTab("DAILY")
end)
btnTabGroup.Activated:Connect(function()
	openFreeTab("GROUP")
end)
btnTabPlaytime.Activated:Connect(function()
	openFreeTab("PLAYTIME")
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
overlay.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
overlay.BackgroundTransparency = 0.35
overlay.Visible = false
overlay.Parent = screenGui

local modeSubLabel = makeLabel(overlay, "DEFAULT MODE", UDim2.new(0.4, 0, 0, 20), UDim2.new(0.30, 0, 0, 8), Color3.new(1, 1, 1))
local headerLabel = makeLabel(overlay, "BUILD A FOOTBALLER", UDim2.new(0.6, 0, 0, 44), UDim2.new(0.2, 0, 0, 24), Color3.new(1, 1, 1))
local winnerNameLabel = makeLabel(overlay, "", UDim2.new(0.5, 0, 0, 42), UDim2.new(0.25, 0, 0, 64), Color3.new(1, 1, 1))
winnerNameLabel.Visible = false
local timerLabel = makeLabel(overlay, "15", UDim2.new(0.2, 0, 0, 42), UDim2.new(0.4, 0, 0, 66), Color3.new(1, 1, 1))

-- ============================================================
-- 2A. SEATED WAITING SCREEN ("INVITE FRIENDS", "LEAVE" + "FIGHT WITH AI -> PLAY!")
-- ============================================================
local waitingWrap = Instance.new("Frame")
waitingWrap.Name = "WaitingWrap"
waitingWrap.Size = UDim2.fromScale(1, 1)
waitingWrap.BackgroundTransparency = 1
waitingWrap.Visible = false
waitingWrap.Parent = overlay

local btnWaitInvite = makeButton(waitingWrap, "", UDim2.fromOffset(232, 48), UDim2.new(0.50, -116, 0.70, 0), Color3.fromHex("#FFD21F"))
do
	local ink = Color3.fromRGB(15, 17, 22)
	local iconWrap = Instance.new("Frame")
	iconWrap.Name = "UserPlusIcon"
	iconWrap.Size = UDim2.fromOffset(30, 26)
	iconWrap.Position = UDim2.new(0, 14, 0.5, -13)
	iconWrap.BackgroundTransparency = 1
	iconWrap.Parent = btnWaitInvite

	local headDot = Instance.new("Frame")
	headDot.Name = "Head"
	headDot.Size = UDim2.fromOffset(11, 11)
	headDot.Position = UDim2.fromOffset(5, 1)
	headDot.BackgroundColor3 = ink
	headDot.BorderSizePixel = 0
	headDot.Parent = iconWrap
	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(1, 0)
	hc.Parent = headDot

	local bodyClip = Instance.new("Frame")
	bodyClip.Name = "ShouldersClip"
	bodyClip.Size = UDim2.fromOffset(21, 12)
	bodyClip.Position = UDim2.fromOffset(0, 12)
	bodyClip.BackgroundTransparency = 1
	bodyClip.ClipsDescendants = true
	bodyClip.Parent = iconWrap

	local dome = Instance.new("Frame")
	dome.Name = "Shoulders"
	dome.Size = UDim2.fromOffset(21, 24)
	dome.Position = UDim2.fromOffset(0, 0)
	dome.BackgroundColor3 = ink
	dome.BorderSizePixel = 0
	dome.Parent = bodyClip
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dome

	local plusH = Instance.new("Frame")
	plusH.Name = "PlusH"
	plusH.Size = UDim2.fromOffset(11, 3)
	plusH.Position = UDim2.fromOffset(19, 12)
	plusH.BackgroundColor3 = ink
	plusH.BorderSizePixel = 0
	plusH.Parent = iconWrap
	local phc = Instance.new("UICorner")
	phc.CornerRadius = UDim.new(1, 0)
	phc.Parent = plusH

	local plusV = Instance.new("Frame")
	plusV.Name = "PlusV"
	plusV.Size = UDim2.fromOffset(3, 11)
	plusV.Position = UDim2.fromOffset(23, 8)
	plusV.BackgroundColor3 = ink
	plusV.BorderSizePixel = 0
	plusV.Parent = iconWrap
	local pvc = Instance.new("UICorner")
	pvc.CornerRadius = UDim.new(1, 0)
	pvc.Parent = plusV

	local inviteLbl = makeLabel(btnWaitInvite, "INVITE FRIENDS", UDim2.new(1, -62, 0, 28), UDim2.new(0, 50, 0.5, -14), Color3.new(1, 1, 1))
	inviteLbl.Name = "InviteLabel"
end
btnWaitInvite.Activated:Connect(function()
	pcall(function()
		SocialService:PromptGameInvite(localPlayer)
	end)
end)

local btnWaitLeave = makeButton(waitingWrap, "LEAVE", UDim2.fromOffset(232, 46), UDim2.new(0.50, -116, 0.785, 0), Color3.fromHex("#E5252A"))
btnWaitLeave.Activated:Connect(function()
	Remotes.MatchAction:FireServer("LeaveTable")
end)

local aiBox = Instance.new("Frame")
aiBox.Size = UDim2.fromOffset(190, 118)
aiBox.Position = UDim2.new(0.50, 130, 0.68, 0)
aiBox.BackgroundTransparency = 1
aiBox.Parent = waitingWrap

makeLabel(aiBox, "TIRED OF WAITING?", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 0), Color3.new(1, 1, 1))
makeLabel(aiBox, "FIGHT WITH AI", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 20), Color3.fromHex("#FFA500"))
local btnPlayBotNow = makeButton(aiBox, "PLAY!", UDim2.new(0.86, 0, 0, 52), UDim2.new(0.07, 0, 0, 52), Color3.fromHex("#22C55E"))
btnPlayBotNow.Activated:Connect(function()
	Remotes.MatchAction:FireServer("PlayBotNow")
end)

-- ============================================================
-- 2B. INTRO SCREEN ("<Player> VS <BOT> / DEFAULT MODE") & COUNTDOWN ("3, 2, 1, GO!")
-- ============================================================
local introWrap = Instance.new("Frame")
introWrap.Name = "IntroWrap"
introWrap.Size = UDim2.fromScale(1, 1)
introWrap.BackgroundTransparency = 1
introWrap.Visible = false
introWrap.Parent = overlay

local introMyName = makeLabel(introWrap, "Player", UDim2.new(0.6, 0, 0, 54), UDim2.new(0.2, 0, 0.34, 0), Color3.fromHex("#1E6FFF"))
local introVs = makeLabel(introWrap, "VS", UDim2.new(0.3, 0, 0, 48), UDim2.new(0.35, 0, 0.43, 0), Color3.fromHex("#FFA500"))
local introOppName = makeLabel(introWrap, "BOT", UDim2.new(0.6, 0, 0, 56), UDim2.new(0.2, 0, 0.51, 0), Color3.fromHex("#FF2E93"))
local introMode = makeLabel(introWrap, "DEFAULT MODE", UDim2.new(0.4, 0, 0, 32), UDim2.new(0.3, 0, 0.61, 0), Color3.new(1, 1, 1))

local countdownWrap = Instance.new("Frame")
countdownWrap.Name = "CountdownWrap"
countdownWrap.Size = UDim2.fromScale(1, 1)
countdownWrap.BackgroundTransparency = 1
countdownWrap.Visible = false
countdownWrap.Parent = overlay

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

local function createBuildCard(parent: Instance, posScale: UDim2)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(186, 214)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = posScale
	frame.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
	frame.ClipsDescendants = true
	addCorner(frame, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = frame
	frame.Parent = parent

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(75, 88, 115), Color3.fromRGB(22, 26, 36))
	grad.Rotation = 90
	grad.Parent = frame

	-- Real 3D Footballer Viewport inside the card (hair, face, skin, club shirt & club shorts)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "ModelViewport"
	viewport.Size = UDim2.new(1, 0, 0.65, 0)
	viewport.Position = UDim2.new(0, 0, 0, 0)
	viewport.BackgroundTransparency = 1
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.Ambient = Color3.fromRGB(185, 192, 208)
	viewport.LightDirection = Vector3.new(-0.45, -0.75, 0.65)
	viewport.Parent = frame

	local vpCam = Instance.new("Camera")
	vpCam.FieldOfView = 36
	vpCam.CFrame = CFrame.lookAt(Vector3.new(0.90, 0.84, -7.75), Vector3.new(0, 0.66, 0))
	vpCam.Parent = viewport
	viewport.CurrentCamera = vpCam

	local posTag = makeLabel(frame, "ST", UDim2.fromOffset(36, 20), UDim2.fromOffset(8, 8), Color3.new(1, 1, 1))
	posTag.BackgroundTransparency = 0.25
	posTag.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	posTag.ZIndex = 4
	addCorner(posTag, 6)

	-- Bottom Dark Overlay (Real Full Name, Real Club - Real Country, Rarity)
	local bottomBox = Instance.new("Frame")
	bottomBox.Size = UDim2.new(1, 0, 0.38, 0)
	bottomBox.Position = UDim2.new(0, 0, 0.62, 0)
	bottomBox.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
	bottomBox.BackgroundTransparency = 0.10
	bottomBox.BorderSizePixel = 0
	bottomBox.ZIndex = 3
	bottomBox.Parent = frame

	local nameLbl = makeLabel(bottomBox, "William Saliba", UDim2.new(0.92, 0, 0, 26), UDim2.new(0.04, 0, 0, 4), Color3.new(1, 1, 1))
	nameLbl.ZIndex = 4
	local clubLbl = makeLabel(bottomBox, "Arsenal - France", UDim2.new(0.94, 0, 0, 19), UDim2.new(0.03, 0, 0, 31), Color3.fromRGB(205, 212, 225))
	clubLbl.ZIndex = 4
	local rarityLbl = makeLabel(bottomBox, "Legendary", UDim2.new(0.92, 0, 0, 22), UDim2.new(0.04, 0, 0, 52), GameConfig.RARITY_COLORS.Legendary)
	rarityLbl.ZIndex = 4

	local dimVeil = Instance.new("Frame")
	dimVeil.Size = UDim2.fromScale(1, 1)
	dimVeil.BackgroundColor3 = Color3.new(0, 0, 0)
	dimVeil.BackgroundTransparency = 0.42
	dimVeil.Visible = false
	dimVeil.ZIndex = 6
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

local function setCardSilhouette(widget: any, randomCard: any)
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

local function populateBuildCard(widget: any, card: any, isMine: boolean?, isDimmed: boolean?)
	if not card then
		widget.frame.Visible = false
		widget.lastId = nil
		return
	end
	widget.frame.Visible = true
	widget.dimVeil.Visible = isDimmed == true
	if widget.lastId ~= card.id then
		widget.lastId = card.id
		popGui(widget.frame, 0.84)
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
buildCenterWrap.Parent = overlay

local function createMiniAvatarBox(parent: Instance, pos: UDim2, _borderCol: Color3)
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromOffset(108, 108)
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = pos
	img.BackgroundTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = parent
	return img
end

local buildMyAvatar = createMiniAvatarBox(buildCenterWrap, UDim2.fromScale(0.415, 0.21), Color3.fromHex("#1E6FFF"))
local buildOppAvatar = createMiniAvatarBox(buildCenterWrap, UDim2.fromScale(0.585, 0.21), Color3.fromHex("#E5252A"))

local myCardWidget = createBuildCard(buildCenterWrap, UDim2.fromScale(0.415, 0.46))
local oppCardWidget = createBuildCard(buildCenterWrap, UDim2.fromScale(0.585, 0.46))
local vsCenterLabel = makeLabel(buildCenterWrap, "VS", UDim2.fromOffset(52, 40), UDim2.new(0.5, -26, 0.46, -20), Color3.fromHex("#FFD21F"))

local rolledInfoLabel = makeLabel(overlay, "ROLLING...", UDim2.new(0.46, 0, 0, 32), UDim2.new(0.27, 0, 0.68, 0), Color3.new(1, 1, 1))
local luckBtn = makeButton(buildCenterWrap, "      LUCK: 1x [→1.5x $750]", UDim2.fromOffset(216, 30), UDim2.new(0.5, -108, 0.74, 0), Color3.fromHex("#22C55E"))
UITheme.styleButton(luckBtn, "Lime", 6)
UITheme.addStuds(luckBtn, 0.88, 16)

do
	local matchClover = Instance.new("ImageLabel")
	matchClover.Name = "Icon_Clover"
	matchClover.Size = UDim2.fromOffset(24, 24)
	matchClover.Position = UDim2.new(0, 6, 0.5, -12)
	matchClover.BackgroundTransparency = 1
	matchClover.Image = UITheme.Assets.CloverIcon
	matchClover.ScaleType = Enum.ScaleType.Fit
	mat... (truncated)
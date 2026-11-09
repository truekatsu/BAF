_G.oc = {}
_G.oc[1] = [=[--!strict
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
	lobby = { sound = createBgm("BGM_Lobby", "rbxassetid://1838601519"), targetVol = 0.22 }, -- Samba E Futebol (Perc & Brass)
	build = { sound = createBgm("BGM_Build", "rbxassetid://103016391217295"), targetVol = 0.22 }, -- Stellar Drift (Liquid Drum & Bass)
	showdown = { sound = createBgm("BGM_Showdown", "rbxassetid://1846418124"), targetVol = 0.25 }, -- Swagger March B (Stadium Drumline)
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
modalWrap.Size = UDim2.fromOffset(760, 500)
modalWrap.AnchorPoint = Vector2.new(0.5, 0.5)
modalWrap.Position = UDim2.fromScale(0.5, 0.50)
modalWrap.BackgroundTransparency = 1
modalWrap.ZIndex = 25
modalWrap.Visible = false
modalWrap.Parent = screenGui

local modalBox = Instance.new("Frame")
modalBox.Name = "ModalBox"
modalBox.Size = UDim2.new(1, 0, 0, 442)
modalBox.BackgroundColor3 = UITheme.Colors.WindowBody
modalBox.BackgroundTransparency = 0.10
UITheme.addCorner(modalBox, 14)
UITheme.applyStroke(modalBox, 4, UITheme.Colors.Black)
UITheme.addStuds(modalBox, 0.88, 24)
UITheme.addShadow(modalBox, 14, 6)

local modalBoxScale = Instance.new("UIScale")
modalBoxScale.Scale = 1.0
modalBoxScale.Parent = modalBox
modalBox.Parent = modalWrap

local modalHeader = Instance.new("Frame")
modalHeader.Name = "ModalHeader"
modalHeader.Size = UDim2.new(1, 0, 0, 58)
modalHeader.BackgroundColor3 = UITheme.Colors.OrangeTop
UITheme.addCorner(modalHeader, 14)
UITheme.applyStroke(modalHeader, 4, UITheme.Colors.Black)
UITheme.applyGradient(modalHeader, UITheme.Colors.OrangeTop, UITheme.Colors.OrangeBottom, 90)
UITheme.addStuds(modalHeader, 0.85, 22)
UITheme.addBevel(modalHeader, 14)
modalHeader.Parent = modalBox

local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "HeaderTitle"
modalTitle.Size = UDim2.new(0.80, 0, 0.78, 0)
modalTitle.Position = UDim2.new(0.03, 0, 0.11, 0)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = UITheme.Fonts.Titles
modalTitle.TextColor3 = UITheme.Colors.White
modalTitle.TextStrokeTransparency = 0
modalTitle.TextStrokeColor3 = UITheme.Colors.Black
modalTitle.TextScaled = true
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.Text = "DAILY REWARDS"
modalTitle.ZIndex = modalHeader.ZIndex + 2
modalTitle.Parent = modalHeader

local btnCloseModal = makeButton(modalHeader, "X", UDim2.fromOffset(42, 42), UDim2.new(1, -50, 0, 8), UITheme.Colors.RedTop)
UITheme.styleButton(btnCloseModal, "Red", 8)
btnCloseModal.ZIndex = modalHeader.ZIndex + 3

local modalBody = Instance.new("Frame")
modalBody.Name = "ModalBody"
modalBody.Size = UDim2.new(0.96, 0, 1, -72)
modalBody.Position = UDim2.new(0.02, 0, 0, 66)
modalBody.BackgroundTransparency = 1
modalBody.Parent = modalBox

-- Bottom Tab Bar for FREE Modal (DAILY | GROUP | PLAYTIME)
local freeTabsBar = Instance.new("Frame")
freeTabsBar.Name = "FreeTabsBar"
freeTabsBar.Size = UDim2.new(0.78, 0, 0, 48)
freeTabsBar.Position = UDim2.new(0.11, 0, 1, -48)
freeTabsBar.BackgroundTransparency = 1
freeTabsBar.Visible = false
freeTabsBar.Parent = modalWrap

local function setTabActive(btn: TextButton, isActive: boolean, text: string)
	UITheme.styleButton(btn, if isActive then "Lime" else "TabInactive", 10)
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

local playtimeTabBadge = makeLabel(btnTabPlaytime, "0", UDim2.fromOffset(24, 24), UDim2.new(1, -14, 0, -8), Color3.new(1, 1, 1))
playtimeTabBadge.BackgroundTransparency = 0
playtimeTabBadge.BackgroundColor3 = Color3.fromHex("#E5252A")
playtimeTabBadge.Visible = false
UITheme.addCorner(playtimeTabBadge, 12)
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

local pageShop = Instance.new("ScrollingFrame")
pageShop.Size = UDim2.fromScale(1, 1)
pageShop.CanvasSize = UDim2.new(0, 0, 0, 660)
pageShop.AutomaticCanvasSize = Enum.AutomaticSize.Y
pageShop.ScrollBarThickness = 10
pageShop.ScrollBarImageColor3 = UITheme.Colors.LimeTop
pageShop.BackgroundTransparency = 1
pageShop.Visible = false
pageShop.Parent = modalBody

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
-- Build Page 1A: DAILY REWARDS (7 Cards + Bottom Controls Row)
-- ============================================================
local dailyCardFrames: { Frame } = {}
local dailyStatusLabels: { TextLabel } = {}
local dailyCountdownLabel: TextLabel
local btnClaimAllDaily: TextButton
local btnClaimDaily: TextButton
do
for i, reward in GameConfig.DAILY_REWARDS do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.134, 0, 0.73, 0)
	card.Position = UDim2.new((i - 1) * 0.143, 0, 0.02, 0)
	card.BackgroundColor3 = UITheme.Colors.CardBg
	UITheme.addCorner(card, 10)
	UITheme.applyStroke(card, 3, UITheme.Colors.Black)
	UITheme.addStuds(card, 0.90, 20)
	UITheme.addBevel(card, 10)
	UITheme.addShadow(card, 10, 3)
	card.Parent = pageFreeDaily

	local dayLbl = makeLabel(card, `DAY {reward.day}`, UDim2.new(0.92, 0, 0.14, 0), UDim2.new(0.04, 0, 0.03, 0), UITheme.Colors.White)
	UITheme.styleText(dayLbl, 16, 10, 2.5)

	if reward.bux > 0 and not reward.chair then
		local cashImg = Instance.new("ImageLabel")
		cashImg.Name = "Icon_Cash"
		cashImg.Size = UDim2.fromScale(0.85, 0.50)
		cashImg.AnchorPoint = Vector2.new(0.5, 0.5)
		cashImg.Position = UDim2.new(0.5, 0, 0.43, 0)
		cashImg.BackgroundTransparency = 1
		cashImg.Image = UITheme.Assets.CashStack
		cashImg.ScaleType = Enum.ScaleType.Fit
		cashImg.Parent = card
	else
		local iconText = if reward.chair then "🪑" elseif reward.spins > 0 then "🎡" else "💵"
		local iconLbl = makeLabel(card, iconText, UDim2.fromScale(0.85, 0.50), UDim2.new(0.075, 0, 0.18, 0), UITheme.Colors.NoticeYellow)
		iconLbl.Name = if reward.chair then "Icon_Chair" else "Icon_Wheel"
		iconLbl.TextScaled = true
	end

	local rewardLbl = makeLabel(card, reward.label, UDim2.new(0.94, 0, 0.16, 0), UDim2.new(0.03, 0, 0.69, 0), UITheme.Colors.MoneyGreen)
	UITheme.styleText(rewardLbl, 15, 10, 2.5, UITheme.Colors.MoneyGreen)

	local st = makeLabel(card, "READY", UDim2.new(0.90, 0, 0.12, 0), UDim2.new(0.05, 0, 0.85, 0), UITheme.Colors.NoticeYellow)
	UITheme.styleText(st, 13, 9, 2, UITheme.Colors.NoticeYellow)

	table.insert(dailyCardFrames, card)
	table.insert(dailyStatusLabels, st)
end

-- Bottom Row: SKIP DAY, Countdown Plate, CLAIM ALL, and Claim Day X Reward
local btnSkipDaily = makeButton(pageFreeDaily, "SKIP DAY", UDim2.new(0.23, 0, 0.18, 0), UDim2.new(0.01, 0, 0.77, 0), UITheme.Colors.CyanTop)
UITheme.styleButton(btnSkipDaily, "Cyan", 8)
btnSkipDaily.TextWrapped = false
local skipSc = btnSkipDaily:FindFirstChildOfClass("UITextSizeConstraint")
if skipSc then skipSc.MaxTextSize = 20 end
UITheme.createRobuxBadge(btnSkipDaily, 12, UDim2.fromOffset(52, 22), UDim2.new(1, -44, 0, -8))

local dailyCountdownPlate = Instance.new("Frame")
dailyCountdownPlate.Name = "DailyCountdownPlate"
dailyCountdownPlate.Size = UDim2.new(0.24, 0, 0.18, 0)
dailyCountdownPlate.Position = UDim2.new(0.26, 0, 0.77, 0)
dailyCountdownPlate.BackgroundColor3 = UITheme.Colors.GrayBottom
UITheme.addCorner(dailyCountdownPlate, 8)
UITheme.applyStroke(dailyCountdownPlate, 3, UITheme.Colors.Black)
UITheme.addStuds(dailyCountdownPlate, 0.88, 20)
UITheme.addBevel(dailyCountdownPlate, 8)
dailyCountdownPlate.Parent = pageFreeDaily

dailyCountdownLabel = makeLabel(dailyCountdownPlate, "18:16:29", UDim2.new(0.96, 0, 0.8, 0), UDim2.new(0.02, 0, 0.1, 0), UITheme.Colors.White)
dailyCountdownLabel.Name = "CountText"
UITheme.styleText(dailyCountdownLabel, 24, 12, 3)

btnClaimAllDaily = makeButton(pageFreeDaily, "CLAIM ALL!", UDim2.new(0.25, 0, 0.18, 0), UDim2.new(0.52, 0, 0.77, 0), UITheme.Colors.GoldTop)
UITheme.styleButton(btnClaimAllDaily, "Gold", 8)
btnClaimAllDaily.TextWrapped = false
local claimAllSc = btnClaimAllDaily:FindFirstChildOfClass("UITextSizeConstraint")
if claimAllSc then claimAllSc.MaxTextSize = 20 end
UITheme.createRobuxBadge(btnClaimAllDaily, 19, UDim2.fromOffset(52, 22), UDim2.new(1, -44, 0, -8))

btnClaimDaily = makeButton(pageFreeDaily, "CLAIM!", UDim2.new(0.20, 0, 0.18, 0), UDim2.new(0.79, 0, 0.77, 0), UITheme.Colors.LimeTop)
UITheme.styleButton(btnClaimDaily, "Lime", 8)
btnClaimDaily.TextWrapped = false
UITheme.addPulse(btnClaimDaily)
UITheme.addShineSweep(btnClaimDaily)

btnClaimDaily.Activated:Connect(function()
	Remotes.MetaAction:FireServer("ClaimDaily")
end)
btnSkipDaily.Activated:Connect(function()
	Remotes.MetaAction:FireServer("BuyShopItem", "skip_daily")
end)
btnClaimAllDaily.Activated:Connect(function()
	Remotes.MetaAction:FireServer("BuyShopItem", "claim_all_daily")
end)
end -- Page 1A Daily block

-- ============================================================
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
-- Build Page 1C: PLAYTIME REWARDS (Milestone Rail + 6 Cards)
-- ============================================================
local ptRail = Instance.new("Frame")
ptRail.Name = "MilestoneRail"
ptRail.Size = UDim2.new(0.96, 0, 0, 8)
ptRail.Position = UDim2.new(0.02, 0, 0.02, 0)
ptRail.BackgroundColor3 = UITheme.Colors.CardDark
UITheme.addCorner(ptRail, 4)
UITheme.applyStroke(ptRail, 2, UITheme.Colors.Black)
ptRail.Parent = pageFreePlaytime

local playtimeButtons: { [string]: TextButton } = {}
for i, pt in GameConfig.PLAYTIME_REWARDS do
	-- Milestone node
	local node = Instance.new("Frame")
	node.Size = UDim2.fromOffset(16, 16)
	node.Position = UDim2.new((i - 1) * 0.168 + 0.07, -8, 0.5, -8)
	node.BackgroundColor3 = UITheme.Colors.NoticeYellow
	UITheme.addCorner(node, 4)
	UITheme.applyStroke(node, 2, UITheme.Colors.Black)
	node.Parent = ptRail

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.156, 0, 0.74, 0)
	card.Position = UDim2.new((i - 1) * 0.168, 0, 0.07, 0)
	card.BackgroundColor3 = if i == 5 then UITheme.Colors.PurpleTop elseif i == 6 then UITheme.Colors.GoldTop else UITheme.Colors.BlueTop
	UITheme.addCorner(card, 10)
	UITheme.applyStroke(card, 3, UITheme.Colors.Black)
	UITheme.addStuds(card, 0.88, 20)
	UITheme.addBevel(card, 10)
	UITheme.addShadow(card, 10, 3)
	card.Parent = pageFreePlaytime

	if i == 5 then
		UITheme.applyGradient(card, UITheme.Colors.PurpleTop, UITheme.Colors.PurpleBottom, 90)
		local tag = makeLabel(card, "+SPINS!", UDim2.new(0.74, 0, 0.13, 0), UDim2.new(0.24, 0, 0.02, 0), UITheme.Colors.White)
		tag.BackgroundColor3 = Color3.fromHex("#FF2E93")
		tag.BackgroundTransparency = 0
		UITheme.addCorner(tag, 4)
		UITheme.applyStroke(tag, 2, UITheme.Colors.Black)
	elseif i == 6 then
		UITheme.applyGradient(card, UITheme.Colors.GoldTop, UITheme.Colors.GoldBottom, 90)
		local tag = makeLabel(card, "+CHAIR!", UDim2.new(0.74, 0, 0.13, 0), UDim2.new(0.24, 0, 0.02, 0), UITheme.Colors.White)
		tag.BackgroundColor3 = Color3.fromHex("#F59E0B")
		tag.BackgroundTransparency = 0
		UITheme.addCorner(tag, 4)
		UITheme.applyStroke(tag, 2, UITheme.Colors.Black)
	else
		UITheme.applyGradient(card, UITheme.Colors.BlueTop, UITheme.Colors.BlueBottom, 90)
	end

	if not pt.chair and i <= 4 then
		local cashImg = Instance.new("ImageLabel")
		cashImg.Name = "Icon_Cash"
		cashImg.Size = UDim2.fromScale(0.85, 0.44)
		cashImg.AnchorPoint = Vector2.new(0.5, 0.5)
		cashImg.Position = UDim2.new(0.5, 0, 0.28, 0)
		cashImg.BackgroundTransparency = 1
		cashImg.Image = UITheme.Assets.CashStack
		cashImg.ScaleType = Enum.ScaleType.Fit
		cashImg.Parent = card
	else
		local icon = if pt.chair then "🪑" elseif i]=]
print("Loaded orig 1")

import re

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

orig_len = len(text)
print("Original length:", orig_len)

# 1. SFX helper scoping
# Replace:
# local sfxFolder = Instance.new("Folder")
# ...
# local function playSfx(kind: string)
# ...
# end
old_sfx = """local sfxFolder = Instance.new("Folder")
sfxFolder.Name = "BAF_SFX"
sfxFolder.Parent = SoundService

local function createSound(name: string, soundId: string, speed: number, vol: number): Sound
\tlocal s = Instance.new("Sound")
\ts.Name = name
\ts.SoundId = soundId
\ts.PlaybackSpeed = speed
\ts.Volume = vol
\ts.Parent = sfxFolder
\treturn s
end

local sfxMap: { [string]: Sound } = {
\tclick = createSound("Click", "rbxasset://sounds/button.wav", 1.25, 0.45),
\troll = createSound("Roll", "rbxasset://sounds/swoosh.wav", 1.15, 0.55),
\trare = createSound("Rare", "rbxasset://sounds/electronicpingshort.wav", 1.45, 0.7),
\treveal = createSound("Reveal", "rbxasset://sounds/electronicpingshort.wav", 1.05, 0.6),
\twin = createSound("Win", "rbxasset://sounds/electronicpingshort.wav", 1.65, 0.8),
\tlose = createSound("Lose", "rbxasset://sounds/swoosh.wav", 0.65, 0.65),
}

local function playSfx(kind: string)
\tlocal s = sfxMap[kind]
\tif s then
\t\tSoundService:PlayLocalSound(s)
\tend
end"""

new_sfx = """local playSfx: (kind: string) -> ()
do
\tlocal sfxFolder = Instance.new("Folder")
\tsfxFolder.Name = "BAF_SFX"
\tsfxFolder.Parent = SoundService

\tlocal function createSound(name: string, soundId: string, speed: number, vol: number): Sound
\t\tlocal s = Instance.new("Sound")
\t\ts.Name = name
\t\ts.SoundId = soundId
\t\ts.PlaybackSpeed = speed
\t\ts.Volume = vol
\t\ts.Parent = sfxFolder
\t\treturn s
\tend

\tlocal sfxMap: { [string]: Sound } = {
\t\tclick = createSound("Click", "rbxasset://sounds/button.wav", 1.25, 0.45),
\t\troll = createSound("Roll", "rbxasset://sounds/swoosh.wav", 1.15, 0.55),
\t\trare = createSound("Rare", "rbxasset://sounds/electronicpingshort.wav", 1.45, 0.7),
\t\treveal = createSound("Reveal", "rbxasset://sounds/electronicpingshort.wav", 1.05, 0.6),
\t\twin = createSound("Win", "rbxasset://sounds/electronicpingshort.wav", 1.65, 0.8),
\t\tlose = createSound("Lose", "rbxasset://sounds/swoosh.wav", 0.65, 0.65),
\t}

\tfunction playSfx(kind: string)
\t\tlocal s = sfxMap[kind]
\t\tif s then
\t\t\tSoundService:PlayLocalSound(s)
\t\tend
\tend
end"""

assert old_sfx in text, "old_sfx not found"
text = text.replace(old_sfx, new_sfx)
print("1. Applied SFX scoping")

# 2. BGM scoping
old_bgm_start = """-- Phase-adaptive Background Music (Lobby Samba/Brass, Build Liquid DnB, Showdown Stadium Drumline)
local function createBgm(name: string, soundId: string): Sound"""

new_bgm_start = """-- Phase-adaptive Background Music (Lobby Samba/Brass, Build Liquid DnB, Showdown Stadium Drumline)
local setBgmPhase: (phase: string) -> ()
do
\tlocal function createBgm(name: string, soundId: string): Sound"""

old_bgm_end = """\t\t\tend)
\t\tend
\tend
end
task.defer(setBgmPhase, "Idle")"""

new_bgm_end = """\t\t\tend)
\t\tend
\tend
\tend
\ttask.defer(setBgmPhase, "Idle")
end"""

assert old_bgm_start in text, "old_bgm_start not found"
assert old_bgm_end in text, "old_bgm_end not found"
text = text.replace(old_bgm_start, new_bgm_start)
# replace local function setBgmPhase with function setBgmPhase
text = text.replace("local function setBgmPhase(phase: string)", "function setBgmPhase(phase: string)", 1)
text = text.replace(old_bgm_end, new_bgm_end, 1)
print("2. Applied BGM scoping")

# 3. MatchBlur scoping
old_blur = """local matchBlur = Lighting:FindFirstChild("BAF_MatchBlur") :: BlurEffect?
if not matchBlur then
\tlocal b = Instance.new("BlurEffect")
\tb.Name = "BAF_MatchBlur"
\tb.Size = 0
\tb.Parent = Lighting
\tmatchBlur = b
end

local function setMatchBlur(enabled: boolean)
\tif matchBlur then
\t\tTweenService:Create(matchBlur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
\t\t\tSize = if enabled then 24 else 0,
\t\t}):Play()
\tend
end"""

new_blur = """local setMatchBlur: (enabled: boolean) -> ()
do
\tlocal matchBlur = Lighting:FindFirstChild("BAF_MatchBlur") :: BlurEffect?
\tif not matchBlur then
\t\tlocal b = Instance.new("BlurEffect")
\tb.Name = "BAF_MatchBlur"
\tb.Size = 0
\tb.Parent = Lighting
\tmatchBlur = b
\tend

\tfunction setMatchBlur(enabled: boolean)
\t\tif matchBlur then
\t\t\tTweenService:Create(matchBlur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
\t\t\t\tSize = if enabled then 24 else 0,
\t\t\t}):Play()
\t\tend
\tend
end"""

assert old_blur in text, "old_blur not found"
text = text.replace(old_blur, new_blur)
print("3. Applied MatchBlur scoping")

# 4. Toast Banner scoping
old_toast = """-- Toast Notification Banner (parented to screenGui so it is visible in both Lobby and Match)
local toastBanner = makeLabel(screenGui, "", UDim2.new(0.44, 0, 0, 38), UDim2.new(0.28, 0, 0, 68), Color3.fromHex("#FFD21F"))
toastBanner.BackgroundTransparency = 0.15
toastBanner.BackgroundColor3 = GameConfig.UI_COLORS.PanelDark
toastBanner.ZIndex = 30
toastBanner.Visible = false
addCorner(toastBanner, 10)
addStroke(toastBanner, Color3.fromHex("#FFD21F"), 2)
local toastToken = 0

local function showToast(msg: string)
\ttoastToken += 1
\tlocal myToken = toastToken
\ttoastBanner.Text = msg
\ttoastBanner.Visible = true
\tplaySfx("rare")
\tpopGui(toastBanner, 0.88)
\ttask.delay(3, function()
\t\tif toastToken == myToken then
\t\t\ttoastBanner.Visible = false
\t\tend
\tend)
end"""

new_toast = """-- Toast Notification Banner (parented to screenGui so it is visible in both Lobby and Match)
local showToast: (msg: string) -> ()
do
\tlocal toastBanner = makeLabel(screenGui, "", UDim2.new(0.44, 0, 0, 38), UDim2.new(0.28, 0, 0, 68), Color3.fromHex("#FFD21F"))
\ttoastBanner.BackgroundTransparency = 0.15
\ttoastBanner.BackgroundColor3 = GameConfig.UI_COLORS.PanelDark
\ttoastBanner.ZIndex = 30
\ttoastBanner.Visible = false
\taddCorner(toastBanner, 10)
\taddStroke(toastBanner, Color3.fromHex("#FFD21F"), 2)
\tlocal toastToken = 0

\tfunction showToast(msg: string)
\t\ttoastToken += 1
\t\tlocal myToken = toastToken
\t\ttoastBanner.Text = msg
\t\ttoastBanner.Visible = true
\t\tplaySfx("rare")
\t\tpopGui(toastBanner, 0.88)
\t\ttask.delay(3, function()
\t\t\tif toastToken == myToken then
\t\t\t\ttoastBanner.Visible = false
\t\t\tend
\t\tend)
\tend
end"""

assert old_toast in text, "old_toast not found"
text = text.replace(old_toast, new_toast)
print("4. Applied Toast Banner scoping")

# 5. TopRightBar scoping
old_top_right = """-- Top-Right Container for Daily Rewards & Quests (parented to screenGui so they remain visible on all screens)
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
\tlocal btn = Instance.new("ImageButton")
\tbtn.Name = name
\tbtn.Size = size
\tbtn.BackgroundTransparency = 1
\tbtn.Image = imageId
\tbtn.ScaleType = Enum.ScaleType.Fit
\tbtn.LayoutOrder = layoutOrder
\tbtn.ZIndex = 20
\tbtn.Parent = topRightBar

\tUITheme.setupButtonHover(btn, 1.05, 0)
\tbtn.Activated:Connect(function()
\t\tplaySfx("click")
\t\tpopGui(btn, 0.93)
\tend)

\treturn btn
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
UITheme.applyStroke(questBadge, 2, UITheme.Colors.Black)"""

new_top_right = """-- Top-Right Container for Daily Rewards & Quests (parented to screenGui so they remain visible on all screens)
local btnTopDaily: ImageButton
local btnTopQuests: ImageButton
local questBadge: TextLabel
do
\tlocal topRightBar = Instance.new("Frame")
\ttopRightBar.Name = "TopRightBar"
\ttopRightBar.Size = UDim2.new(0, 300, 0, 42)
\ttopRightBar.Position = UDim2.new(1, -16, 0, 14)
\ttopRightBar.AnchorPoint = Vector2.new(1, 0)
\ttopRightBar.BackgroundTransparency = 1
\ttopRightBar.ZIndex = 20
\ttopRightBar.Parent = screenGui

\tlocal topRightLayout = Instance.new("UIListLayout")
\ttopRightLayout.FillDirection = Enum.FillDirection.Horizontal
\ttopRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
\ttopRightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
\ttopRightLayout.Padding = UDim.new(0, 10)
\ttopRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
\ttopRightLayout.Parent = topRightBar

\tlocal function makeTopButton(name: string, imageId: string, size: UDim2, layoutOrder: number): ImageButton
\t\tlocal btn = Instance.new("ImageButton")
\t\tbtn.Name = name
\t\tbtn.Size = size
\t\tbtn.BackgroundTransparency = 1
\t\tbtn.Image = imageId
\t\tbtn.ScaleType = Enum.ScaleType.Fit
\t\tbtn.LayoutOrder = layoutOrder
\t\tbtn.ZIndex = 20
\t\tbtn.Parent = topRightBar

\t\tUITheme.setupButtonHover(btn, 1.05, 0)
\t\tbtn.Activated:Connect(function()
\t\t\tplaySfx("click")
\t\t\tpopGui(btn, 0.93)
\t\tend)

\t\treturn btn
\tend

\tbtnTopDaily = makeTopButton("BtnTopDaily", UITheme.Assets.BtnDaily, UDim2.fromOffset(144, 42), 1)
\tbtnTopQuests = makeTopButton("BtnTopQuests", UITheme.Assets.BtnQuests, UDim2.fromOffset(136, 42), 2)

\tquestBadge = makeLabel(btnTopQuests, "0", UDim2.fromOffset(22, 22), UDim2.new(1, -6, 0, 2), Color3.new(1, 1, 1))
\tquestBadge.AnchorPoint = Vector2.new(0.5, 0.5)
\tquestBadge.BackgroundTransparency = 0
\tquestBadge.BackgroundColor3 = Color3.fromHex("#E5252A")
\tquestBadge.ZIndex = 25
\tquestBadge.Visible = false
\tUITheme.addCorner(questBadge, 11)
\tUITheme.applyStroke(questBadge, 2, UITheme.Colors.Black)
end"""

assert old_top_right in text, "old_top_right not found"
text = text.replace(old_top_right, new_top_right)
print("5. Applied TopRightBar scoping")

with open('D:/BAF/scratch/MatchClient_scoped.luau', 'w', encoding='utf-8') as f:
    f.write(text)

print("Saved MatchClient_scoped.luau")

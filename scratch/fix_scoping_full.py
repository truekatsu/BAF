with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

print(f"Original length: {len(text)}")

# 1. Action bar buttons (lines 2850-2868): wrap in do ... end
t1 = '''local btnRevealAll = makeButton(actionBar, "👁️ REVEAL ALL", UDim2.new(0.18, 0, 0.70, 0), UDim2.new(0.02, 0, 0.15, 0), UITheme.Colors.PurpleTop)'''
r1 = '''do
local btnRevealAll = makeButton(actionBar, "👁️ REVEAL ALL", UDim2.new(0.18, 0, 0.70, 0), UDim2.new(0.02, 0, 0.15, 0), UITheme.Colors.PurpleTop)'''

t1_end = '''btnShuffle.Activated:Connect(function()
\tRemotes.MetaAction:FireServer("ShuffleCards")
end)'''
r1_end = '''btnShuffle.Activated:Connect(function()
\tRemotes.MetaAction:FireServer("ShuffleCards")
end)
end'''

assert t1 in text, "t1 not found"
assert t1_end in text, "t1_end not found"
text = text.replace(t1, r1, 1)
text = text.replace(t1_end, r1_end, 1)

# 2. Waiting AI & Leave buttons: wrap in do ... end
t2 = '''local btnWaitLeave = makeButton(waitingWrap, "LEAVE", UDim2.new(0.14, 0, 0, 44), UDim2.new(0.50, -70, 0.58, 0), UITheme.Colors.RedTop)'''
r2 = '''do
local btnWaitLeave = makeButton(waitingWrap, "LEAVE", UDim2.new(0.14, 0, 0, 44), UDim2.new(0.50, -70, 0.58, 0), UITheme.Colors.RedTop)'''

t2_end = '''btnPlayBotNow.Activated:Connect(function()
\tRemotes.MetaAction:FireServer("PlayVsBotNow")
end)'''
r2_end = '''btnPlayBotNow.Activated:Connect(function()
\tRemotes.MetaAction:FireServer("PlayVsBotNow")
end)
end'''

assert t2 in text, "t2 not found"
assert t2_end in text, "t2_end not found"
text = text.replace(t2, r2, 1)
text = text.replace(t2_end, r2_end, 1)

# 3. Intro VS & Mode labels: wrap in do ... end
t3 = '''local introVs = makeLabel(introWrap, "VS", UDim2.new(0.3, 0, 0, 48), UDim2.new(0.35, 0, 0.43, 0), Color3.fromHex("#FFA500"))
local introOppName = makeLabel(introWrap, "BOT", UDim2.new(0.6, 0, 0, 56), UDim2.new(0.2, 0, 0.51, 0), Color3.fromHex("#FF2E93"))
local introMode = makeLabel(introWrap, "DEFAULT MODE", UDim2.new(0.4, 0, 0, 32), UDim2.new(0.3, 0, 0.61, 0), Color3.new(1, 1, 1))'''

r3 = '''local introOppName = makeLabel(introWrap, "BOT", UDim2.new(0.6, 0, 0, 56), UDim2.new(0.2, 0, 0.51, 0), Color3.fromHex("#FF2E93"))
do
local introVs = makeLabel(introWrap, "VS", UDim2.new(0.3, 0, 0, 48), UDim2.new(0.35, 0, 0.43, 0), Color3.fromHex("#FFA500"))
local introMode = makeLabel(introWrap, "DEFAULT MODE", UDim2.new(0.4, 0, 0, 32), UDim2.new(0.3, 0, 0.61, 0), Color3.new(1, 1, 1))
end'''

assert t3 in text, "t3 not found"
text = text.replace(t3, r3, 1)

# 4. Top alert banner buttons: wrap in do ... end
t4 = '''local alertAvatarImg = Instance.new("ImageLabel")'''
r4 = '''do
local alertAvatarImg = Instance.new("ImageLabel")'''

t4_end = '''btnAlertDismiss.Activated:Connect(function()
\topponentAlertBanner.Visible = false
\tactiveAlertTableId = nil
end)'''

r4_end = '''btnAlertDismiss.Activated:Connect(function()
\topponentAlertBanner.Visible = false
\tactiveAlertTableId = nil
end)
end'''

assert t4 in text, "t4 not found"
assert t4_end in text, "t4_end not found"
text = text.replace(t4, r4, 1)
text = text.replace(t4_end, r4_end, 1)

# 5. Top Cash Pill: wrap in do ... end
t5 = '''local cashPill = Instance.new("Frame")'''
r5 = '''local cashLabel: TextLabel
do
local cashPill = Instance.new("Frame")'''

t5_cashLabel = '''local cashLabel = makeLabel(cashPill, "$0", UDim2.new(0.46, 0, 0.8, 0), UDim2.new(0.24, 0, 0.1, 0), UITheme.Colors.White)'''
r5_cashLabel = '''cashLabel = makeLabel(cashPill, "$0", UDim2.new(0.46, 0, 0.8, 0), UDim2.new(0.24, 0, 0.1, 0), UITheme.Colors.White)'''

t5_end = '''btnAddCash.Activated:Connect(function()
\topenShop()
end)'''

r5_end = '''btnAddCash.Activated:Connect(function()
\topenShop()
end)
end'''

assert t5 in text, "t5 not found"
assert t5_cashLabel in text, "t5_cashLabel not found"
assert t5_end in text, "t5_end not found"
text = text.replace(t5, r5, 1)
text = text.replace(t5_cashLabel, r5_cashLabel, 1)
text = text.replace(t5_end, r5_end, 1)

# 6. Toast banner: wrap in do ... end
t6 = '''local toastBanner = Instance.new("TextLabel")'''
r6 = '''local showToast: (msg: string) -> ()
do
local toastBanner = Instance.new("TextLabel")'''

t6_func = '''local function showToast(msg: string)'''
r6_func = '''function showToast(msg: string)'''

t6_end = '''\tTweenService:Create(toastBanner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
\t\tPosition = UDim2.new(0.5, 0, 0, -60),
\t}):Play()
end'''

r6_end = '''\tTweenService:Create(toastBanner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
\t\tPosition = UDim2.new(0.5, 0, 0, -60),
\t}):Play()
end
end'''

assert t6 in text, "t6 not found"
assert t6_func in text, "t6_func not found"
assert t6_end in text, "t6_end not found"
text = text.replace(t6, r6, 1)
text = text.replace(t6_func, r6_func, 1)
text = text.replace(t6_end, r6_end, 1)

# 7. Radar chart geometry arrays: wrap in do ... end
t7 = '''local RADAR_SIZE = 170
local RADAR_CENTER = Vector2.new(85, 85)
local RADAR_RADIUS = 68'''

r7 = '''local updateRadarChart: (slotScores: { [string]: number }?, isSelf: boolean?) -> ()
do
local RADAR_SIZE = 170
local RADAR_CENTER = Vector2.new(85, 85)
local RADAR_RADIUS = 68'''

t7_func = '''local function updateRadarChart(slotScores: { [string]: number }?, isSelf: boolean?)'''
r7_func = '''function updateRadarChart(slotScores: { [string]: number }?, isSelf: boolean?)'''

t7_end = '''\tradarPolyEdges[1].Visible = true
\tradarPolyEdges[2].Visible = true
end'''

r7_end = '''\tradarPolyEdges[1].Visible = true
\tradarPolyEdges[2].Visible = true
end
end'''

assert t7 in text, "t7 not found"
assert t7_func in text, "t7_func not found"
assert t7_end in text, "t7_end not found"
text = text.replace(t7, r7, 1)
text = text.replace(t7_func, r7_func, 1)
text = text.replace(t7_end, r7_end, 1)

# 8. Rematch & Leave buttons & Result popup header: wrap in do ... end
t8 = '''local bottomRematchBtn = makeButton(resultPopup, "REMATCH", UDim2.new(0.38, 0, 0, 48), UDim2.new(0.10, 0, 0.88, 0), UITheme.Colors.LimeTop)'''
r8 = '''do
local bottomRematchBtn = makeButton(resultPopup, "REMATCH", UDim2.new(0.38, 0, 0, 48), UDim2.new(0.10, 0, 0.88, 0), UITheme.Colors.LimeTop)'''

t8_end = '''btnCloseResultPopup.Activated:Connect(function()
\tresultPopup.Visible = false
end)'''

r8_end = '''btnCloseResultPopup.Activated:Connect(function()
\tresultPopup.Visible = false
end)
end'''

assert t8 in text, "t8 not found"
assert t8_end in text, "t8_end not found"
text = text.replace(t8, r8, 1)
text = text.replace(t8_end, r8_end, 1)

# 9. Summary cards: wrap in do ... end
t9 = '''local _, sumBuxVal = makeSummaryCard(UDim2.new(0.035, 0, 0.20, 0), UDim2.new(0.29, 0, 0.24, 0), "+$250 EARNED", UITheme.Colors.GreenLight)
local sumWinsCard, sumWinsVal = makeSummaryCard(UDim2.new(0.352, 0, 0.20, 0), UDim2.new(0.29, 0, 0.24, 0), "+1 WIN ADDED", UITheme.Colors.GoldTop)'''

r9 = '''local sumBuxVal: TextLabel
local sumWinsVal: TextLabel
local sumStreakVal: TextLabel
local sumQuestVal: TextLabel
local sumPlay30Val: TextLabel
local sumNextPtVal: TextLabel
local sumNextSkinVal: TextLabel
local sumFooterLabel: TextLabel
local btnSumClaimQuest: TextButton
do
local sumBuxCard
sumBuxCard, sumBuxVal = makeSummaryCard(UDim2.new(0.035, 0, 0.20, 0), UDim2.new(0.29, 0, 0.24, 0), "+$250 EARNED", UITheme.Colors.GreenLight)
local sumWinsCard
sumWinsCard, sumWinsVal = makeSummaryCard(UDim2.new(0.352, 0, 0.20, 0), UDim2.new(0.29, 0, 0.24, 0), "+1 WIN ADDED", UITheme.Colors.GoldTop)'''

t9_rest = '''local _, sumStreakVal = makeSummaryCard(UDim2.new(0.669, 0, 0.20, 0), UDim2.new(0.29, 0, 0.24, 0), "STREAK ACTIVE", UITheme.Colors.OrangeTop)
local sumQuestCard, sumQuestVal = makeSummaryCard(UDim2.new(0.035, 0, 0.48, 0), UDim2.new(0.29, 0, 0.24, 0), "DAILY QUEST", UITheme.Colors.GoldTop)

local btnSumClaimQuest = makeButton(sumQuestCard, "CLAIM!", UDim2.new(0.88, 0, 0, 26), UDim2.new(0.06, 0, 1, -30), UITheme.Colors.LimeTop)
UITheme.styleButton(btnSumClaimQuest, "Lime", 6)
btnSumClaimQuest.Activated:Connect(function()
\tRemotes.MetaAction:FireServer("ClaimQuest", "play_match")
end)

local _, sumPlay30Val = makeSummaryCard(UDim2.new(0.352, 0, 0.48, 0), UDim2.new(0.29, 0, 0.24, 0), "PLAYTIME: 30M", UITheme.Colors.BlueTop)
local _, sumNextPtVal = makeSummaryCard(UDim2.new(0.352, 0, 0.74, 0), UDim2.new(0.29, 0, 0.20, 0), "NEXT PLAYTIME REWARD", UITheme.Colors.BlueTop)
local _, sumNextSkinVal = makeSummaryCard(UDim2.new(0.669, 0, 0.48, 0), UDim2.new(0.29, 0, 0.24, 0), "CHAIR SHOP", UITheme.Colors.PurpleTop)

local sumFooterLabel = makeLabel(resultPopup, "1 MATCH PLAYED • 1 WON", UDim2.new(0.92, 0, 0, 24), UDim2.new(0.04, 0, 0.81, 0), Color3.fromRGB(160, 175, 205))
sumFooterLabel.TextScaled = true'''

r9_rest = '''local sumStreakCard
sumStreakCard, sumStreakVal = makeSummaryCard(UDim2.new(0.669, 0, 0.20, 0), UDim2.new(0.29, 0, 0.24, 0), "STREAK ACTIVE", UITheme.Colors.OrangeTop)
local sumQuestCard
sumQuestCard, sumQuestVal = makeSummaryCard(UDim2.new(0.035, 0, 0.48, 0), UDim2.new(0.29, 0, 0.24, 0), "DAILY QUEST", UITheme.Colors.GoldTop)

btnSumClaimQuest = makeButton(sumQuestCard, "CLAIM!", UDim2.new(0.88, 0, 0, 26), UDim2.new(0.06, 0, 1, -30), UITheme.Colors.LimeTop)
UITheme.styleButton(btnSumClaimQuest, "Lime", 6)
btnSumClaimQuest.Activated:Connect(function()
\tRemotes.MetaAction:FireServer("ClaimQuest", "play_match")
end)

local sumPlayCard
sumPlayCard, sumPlay30Val = makeSummaryCard(UDim2.new(0.352, 0, 0.48, 0), UDim2.new(0.29, 0, 0.24, 0), "PLAYTIME: 30M", UITheme.Colors.BlueTop)
local sumPtCard
sumPtCard, sumNextPtVal = makeSummaryCard(UDim2.new(0.352, 0, 0.74, 0), UDim2.new(0.29, 0, 0.20, 0), "NEXT PLAYTIME REWARD", UITheme.Colors.BlueTop)
local sumSkinCard
sumSkinCard, sumNextSkinVal = makeSummaryCard(UDim2.new(0.669, 0, 0.48, 0), UDim2.new(0.29, 0, 0.24, 0), "CHAIR SHOP", UITheme.Colors.PurpleTop)

sumFooterLabel = makeLabel(resultPopup, "1 MATCH PLAYED • 1 WON", UDim2.new(0.92, 0, 0, 24), UDim2.new(0.04, 0, 0.81, 0), Color3.fromRGB(160, 175, 205))
sumFooterLabel.TextScaled = true
end'''

assert t9 in text, "t9 not found"
assert t9_rest in text, "t9_rest not found"
text = text.replace(t9, r9, 1)
text = text.replace(t9_rest, r9_rest, 1)

# 10. setupMythicalVoteUI & setupWheelZone: convert to do ... end
t10 = '''local refreshMythicalVoteUI: () -> ()

local function setupMythicalVoteUI()'''
r10 = '''local refreshMythicalVoteUI: () -> ()

do -- setupMythicalVoteUI'''

t10_call = '''setupMythicalVoteUI()
end -- setupMythicalVoteUI'''
r10_call = '''end -- setupMythicalVoteUI'''

assert t10 in text, "t10 not found"
assert t10_call in text, "t10_call not found"
text = text.replace(t10, r10, 1)
text = text.replace(t10_call, r10_call, 1)

t11 = '''local function setupWheelZone()'''
r11 = '''do -- setupWheelZone'''

t11_call = '''setupWheelZone()
end -- setupWheelZone'''
r11_call = '''end -- setupWheelZone'''

assert t11 in text, "t11 not found"
assert t11_call in text, "t11_call not found"
text = text.replace(t11, r11, 1)
text = text.replace(t11_call, r11_call, 1)

out_path = r'd:\BAF\scratch\MatchClient_optimized.luau'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(text)

print(f"Success! Optimized MatchClient written to {out_path}: {len(text)} chars")

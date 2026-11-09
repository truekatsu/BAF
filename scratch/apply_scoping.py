import re

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

print(f"Original length: {len(text)}")

def wrap_in_do(s, start_marker, end_marker, label=""):
    start_idx = s.find(start_marker)
    if start_idx == -1:
        raise ValueError(f"Start marker not found for {label}: {start_marker[:40]}")
    end_idx = s.find(end_marker, start_idx)
    if end_idx == -1:
        raise ValueError(f"End marker not found for {label}: {end_marker[:40]}")
    end_idx += len(end_marker)
    block = s[start_idx:end_idx]
    wrapped = f"do -- {label}\n{block}\nend -- {label}"
    print(f"Wrapped {label}: {len(block)} chars")
    return s[:start_idx] + wrapped + s[end_idx:]

# 1. Action bar buttons
text = wrap_in_do(
    text,
    'local actionBar = Instance.new("Frame")',
    'Remotes.MatchAction:FireServer("Steal", attr, attr)\n\t\t\tbreak\n\t\tend\n\tend\nend)',
    "Action bar buttons"
)

# 2. Waiting AI & Leave buttons
text = wrap_in_do(
    text,
    'local btnWaitLeave = makeButton(waitingWrap, "LEAVE"',
    'Remotes.MatchAction:FireServer("PlayBotNow")\nend)',
    "Waiting buttons"
)

# 3. Opponent alert banner buttons
text = wrap_in_do(
    text,
    'local alertAvatarImg = Instance.new("ImageLabel")',
    'btnAlertDismiss.Activated:Connect(function()\n\tplaySfx("click")\n\topponentAlertBanner.Visible = false\n\tactiveAlertTableId = nil\nend)',
    "Alert banner buttons"
)

# 4. Cash pill
cash_start = 'local cashPill = Instance.new("Frame")'
cash_label = 'local cashLabel = makeLabel(cashPill, "$0", UDim2.new(0.46, 0, 0.8, 0), UDim2.new(0.24, 0, 0.1, 0), UITheme.Colors.White)'
cash_end = 'btnAddCash.Activated:Connect(function()\n\topenShop()\nend)'
idx1 = text.find(cash_start)
idx2 = text.find(cash_end) + len(cash_end)
block_cash = text[idx1:idx2]
block_cash = block_cash.replace(cash_label, 'cashLabel = makeLabel(cashPill, "$0", UDim2.new(0.46, 0, 0.8, 0), UDim2.new(0.24, 0, 0.1, 0), UITheme.Colors.White)')
text = text[:idx1] + "local cashLabel: TextLabel\ndo -- CashPill\n" + block_cash + "\nend -- CashPill" + text[idx2:]
print("Wrapped CashPill")

# 5. Toast banner
toast_start = 'local toastBanner = Instance.new("TextLabel")'
toast_func = 'local function showToast(msg: string)'
toast_end = 'task.delay(3, function()\n\t\tif toastToken == myToken then\n\t\t\ttoastBanner.Visible = false\n\t\tend\n\tend)\nend'
idx1 = text.find(toast_start)
idx2 = text.find(toast_end) + len(toast_end)
block_toast = text[idx1:idx2]
block_toast = block_toast.replace(toast_func, 'function showToast(msg: string)')
text = text[:idx1] + "local showToast: (msg: string) -> ()\ndo -- ToastBanner\n" + block_toast + "\nend -- ToastBanner" + text[idx2:]
print("Wrapped ToastBanner")

# 6. Radar Chart
radar_start = 'local RADAR_SIZE = 170'
radar_func = 'local function updateRadarChart(slotScores: { [string]: number }?, isSelf: boolean?)'
radar_end = 'radarVertexDots[i].Position = UDim2.fromOffset(p1.X, p1.Y)\n\t\t\tend\n\t\t\ttask.wait(0.025)\n\t\tend\n\tend)\nend'
idx1 = text.find(radar_start)
idx2 = text.find(radar_end) + len(radar_end)
block_radar = text[idx1:idx2]
block_radar = block_radar.replace(radar_func, 'function updateRadarChart(slotScores: { [string]: number }?, isSelf: boolean?)')
text = text[:idx1] + "local updateRadarChart: (slotScores: { [string]: number }?, isSelf: boolean?) -> ()\ndo -- RadarChart\n" + block_radar + "\nend -- RadarChart" + text[idx2:]
print("Wrapped RadarChart")

# 7. Winner Wrap rematch & leave buttons
text = wrap_in_do(
    text,
    'local bottomRematchBtn = makeButton(winnerWrap, "REMATCH"',
    'bottomLeaveBtn.Activated:Connect(function()\n\tRemotes.MatchAction:FireServer("LeaveTable")\nend)',
    "Winner rematch buttons"
)

# 8. Result popup close button
text = wrap_in_do(
    text,
    'local btnCloseResultPopup = makeButton(resultHeader, "X"',
    'btnCloseResultPopup.Activated:Connect(function()\n\tresultPopup.Visible = false\nend)',
    "Result close button"
)

# 9. Summary cards
sum_start = 'local _, sumBuxVal = makeSummaryCard'
sum_end = 'sumFooterLabel.TextScaled = true'
idx1 = text.find(sum_start)
idx2 = text.find(sum_end) + len(sum_end)
block_sum = text[idx1:idx2]

declarations_outside = """local sumBuxVal: TextLabel
local sumWinsVal: TextLabel
local sumStreakVal: TextLabel
local sumQuestVal: TextLabel
local sumPlay30Val: TextLabel
local sumNextPtVal: TextLabel
local sumNextSkinVal: TextLabel
local sumFooterLabel: TextLabel
local btnSumClaimQuest: TextButton
"""

block_sum = block_sum.replace('local _, sumBuxVal = makeSummaryCard', 'local sumBuxCard\n\tsumBuxCard, sumBuxVal = makeSummaryCard')
block_sum = block_sum.replace('local sumWinsCard, sumWinsVal = makeSummaryCard', 'local sumWinsCard\n\tsumWinsCard, sumWinsVal = makeSummaryCard')
block_sum = block_sum.replace('local _, sumStreakVal = makeSummaryCard', 'local sumStreakCard\n\tsumStreakCard, sumStreakVal = makeSummaryCard')
block_sum = block_sum.replace('local sumQuestCard, sumQuestVal = makeSummaryCard', 'local sumQuestCard\n\tsumQuestCard, sumQuestVal = makeSummaryCard')
block_sum = block_sum.replace('local btnSumClaimQuest = makeButton', 'btnSumClaimQuest = makeButton')
block_sum = block_sum.replace('local _, sumPlay30Val = makeSummaryCard', 'local sumPlayCard\n\tsumPlayCard, sumPlay30Val = makeSummaryCard')
block_sum = block_sum.replace('local _, sumNextPtVal = makeSummaryCard', 'local sumPtCard\n\tsumPtCard, sumNextPtVal = makeSummaryCard')
block_sum = block_sum.replace('local _, sumNextSkinVal = makeSummaryCard', 'local sumSkinCard\n\tsumSkinCard, sumNextSkinVal = makeSummaryCard')
block_sum = block_sum.replace('local sumFooterLabel = makeLabel', 'sumFooterLabel = makeLabel')

text = text[:idx1] + declarations_outside + "do -- SummaryCards\n" + block_sum + "\nend -- SummaryCards" + text[idx2:]
print("Wrapped SummaryCards")

# 10. Playtime rewards (wrap lines 935 to 1121)
pt_start = 'local ptRail = Instance.new("Frame")'
pt_end = 'Remotes.MetaAction:FireServer("BuyShopItem", "skip_all_playtime")\nend)'
idx1 = text.find(pt_start)
idx2 = text.find(pt_end) + len(pt_end)
block_pt = text[idx1:idx2]

pt_decl_outside = """local playtimeButtons: { [string]: TextButton } = {}
local playtimeInsetFrames: { [string]: Frame } = {}
local playtimeLockBadges: { [string]: ImageLabel } = {}
local playedElapsedLabel: TextLabel
"""
block_pt = block_pt.replace('local playtimeButtons: { [string]: TextButton } = {}', '')
block_pt = block_pt.replace('local playtimeInsetFrames: { [string]: Frame } = {}', '')
block_pt = block_pt.replace('local playtimeLockBadges: { [string]: ImageLabel } = {}', '')
block_pt = block_pt.replace('local playedElapsedLabel = makeLabel', 'playedElapsedLabel = makeLabel')

text = text[:idx1] + pt_decl_outside + "do -- PlaytimeRewards\n" + block_pt + "\nend -- PlaytimeRewards" + text[idx2:]
print("Wrapped PlaytimeRewards")

out_path = r'd:\BAF\scratch\MatchClient_optimized.luau'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(text)

print(f"ALL DONE! Written {len(text)} chars to {out_path}")

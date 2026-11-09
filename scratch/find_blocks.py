with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Total lines: {len(lines)}')

blocks = [
    ('ToastBanner', 'local toastBanner = Instance.new("TextLabel")', 'toastBanner.Visible = false'),
    ('CashPill', 'local cashPill = Instance.new("Frame")', 'btnAddCash.Activated:Connect'),
    ('AlertBanner', 'local alertAvatarImg = Instance.new("ImageLabel")', 'btnAlertDismiss.Activated:Connect'),
    ('WaitingButtons', 'local btnWaitLeave = makeButton(waitingWrap, "LEAVE"', 'btnPlayBotNow.Activated:Connect'),
    ('ActionBar', 'local actionBar = Instance.new("Frame")', 'btnSteal.Activated:Connect'),
    ('RadarChart', 'local RADAR_SIZE = 170', 'radarVertexDots[i].Position = UDim2'),
    ('RematchButtons', 'local bottomRematchBtn = makeButton(winnerWrap, "REMATCH"', 'bottomLeaveBtn.Activated:Connect'),
    ('ResultClose', 'local btnCloseResultPopup = makeButton(resultHeader, "X"', 'btnCloseResultPopup.Activated:Connect'),
    ('SummaryCards', 'local _, sumBuxVal = makeSummaryCard', 'sumFooterLabel.TextScaled = true'),
]

for name, start_m, end_m in blocks:
    s_idx = [i for i, l in enumerate(lines) if start_m in l]
    e_idx = [i for i, l in enumerate(lines) if end_m in l]
    print(f'{name}: start {s_idx}, end {e_idx}')

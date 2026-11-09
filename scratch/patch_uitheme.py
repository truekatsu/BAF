path = r'd:\BAF\src\ReplicatedStorage\Shared\UITheme.luau'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

funcs = """
function UITheme.animateWindowOpen(modalWrap: GuiObject, modalBox: GuiObject)
\tmodalWrap.Visible = true
\tlocal uiScale = modalBox:FindFirstChildOfClass("UIScale")
\tif not uiScale then
\t\tuiScale = Instance.new("UIScale")
\t\tuiScale.Parent = modalBox
\tend

\tuiScale.Scale = 0.80
\tTweenService:Create(uiScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
\t\tScale = 1.0,
\t}):Play()

\tlocal backdrop = modalWrap:FindFirstChild("ModalBackdrop") or (modalWrap.Parent and modalWrap.Parent:FindFirstChild("ModalBackdrop"))
\tif backdrop and backdrop:IsA("GuiObject") then
\t\tbackdrop.Visible = true
\t\tbackdrop.BackgroundTransparency = 0.55
\tend
end

function UITheme.animateWindowClose(modalWrap: GuiObject, modalBox: GuiObject, onComplete: (() -> ())?)
\tlocal backdrop = modalWrap:FindFirstChild("ModalBackdrop") or (modalWrap.Parent and modalWrap.Parent:FindFirstChild("ModalBackdrop"))
\tif backdrop and backdrop:IsA("GuiObject") then
\t\tbackdrop.Visible = false
\tend

\tlocal uiScale = modalBox:FindFirstChildOfClass("UIScale")
\tif not uiScale then
\t\tmodalWrap.Visible = false
\t\tif onComplete then onComplete() end
\t\treturn
\tend

\tlocal tw = TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
\t\tScale = 0.80,
\t})
\ttw:Play()
\ttw.Completed:Connect(function()
\t\tmodalWrap.Visible = false
\t\tif onComplete then onComplete() end
\tend)
end
"""

target = 'function UITheme.closeWindow'
idx = text.find(target)
if idx != -1:
    end_marker = '-- 6. REUSABLE BUILDERS'
    end_idx = text.find(end_marker, idx)
    if end_idx != -1:
        # find last line before end_marker
        line_start = text.rfind('\n', 0, end_idx)
        text = text[:end_idx] + funcs + "\n\n" + text[end_idx:]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
        print("Success! Added animateWindow functions to UITheme.luau")
    else:
        print("End marker not found")
else:
    print("Target not found")

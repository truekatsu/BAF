# scratch/gen_hud_edits.py
import json

with open("scratch/apply_hud_revision.py", "r", encoding="utf-8") as f:
    text = f.read()

start_marker = 'new_hud_code = """'
end_marker = '"""\n\n# 1.'
start_idx = text.find(start_marker) + len(start_marker)
end_idx = text.find(end_marker)
new_hud_code = text[start_idx:end_idx]

old_hud_block = """-- Bottom-Left Friends Boost + Cash Display
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
UITheme.styleButton(btnAddCash, "Lime", 8)"""

old_refresh_block = """\tcashLabel.Text = `$` .. tostring(p.Bux)
\tlocal boostPct = (localPlayer:GetAttribute("FriendsBoostPct") :: number?) or 0
\tfriendsLabel.Text = `FRIENDS BOOST: +{boostPct}%`"""

new_refresh_block = """\tupdateCashDisplay(p.Bux or 0)
\tlocal boostPct = (localPlayer:GetAttribute("FriendsBoostPct") :: number?) or 0
\tupdateFriendsDisplay(boostPct)"""

payload = {
    "studio_id": "649a33bb-29a0-415b-a167-51eaf7f9f85f",
    "datamodel_type": "Edit",
    "file_path": "game.StarterPlayer.StarterPlayerScripts.Client.MatchClient",
    "edits": [
        {
            "old_string": old_hud_block,
            "new_string": new_hud_code
        },
        {
            "old_string": old_refresh_block,
            "new_string": new_refresh_block
        }
    ]
}

with open("scratch/hud_edits_payload.json", "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)

print("Generated payload, size:", len(json.dumps(payload)))

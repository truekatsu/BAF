# Let's inspect Group 2 in studio_MatchClient.luau
with open('D:/BAF/scratch/studio_MatchClient.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Left Nav
s_nav = text.find('-- Left Vertical Nav Column')
e_nav = text.find('UITheme.applyStroke(badge, 2, UITheme.Colors.Black)\nend', s_nav) + len('UITheme.applyStroke(badge, 2, UITheme.Colors.Black)\nend')
old_nav = text[s_nav:e_nav]

# Wrap makeNavButton & size constants in do ... end
new_nav = """-- Left Vertical Nav Column (FREE, SHOP, SKINS, TITLES, INDEX, PROFILE)
local btnNavFree: TextButton
local btnNavShop: TextButton
local btnNavSkins: TextButton
local btnNavTitles: TextButton
local btnNavIndex: TextButton
local btnNavProfile: TextButton
do
\tlocal NAV_BTN_SIZE = 84
\tlocal NAV_BTN_STEP = 90

\tlocal function makeNavButton(name: string, imageId: string, index: number, scaleX: number, scaleY: number, anchorX: number, anchorY: number): TextButton
\t\tlocal btn = Instance.new("TextButton")
\t\tbtn.Name = name
\t\tbtn.Size = UDim2.fromOffset(NAV_BTN_SIZE, NAV_BTN_SIZE)
\t\tbtn.Position = UDim2.new(0, 16, 0.085, (index - 1) * NAV_BTN_STEP)
\t\tbtn.BackgroundTransparency = 1
\t\tbtn.Text = ""
\t\tbtn.Parent = lobbyHud
\t\tUITheme.setupButtonHover(btn, 1.06, 0)

\t\tlocal img = Instance.new("ImageLabel")
\t\timg.Name = "NavIcon"
\t\timg.Size = UDim2.fromScale(scaleX, scaleY)
\t\timg.AnchorPoint = Vector2.new(anchorX, anchorY)
\t\timg.Position = UDim2.fromScale(0.5, 0.5)
\t\timg.BackgroundTransparency = 1
\t\timg.Image = imageId
\t\timg.ScaleType = Enum.ScaleType.Stretch
\t\timg.ZIndex = btn.ZIndex + 1
\t\timg.Parent = btn
\t\treturn btn
\tend

\t-- Compensate per-PNG transparent padding (557x557 canvas) so every icon frame renders at the exact 84x84 button size
\tbtnNavFree = makeNavButton("BtnNavFree", UITheme.Assets.NavFreeIcon, 1, 557 / 444, 557 / 449, 277.5 / 557, 266.0 / 557)
\tbtnNavShop = makeNavButton("BtnNavShop", UITheme.Assets.NavShopIcon, 2, 557 / 496, 557 / 506, 278.5 / 557, 282.5 / 557)
\tbtnNavSkins = makeNavButton("BtnNavSkins", UITheme.Assets.NavSkinsIcon, 3, 557 / 477, 557 / 489, 278.0 / 557, 284.0 / 557)
\tbtnNavTitles = makeNavButton("BtnNavTitles", UITheme.Assets.NavTitlesIcon, 4, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
\tbtnNavIndex = makeNavButton("BtnNavIndex", UITheme.Assets.NavIndexIcon, 5, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)
\tbtnNavProfile = makeNavButton("BtnNavProfile", UITheme.Assets.NavProfileIcon, 6, 557 / 475, 557 / 475, 278.0 / 557, 278.0 / 557)

\tlocal badge = makeLabel(btnNavIndex, "0/152", UDim2.fromOffset(52, 20), UDim2.new(1, -40, 0, -6), Color3.new(1, 1, 1))
\tbadge.Name = "IndexBadge"
\tbadge.BackgroundTransparency = 0
\tbadge.BackgroundColor3 = Color3.fromHex("#E5252A")
\tbadge.ZIndex = btnNavIndex.ZIndex + 4
\tbadge.TextSize = 11
\tbadge.Font = UITheme.Fonts.Body
\tUITheme.addCorner(badge, 10)
\tUITheme.applyStroke(badge, 2, UITheme.Colors.Black)
end"""

import json
with open('D:/BAF/scratch/edit_nav.json', 'w', encoding='utf-8') as out:
    json.dump({'old_string': old_nav, 'new_string': new_nav}, out)

print("Saved edit_nav.json")

import re

with open(r'd:\BAF\scratch\MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix Playtime (lines around Page 1C)
# Inside the do block, replace 'local ptRailFill = Instance.new' with 'ptRailFill = Instance.new'
# And remove the duplicate local dict declarations inside do
old_pt_setup = """local ptRailFill: Frame
local playtimeNodes: { [string]: Frame } = {}
local playtimeNodeIcons: { [string]: TextLabel } = {}
local playtimeButtons: { [string]: TextButton } = {}
local playtimeInsetFrames: { [string]: Frame } = {}
local playtimeLockBadges: { [string]: ImageLabel } = {}
local playedElapsedLabel: TextLabel
do
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
local playtimeLockBadges: { [string]: ImageLabel } = {}"""

new_pt_setup = """local ptRailFill: Frame
local playtimeNodes: { [string]: Frame } = {}
local playtimeNodeIcons: { [string]: TextLabel } = {}
local playtimeButtons: { [string]: TextButton } = {}
local playtimeCardFrames: { [string]: Frame } = {}
local playtimeInsetFrames: { [string]: Frame } = {}
local playtimeLockBadges: { [string]: ImageLabel } = {}
local playedElapsedLabel: TextLabel
do
local ptRail = Instance.new("Frame")
ptRail.Name = "MilestoneRail"
ptRail.Size = UDim2.new(0.80, 0, 0, 14)
ptRail.Position = UDim2.new(0.09, 0, 0.025, 0)
ptRail.BackgroundColor3 = Color3.fromHex("#1B1B1F")
UITheme.addCorner(ptRail, 4)
UITheme.applyStroke(ptRail, 2, UITheme.Colors.Black)
ptRail.Parent = pageFreePlaytime

ptRailFill = Instance.new("Frame")
ptRailFill.Name = "RailFill"
ptRailFill.Size = UDim2.fromScale(0, 1)
ptRailFill.BackgroundColor3 = Color3.fromHex("#7CFF2B")
ptRailFill.BorderSizePixel = 0
UITheme.addCorner(ptRailFill, 3)
ptRailFill.Parent = ptRail"""

assert old_pt_setup in text, "old_pt_setup not found"
text = text.replace(old_pt_setup, new_pt_setup)

# Also in Playtime: local playedElapsedLabel = makeLabel -> playedElapsedLabel = makeLabel
text = text.replace(
    'local playedElapsedLabel = makeLabel(pageFreePlaytime',
    'playedElapsedLabel = makeLabel(pageFreePlaytime'
)

# 2. Fix Quests (Page 2)
old_quests = """local questProgLabels: { [string]: TextLabel } = {}
local questClaimBtns: { [string]: TextButton } = {}
do
local questProgLabels: { [string]: TextLabel } = {}
local questClaimBtns: { [string]: TextButton } = {}
do
for i, q in GameConfig.QUESTS do"""

new_quests = """local questProgLabels: { [string]: TextLabel } = {}
local questClaimBtns: { [string]: TextButton } = {}
do
for i, q in GameConfig.QUESTS do"""

assert old_quests in text, "old_quests not found"
text = text.replace(old_quests, new_quests)

# And remove duplicate end for Page 2
text = text.replace(
    'end -- Page 2 Quests block\n\nend -- Page 2 Quests',
    'end -- Page 2 Quests'
)

# 3. Fix Chair Skins (Page 3)
old_skins = """local wheelSpinBtn: TextButton
local luckUpgradeBtn: TextButton
local skinActionBtns: { [string]: TextButton } = {}
do
pageSkins.Name = "PageSkins"
local wheelSpinBtn: TextButton
local luckUpgradeBtn: TextButton
local skinActionBtns: { [string]: TextButton } = {}
local skinNameLabels: { [string]: TextLabel } = {}

do
\t-- Top Slim Action Row"""

new_skins = """pageSkins.Name = "PageSkins"
local wheelSpinBtn: TextButton
local luckUpgradeBtn: TextButton
local skinActionBtns: { [string]: TextButton } = {}
local skinNameLabels: { [string]: TextLabel } = {}
do
\t-- Top Slim Action Row"""

assert old_skins in text, "old_skins not found"
text = text.replace(old_skins, new_skins)

# 4. Fix Titles (Page 4)
old_titles = """local titlesWinsHeader: TextLabel
local titleActionBtns: { [string]: TextButton } = {}
do
local titlesWinsHeader: TextLabel
local titleActionBtns: { [string]: TextButton } = {}
do
local winsHeaderFrame = Instance.new("Frame")"""

new_titles = """local titlesWinsHeader: TextLabel
local titleActionBtns: { [string]: TextButton } = {}
do
local winsHeaderFrame = Instance.new("Frame")"""

assert old_titles in text, "old_titles not found"
text = text.replace(old_titles, new_titles)

text = text.replace(
    'end -- Page 4 Titles block\n\nend -- Page 4 Titles',
    'end -- Page 4 Titles'
)

# 5. Fix Index (Page 6)
old_index = """local indexProgressHeader: TextLabel
local indexCardCells: { [number]: { card: Frame, label: TextLabel, stroke: UIStroke } } = {}
do
local indexProgressHeader = makeLabel(pageIndex, "DISCOVERED: 0 / 152 (0%) • +$25–$250 PER NEW CARD!", UDim2.new(0.96, 0, 0.11, 0), UDim2.new(0.02, 0, 0, 0), UITheme.Colors.NoticeYellow)
local indexCardCells: { [string]: { frame: Frame, label: TextLabel, card: Footballers.Footballer } } = {}
do
local indexScroll = Instance.new("ScrollingFrame")"""

new_index = """local indexProgressHeader: TextLabel
local indexCardCells: { [string]: { frame: Frame, label: TextLabel, card: Footballers.Footballer } } = {}
do
indexProgressHeader = makeLabel(pageIndex, "DISCOVERED: 0 / 152 (0%) • +$25–$250 PER NEW CARD!", UDim2.new(0.96, 0, 0.11, 0), UDim2.new(0.02, 0, 0, 0), UITheme.Colors.NoticeYellow)
local indexScroll = Instance.new("ScrollingFrame")"""

assert old_index in text, "old_index not found"
text = text.replace(old_index, new_index)

# Ensure line endings are LF
text = text.replace('\r\n', '\n').replace('\r', '\n')

with open(r'd:\BAF\scratch\MatchClient_clean.luau', 'w', encoding='utf-8') as f:
    f.write(text)

print(f'Success! Clean MatchClient written: {len(text)} characters, {text.count(chr(10))} lines')

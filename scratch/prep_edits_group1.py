with open('D:/BAF/scratch/studio_MatchClient.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. SFX
old_sfx = text[text.find('local sfxFolder = Instance.new("Folder")'):text.find('SoundService:PlayLocalSound(s)\n\tend\nend') + len('SoundService:PlayLocalSound(s)\n\tend\nend')]

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

# 2. BGM
old_bgm = text[text.find('-- Phase-adaptive Background Music'):text.find('task.defer(setBgmPhase, "Idle")') + len('task.defer(setBgmPhase, "Idle")')]

# In old_bgm, replace 'local function setBgmPhase' with 'function setBgmPhase'
bgm_body = old_bgm.replace('local function setBgmPhase(phase: string)', 'function setBgmPhase(phase: string)')
new_bgm = """-- Phase-adaptive Background Music (Lobby Samba/Brass, Build Liquid DnB, Showdown Stadium Drumline)
local setBgmPhase: (phase: string) -> ()
do
""" + bgm_body[bgm_body.find('local function createBgm'):] + "\nend"

# 3. Blur
old_blur = text[text.find('local matchBlur = Lighting:FindFirstChild("BAF_MatchBlur")'):text.find('}):Play()\n\tend\nend') + len('}):Play()\n\tend\nend')]
blur_body = old_blur.replace('local function setMatchBlur', 'function setMatchBlur')
new_blur = """local setMatchBlur: (enabled: boolean) -> ()
do
""" + blur_body + "\nend"

# 4. Toast
old_toast = text[text.find('-- Toast Notification Banner'):text.find('toastBanner.Visible = false\n\t\tend\n\tend)\nend') + len('toastBanner.Visible = false\n\t\tend\n\tend)\nend')]
toast_body = old_toast.replace('local function showToast', 'function showToast')
new_toast = """-- Toast Notification Banner (parented to screenGui so it is visible in both Lobby and Match)
local showToast: (msg: string) -> ()
do
""" + toast_body[toast_body.find('local toastBanner'):] + "\nend"

# 5. Top Right
old_top = text[text.find('-- Top-Right Container for Daily Rewards & Quests'):text.find('UITheme.applyStroke(questBadge, 2, UITheme.Colors.Black)') + len('UITheme.applyStroke(questBadge, 2, UITheme.Colors.Black)')]

# In top right, btnTopDaily, btnTopQuests, questBadge need to be declared outside
new_top = """-- Top-Right Container for Daily Rewards & Quests (parented to screenGui so they remain visible on all screens)
local btnTopDaily: ImageButton
local btnTopQuests: ImageButton
local questBadge: TextLabel
do
""" + old_top[old_top.find('local topRightBar'):].replace('local btnTopDaily =', 'btnTopDaily =').replace('local btnTopQuests =', 'btnTopQuests =').replace('local questBadge =', 'questBadge =') + "\nend"

import json
edits = [
    {"old_string": old_sfx, "new_string": new_sfx},
    {"old_string": old_bgm, "new_string": new_bgm},
    {"old_string": old_blur, "new_string": new_blur},
    {"old_string": old_toast, "new_string": new_toast},
    {"old_string": old_top, "new_string": new_top}
]

with open('D:/BAF/scratch/edits_group1.json', 'w', encoding='utf-8') as out:
    json.dump(edits, out)

print("Saved edits_group1.json, count:", len(edits))

with open('D:/BAF/scratch/studio_MatchClient.luau', 'r', encoding='utf-8') as f:
    text = f.read()

def find_snippet(title, start_marker, end_marker):
    s = text.find(start_marker)
    if s == -1:
        print(f"FAILED to find {title} start: {start_marker[:40]}")
        return None
    e = text.find(end_marker, s)
    if e == -1:
        print(f"FAILED to find {title} end: {end_marker[:40]}")
        return None
    e += len(end_marker)
    snippet = text[s:e]
    print(f"FOUND {title}: len={len(snippet)}")
    return snippet

# 1. SFX
sfx_orig = find_snippet("SFX", "local sfxFolder = Instance.new(\"Folder\")", "SoundService:PlayLocalSound(s)\n\tend\nend")

# 2. BGM
bgm_orig = find_snippet("BGM", "-- Phase-adaptive Background Music", "task.defer(setBgmPhase, \"Idle\")")

# 3. Blur
blur_orig = find_snippet("Blur", "local matchBlur = Lighting:FindFirstChild(\"BAF_MatchBlur\")", "}):Play()\n\tend\nend")

# 4. Toast
toast_orig = find_snippet("Toast", "-- Toast Notification Banner", "toastBanner.Visible = false\n\t\tend\n\tend)\nend")

# 5. Top Right
top_orig = find_snippet("TopRight", "-- Top-Right Container for Daily Rewards & Quests", "UITheme.applyStroke(questBadge, 2, UITheme.Colors.Black)")

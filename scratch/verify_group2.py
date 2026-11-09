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

# 6. Left Nav
nav_orig = find_snippet("LeftNav", "-- Left Vertical Nav Column (FREE, SHOP, SKINS, TITLES, INDEX, PROFILE)", "UITheme.applyStroke(badge, 2, UITheme.Colors.Black)\nend")

# 7. Friends & Cash
cash_orig = find_snippet("Cash", "-- Bottom-Left Friends Boost + Cash Display", "UITheme.styleButton(btnAddCash, \"Lime\", 8)")

# 8. Opponent Alert
alert_orig = find_snippet("Alert", "-- Opponent Needed Notification Banner", "activeAlertTableId = nil\nend)")

# 9. Modal Header
modal_orig = find_snippet("ModalHeader", "local modalBoxScale = Instance.new(\"UIScale\")", "modalTitle.Parent = modalHeader")

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

# 10. Page 1C
pt_orig = find_snippet("Page1C", "-- Build Page 1C: PLAYTIME REWARDS", "Remotes.MetaAction:FireServer(\"BuyShopItem\", \"skip_all_playtime\")\nend)")

# 11. Page 2
q_orig = find_snippet("Page2", "-- Build Page 2: DAILY QUESTS", "questClaimBtns[q.id] = cBtn\nend")

# 12. Page 3
skins_orig = find_snippet("Page3", "-- Build Page 3: CHAIR SKINS", "end -- Page 3 Skins block")

# 13. Page 4
titles_orig = find_snippet("Page4", "-- Build Page 4: TITLES", "btnRobuxUnlock.Parent = pageTitles")

# 14. Page 6
idx_orig = find_snippet("Page6", "-- Build Page 6: CARD INDEX", "indexCardCells[c.id] = { card = card, label = lbl, stroke = s }\n\tend\nend")

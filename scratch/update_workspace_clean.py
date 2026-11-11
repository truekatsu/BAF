# scratch/update_workspace_clean.py
import re

with open("scratch/min_reg_code.txt", "r", encoding="utf-8") as f:
    min_hud_code = f.read()

ws_file = "src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau"
with open(ws_file, "r", encoding="utf-8") as f:
    content = f.read()

# Pattern for old HUD block in workspace
ws_pattern = re.compile(
    r"-- Bottom-Left Friends Boost \+ Cash Display.*?"
    r"UITheme\.styleButton\(btnAddCash,\s*\"Lime\",\s*8\)",
    re.DOTALL
)

if not ws_pattern.search(content):
    print("ERROR: old HUD block not found in workspace!")
else:
    content = ws_pattern.sub(lambda m: min_hud_code, content, count=1)
    
    # Replace in refreshMetaUI
    pattern_refresh = re.compile(
        r"cashLabel\.Text\s*=\s*`\$`\s*\.\.\s*tostring\(p\.Bux\)\s*"
        r"(?:local\s+boostPct\s*=\s*\(localPlayer:GetAttribute\(\"FriendsBoostPct\"\)\s*::\s*number\?\)\s*or\s*0\s*)"
        r"friendsLabel\.Text\s*=\s*`FRIENDS BOOST:\s*\+\{boostPct\}%`",
        re.DOTALL
    )
    new_refresh = (
        "if HUD.updateCash then HUD.updateCash(p.Bux or 0) else cashLabel.Text = `$` .. tostring(p.Bux) end\n\n\t"
        "local boostPct = (localPlayer:GetAttribute(\"FriendsBoostPct\") :: number?) or 0\n\n\t"
        "if HUD.updateFriends then HUD.updateFriends(boostPct) else friendsLabel.Text = `FRIENDS BOOST: +{boostPct}%` end"
    )
    if pattern_refresh.search(content):
        content = pattern_refresh.sub(lambda m: new_refresh, content, count=1)
        print("Replaced refreshMetaUI in workspace file")
    else:
        print("WARNING: refresh block not found in workspace file")

    with open(ws_file, "w", encoding="utf-8") as f:
        f.write(content)
    print("Workspace file successfully updated!")

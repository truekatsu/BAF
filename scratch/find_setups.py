with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, l in enumerate(lines):
    if "setupWheelZone" in l or "setupSpectatorDisplay" in l or "setupFeedbackModal" in l:
        print(f"{i+1}: {l.strip()}")

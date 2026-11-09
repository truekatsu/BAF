import re

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

print(f"Original length: {len(text)}")

# Pattern 1: Action bar buttons
# From 'local btnRevealAll = makeButton(actionBar' to 'Remotes.MetaAction:FireServer("ShuffleCards")\nend)'
p1 = re.compile(r'(local btnRevealAll = makeButton\(actionBar.*?Remotes\.MetaAction:FireServer\("ShuffleCards"\)\s*end\))', re.DOTALL)
m1 = p1.search(text)
assert m1, "Pattern 1 not found"
text = text[:m1.start()] + "do\n" + m1.group(1) + "\nend" + text[m1.end():]
print("Applied 1: Action bar")

# Pattern 2: Waiting AI and Leave buttons
p2 = re.compile(r'(local btnWaitLeave = makeButton\(waitingWrap.*?Remotes\.MetaAction:FireServer\("PlayVsBotNow"\)\s*end\))', re.DOTALL)
m2 = p2.search(text)
assert m2, "Pattern 2 not found"
text = text[:m2.start()] + "do\n" + m2.group(1) + "\nend" + text[m2.end():]
print("Applied 2: Waiting buttons")

# Pattern 3: Top Alert Banner
p3 = re.compile(r'(local alertAvatarImg = Instance\.new\("ImageLabel"\).*?btnAlertDismiss\.Activated:Connect\(function\(\)\s*opponentAlertBanner\.Visible = false\s*activeAlertTableId = nil\s*end\))', re.DOTALL)
m3 = p3.search(text)
assert m3, "Pattern 3 not found"
text = text[:m3.start()] + "do\n" + m3.group(1) + "\nend" + text[m3.end():]
print("Applied 3: Top Alert Banner")

# Pattern 4: Top Cash Pill
p4 = re.compile(r'local cashPill = Instance\.new\("Frame"\)(.*?)local cashLabel = (makeLabel\(cashPill, "\$0".*?btnAddCash\.Activated:Connect\(function\(\)\s*openShop\(\)\s*end\))', re.DOTALL)
m4 = p4.search(text)
assert m4, "Pattern 4 not found"
rep4 = "local cashLabel: TextLabel\ndo\nlocal cashPill = Instance.new(\"Frame\")" + m4.group(1) + "cashLabel = " + m4.group(2) + "\nend"
text = text[:m4.start()] + rep4 + text[m4.end():]
print("Applied 4: Top Cash Pill")

# Pattern 5: Toast Banner
p5 = re.compile(r'local toastBanner = Instance\.new\("TextLabel"\)(.*?)local function showToast\(msg: string\)(.*?\nend\s*\n)', re.DOTALL)
m5 = p5.search(text)
assert m5, "Pattern 5 not found"
rep5 = "local showToast: (msg: string) -> ()\ndo\nlocal toastBanner = Instance.new(\"TextLabel\")" + m5.group(1) + "function showToast(msg: string)" + m5.group(2) + "end\n"
text = text[:m5.start()] + rep5 + text[m5.end():]
print("Applied 5: Toast Banner")

# Pattern 6: Radar Chart
p6 = re.compile(r'local RADAR_SIZE = 170(.*?)local function updateRadarChart\(slotScores: \{\s*\[string\]:\s*number\s*\}\?, isSelf: boolean\?\)(.*?\tradarPolyEdges\[2\]\.Visible = true\s*end)', re.DOTALL)
m6 = p6.search(text)
assert m6, "Pattern 6 not found"
rep6 = "local updateRadarChart: (slotScores: { [string]: number }?, isSelf: boolean?) -> ()\ndo\nlocal RADAR_SIZE = 170" + m6.group(1) + "function updateRadarChart(slotScores: { [string]: number }?, isSelf: boolean?)" + m6.group(2) + "\nend"
text = text[:m6.start()] + rep6 + text[m6.end():]
print("Applied 6: Radar Chart")

# Pattern 7: Rematch, Leave & Close Result
p7 = re.compile(r'(local bottomRematchBtn = makeButton\(resultPopup, "REMATCH".*?btnCloseResultPopup\.Activated:Connect\(function\(\)\s*resultPopup\.Visible = false\s*end\))', re.DOTALL)
m7 = p7.search(text)
assert m7, "Pattern 7 not found"
text = text[:m7.start()] + "do\n" + m7.group(1) + "\nend" + text[m7.end():]
print("Applied 7: Result buttons")

# Pattern 8: setupMythicalVoteUI -> do ... end
p8 = re.compile(r'local function setupMythicalVoteUI\(\)(.*?)setupMythicalVoteUI\(\)\s*end -- setupMythicalVoteUI', re.DOTALL)
m8 = p8.search(text)
assert m8, "Pattern 8 not found"
text = text[:m8.start()] + "do -- setupMythicalVoteUI" + m8.group(1) + "end -- setupMythicalVoteUI" + text[m8.end():]
print("Applied 8: setupMythicalVoteUI")

# Pattern 9: setupWheelZone -> do ... end
p9 = re.compile(r'local function setupWheelZone\(\)(.*?)setupWheelZone\(\)\s*end -- setupWheelZone', re.DOTALL)
m9 = p9.search(text)
assert m9, "Pattern 9 not found"
text = text[:m9.start()] + "do -- setupWheelZone" + m9.group(1) + "end -- setupWheelZone" + text[m9.end():]
print("Applied 9: setupWheelZone")

out_path = r'd:\BAF\scratch\MatchClient_optimized.luau'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(text)

print(f"Success! Output written to {out_path}: {len(text)} chars")

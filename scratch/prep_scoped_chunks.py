import json

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Lines count: {len(lines)}")

# We will insert 'do' and 'end' at exact line numbers:
# Remember 0-indexed in Python vs 1-indexed in editor:

# 1. ActionBar: line 2853 (idx 2852) to line 2885 (idx 2884)
# Insert 'do\n' before idx 2852
# Insert 'end\n' after idx 2884
lines[2852] = "do -- ActionBar\n" + lines[2852]
lines[2884] = lines[2884] + "end -- ActionBar\n"

# 2. WaitingButtons: line 2409 (idx 2408) to line 2425 (idx 2424)
lines[2408] = "do -- WaitingButtons\n" + lines[2408]
lines[2424] = lines[2424] + "end -- WaitingButtons\n"

# 3. AlertBanner: line 542 (idx 541) to line 597 (idx 596)
lines[541] = "do -- AlertBanner\n" + lines[541]
lines[596] = lines[596] + "end -- AlertBanner\n"

# 4. RematchButtons: line 3151 (idx 3150) to line 3160 (idx 3159)
lines[3150] = "do -- RematchButtons\n" + lines[3150]
lines[3159] = lines[3159] + "end -- RematchButtons\n"

# 5. ResultClose: line 3187 (idx 3186) to line 3190 (idx 3189)
lines[3186] = "do -- ResultClose\n" + lines[3186]
lines[3189] = lines[3189] + "end -- ResultClose\n"

# 6. setupMythicalVoteUI: line 3671 (idx 3670) is 'local function setupMythicalVoteUI()'
# line 3986 (idx 3985) is 'end'
# line 3987 (idx 3986) is 'setupMythicalVoteUI()'
# line 3988 (idx 3987) is 'end -- setupMythicalVoteUI'
# Wait! In lines 3670-3671:
# line 3670 is 'do', line 3671 is 'local function setupMythicalVoteUI()'
# If we replace 'local function setupMythicalVoteUI()' with ''
# and replace 'setupMythicalVoteUI()' with ''
# Then lines 3670..3988 is just a single 'do ... end' block!
lines[3670] = "-- do setupMythicalVoteUI\n"
lines[3986] = "-- call setupMythicalVoteUI\n"

# 7. setupWheelZone:
# line 3993 is 'do', line 3994 is 'local function setupWheelZone()'
# line 4122 is 'end', line 4123 is 'setupWheelZone()', line 4124 is 'end -- setupWheelZone'
lines[3993] = "-- do setupWheelZone\n"
lines[4122] = "-- call setupWheelZone\n"

# 8. setupSpectatorDisplay:
# line 4588 is 'do', line 4589 is 'local function setupSpectatorDisplay()'
# line 4884 is 'end -- setupSpectatorDisplay', line 4885 is 'setupSpectatorDisplay()', line 4886 is 'end -- spectator display'
lines[4588] = "-- do setupSpectatorDisplay\n"
lines[4884] = "-- call setupSpectatorDisplay\n"

# 9. setupFeedbackModal:
# line 4891 is 'do', line 4892 is 'local function setupFeedbackModal()'
# line 5158 is 'end -- setupFeedbackModal', line 5159 is 'setupFeedbackModal()', line 5160 is 'end -- feedback modal'
lines[4891] = "-- do setupFeedbackModal\n"
lines[5158] = "-- call setupFeedbackModal\n"

full_text = "".join(lines)
out_path = r'd:\BAF\scratch\MatchClient_test.luau'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(full_text)

print(f"Success! Written {len(full_text)} chars to {out_path}")

# Split into 5 chunks for Studio execute_luau transfer
NUM_PARTS = 5
total_len = len(full_text)
part_size = (total_len + NUM_PARTS - 1) // NUM_PARTS
for idx in range(NUM_PARTS):
    start = idx * part_size
    end = min(start + part_size, total_len)
    chunk = full_text[start:end]
    payload = json.dumps({'c': chunk})
    luau_code = f'_G.mc_test = _G.mc_test or {{}}\n_G.mc_test[{idx+1}] = game:GetService("HttpService"):JSONDecode({json.dumps(payload)}).c\nreturn "Part {idx+1} len: " .. tostring(#_G.mc_test[{idx+1}])'
    fname = rf'd:\BAF\scratch\tpart_{idx+1}.luau'
    with open(fname, 'w', encoding='utf-8') as out:
        out.write(luau_code)
    print(f"Wrote {fname}: {len(chunk)} chunk chars, {len(luau_code)} file size")

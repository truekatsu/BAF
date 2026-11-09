import re, sys
sys.stdout.reconfigure(encoding='utf-8')

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Collect all indent-0 locals and their line numbers
top_locals = []
for i, l in enumerate(lines[:3661]):
    stripped = l.strip()
    if (stripped.startswith("local ") or stripped.startswith("export local ")) and not stripped.startswith("local function"):
        if not l.startswith(" ") and not l.startswith("\t"):
            # extract var name
            m = re.match(r'^(?:export\s+)?local\s+([a-zA-Z0-9_]+)', stripped)
            if m:
                top_locals.append((i, m.group(1), l))

print(f"Total indent-0 locals before 3661: {len(top_locals)}")

# Check usage of each variable across lines 3660 to end of file
later_lines = lines[3660:]
later_text = "".join(later_lines)

used_later = []
not_used_later = []

for line_idx, var_name, full_line in top_locals:
    # search for whole word var_name in later_text
    matches = re.findall(r'\b' + re.escape(var_name) + r'\b', later_text)
    if matches:
        used_later.append((line_idx, var_name, len(matches)))
    else:
        not_used_later.append((line_idx, var_name))

print(f"Used in line 3661+: {len(used_later)}")
print(f"NOT used in line 3661+: {len(not_used_later)}")

print("\n--- SAMPLE NOT USED IN 3661+ (first 30) ---")
for idx, name in not_used_later[:30]:
    print(f"Line {idx+1}: {name}")

import subprocess, sys, re
sys.stdout.reconfigure(encoding='utf-8')

res = subprocess.run(['git', 'diff', 'src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau'], capture_output=True, encoding='utf-8', errors='replace')
diff = res.stdout

added_locals = []
removed_locals = []

for line in diff.splitlines():
    if line.startswith('+') and not line.startswith('+++'):
        txt = line[1:].strip()
        m = re.match(r'^(?:local\s+(?:function\s+([a-zA-Z0-9_]+)|([a-zA-Z0-9_,\s]+)))', txt)
        if m:
            added_locals.append((txt, m.group(1) or m.group(2)))
    elif line.startswith('-') and not line.startswith('---'):
        txt = line[1:].strip()
        m = re.match(r'^(?:local\s+(?:function\s+([a-zA-Z0-9_]+)|([a-zA-Z0-9_,\s]+)))', txt)
        if m:
            removed_locals.append((txt, m.group(1) or m.group(2)))

print(f"Added local declarations: {len(added_locals)}")
print(f"Removed local declarations: {len(removed_locals)}")
print("\n--- SAMPLE ADDED LOCALS ---")
for t, name in added_locals[:30]:
    print(f"+ {name}  (full: {t[:60]})")

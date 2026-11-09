import subprocess

res = subprocess.run(["git", "diff", "--unified=1", "src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau"], capture_output=True, encoding="utf-8", errors="replace")
diff_lines = res.stdout.splitlines()
print(f"Diff lines count: {len(diff_lines)}")
for line in diff_lines[:150]:
    print(line)

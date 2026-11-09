import subprocess, sys
sys.stdout.reconfigure(encoding='utf-8')

res = subprocess.run(['git', 'show', 'HEAD:src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau'], capture_output=True, encoding='utf-8', errors='replace')
with open("d:/BAF/scratch/orig_MatchClient.luau", "w", encoding="utf-8") as f:
    f.write(res.stdout)
print("Saved orig_MatchClient.luau, size:", len(res.stdout))

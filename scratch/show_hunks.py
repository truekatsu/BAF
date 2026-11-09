import subprocess, re

res = subprocess.run(['git', 'diff', '--unified=0', 'src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau'], capture_output=True, encoding='utf-8', errors='replace')
hunks = [line for line in res.stdout.splitlines() if line.startswith('@@')]
for h in hunks:
    print(h)

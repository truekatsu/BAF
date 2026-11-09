import sys
sys.stdout.reconfigure(encoding='utf-8')

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i in range(834, 935):
    print(f"{i+1}: {lines[i]}", end="")

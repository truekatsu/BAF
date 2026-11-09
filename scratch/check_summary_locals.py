import re

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(2940, 3365):
    l = lines[i]
    if l.startswith('local '):
        name = l.split()[1].split(':')[0].split('=')[0].strip()
        print(f"L{i+1}: {name}")

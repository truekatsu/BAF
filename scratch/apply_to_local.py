import json

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Load Group 1 edits
with open('D:/BAF/scratch/edits_group1.json', 'r', encoding='utf-8') as f:
    edits1 = json.load(f)

for i, e in enumerate(edits1):
    if e['old_string'] in text:
        text = text.replace(e['old_string'], e['new_string'])
        print(f"Applied Group 1 edit {i+1}")
    else:
        print(f"WARNING: Group 1 edit {i+1} not found")

# Load Left Nav edit
with open('D:/BAF/scratch/edit_nav.json', 'r', encoding='utf-8') as f:
    e_nav = json.load(f)

if e_nav['old_string'] in text:
    text = text.replace(e_nav['old_string'], e_nav['new_string'])
    print("Applied Left Nav edit")
else:
    print("WARNING: Left Nav edit not found")

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated local MatchClient.client.luau successfully!")

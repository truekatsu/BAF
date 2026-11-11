# scratch/sync_hud_to_studio.py
import json

with open("src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    full_source = f.read()

# Let's save as JSON with code argument for execute_luau or check size
print("Total source length:", len(full_source))

# In Studio, we can write the source directly by passing it in a small script or setting it
# Because execute_luau accepts a code string, let's write a python script that calls Studio API or multi_edit

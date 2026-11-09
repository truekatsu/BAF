with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's inspect where the register count actually exceeds 200 using Studio loadstring!
# We can test slices of MatchClient in Studio to see exactly at what line it exceeds 200!
print("Text length:", len(text))

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's inspect Left Nav
m = text.find("-- Left Vertical Nav Column")
print("Left Nav found:", m != -1)
if m != -1:
    print(text[m:m+500])

# Let's inspect Cash Pill
m = text.find("-- Bottom-Left Friends Boost")
print("Friends Boost found:", m != -1)
if m != -1:
    print(text[m:m+500])

# Let's inspect Opponent Alert Banner
m = text.find("-- Opponent Needed Notification Banner")
print("Opponent Alert found:", m != -1)
if m != -1:
    print(text[m:m+500])

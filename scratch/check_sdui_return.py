with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's find where updateGamepasses ends
s = text.find('return {')
print(text[s-150:s+250])

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    text = f.read()

s = text.find('priceBtn.Activated:Connect(function()')
e = text.find('return {', s) + len('return {')

print("Old slice:")
print(repr(text[s:e]))

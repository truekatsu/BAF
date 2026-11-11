with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'rb') as f:
    content = f.read()

target = b'\t\tmakePart("Gem_PostCap_R_Front", Vector3.new( 0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)\r\n'
replacement = b'\t\tmakePart("Gem_PostCap_R_Front", Vector3.new(0.09, 0.09, 0.03), CFrame.new( 0.64, 3.28, 0.44) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)\r\n'

assert target in content, 'target not found'
content = content.replace(target, replacement, 1)

with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'wb') as f:
    f.write(content)

print('Fixed line 695 successfully!')

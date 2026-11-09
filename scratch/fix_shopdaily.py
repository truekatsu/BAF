import json

old_slice = '''priceBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyShopItem", bp.id)
		end)
	end
end -- Page 5 Shop block
	end

	local function updateGamepasses(p: any)
		if not p then return end
	if shopGamepassCards["vip"] then
		shopGamepassCards["vip"].SetOwned(p.DoubleBux == true and p.OwnedChairs ~= nil and p.OwnedChairs["golden"] == true)
	end
	if shopGamepassCards["2x_bux"] then
		shopGamepassCards["2x_bux"].SetOwned(p.DoubleBux == true)
	end
	if shopGamepassCards["2x_wins"] then
		shopGamepassCards["2x_wins"].SetOwned(p.DoubleWins == true)
	end
	if shopGamepassCards["2x_streak"] then
		shopGamepassCards["2x_streak"].SetOwned(p.DoubleStreak == true)
	end
	if shopGamepassCards["2x_luck"] then
		shopGamepassCards["2x_luck"].SetOwned(p.DoubleLuck == true)
	end
	if shopGamepassCards["inf_rerolls"] then
		shopGamepassCards["inf_rerolls"].SetOwned(p.InfRerolls == true)
	end


	return {'''

new_slice = '''priceBtn.Activated:Connect(function()
			Remotes.MetaAction:FireServer("BuyShopItem", bp.id)
		end)
	end

	local function updateGamepasses(p: any)
		if not p then return end
		if shopGamepassCards["vip"] then
			shopGamepassCards["vip"].SetOwned(p.DoubleBux == true and p.OwnedChairs ~= nil and p.OwnedChairs["golden"] == true)
		end
		if shopGamepassCards["2x_bux"] then
			shopGamepassCards["2x_bux"].SetOwned(p.DoubleBux == true)
		end
		if shopGamepassCards["2x_wins"] then
			shopGamepassCards["2x_wins"].SetOwned(p.DoubleWins == true)
		end
		if shopGamepassCards["2x_streak"] then
			shopGamepassCards["2x_streak"].SetOwned(p.DoubleStreak == true)
		end
		if shopGamepassCards["2x_luck"] then
			shopGamepassCards["2x_luck"].SetOwned(p.DoubleLuck == true)
		end
		if shopGamepassCards["inf_rerolls"] then
			shopGamepassCards["inf_rerolls"].SetOwned(p.InfRerolls == true)
		end
	end

	return {'''

# 1. Update disk file
with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    disk_text = f.read()

assert old_slice in disk_text, "old_slice not in disk_text"
disk_text = disk_text.replace(old_slice, new_slice)

with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'w', encoding='utf-8') as f:
    f.write(disk_text)

print("Updated ShopDailyUI.luau on disk")

# Prepare edit payload for multi_edit
with open('D:/BAF/scratch/edit_shopdaily.json', 'w', encoding='utf-8') as f:
    json.dump({'old_string': old_slice, 'new_string': new_slice}, f)

print("Saved edit_shopdaily.json")

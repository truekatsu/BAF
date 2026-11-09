
local full = table.concat(_G.mc_chunks)
print("Total concatenated length:", #full)
local fn, err = loadstring(full)
print("loadstring syntax ok:", fn ~= nil, "err:", err)
if fn then
    local m = game.StarterPlayer.StarterPlayerScripts.Client:FindFirstChild("MatchClient")
    if m then
        m.Source = full
        print("Updated MatchClient.Source successfully! New len:", #m.Source)
    else
        print("ERROR: MatchClient not found in Client!")
    end
end

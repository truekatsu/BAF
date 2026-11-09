with open('d:/BAF/scratch/MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    code = f.read()

chunk_size = 25000
chunks = [code[i:i+chunk_size] for i in range(0, len(code), chunk_size)]
print(f"Chunks: {len(chunks)}")
for idx, ch in enumerate(chunks):
    with open(f'd:/BAF/scratch/c_{idx+1}.luau', 'w', encoding='utf-8') as f_out:
        f_out.write(f'_G.mc_chunks = _G.mc_chunks or {{}}\n_G.mc_chunks[{idx+1}] = [=[' + ch + f']=]\nprint("Loaded c_{idx+1}")\n')

# And a finisher script
with open('d:/BAF/scratch/c_finish.luau', 'w', encoding='utf-8') as f_out:
    f_out.write("""
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
""")
print("Wrote all chunk scripts and c_finish.luau")

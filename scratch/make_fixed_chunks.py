with open('d:/BAF/scratch/MatchClient_fixed.luau', 'r', encoding='utf-8') as f:
    code = f.read()

chunk_size = 40000
chunks = [code[i:i+chunk_size] for i in range(0, len(code), chunk_size)]
print(f"Chunks: {len(chunks)}")
for idx, ch in enumerate(chunks):
    with open(f'd:/BAF/scratch/fixed_chunk_{idx}.luau', 'w', encoding='utf-8') as f_out:
        # We write Lua code that sets _G.mc_chunks[idx+1]
        f_out.write(f'_G.mc_chunks = _G.mc_chunks or {{}}\n_G.mc_chunks[{idx+1}] = [=[' + ch + ']=]\nprint("Loaded fixed chunk ' + str(idx+1) + '")\n')
print("All chunk files written.")

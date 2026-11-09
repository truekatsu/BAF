import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('d:/BAF/scratch/chunks/orig_0.txt', 'r', encoding='utf-8') as f: c0 = f.read()
with open('d:/BAF/scratch/chunks/orig_1.txt', 'r', encoding='utf-8') as f: c1 = f.read()
with open('d:/BAF/scratch/chunks/orig_2.txt', 'r', encoding='utf-8') as f: c2 = f.read()
with open('d:/BAF/scratch/chunks/orig_3.txt', 'r', encoding='utf-8') as f: c3 = f.read()
with open('d:/BAF/scratch/chunks/orig_4.txt', 'r', encoding='utf-8') as f: c4 = f.read()

with open('d:/BAF/scratch/test_orig_0.luau', 'w', encoding='utf-8') as f:
    f.write('_G.oc = {}\n_G.oc[1] = [=[' + c0 + ']=]\nprint("Loaded orig 1")\n')
with open('d:/BAF/scratch/test_orig_1.luau', 'w', encoding='utf-8') as f:
    f.write('_G.oc[2] = [=[' + c1 + ']=]\nprint("Loaded orig 2")\n')
with open('d:/BAF/scratch/test_orig_2.luau', 'w', encoding='utf-8') as f:
    f.write('_G.oc[3] = [=[' + c2 + ']=]\nprint("Loaded orig 3")\n')
with open('d:/BAF/scratch/test_orig_3.luau', 'w', encoding='utf-8') as f:
    f.write('_G.oc[4] = [=[' + c3 + ']=]\nprint("Loaded orig 4")\n')
with open('d:/BAF/scratch/test_orig_4.luau', 'w', encoding='utf-8') as f:
    f.write('_G.oc[5] = [=[' + c4 + ']=]\nlocal full = table.concat(_G.oc)\nlocal fn, err = loadstring(full)\nprint("Orig MatchClient loadstring result:", fn ~= nil, err)\n')

print("Created 5 test files")

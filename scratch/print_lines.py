with open("d:/BAF/scratch/orig_MatchClient.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i in range(75, 120):
    print(f"{i+1}: {lines[i]}", end="")

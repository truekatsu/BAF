from compare_vars import get_top_level_vars

orig = get_top_level_vars("d:/BAF/scratch/orig_MatchClient.luau")
for line_num, name, kind in orig:
    print(f"{line_num}: {kind} {name}")

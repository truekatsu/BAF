from check_blocks import check_vars_in_range

total, internal, escapes = check_vars_in_range(600, 2200)
print(f"Lines 600-2200: {len(total)} locals ({len(internal)} internal only, {len(escapes)} used outside)")
print("\nUsed outside:")
for line_no, name, cnt in escapes:
    print(f"  Line {line_no}: {name} (count={cnt})")

print("\nInternal only (first 25):")
for line_no, name in internal[:25]:
    print(f"  Line {line_no}: {name}")

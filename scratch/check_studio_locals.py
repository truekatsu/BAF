with open('D:/BAF/scratch/studio_MatchClient.luau', 'r', encoding='utf-8') as f:
    text = f.read()

lines = text.split('\n')
print(f"Total lines in studio_MatchClient: {len(lines)}")
# Check where the registers pile up between 2260 and 3660
count = 0
for i, line in enumerate(lines):
    if line.startswith('local ') or line.startswith('local function '):
        count += 1
        if count >= 190 and count <= 205:
            print(f"#{count:03d} L{i+1}: {line.strip()[:70]}")

print(f"Total col0 locals in Studio file: {count}")

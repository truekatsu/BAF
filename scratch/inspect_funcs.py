with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

print("Lines 3660 to 3675:")
for i in range(3659, 3675):
    print(f"{i+1}: {lines[i]}", end="")

print("\nLines 3970 to 3990:")
for i in range(3969, 3990):
    print(f"{i+1}: {lines[i]}", end="")

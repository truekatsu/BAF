# Let's count actual local declarations in Luau syntax.
# In Luau, a local variable is declared by:
# 1. `local x = ...` or `local x: Type = ...` or `local x, y = ...`
# 2. `local function x(...)`
# But if it's INSIDE a function `function ... end`, those locals belong to THAT function's scope and do NOT consume registers of the outer scope once that function is closed!
# However, if an outer scope has a lot of `local` variables, they stay in the register file of that outer scope!

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

print(f"Lines 3655-3670:")
for i in range(3654, min(3670, len(lines))):
    print(f"{i+1}: {lines[i]}", end="")

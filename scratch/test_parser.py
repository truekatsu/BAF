with open('D:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Let's count how many local variables are declared in MatchClient.client.luau:
# In Luau, any `local x` or `local function x` in the top-level chunk counts toward the 200 register limit.
# What are the actual local variables in MatchClient?
# Let's write a script that parses Luau statements.

# In Lua/Luau:
# Keywords:
# Block starters:
# - do ... end
# - while exp do ... end
# - repeat ... until exp
# - if exp then ... elseif exp then ... else ... end
# - for ... do ... end
# - function [name](...) ... end
# - local function name(...) ... end
#
# BUT:
# - `if c then a else b` is an if-expression (ternary), only when preceded by '=', 'return', '(', '{', ',', ':', 'then', 'else', or at start of expression.
# - type annotations: `(a: string) -> ()`
# - strings, comments.

# Instead of writing a full compiler, why don't we test with Luau in Roblox Studio via execute_luau?
# Remember, Studio has execute_luau which actually compiles and runs Luau!
print("Ready to analyze via python or Studio")

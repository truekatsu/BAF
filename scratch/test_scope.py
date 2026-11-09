import re

with open(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau', 'r', encoding='utf-8') as f:
    text = f.read()

# Tokenize words, strings, comments
# In Lua:
# Block openers: 'do', 'then', 'repeat', 'function' (when not followed by an end or not anonymous inside expr... wait)
# Luau lexical scopes:
# Every 'function ... end' creates a scope.
# Every 'do ... end' creates a scope.
# Every 'then ... else/elseif ... end' creates a scope.
# Every 'repeat ... until' creates a scope.
# In Luau, register allocation limit is 200 per FUNCTION / CHUNK scope.
# The whole file is chunk function `main()`.
# If `main()` has more than 200 locals, Luau throws:
# "Out of local registers when trying to allocate ...: exceeded limit 200"

# Any local defined inside `function foo() ... end` is in foo's scope, NOT main()'s scope!
# BUT any `local function foo()` declared at chunk level IS a local in main()!
# And any `local x = ...` declared at chunk level IS a local in main()!

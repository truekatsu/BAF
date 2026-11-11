import os

files_to_check = [
    r'd:\BAF\src\ReplicatedStorage\Shared\GameConfig.luau',
    r'd:\BAF\src\ReplicatedStorage\Prefabs\ChairModelBuilder.luau',
    r'd:\BAF\src\ReplicatedStorage\Shared\SelfTest.luau',
    r'd:\BAF\src\ServerScriptService\Server\MatchService.luau',
    r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau',
]

def check_luau_brackets(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    in_str = None
    in_block_comment = False
    i = 0
    lno = 1
    n = len(content)
    
    while i < n:
        ch = content[i]
        if ch == '\n':
            lno += 1
            i += 1
            continue
            
        if in_block_comment:
            if content[i:i+2] == ']]':
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue
            
        if in_str:
            if ch == '\\':
                i += 2
                continue
            if ch == in_str:
                in_str = None
            i += 1
            continue
            
        if content[i:i+4] == '--[[':
            in_block_comment = True
            i += 4
            continue
            
        if content[i:i+2] == '--':
            # line comment
            while i < n and content[i] != '\n':
                i += 1
            continue
            
        if ch in ('"', "'", '`'):
            in_str = ch
            i += 1
            continue
            
        if ch in '([{':
            stack.append((ch, lno))
        elif ch in ')]}':
            expected = pairs[ch]
            if not stack or stack[-1][0] != expected:
                return False, f"Mismatch at line {lno}: found '{ch}', stack top {stack[-1] if stack else 'empty'}"
            stack.pop()
        i += 1
        
    if stack:
        return False, f"Unclosed brackets: {stack[-5:]}"
    return True, "OK"

for fpath in files_to_check:
    fname = os.path.basename(fpath)
    ok, msg = check_luau_brackets(fpath)
    print(f"{fname}: {'PASSED' if ok else 'FAILED - ' + msg}")

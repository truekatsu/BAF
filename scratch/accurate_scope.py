import re

def analyze_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        src = f.read()

    # Strip multi-line comments and single-line comments first
    src_clean = re.sub(r'--\[(=*)\[[\s\S]*?\]\1\]', '', src)
    src_clean = re.sub(r'\[(=*)\[[\s\S]*?\]\1\]', '""', src_clean)
    
    lines = src_clean.split('\n')
    
    depth = 0
    file_locals = []
    
    for line_idx, line in enumerate(lines):
        line_no = line_idx + 1
        line_no_comment = line.split('--')[0]
        line_no_str = re.sub(r'"(?:\\.|[^"\\])*"', '""', line_no_comment)
        line_no_str = re.sub(r"'(?:\\.|[^'\\])*'", "''", line_no_str)
        line_no_str = re.sub(r"`(?:\\.|[^`\\])*`", "``", line_no_str)
        
        words = re.findall(r'\b[A-Za-z_][A-Za-z0-9_]*\b', line_no_str)
        
        if depth == 0 and words and words[0] == 'local':
            decl = line_no_comment.strip()
            file_locals.append((line_no, decl))
            
        for w in words:
            if w in ('do', 'then', 'repeat', 'function'):
                depth += 1
            elif w in ('end', 'until'):
                depth = max(0, depth - 1)

    print(f"Total file scope locals found: {len(file_locals)}")
    for lno, txt in file_locals:
        print(f"L{lno:4d}: {txt[:80]}")

analyze_file(r'd:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\MatchClient.client.luau')

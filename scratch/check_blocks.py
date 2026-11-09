import re, sys
sys.stdout.reconfigure(encoding='utf-8')

with open("d:/BAF/src/StarterPlayer/StarterPlayerScripts/Client/MatchClient.client.luau", "r", encoding="utf-8") as f:
    lines = f.readlines()

def check_vars_in_range(start_line, end_line):
    # Find all indent-0 locals
    locals_in_range = []
    for idx in range(start_line - 1, min(end_line, len(lines))):
        l = lines[idx]
        stripped = l.strip()
        if (stripped.startswith("local ") or stripped.startswith("export local ")) and not stripped.startswith("local function"):
            if not l.startswith(" ") and not l.startswith("\t"):
                m = re.match(r'^(?:export\s+)?local\s+([a-zA-Z0-9_]+)', stripped)
                if m:
                    locals_in_range.append((idx + 1, m.group(1)))
    
    # Check if used outside start_line..end_line
    outside_text = "".join(lines[:start_line-1]) + "".join(lines[end_line:])
    escapes = []
    internal = []
    for line_no, name in locals_in_range:
        m = re.findall(r'\b' + re.escape(name) + r'\b', outside_text)
        if m:
            escapes.append((line_no, name, len(m)))
        else:
            internal.append((line_no, name))
    return locals_in_range, internal, escapes

for (s, e, label) in [
    (316, 450, "TopRightBar & NavColumn"),
    (526, 595, "OpponentAlertBanner"),
    (2320, 2418, "WaitingWrap"),
    (2419, 2432, "IntroWrap"),
    (2433, 2450, "CountdownWrap"),
    (2880, 2933, "ShowdownWrap"),
    (2934, 3030, "WinnerWrap"),
    (3031, 3140, "RadarPanel & BadgeToast"),
    (3155, 3250, "ResultPopup"),
]:
    total, internal, escapes = check_vars_in_range(s, e)
    print(f"\n[{label}] Lines {s}-{e}: {len(total)} locals ({len(internal)} internal only, {len(escapes)} used outside)")
    if escapes:
        print("  Used outside:", [name for _, name, _ in escapes])

from check_blocks import check_vars_in_range

for (s, e, label) in [
    (3659, 3978, "setupMythicalVoteUI"),
    (3982, 4025, "setupWheelZone"),
    (4575, 4872, "setupSpectatorDisplay"),
    (4876, 5161, "setupFeedbackModal"),
]:
    total, internal, escapes = check_vars_in_range(s, e)
    print(f"\n[{label}] Lines {s}-{e}: {len(total)} locals ({len(internal)} internal only, {len(escapes)} used outside)")
    if escapes:
        print("  Used outside:", [name for _, name, _ in escapes])

path = r"d:\BAF\src\StarterPlayer\StarterPlayerScripts\Client\ShopDailyUI.luau"
with open(path, "r", encoding="utf-8") as f:
    c = f.read()

# Normalize CRLF to LF for reliable matching
is_crlf = "\r\n" in c
c_lf = c.replace("\r\n", "\n")

target = """end -- Page 5 Shop block
\tend

\tlocal function updateGamepasses(p: any)"""

replacement = """end -- Page 5 Shop block

\tlocal function updateGamepasses(p: any)"""

print("Target found:", target in c_lf)
c_lf = c_lf.replace(target, replacement)

end_target = """\tif shopGamepassCards["inf_rerolls"] then
\t\tshopGamepassCards["inf_rerolls"].SetOwned(p.InfRerolls == true)
\tend


\treturn {"""

end_replacement = """\tif shopGamepassCards["inf_rerolls"] then
\t\tshopGamepassCards["inf_rerolls"].SetOwned(p.InfRerolls == true)
\tend
\tend

\treturn {"""

print("End target found:", end_target in c_lf)
c_lf = c_lf.replace(end_target, end_replacement)

final_c = c_lf.replace("\n", "\r\n") if is_crlf else c_lf
with open(path, "w", encoding="utf-8") as f:
    f.write(final_c)

print("Saved fixed ShopDailyUI.luau!")

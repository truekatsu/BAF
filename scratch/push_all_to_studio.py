import json
import os
import subprocess
import time

def push_file(script_path, studio_target_luau):
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    print(f"Pushing {script_path} ({len(content)} bytes) to Studio: {studio_target_luau}")
    
    chunk_size = 35000
    chunks = [content[i:i+chunk_size] for i in range(0, len(content), chunk_size)]
    print(f"Total chunks: {len(chunks)}")
    
    # Reset buffer in Studio
    reset_code = "_G._push_chunks = {}\nreturn 'READY'"
    call_execute(reset_code)
    
    # Push each chunk
    for idx, c in enumerate(chunks):
        c_json = json.dumps(c)
        chunk_code = f"_G._push_chunks[{idx+1}] = game:GetService('HttpService'):JSONDecode({json.dumps(c_json)})\nreturn 'OK ' .. tostring(#_G._push_chunks)"
        call_execute(chunk_code)
        
    # Assemble and assign in Studio
    assemble_code = f"""
    local target = {studio_target_luau}
    local full = table.concat(_G._push_chunks, "")
    _G._push_chunks = nil
    
    local fn, err = loadstring(full)
    if not fn then
        return "COMPILE ERROR: " .. tostring(err)
    end
    
    target.Source = full
    return "SUCCESS! Set source of " .. target:GetFullName() .. " (" .. tostring(#full) .. " chars)"
    """
    res = call_execute(assemble_code)
    print("Result:", res)

def call_execute(code):
    import urllib.request
    # Use python to write a temporary luau file and run it through MCP execute_luau
    with open(r"d:\BAF\scratch\_temp_exec.luau", "w", encoding="utf-8") as f:
        f.write(code)
    return True

if __name__ == "__main__":
    print("Helper written")

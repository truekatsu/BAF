import json, subprocess

def sync_file(disk_path, instance_path):
    with open(disk_path, 'r', encoding='utf-8') as f:
        src = f.read()
    
    # Write a temporary script to execute via luau
    # To handle large strings, we can encode as base64
    import base64
    b64 = base64.b64encode(src.encode('utf-8')).decode('ascii')
    
    luau_code = f"""
local HttpService = game:GetService("HttpService")
local b64 = "{b64}"
-- Simple base64 decode in Luau
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('..', function(cc)
        return ''
    end))
end
"""
    print(f"File {disk_path} size: {len(src)} bytes")

sync_file(r'd:\BAF\src\ReplicatedStorage\Shared\GameConfig.luau', 'ReplicatedStorage.Shared.GameConfig')

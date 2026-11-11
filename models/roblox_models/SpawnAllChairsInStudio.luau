--!strict
--[[
    SpawnAllChairsInStudio.luau
    Usage:
      1. Open Roblox Studio.
      2. Paste this entire script into the Command Bar at the bottom of Studio and press Enter.
      3. A folder named 'ExportedChairs_Showcase' will immediately be created in Workspace
         containing all 4 chairs lined up side-by-side with full Seats, Particles, Lights, and Effects!
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local existing = Workspace:FindFirstChild("ExportedChairs_Showcase")
if existing then
    existing:Destroy()
end

-- Clean up any existing loose chair models in Workspace so they don't overlap / tertimpa
for _, oldName in { "CrimsonFlameChair", "Chair_crimson", "CrimsonChair", "Chair_cyber_core", "CyberCoreChair", "FrostbiteIceThrone", "FrostbiteChair", "Chair_frostbite", "RoyalFootballThrone", "RoyalThrone" } do
    local old = Workspace:FindFirstChild(oldName)
    if old then
        old:Destroy()
    end
end

local showcaseFolder = Instance.new("Folder")
showcaseFolder.Name = "ExportedChairs_Showcase"
showcaseFolder.Parent = Workspace

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, canCollide: boolean?, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = mat or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = if canCollide ~= nil then canCollide else false
    p.CastShadow = true
    if shape then
        p.Shape = shape
    end
    p.Parent = parent
    return p
end

local function makeSeat(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Seat
    local s = Instance.new("Seat")
    s.Name = name
    s.Size = size
    s.CFrame = cf
    s.Color = color
    s.Material = mat or Enum.Material.SmoothPlastic
    s.Anchored = true
    s.CanCollide = true
    s.CastShadow = true
    s.Parent = parent
    return s
end

-- ============================================================================
-- 1. CRIMSON FLAME CHAIR
-- ============================================================================
local function spawnCrimsonFlameChair(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "CrimsonFlameChair"
    model.Parent = showcaseFolder

    local cWood = Color3.fromRGB(150, 15, 25)
    local cLeg = Color3.fromRGB(110, 10, 20)
    local cIron = Color3.fromRGB(30, 24, 28)
    local cGem = Color3.fromRGB(255, 40, 50)

    local seat = makeSeat(model, "Seat", Vector3.new(4, 0.7, 4), cfBase * CFrame.new(0, 2.85, 0), cWood, Enum.Material.WoodPlanks)
    model.PrimaryPart = seat

    local glow = Instance.new("PointLight")
    glow.Name = "SeatGlow"
    glow.Color = Color3.fromRGB(255, 40, 40)
    glow.Brightness = 2
    glow.Range = 14
    glow.Parent = seat

    local legOffsets = {
        FL = Vector3.new(-1.6, 1.25, -1.6),
        FR = Vector3.new( 1.6, 1.25, -1.6),
        BL = Vector3.new(-1.6, 1.25,  1.6),
        BR = Vector3.new( 1.6, 1.25,  1.6),
    }

    local legCaps = {}
    for tag, offset in legOffsets do
        makePart(model, "Leg_" .. tag, Vector3.new(0.8, 2.5, 0.8), cfBase * CFrame.new(offset), cLeg, Enum.Material.WoodPlanks, true)
        local cap = makePart(model, "LegCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(offset.X, 0.25, offset.Z), cIron, Enum.Material.Slate, false)
        legCaps[tag] = cap

        local att = Instance.new("Attachment")
        att.Name = "FireAtt"
        att.Parent = cap
        local fire = Instance.new("ParticleEmitter")
        fire.Name = "FireEmitter"
        fire.Texture = "rbxassetid://253188732"
        fire.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(120, 0, 10))
        fire.LightEmission = 1
        fire.Size = NumberSequence.new(1.8, 0)
        fire.Lifetime = NumberRange.new(0.8, 1.4)
        fire.Rate = 20
        fire.Speed = NumberRange.new(2, 4)
        fire.Acceleration = Vector3.new(0, 5, 0)
        fire.Parent = att

        makePart(model, "Gem_LegCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(offset.X, 0.25, offset.Z - 0.49) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
    end

    for _, tag in { "Left", "Right" } do
        local px = if tag == "Left" then -1.6 else 1.6
        makePart(model, "Post_" .. tag, Vector3.new(0.8, 5, 0.8), cfBase * CFrame.new(px, 5.7, 1.6), cWood, Enum.Material.WoodPlanks, true)
        local cap = makePart(model, "PostCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(px, 8.2, 1.6), cIron, Enum.Material.Slate, false)

        local att = Instance.new("Attachment")
        att.Parent = cap
        local fire = Instance.new("ParticleEmitter")
        fire.Texture = "rbxassetid://253188732"
        fire.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(120, 0, 10))
        fire.LightEmission = 1
        fire.Size = NumberSequence.new(1.8, 0)
        fire.Lifetime = NumberRange.new(0.8, 1.4)
        fire.Rate = 24
        fire.Speed = NumberRange.new(2, 4)
        fire.Acceleration = Vector3.new(0, 5, 0)
        fire.Parent = att

        makePart(model, "Gem_PostCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(px, 8.2, 1.11) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
    end

    makePart(model, "BackrestPanel", Vector3.new(3.2, 4.4, 0.4), cfBase * CFrame.new(0, 5.7, 1.6), cWood, Enum.Material.WoodPlanks, true)

    for tag, d in { FL = { -1, -1 }, FR = { 1, -1 }, BL = { -1, 1 }, BR = { 1, 1 } } do
        local cx, cz = d[1], d[2]
        makePart(model, "BracketX_" .. tag, Vector3.new(0.85, 0.12, 0.28), cfBase * CFrame.new(cx * 1.575, 3.26, cz * 1.86), cIron, Enum.Material.Slate)
        makePart(model, "BracketZ_" .. tag, Vector3.new(0.28, 0.12, 0.85), cfBase * CFrame.new(cx * 1.86, 3.26, cz * 1.575), cIron, Enum.Material.Slate)
        makePart(model, "Gem_Corner_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(cx * 1.80, 3.32, cz * 1.80) * CFrame.Angles(math.rad(90), math.rad(45), 0), cGem, Enum.Material.Neon)
    end

    local hl = Instance.new("Highlight")
    hl.Name = "FlameHighlight"
    hl.OutlineColor = Color3.fromRGB(255, 60, 50)
    hl.OutlineTransparency = 1
    hl.FillColor = Color3.fromRGB(200, 20, 30)
    hl.FillTransparency = 0.95
    hl.Adornee = model
    hl.Parent = model

    local scr = Instance.new("Script")
    scr.Source = [[
local TweenService = game:GetService("TweenService")
local model = script.Parent
local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
for _, desc in ipairs(model:GetDescendants()) do
    if desc:IsA("BasePart") and desc.Name:find("Gem") then
        desc.Color = Color3.fromRGB(153, 24, 30)
        TweenService:Create(desc, info, { Color = Color3.fromRGB(255, 40, 50) }):Play()
    end
end
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- 2. CYBER CORE CHAIR
-- ============================================================================
local function spawnCyberCoreChair(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "CyberCoreChair"
    model.Parent = showcaseFolder

    local cMetal = Color3.fromRGB(18, 20, 32)
    local cCap = Color3.fromRGB(35, 40, 60)
    local cCyan = Color3.fromRGB(0, 255, 240)
    local cMagenta = Color3.fromRGB(255, 0, 200)

    local seat = makeSeat(model, "Seat", Vector3.new(4, 0.7, 4), cfBase * CFrame.new(0, 2.85, 0), cMetal, Enum.Material.Metal)
    model.PrimaryPart = seat

    makePart(model, "SeatCircuitX1", Vector3.new(3.8, 0.08, 0.12), cfBase * CFrame.new(0, 3.22, -1.8), cCyan, Enum.Material.Neon)
    makePart(model, "SeatCircuitX2", Vector3.new(3.8, 0.08, 0.12), cfBase * CFrame.new(0, 3.22,  1.8), cCyan, Enum.Material.Neon)
    makePart(model, "SeatCircuitZ1", Vector3.new(0.12, 0.08, 3.6), cfBase * CFrame.new(-1.8, 3.22, 0), cMagenta, Enum.Material.Neon)
    makePart(model, "SeatCircuitZ2", Vector3.new(0.12, 0.08, 3.6), cfBase * CFrame.new( 1.8, 3.22, 0), cMagenta, Enum.Material.Neon)
    makePart(model, "SeatChipCenter", Vector3.new(1.2, 0.06, 1.2), cfBase * CFrame.new(0, 3.22, 0) * CFrame.Angles(0, math.rad(45), 0), cCyan, Enum.Material.Neon)

    for tag, d in { FL = { -1.6, -1.6 }, FR = { 1.6, -1.6 }, BL = { -1.6, 1.6 }, BR = { 1.6, 1.6 } } do
        local lx, lz = d[1], d[2]
        makePart(model, "Leg_" .. tag, Vector3.new(0.8, 2.5, 0.8), cfBase * CFrame.new(lx, 1.25, lz), cMetal, Enum.Material.Metal, true)
        makePart(model, "LegTrace_" .. tag, Vector3.new(0.12, 2.4, 0.12), cfBase * CFrame.new(lx, 1.25, lz - 0.38), cCyan, Enum.Material.Neon)
        local cap = makePart(model, "LegCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(lx, 0.25, lz), cCap, Enum.Material.Metal, false)
        
        local pl = Instance.new("PointLight")
        pl.Color = cMagenta
        pl.Brightness = 1.5
        pl.Range = 8
        pl.Parent = cap

        makePart(model, "Gem_LegCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(lx, 0.25, lz - 0.49) * CFrame.Angles(0, 0, math.rad(45)), cMagenta, Enum.Material.Neon)
    end

    for _, tag in { "Left", "Right" } do
        local px = if tag == "Left" then -1.6 else 1.6
        makePart(model, "Post_" .. tag, Vector3.new(0.8, 5, 0.8), cfBase * CFrame.new(px, 5.7, 1.6), cMetal, Enum.Material.Metal, true)
        makePart(model, "PostTrace_" .. tag, Vector3.new(0.12, 4.8, 0.12), cfBase * CFrame.new(px, 5.7, 1.18), cMagenta, Enum.Material.Neon)
        local cap = makePart(model, "PostCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(px, 8.2, 1.6), cCap, Enum.Material.Metal, false)

        local pl = Instance.new("PointLight")
        pl.Color = cCyan
        pl.Brightness = 1.5
        pl.Range = 8
        pl.Parent = cap

        makePart(model, "Gem_PostCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(px, 8.2, 1.11) * CFrame.Angles(0, 0, math.rad(45)), cCyan, Enum.Material.Neon)
    end

    makePart(model, "BackrestPanel", Vector3.new(3.2, 4.4, 0.4), cfBase * CFrame.new(0, 5.7, 1.6), cMetal, Enum.Material.Metal, true)

    local hexR = 0.85
    for i = 0, 5 do
        local rad = math.rad(i * 60)
        local hx = math.cos(rad) * hexR
        local hy = math.sin(rad) * hexR
        makePart(model, "HexStrut_" .. i, Vector3.new(0.45, 0.10, 0.12), cfBase * CFrame.new(hx, 5.7 + hy, 1.36) * CFrame.Angles(0, 0, rad + math.rad(30)), cMagenta, Enum.Material.Neon)
    end

    local core = makePart(model, "EnergyCore", Vector3.new(0.8, 0.8, 0.8), cfBase * CFrame.new(0, 5.7, 1.35) * CFrame.Angles(math.rad(45), math.rad(45), 0), cCyan, Enum.Material.Neon)
    local coreLight = Instance.new("PointLight")
    coreLight.Color = cCyan
    coreLight.Brightness = 3
    coreLight.Range = 16
    coreLight.Parent = core

    local sparksAtt = Instance.new("Attachment")
    sparksAtt.Parent = core
    local sparks = Instance.new("ParticleEmitter")
    sparks.Color = ColorSequence.new(cCyan, cMagenta)
    sparks.LightEmission = 1
    sparks.Size = NumberSequence.new(0.6, 0.1)
    sparks.Lifetime = NumberRange.new(0.8, 1.6)
    sparks.Rate = 20
    sparks.Speed = NumberRange.new(1.5, 3.5)
    sparks.Parent = sparksAtt

    local scr = Instance.new("Script")
    scr.Source = [[
local RunService = game:GetService("RunService")
local model = script.Parent
local core = model:FindFirstChild("EnergyCore")
local baseY = core and core.Position.Y or 5.7
local t = 0
RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    if core and core:IsA("BasePart") then
        core.CFrame = CFrame.new(core.Position.X, baseY + math.sin(t * 3) * 0.18, core.Position.Z) * CFrame.Angles(0, t * 1.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
    end
end)
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- 3. FROSTBITE ICE THRONE
-- ============================================================================
local function spawnFrostbiteThrone(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "FrostbiteIceThrone"
    model.Parent = showcaseFolder

    local cDeep = Color3.fromRGB(60, 150, 230)
    local cMain = Color3.fromRGB(120, 210, 255)
    local cGlow = Color3.fromRGB(160, 240, 255)
    local cSnow = Color3.fromRGB(245, 250, 255)
    local cGem = Color3.fromRGB(100, 235, 255)

    local seat = makeSeat(model, "Seat", Vector3.new(3.8, 0.7, 3.6), cfBase * CFrame.new(0, 2.5, 0), cDeep, Enum.Material.Glass)
    model.PrimaryPart = seat
    makePart(model, "SeatCushionRecess", Vector3.new(3.2, 0.25, 3.0), cfBase * CFrame.new(0, 2.88, 0.1), cMain, Enum.Material.Glass)

    for i = 0, 2 do
        local yOff = 2.2 - (i * 0.45)
        makePart(model, "Chevron_L_" .. i, Vector3.new(1.1, 0.28, 0.2), cfBase * CFrame.new(-0.55, yOff, -1.85) * CFrame.Angles(0, 0, math.rad(-22)), cGlow, Enum.Material.Neon)
        makePart(model, "Chevron_R_" .. i, Vector3.new(1.1, 0.28, 0.2), cfBase * CFrame.new( 0.55, yOff, -1.85) * CFrame.Angles(0, 0, math.rad(22)), cGlow, Enum.Material.Neon)
    end

    for tag, d in { FL = { -1.5, -1.4 }, FR = { 1.5, -1.4 }, BL = { -1.5, 1.4 }, BR = { 1.5, 1.4 } } do
        local lx, lz = d[1], d[2]
        makePart(model, "Leg_" .. tag, Vector3.new(0.8, 2.2, 0.8), cfBase * CFrame.new(lx, 1.1, lz), cDeep, Enum.Material.Glass, true)
        makePart(model, "FootBlock_" .. tag, Vector3.new(1.15, 0.75, 1.15), cfBase * CFrame.new(lx, 0.38, lz) * CFrame.Angles(0, math.rad(if tag:find("L") then 15 else -15), 0), cMain, Enum.Material.Glass)
    end

    for _, tag in { "Left", "Right" } do
        local ax = if tag == "Left" then -1.9 else 1.9
        makePart(model, "ArmrestPillar_" .. tag, Vector3.new(0.85, 1.8, 0.85), cfBase * CFrame.new(ax, 1.7, -1.2), cDeep, Enum.Material.Glass, true)
        makePart(model, "Armrest_" .. tag, Vector3.new(0.85, 0.85, 3.2), cfBase * CFrame.new(ax, 3.4, 0), cDeep, Enum.Material.Glass, true)
        makePart(model, "SnowCap_" .. tag, Vector3.new(0.95, 0.28, 3.2), cfBase * CFrame.new(ax, 3.85, 0), cSnow, Enum.Material.SmoothPlastic)
        for ic = 0, 3 do
            makePart(model, "Icicle_" .. tag .. "_" .. ic, Vector3.new(0.12, 0.55, 0.12), cfBase * CFrame.new(ax, 2.75 - ic * 0.05, -1.2 + ic * 0.8), cGlow, Enum.Material.Glass)
        end
    end

    makePart(model, "BackrestSlab", Vector3.new(3.4, 5.2, 0.6), cfBase * CFrame.new(0, 5.1, 1.5), cDeep, Enum.Material.Glass, true)

    for i = 0, 4 do
        local yOff = 3.8 + (i * 0.75)
        local w = 1.6 - (i * 0.18)
        makePart(model, "BackChevron_L_" .. i, Vector3.new(w, 0.32, 0.18), cfBase * CFrame.new(-w * 0.45, yOff, 1.18) * CFrame.Angles(0, 0, math.rad(-26)), cMain, Enum.Material.Glass)
        makePart(model, "BackChevron_R_" .. i, Vector3.new(w, 0.32, 0.18), cfBase * CFrame.new( w * 0.45, yOff, 1.18) * CFrame.Angles(0, 0, math.rad(26)), cMain, Enum.Material.Glass)
    end

    local shardConfigs = {
        { -2.2, 4.0, -32, 0.48 },
        { -1.8, 4.8, -26, 0.52 },
        { -1.4, 5.6, -20, 0.55 },
        { -1.0, 6.2, -14, 0.58 },
        { -0.5, 6.8,  -7, 0.60 },
        {  0.0, 7.4,   0, 0.64 },
        {  0.5, 6.8,   7, 0.60 },
        {  1.0, 6.2,  14, 0.58 },
        {  1.4, 5.6,  20, 0.55 },
        {  1.8, 4.8,  26, 0.52 },
        {  2.2, 4.0,  32, 0.48 },
    }
    for idx, cfg in ipairs(shardConfigs) do
        local sx, sh, srot, sw = cfg[1], cfg[2], cfg[3], cfg[4]
        makePart(model, "CrystalShard_" .. idx, Vector3.new(sw, sh, sw), cfBase * CFrame.new(sx, 5.2 + sh * 0.45, 1.65) * CFrame.Angles(0, 0, math.rad(srot)), cGlow, Enum.Material.Neon)
    end

    local gem = makePart(model, "TopDiamondGem", Vector3.new(1.2, 1.8, 0.8), cfBase * CFrame.new(0, 8.8, 1.45) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
    local pl = Instance.new("PointLight")
    pl.Color = Color3.fromRGB(140, 230, 255)
    pl.Brightness = 2.5
    pl.Range = 16
    pl.Parent = gem

    local mistAtt = Instance.new("Attachment")
    mistAtt.Parent = gem
    local mist = Instance.new("ParticleEmitter")
    mist.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255), Color3.fromRGB(255, 255, 255))
    mist.LightEmission = 0.8
    mist.Size = NumberSequence.new(1.2, 0.2)
    mist.Lifetime = NumberRange.new(1.0, 2.5)
    mist.Rate = 12
    mist.Speed = NumberRange.new(0.8, 2.0)
    mist.Parent = mistAtt

    local scr = Instance.new("Script")
    scr.Source = [[
local TweenService = game:GetService("TweenService")
local model = script.Parent
local topGem = model:FindFirstChild("TopDiamondGem")
if topGem and topGem:IsA("BasePart") then
    local tw = TweenService:Create(topGem, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Color = Color3.fromRGB(180, 250, 255)
    })
    tw:Play()
end
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- 4. ROYAL FOOTBALL THRONE
-- ============================================================================
local function spawnRoyalFootballThrone(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "RoyalFootballThrone"
    model.Parent = showcaseFolder

    local cGold = Color3.fromRGB(255, 195, 30)
    local cVelvet = Color3.fromRGB(180, 20, 32)
    local cDarkUnderside = Color3.fromRGB(30, 24, 22)
    local cRuby = Color3.fromRGB(255, 30, 50)
    local cWhite = Color3.fromRGB(255, 255, 255)
    local cBlack = Color3.fromRGB(20, 20, 22)

    for _, tag in { "Left", "Right" } do
        local bx = if tag == "Left" then -1.9 else 1.9
        makePart(model, "FootSlab_" .. tag, Vector3.new(1.8, 0.6, 3.2), cfBase * CFrame.new(bx, 0.3, 0), cGold, Enum.Material.SmoothPlastic, true)
        makePart(model, "Pillar_" .. tag, Vector3.new(1.4, 1.8, 2.4), cfBase * CFrame.new(bx, 1.5, 0), cGold, Enum.Material.SmoothPlastic, true)
        makePart(model, "PillarRedPanel_" .. tag, Vector3.new(1.1, 1.4, 0.05), cfBase * CFrame.new(bx, 1.5, -1.23), cVelvet, Enum.Material.SmoothPlastic)
    end
    makePart(model, "UndersideHollow", Vector3.new(2.2, 1.6, 2.6), cfBase * CFrame.new(0, 1.4, 0), cDarkUnderside, Enum.Material.SmoothPlastic)

    makePart(model, "SeatFrame", Vector3.new(3.6, 0.6, 3.2), cfBase * CFrame.new(0, 2.5, 0), cGold, Enum.Material.SmoothPlastic)
    local seat = makeSeat(model, "Seat", Vector3.new(3.2, 0.8, 2.8), cfBase * CFrame.new(0, 2.9, 0.1), cVelvet, Enum.Material.SmoothPlastic)
    model.PrimaryPart = seat

    local pl = Instance.new("PointLight")
    pl.Color = Color3.fromRGB(255, 210, 90)
    pl.Brightness = 2.5
    pl.Range = 16
    pl.Parent = seat

    makePart(model, "FrontDiamondFrame", Vector3.new(1.4, 1.4, 0.15), cfBase * CFrame.new(0, 2.5, -1.65) * CFrame.Angles(0, 0, math.rad(45)), cGold, Enum.Material.SmoothPlastic)
    makePart(model, "FrontRubyGem", Vector3.new(0.7, 0.7, 0.22), cfBase * CFrame.new(0, 2.5, -1.72) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

    for _, tag in { "Left", "Right" } do
        local ax = if tag == "Left" then -2.2 else 2.2
        makePart(model, "Armrest_" .. tag, Vector3.new(1.3, 1.4, 3.0), cfBase * CFrame.new(ax, 3.7, 0), cGold, Enum.Material.SmoothPlastic, true)
        makePart(model, "ArmrestPanel_" .. tag, Vector3.new(0.9, 1.0, 0.05), cfBase * CFrame.new(ax, 3.7, -1.53), cVelvet, Enum.Material.SmoothPlastic)
        makePart(model, "ArmrestGem_" .. tag, Vector3.new(0.35, 0.35, 0.08), cfBase * CFrame.new(ax, 3.7, -1.58) * CFrame.Angles(0, 0, math.rad(45)), cGold, Enum.Material.SmoothPlastic)
    end

    makePart(model, "BackrestFrame", Vector3.new(4.4, 6.2, 0.8), cfBase * CFrame.new(0, 6.0, 1.4), cGold, Enum.Material.SmoothPlastic, true)
    makePart(model, "WingSpike_Left", Vector3.new(1.2, 1.8, 0.6), cfBase * CFrame.new(-2.4, 8.8, 1.4) * CFrame.Angles(0, 0, math.rad(35)), cGold, Enum.Material.SmoothPlastic)
    makePart(model, "WingSpike_Right", Vector3.new(1.2, 1.8, 0.6), cfBase * CFrame.new( 2.4, 8.8, 1.4) * CFrame.Angles(0, 0, math.rad(-35)), cGold, Enum.Material.SmoothPlastic)

    makePart(model, "QuiltedPanel", Vector3.new(3.2, 4.8, 0.5), cfBase * CFrame.new(0, 5.6, 1.1), cVelvet, Enum.Material.SmoothPlastic)
    for row = 0, 2 do
        for col = 0, 2 do
            local bx = (col - 1) * 0.95
            local by = 4.4 + row * 1.15
            makePart(model, "TuftButton_" .. row .. "_" .. col, Vector3.new(0.35, 0.35, 0.35), cfBase * CFrame.new(bx, by, 0.82), cGold, Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
        end
    end

    makePart(model, "EmblemRing", Vector3.new(2.8, 2.8, 0.4), cfBase * CFrame.new(0, 7.6, 1.15) * CFrame.Angles(0, 0, math.rad(45)), cGold, Enum.Material.SmoothPlastic)
    makePart(model, "SoccerBall", Vector3.new(2.1, 2.1, 2.1), cfBase * CFrame.new(0, 7.6, 1.15), cWhite, Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
    makePart(model, "Pentagon_Center", Vector3.new(0.55, 0.55, 0.1), cfBase * CFrame.new(0, 7.6, 0.08) * CFrame.Angles(0, 0, math.rad(36)), cBlack, Enum.Material.SmoothPlastic)

    local crownPeaks = {
        { -1.2, 0.8, -18 },
        { -0.6, 1.2,  -9 },
        {  0.0, 1.7,   0 },
        {  0.6, 1.2,   9 },
        {  1.2, 0.8,  18 },
    }
    for idx, cfg in ipairs(crownPeaks) do
        local px, ph, prot = cfg[1], cfg[2], cfg[3]
        makePart(model, "CrownPeak_" .. idx, Vector3.new(0.55, ph, 0.45), cfBase * CFrame.new(px, 9.3 + ph * 0.4, 1.15) * CFrame.Angles(0, 0, math.rad(prot)), cGold, Enum.Material.SmoothPlastic)
    end
    makePart(model, "CrownRubyGem", Vector3.new(0.55, 0.55, 0.25), cfBase * CFrame.new(0, 9.9, 0.92) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

    for _, tag in { "Left", "Right" } do
        local bx = if tag == "Left" then -2.6 else 2.6
        makePart(model, "Banner_" .. tag, Vector3.new(0.7, 2.2, 0.08), cfBase * CFrame.new(bx, 6.2, 1.2), cVelvet, Enum.Material.SmoothPlastic)
        makePart(model, "BannerCrownEmblem_" .. tag, Vector3.new(0.4, 0.3, 0.04), cfBase * CFrame.new(bx, 6.6, 1.14), cGold, Enum.Material.Neon)
    end

    local spAtt = Instance.new("Attachment")
    spAtt.Parent = seat
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 180, 20))
    sparkles.LightEmission = 1
    sparkles.Size = NumberSequence.new(0.4, 0.08)
    sparkles.Lifetime = NumberRange.new(1.0, 2.5)
    sparkles.Rate = 10
    sparkles.Speed = NumberRange.new(0.6, 1.8)
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Parent = spAtt

    local scr = Instance.new("Script")
    scr.Source = [[
local TweenService = game:GetService("TweenService")
local model = script.Parent
local ruby = model:FindFirstChild("CrownRubyGem")
local frontRuby = model:FindFirstChild("FrontRubyGem")
local info = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
if ruby and ruby:IsA("BasePart") then
    TweenService:Create(ruby, info, { Color = Color3.fromRGB(255, 80, 100) }):Play()
end
if frontRuby and frontRuby:IsA("BasePart") then
    TweenService:Create(frontRuby, info, { Color = Color3.fromRGB(255, 80, 100) }):Play()
end
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- SPAWN ALL 4 CHAIRS SIDE-BY-SIDE
-- ============================================================================
print("✨ Spawning all 4 stylized chairs into Workspace...")
spawnCrimsonFlameChair(CFrame.new(-12, 0, 0))
spawnCyberCoreChair(CFrame.new(-4, 0, 0))
spawnFrostbiteThrone(CFrame.new(4, 0, 0))
spawnRoyalFootballThrone(CFrame.new(12, 0, 0))
print("✅ Successfully spawned all 4 chairs into Workspace.ExportedChairs_Showcase!")

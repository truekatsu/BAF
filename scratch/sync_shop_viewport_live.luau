
local s = game.StarterPlayer.StarterPlayerScripts.Client.ShopDailyUI
local source = s.Source

local oldTop = "local Players = game:GetService(\"Players\")\nlocal localPlayer = Players.LocalPlayer"
local newTop = "local Players = game:GetService(\"Players\")\nlocal UserInputService = game:GetService(\"UserInputService\")\nlocal localPlayer = Players.LocalPlayer"
local pIdx = string.find(source, oldTop, 1, true)
if pIdx then
    source = string.sub(source, 1, pIdx - 1) .. newTop .. string.sub(source, pIdx + #oldTop)
end

local startM = "local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame"
local endM = "local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame"

local i1 = string.find(source, startM, 1, true)
local i2 = string.find(source, endM, 1, true)

if not i1 or not i2 then
    return "Markers not found in Studio script! i1=" .. tostring(i1) .. ", i2=" .. tostring(i2)
end

local snippet = "local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame\n	local vp = Instance.new(\"ViewportFrame\")\n	vp.Name = \"ChairVP_\" .. skinId\n	vp.Size = UDim2.new(0.92, 0, 0.54, 0)\n	vp.Position = UDim2.new(0.04, 0, 0.17, 0)\n	vp.BackgroundTransparency = 1\n	vp.BorderSizePixel = 0\n	vp.ZIndex = parent.ZIndex + 2\n	vp.Active = true\n	vp.LightColor = Color3.fromRGB(255, 255, 255)\n	vp.Ambient = Color3.fromRGB(240, 240, 245)\n	vp.LightDirection = Vector3.new(-0.2, -0.4, -0.9)\n\n	local model = ChairModelBuilder.buildChair(skinId)\n	model.Parent = vp\n	model.PrimaryPart = nil\n\n	-- Exact bounding box center as pivot\n	local bbCF, bbSize = model:GetBoundingBox()\n	model.WorldPivot = CFrame.new(bbCF.Position)\n	local maxDim = math.max(bbSize.X, bbSize.Y, bbSize.Z)\n\n	-- Default orientation: golden throne FBX has inverted forward, others face +Z\n	local baseAngle = if skinId == \"golden\" or skinId == \"royal\" or skinId == \"football_throne\" or skinId == \"footballthrone\" or skinId == \"royalfootballthrone\" then math.pi else 0\n\n	local cam = Instance.new(\"Camera\")\n	cam.FieldOfView = 24\n	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.35\n	local camDir = Vector3.new(0.55, 0.32, 1.25).Unit\n	cam.CFrame = CFrame.lookAt(camDir * dist, Vector3.new(0, 0, 0))\n	cam.Parent = vp\n	vp.CurrentCamera = cam\n\n	-- Interactive turntable rotation (cursor drag + hold, mobile touch drag + hold)\n	local angle = 0\n	local isHeld = false\n	local isHovered = false\n	local lastDragX: number? = nil\n\n	local function updateModelCFrame()\n		model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, baseAngle + angle, 0))\n	end\n	updateModelCFrame()\n\n	vp.InputBegan:Connect(function(input)\n		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then\n			isHeld = true\n			lastDragX = input.Position.X\n		end\n	end)\n\n	vp.InputEnded:Connect(function(input)\n		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then\n			isHeld = false\n			lastDragX = nil\n		end\n	end)\n\n	vp.InputChanged:Connect(function(input)\n		if isHeld and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then\n			if lastDragX then\n				local deltaX = input.Position.X - lastDragX\n				angle += deltaX * 0.018\n				lastDragX = input.Position.X\n				updateModelCFrame()\n			end\n		end\n	end)\n\n	vp.MouseEnter:Connect(function()\n		isHovered = true\n	end)\n\n	vp.MouseLeave:Connect(function()\n		isHovered = false\n	end)\n\n	local globalEndConn: RBXScriptConnection?\n	globalEndConn = UserInputService.InputEnded:Connect(function(input)\n		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then\n			isHeld = false\n			lastDragX = nil\n		end\n	end)\n\n	local stepConn: RBXScriptConnection?\n	stepConn = RunService.RenderStepped:Connect(function(dt)\n		if not vp:IsDescendantOf(game) then return end\n		if isHeld then\n			angle += 2.2 * dt\n			updateModelCFrame()\n		elseif isHovered then\n			angle += 0.9 * dt\n			updateModelCFrame()\n		end\n	end)\n\n	vp.Destroying:Connect(function()\n		if stepConn then\n			stepConn:Disconnect()\n			stepConn = nil\n		end\n		if globalEndConn then\n			globalEndConn:Disconnect()\n			globalEndConn = nil\n		end\n	end)\n\n	vp.Parent = parent\n	return vp\nend\n\n"
source = string.sub(source, 1, i1 - 1) .. snippet .. string.sub(source, i2)
s.Source = source
return "Synced to Studio ShopDailyUI successfully! Total len: " .. #s.Source

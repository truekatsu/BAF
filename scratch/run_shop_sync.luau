
local s = game.StarterPlayer.StarterPlayerScripts.Client.ShopDailyUI
local source = s.Source

local p1 = "local TweenService = game:GetService(\"TweenService\")\nlocal Players = game:GetService(\"Players\")"
local r1 = "local TweenService = game:GetService(\"TweenService\")\nlocal RunService = game:GetService(\"RunService\")\nlocal ReplicatedStorage = game:GetService(\"ReplicatedStorage\")\nlocal Players = game:GetService(\"Players\")\nlocal ChairModelBuilder = require(ReplicatedStorage:WaitForChild(\"Prefabs\"):WaitForChild(\"ChairModelBuilder\"))"

local startM = "local function buildChairModel(skinId: string): Model"
local endM = "local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame"

local i1 = string.find(source, startM, 1, true)
local i2 = string.find(source, endM, 1, true)

if not i1 or not i2 then
    return "Markers not found! i1=" .. tostring(i1) .. ", i2=" .. tostring(i2)
end

local pIdx = string.find(source, p1, 1, true)
if pIdx then
    source = string.sub(source, 1, pIdx - 1) .. r1 .. string.sub(source, pIdx + #p1)
end

i1 = string.find(source, startM, 1, true)
i2 = string.find(source, endM, 1, true)

local newCode = "local function buildChairModel(skinId: string): Model\n	return ChairModelBuilder.buildChair(skinId)\nend\n\nlocal function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame\n	local vp = Instance.new(\"ViewportFrame\")\n	vp.Name = \"ChairVP_\" .. skinId\n	vp.Size = UDim2.new(0.88, 0, 0.50, 0)\n	vp.Position = UDim2.new(0.06, 0, 0.19, 0)\n	vp.BackgroundTransparency = 1\n	vp.BorderSizePixel = 0\n	vp.ZIndex = parent.ZIndex + 2\n	vp.Active = true\n	vp.LightColor = Color3.fromRGB(255, 255, 255)\n	vp.Ambient = Color3.fromRGB(220, 220, 230)\n	vp.LightDirection = Vector3.new(-0.35, -0.60, 0.72)\n\n	local model = ChairModelBuilder.buildChair(skinId)\n	model.Parent = vp\n\n	-- Center model at 0, 0, 0\n	local bbCF, bbSize = model:GetBoundingBox()\n	local center = bbCF.Position\n	model:PivotTo(model:GetPivot() - center)\n\n	local cam = Instance.new(\"Camera\")\n	cam.FieldOfView = 24\n	local maxDim = math.max(bbSize.X, bbSize.Y, bbSize.Z)\n	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.18\n	local camDir = Vector3.new(0.55, 0.40, 1.25).Unit\n	cam.CFrame = CFrame.lookAt(camDir * dist, Vector3.new(0, 0, 0))\n	cam.Parent = vp\n	vp.CurrentCamera = cam\n\n	-- Interactive turntable rotation (cursor drag + hold, mobile touch drag + hold)\n	local angle = 0\n	local isHeld = false\n	local isHovered = false\n	local lastX: number? = nil\n\n	vp.InputBegan:Connect(function(input)\n		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then\n			isHeld = true\n			lastX = input.Position.X\n		end\n	end)\n\n	vp.InputEnded:Connect(function(input)\n		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then\n			isHeld = false\n			lastX = nil\n		end\n	end)\n\n	vp.InputChanged:Connect(function(input)\n		if isHeld and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then\n			if lastX then\n				local deltaX = input.Position.X - lastX\n				angle += deltaX * 0.015\n				lastX = input.Position.X\n				model:PivotTo(CFrame.Angles(0, angle, 0))\n			end\n		end\n	end)\n\n	vp.MouseEnter:Connect(function()\n		isHovered = true\n	end)\n\n	vp.MouseLeave:Connect(function()\n		isHovered = false\n		isHeld = false\n		lastX = nil\n	end)\n\n	local stepConn: RBXScriptConnection?\n	stepConn = RunService.RenderStepped:Connect(function(dt)\n		if not vp:IsDescendantOf(game) then return end\n		if isHeld then\n			angle += 2.0 * dt\n			model:PivotTo(CFrame.Angles(0, angle, 0))\n		elseif isHovered then\n			angle += 0.8 * dt\n			model:PivotTo(CFrame.Angles(0, angle, 0))\n		end\n	end)\n\n	vp.Destroying:Connect(function()\n		if stepConn then\n			stepConn:Disconnect()\n			stepConn = nil\n		end\n	end)\n\n	vp.Parent = parent\n	return vp\nend\n"
source = string.sub(source, 1, i1 - 1) .. newCode .. "\n" .. string.sub(source, i2)
s.Source = source
return "Success! ShopDailyUI updated, new length: " .. #s.Source

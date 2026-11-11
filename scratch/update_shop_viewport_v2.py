with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    content = f.read()

# Add UserInputService to top if not present at top
top_marker = 'local Players = game:GetService("Players")\nlocal localPlayer = Players.LocalPlayer'
new_top = 'local Players = game:GetService("Players")\nlocal UserInputService = game:GetService("UserInputService")\nlocal localPlayer = Players.LocalPlayer'

if 'local UserInputService = game:GetService("UserInputService")\nlocal localPlayer' not in content:
    assert top_marker in content, "top_marker not found"
    content = content.replace(top_marker, new_top, 1)

# Replace createChairViewport
start_marker = 'local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame'
end_marker = 'local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame'

idx1 = content.find(start_marker)
idx2 = content.find(end_marker)

assert idx1 != -1, "start_marker not found"
assert idx2 != -1, "end_marker not found"

new_viewport_func = '''local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = "ChairVP_" .. skinId
	vp.Size = UDim2.new(0.92, 0, 0.54, 0)
	vp.Position = UDim2.new(0.04, 0, 0.17, 0)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.ZIndex = parent.ZIndex + 2
	vp.Active = true
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.Ambient = Color3.fromRGB(240, 240, 245)
	vp.LightDirection = Vector3.new(-0.2, -0.4, -0.9)

	local model = ChairModelBuilder.buildChair(skinId)
	model.Parent = vp
	model.PrimaryPart = nil

	-- Exact bounding box center as pivot
	local bbCF, bbSize = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(bbCF.Position)
	local maxDim = math.max(bbSize.X, bbSize.Y, bbSize.Z)

	-- Default orientation: golden throne FBX has inverted forward, others face +Z
	local baseAngle = if skinId == "golden" or skinId == "royal" or skinId == "football_throne" or skinId == "footballthrone" or skinId == "royalfootballthrone" then math.pi else 0

	local cam = Instance.new("Camera")
	cam.FieldOfView = 24
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.35
	local camDir = Vector3.new(0.55, 0.32, 1.25).Unit
	cam.CFrame = CFrame.lookAt(camDir * dist, Vector3.new(0, 0, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam

	-- Interactive turntable rotation (cursor drag + hold, mobile touch drag + hold)
	local angle = 0
	local isHeld = false
	local isHovered = false
	local lastDragX: number? = nil

	local function updateModelCFrame()
		model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, baseAngle + angle, 0))
	end
	updateModelCFrame()

	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = true
			lastDragX = input.Position.X
		end
	end)

	vp.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = false
			lastDragX = nil
		end
	end)

	vp.InputChanged:Connect(function(input)
		if isHeld and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if lastDragX then
				local deltaX = input.Position.X - lastDragX
				angle += deltaX * 0.018
				lastDragX = input.Position.X
				updateModelCFrame()
			end
		end
	end)

	vp.MouseEnter:Connect(function()
		isHovered = true
	end)

	vp.MouseLeave:Connect(function()
		isHovered = false
	end)

	local globalEndConn: RBXScriptConnection?
	globalEndConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = false
			lastDragX = nil
		end
	end)

	local stepConn: RBXScriptConnection?
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if not vp:IsDescendantOf(game) then return end
		if isHeld then
			angle += 2.2 * dt
			updateModelCFrame()
		elseif isHovered then
			angle += 0.9 * dt
			updateModelCFrame()
		end
	end)

	vp.Destroying:Connect(function()
		if stepConn then
			stepConn:Disconnect()
			stepConn = nil
		end
		if globalEndConn then
			globalEndConn:Disconnect()
			globalEndConn = nil
		end
	end)

	vp.Parent = parent
	return vp
end

'''

content = content[:idx1] + new_viewport_func + content[idx2:]

with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated ShopDailyUI.luau successfully!")

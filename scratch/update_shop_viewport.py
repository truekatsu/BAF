with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = 'local function buildChairModel(skinId: string): Model'
end_marker = 'local function createMiniChairModel(chairColor: Color3, mat: Enum.Material, parent: GuiObject, skinId: string?): ViewportFrame'

idx1 = content.find(start_marker)
idx2 = content.find(end_marker)

assert idx1 != -1, 'start_marker not found'
assert idx2 != -1, 'end_marker not found'

new_code = '''local function buildChairModel(skinId: string): Model
	return ChairModelBuilder.buildChair(skinId)
end

local function createChairViewport(skinId: string, parent: GuiObject): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = "ChairVP_" .. skinId
	vp.Size = UDim2.new(0.88, 0, 0.50, 0)
	vp.Position = UDim2.new(0.06, 0, 0.19, 0)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.ZIndex = parent.ZIndex + 2
	vp.Active = true
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.Ambient = Color3.fromRGB(220, 220, 230)
	vp.LightDirection = Vector3.new(-0.35, -0.60, 0.72)

	local model = ChairModelBuilder.buildChair(skinId)
	model.Parent = vp

	-- Center model at 0, 0, 0
	local bbCF, bbSize = model:GetBoundingBox()
	local center = bbCF.Position
	model:PivotTo(model:GetPivot() - center)

	local cam = Instance.new("Camera")
	cam.FieldOfView = 24
	local maxDim = math.max(bbSize.X, bbSize.Y, bbSize.Z)
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.18
	local camDir = Vector3.new(0.55, 0.40, 1.25).Unit
	cam.CFrame = CFrame.lookAt(camDir * dist, Vector3.new(0, 0, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam

	-- Interactive turntable rotation (cursor drag + hold, mobile touch drag + hold)
	local angle = 0
	local isHeld = false
	local isHovered = false
	local lastX: number? = nil

	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = true
			lastX = input.Position.X
		end
	end)

	vp.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isHeld = false
			lastX = nil
		end
	end)

	vp.InputChanged:Connect(function(input)
		if isHeld and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			if lastX then
				local deltaX = input.Position.X - lastX
				angle += deltaX * 0.015
				lastX = input.Position.X
				model:PivotTo(CFrame.Angles(0, angle, 0))
			end
		end
	end)

	vp.MouseEnter:Connect(function()
		isHovered = true
	end)

	vp.MouseLeave:Connect(function()
		isHovered = false
		isHeld = false
		lastX = nil
	end)

	local stepConn: RBXScriptConnection?
	stepConn = RunService.RenderStepped:Connect(function(dt)
		if not vp:IsDescendantOf(game) then return end
		if isHeld then
			angle += 2.0 * dt
			model:PivotTo(CFrame.Angles(0, angle, 0))
		elseif isHovered then
			angle += 0.8 * dt
			model:PivotTo(CFrame.Angles(0, angle, 0))
		end
	end)

	vp.Destroying:Connect(function()
		if stepConn then
			stepConn:Disconnect()
			stepConn = nil
		end
	end)

	vp.Parent = parent
	return vp
end

'''

new_content = content[:idx1] + new_code + content[idx2:]
with open('src/StarterPlayer/StarterPlayerScripts/Client/ShopDailyUI.luau', 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Successfully updated ShopDailyUI.luau!')

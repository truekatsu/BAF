import json

with open(r'C:/Users/Lenovo/.gemini/antigravity/brain/ef743658-a1fd-403d-8a26-9b3463ba3cde/.system_generated/steps/2092/output.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

content_lines = []
for l in lines:
    parts = l.split('→', 1)
    if len(parts) == 2:
        content_lines.append(parts[1])
    else:
        content_lines.append(l)

old_str = ''.join(content_lines)

new_str = '''local function buildChairModel(skinId: string): Model
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

if old_str.endswith('\n') and not new_str.endswith('\n'):
    new_str += '\n'

args = {
    'studio_id': '649a33bb-29a0-415b-a167-51eaf7f9f85f',
    'datamodel_type': 'Edit',
    'file_path': 'game.StarterPlayer.StarterPlayerScripts.Client.ShopDailyUI',
    'edits': [
        {
            'old_string': 'local TweenService = game:GetService("TweenService")\nlocal Players = game:GetService("Players")',
            'new_string': 'local TweenService = game:GetService("TweenService")\nlocal RunService = game:GetService("RunService")\nlocal ReplicatedStorage = game:GetService("ReplicatedStorage")\nlocal Players = game:GetService("Players")\nlocal ChairModelBuilder = require(ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("ChairModelBuilder"))'
        },
        {
            'old_string': old_str,
            'new_string': new_str
        }
    ]
}

with open('scratch/shop_multi_edit_args.json', 'w', encoding='utf-8') as out:
    json.dump(args, out)

print('Generated scratch/shop_multi_edit_args.json successfully! Old str len:', len(old_str), 'New str len:', len(new_str))

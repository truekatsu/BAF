--!strict
--[[
	TableRigBuilder
	Responsibility: Constructs the standardized TableRig prefab with wooden table (10x3x4 L x H x W),
	opposing chairs on the short sides (SeatA at +Z, SeatB at -Z), CameraAnchorA/B,
	lantern post beside the table, and BillboardAnchor attachment.
	LookVector (-Z) points from SeatA to SeatB.
	Location: ReplicatedStorage/Prefabs/TableRigBuilder.luau
]]

local TableRigBuilder = {}

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material,
	canCollide: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Anchored = true
	p.CanCollide = canCollide == true
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

function TableRigBuilder.buildPrefab(): Model
	local rig = Instance.new("Model")
	rig.Name = "TableRig"

	local woodCol = Color3.fromHex("#8B5A2B")
	local darkWood = Color3.fromHex("#5C3A1E")
	local chairCol = Color3.fromHex("#7A4B24")

	-- 1. Table Top: 4 x 0.5 x 10 studs (L=10 in Z, W=4 in X, H=3 to ground)
	local tableTop = makePart(rig, "TableTop", Vector3.new(4.0, 0.5, 10.0), CFrame.new(0, 2.75, 0), woodCol, Enum.Material.Wood, true)
	rig.PrimaryPart = tableTop

	-- Attachment BillboardAnchor (7 studs above table centre)
	local bbAnchor = Instance.new("Attachment")
	bbAnchor.Name = "BillboardAnchor"
	bbAnchor.Position = Vector3.new(0, 7.0, 0)
	bbAnchor.Parent = tableTop

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "TableStatusBillboard"
	bbg.Adornee = bbAnchor
	bbg.Size = UDim2.fromScale(10.0, 5.0)
	bbg.AlwaysOnTop = false
	bbg.MaxDistance = 90.0
	bbg.LightInfluence = 0.0

	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.Parent = bbg

	local idleView = Instance.new("Frame")
	idleView.Name = "IdleView"
	idleView.Size = UDim2.fromScale(1, 1)
	idleView.BackgroundTransparency = 1
	idleView.Parent = canvas

	local idleLayout = Instance.new("UIListLayout")
	idleLayout.SortOrder = Enum.SortOrder.LayoutOrder
	idleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	idleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	idleLayout.Padding = UDim.new(0, 1)
	idleLayout.Parent = idleView

	local function addStroke(parent: Instance, col: Color3, thick: number)
		local s = Instance.new("UIStroke")
		s.Color = col
		s.Thickness = thick
		s.Parent = parent
	end

	local defaultModeLbl = Instance.new("TextLabel")
	defaultModeLbl.Name = "DefaultModeLabel"
	defaultModeLbl.LayoutOrder = 1
	defaultModeLbl.Size = UDim2.new(1, 0, 0.20, 0)
	defaultModeLbl.BackgroundTransparency = 1
	defaultModeLbl.Font = Enum.Font.FredokaOne
	defaultModeLbl.Text = "Default Mode"
	defaultModeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	defaultModeLbl.TextScaled = true
	addStroke(defaultModeLbl, Color3.fromRGB(0, 0, 0), 4)
	defaultModeLbl.Parent = idleView

	local occLbl = Instance.new("TextLabel")
	occLbl.Name = "OccupancyLabel"
	occLbl.LayoutOrder = 2
	occLbl.Size = UDim2.new(1, 0, 0.28, 0)
	occLbl.BackgroundTransparency = 1
	occLbl.Font = Enum.Font.FredokaOne
	occLbl.Text = "0/2"
	occLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	occLbl.TextScaled = true
	addStroke(occLbl, Color3.fromRGB(0, 0, 0), 3.5)
	occLbl.Parent = idleView

	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name = "PriceLabel"
	priceLbl.LayoutOrder = 3
	priceLbl.Size = UDim2.new(1, 0, 0.24, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font = Enum.Font.FredokaOne
	priceLbl.Text = "$100"
	priceLbl.TextColor3 = Color3.fromHex("#3DDC3D")
	priceLbl.TextScaled = true
	addStroke(priceLbl, Color3.fromRGB(0, 0, 0), 4)
	priceLbl.Parent = idleView

	bbg.Parent = tableTop

	-- 4 Table Legs
	for _, off in {
		Vector3.new(-1.6, 1.25, -4.4),
		Vector3.new(1.6, 1.25, -4.4),
		Vector3.new(-1.6, 1.25, 4.4),
		Vector3.new(1.6, 1.25, 4.4),
	} do
		makePart(rig, "TableLeg", Vector3.new(0.5, 2.5, 0.5), CFrame.new(off), darkWood, Enum.Material.Wood, true)
	end

	-- 2. Chairs on the SHORT sides (facing each other along Z axis)
	-- Short sides are at Z = +5.0 and Z = -5.0 (width 4.0 in X)
	-- SeatA at +Z facing -Z (towards SeatB)
	-- SeatB at -Z facing +Z (towards SeatA)
	local function buildChair(side: "A" | "B", zPos: number, facingDir: number): Seat
		local seat = Instance.new("Seat")
		seat.Name = "Seat" .. side
		seat.Size = Vector3.new(2.2, 0.4, 2.2)
		local lookTarget = Vector3.new(0, 1.6, zPos + facingDir * 5)
		seat.CFrame = CFrame.lookAt(Vector3.new(0, 1.6, zPos), lookTarget)
		seat.Color = chairCol
		seat.Material = Enum.Material.Wood
		seat.Anchored = true
		seat.CanCollide = false
		seat.Disabled = false
		seat:SetAttribute("SeatSide", side)
		seat:SetAttribute("TableId", 0)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SitPrompt"
		prompt.ActionText = "Duduk & Main"
		prompt.ObjectText = "Meja Pertandingan"
		prompt.MaxActivationDistance = 9
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = seat
		seat.Parent = rig

		-- Chair back
		local backZ = zPos - (facingDir * 0.95)
		makePart(rig, `Seat{side}_Back`, Vector3.new(2.2, 2.2, 0.3), CFrame.new(0, 2.7, backZ), darkWood, Enum.Material.Wood, true)

		-- Chair legs
		for _, xOff in { -0.85, 0.85 } do
			for _, zOffset in { -0.85, 0.85 } do
				makePart(rig, `Seat{side}_Leg`, Vector3.new(0.3, 1.4, 0.3), CFrame.new(xOff, 0.7, zPos + zOffset), darkWood, Enum.Material.Wood, false)
			end
		end

		return seat
	end

	-- SeatA at Z = +6.2 (facing -Z towards table edge at Z = +5.0)
	local seatA = buildChair("A", 6.2, -1)
	-- SeatB at Z = -6.2 (facing +Z towards table edge at Z = -5.0)
	local seatB = buildChair("B", -6.2, 1)

	-- 3. Camera Anchors
	-- CameraAnchorA: behind seat A (2 studs above head height, looking at SeatB)
	local camPosA = Vector3.new(0, 5.5, 9.8)
	local lookTargetA = seatB.Position + Vector3.new(0, 1.5, 0)
	local camAnchorA = makePart(rig, "CameraAnchorA", Vector3.new(0.5, 0.5, 0.5), CFrame.lookAt(camPosA, lookTargetA), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, false)
	camAnchorA.Transparency = 1

	-- CameraAnchorB: behind seat B (mirror of A)
	local camPosB = Vector3.new(0, 5.5, -9.8)
	local lookTargetB = seatA.Position + Vector3.new(0, 1.5, 0)
	local camAnchorB = makePart(rig, "CameraAnchorB", Vector3.new(0.5, 0.5, 0.5), CFrame.lookAt(camPosB, lookTargetB), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, false)
	camAnchorB.Transparency = 1

	-- 4. Lantern Post (decor beside the table at corner X = -2.4, Z = -4.2)
	makePart(rig, "LanternPost", Vector3.new(0.4, 4.5, 0.4), CFrame.new(-2.4, 2.25, -4.2), darkWood, Enum.Material.Wood, false)
	makePart(rig, "LanternFrame", Vector3.new(1.0, 1.2, 1.0), CFrame.new(-2.4, 4.8, -4.2), Color3.fromRGB(45, 45, 50), Enum.Material.Metal, false)
	local lanternCore = makePart(rig, "LanternCore", Vector3.new(0.65, 0.85, 0.65), CFrame.new(-2.4, 4.8, -4.2), Color3.fromHex("#FFEAA7"), Enum.Material.Neon, false)
	local lanternLight = Instance.new("PointLight")
	lanternLight.Name = "LanternLight"
	lanternLight.Brightness = 0.8
	lanternLight.Range = 12
	lanternLight.Color = Color3.fromHex("#FFE599")
	lanternLight.Parent = lanternCore

	-- 5. Welds: weld all BaseParts to TableTop
	for _, desc in rig:GetDescendants() do
		if desc:IsA("BasePart") and desc ~= tableTop then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = tableTop
			weld.Part1 = desc
			weld.Parent = tableTop
		end
	end

	-- Table attributes
	rig:SetAttribute("TableId", 0)
	rig:SetAttribute("Mode", "Default")

	return rig
end

return TableRigBuilder

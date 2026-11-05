--!strict
--[[
	CenterHubService (Server)
	Responsibility: Builds and maintains the Center Circle Hub (markings, 2-tier gold podium,
	rotating pedestal, Rank #1 statue slot, Streak King billboard, spotlight, and sparkle emitter).
	Loop step: progression | social display | retention
	Location: ServerScriptService/Server/CenterHubService.server.luau
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CenterHubConfig"))

--[[
	HOW TO MOVE / RESIZE:
	Edit 'CenterHubConfig.luau' in ReplicatedStorage/Shared.
	- Adjust 'PITCH_CENTER' to relocate the entire hub.
	- Adjust 'TIER_1' and 'TIER_2' tables for podium radius and height.
	- Adjust 'WALKWAY_BYPASS_WIDTH' to adjust walking clearance around the podium.
]]

local winsStore: OrderedDataStore? = nil
local streakStore: OrderedDataStore? = nil
pcall(function()
	winsStore = DataStoreService:GetOrderedDataStore(Config.LeaderboardWinsStoreName)
	streakStore = DataStoreService:GetOrderedDataStore(Config.LeaderboardStreakStoreName)
end)

local currentStatueUserId: number? = nil
local userNameCache: { [number]: string } = {}

-- Utility: Create anchored, collision-free prop part
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

-- Utility: Create cylinder oriented vertically
local function makeVerticalCylinder(
	parent: Instance,
	name: string,
	diameter: number,
	height: number,
	centerPos: Vector3,
	color: Color3,
	mat: Enum.Material,
	canCollide: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, 0, math.rad(90))
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

-- Resolve user name safely with cache
local function resolveUserName(userId: number): string
	if userId <= 0 then
		return "Champion"
	end
	if userNameCache[userId] then
		return userNameCache[userId]
	end
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		userNameCache[userId] = plr.DisplayName
		return plr.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = if ok and typeof(name) == "string" and #name > 0 then name else `Player_{userId}`
	userNameCache[userId] = resolved
	return resolved
end

-- Build the static geometry of CenterHub
local function buildCenterHubGeometry(): (Folder, Model, Part)
	local lobby = Workspace:WaitForChild("Lobby", 10) or Workspace
	local existing = lobby:FindFirstChild("CenterHub") or lobby:FindFirstChild("Hub")
	if existing then
		existing:Destroy()
	end

	local hub = Instance.new("Folder")
	hub.Name = "Hub"

	local center = Config.PITCH_CENTER

	----------------------------------------------------------------------
	-- 1. PITCH MARKINGS (<= 6 parts budget)
	----------------------------------------------------------------------
	local markings = Instance.new("Model")
	markings.Name = "Markings"

	-- White Halfway Line (1.2 studs wide across pitch)
	makePart(
		markings,
		"HalfwayLine",
		Vector3.new(Config.HALFWAY_LINE_WIDTH, 0.08, Config.HALFWAY_LINE_LENGTH),
		CFrame.new(center.X, 0.14, center.Z),
		Color3.fromRGB(250, 250, 250),
		Enum.Material.SmoothPlastic,
		false
	)

	-- Center Circle (outer diameter 60 studs with ring decal placeholder)
	local circlePart = makePart(
		markings,
		"CenterCircle",
		Vector3.new(Config.CENTER_CIRCLE_DIAMETER, 0.08, Config.CENTER_CIRCLE_DIAMETER),
		CFrame.new(center.X, 0.13, center.Z),
		Color3.fromRGB(250, 250, 250),
		Enum.Material.SmoothPlastic,
		false
	)
	circlePart.Transparency = 1
	local ringDecal = Instance.new("Decal")
	ringDecal.Name = "DEC_CenterCircleRing"
	ringDecal.Face = Enum.NormalId.Top
	ringDecal.Texture = "rbxassetid://0"
	ringDecal.Parent = circlePart

	-- 4 Thin Visual Ring Segments for in-studio visibility without textures
	local r = Config.CENTER_CIRCLE_DIAMETER / 2
	local t = Config.CENTER_CIRCLE_THICKNESS
	makePart(markings, "RingSegment_N", Vector3.new(t * 12, 0.08, t), CFrame.new(center.X, 0.14, center.Z - r), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, false)
	makePart(markings, "RingSegment_S", Vector3.new(t * 12, 0.08, t), CFrame.new(center.X, 0.14, center.Z + r), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, false)
	makePart(markings, "RingSegment_W", Vector3.new(t, 0.08, t * 12), CFrame.new(center.X - r, 0.14, center.Z), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, false)
	makePart(markings, "RingSegment_E", Vector3.new(t, 0.08, t * 12), CFrame.new(center.X + r, 0.14, center.Z), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, false)

	-- Center Spot (3 studs diameter)
	makeVerticalCylinder(
		markings,
		"CenterSpot",
		Config.CENTER_SPOT_DIAMETER,
		0.1,
		Vector3.new(center.X, 0.15, center.Z),
		Color3.fromRGB(250, 250, 250),
		Enum.Material.SmoothPlastic,
		false
	)
	markings.Parent = hub

	----------------------------------------------------------------------
	-- 2. WALKWAY BYPASS APRONS (>= 20 studs clear passage around podium)
	----------------------------------------------------------------------
	local bypass = Instance.new("Model")
	bypass.Name = "WalkwayBypass"
	local walkwayCol = Color3.fromRGB(152, 158, 168)
	local curbCol = Color3.fromRGB(108, 114, 124)

	-- West bypass apron
	makePart(bypass, "BypassWest", Vector3.new(Config.WALKWAY_BYPASS_WIDTH, 0.25, 28), CFrame.new(center.X - 17, 0.12, center.Z), walkwayCol, Enum.Material.Concrete, true)
	makePart(bypass, "BypassCurbW", Vector3.new(0.8, 0.4, 28), CFrame.new(center.X - 22.4, 0.2, center.Z), curbCol, Enum.Material.Concrete, true)

	-- East bypass apron
	makePart(bypass, "BypassEast", Vector3.new(Config.WALKWAY_BYPASS_WIDTH, 0.25, 28), CFrame.new(center.X + 17, 0.12, center.Z), walkwayCol, Enum.Material.Concrete, true)
	makePart(bypass, "BypassCurbE", Vector3.new(0.8, 0.4, 28), CFrame.new(center.X + 22.4, 0.2, center.Z), curbCol, Enum.Material.Concrete, true)
	bypass.Parent = hub

	----------------------------------------------------------------------
	-- 3. 2-TIER GOLD PODIUM
	----------------------------------------------------------------------
	local podium = Instance.new("Model")
	podium.Name = "Podium"

	local baseElevation = 0.25

	-- Tier 1: Radius 12, Height 2
	local t1 = Config.TIER_1
	local t1CenterY = baseElevation + (t1.Height / 2)
	makeVerticalCylinder(podium, "Tier1_Base", t1.Radius * 2, t1.Height, Vector3.new(center.X, t1CenterY, center.Z), t1.Color, Enum.Material.SmoothPlastic, true)
	-- Tier 1 thin black rims
	makeVerticalCylinder(podium, "Tier1_BottomRim", (t1.Radius * 2) + 0.3, 0.15, Vector3.new(center.X, baseElevation + 0.08, center.Z), t1.RimColor, Enum.Material.SmoothPlastic, false)
	makeVerticalCylinder(podium, "Tier1_TopRim", (t1.Radius * 2) + 0.2, 0.15, Vector3.new(center.X, baseElevation + t1.Height - 0.08, center.Z), t1.RimColor, Enum.Material.SmoothPlastic, false)

	-- Tier 2: Radius 7, Height 4
	local t2 = Config.TIER_2
	local t2BaseY = baseElevation + t1.Height
	local t2CenterY = t2BaseY + (t2.Height / 2)
	makeVerticalCylinder(podium, "Tier2_Base", t2.Radius * 2, t2.Height, Vector3.new(center.X, t2CenterY, center.Z), t2.Color, Enum.Material.SmoothPlastic, true)
	-- Tier 2 thin black rims
	makeVerticalCylinder(podium, "Tier2_BottomRim", (t2.Radius * 2) + 0.25, 0.15, Vector3.new(center.X, t2BaseY + 0.08, center.Z), t2.RimColor, Enum.Material.SmoothPlastic, false)
	makeVerticalCylinder(podium, "Tier2_TopRim", (t2.Radius * 2) + 0.2, 0.15, Vector3.new(center.X, t2BaseY + t2.Height - 0.08, center.Z), t2.RimColor, Enum.Material.SmoothPlastic, false)

	podium.Parent = hub

	----------------------------------------------------------------------
	-- 4. ROTATING PEDESTAL & LIGHTING
	----------------------------------------------------------------------
	local ped = Config.PEDESTAL
	local pedBaseY = t2BaseY + t2.Height
	local pedCenterY = pedBaseY + (ped.Height / 2)

	local rotatingPedestal = Instance.new("Model")
	rotatingPedestal.Name = "RotatingPedestal"

	local pedestalBase = makeVerticalCylinder(
		rotatingPedestal,
		"PedestalBase",
		ped.Radius * 2,
		ped.Height,
		Vector3.new(center.X, pedCenterY, center.Z),
		ped.Color,
		Enum.Material.SmoothPlastic,
		true
	)
	makeVerticalCylinder(
		rotatingPedestal,
		"PedestalRim",
		(ped.Radius * 2) + 0.2,
		0.12,
		Vector3.new(center.X, pedCenterY, center.Z),
		ped.RimColor,
		Enum.Material.SmoothPlastic,
		false
	)
	rotatingPedestal.PrimaryPart = pedestalBase

	-- Subtle SpotLight aimed upward at the statue
	local spotLight = Instance.new("SpotLight")
	spotLight.Name = "StatueSpotLight"
	spotLight.Brightness = Config.LIGHTING.Brightness
	spotLight.Angle = Config.LIGHTING.Angle
	spotLight.Range = Config.LIGHTING.Range
	spotLight.Color = Config.LIGHTING.Color
	spotLight.Face = Enum.NormalId.Top
	spotLight.Parent = pedestalBase

	-- Gold sparkles particle emitter
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "GoldSparkles"
	sparkles.Rate = Config.PARTICLES.Rate
	sparkles.Lifetime = NumberRange.new(1.8, 2.6)
	sparkles.Speed = NumberRange.new(1.2, 2.8)
	sparkles.SpreadAngle = Vector2.new(35, 35)
	sparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#FFE885")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#F5B800")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#D48800")),
	})
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Texture = Config.PARTICLES.Texture
	sparkles.LightEmission = 0.8
	sparkles.Parent = pedestalBase

	rotatingPedestal.Parent = hub
	hub.Parent = lobby

	return hub, rotatingPedestal, pedestalBase
end

-- Create the BillboardGui above the statue
local function createStreakBillboard(adornee: BasePart, playerName: string, streakCount: number): BillboardGui
	local existing = adornee:FindFirstChild("StreakKingBillboard")
	if existing then
		existing:Destroy()
	end

	local bbg = Instance.new("BillboardGui")
	bbg.Name = "StreakKingBillboard"
	bbg.Adornee = adornee
	bbg.Size = UDim2.new(Config.BILLBOARD.Size.X, 0, Config.BILLBOARD.Size.Y, 0)
	bbg.StudsOffset = Config.BILLBOARD.StudsOffset
	bbg.MaxDistance = Config.BILLBOARD.MaxDistance
	bbg.AlwaysOnTop = true

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = bbg

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 2)
	layout.Parent = container

	-- Line 1: STREAK KING (Gold)
	local line1 = Instance.new("TextLabel")
	line1.Name = "TitleLabel"
	line1.LayoutOrder = 1
	line1.Size = UDim2.new(1, 0, 0.34, 0)
	line1.BackgroundTransparency = 1
	line1.Font = Enum.Font.FredokaOne
	line1.Text = "👑 STREAK KING"
	line1.TextColor3 = Color3.fromHex("#FFD700")
	line1.TextScaled = true
	local stroke1 = Instance.new("UIStroke")
	stroke1.Thickness = Config.BILLBOARD.StrokeThickness
	stroke1.Color = Color3.fromRGB(0, 0, 0)
	stroke1.Parent = line1
	line1.Parent = container

	-- Line 2: Player's Name (White)
	local line2 = Instance.new("TextLabel")
	line2.Name = "PlayerNameLabel"
	line2.LayoutOrder = 2
	line2.Size = UDim2.new(1, 0, 0.36, 0)
	line2.BackgroundTransparency = 1
	line2.Font = Enum.Font.FredokaOne
	line2.Text = playerName
	line2.TextColor3 = Color3.fromRGB(255, 255, 255)
	line2.TextScaled = true
	local stroke2 = Instance.new("UIStroke")
	stroke2.Thickness = Config.BILLBOARD.StrokeThickness
	stroke2.Color = Color3.fromRGB(0, 0, 0)
	stroke2.Parent = line2
	line2.Parent = container

	-- Line 3: <N> WIN STREAK (Orange/Gold)
	local line3 = Instance.new("TextLabel")
	line3.Name = "StreakCountLabel"
	line3.LayoutOrder = 3
	line3.Size = UDim2.new(1, 0, 0.30, 0)
	line3.BackgroundTransparency = 1
	line3.Font = Enum.Font.FredokaOne
	line3.Text = `{streakCount} WIN STREAK`
	line3.TextColor3 = Color3.fromHex("#FFA500")
	line3.TextScaled = true
	local stroke3 = Instance.new("UIStroke")
	stroke3.Thickness = Config.BILLBOARD.StrokeThickness
	stroke3.Color = Color3.fromRGB(0, 0, 0)
	stroke3.Parent = line3
	line3.Parent = container

	bbg.Parent = adornee
	return bbg
end

-- Build fallback gold "?" statue when DataStore is empty or offline
local function buildFallbackStatue(standCF: CFrame): Model
	local statue = Instance.new("Model")
	statue.Name = "Rank1Statue"

	local goldCol = Color3.fromHex("#F5B800")
	local darkGold = Color3.fromHex("#B58000")
	local mat = Enum.Material.SmoothPlastic

	-- Golden Blocky Torso & Head
	local root = makePart(statue, "HumanoidRootPart", Vector3.new(2, 2, 1), standCF * CFrame.new(0, 3, 0), goldCol, mat, false)
	local head = makePart(statue, "Head", Vector3.new(1.25, 1.25, 1.25), standCF * CFrame.new(0, 4.6, 0), goldCol, mat, false)
	makePart(statue, "LeftArm", Vector3.new(1, 2, 1), standCF * CFrame.new(-1.5, 3, 0), goldCol, mat, false)
	makePart(statue, "RightArm", Vector3.new(1, 2, 1), standCF * CFrame.new(1.5, 3.5, 0) * CFrame.Angles(0, 0, math.rad(-25)), goldCol, mat, false)
	makePart(statue, "LeftLeg", Vector3.new(1, 2, 1), standCF * CFrame.new(-0.55, 1, 0), goldCol, mat, false)
	makePart(statue, "RightLeg", Vector3.new(1, 2, 1), standCF * CFrame.new(0.55, 1, 0), goldCol, mat, false)

	-- 3D Gold "?" Block Question Symbol
	local qMark = makePart(statue, "QuestionMarkSymbol", Vector3.new(1.8, 2.2, 0.4), standCF * CFrame.new(0, 6.2, 0), darkGold, mat, false)
	local qGui = Instance.new("SurfaceGui")
	qGui.Face = Enum.NormalId.Front
	local qLbl = Instance.new("TextLabel")
	qLbl.Size = UDim2.fromScale(1, 1)
	qLbl.BackgroundTransparency = 1
	qLbl.Font = Enum.Font.FredokaOne
	qLbl.Text = "?"
	qLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	qLbl.TextScaled = true
	local qStroke = Instance.new("UIStroke")
	qStroke.Thickness = 4
	qStroke.Color = Color3.fromRGB(0, 0, 0)
	qStroke.Parent = qLbl
	qLbl.Parent = qGui
	qGui.Parent = qMark

	statue.PrimaryPart = root
	createStreakBillboard(head, "Nobody Yet", 0)
	return statue
end

-- Refresh the Rank 1 Statue with the top player
local function updateRank1Statue(pedestal: Model, pedestalBase: Part)
	-- Read Rank #1 from TOP WINS DataStore
	local topWinsUserId: number? = nil
	local topStreakUserId: number? = nil
	local topStreakVal = 0

	if winsStore then
		local ok, pages = pcall(function()
			return winsStore:GetSortedAsync(false, 1)
		end)
		if ok and pages then
			local pageOk, page = pcall(function()
				return pages:GetCurrentPage()
			end)
			if pageOk and typeof(page) == "table" and page[1] then
				local uid = tonumber(page[1].key)
				if uid and uid > 0 then
					topWinsUserId = uid
				end
			end
		end
	end

	-- Read Rank #1 Streak & Player
	if streakStore then
		local ok, pages = pcall(function()
			return streakStore:GetSortedAsync(false, 1)
		end)
		if ok and pages then
			local pageOk, page = pcall(function()
				return pages:GetCurrentPage()
			end)
			if pageOk and typeof(page) == "table" and page[1] then
				local uid = tonumber(page[1].key)
				local val = tonumber(page[1].value) or 0
				if uid and uid > 0 then
					topStreakUserId = uid
					topStreakVal = val
				end
			end
		end
	end

	local targetUserId = topWinsUserId or topStreakUserId
	local streakDisplayUser = topStreakUserId or targetUserId
	local playerName = if streakDisplayUser then resolveUserName(streakDisplayUser) else "Nobody Yet"

	local standPos = pedestalBase.Position + Vector3.new(0, Config.PEDESTAL.Height / 2, 0)
	local standCF = CFrame.lookAt(standPos, standPos + Vector3.new(0, 0, 1))

	-- Clean up existing statue
	local oldStatue = pedestal:FindFirstChild("Rank1Statue")

	if not targetUserId or targetUserId <= 0 then
		if oldStatue and currentStatueUserId == -1 then
			return -- Already displaying fallback
		end
		currentStatueUserId = -1
		if oldStatue then
			oldStatue:Destroy()
		end
		local fallback = buildFallbackStatue(standCF)
		fallback.Parent = pedestal
		return
	end

	if currentStatueUserId == targetUserId and oldStatue then
		-- Update billboard numbers if userId hasn't changed
		local head = oldStatue:FindFirstChild("Head") :: BasePart?
		if head then
			createStreakBillboard(head, playerName, topStreakVal)
		end
		return
	end

	currentStatueUserId = targetUserId

	task.spawn(function()
		local ok, rig = pcall(function()
			return Players:CreateHumanoidModelFromUserId(targetUserId)
		end)

		if not ok or not rig or currentStatueUserId ~= targetUserId then
			if rig then
				rig:Destroy()
			end
			if not oldStatue then
				local fallback = buildFallbackStatue(standCF)
				fallback.Parent = pedestal
			end
			return
		end

		rig.Name = "Rank1Statue"

		-- Clean up animations, scripts, shirts, pants to let gold body shine
		local hrp = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
		local head = rig:FindFirstChild("Head") :: BasePart?

		for _, desc in rig:GetDescendants() do
			if desc:IsA("BaseScript") or desc:IsA("Animator") or desc:IsA("Animation") then
				desc:Destroy()
			elseif desc:IsA("Clothing") or desc:IsA("ShirtGraphic") then
				desc:Destroy()
			elseif desc:IsA("Humanoid") then
				desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				desc.EvaluateStateMachine = false
			elseif desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanQuery = false
				desc.CanTouch = false
				desc.CastShadow = false
				desc.Material = Enum.Material.SmoothPlastic
				desc.Color = Config.TIER_1.Color -- Gold tint
			end
		end

		-- Pose avatar in a generic victory pose (Right arm raised)
		local rightArm = rig:FindFirstChild("Right Arm") or rig:FindFirstChild("RightUpperArm")
		if rightArm and rightArm:IsA("BasePart") and hrp then
			rightArm.CFrame = hrp.CFrame * CFrame.new(1.3, 0.5, -0.3) * CFrame.Angles(math.rad(130), 0, math.rad(-20))
		end

		-- Align to pedestal
		if hrp then
			hrp.CFrame = standCF * CFrame.new(0, 3.0, 0)
		else
			rig:PivotTo(standCF * CFrame.new(0, 3.0, 0))
		end

		rig.PrimaryPart = hrp or head

		-- Attach Streak King Billboard
		if head then
			createStreakBillboard(head, playerName, topStreakVal)
		elseif hrp then
			createStreakBillboard(hrp, playerName, topStreakVal)
		end

		if oldStatue then
			oldStatue:Destroy()
		end
		rig.Parent = pedestal
	end)
end

-- Initialize Service
local function init()
	local function ensureHub()
		local lobby = Workspace:WaitForChild("Lobby")
		local rogue = lobby:FindFirstChild("CenterHub")
		if rogue then
			rogue:Destroy()
		end
		local currentHub = lobby:FindFirstChild("Hub")
		if not currentHub then
			local hub, rotatingPedestal, pedestalBase = buildCenterHubGeometry()
			updateRank1Statue(rotatingPedestal, pedestalBase)
		else
			local ped = currentHub:FindFirstChild("RotatingPedestal") :: Model?
			local base = if ped then ped:FindFirstChild("PedestalBase") :: Part? else nil
			if ped and base then
				updateRank1Statue(ped, base)
			end
		end
	end

	ensureHub()

	-- Re-attach if Lobby is ever rebuilt at runtime
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Lobby" then
			task.defer(ensureHub)
		end
	end)

	-- 60 second update loop
	task.spawn(function()
		while true do
			task.wait(Config.REFRESH_INTERVAL_SECONDS)
			local lobby = Workspace:FindFirstChild("Lobby")
			local hub = if lobby then (lobby:FindFirstChild("Hub") or lobby:FindFirstChild("CenterHub")) else nil
			local ped = if hub then hub:FindFirstChild("RotatingPedestal") :: Model? else nil
			local base = if ped then ped:FindFirstChild("PedestalBase") :: Part? else nil
			if ped and base then
				updateRank1Statue(ped, base)
			end
		end
	end)
end

init()

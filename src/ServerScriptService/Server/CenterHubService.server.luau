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
	line3.Text = if streakCount > 0 then `{streakCount} WIN STREAK` else "CHAMPION"
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

-- Align avatar limbs and accessories cleanly so heads, hats, and hair never detach
local function assembleAvatarRig(model: Model)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("Constraint") and desc.Attachment0 and desc.Attachment1 then
			local att0 = desc.Attachment0
			local att1 = desc.Attachment1
			local part0 = att0.Parent :: BasePart?
			local part1 = att1.Parent :: BasePart?
			if part0 and part1 and part0:IsA("BasePart") and part1:IsA("BasePart") then
				part1.CFrame = part0.CFrame * att0.CFrame * att1.CFrame:Inverse()
			end
		end
	end

	for _, acc in ipairs(model:GetChildren()) do
		if acc:IsA("Accessory") then
			local handle = acc:FindFirstChild("Handle") :: BasePart?
			if handle then
				local handleAtt = handle:FindFirstChildOfClass("Attachment")
				if handleAtt then
					for _, desc in ipairs(model:GetDescendants()) do
						if desc:IsA("Attachment") and desc.Name == handleAtt.Name and desc.Parent ~= handle then
							local bodyPart = desc.Parent :: BasePart?
							if bodyPart and bodyPart:IsA("BasePart") then
								handle.CFrame = bodyPart.CFrame * desc.CFrame * handleAtt.CFrame:Inverse()
								break
							end
						end
					end
				end
			end
		end
	end
end

-- Resolve champion from active players in the server (streak first, then wins)
local function getTopServerChampion(): (Player?, number)
	local bestPlayer: Player? = nil
	local bestStreak = -1

	for _, player in ipairs(Players:GetPlayers()) do
		local streak = 0
		local ls = player:FindFirstChild("leaderstats")
		local sVal = ls and ls:FindFirstChild("Streak")
		if sVal and sVal:IsA("IntValue") then
			streak = sVal.Value
		end

		if streak == 0 then
			local ok, prof = pcall(function()
				return require(game.ServerScriptService.Server.ProfileService).Get(player)
			end)
			if ok and prof and prof.Streak then
				streak = prof.Streak
			end
		end

		if streak > bestStreak then
			bestStreak = streak
			bestPlayer = player
		end
	end

	return bestPlayer, math.max(0, bestStreak)
end

-- Refresh the Rank 1 Statue with the top player
local function updateRank1Statue(pedestal: Model, pedestalBase: Part)
	local serverPlayer, serverStreak = getTopServerChampion()
	local targetUserId: number? = nil
	local topStreakVal = 0
	local playerName = "Nobody Yet"

	if serverPlayer then
		targetUserId = serverPlayer.UserId
		topStreakVal = serverStreak
		playerName = serverPlayer.DisplayName
	else
		-- Fallback to global DataStore if no active player in server
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
					if uid and uid > 0 and val > 0 then
						targetUserId = uid
						topStreakVal = val
						playerName = resolveUserName(uid)
					end
				end
			end
		end
	end

	local oldStatue = pedestal:FindFirstChild("Rank1Statue")

	if not targetUserId or targetUserId <= 0 then
		currentStatueUserId = -1
		if oldStatue then
			oldStatue:Destroy()
		end
		createStreakBillboard(pedestalBase, "Nobody Yet", 0)
		return
	end

	-- If already displaying the same user, just refresh billboard numbers
	if currentStatueUserId == targetUserId and oldStatue then
		local head = oldStatue:FindFirstChild("Head") or oldStatue:FindFirstChild("HumanoidRootPart") or pedestalBase
		if head and head:IsA("BasePart") then
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
			return
		end

		rig.Name = "Rank1Statue"

		-- 1. Assemble body joints and accessories intact at raw origin
		assembleAvatarRig(rig)

		local hrp = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
		local head = rig:FindFirstChild("Head") :: BasePart?

		-- 2. Position standing cleanly on the golden pedestal platform
		local standPos = pedestalBase.Position + Vector3.new(0, (pedestalBase.Size.X / 2) + 3.0, 0)
		local standCF = CFrame.lookAt(standPos, standPos + Vector3.new(0, 0, 1))

		-- 3. Pivot the entire assembled avatar rig to pedestal BEFORE anchoring parts
		rig.PrimaryPart = hrp or head
		rig:PivotTo(standCF)

		-- 4. Anchor all parts, preserve clothing/hair/face, prevent humanoid death
		for _, desc in ipairs(rig:GetDescendants()) do
			if desc:IsA("BaseScript") or desc:IsA("Animator") or desc:IsA("Animation") then
				desc:Destroy()
			elseif desc:IsA("Humanoid") then
				desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				desc.EvaluateStateMachine = false
				desc.NameDisplayDistance = 0
				desc.HealthDisplayDistance = 0
				desc.RequiresNeck = false
			elseif desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanQuery = false
				desc.CanTouch = false
				desc.CastShadow = true
			end
		end

		-- 5. Attach 👑 STREAK KING Billboard to head
		local adornee = head or hrp or pedestalBase
		if adornee and adornee:IsA("BasePart") then
			createStreakBillboard(adornee, playerName, topStreakVal)
		end

		-- Remove idle billboard from pedestalBase if placed there previously
		local idleBb = pedestalBase:FindFirstChild("StreakKingBillboard")
		if idleBb and idleBb.Parent ~= adornee then
			idleBb:Destroy()
		end

		if oldStatue and oldStatue.Parent then
			oldStatue:Destroy()
		end
		rig.Parent = pedestal
	end)
end

-- Initialize Service
local function init()
	local function getPedestalComponents(): (Model?, Part?)
		local lobby = Workspace:FindFirstChild("Lobby")
		local currentHub = lobby and (lobby:FindFirstChild("Hub") or lobby:FindFirstChild("CenterHub"))
		local ped = currentHub and currentHub:FindFirstChild("RotatingPedestal") :: Model?
		local base = ped and ped:FindFirstChild("PedestalBase") :: Part?
		return ped, base
	end

	local function refresh()
		local ped, base = getPedestalComponents()
		if ped and base then
			updateRank1Statue(ped, base)
		end
	end

	refresh()

	-- Hook into players joining, leaving, and updating streaks in real-time
	local function hookPlayer(player: Player)
		local function onStreakChanged()
			refresh()
		end

		local function checkLeaderstats()
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local sVal = ls:FindFirstChild("Streak")
				if sVal and sVal:IsA("IntValue") then
					sVal.Changed:Connect(onStreakChanged)
				end
			end
		end

		player.ChildAdded:Connect(function(c)
			if c.Name == "leaderstats" then
				checkLeaderstats()
			end
		end)
		checkLeaderstats()
		refresh()
	end

	for _, p in ipairs(Players:GetPlayers()) do
		hookPlayer(p)
	end
	Players.PlayerAdded:Connect(hookPlayer)
	Players.PlayerRemoving:Connect(function()
		task.defer(refresh)
	end)

	-- 60 second periodic refresh
	task.spawn(function()
		while true do
			task.wait(Config.REFRESH_INTERVAL_SECONDS or 60)
			refresh()
		end
	end)
end

init()

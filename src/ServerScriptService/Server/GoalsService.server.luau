--!strict
--[[
	GoalsService (Server)
	Responsibility: Manages stadium goal net enclosures and containment walls.
	(Minigames removed per user request)
	Location: ServerScriptService/Server/GoalsService.server.luau
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GoalsConfig = require(Shared:WaitForChild("GoalsConfig"))

type GoalDef = GoalsConfig.GoalDef

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material,
	transparency: number,
	canCollide: boolean
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Transparency = transparency or 0
	p.CanCollide = canCollide
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function setupGoalNet(goalModel: Model, goalKey: string, gDef: GoalDef)
	local existingNet = goalModel:FindFirstChild("Net")
	if existingNet then existingNet:Destroy() end

	local netFolder = goalModel:FindFirstChild("NetEnclosure")
	if netFolder then netFolder:Destroy() end

	netFolder = Instance.new("Folder")
	netFolder.Name = "NetEnclosure"
	netFolder.Parent = goalModel

	local xBase = gDef.goalLineX
	local xOffset = if gDef.facingX == -1 then -3.5 else 3.5
	local xBack = xBase + xOffset
	local zCenter = gDef.centerZ
	local yCenter = gDef.height * 0.5

	makePart(netFolder, "BackNet", Vector3.new(0.2, gDef.height, gDef.width), CFrame.new(xBack, yCenter, zCenter), GoalsConfig.NET_COLOR, Enum.Material.Fabric, GoalsConfig.NET_TRANSPARENCY, false)
	makePart(netFolder, "TopNet", Vector3.new(3.5, 0.2, gDef.width), CFrame.new(xBase + xOffset * 0.5, gDef.height, zCenter), GoalsConfig.NET_COLOR, Enum.Material.Fabric, GoalsConfig.NET_TRANSPARENCY, false)
	makePart(netFolder, "SideNet_N", Vector3.new(3.5, gDef.height, 0.2), CFrame.new(xBase + xOffset * 0.5, yCenter, zCenter - gDef.width * 0.5), GoalsConfig.NET_COLOR, Enum.Material.Fabric, GoalsConfig.NET_TRANSPARENCY, false)
	makePart(netFolder, "SideNet_S", Vector3.new(3.5, gDef.height, 0.2), CFrame.new(xBase + xOffset * 0.5, yCenter, zCenter + gDef.width * 0.5), GoalsConfig.NET_COLOR, Enum.Material.Fabric, GoalsConfig.NET_TRANSPARENCY, false)

	local wallX = xBack + (if gDef.facingX == -1 then -0.3 else 0.3)
	makePart(netFolder, "BackWallStopper", Vector3.new(0.4, gDef.height + 1, gDef.width + 1), CFrame.new(wallX, yCenter, zCenter), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1, true)

	local barrierX = xBase + (if gDef.facingX == -1 then -8.0 else 8.0)
	makePart(netFolder, "StadiumBarrierWall", Vector3.new(0.6, 25.0, 50.0), CFrame.new(barrierX, 12.5, zCenter), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1, true)
end

local function initGoalsService()
	local lobby = Workspace:WaitForChild("Lobby", 10) :: Folder?
	if not lobby then return end

	local goalsFolder = lobby:FindFirstChild("Goals")
	local westGoal = (if goalsFolder then goalsFolder:FindFirstChild("WestGoal") else nil) or (lobby:FindFirstChild("WestGoal") :: Model?)
	local eastGoal = (if goalsFolder then goalsFolder:FindFirstChild("EastGoal") else nil) or (lobby:FindFirstChild("EastGoal") :: Model?)
	if not westGoal or not eastGoal then return end

	for goalKey, gDef in pairs(GoalsConfig.GOALS) do
		local goalModel = if goalKey == "West" then westGoal else eastGoal
		setupGoalNet(goalModel, goalKey, gDef)
	end
end

task.defer(initGoalsService)

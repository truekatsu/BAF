--!strict
--[[
	ModelSnapHelper
	Responsibility: Reusable Studio Command Bar / Plugin helper for snapping models to ground/surfaces
	and generating structural support pillars.
	Features:
	- Downward raycasting from lowest bounding box / part bottom
	- snapToGround(model, extraOffset) using model:PivotTo() with ChangeHistoryService undo support
	- generatePillars(model, options) for building structural supports between model corners and surface
	- runOnSelection() for 1-click execution in Studio Command Bar
	Location: ReplicatedStorage/Shared/ModelSnapHelper (ModuleScript)
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local Workspace = game:GetService("Workspace")

export type PillarOptions = {
	pillarWidth: number?,
	overlapBoard: number?,
	color: Color3?,
	material: Enum.Material?,
	addFootPlates: boolean?,
	footPlateColor: Color3?,
	addBackBrace: boolean?,
}

local ModelSnapHelper = {}

-- 1. Measure lowest Y and downward distance to surface
function ModelSnapHelper.measureGap(model: Model): (number?, RaycastResult?, number)
	local cf, sz = model:GetBoundingBox()
	local lowestY = math.huge

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local bot = d.Position.Y - (d.Size.Y * 0.5)
			if bot < lowestY then
				lowestY = bot
			end
		end
	end

	if lowestY == math.huge then
		lowestY = cf.Position.Y - (sz.Y * 0.5)
	end

	local rayOrigin = Vector3.new(cf.Position.X, lowestY + 0.05, cf.Position.Z)
	local rayDir = Vector3.new(0, -200, 0)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { model }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local hit = Workspace:Raycast(rayOrigin, rayDir, params)
	if hit then
		local gap = rayOrigin.Y - hit.Position.Y - 0.05
		return gap, hit, lowestY
	end

	return nil, nil, lowestY
end

-- 2. Snap model lowest face to ground (with optional extra offset / embed)
function ModelSnapHelper.snapToGround(model: Model, extraOffset: number?): (number, number)
	local offset = extraOffset or 0
	local gapBefore, hit, lowestY = ModelSnapHelper.measureGap(model)

	if not gapBefore or not hit then
		warn(string.format("[ModelSnapHelper] No surface found under %s", model.Name))
		return 0, 0
	end

	local deltaY = -(gapBefore - offset)
	model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))

	local gapAfter = math.max(0, ModelSnapHelper.measureGap(model) or 0)
	ChangeHistoryService:SetWaypoint(string.format("Snap %s to Ground", model.Name))

	print(string.format("[ModelSnapHelper] %s: Gap Before = %.3f studs | Gap After = %.3f studs (Offset = %.3f)",
		model.Name, gapBefore, gapAfter, offset))

	return gapBefore, gapAfter
end

-- 3. Generate two structural pillars under bottom corners
function ModelSnapHelper.generatePillars(model: Model, options: PillarOptions?): { Part }
	local opt = options or {}
	local pWidth = opt.pillarWidth or 1.4
	local overlap = opt.overlapBoard or 0.25
	local pillarColor = opt.color or Color3.fromHex("#1F4FD8")
	local pillarMat = opt.material or Enum.Material.Metal
	local addFootPlates = if opt.addFootPlates == nil then true else opt.addFootPlates
	local footColor = opt.footPlateColor or Color3.fromHex("#F5B82E")
	local addBrace = if opt.addBackBrace == nil then true else opt.addBackBrace

	local cf, sz = model:GetBoundingBox()
	local gap, hit, lowestY = ModelSnapHelper.measureGap(model)

	if not gap or not hit then
		warn(string.format("[ModelSnapHelper] Cannot generate pillars: no surface under %s", model.Name))
		return {}
	end

	local surfaceY = hit.Position.Y
	local height = (lowestY - surfaceY) + overlap
	if height <= 0.1 then
		print(string.format("[ModelSnapHelper] %s is already touching surface; skipping pillars", model.Name))
		return {}
	end

	local created: { Part } = {}
	local leftX = -((sz.X * 0.5) - (pWidth * 0.5))
	local rightX = ((sz.X * 0.5) - (pWidth * 0.5))

	local rotOnly = cf - cf.Position

	for _, side in { { name = "Support_Left", x = leftX, fp = "FootPlate_L" }, { name = "Support_Right", x = rightX, fp = "FootPlate_R" } } do
		local pillarCenterY = surfaceY + (height * 0.5)
		local localPillarPos = cf * Vector3.new(side.x, 0, 0)
		local pCF = CFrame.new(localPillarPos.X, pillarCenterY, localPillarPos.Z) * rotOnly

		local pillar = Instance.new("Part")
		pillar.Name = side.name
		pillar.Size = Vector3.new(pWidth, height, pWidth)
		pillar.CFrame = pCF
		pillar.Color = pillarColor
		pillar.Material = pillarMat
		pillar.Anchored = true
		pillar.CanCollide = false
		pillar.CanTouch = false
		pillar.CanQuery = false
		pillar.CastShadow = false
		pillar.Parent = model
		table.insert(created, pillar)

		if addFootPlates then
			local fpHeight = 0.2
			local fpSize = pWidth * 1.5
			local fpCF = CFrame.new(localPillarPos.X, surfaceY + (fpHeight * 0.5), localPillarPos.Z) * rotOnly
			local fp = Instance.new("Part")
			fp.Name = side.fp
			fp.Size = Vector3.new(fpSize, fpHeight, fpSize)
			fp.CFrame = fpCF
			fp.Color = footColor
			fp.Material = Enum.Material.Metal
			fp.Anchored = true
			fp.CanCollide = false
			fp.CanTouch = false
			fp.CanQuery = false
			fp.Parent = model
			table.insert(created, fp)
		end
	end

	if addBrace then
		local braceCenterY = surfaceY + (height * 0.5)
		local braceWidth = math.abs(rightX - leftX)
		local braceCF = CFrame.new(cf.Position.X, braceCenterY, cf.Position.Z) * rotOnly * CFrame.new(0, 0, -(pWidth * 0.5))
		local brace = Instance.new("Part")
		brace.Name = "Brace_Back"
		brace.Size = Vector3.new(braceWidth, 0.4, 0.4)
		brace.CFrame = braceCF
		brace.Color = Color3.fromHex("#141B3A")
		brace.Material = Enum.Material.Metal
		brace.Anchored = true
		brace.CanCollide = false
		brace.CanTouch = false
		brace.CanQuery = false
		brace.Parent = model
		table.insert(created, brace)
	end

	ChangeHistoryService:SetWaypoint(string.format("Generate Supports for %s", model.Name))
	print(string.format("[ModelSnapHelper] Generated %d support parts for %s (Height: %.2f studs)", #created, model.Name, height))
	return created
end

-- 4. Convenient Command Bar entry point
function ModelSnapHelper.runOnSelection(extraOffset: number?, makePillars: boolean?)
	local targets = Selection:Get()
	if #targets == 0 then
		warn("[ModelSnapHelper] No objects selected! Select one or more Models in Explorer first.")
		return
	end

	for _, item in ipairs(targets) do
		if item:IsA("Model") then
			local gapBefore, gapAfter = ModelSnapHelper.snapToGround(item, extraOffset or 0.05)
			if makePillars then
				ModelSnapHelper.generatePillars(item)
			end
		else
			warn(string.format("[ModelSnapHelper] Skipping %s (%s is not a Model)", item.Name, item.ClassName))
		end
	end
end

return ModelSnapHelper
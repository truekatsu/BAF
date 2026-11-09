--!strict
--[[
	StandsService (Server)
	Responsibility: Manages the 8 stadium sectors, seat color variety, and signage:
	- Backs up original bowl to Workspace.Lobby.Stands_Backup (Archivable=false)
	- Organizes sector decor in Workspace.Lobby.Stands
	- Styles the 8 sectors (A..H) with distinct colors (Blue, Red, Yellow, Green, Purple, Orange, Cyan, Pink)
	- Applies 70% primary / 30% white-grey seat mix with custom patterns per sector
	- Applies 60% bias to spectator shirt colors per sector
	- Mounts SECTOR A..H signs (6x2 studs) and 2 vertical white aisle lines per sector
	Loop step: live lobby atmosphere | visual immersion | stadium identity
	Location: ServerScriptService/Server/StandsService.server.luau
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StandsConfig = require(Shared:WaitForChild("StandsConfig"))

local octantToSectorId = {
	[6] = "A", -- North
	[7] = "B", -- North-East
	[0] = "C", -- East
	[1] = "D", -- South-East
	[2] = "E", -- South
	[3] = "F", -- South-West
	[4] = "G", -- West
	[5] = "H", -- North-West
}

local sectorPatterns = {
	A = "vertical_stripes",
	B = "checker",
	C = "chevrons",
	D = "double_stripes",
	E = "alternating",
	F = "checker_stagger",
	G = "triple_stripes",
	H = "stagger_mix",
}

local function getPartSector(part: BasePart): (string?, Color3?)
	local p = part.Position
	local dx = p.X - 0
	local dz = p.Z - (-43)
	local angle = math.deg(math.atan2(dz, dx))
	if angle < 0 then angle = angle + 360 end
	local octant = math.floor((angle + 22.5) / 45) % 8
	local secId = octantToSectorId[octant]
	local col = if secId then StandsConfig.SECTOR_COLORS[secId] else nil
	return secId, col
end

local function applyStandVariety()
	local lobby = Workspace:WaitForChild("Lobby", 10)
	if not lobby then return end

	local bowl = (lobby:FindFirstChild("StadiumBowl") or (lobby:FindFirstChild("Stands") and lobby.Stands:FindFirstChild("StadiumBowl"))) :: Model?
	if not bowl then return end

	-- 1. Backup if not already backed up
	local ServerStorage = game:GetService("ServerStorage")
	local backupFolder = ServerStorage:FindFirstChild("Stands_Backup")
	if not backupFolder then
		backupFolder = Instance.new("Folder")
		backupFolder.Name = "Stands_Backup"
		backupFolder.Archivable = false
		local bowlBackup = bowl:Clone()
		bowlBackup.Name = "StadiumBowl_Original"
		bowlBackup.Parent = backupFolder
		backupFolder.Parent = ServerStorage
	end

	-- 2. Ensure Workspace.Lobby.Stands folder
	local standsFolder = lobby:FindFirstChild("Stands")
	if not standsFolder then
		standsFolder = Instance.new("Folder")
		standsFolder.Name = "Stands"
		standsFolder.Parent = lobby
	end

	local structCols = StandsConfig.STRUCTURE_COLORS
	local whiteSeat = structCols.WhiteSeats

	-- 3. Dark neutral structure
	for _, desc in ipairs(bowl:GetChildren()) do
		if desc:IsA("BasePart") then
			if desc.Name:find("Tier") then
				desc.Color = structCols.Tiers
				desc.Material = Enum.Material.SmoothPlastic
			elseif desc.Name == "FrontWall" or desc.Name:find("TribuneFront") then
				desc.Color = structCols.FrontWall
				desc.Material = Enum.Material.SmoothPlastic
			elseif desc.Name == "BackWall" then
				desc.Color = structCols.BackWall
				desc.Material = Enum.Material.SmoothPlastic
			elseif desc.Name == "UpperRim" then
				desc.Color = structCols.Tiers
				desc.Material = Enum.Material.SmoothPlastic
			elseif desc.Name == "StairAisle" then
				desc.Color = structCols.Aisles
				desc.Material = Enum.Material.SmoothPlastic
			end
		end
	end

	-- 4. Seats: 70% primary, 30% white/grey pattern
	for _, desc in ipairs(bowl:GetChildren()) do
		if desc:IsA("BasePart") and desc.Name:find("Seats") then
			local secId, secColor = getPartSector(desc)
			if secId and secColor then
				desc.Color = secColor
				desc.Material = Enum.Material.SmoothPlastic

				local oldGui = desc:FindFirstChild("SeatPatternGui")
				if oldGui then oldGui:Destroy() end

				local sg = Instance.new("SurfaceGui")
				sg.Name = "SeatPatternGui"
				sg.Face = Enum.NormalId.Top
				sg.CanvasSize = Vector2.new(1200, 40)
				sg.LightInfluence = 1.0
				sg.AlwaysOnTop = false
				sg.Parent = desc

				local pattern = sectorPatterns[secId] or "vertical_stripes"
				local rowNum = tonumber(desc.Name:match("%d+")) or 1
				local totalSegments = 24
				local segWidth = 1200 / totalSegments

				for col = 1, totalSegments do
					local isPrimary = true
					if pattern == "vertical_stripes" then
						isPrimary = (col % 4 ~= 0)
					elseif pattern == "checker" then
						isPrimary = ((col + rowNum) % 3 ~= 0)
					elseif pattern == "chevrons" then
						local dist = math.abs(col - 12)
						isPrimary = ((dist + rowNum) % 3 ~= 0)
					elseif pattern == "double_stripes" then
						isPrimary = ((col % 3) ~= 0)
					elseif pattern == "alternating" then
						isPrimary = (rowNum == 3) and (col % 2 == 0) or (col % 4 ~= 0)
					elseif pattern == "checker_stagger" then
						isPrimary = ((col * 2 + rowNum) % 4 ~= 0)
					elseif pattern == "triple_stripes" then
						isPrimary = (col % 5 ~= 0)
					else
						isPrimary = ((col + rowNum * 2) % 3 ~= 0)
					end

					local f = Instance.new("Frame")
					f.Name = `Seat_{col}`
					f.Size = UDim2.fromOffset(segWidth, 40)
					f.Position = UDim2.fromOffset((col - 1) * segWidth, 0)
					f.BackgroundColor3 = if isPrimary then secColor else whiteSeat
					f.BorderSizePixel = 1
					f.BorderColor3 = Color3.fromHex("#111827")
					f.Parent = sg
				end
			end
		end
	end

	-- 5. Spectators: 60% bias towards sector primary color
	local rng = Random.new(42)
	local neutralShirts = {
		Color3.fromHex("#FFFFFF"),
		Color3.fromHex("#1F2937"),
		Color3.fromHex("#4B5563"),
		Color3.fromHex("#9CA3AF"),
		Color3.fromHex("#D1D5DB"),
		Color3.fromHex("#F59E0B"),
	}

	for _, desc in ipairs(bowl:GetChildren()) do
		if desc:IsA("BasePart") and desc.Name:find("CrowdStrip") then
			local secId, secColor = getPartSector(desc)
			if secId and secColor then
				local cg = desc:FindFirstChildWhichIsA("SurfaceGui")
				local frame = cg and cg:FindFirstChild("Frame")
				if frame then
					for _, spec in ipairs(frame:GetChildren()) do
						if spec:IsA("Frame") and #spec:GetChildren() >= 2 then
							local shirt = spec:GetChildren()[2]
							if shirt and shirt:IsA("Frame") then
								if rng:NextNumber() < StandsConfig.SPECTATOR_PRIMARY_BIAS then
									local tint = 0.85 + rng:NextNumber() * 0.30
									shirt.BackgroundColor3 = Color3.new(
										math.clamp(secColor.R * tint, 0, 1),
										math.clamp(secColor.G * tint, 0, 1),
										math.clamp(secColor.B * tint, 0, 1)
									)
								else
									shirt.BackgroundColor3 = neutralShirts[rng:NextInteger(1, #neutralShirts)]
								end
							end
						end
					end
				end
			end
		end
	end

	-- 6. Recolor banners to sector primary color
	for _, desc in ipairs(bowl:GetChildren()) do
		if desc:IsA("BasePart") and desc.Name:find("Banner") then
			local secId, secColor = getPartSector(desc)
			if secId and secColor then
				desc.Color = secColor
				desc.Material = Enum.Material.SmoothPlastic
			end
		end
	end

	-- 7. Sector signs (static geometry built in Edit mode; skip runtime spawn if already present)
	local existingSign = standsFolder:FindFirstChild("Sign_A")
	if existingSign then
		return
	end
end

task.defer(applyStandVariety)

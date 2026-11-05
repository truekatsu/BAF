--!strict
--[[
	StandsConfig
	Responsibility: Configuration for the 8 stadium sectors, seat colors, patterns, and signage:
	- 8 sectors (A..H) with distinct colors matching PRD
	- 70% primary / 30% white-grey pattern distributions
	- Sector sign dimensions and aisle line specs
	Loop step: live lobby atmosphere | visual immersion | stadium identity
	Location: ReplicatedStorage/Shared/StandsConfig (ModuleScript)
]]

export type SectorDef = {
	id: string,
	name: string,
	color: Color3,
	pattern: string,
	octant: number,
}

local StandsConfig = {
	SECTOR_COLORS = {
		A = Color3.fromHex("#1E6FFF"), -- Blue (North)
		B = Color3.fromHex("#E5252A"), -- Red (North-East)
		C = Color3.fromHex("#FFD21F"), -- Yellow (East)
		D = Color3.fromHex("#3DDC3D"), -- Green (South-East)
		E = Color3.fromHex("#A855F7"), -- Purple (South)
		F = Color3.fromHex("#FF8A1F"), -- Orange (South-West)
		G = Color3.fromHex("#19C2FF"), -- Cyan (West)
		H = Color3.fromHex("#FF2E93"), -- Pink (North-West)
	},

	SECTOR_ORDER = { "A", "B", "C", "D", "E", "F", "G", "H" },

	STRUCTURE_COLORS = {
		Tiers = Color3.fromHex("#262930"),
		FrontWall = Color3.fromHex("#1E2026"),
		BackWall = Color3.fromHex("#181A20"),
		Aisles = Color3.fromHex("#333742"),
		WhiteSeats = Color3.fromHex("#E2E8F0"),
	},

	SIGN_SIZE = Vector3.new(6.0, 2.0, 0.4),
	AISLE_LINE_WIDTH = 0.4,
	SPECTATOR_PRIMARY_BIAS = 0.60, -- 60% bias towards sector primary color
}

return table.freeze(StandsConfig)

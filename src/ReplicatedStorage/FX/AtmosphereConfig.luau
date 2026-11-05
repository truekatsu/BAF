--!strict
--[[
	AtmosphereConfig
	Responsibility: Configuration and toggle flags for Stadium Atmosphere FX (TASK P8):
	- Ambient Confetti bursts from stand rim (every 45-90s, 6 bright colors, low graphics auto-disable)
	- Crowd Wave (Mexican wave light band across 8 sectors every 60s)
	- Win Celebration (3 firework bursts 1.2s apart, kit smoke puff, Jumbotron confetti within 120 studs)
	- Stadium Ambience Audio (looping ambient crowd, random 20-40s one-shots, in-match low-pass equalizer muffle)
	Loop step: lobby atmosphere | stadium immersion | celebratory juice
	Location: ReplicatedStorage/FX/AtmosphereConfig.luau
]]

export type OneShotSound = {
	name: string,
	id: string,
	volume: number,
}

local AtmosphereConfig = {
	-- On/Off toggle flags (all features can be individually disabled)
	FLAGS = {
		ENABLE_AMBIENT_CONFETTI = true,
		ENABLE_CROWD_WAVE = true,
		ENABLE_WIN_CELEBRATION = true,
		ENABLE_AMBIENCE_AUDIO = true,
	},

	-- A) Ambient Confetti
	AMBIENT_CONFETTI = {
		MIN_INTERVAL_SEC = 45.0,
		MAX_INTERVAL_SEC = 90.0,
		BURST_DURATION_SEC = 2.0,
		PARTICLES_PER_BURST = 120,
		ACTIVE_EMITTERS_COUNT = 3,
		COLORS = {
			Color3.fromHex("#EF4444"), -- Red
			Color3.fromHex("#3B82F6"), -- Blue
			Color3.fromHex("#EAB308"), -- Yellow
			Color3.fromHex("#22C55E"), -- Green
			Color3.fromHex("#A855F7"), -- Purple
			Color3.fromHex("#EC4899"), -- Pink
		},
		LOW_GRAPHICS_THRESHOLD = 3, -- Disabled if SavedQualityLevel <= 3
	},

	-- B) Crowd Wave
	CROWD_WAVE = {
		INTERVAL_SEC = 60.0,
		WAVE_DURATION_SEC = 4.0,
		SECTORS_COUNT = 8,
		HIGHLIGHT_COLOR = Color3.fromHex("#FEF08A"), -- Warm light yellow wave
		PEAK_TRANSPARENCY = 0.35,
	},

	-- C) Win Celebration
	WIN_CELEBRATION = {
		BURST_COUNT = 3,
		BURST_INTERVAL_SEC = 1.2,
		MAX_PARTICLES_PER_BURST = 180, -- Budget <= 200
		TABLE_COOLDOWN_SEC = 2.0,
		MAX_DISTANCE_STUDS = 120.0,
		TEAM_COLORS = {
			Blue = Color3.fromHex("#1E6FFF"),
			Red = Color3.fromHex("#EF4444"),
			Gold = Color3.fromHex("#FFD21F"),
		},
	},

	-- D) Stadium Ambience Audio
	AUDIO = {
		MASTER_VOLUME = 0.5,
		AMBIENT_LOOP = {
			name = "SFX_CrowdAmbient",
			id = "rbxassetid://0",
			volume = 0.25,
			looped = true,
		},
		ONE_SHOTS = {
			{ name = "SFX_Cheer", id = "rbxassetid://0", volume = 0.30 },
			{ name = "SFX_Chant", id = "rbxassetid://0", volume = 0.25 },
			{ name = "SFX_Whistle", id = "rbxassetid://0", volume = 0.20 },
		} :: { OneShotSound },
		ONE_SHOT_MIN_INTERVAL_SEC = 20.0,
		ONE_SHOT_MAX_INTERVAL_SEC = 40.0,
		MUFFLE_EQUALIZER = {
			LowGain = 0,
			MidGain = -10,
			HighGain = -24,
		},
	},
}

return table.freeze(AtmosphereConfig)

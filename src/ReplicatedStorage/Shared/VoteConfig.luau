--!strict
--[[
	VoteConfig.luau
	Responsibility: Shared configuration for the Session-Playtime-Gated Voting system.
	Location: ReplicatedStorage/Shared/VoteConfig (ModuleScript)
]]

local VoteConfig = {
	MIN_SESSION_SECONDS = 300,        -- 5 minutes (300 seconds) in current server session
	VOTES_PER_ROUND = 1,              -- 1 vote allowed per round
	COUNT_ONLY_ACTIVE_TIME = false,   -- Optional Anti-AFK toggle (false = raw session time)
	AFK_THRESHOLD_SECONDS = 60,       -- Max idle seconds before active timer pauses
	NOTIFY_WHEN_UNLOCKED = true,      -- Toast player when 5:00 is reached in session
	MAX_PAD_DISTANCE = 16,            -- Maximum studs from pad to cast vote
	RATE_LIMIT_SECONDS = 2.0,         -- Throttling debounce per player
	ENABLE_TEST_COMMAND = true,       -- Enable /skipvotetimer command for Studio & Admins
}

return table.freeze(VoteConfig)

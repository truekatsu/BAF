--!strict
--[[
	JumbotronConfig
	Responsibility: Configuration for the South end Stadium Jumbotron:
	- 3-panel display (Skin Refresh Timer, Center Social Proof Rotation, Event Promo) + Bottom Tips Banner
	- Single server-synchronized timestamp (workspace:GetServerTimeNow())
	- Throttled 1 Hz updates, 8s social proof auto-rotation, 6s bottom tips cycle
	- SurfaceGui performance tuning (PixelsPerStud, LightInfluence 0, MaxDistance 150)
	Location: ReplicatedStorage/Shared/JumbotronConfig (ModuleScript)
]]

export type PromoSlide = {
	title: string,
	subtitle: string,
	color: Color3,
}

export type WeekendEventState = {
	active: boolean,
	targetTimestamp: number,
	remainingSec: number,
}

local JumbotronConfig = {
	SCREEN_SIZE = Vector3.new(60.0, 28.0, 0.8),
	POSITION = Vector3.new(0.0, 22.0, -110.0),
	LOOK_TARGET = Vector3.new(0.0, 3.0, 26.0),
	PIXELS_PER_STUD = 50,
	MAX_DISTANCE = 150,
	LIGHT_INFLUENCE = 0,
	BRIGHTNESS = 1.5,

	FRAME_COLOR = Color3.fromHex("#1F4FD8"),
	GOLD_TRIM_COLOR = Color3.fromHex("#F5B82E"),
	PANEL_BG_COLOR = Color3.fromHex("#0F1530"),
	CARD_BG_COLOR = Color3.fromHex("#141B3A"),
	STROKE_COLOR = Color3.fromHex("#232E52"),

	-- Refresh Timers & Rotation Intervals
	SKIN_ROTATION_INTERVAL_SEC = 600, -- 10 minutes
	CENTER_ROTATE_INTERVAL_SEC = 8,   -- 8s between Latest Winner -> Top Cash -> Rarest Pull
	BANNER_ROTATE_INTERVAL_SEC = 6,   -- 6s rotating tips
	TIMER_THROTTLE_RATE_HZ = 1,       -- 1 Hz single-timestamp update
	FADE_DURATION_SEC = 0.35,

	-- Bottom Banner Cycling Tips (readable from 30+ studs away)
	ROTATING_TIPS = {
		"⚽  BUILD A FOOTBALLER  ⚽",
		"👍  LIKE THE GAME FOR 1 VOTE  👍",
		"👥  JOIN THE GROUP FOR FREE CASH  👥",
		"⚡  PRESS [E] ON A PAD TO VOTE  ⚡",
		"🎁  CLAIM YOUR DAILY REWARD  🎁",
		"🎴  COLLECT ALL 150 CARDS  🎴",
	},

	-- Right Panel Default Events
	PROMO_SLIDES = {
		{
			title = "2X WINS WEEKEND",
			subtitle = "Double wins on all tables this weekend!",
			color = Color3.fromHex("#FFD21F"),
		},
		{
			title = "NEW MYTHIC KITS",
			subtitle = "Discover Messi, Ronaldo & more in the Mythic pool!",
			color = Color3.fromHex("#38BDF8"),
		},
		{
			title = "LIKE & JOIN FOR FREE CASH",
			subtitle = "Like the game and join the group for free bonus Bux!",
			color = Color3.fromHex("#4ADE80"),
		},
	} :: { PromoSlide },

	GRADE_COLORS = {
		S = Color3.fromHex("#E5252A"),
		A = Color3.fromHex("#E5252A"),
		B = Color3.fromHex("#3FD43F"),
		C = Color3.fromHex("#F59E0B"),
		D = Color3.fromHex("#6B7280"),
	},
}

-- Active every Saturday (wday == 7) & Sunday (wday == 1) 00:00 -> Monday 00:00; inactive Mon-Fri -> next Saturday 00:00
function JumbotronConfig.getWeekendEventState(unixNow: number?): WeekendEventState
	local nowSec = math.floor(unixNow or os.time())
	-- Use UTC ("!*t") to match Roblox os.time(table) semantics across Studio and cloud servers
	local dt = os.date("!*t", nowSec) :: { year: number, month: number, day: number, wday: number, hour: number, min: number, sec: number }
	local isWeekend = (dt.wday == 7 or dt.wday == 1)
	local daysAhead = if dt.wday == 7 then 2 elseif dt.wday == 1 then 1 else (7 - dt.wday)
	local targetTs = os.time({
		year = dt.year,
		month = dt.month,
		day = dt.day + daysAhead,
		hour = 0,
		min = 0,
		sec = 0,
	})
	return {
		active = isWeekend,
		targetTimestamp = targetTs,
		remainingSec = math.max(0, targetTs - nowSec),
	}
end

function JumbotronConfig.isWeekendEventActive(unixNow: number?): boolean
	return JumbotronConfig.getWeekendEventState(unixNow).active
end

return table.freeze(JumbotronConfig)
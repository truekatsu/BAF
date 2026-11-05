--!strict
--[[
	JumbotronClient (Client)
	Responsibility: Drives the South end Stadium Jumbotron client display:
	- 1 Hz synchronized countdown timer with last-60s red/yellow pulsing
	- 8s auto-rotation of Middle Panel (Latest Winner -> Top Player Today -> Top Cash Today -> Rarest Pull)
	- Right Panel live event countdown ("ENDS IN 1d 04h") with active status badge
	- 6s rotating tips banner with smooth fade (readable from 30+ studs away)
	Location: StarterPlayer/StarterPlayerScripts/Client/JumbotronClient.client.luau
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JumbotronConfig = require(Shared:WaitForChild("JumbotronConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local function formatTime(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	if s >= 86400 then
		local days = math.floor(s / 86400)
		local hours = math.floor((s % 86400) / 3600)
		return string.format("%dd %02dh", days, hours)
	elseif s >= 3600 then
		local hours = math.floor(s / 3600)
		local mins = math.floor((s % 3600) / 60)
		return string.format("%02d:%02d:%02d", hours, mins, s % 60)
	else
		local mins = math.floor(s / 60)
		return string.format("%02d:%02d", mins, s % 60)
	end
end

local function initJumbotronClient()
	local lobby = Workspace:WaitForChild("Lobby", 15) :: Instance?
	if not lobby then return end

	local jumbotron = lobby:WaitForChild("Jumbotron", 15) :: Model?
	if not jumbotron then return end

	local screen = jumbotron:WaitForChild("Screen", 15) :: BasePart?
	if not screen then return end

	local gui = screen:WaitForChild("JumbotronGui", 15) :: SurfaceGui?
	if not gui then return end

	local root = gui:WaitForChild("Root", 10) :: Frame?
	if not root then return end

	local configFolder = ReplicatedStorage:WaitForChild("Config", 15)
	local skinEndsAt = configFolder and configFolder:WaitForChild("SkinRotationEndsAt", 10) :: NumberValue?

	-- 1. LEFT PANEL: Countdown Timer & 60s Pulse
	local leftPanel = root:WaitForChild("LeftPanel", 5) :: Frame?
	local timerBox = leftPanel and leftPanel:WaitForChild("TimerBox", 5) :: Frame?
	local countdownLbl = timerBox and timerBox:WaitForChild("CountdownLabel", 5) :: TextLabel?
	local timerStroke = timerBox and timerBox:FindFirstChild("Stroke") :: UIStroke?

	task.spawn(function()
		local normalGold = Color3.fromHex("#FFD54A")
		local alertRed = Color3.fromHex("#EF4444")
		local alertYellow = Color3.fromHex("#F59E0B")

		while countdownLbl and countdownLbl.Parent do
			local now = Workspace:GetServerTimeNow()
			local targetTime = if skinEndsAt then skinEndsAt.Value else (now + 600)
			local remaining = math.max(0, targetTime - now)

			local mins = math.floor(remaining / 60)
			local secs = math.floor(remaining % 60)
			countdownLbl.Text = string.format("%02d:%02d", mins, secs)

			-- Pulse red/yellow in last 60 seconds
			if remaining <= 60 and remaining > 0 then
				local isEven = (math.floor(remaining) % 2 == 0)
				countdownLbl.TextColor3 = if isEven then alertRed else alertYellow
				if timerStroke then
					timerStroke.Color = if isEven then alertRed else alertYellow
				end
			else
				countdownLbl.TextColor3 = normalGold
				if timerStroke then
					timerStroke.Color = normalGold
				end
			end

			task.wait(JumbotronConfig.TIMER_THROTTLE_RATE_HZ)
		end
	end)

	-- 2. CENTER PANEL: 8s Auto-Rotation Social Proof
	local centerPanel = root:WaitForChild("CenterPanel", 5) :: Frame?
	local centerHeader = centerPanel and centerPanel:WaitForChild("HeaderFrame", 5) :: Frame?
	local centerHeaderLbl = centerHeader and centerHeader:WaitForChild("HeaderLabel", 5) :: TextLabel?
	local winnerContent = centerPanel and centerPanel:WaitForChild("WinnerContent", 5) :: Frame?
	local avatarImg = winnerContent and winnerContent:WaitForChild("AvatarImage", 5) :: ImageLabel?
	local winnerNameLbl = winnerContent and winnerContent:WaitForChild("WinnerName", 5) :: TextLabel?
	local wonScoreLbl = winnerContent and winnerContent:WaitForChild("WonScore", 5) :: TextLabel?
	local gradeBadge = winnerContent and winnerContent:WaitForChild("GradeBadge", 5) :: Frame?
	local gradeLbl = gradeBadge and gradeBadge:WaitForChild("GradeLabel", 5) :: TextLabel?

	type SocialSlide = {
		header: string,
		name: string,
		userId: number,
		subtitle: string,
		badgeText: string,
		badgeColor: Color3,
	}

	local function getSocialSlides(): { SocialSlide }
		local slides: { SocialSlide } = {}

		-- Slide 1: Latest Winner (or Top Player Today if none)
		local winName = configFolder:GetAttribute("LatestWinnerName")
		if typeof(winName) == "string" and #winName > 0 then
			local uid = tonumber(configFolder:GetAttribute("LatestWinnerUserId")) or 1
			local score = tonumber(configFolder:GetAttribute("LatestWinnerScore")) or 92.0
			local prize = tostring(configFolder:GetAttribute("LatestWinnerPrize") or "MYTHIC PACK")
			table.insert(slides, {
				header = "🏆 LATEST WINNER",
				name = winName,
				userId = uid,
				subtitle = string.format("WON %s (%.1f)", prize, score),
				badgeText = "MATCH WINNER",
				badgeColor = Color3.fromHex("#E5252A"),
			})
		else
			-- Fallback: Top Player Today
			local topName = configFolder:GetAttribute("TopPlayerName") or "Leader #1"
			local topUid = tonumber(configFolder:GetAttribute("TopPlayerUserId")) or 1
			local topWins = tonumber(configFolder:GetAttribute("TopPlayerWins")) or 0
			table.insert(slides, {
				header = "👑 TOP PLAYER TODAY",
				name = tostring(topName),
				userId = topUid,
				subtitle = string.format("%d Wins Today", topWins),
				badgeText = "RANK #1 WINS",
				badgeColor = Color3.fromHex("#F59E0B"),
			})
		end

		-- Slide 2: Top Cash Today
		local cashName = configFolder:GetAttribute("TopCashName") or "Richest Player"
		local cashUid = tonumber(configFolder:GetAttribute("TopCashUserId")) or 1
		local cashAmt = tonumber(configFolder:GetAttribute("TopCashAmount")) or 0
		table.insert(slides, {
			header = "💵 TOP CASH TODAY",
			name = tostring(cashName),
			userId = cashUid,
			subtitle = string.format("$%s Bux", tostring(cashAmt)),
			badgeText = "RICHEST",
			badgeColor = Color3.fromHex("#22C55E"),
		})

		-- Slide 3: Rarest Pull
		local pullName = configFolder:GetAttribute("RarestPullName") or "Lucky Striker"
		local pullUid = tonumber(configFolder:GetAttribute("RarestPullUserId")) or 1
		local pullCard = tostring(configFolder:GetAttribute("RarestPullCard") or "MESSI #10 (MYTHIC)")
		table.insert(slides, {
			header = "✨ RAREST PULL",
			name = tostring(pullName),
			userId = pullUid,
			subtitle = pullCard,
			badgeText = "MYTHIC PULL",
			badgeColor = Color3.fromHex("#A855F7"),
		})

		return slides
	end

	-- Center auto-rotation loop (8s)
	task.spawn(function()
		local slideIdx = 1
		while winnerContent and winnerContent.Parent do
			local slides = getSocialSlides()
			if #slides > 0 then
				local current = slides[((slideIdx - 1) % #slides) + 1]

				-- Smooth crossfade
				if centerHeaderLbl and winnerNameLbl and wonScoreLbl and avatarImg and gradeLbl and gradeBadge then
					local fadeOut = TweenService:Create(winnerContent, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0.5,
					})
					fadeOut:Play()
					fadeOut.Completed:Wait()

					centerHeaderLbl.Text = current.header
					winnerNameLbl.Text = current.name
					wonScoreLbl.Text = current.subtitle
					gradeLbl.Text = current.badgeText
					gradeBadge.BackgroundColor3 = current.badgeColor

					local uid = if current.userId > 0 then current.userId else 1
					avatarImg.Image = `rbxthumb://type=AvatarHeadShot&id={uid}&w=150&h=150`

					local fadeIn = TweenService:Create(winnerContent, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						BackgroundTransparency = 0,
					})
					fadeIn:Play()
				end
			end

			slideIdx += 1
			task.wait(JumbotronConfig.CENTER_ROTATE_INTERVAL_SEC)
		end
	end)

	-- 3. RIGHT PANEL: Event Countdown & Status Badge
	local rightPanel = root:WaitForChild("RightPanel", 5) :: Frame?
	local activeBadge = rightPanel and rightPanel:WaitForChild("ActiveBadge", 5) :: Frame?
	local activeLbl = activeBadge and activeBadge:WaitForChild("BadgeLabel", 5) :: TextLabel?
	local slideBox = rightPanel and rightPanel:WaitForChild("SlideBox", 5) :: Frame?
	local slideTitle = slideBox and slideBox:WaitForChild("SlideTitle", 5) :: TextLabel?
	local slideSub = slideBox and slideBox:WaitForChild("SlideSubtitle", 5) :: TextLabel?
	local eventTimerLbl = slideBox and slideBox:WaitForChild("EventTimerLabel", 5) :: TextLabel?

	task.spawn(function()
		while eventTimerLbl and eventTimerLbl.Parent do
			local now = Workspace:GetServerTimeNow()
			local endsAt = tonumber(configFolder:GetAttribute("EventEndsAt")) or (now + 100800)
			local isActive = (configFolder:GetAttribute("EventActive") ~= false)
			local eventName = tostring(configFolder:GetAttribute("EventName") or "2X WINS WEEKEND")
			local eventSub = tostring(configFolder:GetAttribute("EventSubtitle") or "Double wins on all tables this weekend!")

			if slideTitle then slideTitle.Text = eventName end
			if slideSub then slideSub.Text = eventSub end

			local rem = endsAt - now
			if rem > 0 and isActive then
				if activeBadge then activeBadge.BackgroundColor3 = Color3.fromHex("#22C55E") end
				if activeLbl then activeLbl.Text = "ACTIVE" end
				eventTimerLbl.Text = `ENDS IN {formatTime(rem)}`
				eventTimerLbl.TextColor3 = Color3.fromHex("#38BDF8")
			else
				if activeBadge then activeBadge.BackgroundColor3 = Color3.fromHex("#64748B") end
				if activeLbl then activeLbl.Text = "UPCOMING" end
				eventTimerLbl.Text = `NEXT: SOON`
				eventTimerLbl.TextColor3 = Color3.fromHex("#94A3B8")
			end

			task.wait(1)
		end
	end)

	-- 4. BOTTOM BANNER: 6s Rotating Tips with Fade (Syncs to Stand Banner)
	local botBanner = root:WaitForChild("BottomBanner", 5) :: Frame?
	local bannerText = botBanner and botBanner:WaitForChild("BannerText", 5) :: TextLabel?

	-- Also find stand sponsor banner if present
	local standBannerPart = lobby:FindFirstChild("Decor") and lobby.Decor:FindFirstChild("Banners") and lobby.Decor.Banners:FindFirstChild("MainBanner_Top") :: BasePart?
	local standBannerGui = standBannerPart and standBannerPart:FindFirstChildWhichIsA("SurfaceGui")
	local standBannerText = standBannerGui and standBannerGui:FindFirstChild("BannerText", true) :: TextLabel?

	task.spawn(function()
		local tips = JumbotronConfig.ROTATING_TIPS
		local tipIdx = 1

		while bannerText and bannerText.Parent do
			task.wait(JumbotronConfig.BANNER_ROTATE_INTERVAL_SEC)
			tipIdx = (tipIdx % #tips) + 1
			local nextTip = tips[tipIdx]

			-- Fade out
			local tOut = TweenService:Create(bannerText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			})
			tOut:Play()
			if standBannerText then
				TweenService:Create(standBannerText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				}):Play()
			end
			tOut.Completed:Wait()

			bannerText.Text = nextTip
			if standBannerText then standBannerText.Text = nextTip end

			-- Fade in
			local tIn = TweenService:Create(bannerText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 0,
				TextStrokeTransparency = 0,
			})
			tIn:Play()
			if standBannerText then
				TweenService:Create(standBannerText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					TextTransparency = 0,
					TextStrokeTransparency = 0,
				}):Play()
			end
		end
	end)
end

task.spawn(initJumbotronClient)
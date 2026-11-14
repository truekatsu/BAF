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
	if not configFolder then return end

	-- 1. LEFT PANEL: Latest Winner (Moved from Center Panel)
	local leftPanel = root:WaitForChild("LeftPanel", 5) :: Frame?
	local leftHeader = leftPanel and leftPanel:WaitForChild("HeaderFrame", 5) :: Frame?
	local leftHeaderLbl = leftHeader and leftHeader:WaitForChild("HeaderLabel", 5) :: TextLabel?
	local leftContent = leftPanel and leftPanel:WaitForChild("WinnerContent", 5) :: Frame?
	local leftAvatar = leftContent and leftContent:WaitForChild("AvatarImage", 5) :: ImageLabel?
	local leftName = leftContent and leftContent:WaitForChild("WinnerName", 5) :: TextLabel?
	local leftScore = leftContent and leftContent:WaitForChild("WonScore", 5) :: TextLabel?
	local leftBadge = leftContent and leftContent:WaitForChild("GradeBadge", 5) :: Frame?
	local leftBadgeLbl = leftBadge and leftBadge:WaitForChild("GradeLabel", 5) :: TextLabel?

	local function updateLeftWinner()
		if not (leftHeaderLbl and leftName and leftScore and leftAvatar and leftBadge and leftBadgeLbl) then
			return
		end
		leftHeaderLbl.Text = "🏆 LATEST WINNER"

		local rawName = configFolder:GetAttribute("LatestWinnerName")
		local uid = tonumber(configFolder:GetAttribute("LatestWinnerUserId")) or 0
		local score = tonumber(configFolder:GetAttribute("LatestWinnerScore")) or 0
		local prize = tostring(configFolder:GetAttribute("LatestWinnerPrize") or "MYTHIC PACK")

		if typeof(rawName) == "string" and #rawName > 0 and uid ~= 0 and rawName ~= "BOT" then
			leftName.Text = rawName
			leftScore.Text = string.format("WON %s (%.1f)", prize, score)
			leftBadgeLbl.Text = "MATCH WINNER"
			leftBadge.BackgroundColor3 = Color3.fromHex("#E5252A")
			leftBadge.Visible = true
			leftAvatar.Image = if uid > 0 then `rbxthumb://type=AvatarHeadShot&id={uid}&w=150&h=150` else ""
		else
			leftName.Text = "EMPTY"
			leftScore.Text = "---"
			leftBadge.Visible = false
			leftAvatar.Image = ""
		end
	end

	updateLeftWinner()
	configFolder.AttributeChanged:Connect(function(attr)
		if string.sub(attr, 1, 12) == "LatestWinner" then
			updateLeftWinner()
		end
	end)

	-- 2. CENTER PANEL: 8s Auto-Rotation Social Proof (Top Player Today -> Top Cash Today -> Rarest Pull)
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

		-- Slide 1: Top Player Today
		local topName = configFolder:GetAttribute("TopPlayerName")
		local topUid = tonumber(configFolder:GetAttribute("TopPlayerUserId")) or 0
		local topWins = tonumber(configFolder:GetAttribute("TopPlayerWins")) or 0
		local hasTopWins = typeof(topName) == "string" and #topName > 0 and topWins > 0
		table.insert(slides, {
			header = "👑 TOP PLAYER TODAY",
			name = if hasTopWins then tostring(topName) else "EMPTY",
			userId = if hasTopWins then topUid else 0,
			subtitle = if hasTopWins then string.format("%d Wins Today", topWins) else "---",
			badgeText = if hasTopWins then "RANK #1 WINS" else "",
			badgeColor = Color3.fromHex("#F59E0B"),
		})

		-- Slide 2: Top Cash Today
		local cashName = configFolder:GetAttribute("TopCashName")
		local cashUid = tonumber(configFolder:GetAttribute("TopCashUserId")) or 0
		local cashAmt = tonumber(configFolder:GetAttribute("TopCashAmount")) or 0
		local hasTopCash = typeof(cashName) == "string" and #cashName > 0 and cashAmt > 0
		table.insert(slides, {
			header = "💵 TOP CASH TODAY",
			name = if hasTopCash then tostring(cashName) else "EMPTY",
			userId = if hasTopCash then cashUid else 0,
			subtitle = if hasTopCash then string.format("$%s Bux", tostring(cashAmt)) else "---",
			badgeText = if hasTopCash then "RICHEST" else "",
			badgeColor = Color3.fromHex("#22C55E"),
		})

		-- Slide 3: Rarest Pull
		local pullName = configFolder:GetAttribute("RarestPullName")
		local pullUid = tonumber(configFolder:GetAttribute("RarestPullUserId")) or 0
		local pullCard = configFolder:GetAttribute("RarestPullCard")
		local hasPull = typeof(pullName) == "string" and #pullName > 0 and typeof(pullCard) == "string" and #pullCard > 0
		table.insert(slides, {
			header = "✨ RAREST PULL",
			name = if hasPull then tostring(pullName) else "EMPTY",
			userId = if hasPull then pullUid else 0,
			subtitle = if hasPull then tostring(pullCard) else "---",
			badgeText = if hasPull then "MYTHIC PULL" else "",
			badgeColor = Color3.fromHex("#A855F7"),
		})

		return slides
	end

	local currentCenterIdx = 1
	local function applyCenterSlide(slide: SocialSlide)
		if not (centerHeaderLbl and winnerNameLbl and wonScoreLbl and avatarImg and gradeLbl and gradeBadge) then
			return
		end
		centerHeaderLbl.Text = slide.header
		winnerNameLbl.Text = slide.name
		wonScoreLbl.Text = slide.subtitle
		if #slide.badgeText > 0 then
			gradeLbl.Text = slide.badgeText
			gradeBadge.BackgroundColor3 = slide.badgeColor
			gradeBadge.Visible = true
		else
			gradeBadge.Visible = false
		end
		avatarImg.Image = if slide.userId > 0 then `rbxthumb://type=AvatarHeadShot&id={slide.userId}&w=150&h=150` else ""
	end

	configFolder.AttributeChanged:Connect(function(attr)
		if string.sub(attr, 1, 9) == "TopPlayer" or string.sub(attr, 1, 7) == "TopCash" or string.sub(attr, 1, 10) == "RarestPull" then
			local slides = getSocialSlides()
			local current = slides[((currentCenterIdx - 1) % #slides) + 1]
			if current then
				applyCenterSlide(current)
			end
		end
	end)

	-- Center auto-rotation loop (8s)
	task.spawn(function()
		local slideIdx = 1
		while winnerContent and winnerContent.Parent do
			local slides = getSocialSlides()
			if #slides > 0 then
				currentCenterIdx = slideIdx
				local current = slides[((slideIdx - 1) % #slides) + 1]

				-- Smooth crossfade
				if centerHeaderLbl and winnerNameLbl and wonScoreLbl and avatarImg and gradeLbl and gradeBadge then
					local fadeOut = TweenService:Create(winnerContent, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0.5,
					})
					fadeOut:Play()
					fadeOut.Completed:Wait()

					applyCenterSlide(current)

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
	local activeBadge = (rightPanel and (rightPanel:FindFirstChild("ActiveBadge", true) or rightPanel:WaitForChild("ActiveBadge", 5))) :: Frame?
	local activeLbl = (activeBadge and (activeBadge:FindFirstChild("BadgeLabel") or activeBadge:WaitForChild("BadgeLabel", 5))) :: TextLabel?
	local slideBox = rightPanel and rightPanel:WaitForChild("SlideBox", 5) :: Frame?
	local slideTitle = slideBox and slideBox:WaitForChild("SlideTitle", 5) :: TextLabel?
	local slideSub = slideBox and slideBox:WaitForChild("SlideSubtitle", 5) :: TextLabel?
	local eventTimerLbl = slideBox and slideBox:WaitForChild("EventTimerLabel", 5) :: TextLabel?

	task.spawn(function()
		while eventTimerLbl and eventTimerLbl.Parent do
			local now = Workspace:GetServerTimeNow()
			local endsAt = tonumber(configFolder:GetAttribute("EventEndsAt"))
			local attrActive = configFolder:GetAttribute("EventActive")
			local isActive: boolean
			local rem: number
			if endsAt ~= nil and typeof(attrActive) == "boolean" then
				isActive = attrActive
				rem = endsAt - now
			else
				local fallback = JumbotronConfig.getWeekendEventState(math.floor(now))
				isActive = fallback.active
				rem = fallback.remainingSec
			end

			local eventName = tostring(configFolder:GetAttribute("EventName") or "2X WINS WEEKEND")
			local eventSub = tostring(configFolder:GetAttribute("EventSubtitle") or (if isActive then "Double wins on all tables this weekend!" else "Double wins on all tables every weekend!"))

			if slideTitle then slideTitle.Text = eventName end
			if slideSub then slideSub.Text = eventSub end

			if isActive and rem > 0 then
				if activeBadge then activeBadge.BackgroundColor3 = Color3.fromHex("#22C55E") end
				if activeLbl then activeLbl.Text = "ACTIVE" end
				eventTimerLbl.Text = `ENDS IN {formatTime(rem)}`
				eventTimerLbl.TextColor3 = Color3.fromHex("#38BDF8")
			else
				if activeBadge then activeBadge.BackgroundColor3 = Color3.fromHex("#64748B") end
				if activeLbl then activeLbl.Text = "INACTIVE" end
				eventTimerLbl.Text = `STARTS IN {formatTime(math.max(0, rem))}`
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
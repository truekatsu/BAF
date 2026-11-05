--!strict
--[[
	MatchLogic
	Responsibility: Pure rules for rolling, placing, stealing, shuffling, bot decisions, and showdown scoring.
	Loop step: action | reward
	Location: ReplicatedStorage/Shared/MatchLogic (ModuleScript)
]]

local GameConfig = require(script.Parent.GameConfig)
local Footballers = require(script.Parent.Footballers)

export type AttributeKey = GameConfig.AttributeKey
export type Rarity = GameConfig.Rarity
export type Grade = GameConfig.Grade
export type Footballer = Footballers.Footballer

export type BoardState = {
	slots: { [AttributeKey]: Footballer? },
	currentRoll: Footballer?,
	rerollsLeft: number,
	stealsLeft: number,
	luck: number,
	infRerolls: boolean,
	revealedAll: boolean,
	bestHint: AttributeKey?,
}

export type BoardEvaluation = {
	slotScores: { [AttributeKey]: number },
	totalScore: number,
	avgScore: number,
	grade: Grade,
}

export type ShowdownResult = {
	evalA: BoardEvaluation,
	evalB: BoardEvaluation,
	winner: "A" | "B",
	tiebreaker: { cardA: Footballer, cardB: Footballer }?,
}

local MatchLogic = {}

local function isValidAttribute(attr: string): boolean
	return table.find(GameConfig.ATTRIBUTES, attr :: AttributeKey) ~= nil
end

function MatchLogic.rollRarity(luck: number, rng: Random?): Rarity
	local randomGen = rng or Random.new()
	local clampedLuck = math.clamp(luck, 1, 10)
	local weights: { [Rarity]: number } = {
		Common = GameConfig.RARITY_WEIGHTS.Common,
		Rare = GameConfig.RARITY_WEIGHTS.Rare,
		Epic = GameConfig.RARITY_WEIGHTS.Epic * clampedLuck,
		Legendary = GameConfig.RARITY_WEIGHTS.Legendary * clampedLuck,
		Mythic = GameConfig.RARITY_WEIGHTS.Mythic * clampedLuck,
	}

	local total = 0
	for _, r in GameConfig.RARITY_ORDER do
		total += weights[r]
	end

	local pick = randomGen:NextNumber(0, total)
	local acc = 0
	for _, r in GameConfig.RARITY_ORDER do
		acc += weights[r]
		if pick <= acc then
			return r
		end
	end
	return "Common"
end

function MatchLogic.rollFootballer(luck: number, rng: Random?): Footballer
	local randomGen = rng or Random.new()
	local rarity = MatchLogic.rollRarity(luck, randomGen)
	local bucket = Footballers.ByRarity[rarity]
	if not bucket or #bucket == 0 then
		bucket = Footballers.All
	end
	return bucket[randomGen:NextInteger(1, #bucket)]
end

function MatchLogic.createBoard(rerolls: number, steals: number, luck: number, infRerolls: boolean, rng: Random?): BoardState
	local randomGen = rng or Random.new()
	return {
		slots = {},
		currentRoll = MatchLogic.rollFootballer(luck, randomGen),
		rerollsLeft = rerolls,
		stealsLeft = steals,
		luck = luck,
		infRerolls = infRerolls,
		revealedAll = false,
		bestHint = nil,
	}
end

function MatchLogic.getEmptySlots(board: BoardState): { AttributeKey }
	local empty: { AttributeKey } = {}
	for _, attr in GameConfig.ATTRIBUTES do
		if board.slots[attr] == nil then
			table.insert(empty, attr)
		end
	end
	return empty
end

function MatchLogic.isBoardFull(board: BoardState): boolean
	return #MatchLogic.getEmptySlots(board) == 0
end

function MatchLogic.getBestSlot(board: BoardState, card: Footballer?): AttributeKey?
	local target = card or board.currentRoll
	if not target then
		return nil
	end
	local bestAttr: AttributeKey? = nil
	local bestVal = -1
	for _, attr in MatchLogic.getEmptySlots(board) do
		local val = (target.stats :: any)[attr] :: number
		if val > bestVal then
			bestVal = val
			bestAttr = attr
		end
	end
	return bestAttr
end

function MatchLogic.placeInSlot(board: BoardState, attr: AttributeKey, rng: Random?): boolean
	if not isValidAttribute(attr) or board.slots[attr] ~= nil or board.currentRoll == nil then
		return false
	end
	board.slots[attr] = board.currentRoll
	board.bestHint = nil
	if MatchLogic.isBoardFull(board) then
		board.currentRoll = nil
	else
		board.currentRoll = MatchLogic.rollFootballer(board.luck, rng)
	end
	return true
end

function MatchLogic.reroll(board: BoardState, rng: Random?): boolean
	if MatchLogic.isBoardFull(board) then
		return false
	end
	if not board.infRerolls and board.rerollsLeft <= 0 then
		return false
	end
	if not board.infRerolls then
		board.rerollsLeft -= 1
	end
	board.bestHint = nil
	board.currentRoll = MatchLogic.rollFootballer(board.luck, rng)
	return true
end

function MatchLogic.stealSlot(thief: BoardState, victim: BoardState, targetAttr: AttributeKey, destAttr: AttributeKey?, rng: Random?): boolean
	local toAttr: AttributeKey = destAttr or targetAttr
	if thief.stealsLeft <= 0 then
		return false
	end
	if not isValidAttribute(targetAttr) or not isValidAttribute(toAttr) then
		return false
	end
	local stolenCard = victim.slots[targetAttr]
	if not stolenCard or thief.slots[toAttr] ~= nil then
		return false
	end

	thief.stealsLeft -= 1
	victim.slots[targetAttr] = nil
	if victim.currentRoll == nil then
		victim.currentRoll = MatchLogic.rollFootballer(victim.luck, rng)
	end

	thief.slots[toAttr] = stolenCard
	thief.bestHint = nil
	if MatchLogic.isBoardFull(thief) then
		thief.currentRoll = nil
	end
	return true
end

function MatchLogic.shuffleSlots(board: BoardState, rng: Random?): boolean
	local randomGen = rng or Random.new()
	local filledAttrs: { AttributeKey } = {}
	local cards: { Footballer } = {}
	for _, attr in GameConfig.ATTRIBUTES do
		local c = board.slots[attr]
		if c then
			table.insert(filledAttrs, attr)
			table.insert(cards, c)
		end
	end
	if #filledAttrs < 2 then
		return false
	end
	for i = #cards, 2, -1 do
		local j = randomGen:NextInteger(1, i)
		cards[i], cards[j] = cards[j], cards[i]
	end
	for idx, attr in filledAttrs do
		board.slots[attr] = cards[idx]
	end
	return true
end

function MatchLogic.autoFillRemaining(board: BoardState, rng: Random?)
	local randomGen = rng or Random.new()
	for _, attr in MatchLogic.getEmptySlots(board) do
		local card = board.currentRoll or MatchLogic.rollFootballer(board.luck, randomGen)
		board.slots[attr] = card
		board.currentRoll = nil
	end
end

function MatchLogic.stepBot(bot: BoardState, human: BoardState, rng: Random?)
	if MatchLogic.isBoardFull(bot) then
		return
	end
	local randomGen = rng or Random.new()

	if bot.stealsLeft > 0 and GameConfig.BOT_STEAL_CHANCE > 0 and randomGen:NextNumber() < GameConfig.BOT_STEAL_CHANCE then
		for _, attr in MatchLogic.getEmptySlots(bot) do
			local humanCard = human.slots[attr]
			if humanCard and (humanCard.stats :: any)[attr] >= 84 then
				if MatchLogic.stealSlot(bot, human, attr, attr, randomGen) then
					return
				end
			end
		end
	end

	local empty = MatchLogic.getEmptySlots(bot)
	if #empty == 0 then
		return
	end
	local chosenAttr: AttributeKey
	if randomGen:NextNumber() < GameConfig.BOT_OPTIMAL_CHANCE then
		chosenAttr = MatchLogic.getBestSlot(bot, bot.currentRoll) or empty[1]
	else
		chosenAttr = empty[randomGen:NextInteger(1, #empty)]
	end
	MatchLogic.placeInSlot(bot, chosenAttr, randomGen)
end

function MatchLogic.evaluateBoard(board: BoardState): BoardEvaluation
	local slotScores: { [AttributeKey]: number } = {} :: any
	local total = 0
	for _, attr in GameConfig.ATTRIBUTES do
		local card = board.slots[attr]
		local val = if card then (card.stats :: any)[attr] :: number else 0
		slotScores[attr] = val
		total += val
	end
	local avg = math.round((total / #GameConfig.ATTRIBUTES) * 10) / 10
	return {
		slotScores = slotScores,
		totalScore = total,
		avgScore = avg,
		grade = GameConfig.getGrade(avg),
	}
end

function MatchLogic.resolveShowdown(boardA: BoardState, boardB: BoardState, rng: Random?): ShowdownResult
	local randomGen = rng or Random.new()
	MatchLogic.autoFillRemaining(boardA, randomGen)
	MatchLogic.autoFillRemaining(boardB, randomGen)

	local evalA = MatchLogic.evaluateBoard(boardA)
	local evalB = MatchLogic.evaluateBoard(boardB)

	if evalA.totalScore > evalB.totalScore then
		return { evalA = evalA, evalB = evalB, winner = "A", tiebreaker = nil }
	elseif evalB.totalScore > evalA.totalScore then
		return { evalA = evalA, evalB = evalB, winner = "B", tiebreaker = nil }
	end

	local cardA = MatchLogic.rollFootballer(boardA.luck, randomGen)
	local cardB = MatchLogic.rollFootballer(boardB.luck, randomGen)
	local winner: "A" | "B" = if cardA.ovr >= cardB.ovr then "A" else "B"
	return {
		evalA = evalA,
		evalB = evalB,
		winner = winner,
		tiebreaker = { cardA = cardA, cardB = cardB },
	}
end

return table.freeze(MatchLogic)


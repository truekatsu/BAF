import json

with open('scratch/exact_old_string.txt', 'r', encoding='utf-8') as f:
    old_apply = f.read()

new_apply = """local function applyChairSkin(tableModel: Model, seatName: string, player: Player?)
	local profile = if player then ProfileService.get(player) else nil
	local skin = GameConfig.getChairSkin(if profile then profile.EquippedChair else "wood")
	local seat = tableModel:FindFirstChild(seatName) :: Seat?
	if not seat then return end

	local oldDecor = tableModel:FindFirstChild(seatName .. "_Decor")
	if oldDecor then
		oldDecor:Destroy()
	end

	local isWood = (skin.id == "wood")
	local isStadium = (skin.id == "stadium")
	local isMesh = not isWood and not isStadium

	for _, child in tableModel:GetChildren() do
		if child:IsA("BasePart") then
			if child.Name == seatName then
				child.Transparency = if isWood then 0 else 1
				child.Color = skin.color
				child.Material = skin.mat
			elseif string.find(child.Name, `^{seatName}_Leg`) ~= nil or string.find(child.Name, `^{seatName}_Back`) ~= nil then
				child.Transparency = if isWood then 0 else 1
				child.Color = skin.color
				child.Material = skin.mat
			end
		end
	end

	if isStadium then
		local decor = ChairModelBuilder.buildStadiumChair()
		decor.Name = seatName .. "_Decor"
		local floorY = seat.Position.Y - 1.6
		local decorCF = CFrame.lookAt(Vector3.new(seat.Position.X, floorY, seat.Position.Z), Vector3.new(seat.Position.X, floorY, seat.Position.Z) + seat.CFrame.LookVector)
		decor:PivotTo(decorCF)
		decor.Parent = tableModel
	elseif isMesh then
		local floorY = seat.Position.Y - 1.6
		local decorCF = CFrame.lookAt(Vector3.new(seat.Position.X, floorY, seat.Position.Z), Vector3.new(seat.Position.X, floorY, seat.Position.Z) + seat.CFrame.LookVector)
		local decor = ChairModelBuilder.buildMeshChair(skin.id, decorCF, false)
		decor.Name = seatName .. "_Decor"
		decor.Parent = tableModel
	end
end
"""

# Strip trailing newline if needed to match exact end
if old_apply.endswith('\n') and not new_apply.endswith('\n'):
    new_apply += '\n'

args = {
    'studio_id': '649a33bb-29a0-415b-a167-51eaf7f9f85f',
    'datamodel_type': 'Edit',
    'file_path': 'game.ServerScriptService.Server.MatchService',
    'edits': [
        {
            'old_string': 'local ProfileService = require(script.Parent.ProfileService)',
            'new_string': 'local ProfileService = require(script.Parent.ProfileService)\nlocal ChairModelBuilder = require(ReplicatedStorage:WaitForChild("Prefabs"):WaitForChild("ChairModelBuilder"))'
        },
        {
            'old_string': old_apply,
            'new_string': new_apply
        }
    ]
}

with open('scratch/multi_edit_args.json', 'w', encoding='utf-8') as out:
    json.dump(args, out)

print('Generated scratch/multi_edit_args.json successfully!')

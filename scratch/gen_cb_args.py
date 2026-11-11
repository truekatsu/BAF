import json

path = r'd:\BAF\src\ReplicatedStorage\Prefabs\ChairModelBuilder.luau'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read().replace('\r\n', '\n')

idx = text.find('-- Constructs the stylized Cyber Core Chair model')
addition = text[idx:]

old_str = "ChairModelBuilder.buildCrimsonChair = ChairModelBuilder.buildCrimsonFlameChair\nChairModelBuilder.buildCrimson = ChairModelBuilder.buildCrimsonFlameChair\n\nreturn ChairModelBuilder"

args = {
    "studio_id": "d4b5150f-b416-44a9-af38-ab450d8935e5",
    "datamodel_type": "Edit",
    "file_path": "game.ReplicatedStorage.Prefabs.ChairModelBuilder",
    "edits": [
        {
            "old_string": old_str,
            "new_string": addition.strip() + "\n",
            "replace_all": False
        }
    ]
}

with open(r'd:\BAF\scratch\chair_builder_args.json', 'w', encoding='utf-8') as f:
    json.dump(args, f)

print(f"Generated chair_builder_args.json, new_string size: {len(addition)} chars")

import bpy
import os

blend_files = [
    r"d:\BAF\models\Stadium_Chair.blend",
    r"d:\BAF\models\CyberCoreChair.blend",
    r"d:\BAF\models\CrimsonFlameChair.blend",
    r"d:\BAF\models\FrostbiteIceThrone.blend",
    r"d:\BAF\models\RoyalFootballThrone.blend"
]

for bf in blend_files:
    print(f"\n==================== {os.path.basename(bf)} ====================")
    bpy.ops.wm.open_mainfile(filepath=bf)
    for o in bpy.data.objects:
        p_name = o.parent.name if o.parent else "None"
        mat_names = [s.material.name for s in o.material_slots if s.material]
        print(f"[{o.type}] {o.name} | Parent: {p_name} | Mats: {mat_names}")

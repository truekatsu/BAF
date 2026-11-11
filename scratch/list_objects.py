import bpy
import sys
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
        if o.type == 'MESH':
            print(f"  {o.name} (parent: {o.parent.name if o.parent else 'None'})")
        elif o.type == 'EMPTY':
            print(f"  EMPTY: {o.name}")

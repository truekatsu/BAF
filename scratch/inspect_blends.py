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
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    print(f"Total mesh objects: {len(meshes)}")
    total_verts = sum(len(m.data.vertices) for m in meshes)
    total_faces = sum(len(m.data.polygons) for m in meshes)
    print(f"Total verts: {total_verts}, total faces: {total_faces}")
    mats = set()
    for o in meshes:
        for slot in o.material_slots:
            if slot.material:
                mats.add(slot.material.name)
    print(f"Materials ({len(mats)}): {list(mats)}")

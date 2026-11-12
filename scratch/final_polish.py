import bpy
import math
from mathutils import Vector

def final_polish():
    bpy.ops.wm.open_mainfile(filepath="d:/BAF/models/vip_chair.blend")

    # 1. Fix VIP text to read cleanly from left to right
    text_obj = bpy.data.objects.get("VIP_Text")
    plate_obj = bpy.data.objects.get("VIP_Plate")
    if text_obj and plate_obj:
        text_obj.location = (0, plate_obj.location.y - 0.022, plate_obj.location.z)
        text_obj.rotation_euler = (math.radians(90), 0, 0)
        text_obj.scale = (1.0, 1.0, 1.0)

    # 2. Camera: Give generous breathing room above the glowing diamond
    cam = bpy.data.objects.get("Camera_Main")
    if cam:
        cam.location = Vector((2.95, -4.60, 2.05))
        target = Vector((0.0, 0.0, 1.15))
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()

    # 3. Remove floating wire stitch curves that clutter the silhouette
    for stitch_name in ["Backrest_Stitch", "Seat_Stitch", "ArmStitch_L", "ArmStitch_R"]:
        obj = bpy.data.objects.get(stitch_name)
        if obj:
            bpy.data.objects.remove(obj, do_unlink=True)

    # 4. Save clean blend file
    bpy.context.view_layer.update()
    bpy.ops.wm.save_mainfile(filepath="d:/BAF/models/vip_chair.blend")
    print("Saved final vip_chair.blend")

    # 5. Export clean FBX and GLB for game use
    chair_root = bpy.data.objects.get("VIPChair")
    if chair_root:
        bpy.ops.object.select_all(action='DESELECT')
        # Select all chair collection objects
        col = bpy.data.collections.get("Chair")
        if col:
            for o in col.objects:
                o.select_set(True)
        bpy.context.view_layer.objects.active = chair_root

        # Export FBX
        fbx_path = "d:/BAF/models/BlackDiamondVIPChair.fbx"
        bpy.ops.export_scene.fbx(
            filepath=fbx_path,
            use_selection=True,
            global_scale=1.0,
            apply_unit_scale=True,
            apply_scale_options='FBX_SCALE_ALL',
            bake_space_transform=True,
            object_types={'MESH', 'EMPTY'},
            mesh_smooth_type='FACE'
        )
        print(f"Exported {fbx_path}")

        # Export GLB
        glb_path = "d:/BAF/models/BlackDiamondVIPChair.glb"
        bpy.ops.export_scene.gltf(
            filepath=glb_path,
            use_selection=True,
            export_format='GLB',
            export_apply=True
        )
        print(f"Exported {glb_path}")

if __name__ == "__main__":
    final_polish()

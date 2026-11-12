import bpy
import math
from mathutils import Vector

def get_action_fcurves(action):
    if not action:
        return []
    if hasattr(action, "fcurves") and action.fcurves:
        return list(action.fcurves)
    fcurves = []
    if hasattr(action, "layers"):
        for layer in action.layers:
            for strip in layer.strips:
                if hasattr(strip, "channelbags"):
                    for cb in strip.channelbags:
                        if hasattr(cb, "fcurves"):
                            fcurves.extend(list(cb.fcurves))
    return fcurves

def refine_vip_chair():
    bpy.ops.wm.open_mainfile(filepath="d:/BAF/models/vip_chair.blend")

    # 1. Nest Diamond & Bezel snugly in the top crown of Backrest
    dia = bpy.data.objects.get("Gem_Diamond")
    bezel = bpy.data.objects.get("Gem_Bezel")
    if dia:
        dia.location = (0, 0.40, 1.95)
        dia.scale = (1.2, 1.2, 1.2)
        if dia.animation_data and dia.animation_data.action:
            for fc in get_action_fcurves(dia.animation_data.action):
                if fc.data_path == "location" and fc.array_index == 2:
                    for kp in fc.keyframe_points:
                        if kp.co[0] >= 91:
                            kp.co[1] = 1.95 + (0.015 if (kp.co[0] - 91) % 120 == 60 else 0.0)

    if bezel:
        bezel.location = (0, 0.39, 1.88)
        bezel.scale = (1.15, 1.15, 1.15)

    # 2. Adjust Camera for perfect framing
    cam = bpy.data.objects.get("Camera_Main")
    if cam:
        cam.location = Vector((2.85, -4.40, 1.95))
        target = Vector((0.0, 0.0, 1.12))
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()

    # 3. Fix VIP text rotation and forward extrusion
    text_obj = bpy.data.objects.get("VIP_Text")
    plate_obj = bpy.data.objects.get("VIP_Plate")
    if text_obj and plate_obj:
        text_obj.location = (0, plate_obj.location.y - 0.024, plate_obj.location.z)
        text_obj.rotation_euler = (math.radians(90), 0, math.radians(180))
        text_obj.scale = (1.0, 1.0, 1.0)

    # 4. Flush stitch lines against cushions
    st_b = bpy.data.objects.get("Backrest_Stitch")
    bp = bpy.data.objects.get("Backrest_TuftedPanel")
    if st_b and bp:
        st_b.location = (bp.location.x, bp.location.y - 0.042, bp.location.z)

    st_s = bpy.data.objects.get("Seat_Stitch")
    sc = bpy.data.objects.get("Seat_Cushion")
    if st_s and sc:
        st_s.location = (sc.location.x, sc.location.y, sc.location.z + 0.082)

    # 5. Position debossed Crown + Football emblem
    emb = bpy.data.objects.get("Emblem_CrownFootball")
    if emb and bp:
        emb.location = (0, bp.location.y - 0.045, bp.location.z + 0.32)

    # 6. Increase button size so they gleam like gold studs
    for o in bpy.data.objects:
        if "Btn" in o.name:
            o.scale = (1.30, 1.30, 1.30)

    bpy.context.view_layer.update()
    bpy.ops.wm.save_mainfile(filepath="d:/BAF/models/vip_chair.blend")
    print("Saved refined vip_chair.blend successfully")

if __name__ == "__main__":
    refine_vip_chair()

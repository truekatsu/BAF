import bpy
import math
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath="d:/BAF/models/vip_chair.blend")

# 1. Camera adjustment to frame full chair (including top diamond)
cam = bpy.data.objects.get("Camera_Main")
if cam:
    cam.location = Vector((2.70, -3.90, 2.10))
    target = Vector((0.0, 0.0, 1.15))
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()

# 2. Refine Leather material to be deeper black with richer tufts
mat_l = bpy.data.materials.get("M_Leather_Black")
if mat_l and mat_l.use_nodes:
    bsdf = mat_l.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.012, 0.012, 0.016, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.38
        if "Coat Weight" in bsdf.inputs:
            bsdf.inputs["Coat Weight"].default_value = 0.25
        if "Coat Roughness" in bsdf.inputs:
            bsdf.inputs["Coat Roughness"].default_value = 0.20

# 3. Ensure VIP text faces front
text_obj = bpy.data.objects.get("VIP_Text")
plate_obj = bpy.data.objects.get("VIP_Plate")
if text_obj and plate_obj:
    text_obj.location = (plate_obj.location.x, plate_obj.location.y - 0.022, plate_obj.location.z)
    text_obj.rotation_euler = (math.radians(90), 0, math.radians(180))

# 4. Save and render
bpy.ops.wm.save_mainfile(filepath="d:/BAF/models/vip_chair.blend")
scene = bpy.context.scene
scene.cycles.samples = 64
scene.render.filepath = "d:/BAF/models/previews/vip_chair_framed.png"
bpy.ops.render.render(write_still=True)
print("Rendered vip_chair_framed")

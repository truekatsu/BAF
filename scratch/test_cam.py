import bpy
import math

bpy.ops.wm.open_mainfile(filepath="d:/BAF/models/vip_chair.blend")

cam = bpy.data.objects.get("Camera_Main")
if cam:
    cam.location = (2.20, 3.20, 1.85)
    cam.rotation_euler = (math.radians(112), 0, math.radians(142))

scene = bpy.context.scene
scene.cycles.samples = 32  # fast test preview
scene.render.filepath = "d:/BAF/models/previews/test_front_view.png"
bpy.ops.render.render(write_still=True)
print("Rendered front test")

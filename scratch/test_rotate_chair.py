import bpy
import math
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath="d:/BAF/models/vip_chair.blend")

chair = bpy.data.objects.get("VIPChair")
if chair:
    chair.rotation_euler.z = math.radians(180)
    bpy.context.view_layer.update()

cam = bpy.data.objects.get("Camera_Main")
if cam:
    cam.location = Vector((2.20, -3.20, 1.85))
    target = Vector((0.0, 0.0, 1.05))
    direction = target - cam.location
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

scene = bpy.context.scene
scene.cycles.samples = 64
scene.render.filepath = "d:/BAF/models/previews/test_front_34.png"
bpy.ops.render.render(write_still=True)
print("Rendered front 3/4 test")

import bpy
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath="d:/BAF/models/vip_chair.blend")

cam = bpy.data.objects.get("Camera_Main")
if cam:
    cam.location = Vector((2.20, -3.20, 1.85))
    target = Vector((0.0, 0.0, 1.0))
    direction = target - cam.location
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

scene = bpy.context.scene
scene.cycles.samples = 32
scene.render.filepath = "d:/BAF/models/previews/test_aim.png"
bpy.ops.render.render(write_still=True)
print("Rendered test_aim")

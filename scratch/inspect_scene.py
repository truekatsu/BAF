import bpy

bpy.context.scene.frame_set(1)
print("=== OBJECTS AT FRAME 1 ===")
for o in bpy.data.objects:
    pname = o.parent.name if o.parent else "None"
    loc = [round(v, 3) for v in o.matrix_world.translation]
    rot = [round(v, 2) for v in o.matrix_world.to_euler()]
    print(f"{o.name:32} parent={pname:22} loc={loc} rot={rot}")

bpy.context.scene.frame_set(120)
print("\n=== OBJECTS AT FRAME 120 ===")
for o in bpy.data.objects:
    pname = o.parent.name if o.parent else "None"
    loc = [round(v, 3) for v in o.matrix_world.translation]
    rot = [round(v, 2) for v in o.matrix_world.to_euler()]
    print(f"{o.name:32} parent={pname:22} loc={loc} rot={rot}")

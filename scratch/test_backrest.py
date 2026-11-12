import bpy
import bmesh
import math

bpy.ops.wm.read_factory_settings(use_empty=True)

def make_backrest_frame(name, width=1.0, height=1.4, depth=0.14, border=0.10, chamfer=0.14):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    
    # Scale cube to width, depth, height
    for v in bm.verts:
        v.co.x *= width
        v.co.y *= depth
        v.co.z *= height
    
    # Chamfer top left and top right edges (parallel to Y axis)
    top_edges = []
    for e in bm.edges:
        v1, v2 = e.verts
        if abs(v1.co.z - height*0.5) < 0.001 and abs(v2.co.z - height*0.5) < 0.001:
            if abs(v1.co.x) > width*0.4 and abs(v2.co.x) > width*0.4:
                top_edges.append(e)
                
    if top_edges:
        bmesh.ops.bevel(bm, geom=top_edges, offset=chamfer, offset_type='OFFSET', segments=1, profile=0.5)
        
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    
    # Add Bevel modifier for rounded chunky aesthetic
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = 0.025
    bev.segments = 3
    bev.harden_normals = True
    
    return obj

obj = make_backrest_frame("Backrest_Frame")
print("Backrest frame created successfully, vertices:", len(obj.data.vertices))

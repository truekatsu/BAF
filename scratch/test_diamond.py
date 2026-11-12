import bpy
import bmesh
import math

bpy.ops.wm.read_factory_settings(use_empty=True)

def make_diamond(name, width=0.28, height=0.22, loc=(0,0,0)):
    bm = bmesh.new()
    segments = 8
    
    table_r = width * 0.35
    table_z = height * 0.40
    
    girdle_r = width * 0.50
    girdle_z = height * 0.05
    
    culet_z = -height * 0.55
    
    # Table vertices
    table_verts = []
    for i in range(segments):
        a = (i / segments) * 2 * math.pi + (math.pi / segments)
        v = bm.verts.new((table_r * math.cos(a), table_r * math.sin(a), table_z))
        table_verts.append(v)
    bm.faces.new(table_verts) # top flat table
    
    # Girdle vertices
    girdle_verts = []
    for i in range(segments):
        a = (i / segments) * 2 * math.pi
        v = bm.verts.new((girdle_r * math.cos(a), girdle_r * math.sin(a), girdle_z))
        girdle_verts.append(v)
        
    # Crown facets (connecting table and girdle)
    for i in range(segments):
        i_next = (i + 1) % segments
        t0 = table_verts[i]
        t1 = table_verts[i_next]
        g0 = girdle_verts[i]
        g1 = girdle_verts[i_next]
        bm.faces.new([t0, g0, t1])
        bm.faces.new([g0, g1, t1])
        
    # Culet vertex
    culet = bm.verts.new((0, 0, culet_z))
    for i in range(segments):
        i_next = (i + 1) % segments
        bm.faces.new([girdle_verts[i], culet, girdle_verts[i_next]])
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    
    obj = bpy.data.objects.new(name, me)
    obj.location = loc
    bpy.context.collection.objects.link(obj)
    
    # Sharp faceted shading
    for f in me.polygons:
        f.use_smooth = False
        
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = 0.003
    bev.segments = 2
    
    return obj

d = make_diamond("Gem_Diamond", 0.28, 0.22, (0, 0, 2.05))
print("Diamond created, polygons:", len(d.data.polygons))

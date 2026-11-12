import bpy
import bmesh

bpy.ops.wm.read_factory_settings(use_empty=True)

def make_tufted_cushion(name, size, nx=4, ny=4, loc=(0,0,0)):
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=nx, y_segments=ny, size=0.5)
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z = size[2] * 0.5
    
    orig_interior = [v for v in bm.verts if not v.is_boundary]
    poke_res = bmesh.ops.poke(bm, faces=bm.faces)
    
    for v in poke_res['verts']:
        v.co.z += size[2] * 0.22
    
    button_coords = []
    for v in orig_interior:
        v.co.z -= size[2] * 0.18
        button_coords.append(v.co.copy())
        
    boundary_edges = [e for e in bm.edges if e.is_boundary]
    ext = bmesh.ops.extrude_edge_only(bm, edges=boundary_edges)
    ext_verts = [v for v in ext['geom'] if isinstance(v, bmesh.types.BMVert)]
    for v in ext_verts:
        v.co.z -= size[2]
        
    bottom_edges = [e for e in ext['geom'] if isinstance(e, bmesh.types.BMEdge) and e.is_boundary]
    bmesh.ops.edgeloop_fill(bm, edges=bottom_edges)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    
    obj = bpy.data.objects.new(name, me)
    obj.location = loc
    bpy.context.collection.objects.link(obj)
    
    sub = obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2
    sub.render_levels = 2
    
    for f in me.polygons:
        f.use_smooth = True
        
    return obj, button_coords

obj, btn_coords = make_tufted_cushion("Seat_Cushion", (0.92, 0.78, 0.16), nx=4, ny=4, loc=(0, 0, 0.70))
print("Cushion created! Polygons:", len(obj.data.polygons), "Buttons:", len(btn_coords))

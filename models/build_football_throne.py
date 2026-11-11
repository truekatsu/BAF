"""
==============================================================================
ROYAL FOOTBALL THRONE - BLENDER 4.x / 5.x PROCEDURAL BUILDER & EXPORTER
==============================================================================
A stylized cartoon game-asset golden throne with a red quilted cushion,
soccer ball emblem inside a gold ring, and a royal crown on top.

Modular hierarchy parented under Empty "RoyalFootballThrone".
Collections: Throne, Effects, Lights, Scene.
Materials: M_Gold_Toon, M_Red_Velvet, M_Red_Gem, M_Dark_Under, M_Ball_White, M_Ball_Black.
Animations: Intro Reveal (1-90) & Seamless Idle Loop (91-330).
Turnaround previews & exports: .blend, .glb, .fbx.
==============================================================================
"""

import sys
import os
import math
import random
import bpy
import bmesh
from mathutils import Vector, Matrix, Euler

# Set deterministic seed
random.seed(11)

# --------------------------------------------------------------------------
# Clean Startup Scene
# --------------------------------------------------------------------------
def clear_scene():
    """Removes all default objects, meshes, collections, and materials."""
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for coll in list(bpy.data.collections):
        bpy.data.collections.remove(coll)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)
    for world in list(bpy.data.worlds):
        bpy.data.worlds.remove(world)

# --------------------------------------------------------------------------
# Collection Helper
# --------------------------------------------------------------------------
def get_or_create_collection(name, parent_coll=None):
    coll = bpy.data.collections.get(name)
    if not coll:
        coll = bpy.data.collections.new(name)
        target = parent_coll or bpy.context.scene.collection
        target.children.link(coll)
    return coll

# --------------------------------------------------------------------------
# Modifier & Shading Helpers
# --------------------------------------------------------------------------
def apply_bevel(obj, width=0.025, segments=3):
    bev = obj.modifiers.new("Bevel", 'BEVEL')
    bev.width = width
    bev.segments = segments
    bev.limit_method = 'ANGLE'
    bev.angle_limit = math.radians(35)
    try:
        bev.harden_normals = True
    except AttributeError:
        pass
    return bev

def shade_auto_smooth(obj, angle_deg=35):
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    limit = math.radians(angle_deg)
    for f in bm.faces:
        f.smooth = True
    for e in bm.edges:
        if len(e.link_faces) == 2:
            e.smooth = e.calc_face_angle(0.0) <= limit
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return obj

def set_socket(node, socket_names, value):
    for s_name in socket_names:
        if s_name in node.inputs:
            try:
                node.inputs[s_name].default_value = value
                return True
            except TypeError:
                pass
    return False

# --------------------------------------------------------------------------
# Materials Setup
# --------------------------------------------------------------------------
def make_material_gold(name="M_Gold_Toon"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (800, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (450, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    # Saturated warm cartoon gold (toy-like vibrant yellow gold)
    bsdf.inputs["Base Color"].default_value = (1.0, 0.80, 0.12, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.98
    bsdf.inputs["Roughness"].default_value = 0.16
    set_socket(bsdf, ["Coat Weight", "Coat"], 0.0)
    
    # Ambient Occlusion node for tight crevice darkening only
    ao = nt.nodes.new("ShaderNodeAmbientOcclusion")
    ao.location = (-300, 100)
    ao.inputs["Distance"].default_value = 0.06 # Only micro-crevices
    
    mix_ao = nt.nodes.new("ShaderNodeMix")
    mix_ao.data_type = 'RGBA'
    mix_ao.location = (150, 100)
    mix_ao.inputs["A"].default_value = (0.78, 0.45, 0.05, 1.0) # Warm amber crevice
    mix_ao.inputs["B"].default_value = (1.0, 0.82, 0.15, 1.0) # Saturated bright gold
    nt.links.new(ao.outputs["Color"], mix_ao.inputs["Factor"])
    nt.links.new(mix_ao.outputs["Result"], bsdf.inputs["Base Color"])
    
    return mat

def make_material_velvet(name="M_Red_Velvet"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (800, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (450, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    # Pure vibrant royal crimson red velvet (#D41424)
    bsdf.inputs["Base Color"].default_value = (0.92, 0.03, 0.06, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.24 # Crisp cartoon finish
    set_socket(bsdf, ["Specular IOR Level", "Specular"], 0.35)
    set_socket(bsdf, ["Coat Weight", "Coat"], 0.0)
    
    return mat

def make_material_gem(name="M_Red_Gem"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (800, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (450, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    # Brilliant ruby gem
    bsdf.inputs["Base Color"].default_value = (0.88, 0.02, 0.05, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.06
    bsdf.inputs["IOR"].default_value = 1.65
    set_socket(bsdf, ["Transmission Weight", "Transmission"], 0.60)
    set_socket(bsdf, ["Emission Color", "Emission"], (0.95, 0.04, 0.08, 1.0))
    set_socket(bsdf, ["Emission Strength"], 1.2)
    
    return mat

def make_material_dark(name="M_Dark_Under"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (200, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    bsdf.inputs["Base Color"].default_value = (0.08, 0.05, 0.05, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    return mat

def make_material_ball(name, is_black=False):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (200, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    if is_black:
        bsdf.inputs["Base Color"].default_value = (0.04, 0.04, 0.05, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.22
    else:
        bsdf.inputs["Base Color"].default_value = (0.96, 0.96, 0.96, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.24
        
    set_socket(bsdf, ["Coat Weight", "Coat"], 0.35)
    set_socket(bsdf, ["Coat Roughness"], 0.10)
    return mat

def make_material_sparkle(name="M_Sparkle"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (200, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    bsdf.inputs["Base Color"].default_value = (1.0, 0.92, 0.55, 1.0)
    set_socket(bsdf, ["Emission Color", "Emission"], (1.0, 0.92, 0.50, 1.0))
    set_socket(bsdf, ["Emission Strength"], 5.0)
    return mat

def make_material_floor(name="M_Shadow_Floor"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (200, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    bsdf.inputs["Base Color"].default_value = (0.07, 0.09, 0.14, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.50
    return mat

# --------------------------------------------------------------------------
# Geometric Builders
# --------------------------------------------------------------------------
def make_block(name, location, size, bevel_width=0.03, bevel_segments=3, coll=None, mat=None, rotation_euler=(0,0,0)):
    bm = bmesh.new()
    rot_m = Euler(rotation_euler, 'XYZ').to_matrix().to_4x4()
    mat_trans = Matrix.Translation(Vector(location)) @ rot_m @ Matrix.Diagonal((size[0]/2, size[1]/2, size[2]/2, 1.0))
    bmesh.ops.create_cube(bm, size=2.0, matrix=mat_trans)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    
    if bevel_width > 0:
        apply_bevel(obj, width=bevel_width, segments=bevel_segments)
    shade_auto_smooth(obj, 35)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_tapered_pillar(name, location, bot_size, top_size, height, bevel_width=0.03, coll=None, mat=None):
    bm = bmesh.new()
    hw_b, hd_b = bot_size[0]*0.5, bot_size[1]*0.5
    hw_t, hd_t = top_size[0]*0.5, top_size[1]*0.5
    
    v0 = bm.verts.new(Vector((-hw_b, -hd_b, 0)))
    v1 = bm.verts.new(Vector(( hw_b, -hd_b, 0)))
    v2 = bm.verts.new(Vector(( hw_b,  hd_b, 0)))
    v3 = bm.verts.new(Vector((-hw_b,  hd_b, 0)))
    
    v4 = bm.verts.new(Vector((-hw_t, -hd_t, height)))
    v5 = bm.verts.new(Vector(( hw_t, -hd_t, height)))
    v6 = bm.verts.new(Vector(( hw_t,  hd_t, height)))
    v7 = bm.verts.new(Vector((-hw_t,  hd_t, height)))
    
    bm.faces.new([v3, v2, v1, v0]) # bottom
    bm.faces.new([v4, v5, v6, v7]) # top
    bm.faces.new([v0, v1, v5, v4]) # front
    bm.faces.new([v1, v2, v6, v5]) # right
    bm.faces.new([v2, v3, v7, v6]) # back
    bm.faces.new([v3, v0, v4, v7]) # left
    
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(location)), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    apply_bevel(obj, width=bevel_width, segments=3)
    shade_auto_smooth(obj, 35)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_diamond_gem(name, location, width=0.20, height=0.28, depth=0.10, coll=None, mat=None, rotation_euler=(0,0,0)):
    bm = bmesh.new()
    hw = width * 0.5
    hh = height * 0.5
    hd = depth * 0.5
    
    v_r = bm.verts.new(Vector(( hw, 0, 0)))
    v_t = bm.verts.new(Vector(( 0, 0,  hh)))
    v_l = bm.verts.new(Vector((-hw, 0, 0)))
    v_b = bm.verts.new(Vector(( 0, 0, -hh)))
    
    v_f = bm.verts.new(Vector((0, -hd, 0)))
    v_k = bm.verts.new(Vector((0,  hd, 0)))
    
    bm.faces.new([v_r, v_t, v_f])
    bm.faces.new([v_t, v_l, v_f])
    bm.faces.new([v_l, v_b, v_f])
    bm.faces.new([v_b, v_r, v_f])
    bm.faces.new([v_t, v_r, v_k])
    bm.faces.new([v_l, v_t, v_k])
    bm.faces.new([v_b, v_l, v_k])
    bm.faces.new([v_r, v_b, v_k])
    
    rot_m = Euler(rotation_euler, 'XYZ').to_matrix().to_4x4()
    mat_trans = Matrix.Translation(Vector(location)) @ rot_m
    bmesh.ops.transform(bm, matrix=mat_trans, verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    apply_bevel(obj, width=0.012, segments=2)
    shade_auto_smooth(obj, 30)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_tufted_panel(name, location, width=0.88, height=1.35, depth=0.10, coll=None, mat_velvet=None, mat_gold=None):
    """
    Creates a diamond-tufted (capitone) quilted velvet cushion panel
    with 9 gold buttons arranged in a clean diamond grid.
    """
    bm = bmesh.new()
    nx = 24
    ny = 36
    hw = width * 0.5
    hh = height * 0.5
    
    step_x = 0.20
    step_y = 0.15
    
    # Diamond tuft puffing across the surface
    for j in range(ny + 1):
        v_y = -hh + (height * j / ny)
        for i in range(nx + 1):
            v_x = -hw + (width * i / nx)
            puff = 0.052 * max(0.0, math.cos(math.pi * v_x / step_x) * math.cos(math.pi * v_y / step_y))
            edge_fac = min(1.0, (hw - abs(v_x)) / 0.05) * min(1.0, (hh - abs(v_y)) / 0.05)
            v_z = puff * edge_fac
            bm.verts.new(Vector((v_x, -v_z, v_y)))
            
    bm.verts.ensure_lookup_table()
    
    for j in range(ny):
        for i in range(nx):
            i0 = j * (nx + 1) + i
            i1 = i0 + 1
            i2 = (j + 1) * (nx + 1) + i + 1
            i3 = (j + 1) * (nx + 1) + i
            bm.faces.new([bm.verts[i0], bm.verts[i1], bm.verts[i2], bm.verts[i3]])
            
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(location)), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    
    sub = obj.modifiers.new("Subsurf", 'SUBSURF')
    sub.levels = 2
    sub.render_levels = 2
    shade_auto_smooth(obj, 45)
    if mat_velvet:
        obj.data.materials.append(mat_velvet)
        
    # 9 gold buttons arranged in the classic capitone diamond layout below the ring
    buttons = []
    btn_coords = [
        # Row 1 (top): center under ring
        ( 0.00,  0.22),
        # Row 2 (mid-high)
        (-0.20,  0.07),
        ( 0.20,  0.07),
        # Row 3 (center)
        (-0.35, -0.08),
        ( 0.00, -0.08),
        ( 0.35, -0.08),
        # Row 4 (mid-low)
        (-0.20, -0.23),
        ( 0.20, -0.23),
        # Row 5 (bottom center)
        ( 0.00, -0.38),
    ]
    for b_idx, (bx, by) in enumerate(btn_coords, 1):
        b_pos = (location[0] + bx, location[1] - 0.015, location[2] + by)
        bm_btn = bmesh.new()
        mat_btn = Matrix.Translation(Vector(b_pos)) @ Matrix.Diagonal((0.034, 0.024, 0.034, 1.0))
        bmesh.ops.create_uvsphere(bm_btn, u_segments=16, v_segments=12, radius=1.0, matrix=mat_btn)
        mesh_btn = bpy.data.meshes.new(f"Button_{b_idx:02d}")
        bm_btn.to_mesh(mesh_btn)
        bm_btn.free()
        mesh_btn.update()
        btn_obj = bpy.data.objects.new(f"Button_{b_idx:02d}", mesh_btn)
        (coll or bpy.context.scene.collection).objects.link(btn_obj)
        shade_auto_smooth(btn_obj, 35)
        if mat_gold:
            btn_obj.data.materials.append(mat_gold)
        buttons.append(btn_obj)
        
    return obj, buttons

def make_soccer_ball(name, location, radius=0.32, coll=None, mat_white=None, mat_black=None):
    """
    Constructs a true truncated icosahedron (classic soccer ball:
    12 regular black pentagons + 20 regular white hexagons).
    """
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
    bmesh.ops.bevel(bm, geom=bm.verts[:], offset=0.3333, offset_type='OFFSET', affect='VERTICES')
    bm.verts.ensure_lookup_table()
    
    for v in bm.verts:
        v.co = v.co.normalized() * radius
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    
    mesh.materials.append(mat_white) # index 0
    mesh.materials.append(mat_black) # index 1
    for poly in mesh.polygons:
        if len(poly.vertices) == 5:
            poly.material_index = 1 # Black pentagon
        else:
            poly.material_index = 0 # White hexagon
            
    obj.location = location
    apply_bevel(obj, width=0.008, segments=2)
    shade_auto_smooth(obj, 35)
    return obj

def make_emblem_ring(name, location, r_out=0.42, r_in=0.34, depth=0.12, coll=None, mat=None):
    bm = bmesh.new()
    segs = 36
    v_out_f, v_in_f = [], []
    v_out_b, v_in_b = [], []
    hd = depth * 0.5
    
    for i in range(segs):
        ang = 2 * math.pi * i / segs
        ca, sa = math.cos(ang), math.sin(ang)
        v_out_f.append(bm.verts.new(Vector((r_out * ca, -hd, r_out * sa))))
        v_in_f.append( bm.verts.new(Vector((r_in  * ca, -hd, r_in  * sa))))
        v_out_b.append(bm.verts.new(Vector((r_out * ca,  hd, r_out * sa))))
        v_in_b.append( bm.verts.new(Vector((r_in  * ca,  hd, r_in  * sa))))
        
    for i in range(segs):
        ni = (i + 1) % segs
        bm.faces.new([v_in_f[i], v_out_f[i], v_out_f[ni], v_in_f[ni]])
        bm.faces.new([v_in_b[ni], v_out_b[ni], v_out_b[i], v_in_b[i]])
        bm.faces.new([v_out_f[i], v_out_b[i], v_out_b[ni], v_out_f[ni]])
        bm.faces.new([v_in_b[i], v_in_f[i], v_in_f[ni], v_in_b[ni]])
        
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(location)), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    apply_bevel(obj, width=0.015, segments=3)
    shade_auto_smooth(obj, 35)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_crown(name, location, coll=None, mat_gold=None, mat_gem=None):
    """
    Constructs the 5-pointed stylized cartoon gold crown with red diamond gem.
    """
    crown_objs = []
    
    # 1. Base connecting band
    band = make_block(f"{name}_Band", location=(location[0], location[1], location[2] + 0.03), size=(0.76, 0.16, 0.08), bevel_width=0.02, coll=coll, mat=mat_gold)
    crown_objs.append(band)
    
    # 2. 5 Crown Peaks (prisms tapering to sharp points)
    peaks_data = [
        # (suffix, x_offset, height, width, tilt_y)
        ("Center",  0.00, 0.44, 0.22,   0.0), # Tall center peak
        ("Inner_L", -0.16, 0.35, 0.18, -10.0),
        ("Inner_R",  0.16, 0.35, 0.18,  10.0),
        ("Outer_L", -0.30, 0.26, 0.15, -18.0),
        ("Outer_R",  0.30, 0.26, 0.15,  18.0),
    ]
    for p_name, px, ph, pw, ptilt in peaks_data:
        bm = bmesh.new()
        hw = pw * 0.5
        hd = 0.07
        
        v_bl = bm.verts.new(Vector((-hw, -hd, 0)))
        v_br = bm.verts.new(Vector(( hw, -hd, 0)))
        v_tl = bm.verts.new(Vector((-hw * 0.6, -hd, ph * 0.7)))
        v_tr = bm.verts.new(Vector(( hw * 0.6, -hd, ph * 0.7)))
        v_tip = bm.verts.new(Vector((0, -hd * 0.8, ph)))
        
        v_kbl = bm.verts.new(Vector((-hw, hd, 0)))
        v_kbr = bm.verts.new(Vector(( hw, hd, 0)))
        v_ktl = bm.verts.new(Vector((-hw * 0.6, hd, ph * 0.7)))
        v_ktr = bm.verts.new(Vector(( hw * 0.6, hd, ph * 0.7)))
        v_ktip = bm.verts.new(Vector((0, hd * 0.8, ph)))
        
        bm.faces.new([v_bl, v_br, v_tr, v_tl])
        bm.faces.new([v_tl, v_tr, v_tip])
        bm.faces.new([v_kbr, v_kbl, v_ktl, v_ktr])
        bm.faces.new([v_ktr, v_ktl, v_ktip])
        bm.faces.new([v_br, v_kbr, v_ktr, v_tr])
        bm.faces.new([v_tr, v_ktr, v_ktip, v_tip])
        bm.faces.new([v_kbl, v_bl, v_tl, v_ktl])
        bm.faces.new([v_ktl, v_tl, v_tip, v_ktip])
        bm.faces.new([v_kbl, v_kbr, v_br, v_bl]) # bottom
        
        rot_m = Euler((0, math.radians(ptilt), 0), 'XYZ').to_matrix().to_4x4()
        mat_p = Matrix.Translation(Vector((location[0] + px, location[1], location[2] + 0.06))) @ rot_m
        bmesh.ops.transform(bm, matrix=mat_p, verts=bm.verts)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        
        mesh_p = bpy.data.meshes.new(f"{name}_Peak_{p_name}")
        bm.to_mesh(mesh_p)
        bm.free()
        mesh_p.update()
        
        obj_p = bpy.data.objects.new(f"{name}_Peak_{p_name}", mesh_p)
        (coll or bpy.context.scene.collection).objects.link(obj_p)
        apply_bevel(obj_p, width=0.015, segments=3)
        shade_auto_smooth(obj_p, 35)
        if mat_gold:
            obj_p.data.materials.append(mat_gold)
        crown_objs.append(obj_p)
        
    # 3. Center Crown Diamond Gem
    gem_loc = (location[0], location[1] - 0.08, location[2] + 0.20)
    gem_obj = make_diamond_gem(f"{name}_Gem", location=gem_loc, width=0.15, height=0.22, depth=0.08, coll=coll, mat=mat_gem)
    crown_objs.append(gem_obj)
    
    return crown_objs, gem_obj

def make_crown_icon(name, location, size=0.14, coll=None, mat=None):
    """Creates a 3-pointed cartoon crown emblem in gold."""
    bm = bmesh.new()
    hw = size * 0.5
    hh = size * 0.38
    hd = 0.016
    
    v_bl = bm.verts.new(Vector((-hw, 0, -hh)))
    v_br = bm.verts.new(Vector(( hw, 0, -hh)))
    v_tl = bm.verts.new(Vector((-hw * 0.85, 0, hh * 0.9)))
    v_ml = bm.verts.new(Vector((-hw * 0.40, 0, hh * 0.2)))
    v_tc = bm.verts.new(Vector(( 0.0,        0, hh * 1.15))) # center highest
    v_mr = bm.verts.new(Vector(( hw * 0.40, 0, hh * 0.2)))
    v_tr = bm.verts.new(Vector(( hw * 0.85, 0, hh * 0.9)))
    
    bm.faces.new([v_bl, v_br, v_tr, v_mr, v_tc, v_ml, v_tl])
    
    res = bmesh.ops.extrude_face_region(bm, geom=bm.faces[:])
    ext_verts = [v for v in res["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, -hd, 0), verts=ext_verts)
    
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(location)), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    apply_bevel(obj, width=0.006, segments=2)
    shade_auto_smooth(obj, 30)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_banner(name, location, width=0.32, height=0.88, coll=None, mat_velvet=None, mat_gold=None):
    """
    Creates a medieval tournament banner with swallowtail V-notch,
    gold hanging rod with ball finials, gold border trim, and 3-pointed crown icon.
    """
    banner_objs = []
    hw = width * 0.5
    hh = height * 0.5
    v_cut = 0.18 # V-cut depth
    
    # 1. Gold hanging rod
    rod = make_block(f"{name}_Rod", location=(location[0], location[1], location[2] + hh + 0.03), size=(width + 0.08, 0.05, 0.05), bevel_width=0.012, coll=coll, mat=mat_gold)
    banner_objs.append(rod)
    
    # Sphere Finials at rod ends
    for sx in (-1, 1):
        s_name = "L" if sx < 0 else "R"
        p_fn = (location[0] + sx * (hw + 0.045), location[1], location[2] + hh + 0.03)
        bm_fn = bmesh.new()
        bmesh.ops.create_uvsphere(bm_fn, u_segments=12, v_segments=8, radius=0.034, matrix=Matrix.Translation(Vector(p_fn)))
        m_fn = bpy.data.meshes.new(f"{name}_Finial_{s_name}")
        bm_fn.to_mesh(m_fn)
        bm_fn.free()
        m_fn.update()
        o_fn = bpy.data.objects.new(m_fn.name, m_fn)
        (coll or bpy.context.scene.collection).objects.link(o_fn)
        shade_auto_smooth(o_fn, 30)
        o_fn.data.materials.append(mat_gold)
        banner_objs.append(o_fn)
        
    # 2. Fabric banner with swallowtail bottom
    bm = bmesh.new()
    v_tl = bm.verts.new(Vector((-hw, 0,  hh)))
    v_tr = bm.verts.new(Vector(( hw, 0,  hh)))
    v_bl = bm.verts.new(Vector((-hw, 0, -hh + v_cut)))
    v_br = bm.verts.new(Vector(( hw, 0, -hh + v_cut)))
    v_bc = bm.verts.new(Vector((  0, 0, -hh)))
    
    bm.faces.new([v_tl, v_tr, v_br, v_bc, v_bl])
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=18)
    
    res = bmesh.ops.extrude_face_region(bm, geom=bm.faces[:])
    extruded_verts = [v for v in res["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, -0.016, 0), verts=extruded_verts)
    
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(location)), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    
    vg = obj.vertex_groups.new(name="Pin_Top")
    for idx, v in enumerate(mesh.vertices):
        top_dist = (location[2] + hh) - v.co.z
        weight = max(0.0, min(1.0, top_dist / 0.20))
        vg.add([idx], weight, 'REPLACE')
        
    shade_auto_smooth(obj, 35)
    if mat_velvet:
        obj.data.materials.append(mat_velvet)
    banner_objs.append(obj)
    
    # 3. Gold 3-pointed crown icon on banner
    crown_ico = make_crown_icon(f"{name}_Emblem", location=(location[0], location[1] - 0.020, location[2] + 0.16), size=0.14, coll=coll, mat=mat_gold)
    banner_objs.append(crown_ico)
    
    return banner_objs, obj

# --------------------------------------------------------------------------
# Full Throne Assembly
# --------------------------------------------------------------------------
def build_royal_football_throne():
    clear_scene()
    
    coll_throne = get_or_create_collection("Throne")
    coll_effects = get_or_create_collection("Effects")
    coll_lights = get_or_create_collection("Lights")
    coll_scene = get_or_create_collection("Scene")
    
    mat_gold = make_material_gold("M_Gold_Toon")
    mat_velvet = make_material_velvet("M_Red_Velvet")
    mat_gem = make_material_gem("M_Red_Gem")
    mat_dark = make_material_dark("M_Dark_Under")
    mat_ball_w = make_material_ball("M_Ball_White", is_black=False)
    mat_ball_b = make_material_ball("M_Ball_Black", is_black=True)
    mat_sparkle = make_material_sparkle("M_Sparkle")
    mat_floor = make_material_floor("M_Shadow_Floor")
    
    root_empty = bpy.data.objects.new("RoyalFootballThrone", None)
    root_empty.empty_display_type = 'PLAIN_AXES'
    root_empty.empty_display_size = 0.6
    coll_throne.objects.link(root_empty)
    root_empty.location = (0, 0, 0)
    
    throne_objects = []
    animated_gems = []
    
    # ----------------------------------------------------------------------
    # 1. Base Foot Slabs & Pillars (Left and Right)
    # ----------------------------------------------------------------------
    foot_coords = [("L", -0.54), ("R", 0.54)]
    for suffix, fx in foot_coords:
        foot = make_block(f"Foot_{suffix}", location=(fx, 0.04, 0.09), size=(0.54, 0.92, 0.18), bevel_width=0.035, coll=coll_throne, mat=mat_gold)
        throne_objects.append(foot)
        
        pillar = make_tapered_pillar(f"Pillar_{suffix}", location=(fx, 0.04, 0.18), bot_size=(0.44, 0.78), top_size=(0.38, 0.72), height=0.55, bevel_width=0.028, coll=coll_throne, mat=mat_gold)
        throne_objects.append(pillar)
        
        panel = make_block(f"PillarPanel_{suffix}", location=(fx, -0.34, 0.45), size=(0.28, 0.04, 0.40), bevel_width=0.015, coll=coll_throne, mat=mat_velvet)
        throne_objects.append(panel)
        
    # ----------------------------------------------------------------------
    # 2. Hollow Underside (Depth under seat)
    # ----------------------------------------------------------------------
    under = make_block("Underside_Hollow", location=(0.0, 0.04, 0.45), size=(0.66, 0.72, 0.52), bevel_width=0.02, coll=coll_throne, mat=mat_dark)
    throne_objects.append(under)
    
    # ----------------------------------------------------------------------
    # 3. Seat Frame & Red Puffy Cushion
    # ----------------------------------------------------------------------
    seat_frame = make_block("Seat_Frame", location=(0.0, 0.04, 0.81), size=(1.06, 0.90, 0.18), bevel_width=0.032, coll=coll_throne, mat=mat_gold)
    throne_objects.append(seat_frame)
    
    cushion = make_block("Cushion_Red", location=(0.0, 0.04, 0.97), size=(0.92, 0.80, 0.20), bevel_width=0.045, coll=coll_throne, mat=mat_velvet)
    sub_c = cushion.modifiers.new("Subsurf", 'SUBSURF')
    sub_c.levels = 2
    throne_objects.append(cushion)
    
    # Front Rhombus Plate & Gem on Seat Front
    rhombus_frame = make_block("Seat_Diamond_Frame", location=(0.0, -0.42, 0.81), size=(0.38, 0.05, 0.38), bevel_width=0.018, coll=coll_throne, mat=mat_gold, rotation_euler=(0, math.radians(45), 0))
    throne_objects.append(rhombus_frame)
    
    seat_gem = make_diamond_gem("Seat_Diamond_Gem", location=(0.0, -0.45, 0.81), width=0.22, height=0.22, depth=0.06, coll=coll_throne, mat=mat_gem)
    throne_objects.append(seat_gem)
    animated_gems.append((seat_gem, 0))
    
    # ----------------------------------------------------------------------
    # 4. Chunky Gold Armrests & Diamond Emblems
    # ----------------------------------------------------------------------
    for suffix, ax in foot_coords:
        arm = make_block(f"Armrest_{suffix}", location=(ax, 0.04, 1.05), size=(0.44, 0.86, 0.52), bevel_width=0.035, coll=coll_throne, mat=mat_gold)
        throne_objects.append(arm)
        
        arm_panel = make_block(f"ArmrestPanel_{suffix}", location=(ax, -0.40, 1.05), size=(0.28, 0.04, 0.34), bevel_width=0.015, coll=coll_throne, mat=mat_velvet)
        throne_objects.append(arm_panel)
        
        arm_gem = make_diamond_gem(f"ArmrestGem_{suffix}", location=(ax, -0.43, 1.05), width=0.16, height=0.16, depth=0.05, coll=coll_throne, mat=mat_gem)
        throne_objects.append(arm_gem)
        animated_gems.append((arm_gem, 6))
        
    # ----------------------------------------------------------------------
    # 5. Backrest Outer Frame & Sharp Angular Wing-Spikes
    # ----------------------------------------------------------------------
    backboard = make_block("Backboard", location=(0.0, 0.44, 1.82), size=(1.34, 0.10, 1.68), bevel_width=0.03, coll=coll_throne, mat=mat_gold)
    throne_objects.append(backboard)
    
    post_l = make_block("Backrest_Post_L", location=(-0.56, 0.34, 1.82), size=(0.22, 0.14, 1.68), bevel_width=0.03, coll=coll_throne, mat=mat_gold)
    post_r = make_block("Backrest_Post_R", location=( 0.56, 0.34, 1.82), size=(0.22, 0.14, 1.68), bevel_width=0.03, coll=coll_throne, mat=mat_gold)
    throne_objects.extend([post_l, post_r])
    
    for sx in (-1, 1):
        s_name = "L" if sx < 0 else "R"
        wing = make_block(f"WingSpike_{s_name}", location=(sx * 0.72, 0.36, 2.45), size=(0.22, 0.18, 0.54), bevel_width=0.025, coll=coll_throne, mat=mat_gold, rotation_euler=(0, math.radians(sx * 22), 0))
        throne_objects.append(wing)
        
    # ----------------------------------------------------------------------
    # 6. Inner Red Quilted (Capitone) Panel with Diamond Tufts & Gold Buttons
    # ----------------------------------------------------------------------
    tuft_panel, buttons = make_tufted_panel("Tuft_Panel", location=(0.0, 0.32, 1.62), width=0.88, height=1.28, depth=0.10, coll=coll_throne, mat_velvet=mat_velvet, mat_gold=mat_gold)
    throne_objects.append(tuft_panel)
    throne_objects.extend(buttons)
    
    # ----------------------------------------------------------------------
    # 7. Emblem Ring & Truncated Icosahedron Soccer Ball
    # ----------------------------------------------------------------------
    ring_loc = (0.0, 0.28, 2.10)
    ring_obj = make_emblem_ring("Ring_Emblem", location=ring_loc, r_out=0.42, r_in=0.34, depth=0.12, coll=coll_throne, mat=mat_gold)
    throne_objects.append(ring_obj)
    
    ball_obj = make_soccer_ball("Soccer_Ball", location=ring_loc, radius=0.32, coll=coll_throne, mat_white=mat_ball_w, mat_black=mat_ball_b)
    throne_objects.append(ball_obj)
    
    back_disc = make_block("Back_Ring_Disc", location=(0.0, 0.49, 2.10), size=(0.78, 0.05, 0.78), bevel_width=0.02, coll=coll_throne, mat=mat_gold, rotation_euler=(0, math.radians(45), 0))
    throne_objects.append(back_disc)
    
    back_panel = make_block("Back_Panel", location=(0.0, 0.49, 1.48), size=(0.96, 0.04, 0.88), bevel_width=0.02, coll=coll_throne, mat=mat_velvet)
    throne_objects.append(back_panel)
    
    # ----------------------------------------------------------------------
    # 8. Royal Crown & Crown Diamond Gem
    # ----------------------------------------------------------------------
    crown_loc = (0.0, 0.28, 2.38)
    crown_objs, crown_gem = make_crown("Crown", location=crown_loc, coll=coll_throne, mat_gold=mat_gold, mat_gem=mat_gem)
    throne_objects.extend(crown_objs)
    animated_gems.append((crown_gem, 18))
    
    # ----------------------------------------------------------------------
    # 9. Tournament Banners (Left & Right)
    # ----------------------------------------------------------------------
    banner_objs_l, banner_cloth_l = make_banner("Banner_L", location=(-0.65, 0.26, 1.68), width=0.30, height=0.85, coll=coll_throne, mat_velvet=mat_velvet, mat_gold=mat_gold)
    banner_objs_r, banner_cloth_r = make_banner("Banner_R", location=( 0.65, 0.26, 1.68), width=0.30, height=0.85, coll=coll_throne, mat_velvet=mat_velvet, mat_gold=mat_gold)
    throne_objects.extend(banner_objs_l)
    throne_objects.extend(banner_objs_r)
    
    for b_cloth, phase_val in [(banner_cloth_l, 0.0), (banner_cloth_r, 1.8)]:
        wave = b_cloth.modifiers.new("Wave", 'WAVE')
        wave.height = 0.035
        wave.width = 1.4
        wave.narrowness = 1.6
        wave.speed = 0.038
        wave.time_offset = phase_val
        wave.vertex_group = "Pin_Top"
        wave.use_x = False
        wave.use_y = True
        
    # ----------------------------------------------------------------------
    # 10. Sparkle Star Particle Meshes
    # ----------------------------------------------------------------------
    bm_sp = bmesh.new()
    for _ in range(60):
        sx = random.uniform(-0.85, 0.85)
        sy = random.uniform(-0.55, 0.45)
        sz = random.uniform(0.70, 2.65)
        s_size = random.uniform(0.008, 0.022)
        mat_sp = Matrix.Translation(Vector((sx, sy, sz))) @ Matrix.Diagonal((s_size, s_size*0.4, s_size, 1.0))
        bmesh.ops.create_cube(bm_sp, size=2.0, matrix=mat_sp)
        
    mesh_sp = bpy.data.meshes.new("Sparkles_Glints")
    bm_sp.to_mesh(mesh_sp)
    bm_sp.free()
    mesh_sp.update()
    sparkles_obj = bpy.data.objects.new("Sparkles_Glints", mesh_sp)
    coll_effects.objects.link(sparkles_obj)
    sparkles_obj.data.materials.append(mat_sparkle)
    
    # ----------------------------------------------------------------------
    # 11. Parent All Throne Objects under Root Empty
    # ----------------------------------------------------------------------
    for obj in throne_objects:
        obj.parent = root_empty
        
    # ----------------------------------------------------------------------
    # 12. Animations Setup (24 fps, Seamless Loop 91-330)
    # ----------------------------------------------------------------------
    setup_animations(ball_obj, animated_gems, crown_objs[1])
    
    # ----------------------------------------------------------------------
    # 13. Lighting & Environment Setup
    # ----------------------------------------------------------------------
    key_data = bpy.data.lights.new("Key_Light_Warm", 'AREA')
    key_data.energy = 480.0
    key_data.color = (1.0, 0.95, 0.88)
    key_data.size = 2.8
    key_obj = bpy.data.objects.new("Key_Light_Warm", key_data)
    key_obj.location = (-3.0, -3.2, 3.8)
    key_obj.rotation_euler = (math.radians(55), math.radians(10), math.radians(-40))
    coll_lights.objects.link(key_obj)
    
    fill_data = bpy.data.lights.new("Fill_Light_Cool", 'AREA')
    fill_data.energy = 160.0
    fill_data.color = (0.85, 0.90, 1.0)
    fill_data.size = 2.2
    fill_obj = bpy.data.objects.new("Fill_Light_Cool", fill_data)
    fill_obj.location = (3.0, -2.4, 2.2)
    fill_obj.rotation_euler = (math.radians(50), math.radians(-15), math.radians(45))
    coll_lights.objects.link(fill_obj)
    
    rim_data = bpy.data.lights.new("Rim_Light_Crisp", 'AREA')
    rim_data.energy = 320.0
    rim_data.color = (0.95, 0.98, 1.0)
    rim_data.size = 3.0
    rim_obj = bpy.data.objects.new("Rim_Light_Crisp", rim_data)
    rim_obj.location = (0.0, 3.2, 3.0)
    rim_obj.rotation_euler = (math.radians(-50), 0, math.radians(180))
    coll_lights.objects.link(rim_obj)
    
    pt_data = bpy.data.lights.new("Point_Ball_Accent", 'POINT')
    pt_data.energy = 45.0
    pt_data.color = (1.0, 0.92, 0.75)
    pt_data.shadow_soft_size = 0.2
    pt_obj = bpy.data.objects.new("Point_Ball_Accent", pt_data)
    pt_obj.location = (0.0, 0.05, 2.10)
    coll_lights.objects.link(pt_obj)
    
    # ----------------------------------------------------------------------
    # 14. Floor & Studio World Setup
    # ----------------------------------------------------------------------
    bm_fl = bmesh.new()
    mat_fl_m = Matrix.Diagonal((14.0, 14.0, 0.05, 1.0))
    bmesh.ops.create_cube(bm_fl, size=2.0, matrix=mat_fl_m)
    mesh_fl = bpy.data.meshes.new("Floor_Plane")
    bm_fl.to_mesh(mesh_fl)
    bm_fl.free()
    mesh_fl.update()
    floor_obj = bpy.data.objects.new("Floor_Plane", mesh_fl)
    floor_obj.location = (0, 0, -0.05)
    coll_scene.objects.link(floor_obj)
    floor_obj.data.materials.append(mat_floor)
    
    world = bpy.data.worlds.new("Football_Throne_World")
    bpy.context.scene.world = world
    world.use_nodes = True
    wnt = world.node_tree
    wbg = wnt.nodes.get("Background")
    if wbg:
        wbg.inputs["Color"].default_value = (0.09, 0.11, 0.17, 1.0)
        wbg.inputs["Strength"].default_value = 0.40
        
    return throne_objects, root_empty

# --------------------------------------------------------------------------
# Animation Setup (Idle Loop: 91 to 330)
# --------------------------------------------------------------------------
def setup_animations(ball_obj, gem_tuples, crown_peak_center):
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 330
    scene.render.fps = 24
    
    try:
        ball_obj.animation_data_create()
        ball_obj.rotation_mode = 'XYZ'
        
        ball_obj.rotation_euler = (0, 0, 0)
        ball_obj.keyframe_insert(data_path="rotation_euler", index=2, frame=91)
        ball_obj.rotation_euler = (0, 0, math.radians(360))
        ball_obj.keyframe_insert(data_path="rotation_euler", index=2, frame=331)
        
        orig_z = ball_obj.location.z
        ball_obj.location.z = orig_z
        ball_obj.keyframe_insert(data_path="location", index=2, frame=91)
        ball_obj.location.z = orig_z + 0.025
        ball_obj.keyframe_insert(data_path="location", index=2, frame=151)
        ball_obj.location.z = orig_z - 0.025
        ball_obj.keyframe_insert(data_path="location", index=2, frame=271)
        ball_obj.location.z = orig_z
        ball_obj.keyframe_insert(data_path="location", index=2, frame=331)
        
        if hasattr(ball_obj.animation_data.action, "fcurves"):
            for fc in ball_obj.animation_data.action.fcurves:
                if fc.data_path == "rotation_euler" and fc.array_index == 2:
                    for kp in fc.keyframe_points:
                        kp.interpolation = 'LINEAR'
                else:
                    for kp in fc.keyframe_points:
                        kp.interpolation = 'BEZIER'
    except Exception:
        pass
        
    for gem_obj, offset_frames in gem_tuples:
        try:
            gem_obj.animation_data_create()
            scale_base = 1.0
            for cycle in range(4):
                f_start = 91 + (cycle * 60) + offset_frames
                if f_start > 330:
                    continue
                gem_obj.scale = (scale_base, scale_base, scale_base)
                gem_obj.keyframe_insert(data_path="scale", frame=f_start)
                gem_obj.scale = (scale_base * 1.15, scale_base * 1.15, scale_base * 1.15)
                gem_obj.keyframe_insert(data_path="scale", frame=min(330, f_start + 12))
                gem_obj.scale = (scale_base, scale_base, scale_base)
                gem_obj.keyframe_insert(data_path="scale", frame=min(330, f_start + 24))
        except Exception:
            pass

# --------------------------------------------------------------------------
# Render & Cameras Setup
# --------------------------------------------------------------------------
def setup_render_engine(engine="EEVEE"):
    scene = bpy.context.scene
    items = bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items.keys()
    
    if engine.upper() == "CYCLES":
        scene.render.engine = "CYCLES"
        scene.cycles.samples = 128
        scene.cycles.use_denoising = True
    else:
        for cand in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
            if cand in items:
                scene.render.engine = cand
                break
        try:
            scene.eevee.taa_render_samples = 64
        except AttributeError:
            pass
            
    vs = scene.view_settings
    for transform in ("AgX", "Filmic", "Standard"):
        try:
            vs.view_transform = transform
            break
        except TypeError:
            continue
    try:
        vs.look = "Medium High Contrast"
    except Exception:
        pass

def add_camera_at(location, target, name="Render_Cam"):
    cam_data = bpy.data.cameras.get(name) or bpy.data.cameras.new(name)
    cam = bpy.data.objects.get(name) or bpy.data.objects.new(name, cam_data)
    coll_scene = get_or_create_collection("Scene")
    if cam.name not in coll_scene.objects:
        coll_scene.objects.link(cam)
        
    cam.location = location
    direction = Vector(target) - Vector(location)
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 55.0
    cam.data.clip_start = 0.1
    cam.data.clip_end = 100.0
    bpy.context.scene.camera = cam
    return cam

def render_turnaround_views(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    scene = bpy.context.scene
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.image_settings.file_format = 'PNG'
    
    center_focus = (0.0, 0.15, 1.35)
    
    camera_views = [
        ("throne_three_quarter",    ( 3.2, -3.6, 2.3), center_focus),
        ("throne_front",            ( 0.0, -4.8, 1.40), center_focus),
        ("throne_side",             ( 4.6,  0.2, 1.40), center_focus),
        ("throne_back",             ( 0.0,  4.8, 1.50), center_focus),
        ("throne_top",              ( 2.2, -2.8, 4.8), center_focus),
        ("throne_closeup_emblem",   ( 0.0, -1.4, 2.10), (0.0, 0.28, 2.10)),
        ("throne_closeup_base",     ( 0.0, -2.2, 0.65), (0.0, -0.20, 0.65)),
    ]
    
    paths = []
    for view_name, cam_pos, cam_target in camera_views:
        add_camera_at(cam_pos, cam_target, name="Render_Cam")
        filepath = os.path.abspath(os.path.join(out_dir, f"{view_name}.png"))
        scene.render.filepath = filepath
        bpy.ops.render.render(write_still=True)
        paths.append(filepath)
        print(f"[Preview Saved] {filepath}")
    return paths

# --------------------------------------------------------------------------
# Main Execution Entrypoint
# --------------------------------------------------------------------------
if __name__ == "__main__":
    out_dir = "d:/BAF/models"
    preview_dir = os.path.join(out_dir, "previews")
    os.makedirs(preview_dir, exist_ok=True)
    
    print("[1/5] Building Royal Football Throne...")
    throne_objs, root_empty = build_royal_football_throne()
    
    print(f"[2/5] Hierarchy assembled: {len(throne_objs)} modular objects parented to '{root_empty.name}'.")
    
    print("[3/5] Setting up render engine (EEVEE preview)...")
    setup_render_engine(engine="EEVEE")
    
    print("[4/5] Rendering 7 turnaround preview views...")
    preview_paths = render_turnaround_views(preview_dir)
    
    print("[5/5] Exporting assets (.blend, .glb, .fbx)...")
    base_export = os.path.join(out_dir, "RoyalFootballThrone")
    
    blend_path = base_export + ".blend"
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(blend_path))
    print(f"  [Export Blend] {blend_path}")
    
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in throne_objs:
        o.select_set(True)
    root_empty.select_set(True)
    bpy.context.view_layer.objects.active = root_empty
    
    glb_path = base_export + ".glb"
    try:
        bpy.ops.export_scene.gltf(filepath=os.path.abspath(glb_path), export_format="GLB", use_selection=True)
        print(f"  [Export GLB] {glb_path}")
    except Exception as e:
        print(f"  [Warn GLB] {e}")
        
    fbx_path = base_export + ".fbx"
    try:
        bpy.ops.export_scene.fbx(filepath=os.path.abspath(fbx_path), use_selection=True, apply_scale_options="FBX_SCALE_ALL")
        print(f"  [Export FBX] {fbx_path}")
    except Exception as e:
        print(f"  [Warn FBX] {e}")
        
    print("=" * 60)
    print("ROYAL FOOTBALL THRONE BUILD COMPLETE!")
    print(f"  Modular Objects: {len(throne_objs)}")
    print(f"  Root Parent: {root_empty.name}")
    print(f"  Collections: Throne, Effects, Lights, Scene")
    print(f"  Animation Frames: 1 to 330 (Intro: 1-90, Idle Loop: 91-330)")
    print(f"  Previews: {len(preview_paths)} images rendered in '{preview_dir}'")
    print(f"  Files: {blend_path}, {glb_path}, {fbx_path}")
    print("  Note: To switch to Cycles beauty render, run: bpy.context.scene.render.engine = 'CYCLES'")
    print("=" * 60)

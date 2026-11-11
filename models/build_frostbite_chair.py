"""Procedural Build Script for the Frostbite Ice Throne Chair (Blender 4.x / 5.x).

Carved from glowing blue ice, based on concept art: media_1794305734037_eee84b71.jpg
Units: Metric (Meters), Z up, facing -Y.
Dimensions: ~1.2 m wide, 1.2 m deep, 2.4 m tall. Origin at center of base on floor.
Hierarchy: All modular objects parented under one Empty named "FrostbiteChair".
Collections: Chair, Effects, Lights, Scene.
Materials: Procedural PBR Ice (Clear & Frosted), Glowing Core Gem, Snow, Cold Mist, Sparkles.
"""

import sys
import os
import math
import random

import bpy
import bmesh
from mathutils import Vector, Matrix, Euler

# --------------------------------------------------------------------------
# Random Seed for Reproducibility
# --------------------------------------------------------------------------
random.seed(7)

# --------------------------------------------------------------------------
# Socket Helper for Universal Blender 4.0 - 5.x Compatibility
# --------------------------------------------------------------------------
def set_socket(node, candidate_names, value):
    """Safely set an input socket value checking multiple version alias names."""
    for name in candidate_names:
        if name in node.inputs:
            node.inputs[name].default_value = value
            return True
    return False

# --------------------------------------------------------------------------
# Collection Management
# --------------------------------------------------------------------------
def get_or_create_collection(name, parent_coll=None):
    coll = bpy.data.collections.get(name)
    if coll is None:
        coll = bpy.data.collections.new(name)
        if parent_coll:
            parent_coll.children.link(coll)
        else:
            bpy.context.scene.collection.children.link(coll)
    return coll

# --------------------------------------------------------------------------
# Procedural PBR Material Setups
# --------------------------------------------------------------------------
def make_material_ice(name="M_Ice_Clear", is_frosted=False):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (800, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (500, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    # Crystalline Glassy Blue Ice
    if is_frosted:
        bsdf.inputs["Base Color"].default_value = (0.35, 0.75, 0.98, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.28
        bsdf.inputs["IOR"].default_value = 1.31
        set_socket(bsdf, ["Transmission Weight", "Transmission"], 0.65)
        set_socket(bsdf, ["Subsurface Weight", "Subsurface"], 0.30)
        set_socket(bsdf, ["Subsurface Color"], (0.15, 0.60, 0.95, 1.0))
        set_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.20)
    else:
        bsdf.inputs["Base Color"].default_value = (0.10, 0.65, 0.98, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.08
        bsdf.inputs["IOR"].default_value = 1.31
        set_socket(bsdf, ["Transmission Weight", "Transmission"], 0.92)
        set_socket(bsdf, ["Subsurface Weight", "Subsurface"], 0.20)
        set_socket(bsdf, ["Subsurface Radius"], (0.2, 0.5, 1.0))
        set_socket(bsdf, ["Subsurface Color"], (0.08, 0.58, 0.98, 1.0))
        set_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.40)
        
    # Micro Frost Bump (subtle, NOT heavy reptile scales)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.location = (-400, 100)
    noise.inputs["Scale"].default_value = 50.0
    noise.inputs["Detail"].default_value = 4.0
    
    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (-150, 100)
    bump.inputs["Strength"].default_value = 0.05 if not is_frosted else 0.08
    bump.inputs["Distance"].default_value = 0.005
    nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    
    # Faint internal cyan crack glow
    if not is_frosted:
        set_socket(bsdf, ["Emission Color", "Emission"], (0.15, 0.70, 0.95, 1.0))
        set_socket(bsdf, ["Emission Strength"], 0.15)
        
    return mat

def make_material_gem(name="M_Gem_Core"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (800, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (500, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    bsdf.inputs["Base Color"].default_value = (0.15, 0.88, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.05
    bsdf.inputs["IOR"].default_value = 1.76
    set_socket(bsdf, ["Transmission Weight", "Transmission"], 0.75)
    
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.location = (-300, 0)
    lw.inputs["Blend"].default_value = 0.35
    
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-50, 0)
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.2, 0.95, 1.0, 1.0) # Intense cyan rim
    ramp.color_ramp.elements[1].position = 1.0
    ramp.color_ramp.elements[1].color = (0.05, 0.55, 0.95, 1.0) # Deep core
    nt.links.new(lw.outputs["Facing"], ramp.inputs["Fac"])
    
    set_socket(bsdf, ["Emission Strength"], 5.0)
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color" if "Emission Color" in bsdf.inputs else "Emission"])
    return mat

def make_material_snow(name="M_Snow"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    bsdf.inputs["Base Color"].default_value = (0.95, 0.98, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.70
    set_socket(bsdf, ["Subsurface Weight", "Subsurface"], 0.40)
    set_socket(bsdf, ["Subsurface Radius"], (0.3, 0.6, 1.0))
    set_socket(bsdf, ["Subsurface Color"], (0.75, 0.88, 1.0, 1.0))
    
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.location = (-300, -100)
    noise.inputs["Scale"].default_value = 60.0
    noise.inputs["Detail"].default_value = 4.0
    
    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (-50, -100)
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.005
    nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    return mat

def make_material_mist(name="M_Mist"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.location = (200, 0)
    nt.links.new(vol.outputs["Volume"], out.inputs["Volume"])
    
    vol.inputs["Density"].default_value = 0.08
    vol.inputs["Color"].default_value = (0.70, 0.90, 1.0, 1.0)
    if "Emission Strength" in vol.inputs:
        vol.inputs["Emission Strength"].default_value = 0.04
        vol.inputs["Emission Color"].default_value = (0.3, 0.75, 1.0, 1.0)
    return mat

def make_material_sparkle(name="M_Sparkle"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (400, 0)
    
    emission = nt.nodes.new("ShaderNodeEmission")
    emission.location = (150, 0)
    emission.inputs["Color"].default_value = (0.85, 0.96, 1.0, 1.0)
    emission.inputs["Strength"].default_value = 4.0
    nt.links.new(emission.outputs["Emission"], out.inputs["Surface"])
    return mat

def make_material_floor(name="M_Floor"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (200, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    bsdf.inputs["Base Color"].default_value = (0.88, 0.93, 0.98, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.45
    set_socket(bsdf, ["Subsurface Weight", "Subsurface"], 0.25)
    set_socket(bsdf, ["Subsurface Color"], (0.6, 0.8, 1.0, 1.0))
    return mat

# --------------------------------------------------------------------------
# Mesh Modeling Helpers
# --------------------------------------------------------------------------
def apply_bevel(obj, width=0.025, segments=2, angle_deg=30):
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(angle_deg)
    if bpy.app.version >= (4, 1, 0):
        mod.harden_normals = True
    return mod

def shade_auto_smooth(obj, angle_deg=30):
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    limit = math.radians(angle_deg)
    for face in bm.faces:
        face.smooth = True
    for edge in bm.edges:
        if len(edge.link_faces) == 2:
            edge.smooth = edge.calc_face_angle(0.0) <= limit
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    return obj

def make_block(name, location, size, bevel_width=0.025, bevel_segments=2, coll=None, mat=None, rotation_euler=(0,0,0)):
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
    shade_auto_smooth(obj, 30)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_faceted_foot(name, location, size, bevel_width=0.035, coll=None, mat=None):
    bm = bmesh.new()
    mat_diag = Matrix.Translation(Vector(location)) @ Matrix.Diagonal((size[0]/2, size[1]/2, size[2]/2, 1.0))
    bmesh.ops.create_cube(bm, size=2.0, matrix=mat_diag)
    
    for v in bm.verts:
        v.co.x += random.uniform(-0.006, 0.006)
        v.co.y += random.uniform(-0.006, 0.006)
        v.co.z += random.uniform(-0.004, 0.004)
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    apply_bevel(obj, width=bevel_width, segments=2)
    shade_auto_smooth(obj, 28)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_chevron_plate(name, location, width, height, depth, v_drop=0.10, coll=None, mat=None):
    bm = bmesh.new()
    hw = width * 0.5
    
    v_bot_c = bm.verts.new(Vector((0, 0, 0)))
    v_top_c = bm.verts.new(Vector((0, 0, height)))
    v_bot_l = bm.verts.new(Vector((-hw, 0, v_drop)))
    v_top_l = bm.verts.new(Vector((-hw, 0, height + v_drop)))
    v_bot_r = bm.verts.new(Vector((hw, 0, v_drop)))
    v_top_r = bm.verts.new(Vector((hw, 0, height + v_drop)))
    
    f_l = bm.faces.new([v_bot_c, v_bot_l, v_top_l, v_top_c])
    f_r = bm.faces.new([v_bot_c, v_top_c, v_top_r, v_bot_r])
    
    res = bmesh.ops.extrude_face_region(bm, geom=[f_l, f_r])
    ext_verts = [v for v in res["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=Vector((0, depth, 0)), verts=ext_verts)
    
    bmesh.ops.translate(bm, vec=Vector(location), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    apply_bevel(obj, width=0.015, segments=2)
    shade_auto_smooth(obj, 30)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_crystal_shard(name, location, rotation_euler, radius, body_height, tip_height, coll=None, mat=None):
    bm = bmesh.new()
    segments = 6
    
    v_base = []
    v_shoulder = []
    for i in range(segments):
        theta = 2 * math.pi * i / segments
        x = radius * math.cos(theta)
        y = radius * math.sin(theta)
        v_base.append(bm.verts.new(Vector((x, y, 0))))
        v_shoulder.append(bm.verts.new(Vector((x, y, body_height))))
        
    v_tip = bm.verts.new(Vector((0, 0, body_height + tip_height)))
    
    for i in range(segments):
        next_i = (i + 1) % segments
        bm.faces.new([v_base[i], v_base[next_i], v_shoulder[next_i], v_shoulder[i]])
        bm.faces.new([v_shoulder[i], v_shoulder[next_i], v_tip])
        
    bm.faces.new(list(reversed(v_base)))
    
    rot_mat = Euler(rotation_euler, 'XYZ').to_matrix().to_4x4()
    trans_mat = Matrix.Translation(Vector(location)) @ rot_mat
    bmesh.ops.transform(bm, matrix=trans_mat, verts=bm.verts)
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

def make_diamond_gem(name, location, width=0.35, height=0.58, depth=0.22, coll=None, mat=None):
    bm = bmesh.new()
    p = Vector(location)
    hw = width * 0.5
    hh = height * 0.5
    hd = depth * 0.5
    
    v_r = bm.verts.new(p + Vector(( hw, 0, 0)))
    v_t = bm.verts.new(p + Vector(( 0, 0,  hh)))
    v_l = bm.verts.new(p + Vector((-hw, 0, 0)))
    v_b = bm.verts.new(p + Vector(( 0, 0, -hh)))
    
    v_f = bm.verts.new(p + Vector((0, -hd, 0)))
    v_k = bm.verts.new(p + Vector((0,  hd, 0)))
    
    bm.faces.new([v_r, v_t, v_f])
    bm.faces.new([v_t, v_l, v_f])
    bm.faces.new([v_l, v_b, v_f])
    bm.faces.new([v_b, v_r, v_f])
    
    bm.faces.new([v_t, v_r, v_k])
    bm.faces.new([v_l, v_t, v_k])
    bm.faces.new([v_b, v_l, v_k])
    bm.faces.new([v_r, v_b, v_k])
    
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    apply_bevel(obj, width=0.010, segments=2)
    shade_auto_smooth(obj, 30)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_icicle(name, location, length=0.25, radius=0.022, coll=None, mat=None):
    bm = bmesh.new()
    rot_x = Matrix.Rotation(math.radians(180), 4, 'X')
    mat_trans = Matrix.Translation(Vector(location)) @ rot_x
    bmesh.ops.create_cone(bm, cap_ends=True, segments=7, radius1=radius, radius2=0.002, depth=length, matrix=mat_trans)
    
    for v in bm.verts:
        t = (v.co.z - location[2]) / -max(length, 0.01)
        v.co.x += math.sin(t * math.pi) * 0.003
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    shade_auto_smooth(obj, 30)
    if mat:
        obj.data.materials.append(mat)
    return obj

def make_snow_mound(name, location, size, coll=None, mat=None):
    bm = bmesh.new()
    mat_diag = Matrix.Translation(Vector(location)) @ Matrix.Diagonal((size[0]/2, size[1]/2, size[2]/2, 1.0))
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=12, radius=1.0, matrix=mat_diag)
    
    for v in bm.verts:
        if v.co.z < location[2]:
            v.co.z = location[2]
        v.co.x += math.sin(v.co.z * 15) * 0.01
        v.co.y += math.cos(v.co.x * 12) * 0.01
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    
    obj = bpy.data.objects.new(name, mesh)
    (coll or bpy.context.scene.collection).objects.link(obj)
    shade_auto_smooth(obj, 35)
    if mat:
        obj.data.materials.append(mat)
    return obj

# --------------------------------------------------------------------------
# Main Assembly Builder
# --------------------------------------------------------------------------
def build_frostbite_throne():
    try:
        bpy.ops.wm.read_homefile(use_empty=True, use_factory_startup=True)
    except Exception:
        for obj in list(bpy.context.scene.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
            
    u = bpy.context.scene.unit_settings
    u.system = "METRIC"
    u.scale_length = 1.0
    u.length_unit = "METERS"
    
    coll_chair = get_or_create_collection("Chair")
    coll_effects = get_or_create_collection("Effects")
    coll_lights = get_or_create_collection("Lights")
    coll_scene = get_or_create_collection("Scene")
    
    mat_ice_clear = make_material_ice("M_Ice_Clear", is_frosted=False)
    mat_ice_frosted = make_material_ice("M_Ice_Frosted", is_frosted=True)
    mat_gem_core = make_material_gem("M_Gem_Core")
    mat_snow = make_material_snow("M_Snow")
    mat_mist = make_material_mist("M_Mist")
    mat_sparkle = make_material_sparkle("M_Sparkle")
    mat_floor = make_material_floor("M_Floor")
    
    root_empty = bpy.data.objects.new("FrostbiteChair", None)
    root_empty.empty_display_type = 'PLAIN_AXES'
    root_empty.empty_display_size = 0.5
    coll_chair.objects.link(root_empty)
    
    chair_objects = []
    
    # ----------------------------------------------------------------------
    # 1. 4 Foot Blocks
    # ----------------------------------------------------------------------
    leg_coords = [
        ("FL", -0.34, -0.34),
        ("FR",  0.34, -0.34),
        ("BL", -0.34,  0.34),
        ("BR",  0.34,  0.34),
    ]
    foot_h = 0.30
    foot_w = 0.32
    for suffix, lx, ly in leg_coords:
        fb = make_faceted_foot(f"FootBlock_{suffix}", location=(lx, ly, foot_h/2), size=(foot_w, foot_w, foot_h), coll=coll_chair, mat=mat_ice_frosted)
        chair_objects.append(fb)
        
    # ----------------------------------------------------------------------
    # 2. 4 Legs
    # ----------------------------------------------------------------------
    leg_h = 0.40
    leg_w = 0.22
    for suffix, lx, ly in leg_coords:
        leg = make_block(f"Leg_{suffix}", location=(lx, ly, 0.30 + leg_h/2), size=(leg_w, leg_w, leg_h), bevel_width=0.02, coll=coll_chair, mat=mat_ice_clear)
        chair_objects.append(leg)
        
    # ----------------------------------------------------------------------
    # 3. Seat Block with Recessed Cushion Top
    # ----------------------------------------------------------------------
    bm_seat = bmesh.new()
    mat_seat = Matrix.Translation(Vector((0.0, 0.02, 0.70 + 0.125))) @ Matrix.Diagonal((0.50, 0.50, 0.125, 1.0))
    bmesh.ops.create_cube(bm_seat, size=2.0, matrix=mat_seat)
    
    top_faces = [f for f in bm_seat.faces if f.normal.z > 0.9]
    if top_faces:
        res_in = bmesh.ops.inset_individual(bm_seat, faces=top_faces, thickness=0.08, depth=0.0)
        in_face = [f for f in res_in["faces"] if f.normal.z > 0.9]
        if in_face:
            res_ext = bmesh.ops.extrude_face_region(bm_seat, geom=in_face)
            bmesh.ops.delete(bm_seat, geom=in_face, context="FACES_ONLY")
            ext_verts = [v for v in res_ext["geom"] if isinstance(v, bmesh.types.BMVert)]
            bmesh.ops.translate(bm_seat, vec=Vector((0, 0, -0.03)), verts=ext_verts)
            
    bmesh.ops.recalc_face_normals(bm_seat, faces=bm_seat.faces)
    mesh_seat = bpy.data.meshes.new("Seat")
    bm_seat.to_mesh(mesh_seat)
    bm_seat.free()
    mesh_seat.update()
    
    seat_obj = bpy.data.objects.new("Seat", mesh_seat)
    coll_chair.objects.link(seat_obj)
    apply_bevel(seat_obj, width=0.022, segments=2)
    shade_auto_smooth(seat_obj, 30)
    seat_obj.data.materials.append(mat_ice_clear)
    chair_objects.append(seat_obj)
    
    # ----------------------------------------------------------------------
    # 4. Seat Front Chevron Plates (3 Stacked Downward V-Prisms)
    # ----------------------------------------------------------------------
    chevron_data_seat = [
        (0.88, 0.18, 0.040, -0.47, 0.74, 0.10),
        (0.72, 0.16, 0.045, -0.49, 0.58, 0.09),
        (0.56, 0.14, 0.050, -0.51, 0.44, 0.08),
    ]
    for idx, (cw, ch, cd, cy, cz, cv) in enumerate(chevron_data_seat, 1):
        cp = make_chevron_plate(f"Chevron_Seat_{idx}", location=(0, cy, cz), width=cw, height=ch, depth=cd, v_drop=cv, coll=coll_chair, mat=mat_ice_frosted)
        chair_objects.append(cp)
        
    # ----------------------------------------------------------------------
    # 5. Armrest Pillars, Armrest Slabs & Snow Caps
    # ----------------------------------------------------------------------
    arm_x_offsets = [("L", -0.46), ("R", 0.46)]
    for suffix, ax in arm_x_offsets:
        pillar = make_block(f"Armrest_Pillar_{suffix}", location=(ax, -0.32, 0.50 + 0.35/2), size=(0.26, 0.26, 0.35), bevel_width=0.02, coll=coll_chair, mat=mat_ice_frosted)
        chair_objects.append(pillar)
        
        arm = make_block(f"Armrest_{suffix}", location=(ax, 0.06, 0.98 + 0.13), size=(0.28, 0.90, 0.26), bevel_width=0.022, coll=coll_chair, mat=mat_ice_clear)
        chair_objects.append(arm)
        
        snow_cap = make_snow_mound(f"SnowCap_Armrest_{suffix}", location=(ax, 0.06, 1.25), size=(0.26, 0.86, 0.08), coll=coll_chair, mat=mat_snow)
        chair_objects.append(snow_cap)
        
    # ----------------------------------------------------------------------
    # 6. Backrest Central Spine Column (Narrow mounting pillar behind chevrons)
    # ----------------------------------------------------------------------
    backrest_spine = make_block("Backrest_Spine", location=(0.0, 0.32, 1.35), size=(0.30, 0.15, 1.20), bevel_width=0.015, coll=coll_chair, mat=mat_ice_frosted)
    chair_objects.append(backrest_spine)
    
    # ----------------------------------------------------------------------
    # 7. Backrest Front Chevron Plates (5 Stacked V-Plates, Arrow Pattern)
    # ----------------------------------------------------------------------
    chevron_data_back = [
        (0.78, 0.17, 0.038, 0.94, 0.11),
        (0.66, 0.17, 0.040, 1.15, 0.10),
        (0.54, 0.16, 0.042, 1.36, 0.09),
        (0.42, 0.15, 0.045, 1.56, 0.08),
        (0.30, 0.14, 0.048, 1.75, 0.07),
    ]
    for idx, (bw, bh, bd, bz, bv) in enumerate(chevron_data_back, 1):
        bcp = make_chevron_plate(f"Chevron_Back_{idx}", location=(0, 0.32 - 0.075 - bd, bz), width=bw, height=bh, depth=bd, v_drop=bv, coll=coll_chair, mat=mat_ice_frosted)
        chair_objects.append(bcp)
        
    # ----------------------------------------------------------------------
    # 8. Crown of Jagged Crystal Shards (11 Radiating Fan Hexagonal Prisms)
    # ----------------------------------------------------------------------
    # Symmetrical upright majestic fan crown radiating outward (0 deg to ±29 deg)
    shard_configs = [
        # (suffix, x_pos, y_pos, z_pos, tilt_deg, radius, body_h, tip_h)
        ("Center_0",   0.00,  0.36, 0.85,   0.0, 0.16, 1.25, 0.42), # Center tall shard
        ("Inner_L1",  -0.11,  0.35, 0.84,  -6.0, 0.14, 1.18, 0.40),
        ("Inner_R1",   0.11,  0.35, 0.84,   6.0, 0.14, 1.18, 0.40),
        ("Mid_L2",    -0.22,  0.35, 0.82, -12.0, 0.13, 1.10, 0.38),
        ("Mid_R2",     0.22,  0.35, 0.82,  12.0, 0.13, 1.10, 0.38),
        ("Outer_L3",  -0.33,  0.36, 0.80, -18.0, 0.12, 1.00, 0.35),
        ("Outer_R3",   0.33,  0.36, 0.80,  18.0, 0.12, 1.00, 0.35),
        ("Wing_L4",   -0.44,  0.36, 0.78, -24.0, 0.11, 0.90, 0.32),
        ("Wing_R4",    0.44,  0.36, 0.78,  24.0, 0.11, 0.90, 0.32),
        ("Flank_L5",  -0.54,  0.37, 0.75, -29.0, 0.10, 0.80, 0.28),
        ("Flank_R5",   0.54,  0.37, 0.75,  29.0, 0.10, 0.80, 0.28),
    ]
    for name_suf, sx, sy, sz, s_tilt, s_rad, s_bh, s_th in shard_configs:
        # s_tilt < 0 tilts towards -X (left), s_tilt > 0 tilts towards +X (right)
        rot_e = (0.0, math.radians(s_tilt), 0.0)
        shard = make_crystal_shard(f"Shard_{name_suf}", location=(sx, sy, sz), rotation_euler=rot_e, radius=s_rad, body_height=s_bh, tip_height=s_th, coll=coll_chair, mat=mat_ice_clear)
        chair_objects.append(shard)
        
    # ----------------------------------------------------------------------
    # 9. Center-Top Diamond Crystal Gem & Angular Ice Frame
    # ----------------------------------------------------------------------
    gem_loc = (0.0, 0.26, 2.10)
    gem_obj = make_diamond_gem("Gem_Core", location=gem_loc, width=0.38, height=0.62, depth=0.24, coll=coll_chair, mat=mat_gem_core)
    chair_objects.append(gem_obj)
    
    # Idle Rotation Animation for the Core Gem (360 deg over 600 frames)
    try:
        gem_obj.animation_data_create()
        gem_obj.rotation_euler = (0, 0, 0)
        gem_obj.keyframe_insert(data_path="rotation_euler", frame=1)
        gem_obj.rotation_euler = (0, 0, math.radians(360))
        gem_obj.keyframe_insert(data_path="rotation_euler", frame=600)
        if hasattr(gem_obj.animation_data.action, "fcurves"):
            for fc in gem_obj.animation_data.action.fcurves:
                for kp in fc.keyframe_points:
                    kp.interpolation = 'LINEAR'
    except Exception:
        pass
        
    # Angular Ice Cradle Struts framing the gem
    for sx in [-1, 1]:
        frame_strut = make_block(f"Gem_Frame_{'L' if sx < 0 else 'R'}", location=(sx * 0.16, 0.28, 2.05), size=(0.04, 0.06, 0.45), bevel_width=0.01, coll=coll_chair, mat=mat_ice_frosted, rotation_euler=(0, math.radians(sx * 36), 0))
        chair_objects.append(frame_strut)
        
    # ----------------------------------------------------------------------
    # 10. Icicles (Hanging Beneath Armrests, Seat Edges, Front Plates)
    # ----------------------------------------------------------------------
    icicle_locations = [
        # Under Left Armrest outer edge
        (-0.58, -0.25, 0.98),
        (-0.58, -0.10, 0.98),
        (-0.58,  0.05, 0.98),
        (-0.58,  0.20, 0.98),
        (-0.58,  0.35, 0.98),
        # Under Right Armrest outer edge
        ( 0.58, -0.25, 0.98),
        ( 0.58, -0.10, 0.98),
        ( 0.58,  0.05, 0.98),
        ( 0.58,  0.20, 0.98),
        ( 0.58,  0.35, 0.98),
        # Under Seat Front Edge & Chevrons
        (-0.40, -0.45, 0.70),
        (-0.25, -0.47, 0.70),
        (-0.10, -0.49, 0.68),
        ( 0.00, -0.50, 0.66),
        ( 0.10, -0.49, 0.68),
        ( 0.25, -0.47, 0.70),
        ( 0.40, -0.45, 0.70),
        # Under Seat Sides
        (-0.48, -0.15, 0.70),
        (-0.48,  0.15, 0.70),
        ( 0.48, -0.15, 0.70),
        ( 0.48,  0.15, 0.70),
    ]
    for idx, (ix, iy, iz) in enumerate(icicle_locations, 1):
        rand_len = random.uniform(0.14, 0.38)
        rand_rad = random.uniform(0.016, 0.026)
        ici = make_icicle(f"Icicle_{idx:02d}", location=(ix, iy, iz), length=rand_len, radius=rand_rad, coll=coll_chair, mat=mat_ice_clear)
        chair_objects.append(ici)
        
    # ----------------------------------------------------------------------
    # 11. Snow Piles & Accumulation (Base Mound & Foot Caps)
    # ----------------------------------------------------------------------
    snow_base = make_snow_mound("Snow_Base_Mound", location=(0.0, 0.0, 0.0), size=(1.35, 1.35, 0.16), coll=coll_chair, mat=mat_snow)
    chair_objects.append(snow_base)
    
    for suffix, lx, ly in leg_coords:
        f_snow = make_snow_mound(f"Snow_Foot_{suffix}", location=(lx, ly, foot_h - 0.01), size=(foot_w * 0.9, foot_w * 0.9, 0.07), coll=coll_chair, mat=mat_snow)
        chair_objects.append(f_snow)
        
    # ----------------------------------------------------------------------
    # 12. Parent All Chair Objects under Root Empty
    # ----------------------------------------------------------------------
    for obj in chair_objects:
        obj.parent = root_empty
        
    # ----------------------------------------------------------------------
    # 13. Effects: Cold Mist Volume & Delicate Floating Sparkles
    # ----------------------------------------------------------------------
    bm_mist = bmesh.new()
    mat_mist_m = Matrix.Translation(Vector((0.0, 0.0, 0.16))) @ Matrix.Diagonal((0.90, 0.90, 0.16, 1.0))
    bmesh.ops.create_cube(bm_mist, size=2.0, matrix=mat_mist_m)
    mesh_mist = bpy.data.meshes.new("Mist_Volume")
    bm_mist.to_mesh(mesh_mist)
    bm_mist.free()
    mesh_mist.update()
    
    mist_obj = bpy.data.objects.new("Mist_Volume", mesh_mist)
    coll_effects.objects.link(mist_obj)
    mist_obj.data.materials.append(mat_mist)
    mist_obj.display_type = 'WIRE'
    
    # Tiny delicate sparkle diamonds around the crystal shards
    bm_sparkles = bmesh.new()
    for i in range(75):
        sp_x = random.uniform(-0.85, 0.85)
        sp_y = random.uniform(-0.75, 0.75)
        sp_z = random.uniform(0.60, 2.45)
        sp_size = random.uniform(0.003, 0.007)
        mat_sp = Matrix.Translation(Vector((sp_x, sp_y, sp_z))) @ Matrix.Diagonal((sp_size, sp_size, sp_size, 1.0))
        bmesh.ops.create_cube(bm_sparkles, size=2.0, matrix=mat_sp)
        
    bmesh.ops.recalc_face_normals(bm_sparkles, faces=bm_sparkles.faces)
    mesh_sparkles = bpy.data.meshes.new("Snowflakes_Sparkles")
    bm_sparkles.to_mesh(mesh_sparkles)
    bm_sparkles.free()
    mesh_sparkles.update()
    
    sparkles_obj = bpy.data.objects.new("Snowflakes_Sparkles", mesh_sparkles)
    coll_effects.objects.link(sparkles_obj)
    sparkles_obj.data.materials.append(mat_sparkle)
    
    # ----------------------------------------------------------------------
    # 14. Lights Setup (Soft Gem Core Glow, Cool Key, Translucent Rim)
    # ----------------------------------------------------------------------
    # Point light inside the Gem Core (soft 35W)
    ldata = bpy.data.lights.new("Light_Gem_Core", 'POINT')
    ldata.energy = 35.0
    ldata.color = (0.2, 0.85, 1.0)
    ldata.shadow_soft_size = 0.25
    lobj = bpy.data.objects.new("Light_Gem_Core", ldata)
    lobj.location = (0.0, 0.30, 2.15)
    coll_lights.objects.link(lobj)
    
    # Cool Key Light (Top-Left-Front)
    key_data = bpy.data.lights.new("Key_Light_Cool", 'AREA')
    key_data.energy = 350.0
    key_data.color = (0.90, 0.95, 1.0)
    key_data.size = 2.2
    key_obj = bpy.data.objects.new("Key_Light_Cool", key_data)
    key_obj.location = (-2.2, -2.8, 3.2)
    key_obj.rotation_euler = (math.radians(52), math.radians(10), math.radians(-32))
    coll_lights.objects.link(key_obj)
    
    # Translucent Rim Light (Behind the shards to illuminate crystal refraction)
    rim_data = bpy.data.lights.new("Rim_Light_Blue", 'AREA')
    rim_data.energy = 280.0
    rim_data.color = (0.20, 0.65, 1.0)
    rim_data.size = 2.5
    rim_obj = bpy.data.objects.new("Rim_Light_Blue", rim_data)
    rim_obj.location = (0.0, 2.8, 2.2)
    rim_obj.rotation_euler = (math.radians(-50), 0, math.radians(180))
    coll_lights.objects.link(rim_obj)
    
    # Soft Fill Light (Right)
    fill_data = bpy.data.lights.new("Fill_Light_Soft", 'AREA')
    fill_data.energy = 140.0
    fill_data.color = (0.75, 0.85, 1.0)
    fill_data.size = 2.2
    fill_obj = bpy.data.objects.new("Fill_Light_Soft", fill_data)
    fill_obj.location = (2.2, -1.8, 1.6)
    fill_obj.rotation_euler = (math.radians(45), math.radians(-15), math.radians(50))
    coll_lights.objects.link(fill_obj)
    
    # ----------------------------------------------------------------------
    # 15. Scene Environment & Ground Floor
    # ----------------------------------------------------------------------
    bm_floor = bmesh.new()
    mat_fl_diag = Matrix.Diagonal((12.0, 12.0, 1.0, 1.0))
    bmesh.ops.create_cube(bm_floor, size=2.0, matrix=mat_fl_diag)
    mesh_floor = bpy.data.meshes.new("Floor_Plane")
    bm_floor.to_mesh(mesh_floor)
    bm_floor.free()
    mesh_floor.update()
    
    floor_obj = bpy.data.objects.new("Floor_Plane", mesh_floor)
    floor_obj.location = (0, 0, -1.0)
    coll_scene.objects.link(floor_obj)
    floor_obj.data.materials.append(mat_floor)
    
    world = bpy.data.worlds.new("Frostbite_World")
    bpy.context.scene.world = world
    world.use_nodes = True
    wnt = world.node_tree
    wbg = wnt.nodes.get("Background")
    if wbg:
        wbg.inputs["Color"].default_value = (0.12, 0.16, 0.22, 1.0)
        wbg.inputs["Strength"].default_value = 0.35
        
    return chair_objects, root_empty

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
        scene.cycles.max_bounces = 16
        scene.cycles.transmission_bounces = 12
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

def add_camera_at(location, target, name="Render_Camera"):
    cam_data = bpy.data.cameras.get(name) or bpy.data.cameras.new(name)
    cam = bpy.data.objects.get(name) or bpy.data.objects.new(name, cam_data)
    coll_scene = get_or_create_collection("Scene")
    if cam.name not in coll_scene.objects:
        coll_scene.objects.link(cam)
        
    cam.location = location
    direction = Vector(target) - Vector(location)
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 50.0
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
    
    center_focus = (0.0, 0.15, 1.25)
    
    camera_views = [
        ("frostbite_three_quarter", ( 2.8, -3.2, 2.2), center_focus),
        ("frostbite_front",         ( 0.0, -4.4, 1.35), center_focus),
        ("frostbite_side",          ( 4.2,  0.2, 1.35), center_focus),
        ("frostbite_back",          ( 0.0,  4.4, 1.45), center_focus),
        ("frostbite_top",           ( 1.8, -2.4, 4.4), center_focus),
        ("frostbite_closeup_gem",   ( 0.0, -1.2, 2.15), (0.0, 0.28, 2.15)),
        ("frostbite_closeup_base",  ( 0.0, -1.8, 0.60), (0.0, -0.30, 0.60)),
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
    
    print("[1/5] Building Frostbite Ice Throne Chair...")
    chair_objs, root_empty = build_frostbite_throne()
    
    print(f"[2/5] Hierarchy assembled: {len(chair_objs)} modular objects parented to '{root_empty.name}'.")
    
    print("[3/5] Setting up render engine (EEVEE preview)...")
    setup_render_engine(engine="EEVEE")
    
    print("[4/5] Rendering 7 turnaround preview views...")
    preview_paths = render_turnaround_views(preview_dir)
    
    print("[5/5] Exporting assets (.blend, .glb, .fbx)...")
    base_export = os.path.join(out_dir, "FrostbiteIceThrone")
    
    blend_path = base_export + ".blend"
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(blend_path))
    print(f"  [Export Blend] {blend_path}")
    
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in chair_objs:
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
    print("FROSTBITE ICE THRONE CHAIR BUILD COMPLETE!")
    print(f"  Modular Objects: {len(chair_objs)}")
    print(f"  Root Parent: {root_empty.name}")
    print(f"  Collections: Chair, Effects, Lights, Scene")
    print(f"  Previews: {len(preview_paths)} images rendered in '{preview_dir}'")
    print(f"  Files: {blend_path}, {glb_path}, {fbx_path}")
    print("  Note: To switch to Cycles beauty render, run: bpy.context.scene.render.engine = 'CYCLES'")
    print("=" * 60)

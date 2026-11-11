"""Deterministic build script for the Crimson Flame Chair (semi-realistic hero asset).

Built to match concept art: media_1794291716946_ad7a1488.jpg
Style: Semi-realistic AA hero asset with bold inverted hull ink outline.
Output: .blend, .glb, .fbx, and multi-angle preview PNGs.
"""

import sys
import os
import math

# Add semi-realistic skill scripts to sys.path
SKILL_SCRIPTS = "C:/Users/Lenovo/.gemini/config/skills/semi-realistic/scripts"
if SKILL_SCRIPTS not in sys.path:
    sys.path.insert(0, SKILL_SCRIPTS)

import bpy
import bmesh
from mathutils import Vector, Matrix, Euler

import setup_scene as S
import modeling_helpers as M
import shader_helpers as SH
import outline_helpers as OL
import validate_model as V

# --------------------------------------------------------------------------
# Proportions & Dimensions (Meters, Z up, Subject faces -Y)
# --------------------------------------------------------------------------
SEAT_SIZE = (0.68, 0.68, 0.09)          # W x D x H
SEAT_Z = 0.495                           # Center Z (0.45 to 0.54)

LEG_SIZE = (0.125, 0.125, 0.45)        # W x D x H
LEG_OFFSETS = [
    ("FL", -0.24, -0.24),
    ("FR",  0.24, -0.24),
    ("BL", -0.24,  0.24),
    ("BR",  0.24,  0.24),
]

POST_SIZE = (0.125, 0.125, 0.81)        # W x D x H
POST_Z = 0.945                           # Center Z (0.54 to 1.35)
POST_OFFSETS = [
    ("L", -0.24, 0.24),
    ("R",  0.24, 0.24),
]

BACKREST_SIZE = (0.355, 0.045, 0.74)    # W x D x H (recessed between posts)
BACKREST_POS = (0.0, 0.24, 0.95)

# --------------------------------------------------------------------------
# Custom Material Builders
# --------------------------------------------------------------------------
def make_ruby_gem_material(name="Gem_Ruby"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    bsdf.inputs["Base Color"].default_value = (0.95, 0.05, 0.10, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.12
    bsdf.inputs["IOR"].default_value = 1.76
    SH._set(bsdf, "Transmission Weight", 0.6)
    bsdf.inputs["Emission Color"].default_value = (1.0, 0.08, 0.15, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 3.5
    return mat

def make_stylized_flame_material(name="Flame_Stylized"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    emission = nt.nodes.new("ShaderNodeEmission")
    emission.location = (350, 0)
    nt.links.new(emission.outputs["Emission"], out.inputs["Surface"])
    
    # Layer Weight facing gradient gives vibrant hot core and rich dark crimson edge
    layer_weight = nt.nodes.new("ShaderNodeLayerWeight")
    layer_weight.location = (-400, 100)
    layer_weight.inputs["Blend"].default_value = 0.35
    
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-150, 100)
    nt.links.new(layer_weight.outputs["Facing"], ramp.inputs["Fac"])
    
    # 0.0 rim -> Deep rich dark crimson
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.48, 0.015, 0.05, 1.0)
    
    # 0.45 body -> Intense burning scarlet
    ramp.color_ramp.elements.new(0.45)
    ramp.color_ramp.elements[1].color = (0.95, 0.06, 0.05, 1.0)
    
    # 0.85 -> Hot fiery orange
    ramp.color_ramp.elements.new(0.85)
    ramp.color_ramp.elements[2].color = (1.0, 0.40, 0.06, 1.0)
    
    # 1.0 core -> Golden amber core
    ramp.color_ramp.elements[3].position = 1.0
    ramp.color_ramp.elements[3].color = (1.0, 0.85, 0.20, 1.0)
    
    nt.links.new(ramp.outputs["Color"], emission.inputs["Color"])
    emission.inputs["Strength"].default_value = 2.4
    return mat

# --------------------------------------------------------------------------
# Mesh Geometry Helpers
# --------------------------------------------------------------------------
def create_flame_blade(bm, spine, widths, thicknesses, up_ref=Vector((0, 0, 1)), close_base=False):
    """Create a stylized tapered 3D flame blade along a spine path.
    close_base=False prevents normal inversion artifacts on open base geometry."""
    rings = []
    for i, p in enumerate(spine):
        if i == len(spine) - 1:
            v_tip = bm.verts.new(p)
            rings.append([v_tip])
        else:
            p_next = spine[i+1]
            t = (p_next - p).normalized()
            if abs(t.dot(up_ref)) > 0.85:
                ref = Vector((1, 0, 0)) if abs(t.x) < 0.85 else Vector((0, 1, 0))
            else:
                ref = up_ref
            l = t.cross(ref).normalized()
            n = t.cross(l).normalized()
            l = n.cross(t).normalized()
            
            w = widths[i] * 0.5
            th = thicknesses[i] * 0.5
            
            v0 = bm.verts.new(p - l * w)
            v1 = bm.verts.new(p + n * th)
            v2 = bm.verts.new(p + l * w)
            v3 = bm.verts.new(p - n * th)
            rings.append([v0, v1, v2, v3])
            
    # Connect rings
    for i in range(len(rings) - 2):
        r1, r2 = rings[i], rings[i+1]
        for j in range(4):
            bm.faces.new([r1[j], r2[j], r2[(j+1)%4], r1[(j+1)%4]])
            
    # Connect last ring to apex tip
    last_r = rings[-2]
    tip = rings[-1][0]
    for j in range(4):
        bm.faces.new([last_r[(j+1)%4], last_r[j], tip])
        
    if close_base:
        bm.faces.new([rings[0][0], rings[0][1], rings[0][2], rings[0][3]])
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

def create_diamond_stud(bm, center, normal, up, width=0.028, height=0.028, depth=0.014, back_depth=0.004):
    """Create a faceted 8-faced diamond gem stud."""
    n = Vector(normal).normalized()
    u = Vector(up).normalized()
    r = n.cross(u).normalized()
    u = r.cross(n).normalized()
    
    p = Vector(center)
    v_top = bm.verts.new(p + u * (height * 0.5))
    v_right = bm.verts.new(p + r * (width * 0.5))
    v_bottom = bm.verts.new(p - u * (height * 0.5))
    v_left = bm.verts.new(p - r * (width * 0.5))
    
    v_apex_front = bm.verts.new(p + n * depth)
    v_apex_back = bm.verts.new(p - n * back_depth)
    
    bm.faces.new([v_top, v_right, v_apex_front])
    bm.faces.new([v_right, v_bottom, v_apex_front])
    bm.faces.new([v_bottom, v_left, v_apex_front])
    bm.faces.new([v_left, v_top, v_apex_front])
    
    bm.faces.new([v_right, v_top, v_apex_back])
    bm.faces.new([v_bottom, v_right, v_apex_back])
    bm.faces.new([v_left, v_bottom, v_apex_back])
    bm.faces.new([v_top, v_left, v_apex_back])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

def build_tribal_emblem(bm, scale=1.0, depth=0.003):
    """Build symmetrical gothic flame sigil in X-Z plane, extruded in Y (quads/tris only, no ngons)."""
    # Build center flame spear
    v_tip_top = bm.verts.new(Vector((0.0, 0.0, 0.20 * scale)))
    v_taper_r = bm.verts.new(Vector((0.028 * scale, 0.0, 0.15 * scale)))
    v_taper_l = bm.verts.new(Vector((-0.028 * scale, 0.0, 0.15 * scale)))
    v_barb1_r = bm.verts.new(Vector((0.055 * scale, 0.0, 0.13 * scale)))
    v_barb1_l = bm.verts.new(Vector((-0.055 * scale, 0.0, 0.13 * scale)))
    v_in1_r   = bm.verts.new(Vector((0.025 * scale, 0.0, 0.10 * scale)))
    v_in1_l   = bm.verts.new(Vector((-0.025 * scale, 0.0, 0.10 * scale)))
    v_mid_r   = bm.verts.new(Vector((0.045 * scale, 0.0, 0.04 * scale)))
    v_mid_l   = bm.verts.new(Vector((-0.045 * scale, 0.0, 0.04 * scale)))
    v_waist_r = bm.verts.new(Vector((0.020 * scale, 0.0, -0.01 * scale)))
    v_waist_l = bm.verts.new(Vector((-0.020 * scale, 0.0, -0.01 * scale)))
    v_barb2_r = bm.verts.new(Vector((0.042 * scale, 0.0, -0.07 * scale)))
    v_barb2_l = bm.verts.new(Vector((-0.042 * scale, 0.0, -0.07 * scale)))
    v_in2_r   = bm.verts.new(Vector((0.018 * scale, 0.0, -0.09 * scale)))
    v_in2_l   = bm.verts.new(Vector((-0.018 * scale, 0.0, -0.09 * scale)))
    v_tip_bot = bm.verts.new(Vector((0.0, 0.0, -0.15 * scale)))
    
    # Triangulate/quad front face cleanly without ngons
    f_list = [
        bm.faces.new([v_tip_top, v_taper_r, v_taper_l]),
        bm.faces.new([v_taper_r, v_barb1_r, v_in1_r]),
        bm.faces.new([v_taper_l, v_in1_l, v_barb1_l]),
        bm.faces.new([v_taper_r, v_in1_r, v_in1_l, v_taper_l]),
        bm.faces.new([v_in1_r, v_mid_r, v_mid_l, v_in1_l]),
        bm.faces.new([v_mid_r, v_waist_r, v_waist_l, v_mid_l]),
        bm.faces.new([v_waist_r, v_barb2_r, v_in2_r]),
        bm.faces.new([v_waist_l, v_in2_l, v_barb2_l]),
        bm.faces.new([v_waist_r, v_in2_r, v_in2_l, v_waist_l]),
        bm.faces.new([v_in2_r, v_tip_bot, v_in2_l]),
    ]
    
    # Left outer curved wing horn (quads/tris)
    wl_0 = bm.verts.new(Vector((-0.025 * scale, 0.0, 0.01 * scale)))
    wl_1 = bm.verts.new(Vector((-0.070 * scale, 0.0, 0.05 * scale)))
    wl_2 = bm.verts.new(Vector((-0.120 * scale, 0.0, 0.11 * scale)))
    wl_3 = bm.verts.new(Vector((-0.110 * scale, 0.0, 0.18 * scale)))
    wl_4 = bm.verts.new(Vector((-0.085 * scale, 0.0, 0.14 * scale)))
    wl_5 = bm.verts.new(Vector((-0.065 * scale, 0.0, 0.07 * scale)))
    wl_6 = bm.verts.new(Vector((-0.020 * scale, 0.0, -0.04 * scale)))
    f_list.append(bm.faces.new([wl_0, wl_1, wl_5, wl_6]))
    f_list.append(bm.faces.new([wl_1, wl_2, wl_4, wl_5]))
    f_list.append(bm.faces.new([wl_2, wl_3, wl_4]))
    
    # Right outer curved wing horn (mirrored)
    wr_0 = bm.verts.new(Vector((0.025 * scale, 0.0, 0.01 * scale)))
    wr_1 = bm.verts.new(Vector((0.070 * scale, 0.0, 0.05 * scale)))
    wr_2 = bm.verts.new(Vector((0.120 * scale, 0.0, 0.11 * scale)))
    wr_3 = bm.verts.new(Vector((0.110 * scale, 0.0, 0.18 * scale)))
    wr_4 = bm.verts.new(Vector((0.085 * scale, 0.0, 0.14 * scale)))
    wr_5 = bm.verts.new(Vector((0.065 * scale, 0.0, 0.07 * scale)))
    wr_6 = bm.verts.new(Vector((0.020 * scale, 0.0, -0.04 * scale)))
    f_list.append(bm.faces.new([wr_0, wr_6, wr_5, wr_1]))
    f_list.append(bm.faces.new([wr_1, wr_5, wr_4, wr_2]))
    f_list.append(bm.faces.new([wr_2, wr_4, wr_3]))
    
    # Extrude along Y by depth
    res = bmesh.ops.extrude_face_region(bm, geom=f_list)
    ext_verts = [v for v in res["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=Vector((0, depth, 0)), verts=ext_verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

# --------------------------------------------------------------------------
# Main Assembly Function
# --------------------------------------------------------------------------
def build():
    S.clear_scene()
    coll = M.collection("CrimsonFlameChair")
    
    # Rich semi-realistic PBR materials
    mat_wood_crimson = SH.make_material("Wood_Crimson", "wood", color="#7D0C15", rough=(0.48, 0.68), var=0.06, bump=0.06)
    mat_wood_legs = SH.make_material("Wood_Legs", "wood", color="#580810", rough=(0.50, 0.70), var=0.06, bump=0.06)
    mat_iron = SH.make_material("Iron_Dark", "painted_metal", color="#1A1618", metallic=0.90, rough=(0.38, 0.52), var=0.04, edge_wear=True, wear_color="#4A4548")
    mat_emblem = SH.make_material("Emblem_Dark", "wood", color="#14060A", rough=(0.65, 0.85), var=0.04)
    mat_gem = make_ruby_gem_material("Gem_Ruby")
    mat_flame = make_stylized_flame_material("Flame_Stylized")
    
    built_objects = []
    
    # ----------------------------------------------------------------------
    # 1. Seat
    # ----------------------------------------------------------------------
    seat = M.box("Seat", location=(0, 0, SEAT_Z), size=SEAT_SIZE, coll=coll)
    M.bevel(seat, width=0.006, segments=3)
    M.apply_modifiers(seat)
    M.shade_smooth_by_angle(seat, 35)
    M.assign_material(seat, mat_wood_crimson)
    built_objects.append(seat)
    
    # ----------------------------------------------------------------------
    # 2. 4 Legs
    # ----------------------------------------------------------------------
    legs = []
    for suffix, lx, ly in LEG_OFFSETS:
        leg = M.box(f"Leg_{suffix}", location=(lx, ly, LEG_SIZE[2] / 2), size=LEG_SIZE, coll=coll)
        M.bevel(leg, width=0.005, segments=3)
        M.apply_modifiers(leg)
        M.shade_smooth_by_angle(leg, 35)
        M.assign_material(leg, mat_wood_legs)
        legs.append(leg)
    built_objects.extend(legs)
    
    # ----------------------------------------------------------------------
    # 3. 4 Iron Leg Base Caps
    # ----------------------------------------------------------------------
    leg_caps = []
    cap_h = 0.085
    cap_w = 0.142
    for suffix, lx, ly in LEG_OFFSETS:
        cap = M.box(f"IronCap_Leg_{suffix}", location=(lx, ly, cap_h / 2), size=(cap_w, cap_w, cap_h), coll=coll)
        M.bevel(cap, width=0.005, segments=3)
        M.apply_modifiers(cap)
        M.shade_smooth_by_angle(cap, 35)
        M.assign_material(cap, mat_iron)
        leg_caps.append(cap)
    built_objects.extend(leg_caps)
    
    # ----------------------------------------------------------------------
    # 4. 2 Backrest Posts
    # ----------------------------------------------------------------------
    posts = []
    for suffix, px, py in POST_OFFSETS:
        post = M.box(f"Post_{suffix}", location=(px, py, POST_Z), size=POST_SIZE, coll=coll)
        M.bevel(post, width=0.005, segments=3)
        M.apply_modifiers(post)
        M.shade_smooth_by_angle(post, 35)
        M.assign_material(post, mat_wood_crimson)
        posts.append(post)
    built_objects.extend(posts)
    
    # ----------------------------------------------------------------------
    # 5. 2 Iron Post Top Caps
    # ----------------------------------------------------------------------
    post_caps = []
    pcap_h = 0.085
    pcap_w = 0.144
    pcap_z = 0.54 + 0.81 + (pcap_h / 2) # 1.392 m
    for suffix, px, py in POST_OFFSETS:
        pcap = M.box(f"IronCap_Post_{suffix}", location=(px, py, pcap_z), size=(pcap_w, pcap_w, pcap_h), coll=coll)
        M.bevel(pcap, width=0.006, segments=3)
        M.apply_modifiers(pcap)
        M.shade_smooth_by_angle(pcap, 35)
        M.assign_material(pcap, mat_iron)
        post_caps.append(pcap)
    built_objects.extend(post_caps)
    
    # ----------------------------------------------------------------------
    # 6. Backrest Panel
    # ----------------------------------------------------------------------
    panel = M.box("Backrest_Panel", location=BACKREST_POS, size=BACKREST_SIZE, coll=coll)
    M.bevel(panel, width=0.005, segments=3)
    M.apply_modifiers(panel)
    M.shade_smooth_by_angle(panel, 35)
    M.assign_material(panel, mat_wood_crimson)
    built_objects.append(panel)
    
    # ----------------------------------------------------------------------
    # 7. Seat Corner Brackets (Iron L-Brackets with Downward Skirt)
    # ----------------------------------------------------------------------
    bm_brackets = bmesh.new()
    bracket_arms = [
        (-0.34, -0.34,  1,  1), # FL
        ( 0.34, -0.34, -1,  1), # FR
        (-0.34,  0.34,  1, -1), # BL
        ( 0.34,  0.34, -1, -1), # BR
    ]
    arm_len = 0.090
    arm_w = 0.035
    arm_t = 0.008
    lip_h = 0.032
    top_z = 0.54
    
    for cx, cy, dx, dy in bracket_arms:
        bx_center = (cx + dx * (arm_len / 2), cy + dy * (arm_w / 2), top_z + (arm_t / 2))
        mat_x = Matrix.Translation(Vector(bx_center)) @ Matrix.Diagonal((arm_len / 2, arm_w / 2, arm_t / 2, 1.0))
        bmesh.ops.create_cube(bm_brackets, size=2.0, matrix=mat_x)
        
        by_center = (cx + dx * (arm_w / 2), cy + dy * (arm_w + (arm_len - arm_w) / 2), top_z + (arm_t / 2))
        mat_y = Matrix.Translation(Vector(by_center)) @ Matrix.Diagonal((arm_w / 2, (arm_len - arm_w) / 2, arm_t / 2, 1.0))
        bmesh.ops.create_cube(bm_brackets, size=2.0, matrix=mat_y)
        
        lip_x_center = (cx + dx * (arm_len / 2), cy - dy * (arm_t / 2), top_z - (lip_h / 2))
        mat_lx = Matrix.Translation(Vector(lip_x_center)) @ Matrix.Diagonal((arm_len / 2, arm_t / 2, lip_h / 2, 1.0))
        bmesh.ops.create_cube(bm_brackets, size=2.0, matrix=mat_lx)
        
        lip_y_center = (cx - dx * (arm_t / 2), cy + dy * (arm_len / 2), top_z - (lip_h / 2))
        mat_ly = Matrix.Translation(Vector(lip_y_center)) @ Matrix.Diagonal((arm_t / 2, arm_len / 2, lip_h / 2, 1.0))
        bmesh.ops.create_cube(bm_brackets, size=2.0, matrix=mat_ly)
        
    bmesh.ops.recalc_face_normals(bm_brackets, faces=bm_brackets.faces)
    brackets_obj = M._object_from_bmesh(bm_brackets, "Seat_Corner_Brackets", coll=coll)
    M.bevel(brackets_obj, width=0.002, segments=2)
    M.apply_modifiers(brackets_obj)
    M.shade_smooth_by_angle(brackets_obj, 35)
    M.assign_material(brackets_obj, mat_iron)
    built_objects.append(brackets_obj)
    
    # ----------------------------------------------------------------------
    # 8. Diamond Ruby Gems (Inlays on Iron Caps & Corner Brackets)
    # ----------------------------------------------------------------------
    bm_gems = bmesh.new()
    
    for cx, cy, dx, dy in bracket_arms:
        g_pos = (cx + dx * 0.026, cy + dy * 0.026, top_z + arm_t)
        create_diamond_stud(bm_gems, g_pos, normal=(0, 0, 1), up=(dx, dy, 0), width=0.026, height=0.026, depth=0.013)
        
    cap_mid_z = cap_h / 2
    create_diamond_stud(bm_gems, (-0.24, -0.24 - cap_w/2, cap_mid_z), normal=(0, -1, 0), up=(0, 0, 1)) # FL front
    create_diamond_stud(bm_gems, (-0.24 - cap_w/2, -0.24, cap_mid_z), normal=(-1, 0, 0), up=(0, 0, 1)) # FL left
    create_diamond_stud(bm_gems, ( 0.24, -0.24 - cap_w/2, cap_mid_z), normal=(0, -1, 0), up=(0, 0, 1)) # FR front
    create_diamond_stud(bm_gems, ( 0.24 + cap_w/2, -0.24, cap_mid_z), normal=( 1, 0, 0), up=(0, 0, 1)) # FR right
    create_diamond_stud(bm_gems, (-0.24,  0.24 + cap_w/2, cap_mid_z), normal=(0,  1, 0), up=(0, 0, 1)) # BL back
    create_diamond_stud(bm_gems, (-0.24 - cap_w/2,  0.24, cap_mid_z), normal=(-1, 0, 0), up=(0, 0, 1)) # BL left
    create_diamond_stud(bm_gems, ( 0.24,  0.24 + cap_w/2, cap_mid_z), normal=(0,  1, 0), up=(0, 0, 1)) # BR back
    create_diamond_stud(bm_gems, ( 0.24 + cap_w/2,  0.24, cap_mid_z), normal=( 1, 0, 0), up=(0, 0, 1)) # BR right
    
    create_diamond_stud(bm_gems, (-0.24, 0.24 - pcap_w/2, pcap_z), normal=(0, -1, 0), up=(0, 0, 1)) # TL front
    create_diamond_stud(bm_gems, (-0.24 - pcap_w/2, 0.24, pcap_z), normal=(-1, 0, 0), up=(0, 0, 1)) # TL left
    create_diamond_stud(bm_gems, ( 0.24, 0.24 - pcap_w/2, pcap_z), normal=(0, -1, 0), up=(0, 0, 1)) # TR front
    create_diamond_stud(bm_gems, ( 0.24 + pcap_w/2, 0.24, pcap_z), normal=( 1, 0, 0), up=(0, 0, 1)) # TR right
    
    gems_obj = M._object_from_bmesh(bm_gems, "Gems_Ruby", coll=coll)
    M.shade_smooth_by_angle(gems_obj, 35)
    M.assign_material(gems_obj, mat_gem)
    built_objects.append(gems_obj)
    
    # ----------------------------------------------------------------------
    # 9. Tribal Flame Emblem (Relief on Backrest & Seat, Clean Topology)
    # ----------------------------------------------------------------------
    bm_emblem_back = bmesh.new()
    build_tribal_emblem(bm_emblem_back, scale=1.5, depth=0.003)
    bmesh.ops.translate(bm_emblem_back, vec=Vector((0.0, 0.24 - (BACKREST_SIZE[1]/2) - 0.002, BACKREST_POS[2])), verts=bm_emblem_back.verts)
    emblem_back_obj = M._object_from_bmesh(bm_emblem_back, "Emblem_Backrest", coll=coll)
    M.bevel(emblem_back_obj, width=0.001, segments=1)
    M.apply_modifiers(emblem_back_obj)
    M.shade_smooth_by_angle(emblem_back_obj, 35)
    M.assign_material(emblem_back_obj, mat_emblem)
    built_objects.append(emblem_back_obj)
    
    bm_emblem_seat = bmesh.new()
    build_tribal_emblem(bm_emblem_seat, scale=1.15, depth=0.003)
    rot_x = Matrix.Rotation(math.radians(-90), 4, 'X')
    bmesh.ops.transform(bm_emblem_seat, matrix=rot_x, verts=bm_emblem_seat.verts)
    bmesh.ops.translate(bm_emblem_seat, vec=Vector((0.0, 0.0, top_z + 0.001)), verts=bm_emblem_seat.verts)
    bmesh.ops.recalc_face_normals(bm_emblem_seat, faces=bm_emblem_seat.faces)
    emblem_seat_obj = M._object_from_bmesh(bm_emblem_seat, "Emblem_Seat", coll=coll)
    M.bevel(emblem_seat_obj, width=0.001, segments=1)
    M.apply_modifiers(emblem_seat_obj)
    M.shade_smooth_by_angle(emblem_seat_obj, 35)
    M.assign_material(emblem_seat_obj, mat_emblem)
    built_objects.append(emblem_seat_obj)
    
    # ----------------------------------------------------------------------
    # 10. Stylized 3D Flames (Full, Broad Overlapping Wings & Collars)
    # ----------------------------------------------------------------------
    bm_flames = bmesh.new()
    
    def add_mirrored_flame(spine, widths, thicknesses):
        create_flame_blade(bm_flames, spine, widths, thicknesses, close_base=False)
        spine_r = [Vector((-p.x, p.y, p.z)) for p in spine]
        create_flame_blade(bm_flames, spine_r, widths, thicknesses, close_base=False)
        
    # --- A. Backrest Flank Flame Wings (Dense, dramatic anime-styled wings) ---
    # Flame 1: Lower billowing flare
    add_mirrored_flame(
        spine=[
            Vector((-0.26, 0.23, 0.50)),
            Vector((-0.34, 0.25, 0.60)),
            Vector((-0.43, 0.26, 0.72)),
            Vector((-0.39, 0.27, 0.84)),
            Vector((-0.30, 0.24, 0.90))
        ],
        widths=[0.06, 0.16, 0.18, 0.09, 0.0],
        thicknesses=[0.025, 0.05, 0.05, 0.025, 0.0]
    )
    
    # Flame 2: Main dramatic mid-wing flare
    add_mirrored_flame(
        spine=[
            Vector((-0.26, 0.22, 0.70)),
            Vector((-0.38, 0.25, 0.84)),
            Vector((-0.50, 0.28, 1.00)),
            Vector((-0.53, 0.29, 1.14)),
            Vector((-0.45, 0.27, 1.26)),
            Vector((-0.32, 0.24, 1.34))
        ],
        widths=[0.08, 0.19, 0.24, 0.18, 0.08, 0.0],
        thicknesses=[0.03, 0.06, 0.065, 0.045, 0.02, 0.0]
    )
    
    # Flame 3: Upper outer wing tongue
    add_mirrored_flame(
        spine=[
            Vector((-0.27, 0.23, 1.00)),
            Vector((-0.38, 0.26, 1.18)),
            Vector((-0.47, 0.28, 1.34)),
            Vector((-0.41, 0.26, 1.46)),
            Vector((-0.28, 0.24, 1.54))
        ],
        widths=[0.07, 0.15, 0.17, 0.09, 0.0],
        thicknesses=[0.025, 0.05, 0.05, 0.025, 0.0]
    )
    
    # Flame 4: Inner front-lapping flame tongue (layered 3D depth)
    add_mirrored_flame(
        spine=[
            Vector((-0.28, 0.16, 0.62)),
            Vector((-0.35, 0.13, 0.78)),
            Vector((-0.39, 0.12, 0.94)),
            Vector((-0.34, 0.15, 1.06)),
            Vector((-0.28, 0.19, 1.14))
        ],
        widths=[0.05, 0.13, 0.14, 0.07, 0.0],
        thicknesses=[0.02, 0.04, 0.04, 0.018, 0.0]
    )
    
    # --- B. Crown Flames (Billowing above post caps) ---
    add_mirrored_flame(
        spine=[
            Vector((-0.24, 0.22, 1.39)),
            Vector((-0.27, 0.26, 1.50)),
            Vector((-0.26, 0.29, 1.60)),
            Vector((-0.20, 0.27, 1.70)),
            Vector((-0.12, 0.24, 1.76))
        ],
        widths=[0.08, 0.15, 0.14, 0.07, 0.0],
        thicknesses=[0.035, 0.05, 0.045, 0.02, 0.0]
    )
    add_mirrored_flame(
        spine=[
            Vector((-0.19, 0.22, 1.41)),
            Vector((-0.17, 0.24, 1.52)),
            Vector((-0.12, 0.23, 1.60)),
            Vector((-0.06, 0.21, 1.65))
        ],
        widths=[0.05, 0.09, 0.07, 0.0],
        thicknesses=[0.02, 0.035, 0.018, 0.0]
    )
    
    # --- C. Leg Base Flames (Licking broad tongues, base safely inside cap) ---
    for lx, ly in [(-0.24, -0.24), (0.24, -0.24), (-0.24, 0.24), (0.24, 0.24)]:
        sx = 1 if lx > 0 else -1
        sy = 1 if ly > 0 else -1
        
        # Outer diagonal tongue (starts at z=0.06 inside cap, flares out above cap)
        create_flame_blade(
            bm_flames,
            spine=[
                Vector((lx + sx * 0.04, ly + sy * 0.04, 0.06)),
                Vector((lx + sx * 0.09, ly + sy * 0.09, 0.13)),
                Vector((lx + sx * 0.13, ly + sy * 0.12, 0.23)),
                Vector((lx + sx * 0.10, ly + sy * 0.08, 0.33)),
                Vector((lx + sx * 0.05, ly + sy * 0.04, 0.39))
            ],
            widths=[0.03, 0.11, 0.10, 0.05, 0.0],
            thicknesses=[0.015, 0.04, 0.035, 0.018, 0.0],
            close_base=False
        )
        
        # Front/rear licking tongue
        create_flame_blade(
            bm_flames,
            spine=[
                Vector((lx, ly + sy * 0.05, 0.06)),
                Vector((lx + sx * 0.02, ly + sy * 0.09, 0.13)),
                Vector((lx, ly + sy * 0.08, 0.22)),
                Vector((lx - sx * 0.02, ly + sy * 0.05, 0.27))
            ],
            widths=[0.03, 0.08, 0.05, 0.0],
            thicknesses=[0.015, 0.03, 0.018, 0.0],
            close_base=False
        )
        
        # Side licking tongue
        create_flame_blade(
            bm_flames,
            spine=[
                Vector((lx + sx * 0.05, ly, 0.06)),
                Vector((lx + sx * 0.09, ly - sy * 0.02, 0.12)),
                Vector((lx + sx * 0.08, ly, 0.19)),
                Vector((lx + sx * 0.04, ly + sy * 0.02, 0.25))
            ],
            widths=[0.03, 0.08, 0.05, 0.0],
            thicknesses=[0.015, 0.03, 0.018, 0.0],
            close_base=False
        )
        
    bmesh.ops.recalc_face_normals(bm_flames, faces=bm_flames.faces)
    flames_obj = M._object_from_bmesh(bm_flames, "Flames_Stylized", coll=coll)
    M.shade_smooth_by_angle(flames_obj, 35)
    M.assign_material(flames_obj, mat_flame)
    built_objects.append(flames_obj)
    
    # --- D. Floating Sparks / Embers ---
    bm_embers = bmesh.new()
    ember_locations = [
        (-0.55, 0.29, 1.20),
        ( 0.55, 0.29, 1.20),
        (-0.47, 0.27, 0.84),
        ( 0.47, 0.27, 0.84),
        (-0.27, 0.26, 1.78),
        ( 0.27, 0.26, 1.78),
        ( 0.00, 0.23, 1.72),
    ]
    for ex, ey, ez in ember_locations:
        create_diamond_stud(bm_embers, (ex, ey, ez), normal=(0, 0, 1), up=(0.5, 0.5, 0.7), width=0.022, height=0.022, depth=0.015)
        
    bmesh.ops.recalc_face_normals(bm_embers, faces=bm_embers.faces)
    embers_obj = M._object_from_bmesh(bm_embers, "Embers_Floating", coll=coll)
    M.shade_smooth_by_angle(embers_obj, 35)
    M.assign_material(embers_obj, mat_flame)
    built_objects.append(embers_obj)
    
    # ----------------------------------------------------------------------
    # Stage 4: Apply transforms and generate Smart UVs
    # ----------------------------------------------------------------------
    for obj in built_objects:
        M.apply_transforms(obj, location=False, rotation=True, scale=True)
        M.smart_uv(obj, angle_deg=66, margin=0.02)
        
    # ----------------------------------------------------------------------
    # Mandatory Ink Outline (uniform 2.8 mm crisp ink line)
    # ----------------------------------------------------------------------
    OL.add_outlines(built_objects, thickness=0.0028, color="#0A0A0F")
    
    return built_objects

# --------------------------------------------------------------------------
# Main Execution Entrypoint
# --------------------------------------------------------------------------
if __name__ == "__main__":
    out_dir = "d:/BAF/models"
    preview_dir = os.path.join(out_dir, "previews")
    os.makedirs(preview_dir, exist_ok=True)
    
    print("[1/5] Building Crimson Flame Chair...")
    objs = build()
    
    print("[2/5] Setting up preview lighting & camera...")
    S.quick_preview_setup(objs, engine="CYCLES", resolution=(1024, 1024))
    
    print("[3/5] Rendering multi-angle previews...")
    views = {
        "chair_front": (0, 8),
        "chair_three_quarter": (35, 15),
        "chair_side": (90, 8),
        "chair_back": (180, 8),
        "chair_top_angle": (25, 45),
    }
    preview_paths = S.render_views(preview_dir, objs=objs, views=views, lens=50, resolution=(1024, 1024))
    
    print("[4/5] Validating model...")
    # Keep outlines active so outline_tris passes validation check
    rep = V.run(max_tris=40000, verbose=True)
    
    print("[5/5] Exporting assets (.blend, .glb, .fbx)...")
    base_export = os.path.join(out_dir, "CrimsonFlameChair")
    exported = S.export_model(objs, base_export, formats=("blend", "glb", "fbx"))
    
    print("Build complete!")
    for p in exported:
        print(f"  Output: {p}")

"""Deterministic build script for the Cyber Core Chair (semi-realistic hero asset).

Built to match concept art: media_1794305018370_797600a7.jpg
Theme: CYBER CORE (dark metal armor, glowing neon cyan/magenta/purple circuits, energy core).
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
# Custom Material Builders (PBR & High-Tech Neon)
# --------------------------------------------------------------------------
def make_cyber_metal(name="Cyber_Metal_Dark", color="#121420", rough=(0.35, 0.48), wear_color="#3A4256"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    base_rgba = (*SH.hex_to_linear(color), 1.0)
    bsdf.inputs["Base Color"].default_value = base_rgba
    bsdf.inputs["Metallic"].default_value = 0.88
    bsdf.inputs["Roughness"].default_value = (rough[0] + rough[1]) / 2
    SH._set(bsdf, "Specular IOR Level", 0.6)
    return mat

def make_neon_material(name, hex_color, strength=5.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    rgba = (*SH.hex_to_linear(hex_color), 1.0)
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = 0.15
    bsdf.inputs["Emission Color"].default_value = rgba
    bsdf.inputs["Emission Strength"].default_value = strength
    return mat

def make_core_crystal_material(name="Core_Crystal"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    bsdf.inputs["Base Color"].default_value = (0.05, 0.95, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.08
    bsdf.inputs["IOR"].default_value = 1.76
    SH._set(bsdf, "Transmission Weight", 0.70)
    bsdf.inputs["Emission Color"].default_value = (0.0, 1.0, 0.95, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 6.0
    return mat

def make_holo_ring_material(name="Holo_Ring"):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    
    bsdf.inputs["Base Color"].default_value = (0.0, 0.9, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.2
    SH._set(bsdf, "Transmission Weight", 0.5)
    bsdf.inputs["Emission Color"].default_value = (0.0, 1.0, 0.95, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 3.5
    return mat

# --------------------------------------------------------------------------
# Mesh Geometry Helpers
# --------------------------------------------------------------------------
def create_diamond_stud(bm, center, normal, up, width=0.024, height=0.024, depth=0.012, back_depth=0.003):
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

def create_octahedron_core(bm, center, radius=0.05, height_scale=1.4):
    """Create floating faceted crystal core rotated 45 deg."""
    p = Vector(center)
    h = radius * height_scale
    r = radius
    
    # 4 equator vertices in X-Z plane
    v_e0 = bm.verts.new(p + Vector(( r, 0,  0)))
    v_e1 = bm.verts.new(p + Vector(( 0, 0,  r)))
    v_e2 = bm.verts.new(p + Vector((-r, 0,  0)))
    v_e3 = bm.verts.new(p + Vector(( 0, 0, -r)))
    
    # Front and back apexes along Y (depth)
    v_top = bm.verts.new(p + Vector((0,  r * 0.7, 0)))
    v_bot = bm.verts.new(p + Vector((0, -r * 0.7, 0)))
    
    # Faces
    bm.faces.new([v_e0, v_e1, v_top])
    bm.faces.new([v_e1, v_e2, v_top])
    bm.faces.new([v_e2, v_e3, v_top])
    bm.faces.new([v_e3, v_e0, v_top])
    
    bm.faces.new([v_e1, v_e0, v_bot])
    bm.faces.new([v_e2, v_e1, v_bot])
    bm.faces.new([v_e3, v_e2, v_bot])
    bm.faces.new([v_e0, v_e3, v_bot])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

def create_circuit_strip(bm, p_start, p_end, normal, width=0.007, depth=0.003):
    """Create a rectangular beveled 3D circuit line segment along a surface."""
    p0 = Vector(p_start)
    p1 = Vector(p_end)
    n = Vector(normal).normalized()
    d = p1 - p0
    length = d.length
    if length < 1e-5:
        return
    tangent = d.normalized()
    side = tangent.cross(n).normalized()
    
    hw = width * 0.5
    hd = depth
    
    # 4 bottom vertices (on surface)
    b0 = p0 - side * hw
    b1 = p0 + side * hw
    b2 = p1 + side * hw
    b3 = p1 - side * hw
    
    # 4 top vertices (raised)
    t0 = b0 + n * hd
    t1 = b1 + n * hd
    t2 = b2 + n * hd
    t3 = b3 + n * hd
    
    v_b0 = bm.verts.new(b0)
    v_b1 = bm.verts.new(b1)
    v_b2 = bm.verts.new(b2)
    v_b3 = bm.verts.new(b3)
    
    v_t0 = bm.verts.new(t0)
    v_t1 = bm.verts.new(t1)
    v_t2 = bm.verts.new(t2)
    v_t3 = bm.verts.new(t3)
    
    # 6 faces of the strip box
    bm.faces.new([v_t0, v_t1, v_t2, v_t3]) # top
    bm.faces.new([v_b3, v_b2, v_b1, v_b0]) # bottom
    bm.faces.new([v_b0, v_b1, v_t1, v_t0]) # start cap
    bm.faces.new([v_b1, v_b2, v_t2, v_t1]) # right side
    bm.faces.new([v_b2, v_b3, v_t3, v_t2]) # end cap
    bm.faces.new([v_b3, v_b0, v_t0, v_t3]) # left side
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

def create_circular_ring(bm, center, normal, radius, width=0.008, depth=0.003, segments=32):
    """Create a 3D circular circuit ring."""
    c = Vector(center)
    n = Vector(normal).normalized()
    up = Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((0, 1, 0))
    u = n.cross(up).normalized()
    v = n.cross(u).normalized()
    
    r_in = radius - width * 0.5
    r_out = radius + width * 0.5
    
    verts_b_in = []
    verts_b_out = []
    verts_t_in = []
    verts_t_out = []
    
    for i in range(segments):
        theta = (2 * math.pi * i) / segments
        dir_vec = u * math.cos(theta) + v * math.sin(theta)
        
        p_bin = c + dir_vec * r_in
        p_bout = c + dir_vec * r_out
        p_tin = p_bin + n * depth
        p_tout = p_bout + n * depth
        
        verts_b_in.append(bm.verts.new(p_bin))
        verts_b_out.append(bm.verts.new(p_bout))
        verts_t_in.append(bm.verts.new(p_tin))
        verts_t_out.append(bm.verts.new(p_tout))
        
    for i in range(segments):
        next_i = (i + 1) % segments
        # Top ring face
        bm.faces.new([verts_t_in[i], verts_t_out[i], verts_t_out[next_i], verts_t_in[next_i]])
        # Bottom ring face
        bm.faces.new([verts_b_out[i], verts_b_in[i], verts_b_in[next_i], verts_b_out[next_i]])
        # Inner wall
        bm.faces.new([verts_b_in[i], verts_t_in[i], verts_t_in[next_i], verts_b_in[next_i]])
        # Outer wall
        bm.faces.new([verts_t_out[i], verts_b_out[i], verts_b_out[next_i], verts_t_out[next_i]])
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

# --------------------------------------------------------------------------
# Main Assembly Function
# --------------------------------------------------------------------------
def build():
    S.clear_scene()
    coll = M.collection("CyberCoreChair")
    
    # Materials
    mat_metal_dark = make_cyber_metal("Cyber_Metal_Dark", color="#121420", rough=(0.35, 0.48), wear_color="#303850")
    mat_metal_trim = make_cyber_metal("Cyber_Metal_Trim", color="#1C2030", rough=(0.40, 0.55), wear_color="#455070")
    mat_neon_cyan = make_neon_material("Neon_Cyan", hex_color="#00FFF0", strength=5.5)
    mat_neon_magenta = make_neon_material("Neon_Magenta", hex_color="#FF00C8", strength=4.5)
    mat_neon_purple = make_neon_material("Neon_Purple", hex_color="#8C3CFF", strength=3.8)
    mat_core_crystal = make_core_crystal_material("Core_Crystal")
    mat_holo_ring = make_holo_ring_material("Holo_Ring")
    
    built_objects = []
    
    # ----------------------------------------------------------------------
    # 1. Seat (Dark Armor Plate)
    # ----------------------------------------------------------------------
    seat = M.box("Seat", location=(0, 0, SEAT_Z), size=SEAT_SIZE, coll=coll)
    M.bevel(seat, width=0.006, segments=3)
    M.apply_modifiers(seat)
    M.shade_smooth_by_angle(seat, 35)
    M.assign_material(seat, mat_metal_dark)
    built_objects.append(seat)
    
    # ----------------------------------------------------------------------
    # 2. 4 Legs (Chunky Armor Struts)
    # ----------------------------------------------------------------------
    legs = []
    for suffix, lx, ly in LEG_OFFSETS:
        leg = M.box(f"Leg_{suffix}", location=(lx, ly, LEG_SIZE[2] / 2), size=LEG_SIZE, coll=coll)
        M.bevel(leg, width=0.005, segments=3)
        M.apply_modifiers(leg)
        M.shade_smooth_by_angle(leg, 35)
        M.assign_material(leg, mat_metal_dark)
        legs.append(leg)
    built_objects.extend(legs)
    
    # ----------------------------------------------------------------------
    # 3. 4 Leg Base Caps with Chamfers & Neon Purple Trim
    # ----------------------------------------------------------------------
    leg_caps = []
    cap_h = 0.085
    cap_w = 0.142
    for suffix, lx, ly in LEG_OFFSETS:
        cap = M.box(f"MetalCap_Leg_{suffix}", location=(lx, ly, cap_h / 2), size=(cap_w, cap_w, cap_h), coll=coll)
        M.bevel(cap, width=0.006, segments=3)
        M.apply_modifiers(cap)
        M.shade_smooth_by_angle(cap, 35)
        M.assign_material(cap, mat_metal_trim)
        leg_caps.append(cap)
    built_objects.extend(leg_caps)
    
    # Glowing Purple Trim Rings around Leg Caps
    bm_leg_trims = bmesh.new()
    for suffix, lx, ly in LEG_OFFSETS:
        # A band around the top edge of each cap
        trim_size = (cap_w + 0.004, cap_w + 0.004, 0.012)
        trim_loc = (lx, ly, cap_h - 0.008)
        mat_t = Matrix.Translation(Vector(trim_loc)) @ Matrix.Diagonal((trim_size[0]/2, trim_size[1]/2, trim_size[2]/2, 1.0))
        bmesh.ops.create_cube(bm_leg_trims, size=2.0, matrix=mat_t)
        
    bmesh.ops.recalc_face_normals(bm_leg_trims, faces=bm_leg_trims.faces)
    leg_trims_obj = M._object_from_bmesh(bm_leg_trims, "Leg_Cap_Neon_Trims", coll=coll)
    M.bevel(leg_trims_obj, width=0.002, segments=2)
    M.apply_modifiers(leg_trims_obj)
    M.shade_smooth_by_angle(leg_trims_obj, 35)
    M.assign_material(leg_trims_obj, mat_neon_purple)
    built_objects.append(leg_trims_obj)
    
    # ----------------------------------------------------------------------
    # 4. 2 Backrest Posts (Vertical Armor Pillars)
    # ----------------------------------------------------------------------
    posts = []
    for suffix, px, py in POST_OFFSETS:
        post = M.box(f"Post_{suffix}", location=(px, py, POST_Z), size=POST_SIZE, coll=coll)
        M.bevel(post, width=0.005, segments=3)
        M.apply_modifiers(post)
        M.shade_smooth_by_angle(post, 35)
        M.assign_material(post, mat_metal_dark)
        posts.append(post)
    built_objects.extend(posts)
    
    # ----------------------------------------------------------------------
    # 5. 2 Post Top Caps (Faceted Emitter Housings)
    # ----------------------------------------------------------------------
    post_caps = []
    pcap_h = 0.085
    pcap_w = 0.144
    pcap_z = 0.54 + 0.81 + (pcap_h / 2) # 1.392 m
    for suffix, px, py in POST_OFFSETS:
        pcap = M.box(f"MetalCap_Post_{suffix}", location=(px, py, pcap_z), size=(pcap_w, pcap_w, pcap_h), coll=coll)
        M.bevel(pcap, width=0.007, segments=3)
        M.apply_modifiers(pcap)
        M.shade_smooth_by_angle(pcap, 35)
        M.assign_material(pcap, mat_metal_trim)
        post_caps.append(pcap)
    built_objects.extend(post_caps)
    
    # Glowing Purple Trim Bands & Emitter Wells on Top Caps
    bm_post_trims = bmesh.new()
    for suffix, px, py in POST_OFFSETS:
        # Band around the chamfer
        ptrim_size = (pcap_w + 0.004, pcap_w + 0.004, 0.014)
        ptrim_loc = (px, py, pcap_z - 0.015)
        mat_pt = Matrix.Translation(Vector(ptrim_loc)) @ Matrix.Diagonal((ptrim_size[0]/2, ptrim_size[1]/2, ptrim_size[2]/2, 1.0))
        bmesh.ops.create_cube(bm_post_trims, size=2.0, matrix=mat_pt)
        
        # Inset glowing emitter tile on top face
        emitter_size = (0.065, 0.065, 0.006)
        emitter_loc = (px, py, pcap_z + pcap_h / 2 + 0.001)
        mat_em = Matrix.Translation(Vector(emitter_loc)) @ Matrix.Diagonal((emitter_size[0]/2, emitter_size[1]/2, emitter_size[2]/2, 1.0))
        bmesh.ops.create_cube(bm_post_trims, size=2.0, matrix=mat_em)
        
    bmesh.ops.recalc_face_normals(bm_post_trims, faces=bm_post_trims.faces)
    post_trims_obj = M._object_from_bmesh(bm_post_trims, "Post_Cap_Neon_Trims", coll=coll)
    M.bevel(post_trims_obj, width=0.002, segments=2)
    M.apply_modifiers(post_trims_obj)
    M.shade_smooth_by_angle(post_trims_obj, 35)
    M.assign_material(post_trims_obj, mat_neon_purple)
    built_objects.append(post_trims_obj)
    
    # ----------------------------------------------------------------------
    # 6. Backrest Panel (Recessed Terminal Plate)
    # ----------------------------------------------------------------------
    panel = M.box("Backrest_Panel", location=BACKREST_POS, size=BACKREST_SIZE, coll=coll)
    M.bevel(panel, width=0.005, segments=3)
    M.apply_modifiers(panel)
    M.shade_smooth_by_angle(panel, 35)
    M.assign_material(panel, mat_metal_dark)
    built_objects.append(panel)
    
    # ----------------------------------------------------------------------
    # 7. Energy Core (Floating Cyan Diamond Crystal in Center of Backrest)
    # ----------------------------------------------------------------------
    bm_core = bmesh.new()
    core_loc = Vector((0.0, 0.24 - (BACKREST_SIZE[1]/2) - 0.015, BACKREST_POS[2]))
    create_octahedron_core(bm_core, core_loc, radius=0.062, height_scale=1.35)
    core_obj = M._object_from_bmesh(bm_core, "Energy_Core_Crystal", coll=coll)
    M.shade_smooth_by_angle(core_obj, 35)
    M.assign_material(core_obj, mat_core_crystal)
    built_objects.append(core_obj)
    
    # Octagonal/Diamond Cyber Frame surrounding the core
    bm_frame = bmesh.new()
    frame_y = 0.24 - (BACKREST_SIZE[1]/2) - 0.004
    # Frame diamond struts
    d_outer = 0.115
    d_inner = 0.090
    frame_corners = [
        Vector((0, frame_y, BACKREST_POS[2] + d_outer)),
        Vector((d_outer, frame_y, BACKREST_POS[2])),
        Vector((0, frame_y, BACKREST_POS[2] - d_outer)),
        Vector((-d_outer, frame_y, BACKREST_POS[2]))
    ]
    for i in range(4):
        p_a = frame_corners[i]
        p_b = frame_corners[(i+1)%4]
        create_circuit_strip(bm_frame, p_a, p_b, normal=(0, -1, 0), width=0.014, depth=0.006)
        
    bmesh.ops.recalc_face_normals(bm_frame, faces=bm_frame.faces)
    frame_obj = M._object_from_bmesh(bm_frame, "Core_Hex_Frame", coll=coll)
    M.bevel(frame_obj, width=0.002, segments=2)
    M.apply_modifiers(frame_obj)
    M.shade_smooth_by_angle(frame_obj, 35)
    M.assign_material(frame_obj, mat_metal_trim)
    built_objects.append(frame_obj)
    
    # ----------------------------------------------------------------------
    # 8. Seat Corner Brackets (Heavy L-Brackets with Downward Skirt)
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
    M.assign_material(brackets_obj, mat_metal_trim)
    built_objects.append(brackets_obj)
    
    # ----------------------------------------------------------------------
    # 9. Diamond Neon Inlay Nodes (Cyan & Magenta Nodes)
    # ----------------------------------------------------------------------
    bm_nodes_cyan = bmesh.new()
    bm_nodes_magenta = bmesh.new()
    
    # Cyan Diamond Studs on 4 Seat Corner Brackets
    for cx, cy, dx, dy in bracket_arms:
        g_pos = (cx + dx * 0.026, cy + dy * 0.026, top_z + arm_t)
        create_diamond_stud(bm_nodes_cyan, g_pos, normal=(0, 0, 1), up=(dx, dy, 0), width=0.026, height=0.026, depth=0.013)
        
    # Leg Cap Diamond Nodes: Front faces have Cyan, Side faces have Magenta
    cap_mid_z = cap_h / 2
    create_diamond_stud(bm_nodes_cyan,    (-0.24, -0.24 - cap_w/2, cap_mid_z), normal=(0, -1, 0), up=(0, 0, 1)) # FL front
    create_diamond_stud(bm_nodes_magenta, (-0.24 - cap_w/2, -0.24, cap_mid_z), normal=(-1, 0, 0), up=(0, 0, 1)) # FL left
    create_diamond_stud(bm_nodes_cyan,    ( 0.24, -0.24 - cap_w/2, cap_mid_z), normal=(0, -1, 0), up=(0, 0, 1)) # FR front
    create_diamond_stud(bm_nodes_magenta, ( 0.24 + cap_w/2, -0.24, cap_mid_z), normal=( 1, 0, 0), up=(0, 0, 1)) # FR right
    create_diamond_stud(bm_nodes_cyan,    (-0.24,  0.24 + cap_w/2, cap_mid_z), normal=(0,  1, 0), up=(0, 0, 1)) # BL back
    create_diamond_stud(bm_nodes_magenta, (-0.24 - cap_w/2,  0.24, cap_mid_z), normal=(-1, 0, 0), up=(0, 0, 1)) # BL left
    create_diamond_stud(bm_nodes_cyan,    ( 0.24,  0.24 + cap_w/2, cap_mid_z), normal=(0,  1, 0), up=(0, 0, 1)) # BR back
    create_diamond_stud(bm_nodes_magenta, ( 0.24 + cap_w/2,  0.24, cap_mid_z), normal=( 1, 0, 0), up=(0, 0, 1)) # BR right
    
    # Post Cap Diamond Nodes
    create_diamond_stud(bm_nodes_cyan,    (-0.24, 0.24 - pcap_w/2, pcap_z), normal=(0, -1, 0), up=(0, 0, 1)) # TL front
    create_diamond_stud(bm_nodes_magenta, (-0.24 - pcap_w/2, 0.24, pcap_z), normal=(-1, 0, 0), up=(0, 0, 1)) # TL left
    create_diamond_stud(bm_nodes_cyan,    ( 0.24, 0.24 - pcap_w/2, pcap_z), normal=(0, -1, 0), up=(0, 0, 1)) # TR front
    create_diamond_stud(bm_nodes_magenta, ( 0.24 + pcap_w/2, 0.24, pcap_z), normal=( 1, 0, 0), up=(0, 0, 1)) # TR right
    
    # 4 Nodes on the Core Frame corners
    for p in frame_corners:
        create_diamond_stud(bm_nodes_magenta, p + Vector((0, -0.003, 0)), normal=(0, -1, 0), up=(0, 0, 1), width=0.016, height=0.016, depth=0.008)
        
    # ----------------------------------------------------------------------
    # 10. Glowing Circuit Traces (Backrest Network, Seat Target, Leg Conduits)
    # ----------------------------------------------------------------------
    bm_circuits_cyan = bmesh.new()
    bm_circuits_mag = bmesh.new()
    
    # --- A. Backrest Circuit Network (Symmetrical Branches) ---
    py_surf = 0.24 - (BACKREST_SIZE[1]/2) - 0.001
    cz = BACKREST_POS[2]
    
    for sx in [1, -1]:
        # Cyan Path 1: Upper outward branch
        create_circuit_strip(bm_circuits_cyan, (sx * 0.05, py_surf, cz + 0.08), (sx * 0.10, py_surf, cz + 0.13), (0, -1, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_cyan, (sx * 0.10, py_surf, cz + 0.13), (sx * 0.10, py_surf, cz + 0.26), (0, -1, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_cyan, (sx * 0.10, py_surf, cz + 0.26), (sx * 0.15, py_surf, cz + 0.30), (0, -1, 0), width=0.006, depth=0.003)
        create_diamond_stud(bm_nodes_cyan, (sx * 0.15, py_surf - 0.001, cz + 0.30), normal=(0, -1, 0), up=(0, 0, 1), width=0.012, height=0.012, depth=0.005)
        
        # Cyan Path 2: Mid-lateral branch
        create_circuit_strip(bm_circuits_cyan, (sx * 0.10, py_surf, cz), (sx * 0.16, py_surf, cz), (0, -1, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_cyan, (sx * 0.16, py_surf, cz), (sx * 0.16, py_surf, cz + 0.08), (0, -1, 0), width=0.006, depth=0.003)
        create_diamond_stud(bm_nodes_cyan, (sx * 0.16, py_surf - 0.001, cz + 0.08), normal=(0, -1, 0), up=(0, 0, 1), width=0.012, height=0.012, depth=0.005)
        
        # Cyan Path 3: Lower downward branch
        create_circuit_strip(bm_circuits_cyan, (sx * 0.05, py_surf, cz - 0.08), (sx * 0.09, py_surf, cz - 0.12), (0, -1, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_cyan, (sx * 0.09, py_surf, cz - 0.12), (sx * 0.09, py_surf, cz - 0.25), (0, -1, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_cyan, (sx * 0.09, py_surf, cz - 0.25), (sx * 0.14, py_surf, cz - 0.29), (0, -1, 0), width=0.006, depth=0.003)
        create_diamond_stud(bm_nodes_cyan, (sx * 0.14, py_surf - 0.001, cz - 0.29), normal=(0, -1, 0), up=(0, 0, 1), width=0.012, height=0.012, depth=0.005)
        
        # Magenta Accent Circuit Traces
        create_circuit_strip(bm_circuits_mag, (sx * 0.07, py_surf, cz + 0.04), (sx * 0.14, py_surf, cz + 0.04), (0, -1, 0), width=0.005, depth=0.003)
        create_circuit_strip(bm_circuits_mag, (sx * 0.14, py_surf, cz + 0.04), (sx * 0.14, py_surf, cz + 0.18), (0, -1, 0), width=0.005, depth=0.003)
        create_diamond_stud(bm_nodes_magenta, (sx * 0.14, py_surf - 0.001, cz + 0.18), normal=(0, -1, 0), up=(0, 0, 1), width=0.011, height=0.011, depth=0.005)
        
        create_circuit_strip(bm_circuits_mag, (sx * 0.07, py_surf, cz - 0.04), (sx * 0.13, py_surf, cz - 0.04), (0, -1, 0), width=0.005, depth=0.003)
        create_circuit_strip(bm_circuits_mag, (sx * 0.13, py_surf, cz - 0.04), (sx * 0.13, py_surf, cz - 0.18), (0, -1, 0), width=0.005, depth=0.003)
        create_diamond_stud(bm_nodes_magenta, (sx * 0.13, py_surf - 0.001, cz - 0.18), normal=(0, -1, 0), up=(0, 0, 1), width=0.011, height=0.011, depth=0.005)
        
    # --- B. Seat Top Cyber Target (Concentric Rings & Radial Traces) ---
    seat_top_z = top_z + 0.001
    create_circular_ring(bm_circuits_cyan, (0, 0, seat_top_z), normal=(0, 0, 1), radius=0.08, width=0.008, depth=0.003, segments=32)
    create_circular_ring(bm_circuits_cyan, (0, 0, seat_top_z), normal=(0, 0, 1), radius=0.16, width=0.008, depth=0.003, segments=36)
    create_circular_ring(bm_circuits_cyan, (0, 0, seat_top_z), normal=(0, 0, 1), radius=0.24, width=0.010, depth=0.003, segments=40)
    
    # Center Cyan Node
    create_diamond_stud(bm_nodes_cyan, (0, 0, seat_top_z), normal=(0, 0, 1), up=(0, 1, 0), width=0.024, height=0.024, depth=0.006)
    
    # Radial Circuit Lines Shooting to Corners and Edges
    for angle_deg in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(angle_deg)
        cos_a, sin_a = math.cos(rad), math.sin(rad)
        p_start = (cos_a * 0.085, sin_a * 0.085, seat_top_z)
        p_mid = (cos_a * 0.155, sin_a * 0.155, seat_top_z)
        p_end = (cos_a * 0.235, sin_a * 0.235, seat_top_z)
        
        if angle_deg % 90 == 0:
            create_circuit_strip(bm_circuits_cyan, p_start, p_mid, normal=(0, 0, 1), width=0.006, depth=0.003)
            create_circuit_strip(bm_circuits_cyan, (cos_a * 0.165, sin_a * 0.165, seat_top_z), (cos_a * 0.28, sin_a * 0.28, seat_top_z), normal=(0, 0, 1), width=0.006, depth=0.003)
            create_diamond_stud(bm_nodes_cyan, (cos_a * 0.28, sin_a * 0.28, seat_top_z), normal=(0, 0, 1), up=(cos_a, sin_a, 0), width=0.014, height=0.014, depth=0.005)
        else:
            create_circuit_strip(bm_circuits_mag, (cos_a * 0.165, sin_a * 0.165, seat_top_z), (cos_a * 0.26, sin_a * 0.26, seat_top_z), normal=(0, 0, 1), width=0.005, depth=0.003)
            create_diamond_stud(bm_nodes_magenta, (cos_a * 0.26, sin_a * 0.26, seat_top_z), normal=(0, 0, 1), up=(cos_a, sin_a, 0), width=0.012, height=0.012, depth=0.005)
            
    # Now finalize Cyan Nodes and Magenta Nodes objects
    bmesh.ops.recalc_face_normals(bm_nodes_cyan, faces=bm_nodes_cyan.faces)
    nodes_cyan_obj = M._object_from_bmesh(bm_nodes_cyan, "Nodes_Diamond_Cyan", coll=coll)
    M.shade_smooth_by_angle(nodes_cyan_obj, 35)
    M.assign_material(nodes_cyan_obj, mat_neon_cyan)
    built_objects.append(nodes_cyan_obj)
    
    bmesh.ops.recalc_face_normals(bm_nodes_magenta, faces=bm_nodes_magenta.faces)
    nodes_mag_obj = M._object_from_bmesh(bm_nodes_magenta, "Nodes_Diamond_Magenta", coll=coll)
    M.shade_smooth_by_angle(nodes_mag_obj, 35)
    M.assign_material(nodes_mag_obj, mat_neon_magenta)
    built_objects.append(nodes_mag_obj)
            
    # --- C. Leg Vertical Power Conduits (Cyan & Magenta Traces along outer faces) ---
    for lx, ly in [(-0.24, -0.24), (0.24, -0.24), (-0.24, 0.24), (0.24, 0.24)]:
        sx = 1 if lx > 0 else -1
        sy = 1 if ly > 0 else -1
        half_l = LEG_SIZE[0] / 2
        
        # Front face trace (if front legs) or rear face trace (if rear legs)
        y_f = ly - sy * (half_l + 0.001)
        create_circuit_strip(bm_circuits_cyan, (lx - sx * 0.02, y_f, 0.09), (lx - sx * 0.02, y_f, 0.24), normal=(0, -sy, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_cyan, (lx - sx * 0.02, y_f, 0.24), (lx + sx * 0.02, y_f, 0.28), normal=(0, -sy, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_cyan, (lx + sx * 0.02, y_f, 0.28), (lx + sx * 0.02, y_f, 0.44), normal=(0, -sy, 0), width=0.006, depth=0.003)
        
        # Parallel Magenta Trace
        create_circuit_strip(bm_circuits_mag, (lx + sx * 0.03, y_f, 0.09), (lx + sx * 0.03, y_f, 0.22), normal=(0, -sy, 0), width=0.005, depth=0.003)
        create_circuit_strip(bm_circuits_mag, (lx + sx * 0.03, y_f, 0.22), (lx - sx * 0.01, y_f, 0.26), normal=(0, -sy, 0), width=0.005, depth=0.003)
        create_circuit_strip(bm_circuits_mag, (lx - sx * 0.01, y_f, 0.26), (lx - sx * 0.01, y_f, 0.44), normal=(0, -sy, 0), width=0.005, depth=0.003)
        
        # Outer lateral face trace
        x_lat = lx + sx * (half_l + 0.001)
        create_circuit_strip(bm_circuits_cyan, (x_lat, ly - sy * 0.02, 0.09), (x_lat, ly - sy * 0.02, 0.44), normal=(sx, 0, 0), width=0.006, depth=0.003)
        create_circuit_strip(bm_circuits_mag, (x_lat, ly + sy * 0.02, 0.09), (x_lat, ly + sy * 0.02, 0.44), normal=(sx, 0, 0), width=0.005, depth=0.003)
        
    # --- D. Post Vertical Conduits (Front and outer side of backrest posts) ---
    for suffix, px, py in POST_OFFSETS:
        sx = 1 if px > 0 else -1
        half_p = POST_SIZE[0] / 2
        
        # Front face
        y_pf = py - (half_p + 0.001)
        create_circuit_strip(bm_circuits_cyan, (px - sx * 0.025, y_pf, 0.55), (px - sx * 0.025, y_pf, 1.34), normal=(0, -1, 0), width=0.007, depth=0.003)
        create_circuit_strip(bm_circuits_mag, (px + sx * 0.025, y_pf, 0.55), (px + sx * 0.025, y_pf, 1.34), normal=(0, -1, 0), width=0.006, depth=0.003)
        
        # Outer side face
        x_plat = px + sx * (half_p + 0.001)
        create_circuit_strip(bm_circuits_cyan, (x_plat, py - 0.02, 0.55), (x_plat, py - 0.02, 1.34), normal=(sx, 0, 0), width=0.007, depth=0.003)
        create_circuit_strip(bm_circuits_mag, (x_plat, py + 0.02, 0.55), (x_plat, py + 0.02, 1.34), normal=(sx, 0, 0), width=0.006, depth=0.003)
        
    bmesh.ops.recalc_face_normals(bm_circuits_cyan, faces=bm_circuits_cyan.faces)
    circuits_cyan_obj = M._object_from_bmesh(bm_circuits_cyan, "Circuits_Neon_Cyan", coll=coll)
    M.shade_smooth_by_angle(circuits_cyan_obj, 35)
    M.assign_material(circuits_cyan_obj, mat_neon_cyan)
    built_objects.append(circuits_cyan_obj)
    
    bmesh.ops.recalc_face_normals(bm_circuits_mag, faces=bm_circuits_mag.faces)
    circuits_mag_obj = M._object_from_bmesh(bm_circuits_mag, "Circuits_Neon_Magenta", coll=coll)
    M.shade_smooth_by_angle(circuits_mag_obj, 35)
    M.assign_material(circuits_mag_obj, mat_neon_magenta)
    built_objects.append(circuits_mag_obj)
    
    # ----------------------------------------------------------------------
    # 11. Hologram Floor Scanning Platform (Glowing Projected Ring)
    # ----------------------------------------------------------------------
    bm_holo = bmesh.new()
    # Inner and outer concentric projector rings on the floor
    create_circular_ring(bm_holo, (0, 0, 0.003), normal=(0, 0, 1), radius=0.45, width=0.016, depth=0.002, segments=48)
    create_circular_ring(bm_holo, (0, 0, 0.003), normal=(0, 0, 1), radius=0.55, width=0.008, depth=0.002, segments=48)
    bmesh.ops.recalc_face_normals(bm_holo, faces=bm_holo.faces)
    holo_obj = M._object_from_bmesh(bm_holo, "Hologram_Floor_Ring", coll=coll)
    M.shade_smooth_by_angle(holo_obj, 35)
    M.assign_material(holo_obj, mat_holo_ring)
    built_objects.append(holo_obj)
    
    # ----------------------------------------------------------------------
    # 12. Floating Holographic Data Voxels (Digital Pixel Particles)
    # ----------------------------------------------------------------------
    bm_voxels = bmesh.new()
    voxel_locations = [
        # Near backrest posts & core
        (-0.35, 0.26, 1.25),
        ( 0.35, 0.26, 1.25),
        (-0.32, 0.22, 0.85),
        ( 0.32, 0.22, 0.85),
        (-0.28, 0.24, 1.48),
        ( 0.28, 0.24, 1.48),
        (-0.06, 0.18, 1.10),
        ( 0.06, 0.18, 1.10),
        # Near leg bases
        (-0.34, -0.24, 0.20),
        ( 0.34, -0.24, 0.20),
        (-0.24, -0.34, 0.15),
        ( 0.24, -0.34, 0.15),
        (-0.34,  0.24, 0.22),
        ( 0.34,  0.24, 0.22),
    ]
    for vx, vy, vz in voxel_locations:
        # Small floating rectangular data bit
        mat_v = Matrix.Translation(Vector((vx, vy, vz))) @ Matrix.Diagonal((0.008, 0.004, 0.012, 1.0))
        bmesh.ops.create_cube(bm_voxels, size=2.0, matrix=mat_v)
        
    bmesh.ops.recalc_face_normals(bm_voxels, faces=bm_voxels.faces)
    voxels_obj = M._object_from_bmesh(bm_voxels, "Hologram_Data_Voxels", coll=coll)
    M.shade_smooth_by_angle(voxels_obj, 35)
    M.assign_material(voxels_obj, mat_neon_cyan)
    built_objects.append(voxels_obj)
    
    # ----------------------------------------------------------------------
    # Stage 4: Apply transforms and generate Smart UVs
    # ----------------------------------------------------------------------
    for obj in built_objects:
        M.apply_transforms(obj, location=False, rotation=True, scale=True)
        M.smart_uv(obj, angle_deg=66, margin=0.02)
        
    # ----------------------------------------------------------------------
    # Mandatory Ink Outline (uniform 2.8 mm crisp ink line)
    # ----------------------------------------------------------------------
    OL.add_outlines(built_objects, thickness=0.0028, color="#08080C")
    
    return built_objects

# --------------------------------------------------------------------------
# Main Execution Entrypoint
# --------------------------------------------------------------------------
if __name__ == "__main__":
    out_dir = "d:/BAF/models"
    preview_dir = os.path.join(out_dir, "previews")
    os.makedirs(preview_dir, exist_ok=True)
    
    print("[1/5] Building Cyber Core Chair...")
    objs = build()
    
    print("[2/5] Setting up preview lighting & camera...")
    # EEVEE for high-tech neon emission bloom & fast render
    S.quick_preview_setup(objs, engine="EEVEE", resolution=(1024, 1024))
    
    print("[3/5] Rendering multi-angle previews...")
    views = {
        "cyber_chair_front": (0, 8),
        "cyber_chair_three_quarter": (35, 15),
        "cyber_chair_side": (90, 8),
        "cyber_chair_back": (180, 8),
        "cyber_chair_top_angle": (25, 45),
    }
    preview_paths = S.render_views(preview_dir, objs=objs, views=views, lens=50, resolution=(1024, 1024))
    
    print("[4/5] Validating model...")
    rep = V.run(max_tris=40000, verbose=True)
    
    print("[5/5] Exporting assets (.blend, .glb, .fbx)...")
    base_export = os.path.join(out_dir, "CyberCoreChair")
    exported = S.export_model(objs, base_export, formats=("blend", "glb", "fbx"))
    
    print("Build complete!")
    for p in exported:
        print(f"  Output: {p}")

"""
build_lucky_clover_chair.py
Procedurally builds the Stylized LUCKY CLOVER CROWN CHAIR in Blender 4.x / 5.x.
Based on the concept sheet:
- Four-leaf clover backrest in padded emerald leather
- Thick gold frame contouring the clover
- Center gold coin medallion with soccer ball emboss and ring of 16 studs
- 5-point stylized gold crown bracket on top
- Plump emerald cushion with gold piping and 4 corner buttons
- 4 chunky forest green legs with gold foot caps & clover inlays
- Armrests with gold clover coin caps
- 5 orbiting floating gold coins & falling clover particles
- Full PBR materials, 3-point studio lighting, camera framing
- Intro reveal (frames 1-90), Seamless idle loop (frames 91-330), Sit reaction action

Outputs:
- Blend file: D:\\BAF\\models\\lucky_clover_chair.blend
- Preview render: D:\\BAF\\models\\previews\\lucky_clover_chair_final.png
"""

import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Euler, Matrix

# ---------------------------------------------------------------------------
# PATHS & CONFIG
# ---------------------------------------------------------------------------
BASE_DIR = r"D:\BAF\models"
PREVIEWS_DIR = os.path.join(BASE_DIR, "previews")
OUTPUT_BLEND = os.path.join(BASE_DIR, "lucky_clover_chair.blend")
os.makedirs(PREVIEWS_DIR, exist_ok=True)

random.seed(17)

# ---------------------------------------------------------------------------
# COLOR PALETTE
# ---------------------------------------------------------------------------
COLOR_EMERALD_LEATHER = (0.012, 0.160, 0.055, 1.0)  # Rich deep jewel emerald
COLOR_FOREST_GREEN    = (0.006, 0.065, 0.024, 1.0)  # Dark forest green for legs
COLOR_GOLD_RICH       = (0.950, 0.650, 0.080, 1.0)  # Warm rich yellow-gold
COLOR_GOLD_HIGHLIGHT  = (1.000, 0.850, 0.350, 1.0)
COLOR_BURGUNDY_VELVET = (0.250, 0.020, 0.050, 1.0)
COLOR_GLOW_GREEN      = (0.250, 1.000, 0.400, 1.0)
COLOR_STUDIO_BG       = (0.22, 0.22, 0.24, 1.0)

# ---------------------------------------------------------------------------
# UTILITIES & HELPERS
# ---------------------------------------------------------------------------
def clear_scene():
    """Wipes all existing objects, materials, and collections for a clean slate."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for block in bpy.data.meshes: bpy.data.meshes.remove(block)
    for block in bpy.data.materials: bpy.data.materials.remove(block)
    for block in bpy.data.curves: bpy.data.curves.remove(block)
    for block in bpy.data.actions: bpy.data.actions.remove(block)


def get_action_fcurves(action):
    """Safely gets fcurves across Blender 4.x and Blender 5.x layered actions."""
    if not action:
        return []
    if hasattr(action, "fcurves") and action.fcurves:
        return list(action.fcurves)
    fcurves = []
    if hasattr(action, "layers"):
        for layer in action.layers:
            for strip in layer.strips:
                if hasattr(strip, "channelbags"):
                    for cb in strip.channelbags:
                        if hasattr(cb, "fcurves"):
                            fcurves.extend(list(cb.fcurves))
    return fcurves


def get_or_create_collection(name: str) -> bpy.types.Collection:
    col = bpy.data.collections.get(name)
    if not col:
        col = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    return col


def move_to_collection(obj: bpy.types.Object, col_name: str):
    col = get_or_create_collection(col_name)
    if obj.name not in col.objects:
        col.objects.link(obj)
    for c in list(obj.users_collection):
        if c != col:
            c.objects.unlink(obj)


def parent_obj(child: bpy.types.Object, parent: bpy.types.Object):
    """Cleanly parents child to parent using inverted parent world matrix."""
    if not child or not parent:
        return
    bpy.context.view_layer.update()
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()
    bpy.context.view_layer.update()


def add_bevel(obj: bpy.types.Object, width: float = 0.025, segments: int = 3):
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = width
    bev.segments = segments
    bev.harden_normals = True
    bev.limit_method = 'ANGLE'
    bev.angle_limit = math.radians(35)
    return bev


# ---------------------------------------------------------------------------
# MATERIALS SETUP
# ---------------------------------------------------------------------------
def create_materials():
    mats = {}

    def new_pbr(name, base_color, metallic=0.0, roughness=0.3, coat=0.0, sheen=0.0, emission=None, emit_strength=0.0):
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        nodes.clear()
        out = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if "Coat Weight" in bsdf.inputs:
            bsdf.inputs["Coat Weight"].default_value = coat
        if "Sheen Weight" in bsdf.inputs:
            bsdf.inputs["Sheen Weight"].default_value = sheen
        if emission and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = emit_strength
        mat.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        return mat, bsdf

    # 1. Emerald Leather with fine micro-noise and soft facing sheen
    m_emerald, bsdf_e = new_pbr("M_Emerald_Leather", COLOR_EMERALD_LEATHER, roughness=0.28, coat=0.25, sheen=0.20)
    nt = m_emerald.node_tree
    tc = nt.nodes.new("ShaderNodeTexCoord")
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 85.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.005
    nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf_e.inputs["Normal"])
    mats["emerald_leather"] = m_emerald

    # 2. Forest Green (legs and posts)
    m_forest, bsdf_f = new_pbr("M_Forest_Green", COLOR_FOREST_GREEN, roughness=0.35, coat=0.15)
    nt_f = m_forest.node_tree
    tc_f = nt_f.nodes.new("ShaderNodeTexCoord")
    noise_f = nt_f.nodes.new("ShaderNodeTexNoise")
    noise_f.inputs["Scale"].default_value = 40.0
    bump_f = nt_f.nodes.new("ShaderNodeBump")
    bump_f.inputs["Strength"].default_value = 0.04
    nt_f.links.new(tc_f.outputs["Object"], noise_f.inputs["Vector"])
    nt_f.links.new(noise_f.outputs["Fac"], bump_f.inputs["Height"])
    nt_f.links.new(bump_f.outputs["Normal"], bsdf_f.inputs["Normal"])
    mats["forest_green"] = m_forest

    # 3. Rich Gold (frame, caps, crown, buttons)
    m_gold, bsdf_g = new_pbr("M_Gold_Rich", COLOR_GOLD_RICH, metallic=1.0, roughness=0.25, coat=0.30)
    mats["gold_rich"] = m_gold

    # 4. Gold Coin (medallion, floating coins)
    m_coin, bsdf_c = new_pbr(
        "M_Gold_Coin", COLOR_GOLD_RICH, metallic=1.0, roughness=0.20, coat=0.30
    )
    mats["gold_coin"] = m_coin

    # 5. Clover Glow (particles and accents)
    m_glow, bsdf_gl = new_pbr(
        "M_Clover_Glow", COLOR_GLOW_GREEN, roughness=0.1,
        emission=COLOR_GLOW_GREEN, emit_strength=4.0
    )
    mats["clover_glow"] = m_glow

    # 6. Deep Burgundy (pedestal mat accent)
    m_burgundy, _ = new_pbr("M_Burgundy_Velvet", COLOR_BURGUNDY_VELVET, roughness=0.45, coat=0.1)
    mats["burgundy_velvet"] = m_burgundy

    # 7. Floor Studio Shadow Catcher
    m_floor = bpy.data.materials.new("M_Studio_Floor")
    m_floor.use_nodes = True
    nt_fl = m_floor.node_tree
    nt_fl.nodes.clear()
    out_fl = nt_fl.nodes.new("ShaderNodeOutputMaterial")
    bsdf_fl = nt_fl.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf_fl.inputs["Base Color"].default_value = (0.04, 0.045, 0.05, 1.0)
    bsdf_fl.inputs["Roughness"].default_value = 0.25
    nt_fl.links.new(bsdf_fl.outputs["BSDF"], out_fl.inputs["Surface"])
    mats["floor"] = m_floor

    return mats


# ---------------------------------------------------------------------------
# GEOMETRY CREATION HELPERS
# ---------------------------------------------------------------------------
def make_block(name, size, loc=(0,0,0), rot=(0,0,0), mat=None, bevel_w=0.025, col="Chair"):
    """Creates a clean beveled box."""
    sx, sy, sz = size
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    move_to_collection(obj, col)

    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector((sx, sy, sz)), verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()

    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot)
    if mat:
        obj.data.materials.append(mat)
    if bevel_w > 0:
        add_bevel(obj, width=bevel_w)
    return obj


def make_tapered_leg(name, top_size, bot_size, height, loc=(0,0,0), mat=None, bevel_w=0.02, col="Chair"):
    """Creates a chunky tapered leg wider at top, narrower at foot."""
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    move_to_collection(obj, col)

    bm = bmesh.new()
    # Create 8 vertices for tapered box centered at origin
    hz = height / 2.0
    tw, td = top_size[0] / 2.0, top_size[1] / 2.0
    bw, bd = bot_size[0] / 2.0, bot_size[1] / 2.0

    v1 = bm.verts.new((-bw, -bd, -hz))
    v2 = bm.verts.new(( bw, -bd, -hz))
    v3 = bm.verts.new(( bw,  bd, -hz))
    v4 = bm.verts.new((-bw,  bd, -hz))
    v5 = bm.verts.new((-tw, -td,  hz))
    v6 = bm.verts.new(( tw, -td,  hz))
    v7 = bm.verts.new(( tw,  td,  hz))
    v8 = bm.verts.new((-tw,  td,  hz))

    bm.faces.new([v4, v3, v2, v1]) # Bottom
    bm.faces.new([v5, v6, v7, v8]) # Top
    bm.faces.new([v1, v2, v6, v5]) # Front
    bm.faces.new([v2, v3, v7, v6]) # Right
    bm.faces.new([v3, v4, v8, v7]) # Back
    bm.faces.new([v4, v1, v5, v8]) # Left

    bm.to_mesh(mesh)
    bm.free()

    obj.location = Vector(loc)
    if mat:
        obj.data.materials.append(mat)
    if bevel_w > 0:
        add_bevel(obj, width=bevel_w)
    return obj


def make_cylinder(name, radius, depth, segments=32, loc=(0,0,0), rot=(0,0,0), mat=None, bevel_w=0.015, col="Chair"):
    """Creates a clean cylinder."""
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    move_to_collection(obj, col)

    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=radius, depth=depth)
    bm.to_mesh(mesh)
    bm.free()

    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot)
    if mat:
        obj.data.materials.append(mat)
    if bevel_w > 0:
        add_bevel(obj, width=bevel_w)
    return obj


def make_clover_inlay(name, radius=0.045, depth=0.012, loc=(0,0,0), rot=(0,0,0), mat=None, col="Chair"):
    """Creates a stylized 3-leaf clover/club cutout inlay for the foot caps."""
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    move_to_collection(obj, col)

    bm = bmesh.new()
    # 3 circular lobes in local X-Y plane, extruded along local Z
    lobe_r = radius * 0.45
    lobe_dist = radius * 0.46
    lobe_angles = [90, 210, 330]
    for ang in lobe_angles:
        rad = math.radians(ang)
        cx = lobe_dist * math.cos(rad)
        cy = lobe_dist * math.sin(rad)
        ret = bmesh.ops.create_cone(
            bm, cap_ends=True, segments=16, radius1=lobe_r, radius2=lobe_r, depth=depth
        )
        for v in ret["verts"]:
            v.co.x += cx
            v.co.y += cy

    # Stem at bottom (-Y in local X-Y plane)
    ret_stem = bmesh.ops.create_cube(bm, size=1.0)
    for v in ret_stem["verts"]:
        v.co.x *= (radius * 0.24)
        v.co.y *= (radius * 0.55)
        v.co.y -= (radius * 0.48)
        v.co.z *= depth

    bm.to_mesh(mesh)
    bm.free()

    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot)
    if mat:
        obj.data.materials.append(mat)
    add_bevel(obj, width=0.004, segments=2)
    return obj


def make_heart_leaf(name, angle_deg, center_loc, mat, back_tilt=0.0, col="Chair"):
    """Creates one puffy heart-shaped clover leaf at angle (0, 90, 180, 270 deg)."""
    curve = bpy.data.curves.new(f"{name}_Curve", type='CURVE')
    curve.dimensions = '2D'
    curve.fill_mode = 'BOTH'
    spline = curve.splines.new('BEZIER')
    spline.use_cyclic_u = True
    spline.bezier_points.add(7) # 8 points total

    # Heart shape pointing UP in local X-Y plane (+Y)
    pts = [
        (0.00, 0.42),   # center tip notch
        (0.12, 0.47),   # right shoulder
        (0.22, 0.34),   # right outer bulge
        (0.16, 0.17),   # right lower taper
        (0.00, 0.06),   # bottom root near center
        (-0.16, 0.17),  # left lower taper
        (-0.22, 0.34),  # left outer bulge
        (-0.12, 0.47)   # left shoulder
    ]
    for i, (x, y) in enumerate(pts):
        bp = spline.bezier_points[i]
        bp.co = (x, y, 0)
        bp.handle_left_type = 'AUTO'
        bp.handle_right_type = 'AUTO'

    # Make the notch and root sharper
    spline.bezier_points[0].handle_left_type = 'VECTOR'
    spline.bezier_points[0].handle_right_type = 'VECTOR'
    spline.bezier_points[4].handle_left_type = 'VECTOR'
    spline.bezier_points[4].handle_right_type = 'VECTOR'

    curve.extrude = 0.05
    curve.bevel_depth = 0.025
    curve.bevel_resolution = 4

    obj = bpy.data.objects.new(name, curve)
    move_to_collection(obj, col)

    # Orientation: rotate in plane first (Z axis), then tilt around X by (90 - tilt)
    mat_rot = (
        Euler((math.radians(90) - back_tilt, 0, 0)).to_matrix()
        @ Euler((0, 0, math.radians(angle_deg - 90))).to_matrix()
    )
    obj.rotation_euler = mat_rot.to_euler()
    obj.location = Vector(center_loc)

    if mat:
        obj.data.materials.append(mat)
    return obj


def backrest_local_to_world(lx, ly, lz, center=(0.0, 0.35, 1.48), back_tilt=math.radians(4.0)):
    """Transforms local backrest coordinates (X=right, Y=up along tilted plane, Z=forward along tilted plane normal) to world."""
    wy = center[1] + ly * math.sin(back_tilt) - lz * math.cos(back_tilt)
    wz = center[2] + ly * math.cos(back_tilt) + lz * math.sin(back_tilt)
    return Vector((center[0] + lx, wy, wz))


def make_clover_gold_frame(name, center_loc, mat, col="Chair"):
    """Creates the continuous thick gold frame contouring the 4-leaf clover using 2 concentric splines."""
    curve_data = bpy.data.curves.new(f"{name}_Curve", type='CURVE')
    curve_data.dimensions = '2D'
    curve_data.fill_mode = 'BOTH'

    # Outer spline
    s_out = curve_data.splines.new('BEZIER')
    s_out.use_cyclic_u = True
    s_out.bezier_points.add(15)

    # Inner spline (hollows the interior)
    s_in = curve_data.splines.new('BEZIER')
    s_in.use_cyclic_u = True
    s_in.bezier_points.add(15)

    leaf_angles = [90, 0, 270, 180]
    idx = 0
    for la in leaf_angles:
        angles = [la - 45, la - 15, la, la + 15]
        radii_out = [0.28, 0.52, 0.46, 0.52]
        radii_in  = [max(0.18, r - 0.065) for r in radii_out]
        for a, ro, ri in zip(angles, radii_out, radii_in):
            rad = math.radians(a)
            xo, zo = ro * math.cos(rad), ro * math.sin(rad)
            xi, zi = ri * math.cos(rad), ri * math.sin(rad)

            bpo = s_out.bezier_points[idx]
            bpo.co = (xo, zo, 0)
            bpo.handle_left_type = 'AUTO'
            bpo.handle_right_type = 'AUTO'

            bpi = s_in.bezier_points[idx]
            bpi.co = (xi, zi, 0)
            bpi.handle_left_type = 'AUTO'
            bpi.handle_right_type = 'AUTO'

            idx += 1

    curve_data.extrude = 0.08
    curve_data.bevel_depth = 0.015
    curve_data.bevel_resolution = 3

    frame_obj = bpy.data.objects.new(name, curve_data)
    move_to_collection(frame_obj, col)

    frame_obj.rotation_euler = Euler((math.radians(90), 0, 0))
    frame_obj.location = Vector(center_loc)
    if mat:
        frame_obj.data.materials.append(mat)
    return frame_obj


def make_coin_medallion(name, radius=0.22, depth=0.045, loc=(0,0,0), rot=(0,0,0), mat=None, col="Chair"):
    """Creates the large central gold coin medallion with soccer ball emboss."""
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    move_to_collection(obj, col)

    bm = bmesh.new()
    # Main coin cylinder along Z
    bmesh.ops.create_cone(bm, cap_ends=True, segments=48, radius1=radius, radius2=radius, depth=depth)

    fz = depth / 2.0  # Front circular cap is at Z = +depth/2

    # Outer raised stepped coin rim
    rim_h = 0.010
    ret_rim = bmesh.ops.create_cone(bm, cap_ends=True, segments=48, radius1=radius * 1.01, radius2=radius * 1.01, depth=rim_h)
    for v in ret_rim["verts"]:
        v.co.z += (fz + rim_h / 2.0)

    # Helper to add extruded prism pentagon for soccer ball
    def add_prism_pentagon(bm_target, cx, cy, r, z_base, h):
        bot_v = []
        top_v = []
        for i in range(5):
            ang = math.radians(90 + i * 72)
            x = cx + r * math.cos(ang)
            y = cy + r * math.sin(ang)
            bot_v.append(bm_target.verts.new((x, y, z_base)))
            top_v.append(bm_target.verts.new((x, y, z_base + h)))
        # Top face
        bm_target.faces.new(top_v)
        # 5 side quad faces
        for i in range(5):
            i2 = (i + 1) % 5
            bm_target.faces.new([bot_v[i], bot_v[i2], top_v[i2], top_v[i]])

    # 1. Raised central pentagon of soccer ball
    add_prism_pentagon(bm, 0.0, 0.0, r=0.052, z_base=fz, h=0.018)

    # 2. Five surrounding pentagons
    for k in range(5):
        c_ang = math.radians(90 + (k + 0.5) * 72)
        cx = 0.115 * math.cos(c_ang)
        cy = 0.115 * math.sin(c_ang)
        add_prism_pentagon(bm, cx, cy, r=0.044, z_base=fz, h=0.015)

    bm.to_mesh(mesh)
    bm.free()

    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot)
    if mat:
        obj.data.materials.append(mat)
    add_bevel(obj, width=0.003, segments=2)
    return obj


def make_stud_ring(parent, clover_center, back_tilt, radius=0.275, count=16, stud_r=0.016, mat=None, col="Chair"):
    """Creates ring of 16 gold spherical studs around the medallion."""
    studs = []
    for i in range(count):
        ang = i * (2.0 * math.pi / count)
        lx = radius * math.cos(ang)
        ly = radius * math.sin(ang)
        lz = 0.078
        pos = backrest_local_to_world(lx, ly, lz, clover_center, back_tilt)
        name = f"Medallion_Stud_{i+1:02d}"

        mesh = bpy.data.meshes.new(f"{name}_Mesh")
        obj = bpy.data.objects.new(name, mesh)
        move_to_collection(obj, col)

        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=stud_r)
        bm.to_mesh(mesh)
        bm.free()

        obj.location = pos
        if mat:
            obj.data.materials.append(mat)
        parent_obj(obj, parent)
        studs.append(obj)
    return studs


def make_crown(name, loc=(0,0,0), rot=(0,0,0), mat=None, col="Chair"):
    """Creates the stylized 5-point gold crown bracket on top of the backrest."""
    curve = bpy.data.curves.new(f"{name}_Curve", type='CURVE')
    curve.dimensions = '2D'
    spline = curve.splines.new('BEZIER')
    spline.use_cyclic_u = True

    # 5 crown peaks and bottom band
    pts = [
        (-0.11, -0.06), # bottom left
        ( 0.11, -0.06), # bottom right
        ( 0.11,  0.03), # right edge
        ( 0.10,  0.07), # peak 5 (right outer)
        ( 0.07,  0.02), # dip 4
        ( 0.05,  0.09), # peak 4 (right mid)
        ( 0.02,  0.03), # dip 3
        ( 0.00,  0.13), # peak 3 (center peak, tallest)
        (-0.02,  0.03), # dip 2
        (-0.05,  0.09), # peak 2 (left mid)
        (-0.07,  0.02), # dip 1
        (-0.10,  0.07), # peak 1 (left outer)
        (-0.11,  0.03), # left edge
    ]
    spline.bezier_points.add(len(pts) - 1)
    for i, (x, z) in enumerate(pts):
        bp = spline.bezier_points[i]
        bp.co = (x, z, 0)
        bp.handle_left_type = 'VECTOR'
        bp.handle_right_type = 'VECTOR'

    curve.extrude = 0.035
    curve.bevel_depth = 0.012
    curve.bevel_resolution = 2

    obj = bpy.data.objects.new(name, curve)
    move_to_collection(obj, col)

    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot)
    if mat:
        obj.data.materials.append(mat)
    return obj


# ---------------------------------------------------------------------------
# MAIN CHAIR BUILDER
# ---------------------------------------------------------------------------
def build_lucky_clover_chair():
    print("=" * 70)
    print("BUILDING STYLIZED LUCKY CLOVER CROWN CHAIR")
    print("=" * 70)

    clear_scene()
    mats = create_materials()

    # 1. Root Empty at Floor Origin
    root = bpy.data.objects.new("CloverChair", None)
    root.empty_display_type = 'ARROWS'
    root.empty_display_size = 0.5
    move_to_collection(root, "Chair")
    bpy.context.scene.collection.objects.link(root)

    # ----------------------------------------------------
    # LEGS & SEAT FRAME
    # ----------------------------------------------------
    leg_x = 0.36
    leg_y = 0.28
    leg_h = 0.50
    leg_z = leg_h / 2.0 # 0.25

    legs = []
    foot_caps = []
    inlays = []

    leg_positions = [
        ("FL", -leg_x, -leg_y),
        ("FR",  leg_x, -leg_y),
        ("BL", -leg_x,  leg_y),
        ("BR",  leg_x,  leg_y),
    ]

    for code, lx, ly in leg_positions:
        # Leg
        leg = make_tapered_leg(
            f"Leg_{code}",
            top_size=(0.17, 0.17),
            bot_size=(0.14, 0.14),
            height=leg_h,
            loc=(lx, ly, leg_z),
            mat=mats["forest_green"],
            bevel_w=0.018
        )
        parent_obj(leg, root)
        legs.append(leg)

        # Foot cap
        cap_h = 0.10
        cap = make_block(
            f"FootCap_{code}",
            size=(0.21, 0.21, cap_h),
            loc=(lx, ly, cap_h / 2.0),
            mat=mats["gold_rich"],
            bevel_w=0.02
        )
        parent_obj(cap, root)
        foot_caps.append(cap)

        # Clover inlay on front face of front foot caps
        if "F" in code:
            inlay = make_clover_inlay(
                f"Inlay_Clover_{code}",
                radius=0.042,
                depth=0.012,
                loc=(lx, ly - 0.106, cap_h / 2.0),
                rot=(math.radians(90), 0, 0),
                mat=mats["forest_green"]
            )
            parent_obj(inlay, root)
            inlays.append(inlay)

    # Seat Frame (gold satin block frame with beveled rim)
    frame_h = 0.14
    frame_z = leg_h + (frame_h / 2.0) # 0.57
    seat_frame = make_block(
        "Seat_Frame",
        size=(1.00, 0.85, frame_h),
        loc=(0, 0, frame_z),
        mat=mats["gold_rich"],
        bevel_w=0.035
    )
    parent_obj(seat_frame, root)

    # ----------------------------------------------------
    # SEAT CUSHION
    # ----------------------------------------------------
    cushion_h = 0.16
    cushion_z = frame_z + 0.08 # 0.65
    cushion = make_block(
        "Seat_Cushion",
        size=(0.90, 0.75, cushion_h),
        loc=(0, -0.01, cushion_z),
        mat=mats["emerald_leather"],
        bevel_w=0.04
    )
    # Add subsurf for soft plumpness
    sub_c = cushion.modifiers.new("Subsurf", 'SUBSURF')
    sub_c.levels = 2
    sub_c.render_levels = 2
    parent_obj(cushion, root)

    # Thin gold piping curve around cushion top
    piping_data = bpy.data.curves.new("Seat_Piping_Curve", type='CURVE')
    piping_data.dimensions = '3D'
    spl = piping_data.splines.new('BEZIER')
    spl.use_cyclic_u = True
    spl.bezier_points.add(3)
    pw, pd = 0.43, 0.355
    pipe_pts = [(-pw, -pd, 0), (pw, -pd, 0), (pw, pd, 0), (-pw, pd, 0)]
    for i, p in enumerate(pipe_pts):
        spl.bezier_points[i].co = p
        spl.bezier_points[i].handle_left_type = 'VECTOR'
        spl.bezier_points[i].handle_right_type = 'VECTOR'
    piping_data.bevel_depth = 0.010
    piping_data.bevel_resolution = 3
    piping_obj = bpy.data.objects.new("Seat_Piping", piping_data)
    move_to_collection(piping_obj, "Chair")
    piping_obj.location = Vector((0, -0.01, cushion_z + (cushion_h / 2.0) - 0.008))
    piping_obj.data.materials.append(mats["gold_rich"])
    parent_obj(piping_obj, root)

    # 4 gold corner buttons
    bx, by = 0.35, 0.28
    button_coords = [(-bx, -by), (bx, -by), (-bx, by), (bx, by)]
    for i, (cx, cy) in enumerate(button_coords):
        mesh = bpy.data.meshes.new(f"Seat_Btn_{i+1:02d}_Mesh")
        btn = bpy.data.objects.new(f"Seat_Btn_{i+1:02d}", mesh)
        move_to_collection(btn, "Chair")
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.026)
        bm.to_mesh(mesh)
        bm.free()
        btn.location = Vector((cx, cy - 0.01, cushion_z + 0.075))
        btn.data.materials.append(mats["gold_rich"])
        parent_obj(btn, root)

    # ----------------------------------------------------
    # ARMRESTS
    # ----------------------------------------------------
    arm_x = 0.50
    arm_post_h = 0.24
    arm_post_z = frame_z + (frame_h / 2.0) + (arm_post_h / 2.0) - 0.02 # ~0.74

    for side, sign in [("L", -1), ("R", 1)]:
        # Support post
        post = make_block(
            f"ArmPost_{side}",
            size=(0.14, 0.20, arm_post_h),
            loc=(sign * arm_x, -0.05, arm_post_z),
            mat=mats["forest_green"],
            bevel_w=0.02
        )
        parent_obj(post, root)

        # Padded armrest block
        arm_pad_h = 0.16
        arm_pad_z = arm_post_z + (arm_post_h / 2.0) + (arm_pad_h / 2.0) - 0.02 # ~0.92
        arm = make_block(
            f"Armrest_{side}",
            size=(0.20, 0.60, arm_pad_h),
            loc=(sign * arm_x, -0.02, arm_pad_z),
            mat=mats["emerald_leather"],
            bevel_w=0.035
        )
        sub_a = arm.modifiers.new("Subsurf", 'SUBSURF')
        sub_a.levels = 1
        parent_obj(arm, root)

        # Gold coin cap on front top of armrest
        coin = make_cylinder(
            f"ArmCoin_{side}",
            radius=0.062,
            depth=0.024,
            segments=32,
            loc=(sign * arm_x, -0.25, arm_pad_z + (arm_pad_h / 2.0) + 0.008),
            rot=(0, 0, 0),
            mat=mats["gold_coin"],
            bevel_w=0.008
        )
        parent_obj(coin, root)

    # ----------------------------------------------------
    # CLOVER BACKREST
    # ----------------------------------------------------
    # Clover center is positioned above the seat rear
    clover_center = (0.0, 0.35, 1.48)
    back_tilt = math.radians(4.0)

    # 1. Four Heart Leaves (Top, Right, Bottom, Left)
    leaf_top = make_heart_leaf("Clover_Leaf_Top", 90, clover_center, mats["emerald_leather"], back_tilt=back_tilt)
    leaf_right = make_heart_leaf("Clover_Leaf_Right", 0, clover_center, mats["emerald_leather"], back_tilt=back_tilt)
    leaf_bottom = make_heart_leaf("Clover_Leaf_Bottom", 270, clover_center, mats["emerald_leather"], back_tilt=back_tilt)
    leaf_left = make_heart_leaf("Clover_Leaf_Left", 180, clover_center, mats["emerald_leather"], back_tilt=back_tilt)

    clover_leaves = [leaf_top, leaf_right, leaf_bottom, leaf_left]
    for leaf in clover_leaves:
        parent_obj(leaf, root)

    # 2. Continuous Gold Clover Frame
    frame_obj = make_clover_gold_frame("Clover_Frame", clover_center, mats["gold_rich"])
    frame_obj.rotation_euler.x = math.radians(90) - back_tilt
    parent_obj(frame_obj, root)

    # 3. Plain Dark Green Rear Disc Panel (matching clover back without square corners)
    rear_panel = make_cylinder(
        "Backrest_RearPanel",
        radius=0.48,
        depth=0.06,
        segments=48,
        loc=(clover_center[0], clover_center[1] + 0.05, clover_center[2]),
        rot=(math.radians(90) - back_tilt, 0, 0),
        mat=mats["forest_green"],
        bevel_w=0.015
    )
    parent_obj(rear_panel, root)

    # 4. Vertical Gold Support Bar Behind Backrest
    support_post = make_block(
        "Backrest_Support_Post",
        size=(0.14, 0.08, 0.95),
        loc=(0, clover_center[1] + 0.10, clover_center[2] - 0.25),
        rot=(-back_tilt, 0, 0),
        mat=mats["gold_rich"],
        bevel_w=0.02
    )
    parent_obj(support_post, root)

    # 5. Center Gold Coin Medallion with Soccer Ball Emboss
    medallion_loc = backrest_local_to_world(0.0, 0.0, 0.088, clover_center, back_tilt)
    medallion_rot = (math.radians(90) - back_tilt, 0, 0)
    medallion = make_coin_medallion(
        "Coin_Medallion",
        radius=0.22,
        depth=0.045,
        loc=medallion_loc,
        rot=medallion_rot,
        mat=mats["gold_coin"]
    )
    parent_obj(medallion, root)

    # 6. Ring of 16 Gold Studs around Medallion
    make_stud_ring(root, clover_center, back_tilt, radius=0.275, count=16, stud_r=0.016, mat=mats["gold_rich"])

    # 7. Crown Bracket on Top
    crown_loc = backrest_local_to_world(0.0, 0.52, 0.035, clover_center, back_tilt)
    crown = make_crown(
        "Crown_Top",
        loc=crown_loc,
        rot=(-back_tilt, 0, 0),
        mat=mats["gold_rich"]
    )
    parent_obj(crown, root)

    # Crown gem inlay
    gem_loc = backrest_local_to_world(0.0, 0.56, 0.055, clover_center, back_tilt)
    crown_gem = make_cylinder(
        "Crown_Gem",
        radius=0.024,
        depth=0.015,
        loc=gem_loc,
        rot=(math.radians(90) - back_tilt, 0, 0),
        mat=mats["emerald_leather"],
        bevel_w=0.005
    )
    parent_obj(crown_gem, root)

    # ----------------------------------------------------
    # EFFECTS: FLOATING COINS & SPARKLES
    # ----------------------------------------------------
    # 5 Floating Coins orbiting around backrest
    float_coins = []
    coin_configs = [
        (1, -0.62,  0.22, 1.62, 0.0),
        (2,  0.64,  0.24, 1.68, 72.0),
        (3, -0.52,  0.30, 1.25, 144.0),
        (4,  0.55,  0.28, 1.22, 216.0),
        (5,  0.00,  0.18, 2.08, 288.0),
    ]
    for cid, fx, fy, fz, _ in coin_configs:
        f_coin = make_cylinder(
            f"FloatCoin_{cid:02d}",
            radius=0.07,
            depth=0.016,
            segments=24,
            loc=(fx, fy, fz),
            rot=(math.radians(35), math.radians(25), math.radians(15)),
            mat=mats["gold_coin"],
            bevel_w=0.005,
            col="Effects"
        )
        parent_obj(f_coin, root)
        float_coins.append(f_coin)

    # 6 Star Sparkle Flares near medallion & crown
    sparkle_coords = [
        (-0.22, 0.26, 1.58),
        ( 0.24, 0.25, 1.52),
        (-0.12, 0.24, 1.34),
        ( 0.14, 0.24, 1.36),
        ( 0.00, 0.22, 1.95),
        (-0.08, 0.22, 2.02),
    ]
    for idx, (sx, sy, sz) in enumerate(sparkle_coords):
        mesh = bpy.data.meshes.new(f"Sparkle_{idx+1:02d}_Mesh")
        sp = bpy.data.objects.new(f"Sparkle_{idx+1:02d}", mesh)
        move_to_collection(sp, "Effects")
        bm = bmesh.new()
        # 4-point flat star
        star_pts = []
        for i in range(8):
            a = math.radians(i * 45)
            r = 0.045 if i % 2 == 0 else 0.012
            star_pts.append(bm.verts.new((r * math.cos(a), 0, r * math.sin(a))))
        bm.faces.new(star_pts)
        bm.to_mesh(mesh)
        bm.free()
        sp.location = Vector((sx, sy, sz))
        sp.rotation_euler = Euler((-back_tilt, 0, math.radians(15 * idx)))
        sp.data.materials.append(mats["clover_glow"])
        parent_obj(sp, root)

    # ----------------------------------------------------
    # SCENE: LIGHTING & CAMERA
    # ----------------------------------------------------
    # Studio Shadow-Catcher Disc
    mesh_fl = bpy.data.meshes.new("Studio_Floor_Mesh")
    floor_obj = bpy.data.objects.new("Ground_ShadowCatcher", mesh_fl)
    move_to_collection(floor_obj, "Scene")
    bm_fl = bmesh.new()
    bmesh.ops.create_cone(bm_fl, cap_ends=True, segments=48, radius1=2.8, radius2=2.8, depth=0.02)
    bm_fl.to_mesh(mesh_fl)
    bm_fl.free()
    floor_obj.location = Vector((0, 0, -0.01))
    floor_obj.data.materials.append(mats["floor"])

    # Gold rim around floor disc
    mesh_frim = bpy.data.meshes.new("Floor_Gold_Rim_Mesh")
    frim_obj = bpy.data.objects.new("Floor_Gold_Rim", mesh_frim)
    move_to_collection(frim_obj, "Scene")
    bm_fr = bmesh.new()
    bmesh.ops.create_cone(bm_fr, cap_ends=True, segments=48, radius1=2.86, radius2=2.86, depth=0.015)
    bm_fr.to_mesh(mesh_frim)
    bm_fr.free()
    frim_obj.location = Vector((0, 0, -0.015))
    frim_obj.data.materials.append(mats["gold_rich"])

    # 1. Key Light (warm white area light front-left)
    key_light = bpy.data.lights.new("Light_Key_Data", type='AREA')
    key_light.energy = 220.0
    key_light.color = (1.0, 0.96, 0.90)
    key_light.size = 2.4
    key_obj = bpy.data.objects.new("Light_Key", key_light)
    move_to_collection(key_obj, "Lights")
    key_obj.location = Vector((-2.2, -3.2, 2.5))
    key_obj.rotation_euler = (Vector((0.0, 0.0, 1.1)) - key_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # 2. Fill Light (cool soft area light front-right)
    fill_light = bpy.data.lights.new("Light_Fill_Data", type='AREA')
    fill_light.energy = 90.0
    fill_light.color = (0.85, 0.92, 1.0)
    fill_light.size = 2.8
    fill_obj = bpy.data.objects.new("Light_Fill", fill_light)
    move_to_collection(fill_obj, "Lights")
    fill_obj.location = Vector((2.8, -2.8, 1.8))
    fill_obj.rotation_euler = (Vector((0.0, 0.0, 1.1)) - fill_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # 3. Low Front Fill Light (illuminates front legs, gold caps, seat frame)
    front_light = bpy.data.lights.new("Light_Front_Data", type='AREA')
    front_light.energy = 60.0
    front_light.color = (1.0, 0.95, 0.88)
    front_light.size = 1.8
    front_obj = bpy.data.objects.new("Light_Front", front_light)
    move_to_collection(front_obj, "Lights")
    front_obj.location = Vector((0.0, -3.5, 0.8))
    front_obj.rotation_euler = (Vector((0.0, 0.0, 0.6)) - front_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # 4. Rim Light (bright cool gold rim from rear)
    rim_light = bpy.data.lights.new("Light_Rim_Data", type='SPOT')
    rim_light.energy = 320.0
    rim_light.color = (1.0, 0.92, 0.75)
    rim_light.spot_size = math.radians(70)
    rim_obj = bpy.data.objects.new("Light_Rim", rim_light)
    move_to_collection(rim_obj, "Lights")
    rim_obj.location = Vector((0.0, 3.0, 3.2))
    rim_obj.rotation_euler = (Vector((0, 0, 1.3)) - rim_obj.location).to_track_quat('-Z', 'Y').to_euler()

    # Camera (50 mm focal length, 3/4 front view)
    cam_data = bpy.data.cameras.new("Camera_Main_Data")
    cam_data.lens = 50.0
    cam_data.dof.use_dof = False
    cam_obj = bpy.data.objects.new("Camera_Main", cam_data)
    move_to_collection(cam_obj, "Scene")
    cam_obj.location = Vector((2.55, -4.25, 1.75))
    cam_target = Vector((0.0, 0.0, 1.15))
    cam_obj.rotation_euler = (cam_target - cam_obj.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.camera = cam_obj

    # ----------------------------------------------------
    # ANIMATIONS (24 fps)
    # ----------------------------------------------------
    scene = bpy.context.scene
    scene.render.fps = 24
    scene.frame_start = 1
    scene.frame_end = 330
    scene.frame_current = 120 # Frame 120 = fully assembled idle state

    # A) Intro "LUCKY REVEAL" (frames 1-90)
    # Seat Frame drop & bounce
    seat_frame.animation_data_create()
    action_sf = bpy.data.actions.new("Intro_SeatFrame")
    seat_frame.animation_data.action = action_sf
    seat_frame.keyframe_insert(data_path="location", frame=1)
    seat_frame.location.z += 1.2
    seat_frame.keyframe_insert(data_path="location", frame=1)
    seat_frame.location.z = frame_z - 0.03
    seat_frame.keyframe_insert(data_path="location", frame=28)
    seat_frame.location.z = frame_z + 0.015
    seat_frame.keyframe_insert(data_path="location", frame=35)
    seat_frame.location.z = frame_z
    seat_frame.keyframe_insert(data_path="location", frame=42)

    # Cushion inflate
    cushion.animation_data_create()
    action_cu = bpy.data.actions.new("Intro_Cushion")
    cushion.animation_data.action = action_cu
    cushion.scale = Vector((0.01, 0.01, 0.01))
    cushion.keyframe_insert(data_path="scale", frame=20)
    cushion.scale = Vector((1.08, 1.08, 1.12))
    cushion.keyframe_insert(data_path="scale", frame=45)
    cushion.scale = Vector((1.0, 1.0, 1.0))
    cushion.keyframe_insert(data_path="scale", frame=54)

    # 4 Clover leaves bloom one by one (top, right, bottom, left)
    leaf_order = [leaf_top, leaf_right, leaf_bottom, leaf_left]
    for i, leaf in enumerate(leaf_order):
        start_f = 35 + (i * 6)
        leaf.animation_data_create()
        action_lf = bpy.data.actions.new(f"Intro_Leaf_{i}")
        leaf.animation_data.action = action_lf
        leaf.scale = Vector((0.001, 0.001, 0.001))
        leaf.keyframe_insert(data_path="scale", frame=start_f)
        leaf.scale = Vector((1.12, 1.12, 1.12))
        leaf.keyframe_insert(data_path="scale", frame=start_f + 16)
        leaf.scale = Vector((1.0, 1.0, 1.0))
        leaf.keyframe_insert(data_path="scale", frame=start_f + 24)

    # Medallion spin in with 720 deg rotation
    medallion.animation_data_create()
    action_med = bpy.data.actions.new("Intro_Medallion")
    medallion.animation_data.action = action_med
    medallion.scale = Vector((0.01, 0.01, 0.01))
    medallion.keyframe_insert(data_path="scale", frame=55)
    medallion.scale = Vector((1.15, 1.15, 1.15))
    medallion.keyframe_insert(data_path="scale", frame=75)
    medallion.scale = Vector((1.0, 1.0, 1.0))
    medallion.keyframe_insert(data_path="scale", frame=85)

    # B) Idle Loop (frames 91-330, seamless loop over 240 frames)
    # Floating Coins orbit & bobbing
    for idx, (f_coin, (_, _, _, _, phase)) in enumerate(zip(float_coins, coin_configs)):
        f_coin.animation_data_create()
        act_fc = bpy.data.actions.new(f"Idle_FloatCoin_{idx+1}")
        f_coin.animation_data.action = act_fc
        orig_z = f_coin.location.z
        orig_rot_z = f_coin.rotation_euler.z

        # Spin on own axis: 360 deg every 72 frames
        for f in range(91, 331, 24):
            t = (f - 91) / 240.0
            phase_rad = math.radians(phase) + (t * 2.0 * math.pi)
            f_coin.location.z = orig_z + (0.03 * math.sin(phase_rad * 3.0))
            f_coin.rotation_euler.z = orig_rot_z + (t * 2.0 * math.pi * (240.0 / 72.0))
            f_coin.keyframe_insert(data_path="location", frame=f)
            f_coin.keyframe_insert(data_path="rotation_euler", frame=f)

        for fc in get_action_fcurves(act_fc):
            mod = fc.modifiers.new('CYCLES')
            mod.mode_after = 'REPEAT'
            mod.mode_before = 'REPEAT'

    # Crown micro-bobbing
    crown.animation_data_create()
    act_cr = bpy.data.actions.new("Idle_Crown")
    crown.animation_data.action = act_cr
    orig_cz = crown.location.z
    for f in (91, 151, 211, 271, 330):
        t = (f - 91) / 60.0
        crown.location.z = orig_cz + (0.012 * math.sin(t * math.pi))
        crown.keyframe_insert(data_path="location", frame=f)
    for fc in get_action_fcurves(act_cr):
        mod = fc.modifiers.new('CYCLES')
        mod.mode_after = 'REPEAT'

    # ----------------------------------------------------
    # RENDER SETTINGS & COLOR MANAGEMENT
    # ----------------------------------------------------
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 64
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100

    scene.view_settings.view_transform = 'AgX'
    scene.view_settings.look = 'AgX - Medium High Contrast'

    # Save master blend file
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT_BLEND)
    print(f"\n[MASTER BLEND SAVED] {OUTPUT_BLEND} ({os.path.getsize(OUTPUT_BLEND):,} bytes)")

    # Render Final Hero Preview
    preview_img = os.path.join(PREVIEWS_DIR, "lucky_clover_chair_final.png")
    scene.render.filepath = preview_img
    print(f"Rendering hero preview to {preview_img}...")
    bpy.ops.render.render(write_still=True)
    print(f"[HERO PREVIEW SAVED] {preview_img} ({os.path.getsize(preview_img):,} bytes)")

    # Summary
    print("\n" + "=" * 70)
    print("CHAIR ASSET BUILD COMPLETE")
    print(f"Total objects in scene: {len(bpy.data.objects)}")
    print(f"Collections: {list(bpy.data.collections.keys())}")
    print("Timeline: 1-90 (Intro Reveal), 91-330 (Seamless Idle Loop), Frame 120 Active")
    print("=" * 70)
    return True


if __name__ == "__main__":
    build_lucky_clover_chair()

"""
=============================================================================
BLACK DIAMOND VIP CHAIR - FINAL PRODUCTION ASSET GENERATOR
Procedural 3D Stylized Game Asset for Blender 4.x & 5.x
=============================================================================
"""

import bpy
import bmesh
import math
import random
from mathutils import Vector, Matrix

FPS = 24
FRAME_INTRO_START = 1
FRAME_INTRO_END = 90
FRAME_IDLE_START = 91
FRAME_IDLE_END = 330

COLOR_LEATHER_BLACK = (0.025, 0.025, 0.030, 1.0)
COLOR_GOLD_CHAMPAGNE = (0.920, 0.780, 0.440, 1.0)
COLOR_GOLD_BRIGHT = (1.000, 0.850, 0.300, 1.0)
COLOR_BURGUNDY = (0.350, 0.050, 0.100, 1.0)
COLOR_STITCH = (0.880, 0.740, 0.450, 1.0)
COLOR_DIAMOND_CYAN = (0.820, 0.950, 1.000, 1.0)
COLOR_CARPET_RED = (0.520, 0.040, 0.070, 1.0)


def get_or_create_collection(name: str) -> bpy.types.Collection:
    if name in bpy.data.collections:
        return bpy.data.collections[name]
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def add_to_col(obj: bpy.types.Object, col_name: str = "Chair"):
    col = get_or_create_collection(col_name)
    if obj.name not in col.objects:
        col.objects.link(obj)
    for c in list(obj.users_collection):
        if c != col:
            c.objects.unlink(obj)


def parent_obj(child: bpy.types.Object, parent: bpy.types.Object):
    """Cleanly parents child to parent using matrix_parent_inverse."""
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
# SHADERS
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

    # Black Leather with fine micro-noise
    m_leather, bsdf_l = new_pbr("M_Leather_Black", COLOR_LEATHER_BLACK, roughness=0.28, coat=0.45, sheen=0.3)
    nt = m_leather.node_tree
    tc = nt.nodes.new("ShaderNodeTexCoord")
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 100.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.06
    bump.inputs["Distance"].default_value = 0.005
    nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
    nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf_l.inputs["Normal"])
    mats["M_Leather_Black"] = m_leather

    mats["M_Gold_Champagne"], _ = new_pbr("M_Gold_Champagne", COLOR_GOLD_CHAMPAGNE, metallic=1.0, roughness=0.28, coat=0.3)
    mats["M_Gold_Bright"], _ = new_pbr("M_Gold_Bright", COLOR_GOLD_BRIGHT, metallic=1.0, roughness=0.14, coat=0.5)
    mats["M_Burgundy_Leather"], _ = new_pbr("M_Burgundy_Leather", COLOR_BURGUNDY, roughness=0.32, sheen=0.4)
    mats["M_Stitch"], _ = new_pbr("M_Stitch", COLOR_STITCH, roughness=0.55)

    # Glowing Diamond
    m_dia, bsdf_d = new_pbr("M_Diamond", (1.0, 1.0, 1.0, 1.0), roughness=0.0, emission=COLOR_DIAMOND_CYAN, emit_strength=1.5)
    bsdf_d.inputs["IOR"].default_value = 2.42
    if "Transmission Weight" in bsdf_d.inputs:
        bsdf_d.inputs["Transmission Weight"].default_value = 1.0
    mats["M_Diamond"] = m_dia

    mats["M_Carpet_Red"], _ = new_pbr("M_Carpet_Red", COLOR_CARPET_RED, roughness=0.85, sheen=0.6)
    mats["M_Velvet_Rope"], _ = new_pbr("M_Velvet_Rope", (0.48, 0.03, 0.06, 1.0), roughness=0.70, sheen=0.8)
    return mats


# ---------------------------------------------------------------------------
# MODELING
# ---------------------------------------------------------------------------
def make_box(name: str, size: tuple, loc: tuple, mat: bpy.types.Material,
             bevel_w: float = 0.02, col_name: str = "Chair") -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z *= size[2]
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    obj.location = loc
    obj.data.materials.append(mat)
    add_to_col(obj, col_name)
    for f in me.polygons:
        f.use_smooth = True
    if bevel_w > 0:
        add_bevel(obj, width=bevel_w, segments=3)
    return obj


def make_tufted_grid(name: str, width: float, height: float, thickness: float,
                     loc: tuple, nx: int, ny: int, mat_leather: bpy.types.Material,
                     mat_button: bpy.types.Material, is_vertical: bool = False,
                     col_name: str = "Chair") -> tuple[bpy.types.Object, list[bpy.types.Object]]:
    """Generates a diamond-tufted cushion with puffed quads and recessed button spheres."""
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=nx, y_segments=ny, size=0.5)

    if not is_vertical:
        # Horizontal cushion (Seat): width along X, length along Y, height along Z
        for v in bm.verts:
            v.co.x *= width
            v.co.y *= height
            v.co.z = 0.0

        poke = bmesh.ops.poke(bm, faces=bm.faces)
        # Bulge centers up (+Z)
        for f in poke['faces']:
            for cv in [v for v in f.verts if len(v.link_edges) > 4]:
                fx, fy = abs(cv.co.x) / (width * 0.5), abs(cv.co.y) / (height * 0.5)
                cv.co.z = (thickness * 0.45) * max(0.0, 1.0 - (fx**2 + fy**2)*0.4)

        # Recess tuft intersections down (-Z)
        button_coords = []
        for v in [v for v in bm.verts if not v.is_boundary and len(v.link_edges) == 4]:
            v.co.z -= thickness * 0.18
            button_coords.append(Vector((v.co.x, v.co.y, v.co.z)))

        # Extrude sides down
        ext = bmesh.ops.extrude_edge_only(bm, edges=[e for e in bm.edges if e.is_boundary])
        for v in [v for v in ext['geom'] if isinstance(v, bmesh.types.BMVert)]:
            v.co.z -= thickness
        bmesh.ops.edgeloop_fill(bm, edges=[e for e in ext['geom'] if isinstance(e, bmesh.types.BMEdge) and e.is_boundary])

    else:
        # Vertical panel (Backrest): width along X, height along Z, front face at -Y
        for v in bm.verts:
            vx = v.co.x * width
            vz = v.co.y * height
            v.co.x = vx
            v.co.y = 0.0
            v.co.z = vz

        poke = bmesh.ops.poke(bm, faces=bm.faces)
        # Bulge centers forward (-Y)
        for f in poke['faces']:
            for cv in [v for v in f.verts if len(v.link_edges) > 4]:
                fx, fz = abs(cv.co.x) / (width * 0.5), abs(cv.co.z) / (height * 0.5)
                cv.co.y = -(thickness * 0.45) * max(0.0, 1.0 - (fx**2 + fz**2)*0.4)

        # Recess tuft intersections back (+Y)
        button_coords = []
        for v in [v for v in bm.verts if not v.is_boundary and len(v.link_edges) == 4]:
            v.co.y += thickness * 0.18
            button_coords.append(Vector((v.co.x, v.co.y, v.co.z)))

        # Extrude sides back (+Y)
        ext = bmesh.ops.extrude_edge_only(bm, edges=[e for e in bm.edges if e.is_boundary])
        for v in [v for v in ext['geom'] if isinstance(v, bmesh.types.BMVert)]:
            v.co.y += thickness
        bmesh.ops.edgeloop_fill(bm, edges=[e for e in ext['geom'] if isinstance(e, bmesh.types.BMEdge) and e.is_boundary])

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    obj = bpy.data.objects.new(name, me)
    obj.location = loc
    obj.data.materials.append(mat_leather)
    add_to_col(obj, col_name)
    for f in me.polygons:
        f.use_smooth = True
    sub = obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2

    # Gold Button Spheres
    buttons = []
    for i, bco in enumerate(button_coords):
        bm_b = bmesh.new()
        bmesh.ops.create_icosphere(bm_b, subdivisions=2, radius=0.018)
        me_b = bpy.data.meshes.new(f"{name}_Btn_{i+1:02d}")
        bm_b.to_mesh(me_b)
        bm_b.free()

        btn = bpy.data.objects.new(f"{name}_Btn_{i+1:02d}", me_b)
        if not is_vertical:
            btn.location = (loc[0] + bco.x, loc[1] + bco.y, loc[2] + bco.z + 0.006)
        else:
            btn.location = (loc[0] + bco.x, loc[1] + bco.y - 0.006, loc[2] + bco.z)
        btn.data.materials.append(mat_button)
        add_to_col(btn, col_name)
        for f in me_b.polygons:
            f.use_smooth = True
        parent_obj(btn, obj)
        buttons.append(btn)

    return obj, buttons


def make_gold_frame_hollow(name: str, width: float, height: float, depth: float,
                           border: float, chamfer: float, loc: tuple,
                           mat_gold: bpy.types.Material, col_name: str = "Chair") -> bpy.types.Object:
    """Builds a regal chamfered picture-frame with an open central cavity."""
    bm = bmesh.new()
    hw, hh = width * 0.5, height * 0.5
    iw, ih = hw - border, hh - border
    hd = depth * 0.5

    # Outer vertices (Front z=-hd/hd, Back)
    # Front face at -Y, Back at +Y
    outer_pts = [
        (-hw, -hd, -hh), ( hw, -hd, -hh), ( hw, -hd,  hh - chamfer),
        ( hw - chamfer, -hd,  hh), (-hw + chamfer, -hd,  hh), (-hw, -hd,  hh - chamfer)
    ]
    inner_pts = [
        (-iw, -hd, -ih), ( iw, -hd, -ih), ( iw, -hd,  ih), (-iw, -hd,  ih)
    ]

    v_outer_front = [bm.verts.new(Vector((p[0], -hd, p[2]))) for p in outer_pts]
    v_inner_front = [bm.verts.new(Vector((p[0], -hd, p[2]))) for p in inner_pts]
    v_outer_back  = [bm.verts.new(Vector((p[0],  hd, p[2]))) for p in outer_pts]
    v_inner_back  = [bm.verts.new(Vector((p[0],  hd, p[2]))) for p in inner_pts]

    # Front border faces
    # Bottom
    bm.faces.new([v_outer_front[0], v_outer_front[1], v_inner_front[1], v_inner_front[0]])
    # Right
    bm.faces.new([v_outer_front[1], v_outer_front[2], v_inner_front[2], v_inner_front[1]])
    # Top
    bm.faces.new([v_outer_front[2], v_outer_front[3], v_outer_front[4], v_outer_front[5], v_inner_front[3], v_inner_front[2]])
    # Left
    bm.faces.new([v_outer_front[5], v_outer_front[0], v_inner_front[0], v_inner_front[3]])

    # Outer side walls
    n_o = len(v_outer_front)
    for i in range(n_o):
        i_next = (i + 1) % n_o
        bm.faces.new([v_outer_front[i], v_outer_back[i], v_outer_back[i_next], v_outer_front[i_next]])

    # Inner cavity walls
    n_i = len(v_inner_front)
    for i in range(n_i):
        i_next = (i + 1) % n_i
        bm.faces.new([v_inner_front[i], v_inner_front[i_next], v_inner_back[i_next], v_inner_back[i]])

    # Back border faces
    bm.faces.new([v_outer_back[1], v_outer_back[0], v_inner_back[0], v_inner_back[1]])
    bm.faces.new([v_outer_back[2], v_outer_back[1], v_inner_back[1], v_inner_back[2]])
    bm.faces.new([v_outer_back[5], v_outer_back[4], v_outer_back[3], v_outer_back[2], v_inner_back[2], v_inner_back[3]])
    bm.faces.new([v_outer_back[0], v_outer_back[5], v_inner_back[3], v_inner_back[0]])

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    obj = bpy.data.objects.new(name, me)
    obj.location = loc
    obj.data.materials.append(mat_gold)
    add_to_col(obj, col_name)
    for f in me.polygons:
        f.use_smooth = True
    add_bevel(obj, width=0.025, segments=3)
    return obj


def make_diamond_gem(name: str, width: float, height: float, loc: tuple,
                     mat_gem: bpy.types.Material, col_name: str = "Chair") -> bpy.types.Object:
    bm = bmesh.new()
    segs = 8
    tr = width * 0.35
    tz = height * 0.40
    gr = width * 0.50
    gz = height * 0.05
    cz = -height * 0.55

    t_verts = [bm.verts.new(Vector((tr * math.cos(i*2*math.pi/segs), tr * math.sin(i*2*math.pi/segs), tz))) for i in range(segs)]
    bm.faces.new(t_verts)

    g_verts = [bm.verts.new(Vector((gr * math.cos((i+0.5)*2*math.pi/segs), gr * math.sin((i+0.5)*2*math.pi/segs), gz))) for i in range(segs)]
    culet = bm.verts.new(Vector((0, 0, cz)))

    for i in range(segs):
        nxt = (i + 1) % segs
        bm.faces.new([t_verts[i], g_verts[i], t_verts[nxt]])
        bm.faces.new([t_verts[nxt], g_verts[i], g_verts[nxt]])
        bm.faces.new([g_verts[i], culet, g_verts[nxt]])

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    obj = bpy.data.objects.new(name, me)
    obj.location = loc
    obj.data.materials.append(mat_gem)
    add_to_col(obj, col_name)
    for f in me.polygons:
        f.use_smooth = False
    add_bevel(obj, width=0.003, segments=2)
    return obj


def make_bezel_cradle(name: str, width: float, height: float, loc: tuple,
                      mat_gold: bpy.types.Material, col_name: str = "Chair") -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=8, radius1=width * 0.50, radius2=0.03, depth=height * 0.85)
    for v in bm.verts:
        v.co.y *= 0.60

    # Side curled scrolls
    for side in (-1, 1):
        res = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=0.035, radius2=0.035, depth=0.03)
        for v in res['verts']:
            v.co.x += side * width * 0.42
            v.co.z -= height * 0.22

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    obj.location = loc
    obj.data.materials.append(mat_gold)
    add_to_col(obj, col_name)
    for f in me.polygons:
        f.use_smooth = True
    add_bevel(obj, width=0.012, segments=3)
    return obj


def make_stitch_curve(name: str, width: float, depth: float, z_off: float,
                      parent_target: bpy.types.Object, mat_stitch: bpy.types.Material,
                      radius: float = 0.004, is_vertical: bool = False,
                      col_name: str = "Chair") -> bpy.types.Object:
    curve_data = bpy.data.curves.new(name, type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = radius
    curve_data.bevel_resolution = 3
    curve_data.use_fill_caps = True

    polyline = curve_data.splines.new('POLY')
    hw, hd = width * 0.49, depth * 0.49
    if not is_vertical:
        pts = [(-hw, -hd, z_off), (hw, -hd, z_off), (hw, hd, z_off), (-hw, hd, z_off)]
    else:
        pts = [(-hw, z_off, -hd), (hw, z_off, -hd), (hw, z_off, hd), (-hw, z_off, hd)]

    polyline.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        polyline.points[i].co = (p[0], p[1], p[2], 1.0)
    polyline.use_cyclic_u = True

    obj = bpy.data.objects.new(name, curve_data)
    obj.location = parent_target.location
    obj.rotation_euler = parent_target.rotation_euler
    obj.data.materials.append(mat_stitch)
    add_to_col(obj, col_name)
    parent_obj(obj, parent_target)
    return obj


# ---------------------------------------------------------------------------
# FULL CHAIR CONSTRUCTION
# ---------------------------------------------------------------------------
def build_master_chair():
    # 1. Reset scene
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c, do_unlink=True)

    mats = create_materials()

    root = bpy.data.objects.new("VIPChair", None)
    root.empty_display_type = 'ARROWS'
    root.empty_display_size = 0.4
    root.location = (0, 0, 0)
    add_to_col(root, "Chair")

    parts = {"legs": [], "foot_caps": [], "armrests": [], "buttons": [], "sparkles": []}

    # A) 4 LEGS & FOOT CAPS
    # Front of chair faces -Y (towards standard front camera at -Y)
    leg_sz = (0.16, 0.16, 0.50)
    leg_x, leg_y = 0.38, 0.28
    leg_coords = [
        ("Leg_FL", -leg_x, -leg_y, True),
        ("Leg_FR",  leg_x, -leg_y, True),
        ("Leg_BL", -leg_x,  leg_y, False),
        ("Leg_BR",  leg_x,  leg_y, False),
    ]

    for lname, lx, ly, is_fr in leg_coords:
        leg = make_box(lname, leg_sz, (lx, ly, leg_sz[2]*0.5), mats["M_Leather_Black"], bevel_w=0.02)
        parent_obj(leg, root)
        parts["legs"].append(leg)

        cap_sz = (0.20, 0.20, 0.10)
        cap = make_box(f"{lname}_Cap", cap_sz, (lx, ly, cap_sz[2]*0.5), mats["M_Gold_Bright"], bevel_w=0.015)
        parent_obj(cap, leg)
        parts["foot_caps"].append(cap)

        # White Diamond Inlay on front face
        gem_y = ly + (-cap_sz[1]*0.5 - 0.003 if is_fr else cap_sz[1]*0.5 + 0.003)
        gem = make_box(f"{lname}_Inlay", (0.045, 0.008, 0.045), (lx, gem_y, cap_sz[2]*0.5), mats["M_Diamond"], bevel_w=0.003)
        gem.rotation_euler.y = math.radians(45)
        parent_obj(gem, cap)

    # B) SEAT FRAME & VIP PLAQUE
    frame_sz = (1.00, 0.85, 0.14)
    frame_z = leg_sz[2] + frame_sz[2]*0.50  # 0.57
    seat_frame = make_box("Seat_Frame", frame_sz, (0, 0, frame_z), mats["M_Gold_Champagne"], bevel_w=0.03)
    parent_obj(seat_frame, root)
    parts["seat_frame"] = seat_frame

    # Front VIP Plaque on front face (-Y)
    plaque_sz = (0.30, 0.04, 0.09)
    plaque_y = -frame_sz[1]*0.50 - plaque_sz[1]*0.50
    vip_plaque = make_box("VIP_Plate", plaque_sz, (0, plaque_y, frame_z), mats["M_Gold_Bright"], bevel_w=0.012)
    parent_obj(vip_plaque, seat_frame)

    # 3D VIP Text facing -Y
    font_curve = bpy.data.curves.new("VIP_Text", type='FONT')
    font_curve.body = "VIP"
    font_curve.size = 0.052
    font_curve.extrude = 0.010
    font_curve.bevel_depth = 0.002
    font_curve.align_x = 'CENTER'
    font_curve.align_y = 'CENTER'
    text_obj = bpy.data.objects.new("VIP_Text", font_curve)
    text_obj.location = (0, plaque_y - 0.005, frame_z)
    text_obj.rotation_euler = (math.radians(90), 0, 0)
    text_obj.data.materials.append(mats["M_Gold_Bright"])
    add_to_col(text_obj, "Chair")
    parent_obj(text_obj, vip_plaque)

    # C) SEAT CUSHION, BUTTONS & BOLSTER
    cushion_sz = (0.92, 0.78, 0.16)
    cushion_z = frame_z + frame_sz[2]*0.50 + 0.02  # 0.66
    seat_cushion, btns_c = make_tufted_grid(
        "Seat_Cushion", cushion_sz[0], cushion_sz[1], cushion_sz[2],
        loc=(0, 0.02, cushion_z), nx=4, ny=4, mat_leather=mats["M_Leather_Black"],
        mat_button=mats["M_Gold_Bright"], is_vertical=False
    )
    parent_obj(seat_cushion, root)
    parts["seat_cushion"] = seat_cushion
    parts["buttons"].extend(btns_c)

    # Seat Stitch perimeter
    make_stitch_curve("Seat_Stitch", cushion_sz[0]*0.96, cushion_sz[1]*0.96, cushion_sz[2]*0.05,
                      seat_cushion, mats["M_Stitch"], radius=0.004)

    # Rolled Bolster Cushion along back (+Y)
    bolster_loc = (0, 0.28, cushion_z + 0.08)
    bolster_rad, bolster_len = 0.088, 0.74
    bolster = make_box("Bolster_Cushion", (bolster_len, bolster_rad*2, bolster_rad*2),
                       bolster_loc, mats["M_Leather_Black"], bevel_w=bolster_rad*0.8)
    parent_obj(bolster, root)
    parts["bolster"] = bolster

    # Burgundy End Caps on Bolster
    for side, xpos in [("L", -bolster_len*0.505), ("R", bolster_len*0.505)]:
        cap_b = make_box(f"Bolster_Cap_{side}", (0.015, bolster_rad*1.8, bolster_rad*1.8),
                         (xpos, bolster_loc[1], bolster_loc[2]), mats["M_Burgundy_Leather"], bevel_w=0.02)
        parent_obj(cap_b, bolster)

    # D) CHUNKY ARMRESTS & GOLD FRONT CUBES
    arm_x = 0.52
    arm_sz = (0.20, 0.68, 0.18)
    arm_z = frame_z + 0.32

    for side, ax in [("L", -arm_x), ("R", arm_x)]:
        arm = make_box(f"Armrest_{side}", arm_sz, (ax, 0.02, arm_z), mats["M_Leather_Black"], bevel_w=0.04)
        parent_obj(arm, root)
        parts["armrests"].append(arm)

        # Chunky Gold Cube Cap at FRONT (-Y)
        cube_sz = (0.20, 0.16, 0.20)
        cube_y = -arm_sz[1]*0.50 - cube_sz[1]*0.45
        arm_cap = make_box(f"ArmCap_{side}", cube_sz, (ax, cube_y, arm_z), mats["M_Gold_Bright"], bevel_w=0.025)
        parent_obj(arm_cap, arm)

        # Armrest Support pillar down to Seat Frame
        sup_sz = (0.14, 0.50, 0.24)
        sup_z = arm_z - arm_sz[2]*0.50 - sup_sz[2]*0.50
        sup = make_box(f"ArmSupport_{side}", sup_sz, (ax, 0.02, sup_z), mats["M_Leather_Black"], bevel_w=0.015)
        parent_obj(sup, arm)

        # Top stitch line
        make_stitch_curve(f"ArmStitch_{side}", arm_sz[0]*0.90, arm_sz[1]*0.94, arm_sz[2]*0.51,
                          arm, mats["M_Stitch"], radius=0.0035)

    # E) REGAL BACKREST FRAME & INNER TUFTED PANEL
    back_w, back_h, back_d = 1.00, 1.40, 0.14
    tilt_rad = math.radians(5.0)  # tilted back towards +Y
    back_base_y = 0.32
    back_base_z = frame_z + frame_sz[2]*0.50
    half_bh = back_h * 0.50

    back_center_y = back_base_y + half_bh * math.sin(tilt_rad)
    back_center_z = back_base_z + half_bh * math.cos(tilt_rad)

    # 1. Champagne-gold border frame
    back_frame = make_gold_frame_hollow(
        "Backrest_Frame", width=back_w, height=back_h, depth=back_d,
        border=0.10, chamfer=0.14, loc=(0, back_center_y, back_center_z),
        mat_gold=mats["M_Gold_Champagne"]
    )
    back_frame.rotation_euler = (tilt_rad, 0, 0)
    parent_obj(back_frame, root)
    parts["backrest_frame"] = back_frame

    # 2. Inner Black Tufted Panel (recessed inside frame, facing -Y)
    panel_w, panel_h, panel_d = 0.82, 1.20, 0.08
    panel_y = back_center_y + 0.01
    back_panel, btns_b = make_tufted_grid(
        "Backrest_TuftedPanel", width=panel_w, height=panel_h, thickness=panel_d,
        loc=(0, panel_y, back_center_z), nx=3, ny=4, mat_leather=mats["M_Leather_Black"],
        mat_button=mats["M_Gold_Bright"], is_vertical=True
    )
    back_panel.rotation_euler = (tilt_rad, 0, 0)
    parent_obj(back_panel, back_frame)
    parts["buttons"].extend(btns_b)

    # Inner stitch border
    make_stitch_curve("Backrest_Stitch", panel_w*0.96, panel_h*0.96, -0.01,
                      back_panel, mats["M_Stitch"], radius=0.0035, is_vertical=True)

    # 3. Rear Black Panel
    rear_p = make_box("Backrest_RearPanel", (0.84, 0.03, 1.22),
                      (0, back_center_y + back_d*0.48, back_center_z),
                      mats["M_Leather_Black"], bevel_w=0.015)
    rear_p.rotation_euler = (tilt_rad, 0, 0)
    parent_obj(rear_p, back_frame)

    # 4. Debossed Crown + Football Emblem on upper leather
    curve_emb = bpy.data.curves.new("Emblem_CrownFootball", type='CURVE')
    curve_emb.dimensions = '3D'
    curve_emb.bevel_depth = 0.003
    curve_emb.extrude = 0.003
    sp_c = curve_emb.splines.new('POLY')
    c_pts = [(-0.065, 0, 0.08), (-0.04, 0, 0.125), (-0.02, 0, 0.095), (0, 0, 0.14),
             (0.02, 0, 0.095), (0.04, 0, 0.125), (0.065, 0, 0.08), (0.05, 0, 0.07), (-0.05, 0, 0.07)]
    sp_c.points.add(len(c_pts) - 1)
    for i, p in enumerate(c_pts):
        sp_c.points[i].co = (p[0], p[1], p[2], 1.0)
    sp_c.use_cyclic_u = True

    sp_b = curve_emb.splines.new('POLY')
    n_b = 16
    sp_b.points.add(n_b - 1)
    for i in range(n_b):
        a = i * 2 * math.pi / n_b
        sp_b.points[i].co = (0.07 * math.cos(a), 0, 0.042 * math.sin(a) * (1 - 0.25*math.cos(a)**2), 1.0)
    sp_b.use_cyclic_u = True

    emblem = bpy.data.objects.new("Emblem_CrownFootball", curve_emb)
    emb_y = back_center_y - 0.045 + (0.28 * math.sin(tilt_rad))
    emb_z = back_center_z + (0.28 * math.cos(tilt_rad))
    emblem.location = (0, emb_y, emb_z)
    emblem.rotation_euler = (tilt_rad, 0, 0)
    emblem.data.materials.append(mats["M_Leather_Black"])
    add_to_col(emblem, "Chair")
    parent_obj(emblem, back_frame)

    # 5. Brilliant-Cut Diamond & Ornate Bezel on Top Rim
    top_gem_y = back_center_y + (half_bh * math.sin(tilt_rad))
    top_gem_z = back_center_z + (half_bh * math.cos(tilt_rad)) + 0.08

    bezel = make_bezel_cradle("Gem_Bezel", width=0.32, height=0.20, loc=(0, top_gem_y, top_gem_z - 0.06),
                              mat_gold=mats["M_Gold_Bright"])
    bezel.rotation_euler = (tilt_rad, 0, 0)
    parent_obj(bezel, back_frame)

    diamond = make_diamond_gem("Gem_Diamond", width=0.28, height=0.22, loc=(0, top_gem_y, top_gem_z),
                               mat_gem=mats["M_Diamond"])
    diamond.rotation_euler = (tilt_rad, 0, 0)
    parent_obj(diamond, back_frame)
    parts["diamond"] = diamond

    # Sparkle Flares
    for i, s_off in enumerate([(-0.16, 0.06), (0.16, 0.08), (0.0, 0.14)]):
        bm_s = bmesh.new()
        rad = 0.045
        pts_s = [Vector((0, 0, rad)), Vector((rad*0.2, 0, rad*0.2)), Vector((rad, 0, 0)),
                 Vector((rad*0.2, 0, -rad*0.2)), Vector((0, 0, -rad)), Vector((-rad*0.2, 0, -rad*0.2)),
                 Vector((-rad, 0, 0)), Vector((-rad*0.2, 0, rad*0.2))]
        bm_s.faces.new([bm_s.verts.new(p) for p in pts_s])
        me_s = bpy.data.meshes.new(f"Sparkle_{i+1:02d}")
        bm_s.to_mesh(me_s)
        bm_s.free()
        flare = bpy.data.objects.new(f"Sparkle_{i+1:02d}", me_s)
        flare.location = (s_off[0], top_gem_y - 0.04, top_gem_z + s_off[1])
        flare.data.materials.append(mats["M_Diamond"])
        add_to_col(flare, "Effects")
        parent_obj(flare, back_frame)
        parts["sparkles"].append(flare)

    # F) RED CARPET & STANCHIONS
    bm_c = bmesh.new()
    bmesh.ops.create_circle(bm_c, cap_ends=True, segments=48, radius=1.25)
    me_c = bpy.data.meshes.new("Carpet_RedCircle")
    bm_c.to_mesh(me_c)
    bm_c.free()
    carpet = bpy.data.objects.new("Carpet_RedCircle", me_c)
    carpet.location = (0, 0, 0.003)
    carpet.data.materials.append(mats["M_Carpet_Red"])
    add_to_col(carpet, "Rope_And_Carpet")

    # Velvet Rope Stanchions
    for side, sx in [("L", -0.85), ("R", 0.85)]:
        st_base = make_box(f"Stanchion_Base_{side}", (0.22, 0.22, 0.04), (sx, -0.20, 0.02), mats["M_Gold_Bright"], bevel_w=0.015, col_name="Rope_And_Carpet")
        bm_p = bmesh.new()
        bmesh.ops.create_cone(bm_p, cap_ends=True, segments=16, radius1=0.025, radius2=0.025, depth=0.88)
        me_p = bpy.data.meshes.new(f"Stanchion_Pole_{side}")
        bm_p.to_mesh(me_p)
        bm_p.free()
        st_pole = bpy.data.objects.new(f"Stanchion_Pole_{side}", me_p)
        st_pole.location = (sx, -0.20, 0.46)
        st_pole.data.materials.append(mats["M_Gold_Bright"])
        add_to_col(st_pole, "Rope_And_Carpet")
        parent_obj(st_pole, st_base)

        bm_bal = bmesh.new()
        bmesh.ops.create_icosphere(bm_bal, subdivisions=2, radius=0.045)
        me_bal = bpy.data.meshes.new(f"Stanchion_Ball_{side}")
        bm_bal.to_mesh(me_bal)
        bm_bal.free()
        st_bal = bpy.data.objects.new(f"Stanchion_Ball_{side}", me_bal)
        st_bal.location = (sx, -0.20, 0.92)
        st_bal.data.materials.append(mats["M_Gold_Bright"])
        add_to_col(st_bal, "Rope_And_Carpet")
        parent_obj(st_bal, st_base)

    # Velvet Rope Curve
    curve_rope = bpy.data.curves.new("Velvet_Rope", type='CURVE')
    curve_rope.dimensions = '3D'
    curve_rope.bevel_depth = 0.022
    curve_rope.bevel_resolution = 4
    curve_rope.use_fill_caps = True
    sp_r = curve_rope.splines.new('BEZIER')
    sp_r.bezier_points.add(2)
    p0, p1, p2 = sp_r.bezier_points[0], sp_r.bezier_points[1], sp_r.bezier_points[2]
    p0.co = (-0.85, -0.20, 0.88)
    p0.handle_right = (-0.50, -0.20, 0.70)
    p0.handle_left = (-1.05, -0.20, 0.88)
    p1.co = (0.0, -0.20, 0.50)
    p1.handle_left = (-0.35, -0.20, 0.50)
    p1.handle_right = (0.35, -0.20, 0.50)
    p2.co = (0.85, -0.20, 0.88)
    p2.handle_left = (0.50, -0.20, 0.70)
    p2.handle_right = (1.05, -0.20, 0.88)
    rope = bpy.data.objects.new("Velvet_Rope", curve_rope)
    rope.data.materials.append(mats["M_Velvet_Rope"])
    add_to_col(rope, "Rope_And_Carpet")

    # G) ANIMATION SETUP (24 fps)
    # Intro Reveal (Frames 1-90)
    for leg in parts["legs"]:
        leg.scale = (1.0, 1.0, 0.001)
        leg.keyframe_insert("scale", frame=1)
        leg.scale = (1.05, 1.05, 1.18)
        leg.keyframe_insert("scale", frame=16)
        leg.scale = (1.0, 1.0, 1.0)
        leg.keyframe_insert("scale", frame=24)
        leg.keyframe_insert("scale", frame=90)

    for cap in parts["foot_caps"]:
        cap.scale = (0.001, 0.001, 0.001)
        cap.keyframe_insert("scale", frame=1)
        cap.keyframe_insert("scale", frame=8)
        cap.scale = (1.15, 1.15, 1.15)
        cap.keyframe_insert("scale", frame=22)
        cap.scale = (1.0, 1.0, 1.0)
        cap.keyframe_insert("scale", frame=30)
        cap.keyframe_insert("scale", frame=90)

    sc = parts["seat_cushion"]
    sc.scale = (0.001, 0.001, 0.001)
    sc.keyframe_insert("scale", frame=1)
    sc.keyframe_insert("scale", frame=22)
    sc.scale = (1.06, 1.06, 1.14)
    sc.keyframe_insert("scale", frame=38)
    sc.scale = (1.0, 1.0, 1.0)
    sc.keyframe_insert("scale", frame=46)
    sc.keyframe_insert("scale", frame=90)

    # Idle Loop: Diamond continuous rotation
    dia = parts["diamond"]
    base_dz = dia.location.z
    dia.rotation_euler.z = 0.0
    dia.keyframe_insert("rotation_euler", index=2, frame=FRAME_IDLE_START)
    dia.rotation_euler.z = math.radians(360)
    dia.keyframe_insert("rotation_euler", index=2, frame=FRAME_IDLE_END)

    for step in range(5):
        f = FRAME_IDLE_START + step * 60
        sine_offset = 0.015 if (step % 2 == 1) else 0.0
        dia.location.z = base_dz + sine_offset
        dia.keyframe_insert("location", index=2, frame=f)

    # H) STUDIO SCENE, LIGHTS & CAMERA
    bm_fl = bmesh.new()
    bmesh.ops.create_circle(bm_fl, cap_ends=True, segments=64, radius=2.6)
    me_fl = bpy.data.meshes.new("Floor_GlossyDisc")
    bm_fl.to_mesh(me_fl)
    bm_fl.free()
    floor = bpy.data.objects.new("Floor_GlossyDisc", me_fl)
    floor.location = (0, 0, 0.001)
    m_floor = bpy.data.materials.new("M_Floor")
    m_floor.use_nodes = True
    bs_fl = m_floor.node_tree.nodes.get("Principled BSDF")
    if bs_fl:
        bs_fl.inputs["Base Color"].default_value = (0.02, 0.02, 0.025, 1.0)
        bs_fl.inputs["Roughness"].default_value = 0.15
    floor.data.materials.append(m_floor)
    add_to_col(floor, "Scene")

    # Lights (Aimed at front of chair)
    key_l = bpy.data.lights.new("Light_Key", 'AREA')
    key_l.energy = 700.0
    key_l.color = (1.00, 0.94, 0.86)
    key_l.size = 2.4
    k_obj = bpy.data.objects.new("Light_Key", key_l)
    k_obj.location = (1.8, -2.6, 2.6)
    k_obj.rotation_euler = (math.radians(52), math.radians(15), math.radians(32))
    add_to_col(k_obj, "Lights")

    fill_l = bpy.data.lights.new("Light_Fill", 'AREA')
    fill_l.energy = 200.0
    fill_l.color = (0.86, 0.92, 1.00)
    fill_l.size = 3.0
    f_obj = bpy.data.objects.new("Light_Fill", fill_l)
    f_obj.location = (-2.2, -2.0, 1.8)
    f_obj.rotation_euler = (math.radians(45), math.radians(-20), math.radians(-48))
    add_to_col(f_obj, "Lights")

    rim_l = bpy.data.lights.new("Light_Rim", 'AREA')
    rim_l.energy = 450.0
    rim_l.color = (0.92, 0.96, 1.00)
    rim_l.size = 2.0
    r_obj = bpy.data.objects.new("Light_Rim", rim_l)
    r_obj.location = (0.0, 2.6, 2.8)
    r_obj.rotation_euler = (math.radians(-135), 0, 0)
    add_to_col(r_obj, "Lights")

    spot_l = bpy.data.lights.new("Light_Spot_VIP", 'SPOT')
    spot_l.energy = 500.0
    spot_l.color = (1.00, 0.92, 0.78)
    spot_l.spot_size = math.radians(42)
    spot_l.spot_blend = 0.80
    sp_obj = bpy.data.objects.new("Light_Spot_VIP", spot_l)
    sp_obj.location = (0.0, 0.0, 3.4)
    add_to_col(sp_obj, "Lights")

    # Camera: Front 3/4 view
    cam_data = bpy.data.cameras.new("Camera_Main")
    cam_data.lens = 55.0
    cam_obj = bpy.data.objects.new("Camera_Main", cam_data)
    cam_obj.location = Vector((2.20, -3.20, 1.75))
    target = Vector((0.0, 0.0, 1.02))
    direction = target - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    add_to_col(cam_obj, "Scene")
    bpy.context.scene.camera = cam_obj

    # Render settings
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = FRAME_INTRO_START
    scene.frame_end = FRAME_IDLE_END
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 192
    scene.cycles.use_denoising = True
    scene.cycles.transmission_bounces = 12

    # Set active timeline frame to 120 (idle state)
    scene.frame_current = 120
    scene.frame_set(120)

    print("\n" + "=" * 70)
    print("BLACK DIAMOND VIP CHAIR V2 - BUILD SUCCESSFUL")
    print(f"Total Objects : {len(bpy.data.objects)}")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    build_master_chair()

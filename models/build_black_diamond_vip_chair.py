"""
=============================================================================
BLACK DIAMOND VIP CHAIR - PROCEDURAL 3D GAME ASSET GENERATOR
Blender 4.x & 5.x Python (bpy) Script
=============================================================================
Description:
    Procedurally constructs a stylized, chunky, hand-painted game-asset armchair:
    - Black tufted leather with puffy diamond quilting & gold buttons
    - Champagne-gold satin frame with chunky bevels & chamfered backrest
    - Large brilliant-cut glowing diamond (Gem_Diamond) in an ornate gold bezel
    - Front "VIP" embossed plaque, bolster with burgundy leather caps & gold piping
    - 4 chunky square legs with gold caps & white diamond inlays
    - Debossed crown & football emblem on the upper backrest leather
    - Complete modular hierarchy parented under an Empty named "VIPChair"
    - Procedural Principled BSDF shader networks (no external textures needed)
    - 24 fps Animations:
        * Intro Reveal (Frames 1-90): Elastic pop, drop, inflate & sparkle burst
        * Seamless Idle Loop (Frames 91-330): Diamond rotation, heartbeat pulse,
          cushion breathing, twinkling star glints & floating gold dust
        * Sit Reaction Action ("Sit_Reaction", 36 frames): Dynamic squash & spring
        * Optional Red Carpet & Velvet-Rope Stanchions with gentle sway
    - 3-point studio lighting, floor disc, spotlight, and camera
=============================================================================
"""

import bpy
import bmesh
import math
import random
from mathutils import Vector, Matrix

# ---------------------------------------------------------------------------
# GLOBAL CONSTANTS & PALETTE
# ---------------------------------------------------------------------------
RANDOM_SEED = 5
FPS = 24

FRAME_INTRO_START = 1
FRAME_INTRO_END = 90
FRAME_IDLE_START = 91
FRAME_IDLE_END = 330
IDLE_DURATION = FRAME_IDLE_END - FRAME_IDLE_START  # 240 frames

# Dimensions (in meters)
CHAIR_TOTAL_WIDTH = 1.30   # including armrests
CHAIR_TOTAL_DEPTH = 1.00
CHAIR_TOTAL_HEIGHT = 2.05

COLOR_LEATHER_BLACK = (0.028, 0.028, 0.035, 1.0)
COLOR_GOLD_CHAMPAGNE = (0.910, 0.760, 0.420, 1.0)
COLOR_GOLD_BRIGHT = (1.000, 0.840, 0.290, 1.0)
COLOR_BURGUNDY = (0.350, 0.050, 0.100, 1.0)     # #5A0F1E
COLOR_STITCH = (0.850, 0.700, 0.400, 1.0)
COLOR_DIAMOND_CYAN = (0.800, 0.950, 1.000, 1.0)
COLOR_CARPET_RED = (0.500, 0.040, 0.070, 1.0)


# ---------------------------------------------------------------------------
# UTILITY & COLLECTION HELPERS
# ---------------------------------------------------------------------------
def get_or_create_collection(name: str, parent: bpy.types.Collection = None) -> bpy.types.Collection:
    """Creates or retrieves a named collection."""
    if name in bpy.data.collections:
        col = bpy.data.collections[name]
    else:
        col = bpy.data.collections.new(name)
        if parent is None:
            bpy.context.scene.collection.children.link(col)
        else:
            parent.children.link(col)
    return col


def add_to_collection(obj: bpy.types.Object, col_name: str):
    """Links object to target collection and unlinks from default scene collection."""
    target_col = get_or_create_collection(col_name)
    if obj.name not in target_col.objects:
        target_col.objects.link(obj)
    for c in list(obj.users_collection):
        if c != target_col:
            c.objects.unlink(obj)


def parent_to(child: bpy.types.Object, parent: bpy.types.Object, keep_transform: bool = True):
    """Cleanly parents child to parent using matrix_parent_inverse to prevent coordinate doubling."""
    if not child or not parent:
        return
    bpy.context.view_layer.update()
    child.parent = parent
    if keep_transform:
        child.matrix_parent_inverse = parent.matrix_world.inverted()
    bpy.context.view_layer.update()


def add_bevel_modifier(obj: bpy.types.Object, width: float = 0.028, segments: int = 3) -> bpy.types.Modifier:
    """Adds a smooth toy-like Bevel modifier with harmonic normals."""
    bev = obj.modifiers.new("Bevel", "BEVEL")
    bev.width = width
    bev.segments = segments
    bev.harden_normals = True
    bev.limit_method = 'ANGLE'
    bev.angle_limit = math.radians(35)
    return bev


def get_action_fcurves(action):
    """Retrieves fcurves compatibly across Blender 4.0 - 5.x."""
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


# ---------------------------------------------------------------------------
# STEP 2: SHADER MATERIAL GENERATION
# ---------------------------------------------------------------------------
def create_all_materials() -> dict[str, bpy.types.Material]:
    """Builds procedural Principled BSDF shader networks for all chair parts."""
    materials = {}

    def init_mat(name: str):
        mat = bpy.data.materials.new(name)
        if not getattr(mat, "use_nodes", False):
            try:
                mat.use_nodes = True
            except Exception:
                pass
        nodes = mat.node_tree.nodes
        nodes.clear()
        out = nodes.new("ShaderNodeOutputMaterial")
        bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        return mat, nodes, mat.node_tree.links, out, bsdf

    # 1. M_Leather_Black
    mat_l, nodes, links, out, bsdf = init_mat("M_Leather_Black")
    bsdf.inputs["Base Color"].default_value = COLOR_LEATHER_BLACK
    bsdf.inputs["Roughness"].default_value = 0.28
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.50
        bsdf.inputs["Coat Roughness"].default_value = 0.15
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.30

    tex_coord = nodes.new("ShaderNodeTexCoord")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 120.0
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.65
    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])

    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.005
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Leather_Black"] = mat_l

    # 2. M_Gold_Champagne (Satin frame)
    mat_gc, nodes, links, out, bsdf = init_mat("M_Gold_Champagne")
    bsdf.inputs["Base Color"].default_value = COLOR_GOLD_CHAMPAGNE
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.30
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.30
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Gold_Champagne"] = mat_gc

    # 3. M_Gold_Bright (Mirror polished gold)
    mat_gb, nodes, links, out, bsdf = init_mat("M_Gold_Bright")
    bsdf.inputs["Base Color"].default_value = COLOR_GOLD_BRIGHT
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.15
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.45
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Gold_Bright"] = mat_gb

    # 4. M_Burgundy_Leather
    mat_bur, nodes, links, out, bsdf = init_mat("M_Burgundy_Leather")
    bsdf.inputs["Base Color"].default_value = COLOR_BURGUNDY
    bsdf.inputs["Roughness"].default_value = 0.35
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.40
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Burgundy_Leather"] = mat_bur

    # 5. M_Stitch
    mat_st, nodes, links, out, bsdf = init_mat("M_Stitch")
    bsdf.inputs["Base Color"].default_value = COLOR_STITCH
    bsdf.inputs["Roughness"].default_value = 0.60
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Stitch"] = mat_st

    # 6. M_Diamond (Crystalline gemstone shader)
    mat_d, nodes, links, out, bsdf = init_mat("M_Diamond")
    bsdf.inputs["Base Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.0
    bsdf.inputs["IOR"].default_value = 2.42
    if "Transmission Weight" in bsdf.inputs:
        bsdf.inputs["Transmission Weight"].default_value = 1.0
    if "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = COLOR_DIAMOND_CYAN
        bsdf.inputs["Emission Strength"].default_value = 1.2
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Diamond"] = mat_d

    # 7. M_Carpet_Red & M_Velvet_Rope
    mat_cr, nodes, links, out, bsdf = init_mat("M_Carpet_Red")
    bsdf.inputs["Base Color"].default_value = COLOR_CARPET_RED
    bsdf.inputs["Roughness"].default_value = 0.85
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.65
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Carpet_Red"] = mat_cr

    mat_vr, nodes, links, out, bsdf = init_mat("M_Velvet_Rope")
    bsdf.inputs["Base Color"].default_value = (0.45, 0.03, 0.06, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.70
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.80
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    materials["M_Velvet_Rope"] = mat_vr

    return materials


# ---------------------------------------------------------------------------
# STEP 1: PROCEDURAL MODELING HELPERS
# ---------------------------------------------------------------------------
def make_block(name: str, size: tuple, loc: tuple, mat: bpy.types.Material = None,
               bevel_width: float = 0.025, bevel_segments: int = 3,
               segments: int = None, col_name: str = "Chair") -> bpy.types.Object:
    """Creates a dimensioned block with smooth bevel."""
    if segments is not None:
        bevel_segments = segments
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
    if mat:
        obj.data.materials.append(mat)
    add_to_collection(obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    if bevel_width > 0:
        add_bevel_modifier(obj, width=bevel_width, segments=bevel_segments)
    return obj


def make_leg(name: str, size: tuple, loc: tuple, mat_wood: bpy.types.Material,
             mat_gold: bpy.types.Material, mat_gem: bpy.types.Material,
             is_front: bool = True, col_name: str = "Chair") -> tuple[bpy.types.Object, bpy.types.Object]:
    """Builds one chunky tapered square leg with a gold foot cap and diamond inlay."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z *= size[2]
        if v.co.z < 0:
            v.co.x *= 0.88
            v.co.y *= 0.88

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    # Leg sits from z=0 to z=size[2]
    leg_obj = bpy.data.objects.new(name, me)
    leg_obj.location = (loc[0], loc[1], loc[2] + size[2] * 0.50)
    leg_obj.data.materials.append(mat_wood)
    add_to_collection(leg_obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    add_bevel_modifier(leg_obj, width=0.02, segments=3)

    # Gold foot cap (0.20 x 0.20 x 0.10)
    cap_size = (size[0] * 1.25, size[1] * 1.25, 0.10)
    cap_loc = (loc[0], loc[1], loc[2] + cap_size[2] * 0.50)
    cap_obj = make_block(f"{name}_Cap", cap_size, cap_loc, mat_gold, bevel_width=0.015, segments=3, col_name=col_name)

    # Diamond inlay on front face of cap
    bm_gem = bmesh.new()
    bmesh.ops.create_cube(bm_gem, size=1.0)
    for v in bm_gem.verts:
        v.co.x *= 0.045
        v.co.y *= 0.008
        v.co.z *= 0.045
    bmesh.ops.rotate(bm_gem, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(45), 4, 'Y'), verts=bm_gem.verts)
    me_gem = bpy.data.meshes.new(f"{name}_GemInlay")
    bm_gem.to_mesh(me_gem)
    bm_gem.free()

    gem_obj = bpy.data.objects.new(f"{name}_GemInlay", me_gem)
    sign_y = 1.0 if is_front else -1.0
    gem_loc = (loc[0], loc[1] + (cap_size[1] * 0.50 + 0.004) * sign_y, loc[2] + cap_size[2] * 0.50)
    gem_obj.location = gem_loc
    if not is_front:
        gem_obj.rotation_euler = (0, 0, math.radians(180))
    gem_obj.data.materials.append(mat_gem)
    add_to_collection(gem_obj, col_name)

    # Clean hierarchy: Gem -> Cap -> Leg
    parent_to(gem_obj, cap_obj)
    parent_to(cap_obj, leg_obj)

    return leg_obj, cap_obj


def make_tufted_cushion(name: str, size: tuple, nx: int = 4, ny: int = 4,
                        loc: tuple = (0, 0, 0), mat_leather: bpy.types.Material = None,
                        mat_button: bpy.types.Material = None, col_name: str = "Chair") -> tuple[bpy.types.Object, list[bpy.types.Object]]:
    """Builds a horizontal puffy diamond-tufted cushion with gold buttons."""
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=nx, y_segments=ny, size=0.5)

    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z = 0.0

    poke_res = bmesh.ops.poke(bm, faces=bm.faces)
    new_faces = poke_res['faces']

    # Raise center vertices for pillow bulge
    for f in new_faces:
        center_v = [v for v in f.verts if len(v.link_edges) > 4]
        for cv in center_v:
            fx = abs(cv.co.x) / (size[0] * 0.5)
            fy = abs(cv.co.y) / (size[1] * 0.5)
            dome = max(0.0, 1.0 - (fx**2 + fy**2) * 0.45)
            cv.co.z = (size[2] * 0.35) * dome

    # Depress interior intersections for buttons
    button_positions = []
    interior_verts = [v for v in bm.verts if not v.is_boundary and len(v.link_edges) == 4]
    for v in interior_verts:
        v.co.z -= size[2] * 0.18
        button_positions.append(Vector((v.co.x, v.co.y, v.co.z)))

    # Extrude side walls down
    boundary_edges = [e for e in bm.edges if e.is_boundary]
    ext = bmesh.ops.extrude_edge_only(bm, edges=boundary_edges)
    ext_verts = [v for v in ext['geom'] if isinstance(v, bmesh.types.BMVert)]
    for v in ext_verts:
        v.co.z -= size[2]

    # Fill base
    bottom_edges = [e for e in ext['geom'] if isinstance(e, bmesh.types.BMEdge) and e.is_boundary]
    bmesh.ops.edgeloop_fill(bm, edges=bottom_edges)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    cushion_obj = bpy.data.objects.new(name, me)
    cushion_obj.location = loc
    if mat_leather:
        cushion_obj.data.materials.append(mat_leather)
    add_to_collection(cushion_obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    sub = cushion_obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2
    sub.render_levels = 2

    # Buttons created at exact world locations, then cleanly parented
    buttons = []
    for i, b_pos in enumerate(button_positions):
        bm_b = bmesh.new()
        bmesh.ops.create_icosphere(bm_b, subdivisions=2, radius=0.018)
        me_b = bpy.data.meshes.new(f"{name}_Button_{i+1:02d}")
        bm_b.to_mesh(me_b)
        bm_b.free()

        btn_obj = bpy.data.objects.new(f"{name}_Button_{i+1:02d}", me_b)
        btn_obj.location = (loc[0] + b_pos.x, loc[1] + b_pos.y, loc[2] + b_pos.z + 0.005)
        if mat_button:
            btn_obj.data.materials.append(mat_button)
        for f in me_b.polygons:
            f.use_smooth = True
        add_to_collection(btn_obj, col_name)
        parent_to(btn_obj, cushion_obj)
        buttons.append(btn_obj)

    return cushion_obj, buttons


def make_tufted_vertical_panel(name: str, width: float, height: float, thickness: float,
                               loc: tuple, mat_leather: bpy.types.Material,
                               mat_button: bpy.types.Material, nx: int = 3, nz: int = 4,
                               col_name: str = "Chair") -> tuple[bpy.types.Object, list[bpy.types.Object]]:
    """Builds a vertical diamond-tufted panel natively in the XZ plane with normals facing +Y."""
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=nx, y_segments=nz, size=0.5)

    # Map to X and Z with Y as depth
    for v in bm.verts:
        vx, vz = v.co.x * width, v.co.y * height
        v.co.x = vx
        v.co.y = 0.0
        v.co.z = vz

    poke_res = bmesh.ops.poke(bm, faces=bm.faces)
    new_faces = poke_res['faces']

    # Raise center vertices in +Y (forward bulge)
    for f in new_faces:
        center_v = [v for v in f.verts if len(v.link_edges) > 4]
        for cv in center_v:
            fx = abs(cv.co.x) / (width * 0.5)
            fz = abs(cv.co.z) / (height * 0.5)
            dome = max(0.0, 1.0 - (fx**2 + fz**2) * 0.40)
            cv.co.y = (thickness * 0.45) * dome

    # Depress interior intersections in -Y
    button_positions = []
    interior_verts = [v for v in bm.verts if not v.is_boundary and len(v.link_edges) == 4]
    for v in interior_verts:
        v.co.y -= thickness * 0.20
        button_positions.append(Vector((v.co.x, v.co.y, v.co.z)))

    # Extrude side walls back in -Y
    boundary_edges = [e for e in bm.edges if e.is_boundary]
    ext = bmesh.ops.extrude_edge_only(bm, edges=boundary_edges)
    ext_verts = [v for v in ext['geom'] if isinstance(v, bmesh.types.BMVert)]
    for v in ext_verts:
        v.co.y -= thickness

    # Fill rear
    back_edges = [e for e in ext['geom'] if isinstance(e, bmesh.types.BMEdge) and e.is_boundary]
    bmesh.ops.edgeloop_fill(bm, edges=back_edges)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    panel_obj = bpy.data.objects.new(name, me)
    panel_obj.location = loc
    if mat_leather:
        panel_obj.data.materials.append(mat_leather)
    add_to_collection(panel_obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    sub = panel_obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2
    sub.render_levels = 2

    # Buttons cleanly placed on front indentations
    buttons = []
    for i, b_pos in enumerate(button_positions):
        bm_b = bmesh.new()
        bmesh.ops.create_icosphere(bm_b, subdivisions=2, radius=0.018)
        me_b = bpy.data.meshes.new(f"{name}_Button_{i+1:02d}")
        bm_b.to_mesh(me_b)
        bm_b.free()

        btn_obj = bpy.data.objects.new(f"{name}_Button_{i+1:02d}", me_b)
        btn_obj.location = (loc[0] + b_pos.x, loc[1] + b_pos.y + 0.005, loc[2] + b_pos.z)
        if mat_button:
            btn_obj.data.materials.append(mat_button)
        for f in me_b.polygons:
            f.use_smooth = True
        add_to_collection(btn_obj, col_name)
        parent_to(btn_obj, panel_obj)
        buttons.append(btn_obj)

    return panel_obj, buttons


def make_stitch_piping(name: str, width: float, depth: float, z_level: float,
                       parent_obj: bpy.types.Object, mat_stitch: bpy.types.Material,
                       radius: float = 0.004, is_vertical: bool = False,
                       col_name: str = "Chair") -> bpy.types.Object:
    """Builds a continuous stitched piping contour around a cushion edge."""
    curve_data = bpy.data.curves.new(name, type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = radius
    curve_data.bevel_resolution = 3
    curve_data.use_fill_caps = True

    polyline = curve_data.splines.new('POLY')
    hw, hd = width * 0.49, depth * 0.49
    if is_vertical:
        pts = [
            (-hw, z_level, -hd),
            ( hw, z_level, -hd),
            ( hw, z_level,  hd),
            (-hw, z_level,  hd),
        ]
    else:
        pts = [
            (-hw, -hd, z_level),
            ( hw, -hd, z_level),
            ( hw,  hd, z_level),
            (-hw,  hd, z_level),
        ]

    polyline.points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        polyline.points[i].co = (p[0], p[1], p[2], 1.0)
    polyline.use_cyclic_u = True

    pipe_obj = bpy.data.objects.new(name, curve_data)
    pipe_obj.location = parent_obj.location
    if mat_stitch:
        pipe_obj.data.materials.append(mat_stitch)
    add_to_collection(pipe_obj, col_name)

    parent_to(pipe_obj, parent_obj)
    return pipe_obj


def make_bolster(name: str, length: float = 0.74, radius: float = 0.09,
                 loc: tuple = (0, 0, 0), mat_leather: bpy.types.Material = None,
                 mat_burgundy: bpy.types.Material = None, mat_gold: bpy.types.Material = None,
                 col_name: str = "Chair") -> bpy.types.Object:
    """Builds the horizontal rolled bolster cushion with burgundy caps and gold piping."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=24, radius1=radius, radius2=radius, depth=length)
    bmesh.ops.rotate(bm, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 4, 'Y'), verts=bm.verts)

    # Soft subtle wrinkles
    for v in bm.verts:
        wrinkle = math.sin(v.co.x * 24.0) * 0.0025
        v.co.y += wrinkle * (v.co.y / (radius + 0.0001))
        v.co.z += wrinkle * (v.co.z / (radius + 0.0001))

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    bolster_obj = bpy.data.objects.new(name, me)
    bolster_obj.location = loc
    if mat_leather:
        bolster_obj.data.materials.append(mat_leather)
    add_to_collection(bolster_obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    sub = bolster_obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2
    add_bevel_modifier(bolster_obj, width=0.015, segments=3)

    # Burgundy end discs & gold stitch rings
    for side, x_pos in [("L", -length * 0.502), ("R", length * 0.502)]:
        bm_disc = bmesh.new()
        bmesh.ops.create_circle(bm_disc, cap_ends=True, segments=24, radius=radius * 0.94)
        bmesh.ops.rotate(bm_disc, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 4, 'Y'), verts=bm_disc.verts)
        me_disc = bpy.data.meshes.new(f"{name}_EndCap_{side}")
        bm_disc.to_mesh(me_disc)
        bm_disc.free()

        disc_obj = bpy.data.objects.new(f"{name}_EndCap_{side}", me_disc)
        disc_obj.location = (loc[0] + x_pos, loc[1], loc[2])
        if mat_burgundy:
            disc_obj.data.materials.append(mat_burgundy)
        add_to_collection(disc_obj, col_name)
        parent_to(disc_obj, bolster_obj)

        # Gold stitch ring
        curve_data = bpy.data.curves.new(f"{name}_Ring_{side}", type='CURVE')
        curve_data.dimensions = '3D'
        curve_data.bevel_depth = 0.004
        polyline = curve_data.splines.new('POLY')
        ring_pts = 16
        polyline.points.add(ring_pts - 1)
        for i in range(ring_pts):
            a = (i / ring_pts) * 2 * math.pi
            polyline.points[i].co = (0, radius * 0.94 * math.cos(a), radius * 0.94 * math.sin(a), 1.0)
        polyline.use_cyclic_u = True

        ring_obj = bpy.data.objects.new(f"{name}_Ring_{side}", curve_data)
        ring_obj.location = (loc[0] + x_pos * 1.002, loc[1], loc[2])
        if mat_gold:
            ring_obj.data.materials.append(mat_gold)
        add_to_collection(ring_obj, col_name)
        parent_to(ring_obj, bolster_obj)

    return bolster_obj


def make_armrest(name: str, size: tuple, loc: tuple,
                 mat_leather: bpy.types.Material, mat_gold: bpy.types.Material,
                 mat_stitch: bpy.types.Material, col_name: str = "Chair") -> tuple[bpy.types.Object, bpy.types.Object]:
    """Builds a thick padded armrest with chunky front gold cube cap and supports."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z *= size[2]

    # Pillow rounding: taper top front and outer corners
    for v in bm.verts:
        if v.co.z > 0:
            v.co.z += (1.0 - (v.co.x / (size[0]*0.5))**2) * 0.02

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    arm_obj = bpy.data.objects.new(name, me)
    arm_obj.location = loc
    arm_obj.data.materials.append(mat_leather)
    add_to_collection(arm_obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    sub = arm_obj.modifiers.new("Subsurf", "SUBSURF")
    sub.levels = 2
    add_bevel_modifier(arm_obj, width=0.025, segments=3)

    # Gold square cap (0.2 x 0.16 x 0.2) at front end
    cap_size = (size[0] * 1.08, 0.16, size[2] * 1.08)
    cap_loc = (loc[0], loc[1] + (size[1] * 0.5) + (cap_size[1] * 0.46), loc[2])
    cap_obj = make_block(f"{name}_Cap", cap_size, cap_loc, mat_gold, bevel_width=0.025, segments=3, col_name=col_name)
    parent_to(cap_obj, arm_obj)

    # Armrest vertical support pillar to seat frame
    support_size = (size[0] * 0.65, size[1] * 0.70, 0.22)
    support_loc = (loc[0], loc[1], loc[2] - (size[2]*0.5) - (support_size[2]*0.48))
    support_obj = make_block(f"{name}_Support", support_size, support_loc, mat_leather, bevel_width=0.015, segments=3, col_name=col_name)
    parent_to(support_obj, arm_obj)

    # Stitched seam line along top ridge
    make_stitch_piping(f"{name}_Stitch", size[0] * 0.92, size[1] * 0.95, size[2] * 0.51, arm_obj, mat_stitch, radius=0.0035, col_name=col_name)

    return arm_obj, cap_obj


def make_backrest_frame(name: str, width: float = 1.0, height: float = 1.40,
                        depth: float = 0.14, chamfer: float = 0.15,
                        mat_gold: bpy.types.Material = None, col_name: str = "Chair") -> bpy.types.Object:
    """Builds the tall regal champagne-gold backrest frame with chamfered top corners."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)

    for v in bm.verts:
        v.co.x *= width
        v.co.y *= depth
        v.co.z *= height

    # Chamfer top-left and top-right corners
    top_edges = []
    for e in bm.edges:
        v1, v2 = e.verts
        if abs(v1.co.z - height*0.5) < 0.001 and abs(v2.co.z - height*0.5) < 0.001:
            if abs(v1.co.x) > width*0.35 and abs(v2.co.x) > width*0.35:
                top_edges.append(e)

    if top_edges:
        bmesh.ops.bevel(bm, geom=top_edges, offset=chamfer, offset_type='OFFSET', segments=1, profile=0.5)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    frame_obj = bpy.data.objects.new(name, me)
    if mat_gold:
        frame_obj.data.materials.append(mat_gold)
    add_to_collection(frame_obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    add_bevel_modifier(frame_obj, width=0.03, segments=3)

    return frame_obj


def make_diamond(name: str, width: float = 0.28, height: float = 0.22,
                 loc: tuple = (0, 0, 0), mat_diamond: bpy.types.Material = None,
                 col_name: str = "Chair") -> bpy.types.Object:
    """Constructs a brilliant-cut faceted diamond gem with shimmering facets."""
    bm = bmesh.new()
    segments = 8

    table_r = width * 0.35
    table_z = height * 0.42
    girdle_r = width * 0.50
    girdle_z = height * 0.04
    culet_z = -height * 0.56

    # Top table
    table_verts = []
    for i in range(segments):
        a = (i / segments) * 2 * math.pi
        v = bm.verts.new(Vector((table_r * math.cos(a), table_r * math.sin(a), table_z)))
        table_verts.append(v)
    bm.faces.new(table_verts)

    # Girdle ring
    girdle_verts = []
    for i in range(segments):
        a = ((i + 0.5) / segments) * 2 * math.pi
        v = bm.verts.new(Vector((girdle_r * math.cos(a), girdle_r * math.sin(a), girdle_z)))
        girdle_verts.append(v)

    # Crown facets (triangles from table to girdle)
    for i in range(segments):
        i_next = (i + 1) % segments
        bm.faces.new([table_verts[i], girdle_verts[i], table_verts[i_next]])
        bm.faces.new([table_verts[i_next], girdle_verts[i], girdle_verts[i_next]])

    # Culet point at base
    culet_v = bm.verts.new(Vector((0, 0, culet_z)))
    for i in range(segments):
        i_next = (i + 1) % segments
        bm.faces.new([girdle_verts[i], culet_v, girdle_verts[i_next]])

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    gem_obj = bpy.data.objects.new(name, me)
    gem_obj.location = loc
    if mat_diamond:
        gem_obj.data.materials.append(mat_diamond)
    add_to_collection(gem_obj, col_name)

    for f in me.polygons:
        f.use_smooth = False
    add_bevel_modifier(gem_obj, width=0.003, segments=2)

    return gem_obj


def make_bezel(name: str, width: float = 0.32, height: float = 0.20,
               loc: tuple = (0, 0, 0), mat_gold: bpy.types.Material = None,
               col_name: str = "Chair") -> bpy.types.Object:
    """Builds the ornate gold bezel cradle with left & right curled scroll shapes."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=8, radius1=width * 0.52, radius2=0.02, depth=height * 0.9)
    for v in bm.verts:
        v.co.y *= 0.65

    # Side curled scrolls
    for side in (-1, 1):
        x_base = side * width * 0.42
        z_base = -height * 0.25
        res_curl = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=0.032, radius2=0.032, depth=0.024)
        for v in res_curl['verts']:
            v.co.x += x_base
            v.co.z += z_base

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    bezel_obj = bpy.data.objects.new(name, me)
    bezel_obj.location = loc
    if mat_gold:
        bezel_obj.data.materials.append(mat_gold)
    add_to_collection(bezel_obj, col_name)

    for f in me.polygons:
        f.use_smooth = True
    add_bevel_modifier(bezel_obj, width=0.01, segments=3)

    return bezel_obj


def make_emblem(name: str, loc: tuple, rot: tuple, parent: bpy.types.Object,
                mat_leather: bpy.types.Material, col_name: str = "Chair") -> bpy.types.Object:
    """Builds the debossed Crown + Football relief emblem on the backrest."""
    curve_data = bpy.data.curves.new(name, type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = 0.003
    curve_data.extrude = 0.004

    # 1. Crown
    spline_crown = curve_data.splines.new('POLY')
    crown_pts = [
        (-0.065, 0, 0.080),
        (-0.040, 0, 0.125),
        (-0.020, 0, 0.095),
        ( 0.000, 0, 0.140),
        ( 0.020, 0, 0.095),
        ( 0.040, 0, 0.125),
        ( 0.065, 0, 0.080),
        ( 0.050, 0, 0.070),
        (-0.050, 0, 0.070),
    ]
    spline_crown.points.add(len(crown_pts) - 1)
    for i, p in enumerate(crown_pts):
        spline_crown.points[i].co = (p[0], p[1], p[2], 1.0)
    spline_crown.use_cyclic_u = True

    # 2. Football
    spline_ball = curve_data.splines.new('POLY')
    n_pts = 16
    ball_rx, ball_rz = 0.070, 0.042
    spline_ball.points.add(n_pts - 1)
    for i in range(n_pts):
        a = (i / n_pts) * 2 * math.pi
        px = ball_rx * math.cos(a)
        pz = ball_rz * math.sin(a) * (1.0 - 0.25 * (math.cos(a)**2))
        spline_ball.points[i].co = (px, 0, pz, 1.0)
    spline_ball.use_cyclic_u = True

    emblem_obj = bpy.data.objects.new(name, curve_data)
    emblem_obj.location = loc
    emblem_obj.rotation_euler = rot
    if mat_leather:
        emblem_obj.data.materials.append(mat_leather)
    add_to_collection(emblem_obj, col_name)

    parent_to(emblem_obj, parent)
    return emblem_obj


def make_vip_plate(name: str, loc: tuple, mat_gold: bpy.types.Material,
                   col_name: str = "Chair") -> bpy.types.Object:
    """Builds the front gold VIP plate with 3D extruded and beveled text."""
    plate_size = (0.30, 0.04, 0.09)
    plate_obj = make_block(name, plate_size, loc, mat_gold, bevel_width=0.012, segments=3, col_name=col_name)

    # 3D VIP Text
    curve_font = bpy.data.curves.new(f"{name}_Text", type='FONT')
    curve_font.body = "VIP"
    curve_font.size = 0.052
    curve_font.extrude = 0.010
    curve_font.bevel_depth = 0.0025
    curve_font.align_x = 'CENTER'
    curve_font.align_y = 'CENTER'

    text_obj = bpy.data.objects.new(f"{name}_Text", curve_font)
    text_obj.location = (loc[0], loc[1] + (plate_size[1] * 0.50) + 0.002, loc[2])
    text_obj.rotation_euler = (math.radians(90), 0, 0)
    if mat_gold:
        text_obj.data.materials.append(mat_gold)
    add_to_collection(text_obj, col_name)

    parent_to(text_obj, plate_obj)
    return plate_obj


def make_star_flare(name: str, radius: float = 0.045, loc: tuple = (0, 0, 0),
                    mat_glow: bpy.types.Material = None, col_name: str = "Effects") -> bpy.types.Object:
    """Builds a flat 4-point diamond sparkle flare mesh."""
    bm = bmesh.new()
    pts = [
        Vector(( 0.0, 0.0,  radius)),
        Vector(( radius * 0.18, 0.0,  radius * 0.18)),
        Vector(( radius, 0.0,  0.0)),
        Vector(( radius * 0.18, 0.0, -radius * 0.18)),
        Vector(( 0.0, 0.0, -radius)),
        Vector((-radius * 0.18, 0.0, -radius * 0.18)),
        Vector((-radius, 0.0,  0.0)),
        Vector((-radius * 0.18, 0.0,  radius * 0.18)),
    ]
    verts = [bm.verts.new(p) for p in pts]
    bm.faces.new(verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()

    flare_obj = bpy.data.objects.new(name, me)
    flare_obj.location = loc
    if mat_glow:
        flare_obj.data.materials.append(mat_glow)
    add_to_collection(flare_obj, col_name)
    return flare_obj


def make_stanchion_and_rope(pos_left: tuple, pos_right: tuple, mat_gold: bpy.types.Material,
                            mat_rope: bpy.types.Material, col_name: str = "Rope_And_Carpet") -> list[bpy.types.Object]:
    """Builds two classic velvet-rope stanchion posts with a gently sagging rope."""
    objs = []
    for side, pos in [("L", pos_left), ("R", pos_right)]:
        base_obj = make_block(f"Stanchion_Base_{side}", (0.24, 0.24, 0.04), (pos[0], pos[1], pos[2] + 0.02),
                              mat_gold, bevel_width=0.015, col_name=col_name)
        objs.append(base_obj)

        pole_bm = bmesh.new()
        bmesh.ops.create_cone(pole_bm, cap_ends=True, segments=16, radius1=0.025, radius2=0.025, depth=0.88)
        pole_me = bpy.data.meshes.new(f"Stanchion_Pole_{side}")
        pole_bm.to_mesh(pole_me)
        pole_bm.free()
        pole_obj = bpy.data.objects.new(f"Stanchion_Pole_{side}", pole_me)
        pole_obj.location = (pos[0], pos[1], pos[2] + 0.46)
        pole_obj.data.materials.append(mat_gold)
        add_to_collection(pole_obj, col_name)
        parent_to(pole_obj, base_obj)
        objs.append(pole_obj)

        ball_bm = bmesh.new()
        bmesh.ops.create_icosphere(ball_bm, subdivisions=2, radius=0.045)
        ball_me = bpy.data.meshes.new(f"Stanchion_Ball_{side}")
        ball_bm.to_mesh(ball_me)
        ball_bm.free()
        ball_obj = bpy.data.objects.new(f"Stanchion_Ball_{side}", ball_me)
        ball_obj.location = (pos[0], pos[1], pos[2] + 0.92)
        ball_obj.data.materials.append(mat_gold)
        add_to_collection(ball_obj, col_name)
        parent_to(ball_obj, base_obj)
        objs.append(ball_obj)

    # Velvet Rope Curve
    curve_data = bpy.data.curves.new("Velvet_Rope", type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = 0.024
    curve_data.bevel_resolution = 4
    curve_data.use_fill_caps = True

    spline = curve_data.splines.new('BEZIER')
    spline.bezier_points.add(2)
    p0, p1, p2 = spline.bezier_points[0], spline.bezier_points[1], spline.bezier_points[2]
    mid_x = (pos_left[0] + pos_right[0]) * 0.5
    mid_y = (pos_left[1] + pos_right[1]) * 0.5

    p0.co = (pos_left[0], pos_left[1], pos_left[2] + 0.88)
    p0.handle_right = (pos_left[0] + 0.35, pos_left[1], pos_left[2] + 0.70)
    p0.handle_left = (pos_left[0] - 0.2, pos_left[1], pos_left[2] + 0.88)

    p1.co = (mid_x, mid_y, 0.48)
    p1.handle_left = (mid_x - 0.35, mid_y, 0.48)
    p1.handle_right = (mid_x + 0.35, mid_y, 0.48)

    p2.co = (pos_right[0], pos_right[1], pos_right[2] + 0.88)
    p2.handle_left = (pos_right[0] - 0.35, pos_right[1], pos_right[2] + 0.70)
    p2.handle_right = (pos_right[0] + 0.2, pos_right[1], pos_right[2] + 0.88)

    rope_obj = bpy.data.objects.new("Velvet_Rope", curve_data)
    rope_obj.data.materials.append(mat_rope)
    add_to_collection(rope_obj, col_name)
    objs.append(rope_obj)

    return objs


# ---------------------------------------------------------------------------
# STEP 3: ANIMATION SEQUENCES (24 FPS)
# ---------------------------------------------------------------------------
def set_kf_interpolation(obj: bpy.types.Object, mode: str = 'BEZIER'):
    """Sets interpolation mode on all keyframe points of an object's action."""
    if not obj.animation_data or not obj.animation_data.action:
        return
    for fc in get_action_fcurves(obj.animation_data.action):
        for kp in fc.keyframe_points:
            kp.interpolation = mode


def animate_intro_reveal(chair_parts: dict):
    """Intro Reveal (Frames 1-90): Elastic pops, bounces, inflation and gemstone flash."""
    # 1. Legs and foot caps (Frames 1 - 25)
    for leg in chair_parts.get("legs", []):
        leg.scale = (1.0, 1.0, 0.001)
        leg.keyframe_insert("scale", frame=1)
        leg.scale = (1.05, 1.05, 1.18)
        leg.keyframe_insert("scale", frame=16)
        leg.scale = (1.0, 1.0, 1.0)
        leg.keyframe_insert("scale", frame=24)
        leg.keyframe_insert("scale", frame=90)
        set_kf_interpolation(leg, 'BACK')

    for cap in chair_parts.get("foot_caps", []):
        cap.scale = (0.001, 0.001, 0.001)
        cap.keyframe_insert("scale", frame=1)
        cap.keyframe_insert("scale", frame=8)
        cap.scale = (1.15, 1.15, 1.15)
        cap.keyframe_insert("scale", frame=22)
        cap.scale = (1.0, 1.0, 1.0)
        cap.keyframe_insert("scale", frame=30)
        cap.keyframe_insert("scale", frame=90)
        set_kf_interpolation(cap, 'BACK')

    # 2. Seat Frame drops and bounces (Frames 1 - 36)
    sf = chair_parts["seat_frame"]
    base_sf_z = sf.location.z
    sf.location.z = base_sf_z + 0.85
    sf.keyframe_insert("location", frame=1)
    sf.keyframe_insert("location", frame=12)
    sf.location.z = base_sf_z - 0.03
    sf.keyframe_insert("location", frame=28)
    sf.location.z = base_sf_z
    sf.keyframe_insert("location", frame=36)
    sf.keyframe_insert("location", frame=90)
    set_kf_interpolation(sf, 'BOUNCE')

    # 3. Seat Cushion inflates from scale 0 (Frames 1 - 46)
    sc = chair_parts["seat_cushion"]
    sc.scale = (0.001, 0.001, 0.001)
    sc.keyframe_insert("scale", frame=1)
    sc.keyframe_insert("scale", frame=22)
    sc.scale = (1.06, 1.06, 1.14)
    sc.keyframe_insert("scale", frame=38)
    sc.scale = (1.0, 1.0, 1.0)
    sc.keyframe_insert("scale", frame=46)
    sc.keyframe_insert("scale", frame=90)
    set_kf_interpolation(sc, 'BACK')

    # 4. Armrests slide in from sides (Frames 1 - 54)
    for arm in chair_parts.get("armrests", []):
        base_x = arm.location.x
        arm.location.x = base_x * 1.55
        arm.keyframe_insert("location", frame=1)
        arm.keyframe_insert("location", frame=32)
        arm.location.x = base_x * 0.96
        arm.keyframe_insert("location", frame=46)
        arm.location.x = base_x
        arm.keyframe_insert("location", frame=54)
        arm.keyframe_insert("location", frame=90)
        set_kf_interpolation(arm, 'BACK')

    # 5. Backrest rises from behind (Frames 1 - 62)
    bf = chair_parts["backrest_frame"]
    base_bf_z = bf.location.z
    bf.location.z = base_bf_z - 0.70
    bf.keyframe_insert("location", frame=1)
    bf.keyframe_insert("location", frame=26)
    bf.location.z = base_bf_z + 0.02
    bf.keyframe_insert("location", frame=52)
    bf.location.z = base_bf_z
    bf.keyframe_insert("location", frame=62)
    bf.keyframe_insert("location", frame=90)
    set_kf_interpolation(bf, 'BEZIER')

    # 6. Bolster rolls in and settles (Frames 1 - 68)
    bolster = chair_parts["bolster"]
    base_bz = bolster.location.z
    bolster.location.z = base_bz + 0.35
    bolster.rotation_euler.x = math.radians(120)
    bolster.keyframe_insert("location", frame=1)
    bolster.keyframe_insert("rotation_euler", frame=1)
    bolster.keyframe_insert("location", frame=42)
    bolster.keyframe_insert("rotation_euler", frame=42)
    bolster.location.z = base_bz
    bolster.rotation_euler.x = 0
    bolster.keyframe_insert("location", frame=64)
    bolster.keyframe_insert("rotation_euler", frame=64)
    bolster.keyframe_insert("location", frame=90)
    bolster.keyframe_insert("rotation_euler", frame=90)
    set_kf_interpolation(bolster, 'BOUNCE')

    # 7. Diamond Gem drops from above, impacts and flashes (Frames 1 - 82)
    dia = chair_parts["diamond"]
    base_dz = dia.location.z
    dia.location.z = base_dz + 0.85
    dia.keyframe_insert("location", frame=1)
    dia.keyframe_insert("location", frame=62)
    dia.location.z = base_dz
    dia.keyframe_insert("location", frame=73)
    dia.location.z = base_dz + 0.015
    dia.keyframe_insert("location", frame=76)
    dia.location.z = base_dz
    dia.keyframe_insert("location", frame=82)
    dia.keyframe_insert("location", frame=90)
    set_kf_interpolation(dia, 'BOUNCE')

    # Diamond Flash on impact (Frame 73 - 77)
    mat_d = dia.data.materials[0]
    bsdf = mat_d.node_tree.nodes.get("Principled BSDF")
    if bsdf and "Emission Strength" in bsdf.inputs:
        emit_input = bsdf.inputs["Emission Strength"]
        emit_input.default_value = 1.0
        emit_input.keyframe_insert("default_value", frame=1)
        emit_input.keyframe_insert("default_value", frame=70)
        emit_input.default_value = 22.0
        emit_input.keyframe_insert("default_value", frame=73)
        emit_input.default_value = 1.0
        emit_input.keyframe_insert("default_value", frame=78)
        emit_input.keyframe_insert("default_value", frame=90)


def animate_idle_loop(chair_parts: dict):
    """Seamless Idle Loop (Frames 91 - 330): 240-frame continuous cycle."""
    dia = chair_parts["diamond"]
    base_dz = dia.location.z

    # Diamond 360 degree rotation + vertical float bob
    dia.rotation_euler.z = 0.0
    dia.keyframe_insert("rotation_euler", index=2, frame=FRAME_IDLE_START)
    dia.rotation_euler.z = math.radians(360)
    dia.keyframe_insert("rotation_euler", index=2, frame=FRAME_IDLE_END)

    for step in range(5):
        f = FRAME_IDLE_START + step * 60
        sine_offset = 0.015 if (step % 2 == 1) else 0.0
        dia.location.z = base_dz + sine_offset
        dia.keyframe_insert("location", index=2, frame=f)

    # Leather breathing squash
    sc = chair_parts["seat_cushion"]
    for step in range(3):
        f_mid = FRAME_IDLE_START + step * 120
        sc.scale.z = 1.0
        sc.keyframe_insert("scale", index=2, frame=f_mid)
        if f_mid + 60 <= FRAME_IDLE_END:
            sc.scale.z = 1.015
            sc.keyframe_insert("scale", index=2, frame=f_mid + 60)
    sc.scale.z = 1.0
    sc.keyframe_insert("scale", index=2, frame=FRAME_IDLE_END)

    # Diamond twinkle sparkles
    random.seed(RANDOM_SEED)
    for flare in chair_parts.get("sparkles", []):
        start_offset = random.randint(0, 48)
        for loop_t in range(FRAME_IDLE_START + start_offset, FRAME_IDLE_END - 24, 60):
            flare.scale = (0.001, 0.001, 0.001)
            flare.keyframe_insert("scale", frame=loop_t)
            flare.scale = (1.0, 1.0, 1.0)
            flare.keyframe_insert("scale", frame=loop_t + 12)
            flare.scale = (0.001, 0.001, 0.001)
            flare.keyframe_insert("scale", frame=loop_t + 24)


def create_sit_reaction_action(chair_parts: dict) -> bpy.types.Action:
    """Creates a dedicated 36-frame 'Sit_Reaction' Action."""
    sc = chair_parts["seat_cushion"]
    act_name = "Sit_Reaction"
    act = bpy.data.actions.new(name=act_name)

    orig_action = sc.animation_data.action if sc.animation_data else None

    if not sc.animation_data:
        sc.animation_data_create()
    sc.animation_data.action = act

    sc.scale = (1.0, 1.0, 1.0)
    sc.keyframe_insert("scale", frame=1)
    sc.scale = (1.05, 1.05, 0.85)  # 15% squash
    sc.keyframe_insert("scale", frame=6)
    sc.scale = (0.98, 0.98, 1.04)  # spring rebound
    sc.keyframe_insert("scale", frame=16)
    sc.scale = (1.0, 1.0, 1.0)
    sc.keyframe_insert("scale", frame=36)
    set_kf_interpolation(sc, 'BACK')

    if orig_action:
        sc.animation_data.action = orig_action

    return act


# ---------------------------------------------------------------------------
# STEP 4: SCENE, LIGHTING, CAMERA & RENDER CONFIGURATION
# ---------------------------------------------------------------------------
def setup_lighting_and_scene():
    """Sets up 3-point studio lighting, floor disc, spotlight and camera."""
    # 1. Round Glossy Black Floor Disc
    bm_floor = bmesh.new()
    bmesh.ops.create_circle(bm_floor, cap_ends=True, segments=64, radius=2.60)
    me_floor = bpy.data.meshes.new("Floor_GlossyDisc")
    bm_floor.to_mesh(me_floor)
    bm_floor.free()
    floor_obj = bpy.data.objects.new("Floor_GlossyDisc", me_floor)
    floor_obj.location = (0, 0, 0.001)

    mat_floor = bpy.data.materials.new("M_Floor_Disc")
    if not getattr(mat_floor, "use_nodes", False):
        try:
            mat_floor.use_nodes = True
        except Exception:
            pass
    nt = mat_floor.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.02, 0.02, 0.025, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.12
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.6
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    floor_obj.data.materials.append(mat_floor)
    add_to_collection(floor_obj, "Scene")

    # 2. Key Area Light (Warm white 800W)
    key_light = bpy.data.lights.new("Light_Key", 'AREA')
    key_light.energy = 800.0
    key_light.color = (1.00, 0.94, 0.86)
    key_light.size = 2.4
    key_obj = bpy.data.objects.new("Light_Key", key_light)
    key_obj.location = (-1.8, -2.4, 2.6)
    key_obj.rotation_euler = (math.radians(52), math.radians(-15), math.radians(-32))
    add_to_collection(key_obj, "Lights")

    # 3. Fill Area Light (Cool white 200W)
    fill_light = bpy.data.lights.new("Light_Fill", 'AREA')
    fill_light.energy = 220.0
    fill_light.color = (0.86, 0.92, 1.00)
    fill_light.size = 3.0
    fill_obj = bpy.data.objects.new("Light_Fill", fill_light)
    fill_obj.location = (2.2, -1.8, 1.8)
    fill_obj.rotation_euler = (math.radians(45), math.radians(20), math.radians(48))
    add_to_collection(fill_obj, "Lights")

    # 4. Rim Area Light (Cool white 400W from behind)
    rim_light = bpy.data.lights.new("Light_Rim", 'AREA')
    rim_light.energy = 450.0
    rim_light.color = (0.92, 0.96, 1.00)
    rim_light.size = 2.0
    rim_obj = bpy.data.objects.new("Light_Rim", rim_light)
    rim_obj.location = (0.0, 2.5, 2.8)
    rim_obj.rotation_euler = (math.radians(-135), 0, 0)
    add_to_collection(rim_obj, "Lights")

    # 5. Warm Spotlight Cone from above
    spot_light = bpy.data.lights.new("Light_Spot_VIP", 'SPOT')
    spot_light.energy = 600.0
    spot_light.color = (1.00, 0.92, 0.78)
    spot_light.spot_size = math.radians(40)
    spot_light.spot_blend = 0.80
    spot_obj = bpy.data.objects.new("Light_Spot_VIP", spot_light)
    spot_obj.location = (0.0, 0.0, 3.4)
    add_to_collection(spot_obj, "Lights")

    # 6. Studio World Environment
    world = bpy.context.scene.world or bpy.data.worlds.new("World_Studio")
    bpy.context.scene.world = world
    if not getattr(world, "use_nodes", False):
        try:
            world.use_nodes = True
        except Exception:
            pass
    wnt = world.node_tree
    wnt.nodes.clear()
    w_out = wnt.nodes.new("ShaderNodeOutputWorld")
    w_bg = wnt.nodes.new("ShaderNodeBackground")
    w_bg.inputs["Color"].default_value = (0.04, 0.04, 0.05, 1.0)
    w_bg.inputs["Strength"].default_value = 0.45
    wnt.links.new(w_bg.outputs["Background"], w_out.inputs["Surface"])

    # 7. Camera (55mm focal length, 3/4 front view)
    cam_data = bpy.data.cameras.new("Camera_Main")
    cam_data.lens = 55.0
    cam_data.sensor_width = 36.0
    cam_obj = bpy.data.objects.new("Camera_Main", cam_data)
    cam_obj.location = (2.40, -3.20, 1.85)
    cam_obj.rotation_euler = (math.radians(68), 0, math.radians(38))
    add_to_collection(cam_obj, "Scene")
    bpy.context.scene.camera = cam_obj


def setup_render_and_compositor():
    """Configures Cycles rendering, AgX color management, and Glare compositor."""
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = FRAME_INTRO_START
    scene.frame_end = FRAME_IDLE_END

    # Cycles default settings
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 192
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 12
    scene.cycles.transmission_bounces = 12

    # AgX Color Management
    if hasattr(scene, "view_settings"):
        try:
            scene.view_settings.view_transform = 'AgX'
            scene.view_settings.look = 'Medium High Contrast'
        except Exception:
            pass

    # Compositor with Glare Fog Glow (safe cross-version)
    try:
        if hasattr(scene, "node_tree") and scene.node_tree:
            cnt = scene.node_tree
            cnt.nodes.clear()
            comp_in = cnt.nodes.new("CompositorNodeRLayers")
            glare = cnt.nodes.new("CompositorNodeGlare")
            if hasattr(glare, "glare_type"):
                glare.glare_type = 'FOG_GLOW'
            if "Threshold" in glare.inputs:
                glare.inputs["Threshold"].default_value = 1.0
            comp_out = cnt.nodes.new("CompositorNodeComposite")
            cnt.links.new(comp_in.outputs["Image"], glare.inputs["Image"])
            cnt.links.new(glare.outputs["Image"], comp_out.inputs["Image"])
    except Exception as e:
        print(f"Note: Compositor setup skipped ({e})")


# ---------------------------------------------------------------------------
# MAIN BUILDER FUNCTION
# ---------------------------------------------------------------------------
def build_vip_chair_scene():
    """Generates the Black Diamond VIP Chair with full procedural geometry, materials, and hierarchy."""
    random.seed(RANDOM_SEED)

    # 1. Clear existing mesh, curve, and light objects
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for col in list(bpy.data.collections):
        bpy.data.collections.remove(col, do_unlink=True)

    # 2. Master Root Empty at origin
    root_empty = bpy.data.objects.new("VIPChair", None)
    root_empty.empty_display_type = 'ARROWS'
    root_empty.empty_display_size = 0.35
    root_empty.location = (0, 0, 0)
    add_to_collection(root_empty, "Chair")

    # 3. Generate Materials
    mats = create_all_materials()

    chair_parts = {
        "legs": [],
        "foot_caps": [],
        "armrests": [],
        "arm_caps": [],
        "buttons": [],
        "sparkles": [],
    }

    # -----------------------------------------------------------------------
    # A) 4 CHUNKY SQUARE LEGS & GOLD FOOT CAPS
    # -----------------------------------------------------------------------
    leg_size = (0.16, 0.16, 0.50)
    leg_x, leg_y = 0.38, 0.28
    leg_positions = [
        ("Leg_FL", (-leg_x,  leg_y, 0), True),
        ("Leg_FR", ( leg_x,  leg_y, 0), True),
        ("Leg_BL", (-leg_x, -leg_y, 0), False),
        ("Leg_BR", ( leg_x, -leg_y, 0), False),
    ]

    for name, loc, is_front in leg_positions:
        leg_obj, cap_obj = make_leg(
            name, leg_size, loc,
            mats["M_Leather_Black"], mats["M_Gold_Bright"], mats["M_Diamond"],
            is_front=is_front, col_name="Chair"
        )
        parent_to(leg_obj, root_empty)
        chair_parts["legs"].append(leg_obj)
        chair_parts["foot_caps"].append(cap_obj)

    # -----------------------------------------------------------------------
    # B) SEAT FRAME & VIP PLAQUE
    # -----------------------------------------------------------------------
    frame_size = (1.00, 0.85, 0.14)
    frame_z = leg_size[2] + (frame_size[2] * 0.50)  # Z = 0.57
    seat_frame = make_block("Seat_Frame", frame_size, (0, 0, frame_z), mats["M_Gold_Champagne"], bevel_width=0.03, col_name="Chair")
    parent_to(seat_frame, root_empty)
    chair_parts["seat_frame"] = seat_frame

    # Front VIP Plaque
    plate_loc = (0, (frame_size[1] * 0.50) + 0.02, frame_z)
    vip_plate = make_vip_plate("VIP_Plate", plate_loc, mats["M_Gold_Bright"], col_name="Chair")
    parent_to(vip_plate, seat_frame)

    # -----------------------------------------------------------------------
    # C) SEAT CUSHION, BUTTONS & BOLSTER
    # -----------------------------------------------------------------------
    cushion_size = (0.92, 0.78, 0.16)
    cushion_z = frame_z + (frame_size[2] * 0.50)  # Z = 0.64 (bottom of cushion)
    seat_cushion, buttons_c = make_tufted_cushion(
        "Seat_Cushion", cushion_size, nx=4, ny=4, loc=(0, -0.01, cushion_z),
        mat_leather=mats["M_Leather_Black"], mat_button=mats["M_Gold_Bright"], col_name="Chair"
    )
    parent_to(seat_cushion, root_empty)
    chair_parts["seat_cushion"] = seat_cushion
    chair_parts["buttons"].extend(buttons_c)

    # Gold stitch perimeter piping
    make_stitch_piping("Seat_Stitch", cushion_size[0] * 0.96, cushion_size[1] * 0.96, cushion_size[2] * 0.02,
                       seat_cushion, mats["M_Stitch"], radius=0.004, col_name="Chair")

    # Rolled Bolster Cushion at back of seat
    bolster_loc = (0, -0.27, cushion_z + (cushion_size[2] * 0.45))
    bolster = make_bolster("Bolster_Cushion", length=0.74, radius=0.088, loc=bolster_loc,
                           mat_leather=mats["M_Leather_Black"], mat_burgundy=mats["M_Burgundy_Leather"],
                           mat_gold=mats["M_Gold_Bright"], col_name="Chair")
    parent_to(bolster, root_empty)
    chair_parts["bolster"] = bolster

    # -----------------------------------------------------------------------
    # D) ARMRESTS & FRONT GOLD CAPS
    # -----------------------------------------------------------------------
    arm_x = 0.52
    arm_size = (0.19, 0.68, 0.17)
    arm_z = frame_z + 0.32

    for side, x_pos in [("L", -arm_x), ("R", arm_x)]:
        arm_obj, cap_obj = make_armrest(
            f"Armrest_{side}", arm_size, (x_pos, 0.02, arm_z),
            mats["M_Leather_Black"], mats["M_Gold_Bright"], mats["M_Stitch"], col_name="Chair"
        )
        parent_to(arm_obj, root_empty)
        chair_parts["armrests"].append(arm_obj)
        chair_parts["arm_caps"].append(cap_obj)

    # -----------------------------------------------------------------------
    # E) BACKREST FRAME, TUFTED PANEL & EMBLEM
    # -----------------------------------------------------------------------
    back_width = 1.00
    back_height = 1.40
    back_depth = 0.14
    back_tilt = math.radians(-5.0)

    # Pivot point at base of backrest
    back_base_z = frame_z + (frame_size[2] * 0.50)
    back_base_y = -0.34
    half_h = back_height * 0.50

    back_center_y = back_base_y - (half_h * math.sin(abs(back_tilt)))
    back_center_z = back_base_z + (half_h * math.cos(back_tilt))

    back_frame = make_backrest_frame("Backrest_Frame", width=back_width, height=back_height, depth=back_depth,
                                     chamfer=0.15, mat_gold=mats["M_Gold_Champagne"], col_name="Chair")
    back_frame.location = (0, back_center_y, back_center_z)
    back_frame.rotation_euler = (back_tilt, 0, 0)
    parent_to(back_frame, root_empty)
    chair_parts["backrest_frame"] = back_frame

    # Inner Tufted Panel natively vertical in XZ
    panel_w, panel_h, panel_d = 0.80, 1.16, 0.08
    panel_loc = (0, back_center_y + 0.035, back_center_z - 0.02)
    back_panel, buttons_b = make_tufted_vertical_panel(
        "Backrest_TuftedPanel", width=panel_w, height=panel_h, thickness=panel_d,
        loc=panel_loc, mat_leather=mats["M_Leather_Black"], mat_button=mats["M_Gold_Bright"],
        nx=3, nz=4, col_name="Chair"
    )
    back_panel.rotation_euler = (back_tilt, 0, 0)
    parent_to(back_panel, back_frame)
    chair_parts["backrest_panel"] = back_panel
    chair_parts["buttons"].extend(buttons_b)

    # Backrest inner stitch line
    make_stitch_piping("Backrest_Stitch", panel_w * 0.96, panel_h * 0.96, 0.02,
                       back_panel, mats["M_Stitch"], radius=0.0035, is_vertical=True, col_name="Chair")

    # Rear flat black inset panel
    rear_panel = make_block("Backrest_RearPanel", (0.84, 0.035, 1.20),
                            (0, back_center_y - 0.05, back_center_z - 0.02),
                            mats["M_Leather_Black"], bevel_width=0.015, col_name="Chair")
    rear_panel.rotation_euler = (back_tilt, 0, 0)
    parent_to(rear_panel, back_frame)

    # Debossed Crown + Football Emblem on the upper leather
    emblem_loc = (0, back_center_y + 0.055, back_center_z + 0.28)
    make_emblem("Emblem_CrownFootball", loc=emblem_loc, rot=(back_tilt, 0, 0), parent=back_frame,
                mat_leather=mats["M_Leather_Black"], col_name="Chair")

    # -----------------------------------------------------------------------
    # F) DIAMOND GEM & ORNATE BEZEL
    # -----------------------------------------------------------------------
    gem_z = back_center_z + (half_h * math.cos(back_tilt)) + 0.06
    gem_y = back_center_y - (half_h * math.sin(abs(back_tilt)))
    bezel_z = gem_z - 0.08
    bezel_y = gem_y

    gem_bezel = make_bezel("Gem_Bezel", width=0.32, height=0.20, loc=(0, bezel_y, bezel_z),
                           mat_gold=mats["M_Gold_Bright"], col_name="Chair")
    gem_bezel.rotation_euler = (back_tilt, 0, 0)
    parent_to(gem_bezel, back_frame)

    diamond = make_diamond("Gem_Diamond", width=0.28, height=0.22, loc=(0, gem_y, gem_z),
                           mat_diamond=mats["M_Diamond"], col_name="Chair")
    diamond.rotation_euler = (back_tilt, 0, 0)
    parent_to(diamond, back_frame)
    chair_parts["diamond"] = diamond

    # -----------------------------------------------------------------------
    # G) EFFECTS: SPARKLE FLARES & FLOATING GOLD DUST
    # -----------------------------------------------------------------------
    sparkle_coords = [
        (-0.16, gem_y + 0.08, gem_z + 0.06),
        ( 0.16, gem_y + 0.08, gem_z + 0.08),
        ( 0.00, gem_y + 0.10, gem_z + 0.16),
        (-0.52, 0.44, arm_z + 0.10),
        ( 0.52, 0.44, arm_z + 0.10),
    ]
    for i, s_loc in enumerate(sparkle_coords):
        flare = make_star_flare(f"Sparkle_Flare_{i+1:02d}", radius=0.045, loc=s_loc,
                                mat_glow=mats["M_Diamond"], col_name="Effects")
        flare.rotation_euler = (math.radians(90), 0, math.radians(i * 35))
        parent_to(flare, back_frame if i < 3 else root_empty)
        chair_parts["sparkles"].append(flare)

    # -----------------------------------------------------------------------
    # H) OPTIONAL "ROPE & CARPET" SET
    # -----------------------------------------------------------------------
    bm_carpet = bmesh.new()
    bmesh.ops.create_circle(bm_carpet, cap_ends=True, segments=48, radius=1.20)
    me_carpet = bpy.data.meshes.new("Carpet_RedCircle")
    bm_carpet.to_mesh(me_carpet)
    bm_carpet.free()
    carpet_obj = bpy.data.objects.new("Carpet_RedCircle", me_carpet)
    carpet_obj.location = (0, 0, 0.003)
    carpet_obj.data.materials.append(mats["M_Carpet_Red"])
    add_to_collection(carpet_obj, "Rope_And_Carpet")

    make_stitch_piping("Carpet_GoldRim", 2.38, 2.38, 0.004, carpet_obj, mats["M_Gold_Bright"], radius=0.012, col_name="Rope_And_Carpet")

    make_stanchion_and_rope((-0.85, 0.20, 0), (0.85, 0.20, 0),
                            mats["M_Gold_Bright"], mats["M_Velvet_Rope"],
                            col_name="Rope_And_Carpet")

    # -----------------------------------------------------------------------
    # I) ANIMATION SEQUENCING
    # -----------------------------------------------------------------------
    animate_intro_reveal(chair_parts)
    animate_idle_loop(chair_parts)
    create_sit_reaction_action(chair_parts)

    # Set viewport and timeline to Frame 120 (Assembled Idle Loop)
    bpy.context.scene.frame_current = 120
    bpy.context.scene.frame_set(120)

    # -----------------------------------------------------------------------
    # J) SCENE, LIGHTS & RENDER
    # -----------------------------------------------------------------------
    setup_lighting_and_scene()
    setup_render_and_compositor()

    # -----------------------------------------------------------------------
    # SUMMARY REPORT
    # -----------------------------------------------------------------------
    total_objects = len(bpy.data.objects)
    print("\n" + "=" * 70)
    print("BLACK DIAMOND VIP CHAIR GENERATION COMPLETE")
    print("=" * 70)
    print(f"Total Objects Generated : {total_objects}")
    print(f"Master Parent Object    : 'VIPChair' (Empty at 0,0,0)")
    print(f"Animation Timeline      : {FRAME_INTRO_START} to {FRAME_IDLE_END} frames @ {FPS} fps")
    print(f"  - Active Display Frame: 120 (Assembled & Idle Loop)")
    print(f"  - Intro Reveal        : Frames {FRAME_INTRO_START} - {FRAME_INTRO_END}")
    print(f"  - Seamless Idle Loop  : Frames {FRAME_IDLE_START} - {FRAME_IDLE_END}")
    print(f"  - Sit Reaction Action : 'Sit_Reaction' (36 frames)")
    print("\nRender Engines:")
    print("  - Cycles (Active)     : 192 samples, Denoising ON, Transmission Bounces 12")
    print("  - To switch to Eevee  : bpy.context.scene.render.engine = 'BLENDER_EEVEE_NEXT'")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    build_vip_chair_scene()

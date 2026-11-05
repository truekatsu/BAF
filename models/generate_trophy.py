# ==============================================================================
# GOLDEN FOOTBALL TROPHY ON ROCKY BASE (Blender 4.x / 5.x)
# Stylized Cartoon Game-Ready 3D Asset Generator
# ==============================================================================
import bpy
import bmesh
import math
import random
import os

# ==============================================================================
# CONFIG BLOCK (All key numbers, colors, texts, and seeds)
# ==============================================================================
CONFIG = {
    # Proportions & Geometry
    "BALL_DIAMETER": 1.0,           # Ball diameter (radius 0.5)
    "BALL_SINK_DEPTH": 0.06,        # Ball sinks into top rocks
    "ROCK_BASE_HEIGHT": 0.85,       # Total rock pile height
    "ROCK_BASE_RADIUS": 0.52,       # Bottom footprint radius (~1.0 width)
    "ROCK_COUNT_BASE": 6,           # Large bottom rocks
    "ROCK_COUNT_MID": 3,            # Medium middle rocks
    "ROCK_COUNT_TOP": 2,            # Top cradling rocks
    "PEBBLE_COUNT": 5,              # Small ground pebbles
    "SEED": 777,                    # Seed for deterministic rock placement

    # Embossed Front Text
    "TEXT_STRING": "BUILD A\nFOOTBALL\nCHARACTER",
    "TEXT_SIZE": 0.075,
    "TEXT_EXTRUDE": 0.012,
    "TEXT_BEVEL": 0.0025,

    # Colors (Hex codes matching reference concept)
    "BALL_GOLD_HEX": "#FFC400",          # Warm saturated yellow-gold
    "BALL_GOLD_HIGHLIGHT_HEX": "#FFE066", # Specular highlight tint
    "BALL_GOLD_TOP_HEX": "#FFD633",      # Gradient top tint
    "BALL_GOLD_BOT_HEX": "#F2A900",      # Gradient bottom orange-gold
    "BALL_GROOVE_HEX": "#8A5A00",        # Darker seam groove gold
    "TEXT_GOLD_HEX": "#FFD54A",          # Slightly lighter embossed gold
    "DARK_STONE_HEX": "#3A3E43",         # Main gray rock
    "DARK_STONE_MIN_HEX": "#2C2F33",     # Rock variation min
    "DARK_STONE_MAX_HEX": "#5E636A",     # Rock variation max
    "DARK_STONE_EDGE_HEX": "#7A8088",    # Rock edge highlight
    "GOLD_NUGGET_HEX": "#B8A038",        # Matte olive-gold rock
    "GOLD_NUGGET_MIN_HEX": "#8F7A22",    # Nugget dark facet
    "GOLD_NUGGET_MAX_HEX": "#E3CF6A",    # Nugget lit facet
    "OUTLINE_HEX": "#14161A",            # Near-black navy cartoon outline
    "SPARKLE_WHITE_HEX": "#FFFFFF",      # Star sparkle core
    "SPARKLE_TINT_HEX": "#FFF3A0",       # Star sparkle warm rim
    "WORLD_BG_HEX": "#B9B9BC",           # Neutral studio background

    # Outline & Effects
    "OUTLINE_THICKNESS": 0.012,
    "SPARKLE_COUNT": 10,
    "SPARKLE_SCALE_MIN": 0.025,
    "SPARKLE_SCALE_MAX": 0.065,

    # Studio Lighting (Watts / Energy)
    "KEY_LIGHT_ENERGY": 400.0,
    "FILL_LIGHT_ENERGY": 120.0,
    "RIM_LIGHT_ENERGY": 250.0,

    # Animation Loop Flag
    "ANIMATE": False,                # Set True for 48f twinkle & 240f rotation loop

    # Export Settings (Roblox)
    "EXPORT_DIR": r"D:\BAF\models",
}

# ==============================================================================
# HELPER UTILITIES
# ==============================================================================
def hex_to_rgba(hex_str: str, alpha: float = 1.0) -> tuple:
    """Converts hex color string to linear RGBA tuple for Blender color sockets."""
    h = hex_str.lstrip('#')
    rgb = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    # sRGB to linear conversion
    linear = tuple((c / 12.92) if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb)
    return linear + (alpha,)

def set_bsdf_input(bsdf, socket_names: list, value):
    """Safely sets socket value across Blender 3.x, 4.x and 5.x Principled BSDF."""
    for name in socket_names:
        if name in bsdf.inputs:
            bsdf.inputs[name].default_value = value
            return True
    return False

def clean_scene(prefix="Trophy_"):
    """Removes previously generated objects by prefix so the script is 100% re-runnable."""
    for obj in list(bpy.data.objects):
        if obj.name.startswith(prefix) or obj.name.startswith("Camera_") or obj.name.startswith("Light_") or obj.name == "ShadowCatcher":
            bpy.data.objects.remove(obj, do_unlink=True)
    for m in list(bpy.data.materials):
        if m.name.startswith("M_"):
            bpy.data.materials.remove(m, do_unlink=True)

# ==============================================================================
# 1. MATERIALS SETUP (Principled BSDF, EEVEE & Cycles friendly)
# ==============================================================================
def create_materials():
    mats = {}

    # M_Outline (Inverted Hull / Cartoon Ink)
    m_outline = bpy.data.materials.new("M_Outline")
    m_outline.use_nodes = True
    n_out = m_outline.node_tree.nodes
    n_out.clear()
    out_node = n_out.new("ShaderNodeOutputMaterial")
    geom_node = n_out.new("ShaderNodeNewGeometry")
    trans_node = n_out.new("ShaderNodeBsdfTransparent")
    emiss_node = n_out.new("ShaderNodeEmission")
    emiss_node.inputs['Color'].default_value = hex_to_rgba(CONFIG["OUTLINE_HEX"])
    emiss_node.inputs['Strength'].default_value = 1.0
    mix_node = n_out.new("ShaderNodeMixShader")
    m_outline.node_tree.links.new(geom_node.outputs['Backfacing'], mix_node.inputs['Fac'])
    m_outline.node_tree.links.new(trans_node.outputs['BSDF'], mix_node.inputs[1])
    m_outline.node_tree.links.new(emiss_node.outputs['Emission'], mix_node.inputs[2])
    m_outline.node_tree.links.new(mix_node.outputs['Shader'], out_node.inputs['Surface'])
    if hasattr(m_outline, "use_backface_culling"):
        m_outline.use_backface_culling = True
    mats["M_Outline"] = m_outline

    # M_BallGold (Glossy saturated gold with subtle Z gradient and inner glow)
    m_gold = bpy.data.materials.new("M_BallGold")
    m_gold.use_nodes = True
    nodes = m_gold.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    set_bsdf_input(bsdf, ["Base Color"], hex_to_rgba(CONFIG["BALL_GOLD_HEX"]))
    set_bsdf_input(bsdf, ["Metallic"], 1.0)
    set_bsdf_input(bsdf, ["Roughness"], 0.18)
    set_bsdf_input(bsdf, ["Specular IOR Level", "Specular"], 0.6)
    set_bsdf_input(bsdf, ["Coat Weight", "Coat"], 0.35)
    set_bsdf_input(bsdf, ["Coat Roughness"], 0.05)
    set_bsdf_input(bsdf, ["Emission Color", "Emission"], hex_to_rgba("#FFB400"))
    set_bsdf_input(bsdf, ["Emission Strength"], 0.08)
    mats["M_BallGold"] = m_gold

    # M_TextGold (Lighter embossed gold)
    m_text = bpy.data.materials.new("M_TextGold")
    m_text.use_nodes = True
    bsdf_text = m_text.node_tree.nodes.get("Principled BSDF")
    set_bsdf_input(bsdf_text, ["Base Color"], hex_to_rgba(CONFIG["TEXT_GOLD_HEX"]))
    set_bsdf_input(bsdf_text, ["Metallic"], 1.0)
    set_bsdf_input(bsdf_text, ["Roughness"], 0.12)
    set_bsdf_input(bsdf_text, ["Coat Weight", "Coat"], 0.40)
    set_bsdf_input(bsdf_text, ["Coat Roughness"], 0.04)
    mats["M_TextGold"] = m_text

    # M_DarkStone (Faceted gray rock)
    m_stone = bpy.data.materials.new("M_DarkStone")
    m_stone.use_nodes = True
    bsdf_stone = m_stone.node_tree.nodes.get("Principled BSDF")
    set_bsdf_input(bsdf_stone, ["Base Color"], hex_to_rgba(CONFIG["DARK_STONE_HEX"]))
    set_bsdf_input(bsdf_stone, ["Metallic"], 0.0)
    set_bsdf_input(bsdf_stone, ["Roughness"], 0.70)
    mats["M_DarkStone"] = m_stone

    # M_GoldNugget (Matte olive-gold faceted rock)
    m_nugget = bpy.data.materials.new("M_GoldNugget")
    m_nugget.use_nodes = True
    bsdf_nugget = m_nugget.node_tree.nodes.get("Principled BSDF")
    set_bsdf_input(bsdf_nugget, ["Base Color"], hex_to_rgba(CONFIG["GOLD_NUGGET_HEX"]))
    set_bsdf_input(bsdf_nugget, ["Metallic"], 0.85)
    set_bsdf_input(bsdf_nugget, ["Roughness"], 0.42)
    set_bsdf_input(bsdf_nugget, ["Specular IOR Level", "Specular"], 0.5)
    mats["M_GoldNugget"] = m_nugget

    # M_Sparkle (Additive White/Gold Emission)
    m_sparkle = bpy.data.materials.new("M_Sparkle")
    m_sparkle.use_nodes = True
    n_sp = m_sparkle.node_tree.nodes
    n_sp.clear()
    out_sp = n_sp.new("ShaderNodeOutputMaterial")
    em_sp = n_sp.new("ShaderNodeEmission")
    em_sp.inputs['Color'].default_value = hex_to_rgba(CONFIG["SPARKLE_TINT_HEX"])
    em_sp.inputs['Strength'].default_value = 12.0
    m_sparkle.node_tree.links.new(em_sp.outputs['Emission'], out_sp.inputs['Surface'])
    mats["M_Sparkle"] = m_sparkle

    return mats

# ==============================================================================
# 2. THE GOLDEN BALL (Truncated Icosahedron: 12 Pentagons + 20 Hexagons)
# ==============================================================================
def create_golden_ball(ball_z: float, mats: dict):
    # Step 1: Base Icosahedron (Subdivision = 1 gives 12 verts, 20 faces)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.5, location=(0, 0, ball_z))
    ball = bpy.context.active_object
    ball.name = "Trophy_Ball"

    # Step 2: Bevel all vertices by 33.333% -> creates 12 pentagons + 20 hexagons
    bev_verts = ball.modifiers.new("BevelVerts", 'BEVEL')
    bev_verts.affect = 'VERTICES'
    bev_verts.offset_type = 'PERCENT'
    bev_verts.width_pct = 33.3333
    bev_verts.segments = 1
    bpy.context.view_layer.objects.active = ball
    bpy.ops.object.modifier_apply(modifier="BevelVerts")

    # Step 3: Inset individual faces & extrude outward along normal for raised panels
    bm = bmesh.new()
    bm.from_mesh(ball.data)
    faces = list(bm.faces)
    res_inset = bmesh.ops.inset_individual(bm, faces=faces, thickness=0.035, depth=0.0)
    inset_faces = [f for f in res_inset['faces'] if f.is_valid]

    res_extrude = bmesh.ops.extrude_face_region(bm, geom=inset_faces)
    extruded_faces = [e for e in res_extrude['geom'] if isinstance(e, bmesh.types.BMFace)]
    for f in extruded_faces:
        bmesh.ops.translate(bm, vec=f.normal * 0.018, verts=f.verts)

    bm.to_mesh(ball.data)
    bm.free()

    # Step 4: Cast modifier (push slightly toward pure sphere for gentle domed panels)
    cast = ball.modifiers.new("CastSphere", 'CAST')
    cast.cast_type = 'SPHERE'
    cast.factor = 0.88

    # Step 5: Edge Bevel modifier for soft chunky panel borders
    bev_edges = ball.modifiers.new("EdgeBevel", 'BEVEL')
    bev_edges.limit_method = 'ANGLE'
    bev_edges.angle_limit = math.radians(30.0)
    bev_edges.width = 0.008
    bev_edges.segments = 2

    # Step 6: Subsurf Level 1
    sub = ball.modifiers.new("Subsurf", 'SUBSURF')
    sub.levels = 1
    sub.render_levels = 2

    for p in ball.data.polygons:
        p.use_smooth = True

    # Assign Materials
    ball.data.materials.append(mats["M_BallGold"])
    ball.data.materials.append(mats["M_Outline"])

    # Step 7: Inverted Hull Outline
    hull = ball.modifiers.new("InvertedHull", 'SOLIDIFY')
    hull.thickness = CONFIG["OUTLINE_THICKNESS"]
    hull.offset = 1.0
    hull.use_flip_normals = True
    hull.material_offset = 1
    hull.use_rim = False

    return ball

# ==============================================================================
# 3. EMBOSSED FRONT TEXT ("BUILD A FOOTBALL CHARACTER")
# ==============================================================================
def create_embossed_text(ball: bpy.types.Object, ball_z: float, mats: dict):
    curve = bpy.data.curves.new(type="FONT", name="Trophy_Text_Curve")
    curve.body = CONFIG["TEXT_STRING"]
    curve.align_x = 'CENTER'
    curve.align_y = 'CENTER'
    curve.size = CONFIG["TEXT_SIZE"]
    curve.extrude = CONFIG["TEXT_EXTRUDE"]
    curve.bevel_depth = CONFIG["TEXT_BEVEL"]
    curve.bevel_resolution = 1

    text_obj = bpy.data.objects.new("Trophy_Text", curve)
    bpy.context.collection.objects.link(text_obj)
    text_obj.rotation_euler = (math.radians(90), 0, 0)
    text_obj.location = (0, -0.495, ball_z + 0.01)

    text_obj.select_set(True)
    bpy.context.view_layer.objects.active = text_obj
    bpy.ops.object.convert(target='MESH')

    # Shrinkwrap to conform to spherical ball surface
    sw = text_obj.modifiers.new("ShrinkwrapText", 'SHRINKWRAP')
    sw.target = ball
    sw.wrap_method = 'NEAREST_SURFACEPOINT'
    sw.offset = 0.004
    bpy.ops.object.modifier_apply(modifier="ShrinkwrapText")

    text_obj.data.materials.append(mats["M_TextGold"])
    text_obj.parent = ball
    return text_obj

# ==============================================================================
# 4. THE ROCK BASE (Faceted Dark Stones & Matte Gold Nuggets)
# ==============================================================================
def create_rock_base(ball_z: float, mats: dict):
    random.seed(CONFIG["SEED"])
    rocks = []

    def make_rock(name, radius, location, is_gold: bool):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius, location=location)
        rock = bpy.context.active_object
        rock.name = name

        # Non-uniform random scale
        rock.scale = (
            random.uniform(0.85, 1.25),
            random.uniform(0.85, 1.25),
            random.uniform(0.70, 1.05)
        )
        rock.rotation_euler = (
            random.uniform(-math.pi, math.pi),
            random.uniform(-math.pi, math.pi),
            random.uniform(-math.pi, math.pi)
        )
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

        # Randomize vertices for chunky organic facets
        bm = bmesh.new()
        bm.from_mesh(rock.data)
        for v in bm.verts:
            disp = v.co.normalized() * random.uniform(-0.16 * radius, 0.22 * radius)
            v.co = v.co + disp
        bm.to_mesh(rock.data)
        bm.free()

        # Decimate for low-poly stylized facets
        dec = rock.modifiers.new("Decimate", 'DECIMATE')
        dec.ratio = 0.65

        # Bevel hard edges
        bev = rock.modifiers.new("Bevel", 'BEVEL')
        bev.width = 0.01
        bev.segments = 1

        for p in rock.data.polygons:
            p.use_smooth = False

        # Materials & Inverted Hull Outline
        mat = mats["M_GoldNugget"] if is_gold else mats["M_DarkStone"]
        rock.data.materials.append(mat)
        rock.data.materials.append(mats["M_Outline"])

        hull = rock.modifiers.new("InvertedHull", 'SOLIDIFY')
        hull.thickness = CONFIG["OUTLINE_THICKNESS"] * 0.9
        hull.offset = 1.0
        hull.use_flip_normals = True
        hull.material_offset = 1
        hull.use_rim = False

        return rock

    # Tier 1: Bottom 6 large rocks (ring at radius ~0.36, z = 0.18-0.24)
    r_bottom = CONFIG["ROCK_COUNT_BASE"]
    for i in range(r_bottom):
        ang = (2 * math.pi / r_bottom) * i + random.uniform(-0.15, 0.15)
        dist = random.uniform(0.32, 0.40)
        x = math.cos(ang) * dist
        y = math.sin(ang) * dist
        z = random.uniform(0.18, 0.24)
        is_gold = (i % 2 == 0)
        rocks.append(make_rock(f"Trophy_Rock_Base_{i+1}", random.uniform(0.24, 0.30), (x, y, z), is_gold))

    # Tier 2: Middle 3 medium rocks (radius ~0.24, z = 0.46-0.54)
    r_mid = CONFIG["ROCK_COUNT_MID"]
    for i in range(r_mid):
        ang = (2 * math.pi / r_mid) * i + 0.5 + random.uniform(-0.15, 0.15)
        dist = random.uniform(0.18, 0.26)
        x = math.cos(ang) * dist
        y = math.sin(ang) * dist
        z = random.uniform(0.46, 0.54)
        is_gold = (i % 2 == 1)
        rocks.append(make_rock(f"Trophy_Rock_Mid_{i+1}", random.uniform(0.19, 0.24), (x, y, z), is_gold))

    # Tier 3: Top 2-3 rocks cradling ball bottom (z = 0.72-0.80)
    r_top = CONFIG["ROCK_COUNT_TOP"]
    for i in range(r_top):
        ang = (2 * math.pi / r_top) * i + 1.2
        dist = random.uniform(0.12, 0.18)
        x = math.cos(ang) * dist
        y = math.sin(ang) * dist
        z = random.uniform(0.72, 0.78)
        is_gold = (i == 0)
        rocks.append(make_rock(f"Trophy_Rock_Top_{i+1}", random.uniform(0.15, 0.19), (x, y, z), is_gold))

    # Small scattered pebbles around ground (z = 0.03-0.06)
    p_count = CONFIG["PEBBLE_COUNT"]
    for i in range(p_count):
        ang = (2 * math.pi / p_count) * i + random.uniform(-0.25, 0.25)
        dist = random.uniform(0.48, 0.60)
        x = math.cos(ang) * dist
        y = math.sin(ang) * dist
        z = random.uniform(0.03, 0.06)
        is_gold = (i % 2 == 0)
        rocks.append(make_rock(f"Trophy_Pebble_{i+1}", random.uniform(0.045, 0.075), (x, y, z), is_gold))

    return rocks

# ==============================================================================
# 5. SPARKLE & SHINE EFFECTS (4-Point Star Meshes)
# ==============================================================================
def create_sparkles(ball_z: float, mats: dict, target_cam: bpy.types.Object):
    random.seed(CONFIG["SEED"] + 42)
    mesh = bpy.data.meshes.new("Trophy_Sparkle_Mesh")
    bm = bmesh.new()
    center_v = bm.verts.new((0, 0, 0))
    R, r = 1.0, 0.22
    outer_pts = [(0, R), (R, 0), (0, -R), (-R, 0)]
    inner_pts = [(r, r), (r, -r), (-r, -r), (-r, r)]
    verts = []
    for i in range(4):
        verts.append(bm.verts.new((outer_pts[i][0], outer_pts[i][1], 0)))
        verts.append(bm.verts.new((inner_pts[i][0], inner_pts[i][1], 0)))
    for i in range(8):
        bm.faces.new([center_v, verts[i], verts[(i+1)%8]])
    bm.to_mesh(mesh)
    bm.free()

    sparkles = []
    ball_r = CONFIG["BALL_DIAMETER"] * 0.5

    # Preset positions on front upper-hemisphere
    offsets = [
        (-0.28, -0.38, 0.24, 0.065),  # Large primary highlight top-left
        (-0.35, -0.28, 0.16, 0.045),  # Secondary top-left
        (-0.16, -0.44, 0.28, 0.038),  # Accent upper
        (0.26, -0.36, 0.18, 0.032),   # Right mid accent
        (0.34, -0.26, 0.08, 0.025),   # Lower right small
        (-0.08, -0.46, 0.12, 0.035),  # Front center accent
        (0.12, -0.42, 0.22, 0.028),   # Front right accent
        (-0.24, -0.32, 0.34, 0.040),  # High crest sparkle
    ]

    for idx, (ox, oy, oz, s) in enumerate(offsets):
        sp_obj = bpy.data.objects.new(f"Trophy_Sparkle_{idx+1}", mesh)
        bpy.context.collection.objects.link(sp_obj)
        # Project onto ball surface with slight offset
        v = math.sqrt(ox*ox + oy*oy + oz*oz)
        scale_fac = (ball_r + 0.025) / v
        sp_obj.location = (ox * scale_fac, oy * scale_fac, ball_z + oz * scale_fac)
        sp_obj.scale = (s, s, s)

        # Billboard Track To camera
        if target_cam:
            tt = sp_obj.constraints.new(type='TRACK_TO')
            tt.target = target_cam
            tt.track_axis = 'TRACK_Z'
            tt.up_axis = 'UP_Y'

        sp_obj.data.materials.append(mats["M_Sparkle"])
        sparkles.append(sp_obj)

    return sparkles

# ==============================================================================
# 6. STUDIO ENVIRONMENT (3-Point Lighting, Shadow Catcher, 4 Cameras)
# ==============================================================================
def create_studio_setup(ball_z: float):
    # World setup
    world = bpy.context.scene.world or bpy.data.worlds.new("TrophyWorld")
    world.use_nodes = True
    bg_node = world.node_tree.nodes.get("Background")
    if bg_node:
        bg_node.inputs['Color'].default_value = hex_to_rgba(CONFIG["WORLD_BG_HEX"])
        bg_node.inputs['Strength'].default_value = 0.85
    bpy.context.scene.world = world

    # Render settings: EEVEE Next / Cycles compatibility
    scene = bpy.context.scene
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.film_transparent = True
    scene.view_settings.view_transform = 'AgX' if 'AgX' in [c.name for c in bpy.types.ColorManagedViewSettings.bl_rna.properties['view_transform'].enum_items] else 'Filmic'
    scene.view_settings.look = 'Medium High Contrast'

    # Shadow Catcher Plane
    bpy.ops.mesh.primitive_plane_add(size=4.0, location=(0, 0, 0.001))
    catcher = bpy.context.active_object
    catcher.name = "ShadowCatcher"
    catcher.is_shadow_catcher = True

    # 3-Point Studio Lights
    def make_light(name, light_type, power, color_hex, pos, rot):
        l_data = bpy.data.lights.new(name, light_type)
        l_data.energy = power
        l_data.color = hex_to_rgba(color_hex)[:3]
        if light_type == 'AREA':
            l_data.size = 1.4
        l_obj = bpy.data.objects.new(name, l_data)
        bpy.context.collection.objects.link(l_obj)
        l_obj.location = pos
        l_obj.rotation_euler = rot
        return l_obj

    # Key light top-left (warm)
    make_light("Light_Key_Warm", 'AREA', CONFIG["KEY_LIGHT_ENERGY"], "#FFF4DC", (-1.5, -2.5, 3.0), (math.radians(45), math.radians(-15), math.radians(-30)))
    # Fill light right (cool)
    make_light("Light_Fill_Cool", 'AREA', CONFIG["FILL_LIGHT_ENERGY"], "#DDE8FF", (2.2, -1.8, 1.6), (math.radians(50), math.radians(20), math.radians(45)))
    # Rim light behind (crisp edge)
    make_light("Light_Rim_White", 'AREA', CONFIG["RIM_LIGHT_ENERGY"], "#FFFFFF", (0.0, 2.5, 2.4), (math.radians(-45), 0, math.radians(180)))

    # 4 Turntable Cameras (Target at trophy center Z = 0.95)
    target_z = 0.95
    cams = {}
    cam_specs = [
        ("Camera_Front", (0.0, -3.2, 1.15), (math.radians(86), 0, 0)),
        ("Camera_Side", (3.2, 0.0, 1.15), (math.radians(86), 0, math.radians(90))),
        ("Camera_Back", (0.0, 3.2, 1.15), (math.radians(94), 0, math.radians(180))),
        ("Camera_ThreeQuarter", (2.2, -2.2, 1.6), (math.radians(68), 0, math.radians(45))),
    ]

    for cname, cpos, crot in cam_specs:
        cdata = bpy.data.cameras.new(cname)
        cdata.lens = 50.0
        cobj = bpy.data.objects.new(cname, cdata)
        bpy.context.collection.objects.link(cobj)
        cobj.location = cpos
        cobj.rotation_euler = crot
        cams[cname] = cobj

    # Default active camera is Front
    scene.camera = cams["Camera_Front"]
    return cams

# ==============================================================================
# 7. OPTIONAL ANIMATION LOOP (Sparkle Twinkle & Ball 360 Rotation)
# ==============================================================================
def setup_animation(ball: bpy.types.Object, sparkles: list):
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 240

    # Ball 360 Rotation (240 frames seamless loop)
    ball.animation_data_clear()
    ball.rotation_mode = 'XYZ'
    ball.rotation_euler = (0, 0, 0)
    ball.keyframe_insert(data_path="rotation_euler", frame=1)
    ball.rotation_euler = (0, 0, math.radians(360))
    ball.keyframe_insert(data_path="rotation_euler", frame=241)
    if ball.animation_data and ball.animation_data.action:
        for fcurve in ball.animation_data.action.fcurves:
            for kf in fcurve.keyframe_points:
                kf.interpolation = 'LINEAR'

    # Sparkle Twinkle (Scale pulse 48 frame loop)
    for idx, sp in enumerate(sparkles):
        sp.animation_data_clear()
        base_s = sp.scale.x
        offset_f = (idx * 6) % 48
        for f in [1, 24, 48, 72, 96, 120, 144, 168, 192, 216, 240]:
            target_f = f + offset_f
            if target_f <= 240:
                mult = 1.3 if (f // 24) % 2 == 1 else 0.4
                sp.scale = (base_s * mult, base_s * mult, base_s * mult)
                sp.keyframe_insert(data_path="scale", frame=target_f)

# ==============================================================================
# 8. GAME-READY EXPORT & STATISTICS (Roblox)
# ==============================================================================
def prepare_roblox_export(ball: bpy.types.Object, rocks: list):
    # Print Triangle Statistics
    total_tris = 0
    ball_tris = sum(len(p.vertices) - 2 for p in ball.data.polygons)
    rock_tris = sum(sum(len(p.vertices) - 2 for p in r.data.polygons) for r in rocks)
    total_tris = ball_tris + rock_tris

    print("=" * 60)
    print("ROBLOX GAME-READY MODEL STATISTICS:")
    print(f"- Trophy_Ball Triangles: {ball_tris:,}")
    print(f"- Trophy_Base Triangles: {rock_tris:,}")
    print(f"- Total Trophy Triangles: {total_tris:,} (Target < 10,000)")
    print("=" * 60)

    # Export paths
    out_dir = CONFIG["EXPORT_DIR"]
    if not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    ball_path = os.path.join(out_dir, "Trophy_Ball.fbx")
    base_path = os.path.join(out_dir, "Trophy_Base.fbx")

    # Export Ball
    bpy.ops.object.select_all(action='DESELECT')
    ball.select_set(True)
    bpy.context.view_layer.objects.active = ball
    try:
        bpy.ops.export_scene.fbx(
            filepath=ball_path,
            use_selection=True,
            apply_unit_scale=True,
            mesh_smooth_type='FACE',
            bake_space_transform=True,
        )
        print(f"Exported: {ball_path}")
    except Exception as e:
        print(f"FBX Export note: {e}")

    # Join and Export Base
    bpy.ops.object.select_all(action='DESELECT')
    for r in rocks:
        r.select_set(True)
    if rocks:
        bpy.context.view_layer.objects.active = rocks[0]
        try:
            bpy.ops.export_scene.fbx(
                filepath=base_path,
                use_selection=True,
                apply_unit_scale=True,
                mesh_smooth_type='FACE',
                bake_space_transform=True,
            )
            print(f"Exported: {base_path}")
        except Exception as e:
            print(f"FBX Export note: {e}")

# ==============================================================================
# MAIN BUILD PIPELINE
# ==============================================================================
def main():
    print("[Trophy Builder] Starting build pipeline...")
    clean_scene("Trophy_")

    # Calculate Ball center Z so it rests naturally embedded on the rock pile
    ball_z = CONFIG["ROCK_BASE_HEIGHT"] - CONFIG["BALL_SINK_DEPTH"] + (CONFIG["BALL_DIAMETER"] * 0.5)

    mats = create_materials()
    cams = create_studio_setup(ball_z)
    ball = create_golden_ball(ball_z, mats)
    text = create_embossed_text(ball, ball_z, mats)
    rocks = create_rock_base(ball_z, mats)
    sparkles = create_sparkles(ball_z, mats, cams["Camera_Front"])

    if CONFIG["ANIMATE"]:
        setup_animation(ball, sparkles)

    prepare_roblox_export(ball, rocks)
    print("[Trophy Builder] Build pipeline completed successfully!")

if __name__ == "__main__":
    main()

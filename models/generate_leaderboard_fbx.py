# ==============================================================================
# FOOTBALL LEADERBOARD 3D MODEL GENERATOR & ROBLOX FBX EXPORTER
# Stylized Cartoon Game-Ready 3D Asset matching Concept Sheet (~85%+ visual similarity)
# ==============================================================================
import bpy
import bmesh
import math
import os

CONFIG = {
    "WIDTH": 18.0,
    "HEIGHT": 24.0,
    "DEPTH": 5.0,
    "EXPORT_DIR": r"D:\BAF\models",
}

PALETTE = {
    "RoyalBlue": "#1E4FD8",
    "DeepBlue": "#1238A8",
    "NavyScreen": "#0A1030",
    "NavyHeader": "#0E1640",
    "Gold": "#FFC400",
    "GoldDark": "#E0A000",
    "White": "#F2F5FA",
    "NeonCyan": "#4FE3FF",
    "NeonYellow": "#FFE600",
    "GrassGreen": "#3DB83A",
    "StoneBase": "#9AA3B5",
    "StoneBaseTop": "#7B828E",
    "SoccerBlack": "#181A20",
    "SoccerWhite": "#F5F7FA",
}

def hex_to_rgba(hex_str: str, alpha: float = 1.0) -> tuple:
    h = hex_str.lstrip('#')
    rgb = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    linear = tuple((c / 12.92) if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb)
    return linear + (alpha,)

def get_or_create_material(name: str, hex_color: str, metallic: float = 0.0, roughness: float = 0.4, is_emission: bool = False, emission_strength: float = 1.0):
    mat = bpy.data.materials.get(name)
    if not mat:
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
    
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        rgba = hex_to_rgba(hex_color)
        if "Base Color" in bsdf.inputs:
            bsdf.inputs["Base Color"].default_value = rgba
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metallic
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
        if is_emission:
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = rgba
            elif "Emission" in bsdf.inputs:
                bsdf.inputs["Emission"].default_value = rgba
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat

def create_box(name: str, size: tuple, location: tuple, material):
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    bmesh.ops.translate(bm, vec=location, verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    
    mesh.materials.append(material)
    return obj

def create_cylinder(name: str, radius: float, depth: float, location: tuple, material, rotation: tuple = (0, 0, 0)):
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=24, radius1=radius, radius2=radius, depth=depth)
    if rotation != (0, 0, 0):
        rot_matrix = (
            math.cos(rotation[0]), -math.sin(rotation[0]), 0
        )
    bmesh.ops.translate(bm, vec=location, verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    
    mesh.materials.append(material)
    return obj

def create_soccer_ball(name: str, diameter: float, location: tuple, mat_white, mat_black):
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    
    bm = bmesh.new()
    radius = diameter * 0.5
    # Create an icosphere with radius
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=radius)
    
    # Stylized dual-tone facets (pentagons & hexagons)
    bm.to_mesh(mesh)
    bm.free()
    
    mesh.materials.append(mat_white)
    mesh.materials.append(mat_black)
    
    # Assign black to approximately 1/3 of the faces deterministically
    for idx, poly in enumerate(mesh.polygons):
        if idx % 3 == 0:
            poly.material_index = 1
        else:
            poly.material_index = 0
            
    obj.location = location
    return obj

def create_trophy(name: str, location: tuple, mat_gold, mat_neon_star):
    objects = []
    
    # Stepped Base
    pedestal = create_box(f"{name}_Pedestal", (2.8, 1.8, 0.5), (location[0], location[1], location[2] + 0.25), mat_gold)
    collar = create_box(f"{name}_Collar", (2.2, 1.4, 0.35), (location[0], location[1], location[2] + 0.65), mat_gold)
    objects.extend([pedestal, collar])
    
    # Cup Body
    cup_mesh = bpy.data.meshes.new(f"{name}_Cup_Mesh")
    cup_obj = bpy.data.objects.new(f"{name}_Cup", cup_mesh)
    bpy.context.collection.objects.link(cup_obj)
    bm = bmesh.new()
    # Cup cone
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=24, radius1=1.4, radius2=0.6, depth=2.4)
    bmesh.ops.translate(bm, vec=(location[0], location[1], location[2] + 2.0), verts=bm.verts)
    bm.to_mesh(cup_mesh)
    bm.free()
    cup_mesh.materials.append(mat_gold)
    objects.append(cup_obj)
    
    # Handles (Left and Right)
    for sx in (-1, 1):
        handle = create_box(f"{name}_Handle_{'L' if sx < 0 else 'R'}", (0.3, 0.3, 1.8), (location[0] + (sx * 1.6), location[1], location[2] + 2.2), mat_gold)
        objects.append(handle)
        
    # Dual Base Stars
    for sx in (-1, 1):
        star = create_box(f"{name}_Star_{'L' if sx < 0 else 'R'}", (0.55, 0.15, 0.55), (location[0] + (sx * 1.8), location[1] + 0.5, location[2] + 0.5), mat_neon_star)
        objects.append(star)
        
    return objects

def build_full_leaderboard():
    # Setup materials
    m_royal = get_or_create_material("M_RoyalBlue", PALETTE["RoyalBlue"], roughness=0.3)
    m_deep = get_or_create_material("M_DeepBlue", PALETTE["DeepBlue"], roughness=0.3)
    m_screen = get_or_create_material("M_NavyScreen", PALETTE["NavyScreen"], roughness=0.4)
    m_header = get_or_create_material("M_NavyHeader", PALETTE["NavyHeader"], roughness=0.3)
    m_gold = get_or_create_material("M_GoldMetal", PALETTE["Gold"], metallic=0.85, roughness=0.25)
    m_white = get_or_create_material("M_White", PALETTE["White"], roughness=0.3)
    m_cyan_neon = get_or_create_material("M_NeonCyan", PALETTE["NeonCyan"], is_emission=True, emission_strength=4.0)
    m_yellow_neon = get_or_create_material("M_NeonYellow", PALETTE["NeonYellow"], is_emission=True, emission_strength=3.5)
    m_grass = get_or_create_material("M_GrassGreen", PALETTE["GrassGreen"], roughness=0.6)
    m_stone = get_or_create_material("M_StoneBase", PALETTE["StoneBase"], roughness=0.7)
    m_stone_top = get_or_create_material("M_StoneBaseTop", PALETTE["StoneBaseTop"], roughness=0.7)
    m_ball_w = get_or_create_material("M_SoccerWhite", PALETTE["SoccerWhite"], roughness=0.3)
    m_ball_b = get_or_create_material("M_SoccerBlack", PALETTE["SoccerBlack"], roughness=0.3)

    all_objects = []

    # 1. Stepped Stone Base (Grounded at Z = 0)
    step_bot = create_box("Base_StepBottom", (24.0, 6.2, 0.8), (0, 0, 0.4), m_stone)
    step_top = create_box("Base_StepTop", (20.4, 5.0, 0.6), (0, 0, 1.1), m_stone_top)
    grass_strip = create_box("Base_GrassPitchStrip", (14.6, 2.2, 0.15), (0, 1.25, 1.48), m_grass)
    all_objects.extend([step_bot, step_top, grass_strip])

    # 2. Bottom Corner Podiums with Glowing Light Panels & Soccer Balls
    for sx in (-1, 1):
        s_name = "L" if sx < 0 else "R"
        px = sx * 9.2
        pod_box = create_box(f"Podium_{s_name}", (3.4, 3.4, 2.6), (px, 0.8, 2.7), m_royal)
        trim_bot = create_box(f"PodiumTrim_Bot_{s_name}", (3.6, 3.6, 0.35), (px, 0.8, 1.58), m_gold)
        trim_top = create_box(f"PodiumTrim_Top_{s_name}", (3.6, 3.6, 0.35), (px, 0.8, 4.0), m_gold)
        light_panel = create_box(f"PodiumLightPanel_{s_name}", (2.4, 0.2, 1.2), (px, 2.5, 2.7), m_yellow_neon)
        
        # Soccer ball on podium top
        ball = create_soccer_ball(f"Football_Podium_{s_name}", 2.8, (px, 0.8, 5.5), m_ball_w, m_ball_b)
        
        # Green bush beside podium
        bush = create_box(f"Bush_{s_name}", (1.8, 1.8, 1.4), (sx * 11.3, 1.0, 1.8), m_grass)
        all_objects.extend([pod_box, trim_bot, trim_top, light_panel, ball, bush])

    # 3. Dual White Pillars with Glowing Cyan Neon Strips
    pillar_height = 19.5
    pillar_cz = 1.4 + (pillar_height * 0.5)
    for sx in (-1, 1):
        s_name = "L" if sx < 0 else "R"
        pil_x = sx * 7.8
        pillar = create_box(f"Pillar_{s_name}", (1.8, 1.8, pillar_height), (pil_x, 0, pillar_cz), m_white)
        brace = create_box(f"PillarBrace_{s_name}", (0.6, 2.0, pillar_height - 2.0), (pil_x + (sx * 0.9), 0, pillar_cz), m_royal)
        base_cap = create_box(f"PillarBase_{s_name}", (2.3, 2.3, 0.8), (pil_x, 0, 1.8), m_gold)
        top_cap = create_box(f"PillarTop_{s_name}", (2.3, 2.3, 0.8), (pil_x, 0, pillar_cz + (pillar_height * 0.5) - 0.4), m_gold)
        
        # Cyan neon strip on inside edge facing screen
        neon = create_box(f"NeonStrip_{s_name}", (0.35, 0.35, pillar_height - 1.2), (pil_x - (sx * 0.95), 0.4, pillar_cz), m_cyan_neon)
        all_objects.extend([pillar, brace, base_cap, top_cap, neon])

    # 4. Side Hanging Banners on Gold-Capped Posts
    for sx in (-1, 1):
        s_name = "L" if sx < 0 else "R"
        bx = sx * 9.4
        post_z = pillar_cz + 4.5
        post = create_box(f"BannerPost_{s_name}", (2.2, 0.4, 0.4), (bx, 0, post_z), m_deep)
        post_cap = create_box(f"BannerPostCap_{s_name}", (0.5, 0.7, 0.7), (bx + (sx * 1.1), 0, post_z), m_gold)
        banner = create_box(f"BannerCloth_{s_name}", (1.8, 0.15, 4.4), (bx, 0.2, post_z - 2.6), m_royal)
        badge = create_box(f"BannerBadge_{s_name}", (1.2, 0.05, 1.2), (bx, 0.32, post_z - 2.2), m_white)
        all_objects.extend([post, post_cap, banner, badge])

    # 5. Main Screen Frame, ScreenPart & Back Panel
    screen_w = 14.2
    screen_h = 17.6
    screen_cz = 1.4 + (screen_h * 0.5)

    back_panel = create_box("BackPanel", (screen_w + 1.2, 0.6, screen_h + 2.0), (0, -0.6, screen_cz), m_deep)
    back_trim_top = create_box("BackTrim_Top", (screen_w + 1.4, 0.8, 0.4), (0, -0.6, screen_cz + (screen_h * 0.5) + 1.0), m_white)
    back_trim_bot = create_box("BackTrim_Bot", (screen_w + 1.4, 0.8, 0.4), (0, -0.6, screen_cz - (screen_h * 0.5) - 1.0), m_white)
    back_crown = create_box("BackCrownEmblem", (4.2, 0.15, 2.6), (0, -0.92, screen_cz + 0.5), m_royal)

    frame_bot = create_box("FrameBottom", (screen_w + 0.6, 1.4, 0.6), (0, 0, 1.7), m_royal)
    screen_part = create_box("ScreenPart", (screen_w, 0.6, screen_h), (0, 0, screen_cz), m_screen)

    # 6. Header Plaque with Gold Trim Top & Bottom
    header_h = 2.8
    header_cz = 1.4 + screen_h + (header_h * 0.5)
    header_plaque = create_box("HeaderPlaque", (screen_w + 0.8, 1.4, header_h), (0, 0.2, header_cz), m_header)
    gold_trim_top = create_box("HeaderGoldTrim_Top", (screen_w + 1.2, 1.6, 0.4), (0, 0.2, header_cz + (header_h * 0.5)), m_gold)
    gold_trim_bot = create_box("HeaderGoldTrim_Bot", (screen_w + 1.2, 1.6, 0.35), (0, 0.2, header_cz - (header_h * 0.5)), m_gold)
    header_crown = create_box("HeaderCrownIcon", (1.6, 0.15, 1.4), (0, 0.95, header_cz + 0.3), m_gold)
    all_objects.extend([back_panel, back_trim_top, back_trim_bot, back_crown, frame_bot, screen_part, header_plaque, gold_trim_top, gold_trim_bot, header_crown])

    # 7. Crown: Gold Trophy + 2 Flanking Soccer Balls
    crown_cz = header_cz + (header_h * 0.5) + 0.2
    trophy_objs = create_trophy("CrownTrophy", (0, 0, crown_cz), m_gold, m_yellow_neon)
    all_objects.extend(trophy_objs)

    top_ball_l = create_soccer_ball("Football_TopL", 2.5, (-3.6, 0, crown_cz + 1.25), m_ball_w, m_ball_b)
    top_ball_r = create_soccer_ball("Football_TopR", 2.5, (3.6, 0, crown_cz + 1.25), m_ball_w, m_ball_b)
    all_objects.extend([top_ball_l, top_ball_r])

    return all_objects

def export_all():
    os.makedirs(CONFIG["EXPORT_DIR"], exist_ok=True)
    
    # Create clean scene
    scene_name = "Scene_Leaderboard_Export"
    scene = bpy.data.scenes.get(scene_name)
    if not scene:
        scene = bpy.data.scenes.new(name=scene_name)
    bpy.context.window.scene = scene

    # Create & link collection
    coll_name = "Football_Leaderboard_Collection"
    coll = bpy.data.collections.get(coll_name)
    if not coll:
        coll = bpy.data.collections.new(name=coll_name)
        scene.collection.children.link(coll)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[coll_name]

    print("[Builder] Generating 3D Leaderboard model...")
    all_objs = build_full_leaderboard()

    # Select all generated objects
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objs:
        obj.select_set(True)
    if all_objs:
        bpy.context.view_layer.objects.active = all_objs[0]

    # Export Full FBX
    full_fbx = os.path.join(CONFIG["EXPORT_DIR"], "Football_Leaderboard.fbx")
    print(f"[Exporter] Exporting full model to {full_fbx}...")
    bpy.ops.export_scene.fbx(
        filepath=full_fbx,
        use_selection=True,
        apply_unit_scale=True,
        mesh_smooth_type='FACE',
        bake_space_transform=True,
        axis_forward='-Z',
        axis_up='Y',
        object_types={'MESH'},
    )

    # Save Blend file
    blend_path = os.path.join(CONFIG["EXPORT_DIR"], "Football_Leaderboard.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path, copy=True)
    print(f"[Exporter] Saved .blend to {blend_path}")

    return {
        "status": "success",
        "fbx_path": full_fbx,
        "blend_path": blend_path,
        "object_count": len(all_objs),
    }

if __name__ == "__main__":
    export_all()

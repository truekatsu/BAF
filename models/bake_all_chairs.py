"""
bake_all_chairs.py
Bakes complete PBR textures (BaseColor, Normal, Roughness, Metallic) at 2048x2048 for all 5 chairs:
1. Stadium_Chair
2. CyberCoreChair
3. CrimsonFlameChair
4. FrostbiteIceThrone
5. RoyalFootballThrone

Outputs:
- Textures: d:\BAF\models\textures\[ChairName]\
    - [ChairName]_BaseColor.png
    - [ChairName]_Normal.png
    - [ChairName]_Roughness.png
    - [ChairName]_Metallic.png
- Game-ready single-mesh FBX: d:\BAF\models\roblox_models\[ChairName]_Baked.fbx
"""

import bpy
import os
import sys

BASE_DIR = r"D:\BAF\models"
TEXTURES_DIR = os.path.join(BASE_DIR, "textures")
ROBLOX_MODELS_DIR = os.path.join(BASE_DIR, "roblox_models")
os.makedirs(TEXTURES_DIR, exist_ok=True)
os.makedirs(ROBLOX_MODELS_DIR, exist_ok=True)

CHAIR_CONFIGS = [
    {
        "blend": os.path.join(BASE_DIR, "Stadium_Chair.blend"),
        "name": "Stadium_Chair",
    },
    {
        "blend": os.path.join(BASE_DIR, "CyberCoreChair.blend"),
        "name": "CyberCoreChair",
    },
    {
        "blend": os.path.join(BASE_DIR, "CrimsonFlameChair.blend"),
        "name": "CrimsonFlameChair",
    },
    {
        "blend": os.path.join(BASE_DIR, "FrostbiteIceThrone.blend"),
        "name": "FrostbiteIceThrone",
    },
    {
        "blend": os.path.join(BASE_DIR, "RoyalFootballThrone.blend"),
        "name": "RoyalFootballThrone",
    },
]

EXCLUDE_KEYWORDS = [
    'preview_ground', 'floor_plane', 'mist_volume', 'snowflakes_sparkles',
    'sparkles_glints', 'embers_floating', 'hologram_data_voxels', 'hologram_floor_ring'
]

RESOLUTION = 2048

def setup_cycles_engine():
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 2
    scene.render.bake.margin = 8
    scene.render.bake.margin_type = 'EXTEND'
    return scene

def bake_chair(cfg):
    blend_file = cfg["blend"]
    chair_name = cfg["name"]
    print("\n" + "=" * 70)
    print(f"PROCESSING: {chair_name} ({blend_file})")
    print("=" * 70)

    if not os.path.exists(blend_file):
        print(f"ERROR: File {blend_file} does not exist!")
        return False

    bpy.ops.wm.open_mainfile(filepath=blend_file)
    scene = setup_cycles_engine()

    chair_dir = os.path.join(TEXTURES_DIR, chair_name)
    os.makedirs(chair_dir, exist_ok=True)

    # 1. Identify valid chair meshes
    chair_meshes = [
        o for o in bpy.data.objects
        if o.type == 'MESH' and not any(k in o.name.lower() for k in EXCLUDE_KEYWORDS)
    ]
    print(f"Found {len(chair_meshes)} chair mesh objects.")

    if not chair_meshes:
        print("ERROR: No valid chair meshes found!")
        return False

    # 2. Duplicate meshes for baking
    bpy.ops.object.select_all(action='DESELECT')
    for m in chair_meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = chair_meshes[0]
    bpy.ops.object.duplicate()
    dup_meshes = [o for o in bpy.context.selected_objects if o.type == 'MESH']

    # 3. Strip any inverted hull Outline solidify modifiers
    for o in dup_meshes:
        for mod in list(o.modifiers):
            if 'outline' in mod.name.lower() or (mod.type == 'SOLIDIFY' and getattr(mod, 'use_flip_normals', False)):
                o.modifiers.remove(mod)

    # 4. Convert to MESH (applies bevels, subdivisions, etc.)
    bpy.ops.object.convert(target='MESH')

    # 5. Join into a single unified object
    bpy.context.view_layer.objects.active = dup_meshes[0]
    bpy.ops.object.join()
    baked_obj = bpy.context.view_layer.objects.active
    baked_obj.name = f"{chair_name}_Baked"

    # 6. Apply transforms and unwrap
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    
    # Ensure origin at floor center
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    min_z = min(v.co.z for v in baked_obj.data.vertices)
    for v in baked_obj.data.vertices:
        v.co.z -= min_z
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Smart UV Project with margin
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.015)
    bpy.ops.object.mode_set(mode='OBJECT')

    print(f"Unified mesh: {len(baked_obj.data.vertices)} vertices, {len(baked_obj.data.polygons)} polygons.")

    # 7. Helper to set up texture image node on all materials
    def prepare_image(name):
        img = bpy.data.images.new(name, width=RESOLUTION, height=RESOLUTION, alpha=True)
        img.colorspace_settings.name = 'sRGB' if 'BaseColor' in name else 'Non-Color'
        for slot in baked_obj.material_slots:
            mat = slot.material
            if not mat or not mat.node_tree:
                continue
            nt = mat.node_tree
            t_node = nt.nodes.get("__bake_tex__")
            if not t_node:
                t_node = nt.nodes.new('ShaderNodeTexImage')
                t_node.name = "__bake_tex__"
            t_node.image = img
            nt.nodes.active = t_node
            t_node.select = True
        return img

    def save_image(img, filepath):
        img.filepath_raw = filepath
        img.file_format = 'PNG'
        img.save()
        print(f"  [SAVED] {os.path.basename(filepath)} ({os.path.getsize(filepath):,} bytes)")

    # ----------------------------------------------------
    # PASS 1: BaseColor (Albedo)
    # ----------------------------------------------------
    print("Baking BaseColor (Albedo)...")
    img_bc = prepare_image(f"{chair_name}_BaseColor")
    for slot in baked_obj.material_slots:
        mat = slot.material
        if not mat or not mat.node_tree: continue
        nt = mat.node_tree
        out_node = next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output), None)
        if not out_node: continue
        
        e_node = nt.nodes.get("__bake_emit__")
        if not e_node:
            e_node = nt.nodes.new('ShaderNodeEmission')
            e_node.name = "__bake_emit__"
        e_node.inputs['Strength'].default_value = 1.0

        p = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        em = next((n for n in nt.nodes if n.type == 'EMISSION' and n != e_node), None)
        if p:
            bc = p.inputs.get('Base Color')
            if bc and bc.is_linked:
                nt.links.new(bc.links[0].from_socket, e_node.inputs['Color'])
            elif bc:
                emi_col = p.inputs.get('Emission Color')
                if max(bc.default_value[:3]) < 0.01 and emi_col and max(emi_col.default_value[:3]) > 0.01:
                    e_node.inputs['Color'].default_value = emi_col.default_value
                else:
                    e_node.inputs['Color'].default_value = bc.default_value
        elif em:
            col = em.inputs.get('Color')
            if col and col.is_linked:
                nt.links.new(col.links[0].from_socket, e_node.inputs['Color'])
            elif col:
                e_node.inputs['Color'].default_value = col.default_value
        nt.links.new(e_node.outputs['Emission'], out_node.inputs['Surface'])

    scene.cycles.bake_type = 'EMIT'
    bpy.ops.object.bake(type='EMIT')
    bc_path = os.path.join(chair_dir, f"{chair_name}_BaseColor.png")
    save_image(img_bc, bc_path)

    # ----------------------------------------------------
    # PASS 2: Metallic
    # ----------------------------------------------------
    print("Baking Metallic...")
    img_met = prepare_image(f"{chair_name}_Metallic")
    for slot in baked_obj.material_slots:
        mat = slot.material
        if not mat or not mat.node_tree: continue
        nt = mat.node_tree
        e_node = nt.nodes.get("__bake_emit__")
        for l in list(e_node.inputs['Color'].links):
            nt.links.remove(l)
        p = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        val = 0.0
        if p:
            m_inp = p.inputs.get('Metallic')
            if m_inp and m_inp.is_linked:
                nt.links.new(m_inp.links[0].from_socket, e_node.inputs['Color'])
            elif m_inp:
                val = float(m_inp.default_value)
                e_node.inputs['Color'].default_value = (val, val, val, 1.0)
        else:
            e_node.inputs['Color'].default_value = (0.0, 0.0, 0.0, 1.0)

    scene.cycles.bake_type = 'EMIT'
    bpy.ops.object.bake(type='EMIT')
    met_path = os.path.join(chair_dir, f"{chair_name}_Metallic.png")
    save_image(img_met, met_path)

    # ----------------------------------------------------
    # PASS 3: Roughness
    # ----------------------------------------------------
    print("Baking Roughness...")
    img_rou = prepare_image(f"{chair_name}_Roughness")
    for slot in baked_obj.material_slots:
        mat = slot.material
        if not mat or not mat.node_tree: continue
        nt = mat.node_tree
        e_node = nt.nodes.get("__bake_emit__")
        for l in list(e_node.inputs['Color'].links):
            nt.links.remove(l)
        p = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        val = 0.5
        if p:
            r_inp = p.inputs.get('Roughness')
            if r_inp and r_inp.is_linked:
                nt.links.new(r_inp.links[0].from_socket, e_node.inputs['Color'])
            elif r_inp:
                val = float(r_inp.default_value)
                e_node.inputs['Color'].default_value = (val, val, val, 1.0)
        else:
            e_node.inputs['Color'].default_value = (0.3, 0.3, 0.3, 1.0)

    scene.cycles.bake_type = 'EMIT'
    bpy.ops.object.bake(type='EMIT')
    rou_path = os.path.join(chair_dir, f"{chair_name}_Roughness.png")
    save_image(img_rou, rou_path)

    # ----------------------------------------------------
    # PASS 4: Normal Map
    # ----------------------------------------------------
    print("Baking Normal Map...")
    img_nor = prepare_image(f"{chair_name}_Normal")
    for slot in baked_obj.material_slots:
        mat = slot.material
        if not mat or not mat.node_tree: continue
        nt = mat.node_tree
        e_node = nt.nodes.get("__bake_emit__")
        out_node = next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output), None)
        if e_node:
            nt.nodes.remove(e_node)
        p = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        em = next((n for n in nt.nodes if n.type == 'EMISSION'), None)
        if p and out_node:
            nt.links.new(p.outputs['BSDF'], out_node.inputs['Surface'])
        elif em and out_node:
            nt.links.new(em.outputs['Emission'], out_node.inputs['Surface'])

    scene.cycles.bake_type = 'NORMAL'
    scene.render.bake.normal_space = 'TANGENT'
    bpy.ops.object.bake(type='NORMAL')
    nor_path = os.path.join(chair_dir, f"{chair_name}_Normal.png")
    save_image(img_nor, nor_path)

    # ----------------------------------------------------
    # 8. Clean Material Slots & Setup PBR Material on FBX
    # ----------------------------------------------------
    baked_obj.data.materials.clear()
    pbr_mat = bpy.data.materials.new(name=f"M_{chair_name}_Baked")
    pbr_mat.use_nodes = True
    nt = pbr_mat.node_tree
    nt.nodes.clear()

    out_node = nt.nodes.new('ShaderNodeOutputMaterial')
    p_node = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(p_node.outputs['BSDF'], out_node.inputs['Surface'])

    # Setup baked BaseColor in node
    t_bc = nt.nodes.new('ShaderNodeTexImage')
    t_bc.image = img_bc
    nt.links.new(t_bc.outputs['Color'], p_node.inputs['Base Color'])

    # Setup baked Metallic in node
    t_met = nt.nodes.new('ShaderNodeTexImage')
    t_met.image = img_met
    nt.links.new(t_met.outputs['Color'], p_node.inputs['Metallic'])

    # Setup baked Roughness in node
    t_rou = nt.nodes.new('ShaderNodeTexImage')
    t_rou.image = img_rou
    nt.links.new(t_rou.outputs['Color'], p_node.inputs['Roughness'])

    # Setup baked Normal in node
    t_nor = nt.nodes.new('ShaderNodeTexImage')
    t_nor.image = img_nor
    nor_map = nt.nodes.new('ShaderNodeNormalMap')
    nt.links.new(t_nor.outputs['Color'], nor_map.inputs['Color'])
    nt.links.new(nor_map.outputs['Normal'], p_node.inputs['Normal'])

    baked_obj.data.materials.append(pbr_mat)

    # ----------------------------------------------------
    # 9. Export Baked FBX
    # ----------------------------------------------------
    bpy.ops.object.select_all(action='DESELECT')
    baked_obj.select_set(True)
    bpy.context.view_layer.objects.active = baked_obj

    fbx_out = os.path.join(ROBLOX_MODELS_DIR, f"{chair_name}_Baked.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx_out,
        use_selection=True,
        apply_scale_options='FBX_SCALE_ALL',
        mesh_smooth_type='FACE'
    )
    print(f"  [SAVED FBX] {os.path.basename(fbx_out)} ({os.path.getsize(fbx_out):,} bytes)")
    print(f"COMPLETED: {chair_name} successfully baked!\n")
    return True

def main():
    print("=" * 70)
    print("STARTING BATCH BAKE FOR ALL 5 CHAIRS")
    print(f"Texture Resolution: {RESOLUTION}x{RESOLUTION}")
    print("=" * 70)

    success_count = 0
    for cfg in CHAIR_CONFIGS:
        try:
            if bake_chair(cfg):
                success_count += 1
        except Exception as e:
            print(f"ERROR baking {cfg['name']}: {e}")
            import traceback
            traceback.print_exc()

    print("\n" + "=" * 70)
    print(f"BATCH BAKE FINISHED: {success_count}/{len(CHAIR_CONFIGS)} chairs baked.")
    print("=" * 70)

if __name__ == "__main__":
    main()

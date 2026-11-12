"""
bake_vip_chair.py
Bakes complete PBR textures (BaseColor, Normal, Roughness, Metallic) at 2048x2048
for BlackDiamondVIPChair, and exports game-ready single-mesh FBX.

Outputs:
- Textures: D:\\BAF\\models\\textures\\BlackDiamondVIPChair\\
    - BlackDiamondVIPChair_BaseColor.png
    - BlackDiamondVIPChair_Normal.png
    - BlackDiamondVIPChair_Roughness.png
    - BlackDiamondVIPChair_Metallic.png
- Game-ready single-mesh FBX: D:\\BAF\\models\\roblox_models\\BlackDiamondVIPChair_Baked.fbx
"""

import bpy
import os
import sys

BASE_DIR = r"D:\BAF\models"
TEXTURES_DIR = os.path.join(BASE_DIR, "textures")
ROBLOX_MODELS_DIR = os.path.join(BASE_DIR, "roblox_models")
os.makedirs(TEXTURES_DIR, exist_ok=True)
os.makedirs(ROBLOX_MODELS_DIR, exist_ok=True)

BLEND_FILE = os.path.join(BASE_DIR, "vip_chair.blend")
CHAIR_NAME = "BlackDiamondVIPChair"
RESOLUTION = 2048

def setup_cycles_engine():
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 4
    scene.render.bake.margin = 8
    scene.render.bake.margin_type = 'EXTEND'
    return scene

def main():
    print("=" * 70)
    print(f"STARTING BAKE FOR: {CHAIR_NAME}")
    print(f"Blend file: {BLEND_FILE}")
    print(f"Texture Resolution: {RESOLUTION}x{RESOLUTION}")
    print("=" * 70)

    if not os.path.exists(BLEND_FILE):
        print(f"ERROR: {BLEND_FILE} not found!")
        return

    bpy.ops.wm.open_mainfile(filepath=BLEND_FILE)
    scene = setup_cycles_engine()

    chair_dir = os.path.join(TEXTURES_DIR, CHAIR_NAME)
    os.makedirs(chair_dir, exist_ok=True)

    # 1. Identify valid chair objects from 'Chair' collection
    col_chair = bpy.data.collections.get("Chair")
    if not col_chair:
        print("ERROR: Collection 'Chair' not found!")
        return

    chair_objs = [
        o for o in col_chair.objects
        if o.type in ('MESH', 'CURVE', 'FONT')
    ]
    print(f"Found {len(chair_objs)} chair objects to bake.")

    # 2. Duplicate objects for baking
    bpy.ops.object.select_all(action='DESELECT')
    for o in chair_objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = chair_objs[0]
    bpy.ops.object.duplicate()
    dup_objs = [o for o in bpy.context.selected_objects if o.type in ('MESH', 'CURVE', 'FONT')]

    # 3. Convert all curves/fonts to MESH (applies modifiers)
    bpy.ops.object.convert(target='MESH')
    dup_meshes = [o for o in bpy.context.selected_objects if o.type == 'MESH']

    # 4. Join into single unified mesh
    bpy.context.view_layer.objects.active = dup_meshes[0]
    bpy.ops.object.join()
    baked_obj = bpy.context.view_layer.objects.active
    baked_obj.name = f"{CHAIR_NAME}_Baked"

    # 5. Apply transforms
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Ensure origin at floor center
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    min_z = min(v.co.z for v in baked_obj.data.vertices)
    for v in baked_obj.data.vertices:
        v.co.z -= min_z
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # 6. Smart UV Project
    print("Unwrapping UV with Smart UV Project...")
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.015)
    bpy.ops.object.mode_set(mode='OBJECT')

    print(f"Unified mesh: {len(baked_obj.data.vertices):,} vertices, {len(baked_obj.data.polygons):,} polygons.")

    # Helper to setup texture node
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
    print("Baking BaseColor...")
    img_bc = prepare_image(f"{CHAIR_NAME}_BaseColor")
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
                # If diamond or pure white emission
                if emi_col and "Diamond" in mat.name:
                    e_node.inputs['Color'].default_value = (0.75, 0.90, 1.0, 1.0)
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
    bc_path = os.path.join(chair_dir, f"{CHAIR_NAME}_BaseColor.png")
    save_image(img_bc, bc_path)

    # ----------------------------------------------------
    # PASS 2: Metallic
    # ----------------------------------------------------
    print("Baking Metallic...")
    img_met = prepare_image(f"{CHAIR_NAME}_Metallic")
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
    met_path = os.path.join(chair_dir, f"{CHAIR_NAME}_Metallic.png")
    save_image(img_met, met_path)

    # ----------------------------------------------------
    # PASS 3: Roughness
    # ----------------------------------------------------
    print("Baking Roughness...")
    img_rou = prepare_image(f"{CHAIR_NAME}_Roughness")
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
    rou_path = os.path.join(chair_dir, f"{CHAIR_NAME}_Roughness.png")
    save_image(img_rou, rou_path)

    # ----------------------------------------------------
    # PASS 4: Normal Map
    # ----------------------------------------------------
    print("Baking Normal Map...")
    img_nor = prepare_image(f"{CHAIR_NAME}_Normal")
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
    nor_path = os.path.join(chair_dir, f"{CHAIR_NAME}_Normal.png")
    save_image(img_nor, nor_path)

    # ----------------------------------------------------
    # 8. Setup PBR Material & Export Baked FBX
    # ----------------------------------------------------
    baked_obj.data.materials.clear()
    pbr_mat = bpy.data.materials.new(name=f"M_{CHAIR_NAME}_Baked")
    pbr_mat.use_nodes = True
    nt = pbr_mat.node_tree
    nt.nodes.clear()

    out_node = nt.nodes.new('ShaderNodeOutputMaterial')
    p_node = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(p_node.outputs['BSDF'], out_node.inputs['Surface'])

    t_bc = nt.nodes.new('ShaderNodeTexImage')
    t_bc.image = img_bc
    nt.links.new(t_bc.outputs['Color'], p_node.inputs['Base Color'])

    t_met = nt.nodes.new('ShaderNodeTexImage')
    t_met.image = img_met
    nt.links.new(t_met.outputs['Color'], p_node.inputs['Metallic'])

    t_rou = nt.nodes.new('ShaderNodeTexImage')
    t_rou.image = img_rou
    nt.links.new(t_rou.outputs['Color'], p_node.inputs['Roughness'])

    t_nor = nt.nodes.new('ShaderNodeTexImage')
    t_nor.image = img_nor
    nor_map = nt.nodes.new('ShaderNodeNormalMap')
    nt.links.new(t_nor.outputs['Color'], nor_map.inputs['Color'])
    nt.links.new(nor_map.outputs['Normal'], p_node.inputs['Normal'])

    baked_obj.data.materials.append(pbr_mat)

    # Clean geometry for Roblox Studio (remove zero-area degenerate faces & triangulate)
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(baked_obj.data)
    bmesh.ops.dissolve_degenerate(bm, dist=0.0001, edges=bm.edges)
    zero_faces = [f for f in bm.faces if f.calc_area() <= 1e-6]
    if zero_faces:
        bmesh.ops.delete(bm, geom=zero_faces, context='FACES_ONLY')
    loose_edges = [e for e in bm.edges if not e.link_faces]
    if loose_edges:
        bmesh.ops.delete(bm, geom=loose_edges, context='EDGES')
    loose_verts = [v for v in bm.verts if not v.link_edges]
    if loose_verts:
        bmesh.ops.delete(bm, geom=loose_verts, context='VERTS')
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method='BEAUTY', ngon_method='BEAUTY')
    bm.to_mesh(baked_obj.data)
    bm.free()
    baked_obj.data.update()

    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')

    # Export Clean Triangulated FBX
    bpy.ops.object.select_all(action='DESELECT')
    baked_obj.select_set(True)
    bpy.context.view_layer.objects.active = baked_obj

    fbx_out = os.path.join(ROBLOX_MODELS_DIR, f"{CHAIR_NAME}_Baked.fbx")
    bpy.ops.export_scene.fbx(
        filepath=fbx_out,
        use_selection=True,
        apply_scale_options='FBX_SCALE_ALL',
        mesh_smooth_type='FACE',
        use_triangles=True
    )
    print(f"\n[SUCCESS FBX EXPORTED] {fbx_out} ({os.path.getsize(fbx_out):,} bytes)")

    # Export Clean OBJ as fallback
    obj_out = os.path.join(ROBLOX_MODELS_DIR, f"{CHAIR_NAME}_Baked.obj")
    bpy.ops.wm.obj_export(
        filepath=obj_out,
        export_selected_objects=True,
        export_triangulated_mesh=True,
        export_uv=True,
        export_normals=True,
        export_materials=False
    )
    print(f"[SUCCESS OBJ EXPORTED] {obj_out} ({os.path.getsize(obj_out):,} bytes)")
    print("=" * 70)
    print("BAKE COMPLETE!")
    print("=" * 70)

if __name__ == "__main__":
    main()

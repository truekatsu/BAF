# ==============================================================================
# LEGO STADIUM CHAIR 3D MODEL GENERATOR & FBX EXPORTER (Blender Python / bpy)
# Stylized Lego Stadium Blue Chair matching 4-view orthographic reference sheet:
# - Dark slate 2x2 stud base plate with 4 cylindrical Lego studs
# - Central square pedestal column
# - Stepped stadium blue seat cushion
# - Angled stadium blue backrest with two vertical front ribs and rear frame recess
# ==============================================================================
import bpy
import bmesh
import math
import os

CONFIG = {
    "EXPORT_DIR": r"D:\BAF\models",
}

PALETTE = {
    "BlueMain": "#1E6FFF",
    "BlueShadow": "#1555C5",
    "BlueRib": "#2879FF",
    "DarkBase": "#242C38",
    "DarkStud": "#2B3442",
}

def hex_to_rgba(hex_str: str, alpha: float = 1.0) -> tuple:
    h = hex_str.lstrip('#')
    rgb = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    linear = tuple((c / 12.92) if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb)
    return linear + (alpha,)

def get_or_create_material(name: str, hex_color: str, roughness: float = 0.35):
    mat = bpy.data.materials.get(name)
    if not mat:
        mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf and "Base Color" in bsdf.inputs:
        bsdf.inputs["Base Color"].default_value = hex_to_rgba(hex_color)
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
    return mat

def create_box(name: str, size: tuple, location: tuple, rotation_euler: tuple = (0,0,0), mat_name: str = "BlueMain"):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation_euler)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    mat = get_or_create_material(mat_name, PALETTE[mat_name])
    obj.data.materials.append(mat)
    return obj

def create_cylinder(name: str, radius: float, depth: float, location: tuple, mat_name: str = "DarkStud"):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=24, location=location)
    obj = bpy.context.active_object
    obj.name = name
    mat = get_or_create_material(mat_name, PALETTE[mat_name])
    obj.data.materials.append(mat)
    return obj

def build_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    # 1. Base Plate (Dark Slate 2x2 plate)
    create_box("BasePlate", (1.40, 1.40, 0.28), (0, -0.05, 0.14), mat_name="DarkBase")

    # 2. 4 Base Studs
    s_dist = 0.38
    for idx, (sx, sy) in enumerate([(-s_dist, s_dist), (s_dist, s_dist), (-s_dist, -s_dist), (s_dist, -s_dist)]):
        create_cylinder(f"Stud_{idx+1}", radius=0.17, depth=0.12, location=(sx, -0.05 + sy, 0.34), mat_name="DarkStud")

    # 3. Center Pedestal Post
    create_box("CenterPost", (0.48, 0.48, 0.48), (0, -0.05, 0.52), mat_name="DarkBase")

    # 4. Seat Lower Plate
    create_box("SeatBase", (1.62, 1.60, 0.18), (0, -0.05, 0.85), mat_name="BlueMain")

    # 5. Seat Front Cushion
    create_box("SeatCushion", (1.58, 1.15, 0.22), (0, 0.18, 1.05), mat_name="BlueMain")

    # 6. Backrest Slab (tilted back 8.5 deg around X)
    tilt_rad = math.radians(8.5)
    rot = (tilt_rad, 0, 0)
    create_box("BackrestSlab", (1.62, 0.26, 1.52), (0, -0.42, 1.72), rotation_euler=rot, mat_name="BlueMain")

    # 7. Front Ribs
    rib_y = -0.42 + math.sin(tilt_rad) * 0.16
    create_box("RibLeft", (0.32, 0.06, 1.26), (-0.36, rib_y + 0.15, 1.72), rotation_euler=rot, mat_name="BlueRib")
    create_box("RibRight", (0.32, 0.06, 1.26), (0.36, rib_y + 0.15, 1.72), rotation_euler=rot, mat_name="BlueRib")

    os.makedirs(CONFIG["EXPORT_DIR"], exist_ok=True)
    blend_path = os.path.join(CONFIG["EXPORT_DIR"], "Stadium_Chair.blend")
    fbx_path = os.path.join(CONFIG["EXPORT_DIR"], "Stadium_Chair.fbx")

    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.fbx(filepath=fbx_path, use_selection=True, apply_scale_options='FBX_SCALE_ALL')
    print(f"Exported: {blend_path} and {fbx_path}")

if __name__ == "__main__":
    build_scene()

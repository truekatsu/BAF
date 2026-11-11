"""
export_roblox_chairs.py
Builds:
1. Four native Roblox XML models: .rbxmx for CrimsonFlameChair, CyberCoreChair, FrostbiteIceThrone, RoyalFootballThrone
2. Showcase model .rbxmx containing all 4 chairs side-by-side
3. Standalone Luau script: SpawnAllChairsInStudio.luau (Command Bar 1-click execution in Studio)
4. Copies and verifies FBX files
"""

import os
import shutil
import math
import xml.etree.ElementTree as ET

OUTPUT_DIR = r"D:\BAF\models\roblox_models"
MODELS_DIR = r"D:\BAF\models"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 1. Copy FBX files
fbx_files = [
    "CrimsonFlameChair.fbx",
    "CyberCoreChair.fbx",
    "FrostbiteIceThrone.fbx",
    "RoyalFootballThrone.fbx",
]
for f in fbx_files:
    src = os.path.join(MODELS_DIR, f)
    dst = os.path.join(OUTPUT_DIR, f)
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f"Copied {f} to {OUTPUT_DIR}")

# 2. Material mapping to Roblox XML token ID
MATERIAL_TOKENS = {
    "Plastic": 256,
    "SmoothPlastic": 272,
    "Neon": 288,
    "Wood": 512,
    "WoodPlanks": 528,
    "Slate": 800,
    "Metal": 1088,
    "DiamondPlate": 1056,
    "Ice": 1536,
    "Glass": 1568,
    "ForceField": 1584,
}

class RbxmxBuilder:
    def __init__(self):
        self.ref_counter = 0

    def get_ref(self):
        self.ref_counter += 1
        return f"RBX{self.ref_counter}"

    def create_root(self):
        root = ET.Element("roblox")
        root.set("xmlns:xmime", "http://www.w3.org/2005/05/xmlmime")
        root.set("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
        root.set("xsi:noNamespaceSchemaLocation", "http://www.roblox.com/roblox.xsd")
        root.set("version", "4")
        meta = ET.SubElement(root, "Meta")
        meta.set("name", "ExplicitAutoJoints")
        meta.text = "true"
        return root

    def add_model(self, parent, name):
        item = ET.SubElement(parent, "Item")
        item.set("class", "Model")
        item.set("referent", self.get_ref())
        props = ET.SubElement(item, "Properties")
        n = ET.SubElement(props, "string")
        n.set("name", "Name")
        n.text = name
        return item

    def add_part(self, parent, name, size, pos, rot_euler_deg=(0, 0, 0), color_rgb=(255, 255, 255), material="SmoothPlastic", shape="Block", can_collide=False, is_seat=False):
        item = ET.SubElement(parent, "Item")
        item.set("class", "Seat" if is_seat else "Part")
        item.set("referent", self.get_ref())
        props = ET.SubElement(item, "Properties")

        n = ET.SubElement(props, "string"); n.set("name", "Name"); n.text = name
        anc = ET.SubElement(props, "bool"); anc.set("name", "Anchored"); anc.text = "true"
        col = ET.SubElement(props, "bool"); col.set("name", "CanCollide"); col.text = "true" if can_collide else "false"
        sha = ET.SubElement(props, "bool"); sha.set("name", "CastShadow"); sha.text = "true"

        sz = ET.SubElement(props, "Vector3"); sz.set("name", "size")
        x_elem = ET.SubElement(sz, "X"); x_elem.text = f"{size[0]:.4f}"
        y_elem = ET.SubElement(sz, "Y"); y_elem.text = f"{size[1]:.4f}"
        z_elem = ET.SubElement(sz, "Z"); z_elem.text = f"{size[2]:.4f}"

        cf = ET.SubElement(props, "CoordinateFrame"); cf.set("name", "CFrame")
        x_elem = ET.SubElement(cf, "X"); x_elem.text = f"{pos[0]:.4f}"
        y_elem = ET.SubElement(cf, "Y"); y_elem.text = f"{pos[1]:.4f}"
        z_elem = ET.SubElement(cf, "Z"); z_elem.text = f"{pos[2]:.4f}"

        rx = math.radians(rot_euler_deg[0])
        ry = math.radians(rot_euler_deg[1])
        rz = math.radians(rot_euler_deg[2])
        cx, sx = math.cos(rx), math.sin(rx)
        cy, sy = math.cos(ry), math.sin(ry)
        cz, sz_val = math.cos(rz), math.sin(rz)
        
        r00 = cy * cz
        r01 = -cy * sz_val
        r02 = sy
        r10 = sx * sy * cz + cx * sz_val
        r11 = -sx * sy * sz_val + cx * cz
        r12 = -sx * cy
        r20 = -cx * sy * cz + sx * sz_val
        r21 = cx * sy * sz_val + sx * cz
        r22 = cx * cy

        for r_name, r_val in [("R00", r00), ("R01", r01), ("R02", r02),
                              ("R10", r10), ("R11", r11), ("R12", r12),
                              ("R20", r20), ("R21", r21), ("R22", r22)]:
            elem = ET.SubElement(cf, r_name)
            elem.text = f"{r_val:.6f}"

        c = ET.SubElement(props, "Color3"); c.set("name", "Color")
        cr = ET.SubElement(c, "R"); cr.text = f"{color_rgb[0]/255.0:.6f}"
        cg = ET.SubElement(c, "G"); cg.text = f"{color_rgb[1]/255.0:.6f}"
        cb = ET.SubElement(c, "B"); cb.text = f"{color_rgb[2]/255.0:.6f}"

        mat_elem = ET.SubElement(props, "token"); mat_elem.set("name", "Material")
        mat_elem.text = str(MATERIAL_TOKENS.get(material, 272))

        if shape == "Cylinder":
            sh_elem = ET.SubElement(props, "token"); sh_elem.set("name", "shape"); sh_elem.text = "2"
        elif shape == "Ball":
            sh_elem = ET.SubElement(props, "token"); sh_elem.set("name", "shape"); sh_elem.text = "0"

        return item

    def add_point_light(self, parent, name, color_rgb, brightness=2.0, range_val=14.0):
        item = ET.SubElement(parent, "Item")
        item.set("class", "PointLight")
        item.set("referent", self.get_ref())
        props = ET.SubElement(item, "Properties")
        
        n = ET.SubElement(props, "string"); n.set("name", "Name"); n.text = name
        c = ET.SubElement(props, "Color3"); c.set("name", "Color")
        cr = ET.SubElement(c, "R"); cr.text = f"{color_rgb[0]/255.0:.6f}"
        cg = ET.SubElement(c, "G"); cg.text = f"{color_rgb[1]/255.0:.6f}"
        cb = ET.SubElement(c, "B"); cb.text = f"{color_rgb[2]/255.0:.6f}"

        b = ET.SubElement(props, "float"); b.set("name", "Brightness"); b.text = f"{brightness:.2f}"
        r = ET.SubElement(props, "float"); r.set("name", "Range"); r.text = f"{range_val:.2f}"
        s = ET.SubElement(props, "bool"); s.set("name", "Shadows"); s.text = "false"
        return item

    def add_particle_emitter(self, parent, name, color_start_rgb, color_end_rgb, rate=15, speed=(2, 4), size=(1.5, 0), lifetime=(0.8, 1.4), texture="rbxassetid://253188732"):
        item = ET.SubElement(parent, "Item")
        item.set("class", "ParticleEmitter")
        item.set("referent", self.get_ref())
        props = ET.SubElement(item, "Properties")
        n = ET.SubElement(props, "string"); n.set("name", "Name"); n.text = name
        tex = ET.SubElement(props, "Content"); tex.set("name", "Texture"); ET.SubElement(tex, "url").text = texture
        r = ET.SubElement(props, "float"); r.set("name", "Rate"); r.text = f"{rate:.1f}"
        le = ET.SubElement(props, "float"); le.set("name", "LightEmission"); le.text = "1.0"
        return item

    def add_script(self, parent, name, source_code):
        item = ET.SubElement(parent, "Item")
        item.set("class", "Script")
        item.set("referent", self.get_ref())
        props = ET.SubElement(item, "Properties")
        n = ET.SubElement(props, "string"); n.set("name", "Name"); n.text = name
        src = ET.SubElement(props, "ProtectedString"); src.set("name", "Source"); src.text = source_code
        return item

    def write_file(self, root_elem, filename):
        tree = ET.ElementTree(root_elem)
        ET.indent(tree, space="\t", level=0)
        out_path = os.path.join(OUTPUT_DIR, filename)
        with open(out_path, "wb") as f:
            f.write(b'<?xml version="1.0" encoding="utf-8"?>\n')
            tree.write(f, encoding="utf-8", xml_declaration=False)
        print(f"Generated {out_path} ({os.path.getsize(out_path)} bytes)")


# Build Individual Chair Data
def populate_crimson_chair(builder, model, ox=0, oy=0, oz=0):
    c_wood = (150, 15, 25)
    c_leg = (110, 10, 20)
    c_iron = (30, 24, 28)
    c_gem = (255, 40, 50)

    # Seat
    seat = builder.add_part(model, "Seat", (4.0, 0.7, 4.0), (ox, oy + 2.85, oz), color_rgb=c_wood, material="WoodPlanks", can_collide=True, is_seat=True)
    builder.add_point_light(seat, "SeatGlow", (255, 40, 40), brightness=2.0, range_val=14.0)

    # 4 Legs & caps
    for tag, lx, lz in [("FL", -1.6, -1.6), ("FR", 1.6, -1.6), ("BL", -1.6, 1.6), ("BR", 1.6, 1.6)]:
        builder.add_part(model, f"Leg_{tag}", (0.8, 2.5, 0.8), (ox + lx, oy + 1.25, oz + lz), color_rgb=c_leg, material="WoodPlanks", can_collide=True)
        cap = builder.add_part(model, f"LegCap_{tag}", (0.95, 0.5, 0.95), (ox + lx, oy + 0.25, oz + lz), color_rgb=c_iron, material="Slate", can_collide=False)
        builder.add_particle_emitter(cap, "FireEmitter", (255, 80, 60), (120, 0, 10), rate=16)
        # Gems on cap
        builder.add_part(model, f"Gem_LegCap_{tag}", (0.24, 0.24, 0.08), (ox + lx, oy + 0.25, oz + lz - 0.49), rot_euler_deg=(0, 0, 45), color_rgb=c_gem, material="Neon")

    # Backrest Posts & Caps
    for tag, px in [("Left", -1.6), ("Right", 1.6)]:
        builder.add_part(model, f"Post_{tag}", (0.8, 5.0, 0.8), (ox + px, oy + 5.7, oz + 1.6), color_rgb=c_wood, material="WoodPlanks", can_collide=True)
        cap = builder.add_part(model, f"PostCap_{tag}", (0.95, 0.5, 0.95), (ox + px, oy + 8.2, oz + 1.6), color_rgb=c_iron, material="Slate", can_collide=False)
        builder.add_particle_emitter(cap, "FireEmitter", (255, 80, 60), (120, 0, 10), rate=20)
        builder.add_part(model, f"Gem_PostCap_{tag}", (0.24, 0.24, 0.08), (ox + px, oy + 8.2, oz + 1.11), rot_euler_deg=(0, 0, 45), color_rgb=c_gem, material="Neon")

    # Backrest Panel
    builder.add_part(model, "BackrestPanel", (3.2, 4.4, 0.4), (ox, oy + 5.7, oz + 1.6), color_rgb=c_wood, material="WoodPlanks", can_collide=True)

    # Seat Corner brackets & gems
    for tag, cx, cz in [("FL", -1.6, -1.6), ("FR", 1.6, -1.6), ("BL", -1.6, 1.6), ("BR", 1.6, 1.6)]:
        builder.add_part(model, f"BracketX_{tag}", (0.85, 0.12, 0.28), (ox + cx, oy + 3.26, oz + cz), color_rgb=c_iron, material="Slate")
        builder.add_part(model, f"BracketZ_{tag}", (0.28, 0.12, 0.85), (ox + cx, oy + 3.26, oz + cz), color_rgb=c_iron, material="Slate")
        builder.add_part(model, f"Gem_Corner_{tag}", (0.24, 0.24, 0.08), (ox + cx, oy + 3.32, oz + cz), rot_euler_deg=(90, 45, 0), color_rgb=c_gem, material="Neon")

    # Script
    script_code = """
local TweenService = game:GetService("TweenService")
local model = script.Parent
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
for _, desc in ipairs(model:GetDescendants()) do
    if desc:IsA("BasePart") and desc.Name:find("Gem") then
        desc.Color = Color3.fromRGB(153, 24, 30)
        local tw = TweenService:Create(desc, tweenInfo, { Color = Color3.fromRGB(255, 40, 50) })
        tw:Play()
    end
end
"""
    builder.add_script(model, "ChairEffectController", script_code.strip())


def populate_cyber_chair(builder, model, ox=0, oy=0, oz=0):
    c_metal = (18, 20, 32)
    c_cap = (35, 40, 60)
    c_cyan = (0, 255, 240)
    c_magenta = (255, 0, 200)

    # Seat
    seat = builder.add_part(model, "Seat", (4.0, 0.7, 4.0), (ox, oy + 2.85, oz), color_rgb=c_metal, material="Metal", can_collide=True, is_seat=True)
    builder.add_part(model, "SeatCircuitX1", (3.8, 0.08, 0.12), (ox, oy + 3.22, oz - 1.8), color_rgb=c_cyan, material="Neon")
    builder.add_part(model, "SeatCircuitX2", (3.8, 0.08, 0.12), (ox, oy + 3.22, oz + 1.8), color_rgb=c_cyan, material="Neon")
    builder.add_part(model, "SeatCircuitZ1", (0.12, 0.08, 3.6), (ox - 1.8, oy + 3.22, oz), color_rgb=c_magenta, material="Neon")
    builder.add_part(model, "SeatCircuitZ2", (0.12, 0.08, 3.6), (ox + 1.8, oy + 3.22, oz), color_rgb=c_magenta, material="Neon")
    # Chip center
    builder.add_part(model, "SeatChipCenter", (1.2, 0.06, 1.2), (ox, oy + 3.22, oz), rot_euler_deg=(0, 45, 0), color_rgb=c_cyan, material="Neon")

    # 4 Legs & caps
    for tag, lx, lz in [("FL", -1.6, -1.6), ("FR", 1.6, -1.6), ("BL", -1.6, 1.6), ("BR", 1.6, 1.6)]:
        builder.add_part(model, f"Leg_{tag}", (0.8, 2.5, 0.8), (ox + lx, oy + 1.25, oz + lz), color_rgb=c_metal, material="Metal", can_collide=True)
        # Leg neon trace
        builder.add_part(model, f"LegTrace_{tag}", (0.12, 2.4, 0.12), (ox + lx, oy + 1.25, oz + lz - 0.38), color_rgb=c_cyan, material="Neon")
        cap = builder.add_part(model, f"LegCap_{tag}", (0.95, 0.5, 0.95), (ox + lx, oy + 0.25, oz + lz), color_rgb=c_cap, material="Metal", can_collide=False)
        builder.add_point_light(cap, f"CapLight_{tag}", c_magenta, brightness=1.5, range_val=8.0)
        builder.add_part(model, f"Gem_LegCap_{tag}", (0.24, 0.24, 0.08), (ox + lx, oy + 0.25, oz + lz - 0.49), rot_euler_deg=(0, 0, 45), color_rgb=c_magenta, material="Neon")

    # Backrest Posts & Caps
    for tag, px in [("Left", -1.6), ("Right", 1.6)]:
        builder.add_part(model, f"Post_{tag}", (0.8, 5.0, 0.8), (ox + px, oy + 5.7, oz + 1.6), color_rgb=c_metal, material="Metal", can_collide=True)
        builder.add_part(model, f"PostTrace_{tag}", (0.12, 4.8, 0.12), (ox + px, oy + 5.7, oz + 1.18), color_rgb=c_magenta, material="Neon")
        cap = builder.add_part(model, f"PostCap_{tag}", (0.95, 0.5, 0.95), (ox + px, oy + 8.2, oz + 1.6), color_rgb=c_cap, material="Metal", can_collide=False)
        builder.add_point_light(cap, f"PostLight_{tag}", c_cyan, brightness=1.5, range_val=8.0)
        builder.add_part(model, f"Gem_PostCap_{tag}", (0.24, 0.24, 0.08), (ox + px, oy + 8.2, oz + 1.11), rot_euler_deg=(0, 0, 45), color_rgb=c_cyan, material="Neon")

    # Backrest Panel & Hex Frame
    builder.add_part(model, "BackrestPanel", (3.2, 4.4, 0.4), (ox, oy + 5.7, oz + 1.6), color_rgb=c_metal, material="Metal", can_collide=True)
    # Hexagonal Frame struts around energy core
    hex_r = 0.85
    for i in range(6):
        ang = i * 60
        rad = math.radians(ang)
        hx = math.cos(rad) * hex_r
        hy = math.sin(rad) * hex_r
        builder.add_part(model, f"HexStrut_{i}", (0.45, 0.10, 0.12), (ox + hx, oy + 5.7 + hy, oz + 1.36), rot_euler_deg=(0, 0, ang + 30), color_rgb=c_magenta, material="Neon")

    # Energy Core (Floating Rotating Gem)
    core = builder.add_part(model, "EnergyCore", (0.8, 0.8, 0.8), (ox, oy + 5.7, oz + 1.35), rot_euler_deg=(45, 45, 0), color_rgb=c_cyan, material="Neon")
    builder.add_point_light(core, "CoreLight", c_cyan, brightness=3.0, range_val=16.0)
    builder.add_particle_emitter(core, "DigitalSparks", c_cyan, c_magenta, rate=20, speed=(1.5, 3.5), size=(0.6, 0.1))

    # Controller Script
    script_code = """
local RunService = game:GetService("TweenService")
local model = script.Parent
local core = model:FindFirstChild("EnergyCore")
local baseY = core and core.Position.Y or 5.7
local t = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
    t = t + dt
    if core and core:IsA("BasePart") then
        core.CFrame = CFrame.new(core.Position.X, baseY + math.sin(t * 3) * 0.18, core.Position.Z) * CFrame.Angles(0, t * 1.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
    end
end)
"""
    builder.add_script(model, "CyberEffectController", script_code.strip())


def populate_frostbite_throne(builder, model, ox=0, oy=0, oz=0):
    c_deep = (60, 150, 230)
    c_main = (120, 210, 255)
    c_glow = (160, 240, 255)
    c_snow = (245, 250, 255)
    c_gem = (100, 235, 255)

    # Seat Block & Recessed Cushion
    seat = builder.add_part(model, "Seat", (3.8, 0.7, 3.6), (ox, oy + 2.5, oz), color_rgb=c_deep, material="Glass", can_collide=True, is_seat=True)
    builder.add_part(model, "SeatCushionRecess", (3.2, 0.25, 3.0), (ox, oy + 2.88, oz + 0.1), color_rgb=c_main, material="Glass")

    # 3 Front Chevron Plates (V-shape)
    for i in range(3):
        y_off = 2.2 - (i * 0.45)
        builder.add_part(model, f"Chevron_L_{i}", (1.1, 0.28, 0.2), (ox - 0.55, oy + y_off, oz - 1.85), rot_euler_deg=(0, 0, -22), color_rgb=c_glow, material="Neon")
        builder.add_part(model, f"Chevron_R_{i}", (1.1, 0.28, 0.2), (ox + 0.55, oy + y_off, oz - 1.85), rot_euler_deg=(0, 0, 22), color_rgb=c_glow, material="Neon")

    # 4 Legs & Chipped Foot Blocks
    for tag, lx, lz in [("FL", -1.5, -1.4), ("FR", 1.5, -1.4), ("BL", -1.5, 1.4), ("BR", 1.5, 1.4)]:
        builder.add_part(model, f"Leg_{tag}", (0.8, 2.2, 0.8), (ox + lx, oy + 1.1, oz + lz), color_rgb=c_deep, material="Glass", can_collide=True)
        builder.add_part(model, f"FootBlock_{tag}", (1.15, 0.75, 1.15), (ox + lx, oy + 0.38, oz + lz), rot_euler_deg=(0, 15 if "L" in tag else -15, 0), color_rgb=c_main, material="Glass", can_collide=False)

    # 2 Armrests with Snow Caps
    for tag, ax in [("Left", -1.9), ("Right", 1.9)]:
        builder.add_part(model, f"ArmrestPillar_{tag}", (0.85, 1.8, 0.85), (ox + ax, oy + 1.7, oz - 1.2), color_rgb=c_deep, material="Glass", can_collide=True)
        builder.add_part(model, f"Armrest_{tag}", (0.85, 0.85, 3.2), (ox + ax, oy + 3.4, oz), color_rgb=c_deep, material="Glass", can_collide=True)
        # Snow cap
        builder.add_part(model, f"SnowCap_{tag}", (0.95, 0.28, 3.2), (ox + ax, oy + 3.85, oz), color_rgb=c_snow, material="SmoothPlastic")
        # Hanging icicles
        for ic in range(4):
            builder.add_part(model, f"Icicle_{tag}_{ic}", (0.12, 0.55, 0.12), (ox + ax, oy + 2.75 - ic * 0.05, oz - 1.2 + ic * 0.8), color_rgb=c_glow, material="Glass")

    # Backrest Slab
    builder.add_part(model, "BackrestSlab", (3.4, 5.2, 0.6), (ox, oy + 5.1, oz + 1.5), color_rgb=c_deep, material="Glass", can_collide=True)
    # 5 Backrest Chevrons
    for i in range(5):
        y_off = 3.8 + (i * 0.75)
        w = 1.6 - (i * 0.18)
        builder.add_part(model, f"BackChevron_L_{i}", (w, 0.32, 0.18), (ox - w * 0.45, oy + y_off, oz + 1.18), rot_euler_deg=(0, 0, -26), color_rgb=c_main, material="Glass")
        builder.add_part(model, f"BackChevron_R_{i}", (w, 0.32, 0.18), (ox + w * 0.45, oy + y_off, oz + 1.18), rot_euler_deg=(0, 0, 26), color_rgb=c_main, material="Glass")

    # Crown Fan of 11 Jagged Crystal Shards
    shard_configs = [
        (-2.2, 4.0, -32, 0.48),
        (-1.8, 4.8, -26, 0.52),
        (-1.4, 5.6, -20, 0.55),
        (-1.0, 6.2, -14, 0.58),
        (-0.5, 6.8, -7,  0.60),
        ( 0.0, 7.4,  0,  0.64), # Tallest center
        ( 0.5, 6.8,  7,  0.60),
        ( 1.0, 6.2,  14, 0.58),
        ( 1.4, 5.6,  20, 0.55),
        ( 1.8, 4.8,  26, 0.52),
        ( 2.2, 4.0,  32, 0.48),
    ]
    for idx, (sx, sh, srot, sw) in enumerate(shard_configs):
        builder.add_part(model, f"CrystalShard_{idx+1}", (sw, sh, sw), (ox + sx, oy + 5.2 + sh * 0.45, oz + 1.65), rot_euler_deg=(0, 0, srot), color_rgb=c_glow, material="Neon")

    # Center-Top Diamond Crystal Gem
    gem = builder.add_part(model, "TopDiamondGem", (1.2, 1.8, 0.8), (ox, oy + 8.8, oz + 1.45), rot_euler_deg=(0, 0, 45), color_rgb=c_gem, material="Neon")
    builder.add_point_light(gem, "IceGlow", (140, 230, 255), brightness=2.5, range_val=16.0)
    builder.add_particle_emitter(gem, "FrostMist", (180, 240, 255), (255, 255, 255), rate=12, speed=(0.8, 2.0), size=(1.2, 0.2))

    # Script
    script_code = """
local TweenService = game:GetService("TweenService")
local model = script.Parent
local topGem = model:FindFirstChild("TopDiamondGem")
if topGem and topGem:IsA("BasePart") then
    local tw = TweenService:Create(topGem, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Color = Color3.fromRGB(180, 250, 255)
    })
    tw:Play()
end
"""
    builder.add_script(model, "FrostEffectController", script_code.strip())


def populate_royal_throne(builder, model, ox=0, oy=0, oz=0):
    c_gold = (255, 195, 30)
    c_velvet = (180, 20, 32)
    c_dark_underside = (30, 24, 22)
    c_ruby = (255, 30, 50)
    c_white = (255, 255, 255)
    c_black = (20, 20, 22)

    # 1. Base Foot Slabs & Pillars
    for tag, bx in [("Left", -1.9), ("Right", 1.9)]:
        builder.add_part(model, f"FootSlab_{tag}", (1.8, 0.6, 3.2), (ox + bx, oy + 0.3, oz), color_rgb=c_gold, material="SmoothPlastic", can_collide=True)
        builder.add_part(model, f"Pillar_{tag}", (1.4, 1.8, 2.4), (ox + bx, oy + 1.5, oz), color_rgb=c_gold, material="SmoothPlastic", can_collide=True)
        # Recessed red panel
        builder.add_part(model, f"PillarRedPanel_{tag}", (1.1, 1.4, 0.05), (ox + bx, oy + 1.5, oz - 1.23), color_rgb=c_velvet, material="SmoothPlastic")
    # Hollow underside
    builder.add_part(model, "UndersideHollow", (2.2, 1.6, 2.6), (ox, oy + 1.4, oz), color_rgb=c_dark_underside, material="SmoothPlastic")

    # 2. Seat Frame & Red Quilted Cushion (Seat)
    builder.add_part(model, "SeatFrame", (3.6, 0.6, 3.2), (ox, oy + 2.5, oz), color_rgb=c_gold, material="SmoothPlastic")
    seat = builder.add_part(model, "Seat", (3.2, 0.8, 2.8), (ox, oy + 2.9, oz + 0.1), color_rgb=c_velvet, material="SmoothPlastic", can_collide=True, is_seat=True)
    builder.add_point_light(seat, "ThroneGlow", (255, 210, 90), brightness=2.5, range_val=16.0)

    # Front Diamond Frame & Ruby Gem
    builder.add_part(model, "FrontDiamondFrame", (1.4, 1.4, 0.15), (ox, oy + 2.5, oz - 1.65), rot_euler_deg=(0, 0, 45), color_rgb=c_gold, material="SmoothPlastic")
    builder.add_part(model, "FrontRubyGem", (0.7, 0.7, 0.22), (ox, oy + 2.5, oz - 1.72), rot_euler_deg=(0, 0, 45), color_rgb=c_ruby, material="Neon")

    # 3. Armrests with recessed panels
    for tag, ax in [("Left", -2.2), ("Right", 2.2)]:
        builder.add_part(model, f"Armrest_{tag}", (1.3, 1.4, 3.0), (ox + ax, oy + 3.7, oz), color_rgb=c_gold, material="SmoothPlastic", can_collide=True)
        builder.add_part(model, f"ArmrestPanel_{tag}", (0.9, 1.0, 0.05), (ox + ax, oy + 3.7, oz - 1.53), color_rgb=c_velvet, material="SmoothPlastic")
        builder.add_part(model, f"ArmrestGem_{tag}", (0.35, 0.35, 0.08), (ox + ax, oy + 3.7, oz - 1.58), rot_euler_deg=(0, 0, 45), color_rgb=c_gold, material="SmoothPlastic")

    # 4. Backrest Outer Frame & Wing-Spikes
    builder.add_part(model, "BackrestFrame", (4.4, 6.2, 0.8), (ox, oy + 6.0, oz + 1.4), color_rgb=c_gold, material="SmoothPlastic", can_collide=True)
    # Wing-Spikes flared at top left/right
    builder.add_part(model, "WingSpike_Left", (1.2, 1.8, 0.6), (ox - 2.4, oy + 8.8, oz + 1.4), rot_euler_deg=(0, 0, 35), color_rgb=c_gold, material="SmoothPlastic")
    builder.add_part(model, "WingSpike_Right", (1.2, 1.8, 0.6), (ox + 2.4, oy + 8.8, oz + 1.4), rot_euler_deg=(0, 0, -35), color_rgb=c_gold, material="SmoothPlastic")

    # Inner Red Quilted Panel
    builder.add_part(model, "QuiltedPanel", (3.2, 4.8, 0.5), (ox, oy + 5.6, oz + 1.1), color_rgb=c_velvet, material="SmoothPlastic")
    # 9 Gold Tuft Buttons (3x3 grid)
    for row in range(3):
        for col in range(3):
            bx = (col - 1) * 0.95
            by = 4.4 + row * 1.15
            builder.add_part(model, f"TuftButton_{row}_{col}", (0.35, 0.35, 0.35), (ox + bx, oy + by, oz + 0.82), color_rgb=c_gold, material="SmoothPlastic", shape="Ball")

    # Emblem Ring & Soccer Ball
    builder.add_part(model, "EmblemRing", (2.8, 2.8, 0.4), (ox, oy + 7.6, oz + 1.15), rot_euler_deg=(0, 0, 45), color_rgb=c_gold, material="SmoothPlastic")
    builder.add_part(model, "SoccerBall", (2.1, 2.1, 2.1), (ox, oy + 7.6, oz + 1.15), color_rgb=c_white, material="SmoothPlastic", shape="Ball")
    # Soccer ball pentagon pattern studs
    builder.add_part(model, "Pentagon_Center", (0.55, 0.55, 0.1), (ox, oy + 7.6, oz + 0.08), rot_euler_deg=(0, 0, 36), color_rgb=c_black, material="SmoothPlastic")

    # 5-Peak Crown on Top with Ruby Gem
    crown_peaks = [
        (-1.2, 0.8, -18),
        (-0.6, 1.2, -9),
        ( 0.0, 1.7,  0), # Center peak
        ( 0.6, 1.2,  9),
        ( 1.2, 0.8,  18),
    ]
    for idx, (px, ph, prot) in enumerate(crown_peaks):
        builder.add_part(model, f"CrownPeak_{idx+1}", (0.55, ph, 0.45), (ox + px, oy + 9.3 + ph * 0.4, oz + 1.15), rot_euler_deg=(0, 0, prot), color_rgb=c_gold, material="SmoothPlastic")
    builder.add_part(model, "CrownRubyGem", (0.55, 0.55, 0.25), (ox, oy + 9.9, oz + 0.92), rot_euler_deg=(0, 0, 45), color_rgb=c_ruby, material="Neon")

    # 2 Side Tournament Banners
    for tag, bx in [("Left", -2.6), ("Right", 2.6)]:
        builder.add_part(model, f"Banner_{tag}", (0.7, 2.2, 0.08), (ox + bx, oy + 6.2, oz + 1.2), color_rgb=c_velvet, material="SmoothPlastic")
        builder.add_part(model, f"BannerCrownEmblem_{tag}", (0.4, 0.3, 0.04), (ox + bx, oy + 6.6, oz + 1.14), color_rgb=c_gold, material="Neon")

    # Sparkle Particles
    builder.add_particle_emitter(seat, "GoldenSparkles", (255, 230, 120), (255, 180, 20), rate=10, speed=(0.6, 1.8), size=(0.4, 0.08), texture="rbxasset://textures/particles/sparkles_main.dds")

    # Script
    script_code = """
local TweenService = game:GetService("TweenService")
local model = script.Parent
local ruby = model:FindFirstChild("CrownRubyGem")
local frontRuby = model:FindFirstChild("FrontRubyGem")
local info = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
if ruby and ruby:IsA("BasePart") then
    TweenService:Create(ruby, info, { Color = Color3.fromRGB(255, 80, 100) }):Play()
end
if frontRuby and frontRuby:IsA("BasePart") then
    TweenService:Create(frontRuby, info, { Color = Color3.fromRGB(255, 80, 100) }):Play()
end
"""
    builder.add_script(model, "RoyalEffectController", script_code.strip())


# Generate Single Model .rbxmx files
def export_all_rbxmx():
    models_to_export = [
        ("CrimsonFlameChair.rbxmx", "CrimsonFlameChair", populate_crimson_chair),
        ("CyberCoreChair.rbxmx", "CyberCoreChair", populate_cyber_chair),
        ("FrostbiteIceThrone.rbxmx", "FrostbiteIceThrone", populate_frostbite_throne),
        ("RoyalFootballThrone.rbxmx", "RoyalFootballThrone", populate_royal_throne),
    ]

    for fname, name, pop_func in models_to_export:
        builder = RbxmxBuilder()
        root = builder.create_root()
        model = builder.add_model(root, name)
        pop_func(builder, model, ox=0, oy=0, oz=0)
        builder.write_file(root, fname)

    # Showcase Model containing all 4 chairs lined up
    sc_builder = RbxmxBuilder()
    sc_root = sc_builder.create_root()
    sc_model = sc_builder.add_model(sc_root, "AllChairsShowcase")
    
    # 4 Chairs at X = -12, -4, 4, 12
    c1 = sc_builder.add_model(sc_model, "CrimsonFlameChair")
    populate_crimson_chair(sc_builder, c1, ox=-12, oy=0, oz=0)

    c2 = sc_builder.add_model(sc_model, "CyberCoreChair")
    populate_cyber_chair(sc_builder, c2, ox=-4, oy=0, oz=0)

    c3 = sc_builder.add_model(sc_model, "FrostbiteIceThrone")
    populate_frostbite_throne(sc_builder, c3, ox=4, oy=0, oz=0)

    c4 = sc_builder.add_model(sc_model, "RoyalFootballThrone")
    populate_royal_throne(sc_builder, c4, ox=12, oy=0, oz=0)

    sc_builder.write_file(sc_root, "AllChairsShowcase.rbxmx")


# Generate SpawnAllChairsInStudio.luau
def generate_studio_luau_script():
    luau_code = """--!strict
--[[
    SpawnAllChairsInStudio.luau
    Usage:
      1. Open Roblox Studio.
      2. Paste this entire script into the Command Bar at the bottom of Studio and press Enter.
      3. A folder named 'ExportedChairs_Showcase' will immediately be created in Workspace
         containing all 4 chairs lined up side-by-side with full Seats, Particles, Lights, and Effects!
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local existing = Workspace:FindFirstChild("ExportedChairs_Showcase")
if existing then
    existing:Destroy()
end

-- Clean up any existing loose chair models in Workspace so they don't overlap / tertimpa
for _, oldName in { "CrimsonFlameChair", "Chair_crimson", "CrimsonChair", "Chair_cyber_core", "CyberCoreChair" } do
    local old = Workspace:FindFirstChild(oldName)
    if old then
        old:Destroy()
    end
end

local showcaseFolder = Instance.new("Folder")
showcaseFolder.Name = "ExportedChairs_Showcase"
showcaseFolder.Parent = Workspace

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, canCollide: boolean?, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = mat or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = if canCollide ~= nil then canCollide else false
    p.CastShadow = true
    if shape then
        p.Shape = shape
    end
    p.Parent = parent
    return p
end

local function makeSeat(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Seat
    local s = Instance.new("Seat")
    s.Name = name
    s.Size = size
    s.CFrame = cf
    s.Color = color
    s.Material = mat or Enum.Material.SmoothPlastic
    s.Anchored = true
    s.CanCollide = true
    s.CastShadow = true
    s.Parent = parent
    return s
end

-- ============================================================================
-- 1. CRIMSON FLAME CHAIR
-- ============================================================================
local function spawnCrimsonFlameChair(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "CrimsonFlameChair"
    model.Parent = showcaseFolder

    local cWood = Color3.fromRGB(150, 15, 25)
    local cLeg = Color3.fromRGB(110, 10, 20)
    local cIron = Color3.fromRGB(30, 24, 28)
    local cGem = Color3.fromRGB(255, 40, 50)

    local seat = makeSeat(model, "Seat", Vector3.new(4, 0.7, 4), cfBase * CFrame.new(0, 2.85, 0), cWood, Enum.Material.WoodPlanks)
    model.PrimaryPart = seat

    local glow = Instance.new("PointLight")
    glow.Name = "SeatGlow"
    glow.Color = Color3.fromRGB(255, 40, 40)
    glow.Brightness = 2
    glow.Range = 14
    glow.Parent = seat

    local legOffsets = {
        FL = Vector3.new(-1.6, 1.25, -1.6),
        FR = Vector3.new( 1.6, 1.25, -1.6),
        BL = Vector3.new(-1.6, 1.25,  1.6),
        BR = Vector3.new( 1.6, 1.25,  1.6),
    }

    local legCaps = {}
    for tag, offset in legOffsets do
        makePart(model, "Leg_" .. tag, Vector3.new(0.8, 2.5, 0.8), cfBase * CFrame.new(offset), cLeg, Enum.Material.WoodPlanks, true)
        local cap = makePart(model, "LegCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(offset.X, 0.25, offset.Z), cIron, Enum.Material.Slate, false)
        legCaps[tag] = cap

        local att = Instance.new("Attachment")
        att.Name = "FireAtt"
        att.Parent = cap
        local fire = Instance.new("ParticleEmitter")
        fire.Name = "FireEmitter"
        fire.Texture = "rbxassetid://253188732"
        fire.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(120, 0, 10))
        fire.LightEmission = 1
        fire.Size = NumberSequence.new(1.8, 0)
        fire.Lifetime = NumberRange.new(0.8, 1.4)
        fire.Rate = 20
        fire.Speed = NumberRange.new(2, 4)
        fire.Acceleration = Vector3.new(0, 5, 0)
        fire.Parent = att

        makePart(model, "Gem_LegCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(offset.X, 0.25, offset.Z - 0.49) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
    end

    for _, tag in { "Left", "Right" } do
        local px = if tag == "Left" then -1.6 else 1.6
        makePart(model, "Post_" .. tag, Vector3.new(0.8, 5, 0.8), cfBase * CFrame.new(px, 5.7, 1.6), cWood, Enum.Material.WoodPlanks, true)
        local cap = makePart(model, "PostCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(px, 8.2, 1.6), cIron, Enum.Material.Slate, false)

        local att = Instance.new("Attachment")
        att.Parent = cap
        local fire = Instance.new("ParticleEmitter")
        fire.Texture = "rbxassetid://253188732"
        fire.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(120, 0, 10))
        fire.LightEmission = 1
        fire.Size = NumberSequence.new(1.8, 0)
        fire.Lifetime = NumberRange.new(0.8, 1.4)
        fire.Rate = 24
        fire.Speed = NumberRange.new(2, 4)
        fire.Acceleration = Vector3.new(0, 5, 0)
        fire.Parent = att

        makePart(model, "Gem_PostCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(px, 8.2, 1.11) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
    end

    makePart(model, "BackrestPanel", Vector3.new(3.2, 4.4, 0.4), cfBase * CFrame.new(0, 5.7, 1.6), cWood, Enum.Material.WoodPlanks, true)

    for tag, d in { FL = { -1, -1 }, FR = { 1, -1 }, BL = { -1, 1 }, BR = { 1, 1 } } do
        local cx, cz = d[1], d[2]
        makePart(model, "BracketX_" .. tag, Vector3.new(0.85, 0.12, 0.28), cfBase * CFrame.new(cx * 1.575, 3.26, cz * 1.86), cIron, Enum.Material.Slate)
        makePart(model, "BracketZ_" .. tag, Vector3.new(0.28, 0.12, 0.85), cfBase * CFrame.new(cx * 1.86, 3.26, cz * 1.575), cIron, Enum.Material.Slate)
        makePart(model, "Gem_Corner_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(cx * 1.80, 3.32, cz * 1.80) * CFrame.Angles(math.rad(90), math.rad(45), 0), cGem, Enum.Material.Neon)
    end

    local hl = Instance.new("Highlight")
    hl.Name = "FlameHighlight"
    hl.OutlineColor = Color3.fromRGB(255, 60, 50)
    hl.OutlineTransparency = 1
    hl.FillColor = Color3.fromRGB(200, 20, 30)
    hl.FillTransparency = 0.95
    hl.Adornee = model
    hl.Parent = model

    local scr = Instance.new("Script")
    scr.Source = [[
local TweenService = game:GetService("TweenService")
local model = script.Parent
local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
for _, desc in ipairs(model:GetDescendants()) do
    if desc:IsA("BasePart") and desc.Name:find("Gem") then
        desc.Color = Color3.fromRGB(153, 24, 30)
        TweenService:Create(desc, info, { Color = Color3.fromRGB(255, 40, 50) }):Play()
    end
end
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- 2. CYBER CORE CHAIR
-- ============================================================================
local function spawnCyberCoreChair(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "CyberCoreChair"
    model.Parent = showcaseFolder

    local cMetal = Color3.fromRGB(18, 20, 32)
    local cCap = Color3.fromRGB(35, 40, 60)
    local cCyan = Color3.fromRGB(0, 255, 240)
    local cMagenta = Color3.fromRGB(255, 0, 200)

    local seat = makeSeat(model, "Seat", Vector3.new(4, 0.7, 4), cfBase * CFrame.new(0, 2.85, 0), cMetal, Enum.Material.Metal)
    model.PrimaryPart = seat

    makePart(model, "SeatCircuitX1", Vector3.new(3.8, 0.08, 0.12), cfBase * CFrame.new(0, 3.22, -1.8), cCyan, Enum.Material.Neon)
    makePart(model, "SeatCircuitX2", Vector3.new(3.8, 0.08, 0.12), cfBase * CFrame.new(0, 3.22,  1.8), cCyan, Enum.Material.Neon)
    makePart(model, "SeatCircuitZ1", Vector3.new(0.12, 0.08, 3.6), cfBase * CFrame.new(-1.8, 3.22, 0), cMagenta, Enum.Material.Neon)
    makePart(model, "SeatCircuitZ2", Vector3.new(0.12, 0.08, 3.6), cfBase * CFrame.new( 1.8, 3.22, 0), cMagenta, Enum.Material.Neon)
    makePart(model, "SeatChipCenter", Vector3.new(1.2, 0.06, 1.2), cfBase * CFrame.new(0, 3.22, 0) * CFrame.Angles(0, math.rad(45), 0), cCyan, Enum.Material.Neon)

    for tag, d in { FL = { -1.6, -1.6 }, FR = { 1.6, -1.6 }, BL = { -1.6, 1.6 }, BR = { 1.6, 1.6 } } do
        local lx, lz = d[1], d[2]
        makePart(model, "Leg_" .. tag, Vector3.new(0.8, 2.5, 0.8), cfBase * CFrame.new(lx, 1.25, lz), cMetal, Enum.Material.Metal, true)
        makePart(model, "LegTrace_" .. tag, Vector3.new(0.12, 2.4, 0.12), cfBase * CFrame.new(lx, 1.25, lz - 0.38), cCyan, Enum.Material.Neon)
        local cap = makePart(model, "LegCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(lx, 0.25, lz), cCap, Enum.Material.Metal, false)
        
        local pl = Instance.new("PointLight")
        pl.Color = cMagenta
        pl.Brightness = 1.5
        pl.Range = 8
        pl.Parent = cap

        makePart(model, "Gem_LegCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(lx, 0.25, lz - 0.49) * CFrame.Angles(0, 0, math.rad(45)), cMagenta, Enum.Material.Neon)
    end

    for _, tag in { "Left", "Right" } do
        local px = if tag == "Left" then -1.6 else 1.6
        makePart(model, "Post_" .. tag, Vector3.new(0.8, 5, 0.8), cfBase * CFrame.new(px, 5.7, 1.6), cMetal, Enum.Material.Metal, true)
        makePart(model, "PostTrace_" .. tag, Vector3.new(0.12, 4.8, 0.12), cfBase * CFrame.new(px, 5.7, 1.18), cMagenta, Enum.Material.Neon)
        local cap = makePart(model, "PostCap_" .. tag, Vector3.new(0.95, 0.5, 0.95), cfBase * CFrame.new(px, 8.2, 1.6), cCap, Enum.Material.Metal, false)

        local pl = Instance.new("PointLight")
        pl.Color = cCyan
        pl.Brightness = 1.5
        pl.Range = 8
        pl.Parent = cap

        makePart(model, "Gem_PostCap_" .. tag, Vector3.new(0.24, 0.24, 0.08), cfBase * CFrame.new(px, 8.2, 1.11) * CFrame.Angles(0, 0, math.rad(45)), cCyan, Enum.Material.Neon)
    end

    makePart(model, "BackrestPanel", Vector3.new(3.2, 4.4, 0.4), cfBase * CFrame.new(0, 5.7, 1.6), cMetal, Enum.Material.Metal, true)

    local hexR = 0.85
    for i = 0, 5 do
        local rad = math.rad(i * 60)
        local hx = math.cos(rad) * hexR
        local hy = math.sin(rad) * hexR
        makePart(model, "HexStrut_" .. i, Vector3.new(0.45, 0.10, 0.12), cfBase * CFrame.new(hx, 5.7 + hy, 1.36) * CFrame.Angles(0, 0, rad + math.rad(30)), cMagenta, Enum.Material.Neon)
    end

    local core = makePart(model, "EnergyCore", Vector3.new(0.8, 0.8, 0.8), cfBase * CFrame.new(0, 5.7, 1.35) * CFrame.Angles(math.rad(45), math.rad(45), 0), cCyan, Enum.Material.Neon)
    local coreLight = Instance.new("PointLight")
    coreLight.Color = cCyan
    coreLight.Brightness = 3
    coreLight.Range = 16
    coreLight.Parent = core

    local sparksAtt = Instance.new("Attachment")
    sparksAtt.Parent = core
    local sparks = Instance.new("ParticleEmitter")
    sparks.Color = ColorSequence.new(cCyan, cMagenta)
    sparks.LightEmission = 1
    sparks.Size = NumberSequence.new(0.6, 0.1)
    sparks.Lifetime = NumberRange.new(0.8, 1.6)
    sparks.Rate = 20
    sparks.Speed = NumberRange.new(1.5, 3.5)
    sparks.Parent = sparksAtt

    local scr = Instance.new("Script")
    scr.Source = [[
local RunService = game:GetService("RunService")
local model = script.Parent
local core = model:FindFirstChild("EnergyCore")
local baseY = core and core.Position.Y or 5.7
local t = 0
RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    if core and core:IsA("BasePart") then
        core.CFrame = CFrame.new(core.Position.X, baseY + math.sin(t * 3) * 0.18, core.Position.Z) * CFrame.Angles(0, t * 1.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
    end
end)
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- 3. FROSTBITE ICE THRONE
-- ============================================================================
local function spawnFrostbiteThrone(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "FrostbiteIceThrone"
    model.Parent = showcaseFolder

    local cDeep = Color3.fromRGB(60, 150, 230)
    local cMain = Color3.fromRGB(120, 210, 255)
    local cGlow = Color3.fromRGB(160, 240, 255)
    local cSnow = Color3.fromRGB(245, 250, 255)
    local cGem = Color3.fromRGB(100, 235, 255)

    local seat = makeSeat(model, "Seat", Vector3.new(3.8, 0.7, 3.6), cfBase * CFrame.new(0, 2.5, 0), cDeep, Enum.Material.Glass)
    model.PrimaryPart = seat
    makePart(model, "SeatCushionRecess", Vector3.new(3.2, 0.25, 3.0), cfBase * CFrame.new(0, 2.88, 0.1), cMain, Enum.Material.Glass)

    for i = 0, 2 do
        local yOff = 2.2 - (i * 0.45)
        makePart(model, "Chevron_L_" .. i, Vector3.new(1.1, 0.28, 0.2), cfBase * CFrame.new(-0.55, yOff, -1.85) * CFrame.Angles(0, 0, math.rad(-22)), cGlow, Enum.Material.Neon)
        makePart(model, "Chevron_R_" .. i, Vector3.new(1.1, 0.28, 0.2), cfBase * CFrame.new( 0.55, yOff, -1.85) * CFrame.Angles(0, 0, math.rad(22)), cGlow, Enum.Material.Neon)
    end

    for tag, d in { FL = { -1.5, -1.4 }, FR = { 1.5, -1.4 }, BL = { -1.5, 1.4 }, BR = { 1.5, 1.4 } } do
        local lx, lz = d[1], d[2]
        makePart(model, "Leg_" .. tag, Vector3.new(0.8, 2.2, 0.8), cfBase * CFrame.new(lx, 1.1, lz), cDeep, Enum.Material.Glass, true)
        makePart(model, "FootBlock_" .. tag, Vector3.new(1.15, 0.75, 1.15), cfBase * CFrame.new(lx, 0.38, lz) * CFrame.Angles(0, math.rad(if tag:find("L") then 15 else -15), 0), cMain, Enum.Material.Glass)
    end

    for _, tag in { "Left", "Right" } do
        local ax = if tag == "Left" then -1.9 else 1.9
        makePart(model, "ArmrestPillar_" .. tag, Vector3.new(0.85, 1.8, 0.85), cfBase * CFrame.new(ax, 1.7, -1.2), cDeep, Enum.Material.Glass, true)
        makePart(model, "Armrest_" .. tag, Vector3.new(0.85, 0.85, 3.2), cfBase * CFrame.new(ax, 3.4, 0), cDeep, Enum.Material.Glass, true)
        makePart(model, "SnowCap_" .. tag, Vector3.new(0.95, 0.28, 3.2), cfBase * CFrame.new(ax, 3.85, 0), cSnow, Enum.Material.SmoothPlastic)
        for ic = 0, 3 do
            makePart(model, "Icicle_" .. tag .. "_" .. ic, Vector3.new(0.12, 0.55, 0.12), cfBase * CFrame.new(ax, 2.75 - ic * 0.05, -1.2 + ic * 0.8), cGlow, Enum.Material.Glass)
        end
    end

    makePart(model, "BackrestSlab", Vector3.new(3.4, 5.2, 0.6), cfBase * CFrame.new(0, 5.1, 1.5), cDeep, Enum.Material.Glass, true)

    for i = 0, 4 do
        local yOff = 3.8 + (i * 0.75)
        local w = 1.6 - (i * 0.18)
        makePart(model, "BackChevron_L_" .. i, Vector3.new(w, 0.32, 0.18), cfBase * CFrame.new(-w * 0.45, yOff, 1.18) * CFrame.Angles(0, 0, math.rad(-26)), cMain, Enum.Material.Glass)
        makePart(model, "BackChevron_R_" .. i, Vector3.new(w, 0.32, 0.18), cfBase * CFrame.new( w * 0.45, yOff, 1.18) * CFrame.Angles(0, 0, math.rad(26)), cMain, Enum.Material.Glass)
    end

    local shardConfigs = {
        { -2.2, 4.0, -32, 0.48 },
        { -1.8, 4.8, -26, 0.52 },
        { -1.4, 5.6, -20, 0.55 },
        { -1.0, 6.2, -14, 0.58 },
        { -0.5, 6.8,  -7, 0.60 },
        {  0.0, 7.4,   0, 0.64 },
        {  0.5, 6.8,   7, 0.60 },
        {  1.0, 6.2,  14, 0.58 },
        {  1.4, 5.6,  20, 0.55 },
        {  1.8, 4.8,  26, 0.52 },
        {  2.2, 4.0,  32, 0.48 },
    }
    for idx, cfg in ipairs(shardConfigs) do
        local sx, sh, srot, sw = cfg[1], cfg[2], cfg[3], cfg[4]
        makePart(model, "CrystalShard_" .. idx, Vector3.new(sw, sh, sw), cfBase * CFrame.new(sx, 5.2 + sh * 0.45, 1.65) * CFrame.Angles(0, 0, math.rad(srot)), cGlow, Enum.Material.Neon)
    end

    local gem = makePart(model, "TopDiamondGem", Vector3.new(1.2, 1.8, 0.8), cfBase * CFrame.new(0, 8.8, 1.45) * CFrame.Angles(0, 0, math.rad(45)), cGem, Enum.Material.Neon)
    local pl = Instance.new("PointLight")
    pl.Color = Color3.fromRGB(140, 230, 255)
    pl.Brightness = 2.5
    pl.Range = 16
    pl.Parent = gem

    local mistAtt = Instance.new("Attachment")
    mistAtt.Parent = gem
    local mist = Instance.new("ParticleEmitter")
    mist.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255), Color3.fromRGB(255, 255, 255))
    mist.LightEmission = 0.8
    mist.Size = NumberSequence.new(1.2, 0.2)
    mist.Lifetime = NumberRange.new(1.0, 2.5)
    mist.Rate = 12
    mist.Speed = NumberRange.new(0.8, 2.0)
    mist.Parent = mistAtt

    local scr = Instance.new("Script")
    scr.Source = [[
local TweenService = game:GetService("TweenService")
local model = script.Parent
local topGem = model:FindFirstChild("TopDiamondGem")
if topGem and topGem:IsA("BasePart") then
    local tw = TweenService:Create(topGem, TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Color = Color3.fromRGB(180, 250, 255)
    })
    tw:Play()
end
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- 4. ROYAL FOOTBALL THRONE
-- ============================================================================
local function spawnRoyalFootballThrone(cfBase: CFrame): Model
    local model = Instance.new("Model")
    model.Name = "RoyalFootballThrone"
    model.Parent = showcaseFolder

    local cGold = Color3.fromRGB(255, 195, 30)
    local cVelvet = Color3.fromRGB(180, 20, 32)
    local cDarkUnderside = Color3.fromRGB(30, 24, 22)
    local cRuby = Color3.fromRGB(255, 30, 50)
    local cWhite = Color3.fromRGB(255, 255, 255)
    local cBlack = Color3.fromRGB(20, 20, 22)

    for _, tag in { "Left", "Right" } do
        local bx = if tag == "Left" then -1.9 else 1.9
        makePart(model, "FootSlab_" .. tag, Vector3.new(1.8, 0.6, 3.2), cfBase * CFrame.new(bx, 0.3, 0), cGold, Enum.Material.SmoothPlastic, true)
        makePart(model, "Pillar_" .. tag, Vector3.new(1.4, 1.8, 2.4), cfBase * CFrame.new(bx, 1.5, 0), cGold, Enum.Material.SmoothPlastic, true)
        makePart(model, "PillarRedPanel_" .. tag, Vector3.new(1.1, 1.4, 0.05), cfBase * CFrame.new(bx, 1.5, -1.23), cVelvet, Enum.Material.SmoothPlastic)
    end
    makePart(model, "UndersideHollow", Vector3.new(2.2, 1.6, 2.6), cfBase * CFrame.new(0, 1.4, 0), cDarkUnderside, Enum.Material.SmoothPlastic)

    makePart(model, "SeatFrame", Vector3.new(3.6, 0.6, 3.2), cfBase * CFrame.new(0, 2.5, 0), cGold, Enum.Material.SmoothPlastic)
    local seat = makeSeat(model, "Seat", Vector3.new(3.2, 0.8, 2.8), cfBase * CFrame.new(0, 2.9, 0.1), cVelvet, Enum.Material.SmoothPlastic)
    model.PrimaryPart = seat

    local pl = Instance.new("PointLight")
    pl.Color = Color3.fromRGB(255, 210, 90)
    pl.Brightness = 2.5
    pl.Range = 16
    pl.Parent = seat

    makePart(model, "FrontDiamondFrame", Vector3.new(1.4, 1.4, 0.15), cfBase * CFrame.new(0, 2.5, -1.65) * CFrame.Angles(0, 0, math.rad(45)), cGold, Enum.Material.SmoothPlastic)
    makePart(model, "FrontRubyGem", Vector3.new(0.7, 0.7, 0.22), cfBase * CFrame.new(0, 2.5, -1.72) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

    for _, tag in { "Left", "Right" } do
        local ax = if tag == "Left" then -2.2 else 2.2
        makePart(model, "Armrest_" .. tag, Vector3.new(1.3, 1.4, 3.0), cfBase * CFrame.new(ax, 3.7, 0), cGold, Enum.Material.SmoothPlastic, true)
        makePart(model, "ArmrestPanel_" .. tag, Vector3.new(0.9, 1.0, 0.05), cfBase * CFrame.new(ax, 3.7, -1.53), cVelvet, Enum.Material.SmoothPlastic)
        makePart(model, "ArmrestGem_" .. tag, Vector3.new(0.35, 0.35, 0.08), cfBase * CFrame.new(ax, 3.7, -1.58) * CFrame.Angles(0, 0, math.rad(45)), cGold, Enum.Material.SmoothPlastic)
    end

    makePart(model, "BackrestFrame", Vector3.new(4.4, 6.2, 0.8), cfBase * CFrame.new(0, 6.0, 1.4), cGold, Enum.Material.SmoothPlastic, true)
    makePart(model, "WingSpike_Left", Vector3.new(1.2, 1.8, 0.6), cfBase * CFrame.new(-2.4, 8.8, 1.4) * CFrame.Angles(0, 0, math.rad(35)), cGold, Enum.Material.SmoothPlastic)
    makePart(model, "WingSpike_Right", Vector3.new(1.2, 1.8, 0.6), cfBase * CFrame.new( 2.4, 8.8, 1.4) * CFrame.Angles(0, 0, math.rad(-35)), cGold, Enum.Material.SmoothPlastic)

    makePart(model, "QuiltedPanel", Vector3.new(3.2, 4.8, 0.5), cfBase * CFrame.new(0, 5.6, 1.1), cVelvet, Enum.Material.SmoothPlastic)
    for row = 0, 2 do
        for col = 0, 2 do
            local bx = (col - 1) * 0.95
            local by = 4.4 + row * 1.15
            makePart(model, "TuftButton_" .. row .. "_" .. col, Vector3.new(0.35, 0.35, 0.35), cfBase * CFrame.new(bx, by, 0.82), cGold, Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
        end
    end

    makePart(model, "EmblemRing", Vector3.new(2.8, 2.8, 0.4), cfBase * CFrame.new(0, 7.6, 1.15) * CFrame.Angles(0, 0, math.rad(45)), cGold, Enum.Material.SmoothPlastic)
    makePart(model, "SoccerBall", Vector3.new(2.1, 2.1, 2.1), cfBase * CFrame.new(0, 7.6, 1.15), cWhite, Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
    makePart(model, "Pentagon_Center", Vector3.new(0.55, 0.55, 0.1), cfBase * CFrame.new(0, 7.6, 0.08) * CFrame.Angles(0, 0, math.rad(36)), cBlack, Enum.Material.SmoothPlastic)

    local crownPeaks = {
        { -1.2, 0.8, -18 },
        { -0.6, 1.2,  -9 },
        {  0.0, 1.7,   0 },
        {  0.6, 1.2,   9 },
        {  1.2, 0.8,  18 },
    }
    for idx, cfg in ipairs(crownPeaks) do
        local px, ph, prot = cfg[1], cfg[2], cfg[3]
        makePart(model, "CrownPeak_" .. idx, Vector3.new(0.55, ph, 0.45), cfBase * CFrame.new(px, 9.3 + ph * 0.4, 1.15) * CFrame.Angles(0, 0, math.rad(prot)), cGold, Enum.Material.SmoothPlastic)
    end
    makePart(model, "CrownRubyGem", Vector3.new(0.55, 0.55, 0.25), cfBase * CFrame.new(0, 9.9, 0.92) * CFrame.Angles(0, 0, math.rad(45)), cRuby, Enum.Material.Neon)

    for _, tag in { "Left", "Right" } do
        local bx = if tag == "Left" then -2.6 else 2.6
        makePart(model, "Banner_" .. tag, Vector3.new(0.7, 2.2, 0.08), cfBase * CFrame.new(bx, 6.2, 1.2), cVelvet, Enum.Material.SmoothPlastic)
        makePart(model, "BannerCrownEmblem_" .. tag, Vector3.new(0.4, 0.3, 0.04), cfBase * CFrame.new(bx, 6.6, 1.14), cGold, Enum.Material.Neon)
    end

    local spAtt = Instance.new("Attachment")
    spAtt.Parent = seat
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 180, 20))
    sparkles.LightEmission = 1
    sparkles.Size = NumberSequence.new(0.4, 0.08)
    sparkles.Lifetime = NumberRange.new(1.0, 2.5)
    sparkles.Rate = 10
    sparkles.Speed = NumberRange.new(0.6, 1.8)
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Parent = spAtt

    local scr = Instance.new("Script")
    scr.Source = [[
local TweenService = game:GetService("TweenService")
local model = script.Parent
local ruby = model:FindFirstChild("CrownRubyGem")
local frontRuby = model:FindFirstChild("FrontRubyGem")
local info = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
if ruby and ruby:IsA("BasePart") then
    TweenService:Create(ruby, info, { Color = Color3.fromRGB(255, 80, 100) }):Play()
end
if frontRuby and frontRuby:IsA("BasePart") then
    TweenService:Create(frontRuby, info, { Color = Color3.fromRGB(255, 80, 100) }):Play()
end
]]
    scr.Parent = model
    return model
end

-- ============================================================================
-- SPAWN ALL 4 CHAIRS SIDE-BY-SIDE
-- ============================================================================
print("✨ Spawning all 4 stylized chairs into Workspace...")
spawnCrimsonFlameChair(CFrame.new(-12, 0, 0))
spawnCyberCoreChair(CFrame.new(-4, 0, 0))
spawnFrostbiteThrone(CFrame.new(4, 0, 0))
spawnRoyalFootballThrone(CFrame.new(12, 0, 0))
print("✅ Successfully spawned all 4 chairs into Workspace.ExportedChairs_Showcase!")
"""
    out_script = os.path.join(OUTPUT_DIR, "SpawnAllChairsInStudio.luau")
    with open(out_script, "w", encoding="utf-8") as f:
        f.write(luau_code.strip() + "\n")
    print(f"Generated {out_script} ({os.path.getsize(out_script)} bytes)")


if __name__ == "__main__":
    export_all_rbxmx()
    generate_studio_luau_script()
    print("All exports completed successfully!")

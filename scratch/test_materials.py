import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)

def create_all_materials():
    mats = {}
    
    # 1. M_Leather_Black
    m_leather = bpy.data.materials.new("M_Leather_Black")
    m_leather.use_nodes = True
    nodes = m_leather.node_tree.nodes
    links = m_leather.node_tree.links
    nodes.clear()
    
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.028, 0.028, 0.035, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.28
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.5
        bsdf.inputs["Coat Roughness"].default_value = 0.15
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.3
        
    # Procedural fine noise bump
    tex_coord = nodes.new("ShaderNodeTexCoord")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 140.0
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.65
    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.005
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    
    # Edge sheen with Layer Weight
    lw = nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.25
    mix_col = nodes.new("ShaderNodeMix")
    mix_col.data_type = 'RGBA'
    mix_col.inputs["Factor"].default_value = 0.15
    mix_col.inputs[6].default_value = (0.028, 0.028, 0.035, 1.0)
    mix_col.inputs[7].default_value = (0.08, 0.08, 0.10, 1.0)
    links.new(lw.outputs["Facing"], mix_col.inputs["Factor"])
    links.new(mix_col.outputs[2], bsdf.inputs["Base Color"])
    
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mats["M_Leather_Black"] = m_leather

    # 2. M_Gold_Champagne (Frame)
    m_gold_champ = bpy.data.materials.new("M_Gold_Champagne")
    m_gold_champ.use_nodes = True
    nodes = m_gold_champ.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.91, 0.76, 0.42, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.30 # satin
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.3
    m_gold_champ.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mats["M_Gold_Champagne"] = m_gold_champ

    # 3. M_Gold_Bright (Caps, Buttons, Bezel, Plate)
    m_gold_bright = bpy.data.materials.new("M_Gold_Bright")
    m_gold_bright.use_nodes = True
    nodes = m_gold_bright.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (1.0, 0.84, 0.29, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.14
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.4
    m_gold_bright.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mats["M_Gold_Bright"] = m_gold_bright

    # 4. M_Burgundy_Leather (Bolster endcaps)
    m_burg = bpy.data.materials.new("M_Burgundy_Leather")
    m_burg.use_nodes = True
    nodes = m_burg.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.35, 0.05, 0.10, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.35
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.4
    m_burg.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mats["M_Burgundy_Leather"] = m_burg

    # 5. M_Stitch
    m_stitch = bpy.data.materials.new("M_Stitch")
    m_stitch.use_nodes = True
    nodes = m_stitch.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.85, 0.70, 0.40, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.60
    m_stitch.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mats["M_Stitch"] = m_stitch

    # 6. M_Diamond
    m_diamond = bpy.data.materials.new("M_Diamond")
    m_diamond.use_nodes = True
    nodes = m_diamond.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    if "Transmission Weight" in bsdf.inputs:
        bsdf.inputs["Transmission Weight"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.0
    bsdf.inputs["IOR"].default_value = 2.42
    bsdf.inputs["Emission Color"].default_value = (0.80, 0.95, 1.0, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 1.2
    m_diamond.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mats["M_Diamond"] = m_diamond

    return mats

mats = create_all_materials()
print("All 6 materials created successfully:", list(mats.keys()))

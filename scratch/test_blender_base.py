import bpy
import bmesh
import math
from mathutils import Vector, Matrix

# Clear existing objects
bpy.ops.wm.read_factory_settings(use_empty=True)

print("Factory settings loaded.")

import bpy
import bmesh
from mathutils import Vector

def test():
    bpy.ops.wm.read_homefile(use_empty=True)
    # Test vertical panel
    bm = bmesh.new()
    nx, nz = 3, 4
    w, h, depth = 0.8, 1.2, 0.08
    res = bmesh.ops.create_grid(bm, x_segments=nx, y_segments=nz, size=0.5)
    # Grid is on XY. Rotate mesh data to XZ so normals point +Y
    bmesh.ops.rotate(bm, cent=(0,0,0), matrix=bmesh.ops.bmesh_rotation_matrix_for_direction if hasattr(bmesh.ops, 'bmesh_rotation_matrix_for_direction') else None or Vector((0,0,0)), verts=bm.verts)
    bm.free()
    print("Test finished")

if __name__ == '__main__':
    test()

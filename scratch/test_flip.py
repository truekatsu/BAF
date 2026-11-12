import bpy
import math

def flip_chair_to_face_camera():
    # If the root VIPChair is rotated 180 degrees around Z, the entire chair faces -Y!
    chair = bpy.data.objects.get("VIPChair")
    if chair:
        chair.rotation_euler.z = math.radians(180)
        bpy.context.view_layer.update()
        print("Rotated VIPChair 180 deg")

if __name__ == "__main__":
    flip_chair_to_face_camera()

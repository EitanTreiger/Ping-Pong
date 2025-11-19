import numpy as np
from scipy.spatial.transform import Rotation
import math

def distance_to_table_midpoint(corners_px, focal_length_px, image_width, image_height):
    """
    Compute the 3D distance from camera to the midpoint of the far table edge.

    Parameters
    ----------
    corners_px : array-like of shape (4, 2)
        Pixel coordinates of table corners in this order:
        TL = far-left, TR = far-right, BL = near-left, BR = near-right.
        
    focal_length_px : float
        Focal length in pixels (fx = fy).
        
    image_width, image_height : int
        Dimensions of the image (for computing principal point).
    
    Returns
    -------
    float :
        Euclidean 3D distance from camera to midpoint of far edge.
    """

    # Table dimensions in meters (ITTF)
    TABLE_WIDTH = 1.525   # left-right
    TABLE_LENGTH = 2.740  # near-far
    
    corners_px = [corners_px["TL"], corners_px["TR"], corners_px["BL"], corners_px["BR"]]

    # Define real-world coordinates of table corners
    # Origin at near-left corner; X = width axis, Y = length axis
    P_world = np.array([
        [0,         TABLE_LENGTH, 0],  # TL (far-left)
        [TABLE_WIDTH, TABLE_LENGTH, 0],  # TR (far-right)
        [0,           0,            0],  # BL (near-left)
        [TABLE_WIDTH, 0,            0],  # BR (near-right)
    ], dtype=float)

    # Build intrinsic matrix K
    cx = image_width  / 2
    cy = image_height / 2

    K = np.array([
        [focal_length_px, 0,               cx],
        [0,               focal_length_px, cy],
        [0,               0,               1],
    ], dtype=float)

    # Extract image points
    P_img = np.hstack([corners_px, np.ones((4,1))])

    # ------- Compute homography H such that  K^{-1} * H maps world->image -------
    # Build matrix A for DLT
    A = []
    for (X, Y, _), (u, v, _) in zip(P_world, P_img):
        A.append([-X, -Y, -1, 0, 0, 0, u*X, u*Y, u])
        A.append([0, 0, 0, -X, -Y, -1, v*X, v*Y, v])
    A = np.array(A)

    # Solve Ah=0
    _, _, VT = np.linalg.svd(A)
    H = VT[-1].reshape(3, 3)

    # Replace H with normalized version so that R columns are unit-length afterwards
    H = H / H[-1, -1]

    # ------- Extract extrinsics from H -------
    # From:  H = K [ r1  r2  t ]
    K_inv = np.linalg.inv(K)
    E = K_inv @ H

    r1 = E[:, 0]
    r2 = E[:, 1]
    t  = E[:, 2]

    # Normalize rotation columns
    scale = 1.0 / np.linalg.norm(r1)
    r1 = r1 * scale
    r2 = r2 * scale
    t  = t  * scale
    r3 = np.cross(r1, r2)

    R = np.column_stack([r1, r2, r3])
    C = -R.T @ t  # Camera center in world coordinates

    # ------- Compute midpoint of far edge in world coordinates -------
    far_left  = P_world[0]
    far_right = P_world[1]
    midpoint  = 0.5 * (far_left + far_right)

    # ------- Distance from camera center to that midpoint -------
    dist = np.linalg.norm(midpoint - C)
    return dist

def distance_to_table_corners(corners_px, focal_length_px, image_width, image_height, q):
    midpoint_dist = corners_px, focal_length_px, image_width, image_height
    angles = Rotation.from_quat(q)
    target_pos = ((corners_px["TL"][0] + corners_px["TR"][0]) / 2, (corners_px["TL"][1] + corners_px["TR"][1]) / 2)
    screen_angle = calc_angle(target_pos, image_height, image_width, focal_length_px)
    midpoint_3pos = calc_position(screen_angle[0] + angles[0], screen_angle[1], screen_angle[2]) # guessing that x axis is the one that needs to be changed
    top_left = (midpoint_3pos[0])
    
def calc_angle(target, image_height, image_width, focal_length_px):
    """
    Compute the horizontal and vertical angles between the camera forward axis
    and a pixel location within the image.

    Returns:
        (horizontal_angle, vertical_angle)
        in radians
    """

    # Offset of the pixel relative to optical center
    offset_x_px = target[0] - image_width // 2
    offset_y_px = target[1] - image_height // 2  # this will be off is the principle point is not perfectly centered

    # Convert pixel offsets to angular offsets using pinhole camera geometry
    horizontal_angle = math.atan(offset_x_px / focal_length_px)
    vertical_angle   = math.atan(offset_y_px / focal_length_px)

    return horizontal_angle, vertical_angle

def calc_position(angle_x, angle_y, distance):
    dx = math.cos(angle_y) * math.cos(angle_x)
    dy = math.sin(angle_y)
    dz = math.cos(angle_y) * math.sin(angle_x)  # tbh idk why this works

    # Scale by distance
    x = distance * dx
    y = distance * dy
    z = distance * dz

    return x, y, z
    
import cv2
import numpy as np

import numpy as np
from scipy.spatial.transform import Rotation as R

def get_ground_point_full(distance, theta_x, theta_y, quaternion_xyzw, 
                          camera_mounting="BACK", screen_orientation="PORTRAIT"):
    """
    Calculates the ground-aligned (world) coordinates for a point, accounting for
    camera type and screen rotation.

    Args:
        distance (float): The scalar distance (magnitude) to the target.
        theta_x (float): Horizontal angle (in RADIANS) to the pixel.
        theta_y (float): Vertical angle (in RADIANS) to the pixel.
        quaternion_xyzw (list/np.array): Sensor's quaternion in [x, y, z, w] format.
        camera_mounting (str): "BACK" or "FRONT".
        screen_orientation (str): "PORTRAIT" or "LANDSCAPE".

    Returns:
        np.array: A 3D vector [x, y, z] of the point in the world frame.
    """
    
    # --- Step 1: Convert (d, angles) to a Camera-Frame Vector ---
    
    # [scaled_vec] is the point in the camera's local frame 
    # (+X right, +Y up, +Z forward).
    unscaled_vec = np.array([np.tan(theta_x), np.tan(theta_y), 1])
    norm = np.linalg.norm(unscaled_vec)
    scaled_vec = (unscaled_vec / norm) * distance
    
    x_cam, y_cam, z_cam = scaled_vec
    
    # --- Step 2: Map Camera-Frame to Sensor-Frame (Handles 90° Rotations) ---
    
    p_sensor_frame = np.zeros(3)
    
    if screen_orientation == "PORTRAIT":
        # Screen X maps to Sensor X (inverted), Screen Y maps to Sensor Y
        x_map, y_map = -x_cam, y_cam
    elif screen_orientation == "LANDSCAPE":
        # Screen X (horizontal) maps to Sensor Y. Screen Y (vertical) maps to Sensor -X.
        x_map, y_map = -y_cam, -x_cam # Assumes 90-degree CCW landscape
    else:
        raise ValueError("Invalid screen_orientation. Use 'PORTRAIT' or 'LANDSCAPE'.")
        
    if camera_mounting == "BACK":
        # Back camera points along Sensor -Z
        p_sensor_frame = np.array([x_map, y_map, -z_cam])
    elif camera_mounting == "FRONT":
        # Front camera points along Sensor +Z
        p_sensor_frame = np.array([x_map, y_map, z_cam])
    else:
        raise ValueError("Invalid camera_mounting. Use 'BACK' or 'FRONT'.")
    
    # --- Step 3: Rotate the Sensor-Frame Vector to World-Frame ---
    
    try:
        r = R.from_quat(quaternion_xyzw)
    except ValueError:
        raise ValueError("Quaternion must be in [x, y, z, w] format.")
        
    # Apply the INVERSE rotation (Sensor -> World)
    p_world_frame = r.inv().apply(p_sensor_frame)
    
    return p_world_frame


import numpy as np

def multilateration_4pts(pts, rs, sigmas=None, tol=1e-8, max_iter=20):
    """
    Weighted-least-squares multilateration using 4 noisy distance measurements.
    pts    : (4,3)
    rs     : (4,)
    sigmas : (4,) or scalar - uncertainty (std dev) of each distance reading.
    Returns:
        X_best : (3,) best-fit point
    """

    pts = np.asarray(pts, float)
    rs  = np.asarray(rs,  float)
    assert pts.shape == (4,3)
    assert rs.shape  == (4,)

    # Handle uncertainty input
    if sigmas is None:
        # assume equal weights
        sigmas = np.ones_like(rs)
    sigmas = np.asarray(sigmas, float)
    if sigmas.ndim == 0:
        sigmas = np.full(4, float(sigmas))
    assert sigmas.shape == (4,)

    # --- Step 1: Algebraic least squares ("linearized" multilateration)
    p1 = pts[0]
    A = np.zeros((3,3))
    b = np.zeros(3)
    for i in range(1,4):
        pi = pts[i]
        A[i-1] = 2*(pi - p1)
        b[i-1] = (pi@pi - rs[i]**2) - (p1@p1 - rs[0]**2)

    # Pseudoinverse (handles rank deficiency)
    U, S, Vt = np.linalg.svd(A)
    S_inv = np.array([1/s if s>tol else 0 for s in S])
    A_pinv = Vt.T @ np.diag(S_inv) @ U.T
    X0 = A_pinv @ b       # initial estimate

    # --- Step 2: Nonlinear refinement (Gauss–Newton)
    X = X0.copy()

    for it in range(max_iter):
        residuals = np.zeros(4)
        J = np.zeros((4,3))  # Jacobian

        for i, (pi, ri, si) in enumerate(zip(pts, rs, sigmas)):
            diff = X - pi
            dist = np.linalg.norm(diff)

            # Avoid division by zero
            if dist < 1e-12:
                dist = 1e-12

            residuals[i] = (dist - ri) / si

            # Jacobian row
            J[i] = (diff / dist) / si

        # Solve normal equations: (Jᵀ J) dx = -Jᵀ r
        lhs = J.T @ J
        rhs = -J.T @ residuals
        
        try:
            dx = np.linalg.solve(lhs, rhs)
        except np.linalg.LinAlgError:
            dx = np.linalg.lstsq(lhs, rhs, rcond=None)[0]

        X += dx

        if np.linalg.norm(dx) < 1e-10:
            break

    return X


def trilaterate_2d_4points(pts, distances):

    points = np.array(pts, dtype=float)
    distances = np.array(distances, dtype=float)
    if points.shape != (4, 2) or distances.shape != (4,):
        raise ValueError("Expected 4 points (4x2) and 4 distances (length 4).")

    # Use the first point as reference to linearize equations
    x1, y1 = points[0]
    r1 = distances[0]

    # Build linear equations of the form: A * [x, y] = b
    A = []
    b = []
    for i in range(1, 4):
        xi, yi = points[i]
        ri = distances[i]
        A.append([2 * (xi - x1), 2 * (yi - y1)])
        b.append(r1 ** 2 - ri ** 2 + xi ** 2 - x1 ** 2 + yi ** 2 - y1 ** 2)

    A = np.array(A)
    b = np.array(b)

    # Solve by least squares (even though for 3 eqns/2 unknowns it's slightly overdetermined)
    pos, _, _, _ = np.linalg.lstsq(A, b, rcond=None)
    return pos


def get_homography(src_pts):
    # pixels = 1 mm
    table_width_px = 2740
    table_length_px = 1525

    dst_pts = np.array([
        [0, 0],
        [table_width_px - 1, 0],
        [table_width_px - 1, table_length_px - 1],
        [0, table_length_px - 1]
    ], dtype=np.float32)


    H, status = cv2.findHomography(src_pts, dst_pts)
    return H
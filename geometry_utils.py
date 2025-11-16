import cv2
import numpy as np



def multilateration_4pts(pts, rs, tol=1e-8):

    pts = np.asarray(pts, dtype=float)
    rs = np.asarray(rs, dtype=float)
    assert pts.shape == (4,3)
    assert rs.shape == (4,)

    # Build A (3x3) and b (3,)
    p1 = pts[0]
    A = np.zeros((3,3))
    b = np.zeros(3)
    for i in range(1,4):
        pi = pts[i]
        A[i-1,:] = 2*(pi - p1)
        b[i-1] = (pi.dot(pi) - rs[i]**2) - (p1.dot(p1) - rs[0]**2)

    # SVD for stability (handles rank-deficient case)
    U, S, Vt = np.linalg.svd(A)
    rank = np.sum(S > tol)

    if rank == 3:
        # full rank: direct solution
        X = np.linalg.solve(A, b)
        return [X]
    else:
        # rank < 3: compute particular solution (min-norm) and nullspace
        # pseudoinverse solution
        A_pinv = Vt.T @ np.diag([ (1/s if s>tol else 0.0) for s in S ]) @ U.T
        X0 = A_pinv @ b   # particular solution (closest in least-squares)

        # nullspace basis vectors are rows of Vt corresponding to zero singular values
        nullspace = Vt[rank:].T   # shape (3, 3-rank)
        # For coplanar anchors rank==2 -> nullspace is (3,1)
        if nullspace.shape[1] == 0:
            return [X0]   # weird numerical edge-case: return particular

        n = nullspace[:,0]        # take the 1-D null vector
        n = n / np.linalg.norm(n)

        # Solve quadratic for t using the first sphere equation (i=1)
        # || X0 + t n - p1 ||^2 = r1^2
        d = X0 - p1
        a = n.dot(n)              # should be 1 after normalization
        bq = 2 * d.dot(n)
        c = d.dot(d) - rs[0]**2

        coeffs = (a, bq, c)
        disc = bq*bq - 4*a*c
        sols = []
        if disc < -tol:
            # no real solution — inconsistency (e.g. measurements incompatible)
            return []   # no real solutions
        elif disc < 0:
            # one (double) real root
            t = -bq / (2*a)
            sols.append(X0 + t*n)
        else:
            sqrtD = np.sqrt(max(disc,0.0))
            t1 = (-bq + sqrtD) / (2*a)
            t2 = (-bq - sqrtD) / (2*a)
            if (X0 + t1*n)[2] >= 0:
                sols.append(X0 + t1*n)
            if (X0 + t2 * n)[2] >= 0:
                sols.append(X0 + t2*n)
        return sols


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
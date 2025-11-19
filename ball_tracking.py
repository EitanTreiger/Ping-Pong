import cv2
import numpy as np
from matplotlib import pyplot as plt
import math
from geometry_utils import trilaterate_2d_4points, multilateration_4pts, get_homography, get_ground_point_full
from bounce_detection import find_robust_peaks


FEET_PER_METER = 3.28084
MM_PER_FT = 304.8

def simple_moving_average(data, window_size):
    weights = np.ones(window_size) / window_size
    sma = np.convolve(data, weights, mode='valid')
    return sma

def smooth_by_distance(frame_numbers, readings, sigma=5):
    frame_numbers = np.array(frame_numbers)
    readings = np.array(readings)
    
    full_frames = np.arange(frame_numbers.min(), frame_numbers.max() + 1)
    smoothed = np.zeros(len(full_frames))

    for j, f in enumerate(full_frames):
        d = np.abs(frame_numbers - f)
        weights = np.exp(-(d**2) / (2 * sigma**2))
        smoothed[j] = np.sum(weights * readings) / np.sum(weights)

    return full_frames, smoothed

class Tracker:
    def __init__(self, focal_length_px, image_size, table_points=None, confidence_threshold=0.8):
        self.confidence_threshold = confidence_threshold
        self.focal_length_px = focal_length_px
        self.table_points = table_points #Now a dictionary
        self.image_size = image_size
        self.prev_frame = None
        self.true_ball_diameter = 0.04 # this is in meters
        
        self.frame_index = 0
        self.recorded_sizes = []        # this really should be an object and not a bunch of lists
        self.recorded_distances = []    # but I tried refactoring it and got bored so oh well
        self.frame_numbers = []
        self.recorded_angles = []
        self.recorded_positions = []
        self.recorded_positions2d = []
        
    def set_distances(self):
        self.distances_to_cam = self.calc_corner_distances() # or whatever it needs to be... from a function maybe
        if self.distances_to_cam is not None:
            self.distances_to_cam_rearranged = self.dictionary_to_arranged_list(self.distances_to_cam) # ordered as top left, top right, bottom right, bottom left. (i.e. clockwise)
            self.corner_locations_mm_2d = self.calc_corners_pos()
            self.corner_locations_3d = np.array([
                [pt[0], pt[1], 0.0] for pt in self.corner_locations_mm_2d
            ])
            self.camera_pos = multilateration_4pts(self.corner_locations_3d, self.distances_to_cam_rearranged)[0]
        
    def set_table_points(self, table_points):
        self.table_points = table_points
        self.H = get_homography(self.dictionary_to_arranged_list(self.table_points))
        
    def reset_tracking(self):
        self.prev_frame = None
        self.frame_index = 0
        self.recorded_sizes = []
        self.recorded_distances = []
        self.frame_numbers = []
        self.recorded_angles = []
        self.recorded_positions = []
        self.recorded_positions2d = []
        
    def corner_calibration(self, no_ball, front_ball, back_ball):
        tracker = Tracker(self.focal_length_px, self.image_size, None)
        tracker.track(no_ball, calc_position=False)
        tracker.track(front_ball, calc_position=False)
        front_ball_dist = tracker.recorded_distances[-1] * MM_PER_FT
        tracker.track(no_ball, calc_position=False)
        tracker.track(back_ball, calc_position=False)
        back_ball_dist = tracker.recorded_distances[-1] * MM_PER_FT
        self.corner_distances = {"TL" : back_ball_dist, "TR" : back_ball_dist, "BL" : front_ball_dist, "BR" : front_ball_dist}
        
    def write_data(self, image, detection, score):
        '''for debugging purposes, annotates an image with detection'''
        image = image.copy()
        if not detection is None:
            if score > self.confidence_threshold:
                cv2.ellipse(image, detection, (0, 255, 0), 2)
            else:
                cv2.ellipse(image, detection, (0, 0, 255), 2)

            cv2.putText(image, f"Score: {score :.2f} Height: {detection[1][0] :.2f}, Width: {detection[1][1] :.2f}", (50, 80), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 4)
        else:
            cv2.putText(image, "No Detection", (50, 80), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 4)
        return image

        
    def detect_best_ellipse(self, binary_img, write_image=None):
        '''outputs resulting_image, best_ellipse, best_score'''

        # Normalize input
        if binary_img.dtype != np.uint8:
            img = (binary_img > 0).astype(np.uint8) * 255
        else:
            img = binary_img.copy()

        contours, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        best_score = -1
        best_ellipse = None

        for cont in contours:
            ellipse = self.safe_fit_ellipse(cont)
            if ellipse is None:
                continue

            area_score = self.ellipse_area_score(cont, ellipse)      # [0, 1]
            geom_score = self.ellipse_geometric_score(cont, ellipse) # ~[0, 1]

            final_score = 0.5 * area_score + 0.5 * geom_score

            if final_score > best_score:
                best_score = final_score
                best_ellipse = ellipse

        if not write_image is None:
            print("write image is", write_image)
            result = write_image

            if best_ellipse is not None:
                cv2.ellipse(result, best_ellipse, (0, 255, 0), 2)
                
            if best_score < self.confidence_threshold:
                cv2.ellipse(result, best_ellipse, (0, 0, 255), 2)
                
            return best_ellipse, best_score, result


        return best_ellipse, best_score
        
    
    def safe_fit_ellipse(self, cont):
        if len(cont) < 5:
            return None
        try:
            ellipse = cv2.fitEllipse(cont)
            (cx, cy), (ax1, ax2), angle = ellipse
            if (
                np.isnan(cx) or np.isnan(cy) or
                np.isnan(ax1) or np.isnan(ax2) or
                np.isnan(angle)
            ):
                return None
            return ellipse
        except cv2.error:
            return None


    def ellipse_area_score(self, cont, ellipse):
        (cx, cy), (ax1, ax2), angle = ellipse
        ellipse_area = np.pi * (ax1 / 2.0) * (ax2 / 2.0)
        contour_area = cv2.contourArea(cont)

        if contour_area <= 0 or ellipse_area <= 0:
            return 0.0
        
        if ax2 < 20:
            return 0.0  # the major axis should not be that small

        return min(contour_area, ellipse_area) / max(contour_area, ellipse_area)

    def ellipse_geometric_score(self, cont, ellipse):
        # Lower is better; convert to similarity score later
        (cx, cy), (ax1, ax2), angle = ellipse
        angle_rad = np.deg2rad(angle)

        R = np.array([
            [np.cos(angle_rad), -np.sin(angle_rad)],
            [np.sin(angle_rad),  np.cos(angle_rad)]
        ])

        errors = []
        for p in cont.reshape(-1, 2):
            v = p - np.array([cx, cy])
            v_rot = R.T @ v
            x, y = v_rot
            value = (x / (ax1 / 2))**2 + (y / (ax2 / 2))**2
            errors.append(abs(value - 1))

        avg_err = np.mean(errors)
        return 1.0 / (1.0 + avg_err)  # convert to similarity: high = good
    
    def preprocess(self, frame):
        if self.prev_frame is None:
            raise ("Cannot run preprocessing without a previous frame")
        
        lab_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2Lab)
        lab_frame[:, :, 0] = 0.5
        
        prev_lab = cv2.cvtColor(self.prev_frame, cv2.COLOR_BGR2Lab)
        prev_lab[:, :, 0] = 0.5
        
        frame_diff = cv2.absdiff(lab_frame, prev_lab)
        frame_diff[:, :, 0] = 0
        
        distances = frame_diff[:, :, 0] ** 2 + frame_diff[:, :, 1] ** 2
        pixels = np.where(distances > 10)
        threshold_arr = np.zeros((frame_diff.shape[0], frame_diff.shape[1]), dtype=np.uint8)
        threshold_arr[pixels] = distances[pixels[0], pixels[1]]
        
        return threshold_arr
    
    def track(self, frame, calc_position=True):
        '''automatically updates previous frame (be careful with that), also updates sizes, distances, frame_numbers'''
        if self.prev_frame is None:
            self.prev_frame = frame
            return None, 0

        threshold_arr = self.preprocess(frame)
        
        detection, score = self.detect_best_ellipse(threshold_arr)
        
        if score > self.confidence_threshold:
            size = detection[1][0]
            position = detection[0]
            self.recorded_positions2d.append((position[0], self.image_size[1] - position[1]))
            self.frame_numbers.append(self.frame_index)
            self.recorded_sizes.append(size)
            self.recorded_distances.append(self.calc_distance(size))
            self.recorded_angles.append(self.calc_angle(position))
            if calc_position:
                # self.recorded_positions.append(self.calc_position(self.recorded_angles[-1][0], self.recorded_angles[-1][1], self.recorded_distances[-1]))
                self.recorded_positions.append(self.calc_position(self.recorded_distances[-1], position))
            
            
        self.prev_frame = frame
        self.frame_index += 1
        
        return detection, score

    def calc_distance(self, observed_size):
        '''returns distance to ball in feet'''
        distance_m = self.focal_length_px * 0.04 / observed_size
        return distance_m * FEET_PER_METER
    
    def calc_angle(self, target):
        """
        Compute the horizontal and vertical angles between the camera forward axis
        and a pixel location within the image.

        Returns:
            (horizontal_angle, vertical_angle)
            in radians
        """

        # Offset of the pixel relative to optical center
        offset_x_px = target[0] - self.image_size[0] // 2
        offset_y_px = target[1] - self.image_size[1] // 2  # this will be off is the principle point is not perfectly centered

        # Convert pixel offsets to angular offsets using pinhole camera geometry
        horizontal_angle = math.atan(offset_x_px / self.focal_length_px)
        vertical_angle   = math.atan(offset_y_px / self.focal_length_px)

        return horizontal_angle, vertical_angle * -1 # yet unclear why the -1 is needed

    def dictionary_to_arranged_list(self, dict):
        # sorts points into correct order
        arranged = []
        
        order = ["TL", "TR", "BR", "BL"]
        
        for key in order:
            arranged.append(dict[key])

        return np.array(arranged)

    def transform_point(self, H, x, y):
        # turns points into a numpy array and applies the homography
        pt = np.array([x, y, 1.0])
        p2 = H @ pt
        return p2[0] / p2[2], p2[1] / p2[2]

    def line_through_2points_3d(self, P1, P2):
        # points get turned into numpy arrays
        P1 = np.array(P1, dtype=float)
        P2 = np.array(P2, dtype=float)

        direction = P2 - P1  # vector from P1 to P2

        # parametric function of the line
        def parametric(t):
            return P1 + t * direction

        return {
            'point': P1,
            'direction': direction,
            'parametric': parametric
        }

    def point_along_line_at_distance(self, line, start_point, distance):

        start_point = np.array(start_point, dtype=float)
        direction = np.array(line['direction'], dtype=float)

        # Normalize direction vector
        dir_norm = direction / np.linalg.norm(direction)

        # Compute new point
        new_point = start_point + distance * dir_norm
        return new_point

    def calc_corners_pos(self):
        corner_location_pxl = []
        # applies homography to the table corners to get real worls position in mm
        order = ["TL", "TR", "BR", "BL"]
        for key in order:
            pt = self.table_points[key]
            tbl_cnr_xy = self.transform_point(self.H, pt[0], pt[1])
            corner_location_pxl.append(np.array([tbl_cnr_xy[0], tbl_cnr_xy[1]]))

        return corner_location_pxl
    
    def calc_position(self, angle_x, angle_y, distance):
        dx = math.cos(angle_y) * math.cos(angle_x)
        dy = math.sin(angle_y)
        dz = math.cos(angle_y) * math.sin(angle_x)  # tbh idk why this works
    
        # Scale by distance
        x = distance * dx
        y = distance * dy
        z = distance * dz
    
        return x, y, z
    
    def calc_position(self, ball_distance_to_camera, ball_pos_pxl):

        # ball homography applied
        bxy = self.transform_point(self.H, ball_pos_pxl[0], ball_pos_pxl[1])
        ball_xy = np.array([bxy[0], bxy[1]])

        # distance of points to ball in mm
        corners_to_ball_distances = []

        # getting points location and distances using homograhpy
        for i in self.corner_locations_mm_2d:
            dist_px = np.linalg.norm(ball_xy - i)
            corners_to_ball_distances.append(dist_px)

        # ball position calculated and then turned into 3d with height 0 due to homography shift
        ball_pos_2d = trilaterate_2d_4points(self.corner_locations_mm_2d, corners_to_ball_distances)
        ball_pos = np.array([ball_pos_2d[0], ball_pos_2d[1], 0.0])

        # line from the camera to the homography ball position
        line = self.line_through_2points_3d(self.camera_pos, ball_pos)

        # returns the real 3d position of the ball in mm relative to top left corner (as of editing)
        return self.point_along_line_at_distance(line, self.camera_pos, ball_distance_to_camera)
        
    def smooth_values(self, sigma=10):
        full_frames, smooth_sizes = smooth_by_distance(self.frame_numbers, self.recorded_sizes, sigma=sigma)
        _, smooth_distances = smooth_by_distance(self.frame_numbers, self.recorded_distances, sigma=sigma)
        return full_frames, smooth_sizes, smooth_distances

    def calc_corner_distances(self):
        if self.corner_distances is None:
            raise Exception("Corner calibration not performed before attempting to access corner distances")
        return self.corner_distances
    
    def is_net_hit(self, x_pos):
        if abs(x_pos - 1369.5) < 300:
            return True
    
    def detect_events(self):
        positions_x = [pos[0] for pos in self.recorded_positions2d]
        positions_y = [pos[1] for pos in self.recorded_positions2d]
        
        hit_indices, x_smoothed, hit_properties = find_robust_peaks(positions_x, smooth_window_size=7, prominence=30, distance=10, peak_type='both')
        bounce_indices, y_smoothed, bounce_properties = find_robust_peaks(positions_y, smooth_window_size=7, prominence=20, distance=10, peak_type='min')
        
        bounce_indices = [b_index for b_index in bounce_indices if min([b_index - h_index for h_index in hit_indices]) > 10]
        is_net = [self.is_net_hit(x_smoothed[index]) for index in hit_indices]
        net_indices = [index for i, index in enumerate(hit_indices) if is_net[i]]
        hit_indices = [index for i, index in enumerate(hit_indices) if not is_net[i]]
        return {"hit_indices" : hit_indices, "bounce_indices" : bounce_indices, "net_indices" : net_indices}
import cv2
import numpy as np
from matplotlib import pyplot as plt
from scipy.interpolate import interp1d
from scipy.ndimage import uniform_filter1d

FEET_PER_METER = 3.28084

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
    def __init__(self, focal_length_px, confidence_threshold=0.8):
        self.confidence_threshold = confidence_threshold
        self.focal_length_px = focal_length_px
        self.prev_frame = None
        self.true_ball_diameter = 0.04 # this is in meters
        
        self.frame_index = 0
        self.recorded_sizes = []
        self.recorded_distances = []
        self.frame_numbers = []
        
    def reset_tracking(self):
        self.prev_frame = None
        self.frame_index = 0
        self.recorded_sizes = []
        self.recorded_distances = []
        self.frame_numbers = []
        
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
    
    def track(self, frame):
        '''automatically updates previous frame (be careful with that), also updates sizes, distances, frame_numbers'''
        if self.prev_frame is None:
            self.prev_frame = frame
            return None, 0

        threshold_arr = self.preprocess(frame)
        
        detection, score = self.detect_best_ellipse(threshold_arr)
        
        if score > self.confidence_threshold:
            size = detection[1][0]
            self.frame_numbers.append(self.frame_index)
            self.recorded_sizes.append(size)
            self.recorded_distances.append(self.calc_distance(size))
            
        self.prev_frame = frame
        self.frame_index += 1
        
        return detection, score

    def calc_distance(self, observed_size):
        '''returns distance to ball in feet'''
        distance_m = self.focal_length_px * 0.04 / observed_size
        return distance_m * FEET_PER_METER
    
    def smooth_values(self, sigma=10):
        full_frames, smooth_sizes = smooth_by_distance(self.frame_numbers, self.recorded_sizes, sigma=sigma)
        _, smooth_distances = smooth_by_distance(self.frame_numbers, self.recorded_distances, sigma=sigma)
        return full_frames, smooth_sizes, smooth_distances
    
    
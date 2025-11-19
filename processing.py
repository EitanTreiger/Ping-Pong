import numpy as np
from PIL import Image
from ball_tracking import Tracker
import cv2

def corner_points_to_dict(corner_points):
    sorted_by_y = corner_points[np.argsort(corner_points[:, 1])]
    
    top = sorted_by_y[:2]
    bottom = sorted_by_y[2:]

    top_left, top_right = top[np.argsort(top[:, 0])]
    bottom_left, bottom_right = bottom[np.argsort(bottom[:, 0])]

    return {"TL": top_left, "TR": top_right, "BR": bottom_left, "BL": bottom_right}

def process(video_dir, table_points):
    
    cap = cv2.VideoCapture(video_dir)
    ret, frame = cap.read()
    tracker = Tracker(image_size=frame.shape)
    table_points = corner_points_to_dict(table_points)
    tracker.set_table_points(table_points)
    
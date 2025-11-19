import numpy as np
from PIL import Image
from ball_tracking import Tracker
import cv2

class Event:
    def __init__(self, type, pos):
        self.type = type
        self.pos = pos

def corner_points_to_dict(corner_points):
    corner_points = np.array(corner_points)
    sorted_by_y = corner_points[np.argsort(corner_points[:, 1])]
    
    top = sorted_by_y[:2]
    bottom = sorted_by_y[2:]

    top_left, top_right = top[np.argsort(top[:, 0])]
    bottom_left, bottom_right = bottom[np.argsort(bottom[:, 0])]

    return {"TL": top_left, "TR": top_right, "BR": bottom_left, "BL": bottom_right}

def process(video_dir, table_points):
    
    cap = cv2.VideoCapture(video_dir)
    ret, frame = cap.read()
    tracker = Tracker(2000, image_size=frame.shape)
    table_points = corner_points_to_dict(table_points)
    tracker.set_table_points(table_points)
    
    i = 0
    while True:
        ret, current_frame = cap.read()
        i += 1
        print("processing frame", i, end="\r")
        if i < 0:
            continue
        if not ret or i >= 10000:
            break

        detection, score = tracker.track(current_frame, calc_position=False)
        
    cap.release()
    
    events = tracker.detect_events()
    
    table_positions_x = [pos[0] for pos in tracker.recorded_table_positions]
    table_positions_y = [pos[1] for pos in tracker.recorded_table_positions]
    
    hit_events = [{"frame_number" : index, "type" : "hit", "pos" : (table_positions_x[index], table_positions_y[index])} for index in events["hit_indices"]]
    net_events = [{"frame_number" : index, "type" : "net", "pos" : (table_positions_x[index], table_positions_y[index])} for index in events["net_indices"]]
    bounce_events = [{"frame_number" : index, "type" : "bounce", "pos" : (table_positions_x[index], table_positions_y[index])} for index in events["bounce_indices"]]
    
    event_points = (hit_events + net_events + bounce_events)
    event_points.sort(key=lambda x: x["frame_number"])
    
    print()
    for event_set in (hit_events, net_events, bounce_events):
        print(event_set)
    print("\n", event_points)
    
if __name__ == "__main__":
    process("downstairs1.mp4", table_points=[[5.5357483e+02, 7.1888324e+02], [2.2216523e+03, 7.6765741e+02], [2.7503645e+03, 1.1617529e+03], [1.4509678e+00, 1.0973710e+03]])
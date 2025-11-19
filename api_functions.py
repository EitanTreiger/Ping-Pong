import json
from flask import Flask, jsonify, request

from ball_tracking import Tracker
import numpy as np
from PIL import Image


app = Flask(__name__)

tracker = Tracker(focal_length_px=2000, image_size=(4000, 3000), table_points=None)


@app.post("/set_corners")
def update_corners():
    data = request.get_json()
    corners = data['corners']  # put these in order
    tracker.set_table_points(corners)
    
@app.post("/output_positions")
def output_position_data():
    return {"bounces" : tracker.bounce_positions, "hits" : tracker.hit_positions, "net_hits" : tracker.net_hit_positions} # each of these will probably be x_pos, y_pos, and speed

@app.post("/output_stats")
def calc_stats():
    pass

@app.post("/process_image")
def process_tracking():
    file = request.files.get("image")

    if not file:
        return {"error": "No image provided"}, 400

    img = Image.open(file.stream).convert("RGB")
    img_np = np.array(img)

    tracker.track(img_np)
    
@app.post("/process_image")   
def corner_points_to_dict(self, corner_points):
    sorted_by_y = corner_points[np.argsort(corner_points[:, 1])]
    
    top = sorted_by_y[:2]
    bottom = sorted_by_y[2:]

    top_left, top_right = top[np.argsort(top[:, 0])]
    bottom_left, bottom_right = bottom[np.argsort(bottom[:, 0])]

    return {"TL": top_left, "TR": top_right, "BR": bottom_left, "BL": bottom_right}


@app.route("/hello")
def hello():
    return {"message": "hello Pierre"}
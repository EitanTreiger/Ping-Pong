## Our Goal

1. Given video, track the ping pong ball across the screen.
2. Build a robust algorithm capable of overcoming motion blur and adverse lighting conditions.
3. From just one camera, estimate the ball's position in 3D space to allow for analysis of ball velocity and shot placement.
4. Provide replay features and statistics.

_(SwingVision provides similar functionality for tennis, we're building something similar for ping pong)_

## Ball Tracking Pipeline

1. Read image from camera
   <img width="2000" height="1125" alt="image" src="https://github.com/user-attachments/assets/a1e84627-2dff-4d2b-84a3-34c78205cd45" />
2. Convert image to CIELAB
   <img width="2000" height="1125" alt="image" src="https://github.com/user-attachments/assets/25c9770e-bd7c-4413-a5f8-d014dbf86bb1" />

3. Compute frame difference between current and previous frame
   <img width="2000" height="1125" alt="image" src="https://github.com/user-attachments/assets/fca5b410-147a-47fb-8ffb-4f6c8a0c0d75" />

4. Generate location proposals
   <img width="2000" height="1125" alt="image" src="https://github.com/user-attachments/assets/aecdcc84-854a-4e10-adf7-6036a714b1d0" />

5. Filter location proposals
  <video width="850" height="480" alt="video" src="https://github.com/user-attachments/assets/3992313a-630a-481b-bce5-cc21cd139be9" />

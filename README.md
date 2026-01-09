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
  <img width="850" height="480" alt="video" src="https://github.com/user-attachments/assets/3992313a-630a-481b-bce5-cc21cd139be9" />


## Distance Calculation

To determine the position of the ball in 3 dimmensional space we count the height of the ball in pixels, then use the known size of a ping pong ball along with the focal length of the camera to apply the following formula:
<img width="1122" height="298" alt="image" src="https://github.com/user-attachments/assets/3b99aad0-6fd2-427d-b760-075f450bc80d" />

While this theoretically allows us to calculate the distance to the ball to within a couple of inches, it also introduces a lot of noise into our data as a result of motion blur and variation in the tracking quality. As a result we need to apply robust smoothing and filtering in order to effecively use the data.

## Data Processing
First points with distnaces with greater than 1.5 standard deviations from the mean are thrown out, as these generally are eroneous detections. Further data is filtered out with a hampel filter. Finally the data is smoothed.

<img width="1352" height="1125" alt="image" src="https://github.com/user-attachments/assets/f30e4012-0f16-4fa4-8bcb-40406476c587" />

## Action Segmentation

Looking at the 2D data, we can identify when the ball flips direction on the x-axis (representing a hit) or changes direction on the y-axis (representing a bounce). 
<img width="1331" height="985" alt="image" src="https://github.com/user-attachments/assets/078f8e44-5a6d-4787-87e5-79f57e18d77a" />
_Red and green dots show where hits took place_

Then curves are fitted to the remaining data to extract speeds from the hits (not the bounces).
<img width="546" height="967" alt="image" src="https://github.com/user-attachments/assets/24805ec2-325e-4ab3-9ca9-d36dcc5ad488" />





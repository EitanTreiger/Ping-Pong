import cv2
import numpy as np
from matplotlib import pyplot as plt
import pandas as pd

import numpy as np
from scipy.signal import find_peaks
import matplotlib.pyplot as plt

def find_robust_peaks(data, smooth_window_size=11, prominence=0.5, distance=50, peak_type='min'):
    """
    Finds robust local minima (valleys), maxima (peaks), or both in a noisy 1D dataset.

    This function is designed to find significant "bounces" or "valleys"
    while ignoring minor fluctuations from noise.

    It works in two stages:
    1. Smooths the data using a simple moving average (SMA).
    2. Finds peaks in the *inverted* (for minima) or *regular* (for maxima)
       smoothed data, using 'prominence' to filter out insignificant peaks.

    Args:
        data (np.array): The 1D array of height values.
        smooth_window_size (int): The number of points to include in the moving average.
                                 Must be an odd number.
        prominence (float): The required prominence of a peak/minimum. This is the
                            most important parameter for filtering noise. It
                            measures how much the peak stands out from its
                            surrounding "shoulders".
        distance (int): The minimum number of data points between adjacent peaks/minima.
        peak_type (str): What to detect. Options are:
                         - 'min': Find local minima (default).
                         - 'max': Find local maxima.
                         - 'both': Find both minima and maxima.

    Returns:
        tuple: (indices, smoothed_data, properties)
            - indices (np.array or dict):
                - If 'min' or 'max', returns an array of detected indices.
                - If 'both', returns a dict: {'minima': [...], 'maxima': [...]}
            - smoothed_data (np.array): The smoothed version of the original data.
            - properties (dict):
                - If 'min' or 'max', returns the properties dict from `find_peaks`.
                - If 'both', returns a dict: {'minima': {...}, 'maxima': {...}}
    """
    if smooth_window_size % 2 == 0:
        print("Warning: smooth_window_size should be odd. Incrementing by 1.")
        smooth_window_size += 1
        
    if len(data) < smooth_window_size:
        print("Error: Data is shorter than the smoothing window.")
        return np.array([]), data

    window = np.ones(smooth_window_size) / smooth_window_size
    smoothed_data = np.convolve(data, window, mode='same')
    
    edge_width = (smooth_window_size - 1) // 2
    smoothed_data[:edge_width] = smoothed_data[edge_width]
    smoothed_data[-edge_width:] = smoothed_data[-edge_width-1]
    
    minima_indices, min_properties = np.array([]), {}
    maxima_indices, max_properties = np.array([]), {}

    if peak_type in ('min', 'both'):
        inverted_data = -smoothed_data
        minima_indices, min_properties = find_peaks(
            inverted_data, 
            prominence=prominence, 
            distance=distance
        )
    
    if peak_type in ('max', 'both'):
        maxima_indices, max_properties = find_peaks(
            smoothed_data, 
            prominence=prominence, 
            distance=distance
        )

    if peak_type == 'min':
        return minima_indices, smoothed_data, min_properties
    elif peak_type == 'max':
        return maxima_indices, smoothed_data, max_properties
    elif peak_type == 'both':
        return (
            {'minima': minima_indices, 'maxima': maxima_indices}, 
            smoothed_data, 
            {'minima': min_properties, 'maxima': max_properties}
        )
    else:
        print(f"Warning: Unknown peak_type '{peak_type}'. Defaulting to 'min'.")
        if not minima_indices.any() and peak_type not in ('min', 'both'):
             inverted_data = -smoothed_data
             minima_indices, min_properties = find_peaks(
                inverted_data, prominence=prominence, distance=distance
             )
        return minima_indices, smoothed_data, min_properties
    

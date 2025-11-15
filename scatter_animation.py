import numpy as np
import matplotlib
matplotlib.use("Agg")   # headless backend
import matplotlib.pyplot as plt
from matplotlib.backends.backend_agg import FigureCanvasAgg
import cv2

def video_scatters(
        xy_list,
        out_path="scatter_multi.mp4",
        fps=20,
        figsize=(12, 4),
        point_size=40,
        trail_color="tab:blue",
        current_color="red",
        freeze_sec=1,
        titles=None,
        is_square: list[bool]=None
    ):
    """
    Create a video where multiple scatter plots are built point-by-point,
    each in its own subplot.

    Parameters
    ----------
    xy_list : list of (x_array, y_array)
        Each pair becomes one subplot.
    titles : list of strings or None
        Titles for each subplot. If None or too short, missing titles are auto-filled.
    """

    # Validate inputs
    if not xy_list:
        raise ValueError("xy_list must contain at least one (x, y) pair")

    num_plots = len(xy_list)

    # Handle titles
    if titles is None:
        titles = [f"Plot {i+1}" for i in range(num_plots)]
    else:
        titles = list(titles)
        # pad missing titles
        while len(titles) < num_plots:
            titles.append(f"Plot {len(titles)+1}")

    # Convert data + find max length
    xs, ys = [], []
    max_len = 0
    for (x, y) in xy_list:
        x = np.asarray(x)
        y = np.asarray(y)
        if x.shape != y.shape:
            raise ValueError("Each (x, y) pair must have equal shape")
        xs.append(x)
        ys.append(y)
        max_len = max(max_len, len(x))

    # --- Matplotlib figure ---
    fig = plt.Figure(figsize=figsize)
    canvas = FigureCanvasAgg(fig)
    axes = fig.subplots(1, num_plots)

    if num_plots == 1:
        axes = [axes]

    # Precompute limits per subplot
    limits = []
    for i in range(num_plots):
        x = xs[i]
        y = ys[i]
        xmin, xmax = np.min(x), np.max(x)
        ymin, ymax = np.min(y), np.max(y)
        xpad = (xmax - xmin) * 0.05 + 1e-9
        ypad = (ymax - ymin) * 0.05 + 1e-9
        limits.append((xmin - xpad, xmax + xpad, ymin - ypad, ymax + ypad))

    canvas.draw()
    w, h = canvas.get_width_height()
    w, h = int(w), int(h)

    # --- OpenCV writer ---
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(out_path, fourcc, fps, (w, h))

    # Convert canvas buffer → OpenCV BGR frame
    def canvas_to_bgr(canvas):
        if hasattr(canvas, "tostring_rgb"):
            arr = np.frombuffer(canvas.tostring_rgb(), dtype=np.uint8)
            rgb = arr.reshape((h, w, 3))
        else:
            arr = np.frombuffer(canvas.tostring_argb(), dtype=np.uint8)
            arr = arr.reshape((h, w, 4))
            rgb = arr[:, :, [1, 2, 3]]  # ARGB → RGB
        return rgb[:, :, ::-1]  # RGB → BGR

    last_frame = None

    # --- Animation loop ---
    for frame_idx in range(max_len):
        for i, ax in enumerate(axes):
            ax.clear()
            xmin, xmax, ymin, ymax = limits[i]
            ax.set_xlim(xmin, xmax)
            ax.set_ylim(ymin, ymax)
            ax.grid(True, alpha=0.4)
            ax.set_title(titles[i])
            if is_square is not None and is_square[i]:
                ax.set_aspect('equal')

            x = xs[i]
            y = ys[i]
            n = len(x)

            # Trail
            if frame_idx > 0:
                upto = min(frame_idx, n)
                ax.scatter(x[:upto-1], y[:upto-1],
                           s=point_size, color=trail_color, alpha=0.7)

            # Current point
            if frame_idx < n:
                ax.scatter([x[frame_idx]], [y[frame_idx]],
                           s=point_size * 1.3,
                           color=current_color,
                           edgecolors="black")

        canvas.draw()
        frame_bgr = canvas_to_bgr(canvas)
        writer.write(frame_bgr)
        last_frame = frame_bgr

    # --- Freeze last frame ---
    if last_frame is not None:
        for _ in range(int(fps * freeze_sec)):
            writer.write(last_frame)

    writer.release()
    plt.close(fig)
    return out_path

if __name__ == "__main__":
    plots = [
        (np.cumsum(np.random.randn(100)),
        np.cumsum(np.random.randn(100))),

        (np.random.randn(150),
        np.random.randn(150)),

        (np.sin(np.linspace(0, 4*np.pi, 120)),
        np.cos(np.linspace(0, 4*np.pi, 120)))
    ]

    titles = ["Random Walk", "Gaussian Scatter", "Circle"]

    video_scatters(plots, out_path="multi.mp4", titles=titles)

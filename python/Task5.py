import serial
import time
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import find_peaks

def receive_data(port, baudrate, num_bytes=256, timeout=1):
    ser = serial.Serial(port, baudrate=baudrate, timeout=timeout)
    time.sleep(2)
    print(f"Opened {port}, expecting {num_bytes} bytes...")

    received = []
    try:
        while len(received) < num_bytes:
            rx = ser.read(size=1)
            if rx:
                val = rx[0]
                received.append(val)
                print(f"Received: {val:3d}")
            else:
                print("[Timeout] No data received.")
    except KeyboardInterrupt:
        print("Interrupted by user.")

    ser.close()
    print(f"Completed: received {len(received)} bytes.")
    return received

def save_to_csv(data, filename="received_only_output.csv"):
    df = pd.DataFrame(data, columns=["Received"])
    df.to_csv(filename, index=False)
    print(f"Saved to {filename}")

def load_original_csv(filename="uart_ready_output.csv"):
    try:
        df = pd.read_csv(filename)
        time_vals = df.iloc[:, 0].values
        values = df.iloc[:, 1].values
        return time_vals, values
    except FileNotFoundError:
        raise FileNotFoundError(f"Original CSV file '{filename}' not found.")
def plot_index_comparison(original_vals, received_vals):
    plt.figure(figsize=(12, 4))
    
    plt.plot(original_vals, label='Original Signal', color='red', linestyle='--')
    plt.plot(received_vals, label='Received Signal', color='blue')

    plt.title("Original vs Received Signal (Index Axis)")
    plt.xlabel("Sample Index")
    plt.ylabel("Value (0-255)")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.show()


def plot_time_comparison(time_vals, original_vals, received_vals):
    time_received = time_vals[:len(received_vals)]

    plt.figure(figsize=(12, 4))
    plt.plot(time_vals, original_vals, label='Original Signal', color='blue')
    plt.plot(time_received, received_vals, label='Received Signal', color='red', linestyle='--')

    plt.title("Original vs Received Signal")
    plt.xlabel("Time (s)")
    plt.ylabel("Value (0-255)")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    port = "COM7"
    baud = 115200
    original_csv = "uart_ready_output.csv"
    cycle = 3  # Change this to 2, 3, etc. to repeat more waveform cycles

    try:
        time_vals, original_data = load_original_csv(original_csv)
        num_bytes = len(original_data) * cycle
        print(f"[Info] Loaded {len(original_data)} samples × {cycle} cycles = {num_bytes} bytes")
    except Exception as e:
        print(f"[Warning] Failed to load original CSV: {e}")
        time_vals = None
        original_data = None
        num_bytes = 512  # fallback default

    received_data = receive_data(port, baud, num_bytes=num_bytes)
    save_to_csv(received_data)

    if original_data is not None and time_vals is not None:
        sample_count = len(original_data)
        duration = time_vals[-1] - time_vals[0]

        extended_original = list(original_data) * cycle
        extended_time = np.concatenate([
            time_vals + i * duration
            for i in range(cycle)
        ])
        plot_index_comparison(extended_original, received_data)
        # plot_time_comparison(extended_time, extended_original, received_data)
    else:
        print("Original data or time axis not available for comparison.")

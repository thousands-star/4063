# receive_only.py
import serial
import time
import pandas as pd
import matplotlib.pyplot as plt

def receive_data(port, baudrate, num_bytes=256, timeout=1):
    ser = serial.Serial(port, baudrate=baudrate, timeout=timeout)
    time.sleep(2)
    print(f"Opened {port}, starting receive-only mode...")

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

def plot_received_data(data):
    plt.figure(figsize=(10, 4))
    plt.plot(data, linestyle='-', color='red')
    plt.title("Received UART Data")
    plt.xlabel("Sample Index")
    plt.ylabel("Value (0-255)")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

def save_to_csv(data, filename="received_only_output.csv"):
    df = pd.DataFrame(data, columns=["Received"])
    df.to_csv(filename, index=False)
    print(f"Saved to {filename}")

if __name__ == "__main__":
    port = "COM7"
    baud = 115200
    num_bytes = 512  # Adjust as needed

    data = receive_data(port, baud, num_bytes=num_bytes)
    save_to_csv(data)
    plot_received_data(data)
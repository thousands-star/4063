import serial
import time
import threading
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from collections import deque

# === Config ===
SERIAL_PORT = "COM7"
BAUDRATE = 115200
CSV_FILE = "./uart_ready_output.csv"
COLUMN_NAME = "Quantized"  # or "value" depending on your CSV
DELAY = 0.005  # seconds
PLOT_WINDOW = 1000

# === Load Data ===
df = pd.read_csv(CSV_FILE)
data_values = df[COLUMN_NAME].tolist()

# === Serial Port ===
ser = serial.Serial(SERIAL_PORT, baudrate=BAUDRATE, timeout=0.01)
print(f"Opened {SERIAL_PORT}")

# === Shared Buffer ===
rx_buffer = deque([0]*PLOT_WINDOW, maxlen=PLOT_WINDOW)
rx_lock = threading.Lock()

# === Receiving Thread ===
def receive_data():
    count = 0
    try:
        while True:
            data = ser.read(1)
            if data:
                val = int.from_bytes(data, 'little')
                with rx_lock:
                    rx_buffer.append(val)
                print(f"[RX] {count}: {val}")
                count += 1
    except KeyboardInterrupt:
        print("\n[Receiver] Interrupted.")

# === Transmit on Enter ===
def transmit_on_enter():
    input("\nPress [Enter] to begin transmitting...\n")
    sent_count = 0
    for value in data_values:
        ser.write(bytes([value]))
        print(f"[TX] {sent_count}: {value}")
        sent_count += 1
        time.sleep(DELAY)
    print(f"\nTransmission complete. Sent {sent_count} bytes.")

# === Live Plot Setup ===
fig, ax = plt.subplots()
x = list(range(PLOT_WINDOW))
y = list(rx_buffer)
line, = ax.plot(x, y, lw=1.5)
ax.set_ylim(0, 255)
ax.set_title("Live UART RX Plot")
ax.set_xlabel("Sample")
ax.set_ylabel("Value (0–255)")
ax.grid(True)

# === Animation Update ===
def update_plot(frame):
    with rx_lock:
        y = list(rx_buffer)
    line.set_ydata(y)
    return line,

ani = animation.FuncAnimation(fig, update_plot, interval=50)

# === Start Threads ===
rx_thread = threading.Thread(target=receive_data, daemon=True)
rx_thread.start()

transmit_on_enter()

try:
    plt.show()
except KeyboardInterrupt:
    print("\n[Main] Exiting...")
    ser.close()
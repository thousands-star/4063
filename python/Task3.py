# Note: This script is for testing UART communication within the same PC. short the TX and RX pins on the FT232
import serial
import time
import pandas as pd
import matplotlib.pyplot as plt

# Load quantized CSV
filename = "./uart_ready_output.csv"
df = pd.read_csv(filename)  # Should contain 'Quantized' column

# === Preview plot before transmission ===
plt.figure(figsize=(14, 5))

# Left: Sample Index vs Quantized
ax1 = plt.subplot(1, 2, 1)
ax1.plot(df['Quantized'], marker='o', linestyle='-', markersize=2, color='gray')
ax1.set_title("Preview: Index vs Quantized")
ax1.set_xlabel("Sample Index")
ax1.set_ylabel("Quantized Value (0-255)")
ax1.grid(True)

# Right: Time vs Quantized
ax2 = plt.subplot(1, 2, 2)
if 'time' in df.columns:
    ax2.plot(df['time'], df['Quantized'], marker='x', linestyle='-', markersize=2, color='purple')
    ax2.set_title("Preview: Time vs Quantized")
    ax2.set_xlabel("Time (s)")
    ax2.set_ylabel("Quantized Value (0-255)")
    ax2.grid(True)
else:
    ax2.text(0.5, 0.5, "No 'time' column in CSV", ha='center', va='center', fontsize=12)
    ax2.axis('off')

plt.suptitle("Preview of Data to be Transmitted")
plt.tight_layout()
plt.show()

# Open serial port
ser = serial.Serial('COM7', baudrate=115200, timeout=1)  # Adjust COM
print(f"Opened COM7, DTR: {ser.dtr}")

sentDataCounter = 0
received_values = []

# Transmit data and collect received
try:
    for value in df['Quantized']:
        ser.write(bytes([value]))  # Send one byte at a time
        sentDataCounter += 1
        # print(f"Sent: {value}")

        # read one byte back (will block up to timeout)
        received = ser.read(size=1)

        if received:
            rec_val = received[0]
            received_values.append(rec_val)
            # print(f"Sent: {value:3d}  → Received: {rec_val:3d}")
        else:
            # print(f"Sent: {value:3d}  → No response (timeout)")
            pass

        # time.sleep(0.0001)  # Optional delay if needed

except KeyboardInterrupt:
    print(f"Was forced to Quit, sent {sentDataCounter} data.")

print(f"Transmission Completed, sent {sentDataCounter} data.")
ser.close()

# Save and plot received data and compare with transmitted
if received_values:
    output_file = "received_data_plot.csv"
    pd.DataFrame(received_values, columns=["Received"]).to_csv(output_file, index=False)
    print(f"Saved received data to {output_file}")

    # Extract transmitted values
    transmitted_values = df['Quantized'].tolist()[:len(received_values)]  # Match length

    # Plot both transmitted and received data side by side
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5), sharey=True)

    ax1.plot(transmitted_values, marker='o', linestyle='-', markersize=2, color='blue')
    ax1.set_title("Transmitted Data")
    ax1.set_xlabel("Sample Index")
    ax1.set_ylabel("Value (0-255)")
    ax1.grid(True)

    ax2.plot(received_values, marker='x', linestyle='-', markersize=2, color='red')
    ax2.set_title("Received Data")
    ax2.set_xlabel("Sample Index")
    ax2.grid(True)

    plt.suptitle("UART Loopback Comparison")
    plt.tight_layout()
    plt.show()
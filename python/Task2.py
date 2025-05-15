import pandas as pd
import matplotlib.pyplot as plt

input_file = 'Task1_1u.txt'
output_file = 'uart_ready_output.csv'

raw_times = []
raw_voltages = []
quantized_vals = []

with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
    lines = infile.readlines()
    outfile.write("time,Quantized\n")

    for line in lines[1:]:
        if not line.strip():
            continue

        parts = line.strip().split()
        try:
            time_val = float(parts[0])
            voltage_val = float(parts[1])

            # Store raw
            raw_times.append(time_val)
            raw_voltages.append(voltage_val)

            # Quantize from 0–255 range assuming 0–255 is already correct scale
            quantized = int(round(voltage_val))
            quantized = max(0, min(quantized, 255))

            quantized_vals.append(quantized)
            outfile.write(f"{time_val},{quantized}\n")

        except Exception as e:
            print(f"Skipping line due to error: {e}")

print(f"Saved quantized output ({len(quantized_vals)} bytes) to {output_file}")

# === Subplot: original vs quantized ===
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

# Original
ax1.plot(raw_times, raw_voltages, color='blue', linewidth=2)
ax1.set_title("Original Voltage Signal")
ax1.set_ylabel("Voltage")
ax1.grid(True)

# Quantized
ax2.plot(raw_times, quantized_vals, color='orange', linewidth = 2)
ax2.set_title("Quantized Signal (0–255)")
ax2.set_xlabel("Time (s)")
ax2.set_ylabel("Quantized Value")
ax2.grid(True)

plt.tight_layout()
plt.show()

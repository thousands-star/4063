import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d

# === Parameters ===
input_file = 'Task1_1u.txt'
output_file = 'uart_ready_output.csv'
interp_step_us = 2e-6  # 1 µs

# === Load raw data ===
raw_times = []
raw_voltages = []

with open(input_file, 'r') as infile:
    lines = infile.readlines()
    for line in lines[1:]:
        if not line.strip():
            continue
        parts = line.strip().split()
        try:
            time_val = float(parts[0])
            voltage_val = float(parts[1])
            raw_times.append(time_val)
            raw_voltages.append(voltage_val)
        except Exception as e:
            print(f"Skipping line due to error: {e}")

raw_times = np.array(raw_times)
raw_voltages = np.array(raw_voltages)

# === Create uniform time base ===
uniform_time = np.arange(raw_times[0], raw_times[-1], interp_step_us)

# === Interpolation ===
interp_func = interp1d(raw_times, raw_voltages, kind='linear', fill_value="extrapolate")
uniform_voltage = interp_func(uniform_time)

# === Quantize ===
quantized_vals = np.clip(np.round(uniform_voltage), 0, 255).astype(int)

# === Export CSV ===
df = pd.DataFrame({
    "time": uniform_time,
    "Quantized": quantized_vals
})
df.to_csv(output_file, index=False)
print(f"Saved {len(df)} interpolated & quantized samples to {output_file}")

# === Plot ===
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

ax1.plot(raw_times, raw_voltages, label='Original', color='blue')
ax1.plot(uniform_time, uniform_voltage, '--', label='Interpolated', color='cyan')
ax1.set_title("Original vs Interpolated Voltage")
ax1.set_ylabel("Voltage")
ax1.legend()
ax1.grid(True)

ax2.plot(uniform_time, quantized_vals, color='orange')
ax2.set_title("Quantized Signal (0–255)")
ax2.set_xlabel("Time (s)")
ax2.set_ylabel("Quantized Value")
ax2.grid(True)

plt.tight_layout()
plt.show()

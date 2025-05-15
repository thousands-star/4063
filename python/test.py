import pandas as pd
import matplotlib.pyplot as plt

# === Load the data file ===
filename = "task1.txt"

# Read the space-separated file with header
df = pd.read_csv(filename, delim_whitespace=True)

# === Plotting ===
plt.figure(figsize=(10, 5))
plt.plot(df['time'], df['V(vquantised)'], linestyle='-', marker='o', markersize=3, color='purple')
plt.title("Task 1 Data: V(vquantised) vs Time")
plt.xlabel("Time (s)")
plt.ylabel("Quantized Voltage Value")
plt.grid(True)
plt.tight_layout()
plt.show()

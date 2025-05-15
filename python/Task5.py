import serial
import os
import time
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt

# === Settings ===
SERIAL_PORT = "COM7"
BAUDRATE = 115200
READ_BYTES = 5
COLLECT_SECONDS = 2
SAMPLE_RATE = 10000  # in Hz

FILENAME = "signal.data"

# === Cleaning Function ===
def clean_data_file(filename):
    print(f"Start Cleaning data file: {filename}")
    tmp_path = filename + '.tmp'
    lower_bound = 0
    upper_bound = 64000
    count = 0
    valid_data = []

    with open(filename, 'r') as fin, open(tmp_path, 'w') as fout:
        for row in fin:
            line = row.strip()
            # print(f"Processing line {count}: {line}")
            if line.isdigit():
                if 0 <= int(line) <= 4095 and (lower_bound < count < upper_bound):
                    valid_data.append(int(line))
                    fout.write(line + '\n')
            count += 1
    with open(tmp_path, 'w') as fout:
        for value in valid_data:
            # print(value)
            fout.write(f"{value}\n")

    os.replace(tmp_path, filename)
    print(f"Cleaning complete. Only valid positive integers remain in {filename}.")

def plot_fft(filename):
    # Step 1: Load the data
    dataset = np.loadtxt(filename)  # Adjust path if needed
    
    # Step 2: Define the sample rate and time axis
    sample_rate = SAMPLE_RATE  # in Hz
    num_samples = len(dataset)

    # Step 3: Perform FFT
    fft_result = np.fft.fft(dataset)
    fft_freqs = np.fft.fftfreq(num_samples, d=1/sample_rate)

    # Step 4: Calculate the magnitude of the FFT
    fft_magnitude = np.abs(fft_result)

    # Step 6: Find the single most dominant frequency (excluding DC component at 0 Hz)
    positive_freqs = fft_freqs[1:num_samples // 2]          # Skip 0 Hz (DC)
    positive_magnitude = fft_magnitude[1:num_samples // 2]  # Skip 0 Hz magnitude

    max_index = np.argmax(positive_magnitude)
    dominant_freq = positive_freqs[max_index]
    dominant_mag = positive_magnitude[max_index]

    print(f"Most dominant frequency: {dominant_freq:.2f} Hz, Magnitude: {dominant_mag:.2f}")

    # Step 7: Plot
    plt.figure(figsize=(10, 6))
    plt.plot(positive_freqs, positive_magnitude)
    plt.title('FFT of ADC Data')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Magnitude')
    plt.grid(True)

    # Mark and label the dominant frequency
    plt.plot(dominant_freq, dominant_mag, 'ro')
    plt.annotate(f"{dominant_freq:.1f} Hz", xy=(dominant_freq, dominant_mag),
                xytext=(dominant_freq + 200, dominant_mag),
                arrowprops=dict(arrowstyle="->"), fontsize=10, color='blue')

    plt.show()
    
def plot_time(filename):
    # Read and convert to integers
    with open(filename, 'r') as f:
        adc_values = [int(line.strip()) for line in f if line.strip().isdigit()]
    print(f"Total data points: {len(adc_values)}")
    # print(f"ADC values: {adc_values}")
    # Generate x values (data index)
    x_values = list(range(len(adc_values)))
    time_stamp = 1/SAMPLE_RATE  # Sample rate in Hz
    x_values = [i * time_stamp for i in x_values]  # Convert to time in seconds
    voltage_value = [v * 3.3 / 4095 for v in adc_values]  # Convert ADC values to voltage

    # Plotting
    plt.figure(figsize=(12, 6))
    # plt.plot(x_values, adc_values, marker='o', linestyle='-', markersize=2)
    plt.plot(x_values, voltage_value, marker='x', linestyle='-', markersize=2, color='red')
    plt.title("Graph of Smoothed Signal")
    plt.xlabel("Time (s)")
    plt.ylabel("Signal Value (V)")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

# === Main collection function ===
def collect_data(filename):
    print(f"Saving ADC data to {filename}")

    ser = serial.Serial(port=SERIAL_PORT, baudrate=BAUDRATE, bytesize=8, parity="N", stopbits=1, timeout=0.01)

    count = 0

    with open(filename, "wb") as file_1:
        try:
            start_time = time.time()
            while (time.time() - start_time) < COLLECT_SECONDS:
                data = ser.read(READ_BYTES)
                if data:
                    file_1.write(data)
                    print(f"{count}: Received {data}")
                    count += 1

        except KeyboardInterrupt:
            print("\nUser stopped the data collection.")

        finally:
            ser.close()
            elapsed_time = time.time() - start_time
            print(f"Data collection time: {elapsed_time:.5f} seconds")
            print("Serial connection closed.")
            print(f"Total data points collected: {count}")

    # Cleaning step after data collection
    try:
        clean_data_file(filename)
    except Exception as e:
        print(f"Cleaning failed: {e}")

def plotting(filename):
    print(f"Plotting data from {filename}")
    try:
        plot_time(filename)
        plot_fft(filename)
    except Exception as e:
        print(f"Plotting failed: {e}")

def change_setting():
    print("Change settings here")
    # Add your settings change logic here
    # For example, you can change SERIAL_PORT, BAUDRATE, etc.
    # This is a placeholder function for demonstration purposes.
    print("1. Change SERIAL_PORT")
    print("2. Change BAUDRATE")
    print("3. Change COLLECT_SECONDS")
    try:
        choice = int(input("Enter your choice: "))
        if choice == 1:
            global SERIAL_PORT
            SERIAL_PORT = input("Enter new SERIAL_PORT: ")
        elif choice == 2:
            global BAUDRATE
            BAUDRATE = int(input("Enter new BAUDRATE: "))
        elif choice == 3:
            global COLLECT_SECONDS
            COLLECT_SECONDS = int(input("Enter new COLLECT_SECONDS: "))
        else:
            print("Invalid choice.")
    except ValueError:
        print("Invalid input. Please enter a number.")
        
# === Program Entry ===
if __name__ == "__main__":
    while True:
        print("\n=== MAIN MENU ===")
        print("1. Start Collecting Data")
        print("2. Start Plotting Data")
        print("3. Change Parameter Settings")
        print("4. Exit")

        choice = input("Enter your choice: ")

        if choice == '1':
            collect_data(FILENAME)
        elif choice == '2':
            plotting(FILENAME)
        elif choice == '3':
            change_setting()
        elif choice == '4':
            print("Exiting program.")
            break
        else:
            print("Invalid choice. Please select 1, 2, 3.")
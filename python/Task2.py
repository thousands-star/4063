input_file = 'Task1.txt'
output_file = 'uart_ready_output.csv'

with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
    # Read all lines
    lines = infile.readlines()

    # Write CSV header
    outfile.write("time,Quantized\n")

    for line in lines[1:]:  # skip header
        if not line.strip():  # skip empty lines
            continue

        parts = line.strip().split()  # split on whitespace (tabs or spaces)
        try:
            time = float(parts[0])
            voltage = float(parts[1])

            # Clip to ±5V
            voltage = max(min(voltage, 5.0), -5.0)

            # Map -5V → 0, +5V → 255
            quantized = int(round((voltage + 5.0) * 25.5))

            # Ensure within bounds
            quantized = max(0, min(quantized, 255))

            outfile.write(f"{time},{quantized}\n")
        except Exception as e:
            print(f"Skipping line due to error: {e}")

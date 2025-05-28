# uart_send_receive.py
import serial
import time
import pandas as pd
import matplotlib.pyplot as plt

def preview_csv_plot(filename):
    df = pd.read_csv(filename)

    plt.figure(figsize=(14, 5))

    # Plot Index vs Quantized
    plt.plot(df.index, df['Quantized'], marker='o', linestyle='-', markersize=2, color='gray', label='Index vs Quantized')

    # Plot Time vs Quantized (if 'time' exists)
    if 'time' in df.columns:
        plt.plot(df['time'] * max(df.index) / max(df['time']), df['Quantized'], marker='x', linestyle='-', markersize=2, color='purple', label='Time vs Quantized')

    plt.title("Preview of Data to be Transmitted")
    plt.grid(True)
    plt.legend(loc='upper right')
    plt.tight_layout()
    plt.show()


def transmit_and_receive(port, baudrate, csv_path, receive_enabled=True):
    df = pd.read_csv(csv_path)
    tx_data = df['Quantized'].tolist()

    ser = serial.Serial(port, baudrate=baudrate, timeout=1)
    time.sleep(1)
    print(f"Opened {port}, DTR: {ser.dtr}")

    received = []
    Tx_count = 0
    try:
        for value in tx_data:
            ser.write(bytes([value]))
            time.sleep(TXDELAY)
            Tx_count += 1
            # print(f"Transmitted data: {value}", end="\t")

            if receive_enabled:
                rx_byte = ser.read(size=1)
                if rx_byte:
                    received.append(rx_byte[0])
                else:
                    received.append(None)
                print(f"Received data: {rx_byte[0]}")

    except KeyboardInterrupt:
        print("Interrupted by user.")

    ser.close()
    print(f"Transmission complete. Sent {Tx_count} bytes.")
    

    if receive_enabled:
        return tx_data[:len(received)], received
    else:
        return tx_data, []
    

def plot_tx_rx(tx_data, rx_data):
    import matplotlib.pyplot as plt

    if not rx_data:
        print("No received data to plot.")
        return

    rx_data_clean = [v if v is not None else -1 for v in rx_data]

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 6), sharex=True)

    ax1.plot(tx_data, linestyle='-', markersize=2, color='blue')
    ax1.set_title("Transmitted Data")
    ax1.set_ylabel("Value (0-255)")
    ax1.grid(True)

    ax2.plot(rx_data_clean, linestyle='-', markersize=2, color='red')
    ax2.set_title("Received Data")
    ax2.set_xlabel("Sample Index")
    ax2.set_ylabel("Value (0-255)")
    ax2.grid(True)

    plt.suptitle("UART Loopback Comparison (TX vs RX)", fontsize=14)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.show()

if __name__ == "__main__":
    csv_file = "./uart_ready_output.csv"
    port = "COM7"
    TXDELAY = 0.0005
    baud = 115200

    preview_csv_plot(csv_file)
    tx, rx = transmit_and_receive(port, baud, csv_file, receive_enabled=False)
    #plot_tx_rx(tx, rx)
module uart_rx_top (
  input  logic       clk,         // 50 MHz system clock
  input  logic       key[1:0],         // key to reset
  input  logic       serial_rx,   // FT232RL TXD → FPGA RXD
  input  logic       dtr_n,       // FT232RL DTR (optional, unused here)

  output logic [7:0] leds,        // Shows last received byte
  output logic       serial_rx_out, // Forwarded RX for debug
  output logic [6:0] hex0,        // Decimal ones
  output logic [6:0] hex1,        // Decimal tens
  output logic [6:0] hex2         // Decimal hundreds
);

  // UART RX signals
  logic [7:0] rx_data;
  logic       rx_valid;

  // Instantiate improved UART receiver
  uart_rxv2 #(
    .CLK_FREQ(50_000_000),
    .BAUD    (100000)
  ) u_rx (
    .clk        (clk),
    .rst        (~key[0]),
    .serial_rx  (serial_rx),
    .data_out   (rx_data),
    .data_valid (rx_valid)
  );

  // Extract decimal digits from received byte
  logic [3:0] digit0, digit1, digit2;

  hex_display u_disp (
    .bin      (rx_data),
    .hundreds (digit2),
    .tens     (digit1),
    .ones     (digit0)
  );

  // Display digits on 7-segment displays (active-low)
  hex_decoder h0 (.bin(digit0), .seg(hex0));
  hex_decoder h1 (.bin(digit1), .seg(hex1));
  hex_decoder h2 (.bin(digit2), .seg(hex2));

  // Output the received raw byte to LEDs
  assign leds = rx_data;

  // Echo raw serial RX for debugging/monitoring
  assign serial_rx_out = serial_rx;

endmodule

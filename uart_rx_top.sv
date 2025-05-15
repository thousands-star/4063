module uart_rx_top (
  input  logic        clk,          // 50 MHz system clock
  input  logic [1:0]  key,          // KEY[0] = reset, KEY[1] = toggle display
  input  logic        serial_rx,    // UART RX input
  input  logic        dtr_n,        // Not used

  output logic [7:0]  leds,         // Display value
  output logic        serial_rx_out,// Debug: raw RX
  output logic [6:0]  hex0,
  output logic [6:0]  hex1,
  output logic [6:0]  hex2,
  output logic [6:0]  hex3,
  output logic [6:0]  hex4,
  output logic [6:0]  hex5
);

  // UART RX signals
  logic [7:0]  rx_data;
  logic        rx_valid;
  logic [15:0] recv_count;

  // Mode toggle logic
  logic show_count_mode;
  logic key1_prev;

  always_ff @(posedge clk) begin
    key1_prev <= key[1];
    if (~key[1] && key1_prev) begin
      show_count_mode <= ~show_count_mode;
    end
  end

  // UART RX instance
  uart_rxv2 #(
    .CLK_FREQ(50_000_000),
    .BAUD    (100000)
  ) u_rx (
    .clk        (clk),
    .rst        (~key[0]),
    .serial_rx  (serial_rx),
    .data_out   (rx_data),
    .data_valid (rx_valid),
    .recv_count (recv_count)
  );

  // Display logic
  logic [23:0] display_val;
  assign display_val = show_count_mode ? {8'd0, recv_count} : {16'd0, rx_data};

  logic [3:0] digit0, digit1, digit2, digit3, digit4, digit5;

  hex_display u_disp (
    .bin       (display_val),
    .digit5    (digit5),
    .digit4    (digit4),
    .digit3    (digit3),
    .digit2    (digit2),
    .digit1    (digit1),
    .digit0    (digit0)
  );

  // HEX decoders (active-low)
  hex_decoder h0 (.bin(digit0), .seg(hex0));
  hex_decoder h1 (.bin(digit1), .seg(hex1));
  hex_decoder h2 (.bin(digit2), .seg(hex2));
  hex_decoder h3 (.bin(digit3), .seg(hex3));
  hex_decoder h4 (.bin(digit4), .seg(hex4));
  hex_decoder h5 (.bin(digit5), .seg(hex5));

  assign leds          = display_val[7:0];
  assign serial_rx_out = serial_rx;

endmodule

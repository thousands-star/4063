//==============================
// Top-level main module
// Integrates: UART RX + Display + Buffer + Audio generator + UART TX
//==============================
module main (
    input  logic        CLOCK_50,      // 50 MHz Clock
    input  logic [1:0]  KEY,           // KEY[0] = Reset, KEY[1] = Toggle Display / Volume Control
    input  logic [8:0]  SW,            // SW[2] = Audio Reset, SW[1:0] = waveform_sel
    input  logic        serial_rx,     // UART RX input
    input  logic        dtr_n,         // Not used
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX5,
    output logic [7:0]  LED,           // Display output value
    output logic        GPIO_9,        // Audio PWM out
    output logic        serial_tx      // UART TX output
);

    // UART RX signals
    logic [7:0]  rx_data;
    logic        rx_valid;
    logic [15:0] recv_count;

    // Buffer signals
    logic        write_en;
    logic [7:0]  write_data;
    logic        read_en;
    logic [7:0]  read_data;
    logic        buffer_valid;
    logic        buffer_empty;
    logic        buffer_full;

    // TX control
    logic        tx_valid;
    logic        tx_ready;

    // Mode toggle logic (KEY[1])
    logic show_count_mode;
    logic key1_prev;

    always_ff @(posedge CLOCK_50) begin
        key1_prev <= KEY[1];
        if (~KEY[1] && key1_prev) begin
            show_count_mode <= ~show_count_mode;
        end
    end

    // UART RX instance
    uart_rxv2 #(
        .CLK_FREQ(50_000_000),
        .BAUD(100000)
    ) u_rx (
        .clk(CLOCK_50),
        .rst(~KEY[0]),
        .serial_rx(serial_rx),
        .data_out(rx_data),
        .data_valid(rx_valid),
        .recv_count(recv_count)
    );

    // Buffer write
    assign write_en   = rx_valid;
    assign write_data = rx_data;

    buffer #(
        .DEPTH(2048),
        .ADDR_WIDTH(11)
    ) buffer (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .write_en   (write_en),
        .write_data (write_data),
        .read_en    (read_en),
        .read_data  (read_data),
        .data_valid (buffer_valid),
        .empty      (buffer_empty),
        .full       (buffer_full)
    );

    // UART TX instance (blast data from buffer)
    assign tx_valid = ~buffer_empty & tx_ready;
    assign read_en  = tx_valid;

    uart_tx #(
        .CLK_FREQ(50_000_000),
        .BAUD(100000)
    ) u_tx (
        .clk       (CLOCK_50),
        .rst       (~KEY[0]),
        .tx_data   (read_data),
        .tx_valid  (tx_valid),
        .tx_ready  (tx_ready),
        .serial_tx (serial_tx)
    );

    // Display value selection
    logic [23:0] display_val;
    assign display_val = show_count_mode ? {8'd0, recv_count} : {16'd0, rx_data};

    // Decimal digit extraction
    logic [3:0] digit0, digit1, digit2, digit3, digit4, digit5;

    hex_display u_disp (
        .bin(display_val),
        .digit5(digit5),
        .digit4(digit4),
        .digit3(digit3),
        .digit2(digit2),
        .digit1(digit1),
        .digit0(digit0)
    );

    // HEX decoders
    hex_decoder h0 (.bin(digit0), .seg(HEX0));
    hex_decoder h1 (.bin(digit1), .seg(HEX1));
    hex_decoder h2 (.bin(digit2), .seg(HEX2));
    hex_decoder h3 (.bin(digit3), .seg(HEX3));
    hex_decoder h4 (.bin(digit4), .seg(HEX4));
    hex_decoder h5 (.bin(digit5), .seg(HEX5));

    assign LED = display_val[7:0];


endmodule

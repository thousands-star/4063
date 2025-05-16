module main_rft_loopback (
    input  logic        CLOCK_50,
    input  logic [1:0]  KEY,
    input  logic [8:0]  SW,
    input  logic        serial_rx,
    input  logic        dtr_n,
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX5,
    output logic [7:0]  LED,
    output logic        serial_tx
);

    // === UART RX ===
    logic [7:0]  rx_data;
    logic        rx_valid;
    logic [15:0] recv_count;

    uart_rxv2 #(
        .CLK_FREQ(50_000_000),
        .BAUD(115200)
    ) u_rx (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .serial_rx  (serial_rx),
        .data_out   (rx_data),
        .data_valid (rx_valid),
        .recv_count (recv_count)
    );

    // === FIR Filter ===
    logic [7:0] fir_out;
    logic       fir_valid;

    fir_filter u_fir (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .in_data    (rx_data),
        .in_valid   (rx_valid),
        .out_data   (fir_out),
        .out_valid  (fir_valid)
    );

    // === MA Filter ===
    logic [7:0] ma_out;
    logic       ma_valid;

    ma_filter #(
        .WIDTH(8),
        .DEPTH(30)
    ) u_ma (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .in_data    (rx_data),
        .in_valid   (rx_valid),
        .out_data   (ma_out),
        .out_valid  (ma_valid)
    );
    // === Filter Selector ===
    logic [7:0] selected_data;
    logic       selected_valid;

    always_comb begin
        if (SW[7]) begin  // FIR
		      selected_data  = ma_out;
            selected_valid = ma_valid;
        end else if (SW[6]) begin           // MA
            selected_data  = fir_out;
            selected_valid = fir_valid;
        end else begin
            selected_data  = rx_data;
            selected_valid = rx_valid;
        end
    end

    // === UART TX ===
    logic tx_ready;
    logic tx_valid;
    assign tx_valid = selected_valid && SW[8];

    uart_tx #(
        .CLK_FREQ(50_000_000),
        .BAUD(115200)
    ) u_tx (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .tx_data    (selected_data),
        .tx_valid   (tx_valid),
        .tx_ready   (tx_ready),
        .serial_tx  (serial_tx)
    );

    // === Display Mode Toggle ===
    logic [2:0] show_mode;
    logic       key1_prev;

    always_ff @(posedge CLOCK_50) begin
        key1_prev <= KEY[1];
        if (~KEY[1] && key1_prev)
            show_mode <= (show_mode == 5) ? 0 : show_mode + 1;
    end

    // === Display Selection ===
    logic [23:0] display_val;
    logic [3:0]  mode_val;

    always_comb begin
        case (show_mode)
            3'd0: begin
                display_val = 24'd030314;       // Project ID
                mode_val    = 4'd0;
            end
            3'd1: begin
                display_val = {16'd0, recv_count}; // RX count
                mode_val    = 4'd1;
            end
            3'd2: begin
                display_val = {16'd0, rx_data};     // Last received
                mode_val    = 4'd2;
            end
            3'd3: begin
                display_val = {16'd0, ma_out};      // MA output
                mode_val    = 4'd3;
            end
            3'd4: begin
                display_val = {16'd0, fir_out};     // FIR output
                mode_val    = 4'd4;
            end
            3'd5: begin
                display_val = {20'd0, tx_ready, selected_valid, tx_valid}; // control flags
                mode_val    = 4'd5;
            end
            default: begin
                display_val = 24'd999999;
                mode_val    = 4'd0;
            end
        endcase
    end

    // === HEX Display ===
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

    hex_decoder h0 (.bin(digit0), .seg(HEX0));
    hex_decoder h1 (.bin(digit1), .seg(HEX1));
    hex_decoder h2 (.bin(digit2), .seg(HEX2));
    hex_decoder h3 (.bin(digit3), .seg(HEX3));
    hex_decoder h4 (.bin(digit4), .seg(HEX4));
    hex_decoder h5 (.bin(mode_val), .seg(HEX5));

    // === LED Indicators ===
    assign LED[0] = rx_valid;
    assign LED[1] = ma_valid;
    assign LED[2] = fir_valid;
    assign LED[3] = selected_valid;
    assign LED[4] = tx_valid;
    assign LED[5] = tx_ready;
    assign LED[6] = SW[8];  // TX Enable
    assign LED[7] = SW[0];  // Filter Select

endmodule

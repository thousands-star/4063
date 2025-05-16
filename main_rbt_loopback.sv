module main_rbt_loopback (
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

    // UART RX
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

    // Buffer (FIFO)
    logic [7:0]  buf_out;
    logic        buf_valid;
    logic        buf_empty, buf_full;
    logic        read_en;
    logic [8:0]  wr_ptr_debug, rd_ptr_debug;
	 logic [9:0]  memory_occupancy;

    buffer #(
        .DEPTH(512),
        .ADDR_WIDTH(9)
    ) u_buffer (
        .clk         (CLOCK_50),
        .rst         (~KEY[0]),
        .write_en    (rx_valid),
        .write_data  (rx_data),
        .read_en     (read_en),
        .read_data   (buf_out),
        .data_valid  (buf_valid),
        .empty       (buf_empty),
        .full        (buf_full),
        .wr_ptr_dbg  (wr_ptr_debug),
        .rd_ptr_dbg  (rd_ptr_debug),
		  .count_dbg      (memory_occupancy)
    );
	 
	     // UART TX
    logic tx_ready;
	 logic tx_ready_prev;
    logic tx_valid;

	 // one-cycle pulse on the rising edge of tx_ready
	always_ff @(posedge CLOCK_50) begin
	  tx_ready_prev <= tx_ready;
	  read_en       <= tx_ready && !tx_ready_prev && tx_valid;
	end

	 
	assign tx_valid = buf_valid && SW[8];        // Only send if buffer has data and user enabled output


    uart_tx #(
        .CLK_FREQ(50_000_000),
        .BAUD(115200)
    ) u_tx (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .tx_data    (buf_out),
        .tx_valid   (tx_valid),
        .tx_ready   (tx_ready),
        .serial_tx  (serial_tx)
    );

    // Mode toggle for 7-segment display using KEY[1]
    logic [2:0] show_mode;
    logic       key1_prev;

    always_ff @(posedge CLOCK_50) begin
        key1_prev <= KEY[1];
        if (~KEY[1] && key1_prev)
            show_mode <= (show_mode == 5) ? 0 : show_mode + 1;
    end

    // Display selection
    logic [23:0] display_val;
    logic [3:0]  mode_val;

    always_comb begin
        case (show_mode)
            3'd0: begin display_val = 24'd030314;       mode_val = 4'd0; end // ID signature
            3'd1: begin display_val = {16'd0, recv_count}; mode_val = 4'd1; end // UART receive count
            3'd2: begin display_val = {16'd0, rx_data};      mode_val = 4'd2; end // Last received byte
            3'd3: begin display_val = {16'd0, wr_ptr_debug}; mode_val = 4'd3; end // Buffer write pointer
            3'd4: begin display_val = {16'd0, rd_ptr_debug}; mode_val = 4'd4; end // Buffer read pointer
				3'd5: begin display_val = {16'd0, memory_occupancy}; mode_val = 4'd5; end // Memory occupancy
            default: begin display_val = 24'd999999;     mode_val = 4'd0; end
        endcase
    end

    // 7-segment digit generation
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

    // Segment decoders
    hex_decoder h0 (.bin(digit0), .seg(HEX0));
    hex_decoder h1 (.bin(digit1), .seg(HEX1));
    hex_decoder h2 (.bin(digit2), .seg(HEX2));
    hex_decoder h3 (.bin(digit3), .seg(HEX3));
    hex_decoder h4 (.bin(digit4), .seg(HEX4));
    hex_decoder h5 (.bin(mode_val), .seg(HEX5)); // Show mode #

    // LED debug indicators
    assign LED[0] = rx_valid;    // UART RX valid
    assign LED[1] = buf_valid;   // Buffer output valid
    assign LED[2] = tx_valid;    // TX enabled
    assign LED[3] = tx_ready;    // TX ready
    assign LED[4] = buf_empty;   // Buffer is empty
    assign LED[5] = buf_full;    // Buffer is full
    assign LED[7:6] = 2'b00;     // Reserved

endmodule

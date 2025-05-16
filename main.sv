module main (
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

    // === MA Filter ===
    logic [7:0] filtered_data_ma;
    logic       filter_valid_ma;

    ma_filter #(
        .WIDTH(8),
        .DEPTH(30)
    ) u_ma (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .in_data    (rx_data),
        .in_valid   (rx_valid),
        .out_data   (filtered_data_ma),
        .out_valid  (filter_valid_ma)
    );

    // === FIR Filter ===
    logic [7:0] filtered_data_fir;
    logic       filter_valid_fir;

    fir_filter #(
        .WIDTH(8),
        .DEPTH(20)
    ) u_fir (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .in_data    (rx_data),
        .in_valid   (rx_valid),
        .out_data   (filtered_data_fir),
        .out_valid  (filter_valid_fir)
    );

    // === Filter selection logic ===
    logic [7:0] buff_in;
    logic       in_valid;

    always_comb begin
        if (SW[7]) begin
            buff_in  = filtered_data_ma;
            in_valid = filter_valid_ma;
        end else if (SW[6]) begin
            buff_in  = filtered_data_fir;
            in_valid = filter_valid_fir;
        end else begin
            buff_in  = rx_data;
            in_valid = rx_valid;
        end
    end

    // === Buffer (cyclic) ===
    logic [7:0] buf_out;
    logic       buf_valid;
    logic       buf_empty, buf_full;
    logic [8:0] wr_ptr_debug, rd_ptr_debug;
    logic [9:0] memory_occupancy;
    logic       read_en;

    buffer #(
        .DEPTH(512),
        .ADDR_WIDTH(9)
    ) u_buffer (
        .clk         (CLOCK_50),
        .rst         (~KEY[0]),
        .write_en    (in_valid),
        .write_data  (buff_in),
        .read_en     (read_en),
        .read_data   (buf_out),
        .data_valid  (buf_valid),
        .empty       (buf_empty),
        .full        (buf_full),
        .wr_ptr_dbg  (wr_ptr_debug),
        .rd_ptr_dbg  (rd_ptr_debug),
        .count_dbg   (memory_occupancy)
    );

    // === UART TX with 1-cycle read_en pulse ===
    logic tx_valid, tx_ready, tx_ready_prev;

    assign tx_valid = buf_valid && SW[8];

    always_ff @(posedge CLOCK_50) begin
        tx_ready_prev <= tx_ready;
        read_en       <= tx_ready && ~tx_ready_prev && tx_valid;
    end

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

    // === Display mode toggle (KEY[1]) ===
    logic [2:0] show_mode;
    logic       key1_prev;

    always_ff @(posedge CLOCK_50) begin
        key1_prev <= KEY[1];
        if (~KEY[1] && key1_prev)
            show_mode <= (show_mode == 5) ? 0 : show_mode + 1;
    end

    // === HEX Display Debug Info ===
    logic [23:0] display_val;
    logic [3:0]  mode_val;

	always_comb begin
		 case (show_mode)
			  3'd0: begin display_val = 24'd030314; mode_val = 4'd0; end
			  3'd1: begin display_val = {16'd0, recv_count}; mode_val = 4'd1; end
			  3'd2: begin display_val = {16'd0, rx_data}; mode_val = 4'd2; end
			  3'd3: begin display_val = {16'd0, wr_ptr_debug}; mode_val = 4'd3; end
			  3'd4: begin display_val = {16'd0, rd_ptr_debug}; mode_val = 4'd4; end
			  3'd5: begin display_val = {14'd0, memory_occupancy}; mode_val = 4'd5; end
			  default: begin display_val = 24'd999999; mode_val = 4'd0; end
		 endcase
	end

    logic [3:0] digit0, digit1, digit2, digit3, digit4, digit5;

    hex_display u_disp (
        .bin(display_val),
        .digit5(digit5), .digit4(digit4), .digit3(digit3),
        .digit2(digit2), .digit1(digit1), .digit0(digit0)
    );

    hex_decoder h0 (.bin(digit0), .seg(HEX0));
    hex_decoder h1 (.bin(digit1), .seg(HEX1));
    hex_decoder h2 (.bin(digit2), .seg(HEX2));
    hex_decoder h3 (.bin(digit3), .seg(HEX3));
    hex_decoder h4 (.bin(digit4), .seg(HEX4));
    hex_decoder h5 (.bin(mode_val), .seg(HEX5));

    // === LED Debug Info ===
    assign LED[0] = rx_valid;
    assign LED[1] = buf_valid;
    assign LED[2] = tx_valid;
    assign LED[3] = tx_ready;
    assign LED[4] = buf_empty;
    assign LED[5] = buf_full;
    assign LED[7:6] = 2'b00;

endmodule

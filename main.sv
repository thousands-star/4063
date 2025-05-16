// ===============================
// Modified main.sv with buffer test logic
// ===============================
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

    // UART RX signals
    logic [7:0] rx_data;
    logic       rx_valid;
    logic [15:0] recv_count;

    // Buffer signals
    logic [7:0] buf_out;
    logic       buf_valid;
    logic       buf_empty, buf_full;
    logic       read_en;
    logic [8:0] wr_ptr_debug, rd_ptr_debug;  // NEW debug pointers

    // TX
    logic       tx_ready;

    // === Mode Toggle Logic ===
    logic [2:0] show_mode;
    logic key1_prev;
	 always_ff @(posedge CLOCK_50) begin
	  	 key1_prev <= KEY[1];
		 if (~KEY[1] && key1_prev)
			  show_mode <= (show_mode == 4) ? 0 : show_mode + 1;
	 end


    // === UART RX Instance ===
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
	 
	 
	 // === MA Filter Integration ===
    logic [7:0] filtered_data;
    logic       filter_valid;

    ma_filter #(
        .WIDTH(8),
        .DEPTH(5)
    ) u_ma (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .in_data    (rx_data),
        .in_valid   (rx_valid),
        .out_data   (filtered_data),
        .out_valid  (filter_valid)
    );
    
    // === FIR Filter Integration ===
    logic [7:0] fir_data;
    logic       fir_valid;

    fir_filter #(
        .WIDTH(8),
        .DEPTH(20)
    ) u_fir (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .in_data    (rx_data),
        .in_valid   (rx_valid),
        .out_data   (fir_data),
        .out_valid  (fir_valid)
    );
    

    logic [7:0] buff_in;
	 logic       in_valid;

	 always_comb begin
		 if (SW[7]) begin
			  buff_in    = filtered_data;
			  in_valid = filter_valid;
		 end else if (SW[6]) begin
			  buff_in    = fir_data;
			  in_valid = fir_valid;
		 end else begin
			  buff_in    = rx_data;
			  in_valid = rx_valid;
		 end
	 end

	 
	 // === caching buffer ===

	buffer #(
		 .DEPTH(512),
		 .ADDR_WIDTH(9)  // log2(512) = 9
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
		 .rd_ptr_dbg  (rd_ptr_debug)
	);
	
	
    // === UART TX ===
	 assign read_en = tx_ready;
    logic tx_valid;
    assign tx_valid = SW[8];

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
	 

    // === Display ===
	logic [23:0] display_val;
	logic [3:0] mode_val;

	always_comb begin
		 case (show_mode)
			  3'd0: begin
					display_val = 24'd030314;  // ID signature
					mode_val    = 4'd0;
			  end
			  3'd1: begin
					display_val = {16'd0, recv_count};  // RX count
					mode_val    = 4'd1;
			  end
			  3'd2: begin
					display_val = {16'd0, rx_data};  // latest received value
					mode_val    = 4'd2;
			  end
			  3'd3: begin
					display_val = {16'd0, wr_ptr_debug};
					mode_val    = 4'd3;
			  end
			  3'd4: begin
					display_val = {16'd0, rd_ptr_debug};
					mode_val    = 4'd4;
			  end
			  default: begin
					display_val = 24'd999999;
					mode_val    = 4'd0;
			  end
		 endcase
	end

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
    hex_decoder h5 (.bin(mode_val), .seg(HEX5));  // show mode #

    // === LED status register ===
    assign LED[0] = rx_valid;
    assign LED[1] = buf_valid;
    assign LED[2] = tx_valid;
    assign LED[3] = tx_ready;
    assign LED[4] = buf_empty;
    assign LED[5] = buf_full;
    assign LED[7:6] = 2'b00;

endmodule
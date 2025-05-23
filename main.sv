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

    // === MA Filter ===
    logic [7:0] ma_data;
    logic       ma_valid;

    ma_filter #(
        .WIDTH(8),
        .DEPTH(30)
    ) u_ma (
        .clk        (CLOCK_50),
        .rst        (~KEY[0]),
        .in_data    (rx_data),
        .in_valid   (rx_valid),
        .out_data   (ma_data),
        .out_valid  (ma_valid)
    );

    // === FIR Filter ===
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

    // === Filter selection logic ===
    logic [7:0] buff_input;
    logic       filter_valid;

    always_comb begin
        if (SW[7]) begin
            buff_input  = ma_data;
            filter_valid = ma_valid;
        end else if (SW[6]) begin
            buff_input  = fir_data;
            filter_valid = fir_valid;
        end else begin
            buff_input  = rx_data;
            filter_valid = rx_valid;
        end
    end

	 
    // === Signal Processing ===
    logic [7:0] square_data;
	 logic [7:0] triangle_data;
	 logic [7:0] fm_data;

    square_wave_gen u_square (
        .in_data  (buff_input),
        .out_data (square_data)
    );
	 
	 triangle_wave_gen u_triangle (
		  .in_data  (buff_input),
		  .out_data (triangle_data)
	 );
	 
	 fm_wave_gen1u u_fm (
	     .clk      (CLOCK_50),
		  .rst      (~KEY[0]),
		  .in_valid (filter_valid),
		  .in_data  (buff_input),
		  .out_data (fm_data)
	 );


    // === Buffer for filtered sine signal ===
    logic [7:0] out_sine;
    logic       val_sine, empty_sine, full_sine, read_sine;
    logic [8:0] wr_ptr_sine, rd_ptr_sine;
    logic [9:0] occ_sine;

    buffer #(
        .DEPTH(512),
        .ADDR_WIDTH(9)
    ) buf_sine (
        .clk         (CLOCK_50),
        .rst         (~KEY[0]),
        .write_en    (filter_valid),
        .write_data  (buff_input),
        .read_en     (read_sine),
        .read_data   (out_sine),
        .data_valid  (val_sine),
        .empty       (empty_sine),
        .full        (full_sine),
        .wr_ptr_dbg  (wr_ptr_sine),
        .rd_ptr_dbg  (rd_ptr_sine),
        .count_dbg   (occ_sine)
    );

    // === Buffer for square wave processed signal ===
    logic [7:0] out_square;
    logic       val_square, empty_square, full_square, read_square;
    logic [8:0] wr_ptr_square, rd_ptr_square;
    logic [9:0] occ_square;

    buffer #(
        .DEPTH(512),
        .ADDR_WIDTH(9)
    ) buf_square (
        .clk         (CLOCK_50),
        .rst         (~KEY[0]),
        .write_en    (filter_valid),
        .write_data  (square_data),
        .read_en     (read_square),
        .read_data   (out_square),
        .data_valid  (val_square),
        .empty       (empty_square),
        .full        (full_square),
        .wr_ptr_dbg  (wr_ptr_square),
        .rd_ptr_dbg  (rd_ptr_square),
        .count_dbg   (occ_square)
    );
	 
	 // === Buffer for triangle wave processed signal ===
		logic [7:0] out_triangle;
		logic       val_triangle, empty_triangle, full_triangle, read_triangle;
		logic [8:0] wr_ptr_triangle, rd_ptr_triangle;
		logic [9:0] occ_triangle;

		buffer #(
			 .DEPTH(512),
			 .ADDR_WIDTH(9)
		) buf_triangle (
			 .clk         (CLOCK_50),
			 .rst         (~KEY[0]),
			 .write_en    (filter_valid),     // write whenever the filtered sample is valid
			 .write_data  (triangle_data),    // your triangle_wave_gen output
			 .read_en     (read_triangle),
			 .read_data   (out_triangle),
			 .data_valid  (val_triangle),
			 .empty       (empty_triangle),
			 .full        (full_triangle),
			 .wr_ptr_dbg  (wr_ptr_triangle),
			 .rd_ptr_dbg  (rd_ptr_triangle),
			 .count_dbg   (occ_triangle)
		);
		
	 // === Buffer for FM-modulated wave processed signal ===
    logic [7:0]  out_fm;
    logic        val_fm, empty_fm, full_fm, read_fm;
    logic [8:0]  wr_ptr_fm, rd_ptr_fm;
    logic [9:0]  occ_fm;

    buffer #(
      .DEPTH      (512),
      .ADDR_WIDTH (9)
    ) buf_fm (
      .clk         (CLOCK_50),
      .rst         (~KEY[0]),
      .write_en    (filter_valid),     // assert when your FM generator output is ready
      .write_data  (fm_data),      // connect to your fm_wave_gen out
      .read_en     (read_fm),
      .read_data   (out_fm),
      .data_valid  (val_fm),
      .empty       (empty_fm),
      .full        (full_fm),
      .wr_ptr_dbg  (wr_ptr_fm),
      .rd_ptr_dbg  (rd_ptr_fm),
      .count_dbg   (occ_fm)
    );

    // === TX Multiplexor ===
    logic [7:0] tx_data;
    logic       tx_valid;
    logic       tx_ready, tx_ready_prev;

    always_comb begin
	     if (SW[2]) begin
		      tx_data = out_fm;
				tx_valid = val_fm;
        end else if (SW[1]) begin
            tx_data  = out_triangle;
            tx_valid = val_triangle;
        end else if (SW[0]) begin
            tx_data  = out_square;
            tx_valid = val_square;
        end else begin
		      tx_data  = out_sine;
            tx_valid = val_sine;
		  end
    end
	 
	 // === Read signal handshake ===
	 
	 logic       read_en;

		assign read_sine     = read_en &&  (SW[2:0] == 3'b000);
		assign read_square   = read_en &&  (SW[2:0] == 3'b001);
		assign read_triangle = read_en &&  (SW[2:0] == 3'b010);
		assign read_fm       = read_en &&  (SW[2:0] == 3'b100);
		
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
        .tx_data    (tx_data),
        .tx_valid   (tx_valid && SW[8]),
        .tx_ready   (tx_ready),
        .serial_tx  (serial_tx)
    );

    // === Display mode toggle (KEY[1]) ===
    logic [2:0] show_mode;
    logic       key1_prev;

    always_ff @(posedge CLOCK_50) begin
        key1_prev <= KEY[1];
        if (~KEY[1] && key1_prev)
            show_mode <= (show_mode == 6) ? 0 : show_mode + 1;
    end

    // === HEX Display Debug Info ===
    logic [23:0] display_val;
    logic [3:0]  mode_val;

	always_comb begin
		 case (show_mode)
			  3'd0: begin display_val = 24'd030314;             mode_val = 4'd0; end
			  3'd1: begin display_val = {16'd0, recv_count};    mode_val = 4'd1; end
			  3'd2: begin display_val = {16'd0, rx_data};       mode_val = 4'd2; end
			  3'd3: begin display_val = {16'd0, buff_input}; mode_val = 4'd3; end
			  3'd4: begin display_val = {16'd0, square_data}; mode_val = 4'd4; end
			  3'd5: begin display_val = {14'd0, triangle_data};    mode_val = 4'd5; end
			  3'd6: begin display_val = {16'd0, fm_data};    mode_val = 4'd6; end
			  default: begin display_val = 24'd999999;          mode_val = 4'd0; end
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
    assign LED[1] = val_square;
    assign LED[2] = tx_valid;
    assign LED[3] = tx_ready;
    assign LED[4] = empty_square;
    assign LED[5] = full_square;
    assign LED[7:6] = 2'b00;

endmodule

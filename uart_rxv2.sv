module uart_rxv2 #(
  parameter int CLK_FREQ = 50_000_000,
  parameter int BAUD     = 100000
) (
  input  logic        clk,         // System clock
  input  logic        rst,         // Synchronous reset
  input  logic        serial_rx,   // UART RX input (async)
  output logic [7:0]  data_out,    // Received byte
  output logic        data_valid,  // Pulses high for 1 clk on valid data
  output logic [15:0] recv_count   // Total number of valid bytes received
);

  // Calculate baud timing
  localparam int BAUD_DIV      = CLK_FREQ / BAUD;
  localparam int HALF_DIV      = BAUD_DIV >> 1;
  localparam int TIMEOUT_LIMIT = BAUD_DIV * 12; // Optional: watchdog

  typedef enum logic [1:0] { IDLE, START, DATA, STOP } state_t;
  state_t        state;

  logic [15:0]   baud_cnt;
  logic [3:0]    bit_cnt;
  logic [15:0]   watchdog_cnt;

  logic [7:0]    rx_shift;
  logic [7:0]    rx_latch;

  logic          rx_sync_0, rx_sync_1;
  always_ff @(posedge clk) begin
    rx_sync_0 <= serial_rx;
    rx_sync_1 <= rx_sync_0;
  end
  wire rx_clean = rx_sync_1;

  assign data_out = rx_latch;

  always_ff @(posedge clk) begin
    if (rst) begin
      state         <= IDLE;
      baud_cnt      <= 0;
      bit_cnt       <= 0;
      rx_shift      <= 8'd0;
      rx_latch      <= 8'd0;
      data_valid    <= 1'b0;
      watchdog_cnt  <= 0;
      recv_count    <= 0;        // Clear receive count
    end else begin
      data_valid <= 1'b0;

      // Watchdog: return to IDLE if stuck
      if (state != IDLE) begin
        watchdog_cnt <= watchdog_cnt + 1;
        if (watchdog_cnt > TIMEOUT_LIMIT) begin
          state <= IDLE;
        end
      end else begin
        watchdog_cnt <= 0;
      end

      case (state)
        IDLE: begin
          baud_cnt <= 0;
          bit_cnt  <= 0;
          if (rx_clean == 1'b0) begin
            state    <= START;
            baud_cnt <= 1;
          end
        end

        START: begin
          if (baud_cnt >= HALF_DIV) begin
            state    <= DATA;
            baud_cnt <= 1;
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        DATA: begin
          if (baud_cnt >= BAUD_DIV) begin
            baud_cnt <= 1;
            rx_shift[bit_cnt] <= rx_clean;
            if (bit_cnt == 3'd7) begin
              bit_cnt <= 0;
              state   <= STOP;
            end else begin
              bit_cnt <= bit_cnt + 1;
            end
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        STOP: begin
          if (baud_cnt >= BAUD_DIV) begin
            baud_cnt <= 0;
            if (rx_clean == 1'b1) begin  // Validate stop bit
              rx_latch    <= rx_shift;
              data_valid  <= 1'b1;
              recv_count  <= recv_count + 1; // Count this byte
            end
            state <= IDLE;
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule

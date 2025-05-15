//======================================================
// uart_tx.sv
// Transmit UART data at given baud rate
// Sends data from buffer continuously
// Adds watchdog timeout to reset if stuck
// Improved tx_valid handshake timing
//======================================================

module uart_tx #(
  parameter int CLK_FREQ = 50_000_000,
  parameter int BAUD     = 100000
)(
  input  logic        clk,
  input  logic        rst,
  input  logic [7:0]  tx_data,
  input  logic        tx_valid,    // Pulse to trigger a new byte transmit
  output logic        tx_ready,    // High when ready to send new byte
  output logic        serial_tx    // UART TX output
);

  localparam int BAUD_DIV = CLK_FREQ / BAUD;
  localparam int TIMEOUT_CYCLES = BAUD_DIV * 20;  // ~2 bytes worth

  typedef enum logic [2:0] {
    IDLE,
    START,
    DATA,
    STOP
  } state_t;

  state_t      state;
  logic [15:0] baud_cnt;
  logic [2:0]  bit_idx;
  logic [7:0]  tx_shift;
  logic [31:0] watchdog_cnt;

  logic        tx_valid_latched;

  always_ff @(posedge clk) begin
    if (rst) begin
      state             <= IDLE;
      serial_tx         <= 1'b1;
      tx_ready          <= 1'b1;
      baud_cnt          <= 0;
      bit_idx           <= 0;
      watchdog_cnt      <= 0;
      tx_valid_latched  <= 0;
    end else begin

      // === Watchdog timeout logic ===
      if (state != IDLE) begin
        if (watchdog_cnt >= TIMEOUT_CYCLES) begin
          state        <= IDLE;
          tx_ready     <= 1'b1;
          serial_tx    <= 1'b1;
          watchdog_cnt <= 0;
        end else begin
          watchdog_cnt <= watchdog_cnt + 1;
        end
      end else begin
        watchdog_cnt <= 0;
      end

      // === Capture tx_valid pulse only when ready ===
      if (tx_ready && tx_valid)
        tx_valid_latched <= 1;

      case (state)
        IDLE: begin
          serial_tx <= 1'b1;
          tx_ready  <= 1'b1;
          if (tx_valid_latched) begin
            tx_shift          <= tx_data;
            state             <= START;
            tx_ready          <= 1'b0;
            tx_valid_latched  <= 1'b0;
            baud_cnt          <= 0;
          end
        end

        START: begin
          serial_tx <= 1'b0;
          if (baud_cnt == BAUD_DIV - 1) begin
            baud_cnt <= 0;
            bit_idx  <= 0;
            state    <= DATA;
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        DATA: begin
          serial_tx <= tx_shift[bit_idx];
          if (baud_cnt == BAUD_DIV - 1) begin
            baud_cnt <= 0;
            if (bit_idx == 3'd7) begin
              state <= STOP;
            end else begin
              bit_idx <= bit_idx + 1;
            end
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        STOP: begin
          serial_tx <= 1'b1;
          if (baud_cnt == BAUD_DIV - 1) begin
            baud_cnt <= 0;
            state    <= IDLE;
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

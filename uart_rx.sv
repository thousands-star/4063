module uart_rx #(
    parameter CLK_FREQ = 50000000,      // e.g. 50 MHz
    parameter BAUDRATE = 115200
)(
    input  logic clk,
    input  logic rst,
    input  logic rx,                    // UART RX line
    output logic [7:0] data_out,
    output logic data_valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUDRATE;
    typedef enum logic [2:0] {IDLE, START, DATA, STOP} state_t;
    
    state_t state;
    logic [$clog2(CLKS_PER_BIT)-1:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] rx_shift;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_out <= 8'd0;
            data_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    data_valid <= 0;
                    if (!rx) begin  // start bit detected
                        state <= START;
                        clk_count <= 0;
                    end
                end
                START: begin
                    if (clk_count == CLKS_PER_BIT/2) begin
                        if (!rx) begin
                            clk_count <= 0;
                            bit_index <= 0;
                            state <= DATA;
                        end else
                            state <= IDLE;  // false start
                    end else
                        clk_count <= clk_count + 1;
                end
                DATA: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        rx_shift[bit_index] <= rx;
                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                    end else
                        clk_count <= clk_count + 1;
                end
                STOP: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        data_out <= rx_shift;
                        data_valid <= 1;
                        state <= IDLE;
                        clk_count <= 0;
                    end else
                        clk_count <= clk_count + 1;
                end
            endcase
        end
    end
endmodule
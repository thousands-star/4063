//=====================================
// buffer.sv
// Circular buffer (FIFO) for 8-bit data
// Supports one writer and one reader
//=====================================

module buffer #(
    parameter DEPTH = 256,               // Buffer size (power of 2)
    parameter ADDR_WIDTH = 8             // log2(DEPTH)
)(
    input  logic        clk,
    input  logic        rst,

    // Write interface
    input  logic        write_en,
    input  logic [7:0]  write_data,

    // Read interface
    input  logic        read_en,
    output logic [7:0]  read_data,
    output logic        data_valid,

    // Status
    output logic        empty,
    output logic        full
);

    // Buffer storage
    logic [7:0] mem [0:DEPTH-1];

    // Pointers
    logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [ADDR_WIDTH:0]   count; // element counter

    // Write logic
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (write_en && !full) begin
            mem[wr_ptr] <= write_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
        end else if (read_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign read_data  = mem[rd_ptr];
    assign data_valid = !empty;

    // Count logic
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else begin
            case ({write_en && !full, read_en && !empty})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

endmodule

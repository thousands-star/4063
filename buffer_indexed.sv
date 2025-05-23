module buffer_indexed #(
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = 8
)(
    input  logic        clk,
    input  logic        rst,

    // Write interface
    input  logic        write_en,
    input  logic [7:0]  write_data,

    // Read interface
    input  logic        read_en,
    input  logic [ADDR_WIDTH-1:0] read_index,  // NEW
    output logic [7:0]  read_data,
    output logic        data_valid,

    // Status
    output logic        empty,
    output logic        full,

    // Debug
    output logic [ADDR_WIDTH-1:0] wr_ptr_dbg,
    output logic [ADDR_WIDTH:0]   count_dbg
);

    // Internal memory
    logic [7:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH:0]   count;

    assign wr_ptr_dbg = wr_ptr;
    assign count_dbg  = count;

    // Write logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            count  <= 0;
        end else if (write_en && !full) begin
            mem[wr_ptr] <= write_data;
            wr_ptr      <= wr_ptr + 1;
            count       <= count + 1;
        end
    end

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Non-destructive indexed read
    logic [ADDR_WIDTH-1:0] read_addr;

    always_comb begin
        // Compute circular index: (wr_ptr - read_index - 1) % DEPTH
        if (read_index <= wr_ptr)
            read_addr = wr_ptr - read_index - 1;
        else
            read_addr = DEPTH + wr_ptr - read_index - 1;
    end

    logic [7:0] read_data_r;

    always_ff @(posedge clk) begin
        if (read_en)
            read_data_r <= mem[read_addr];
    end

    assign read_data  = read_data_r;
    assign data_valid = read_en;

endmodule

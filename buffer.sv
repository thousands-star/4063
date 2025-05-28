module buffer #(
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = 8
)(
    input  logic        clk,
    input  logic        rst,
	 input  logic        read_rst,

    // Write interface
    input  logic        write_en,
    input  logic [7:0]  write_data,

    // Read interface
    input  logic        read_en,
    output logic [7:0]  read_data,
    output logic        data_valid,

    // Status
    output logic        empty,
    output logic        full,

    // Debug pointers
    output logic [ADDR_WIDTH-1:0] wr_ptr_dbg,
    output logic [ADDR_WIDTH-1:0] rd_ptr_dbg,
	 output logic [ADDR_WIDTH:0] count_dbg 
);

    // Internal memory
    logic [7:0] mem [0:DEPTH-1];

    // Write pointer and counter (for write limit)
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH:0]   count;

    // Read pointer (will loop forever)
    logic [ADDR_WIDTH-1:0] rd_ptr;

    // Debug
    assign wr_ptr_dbg = wr_ptr;
    assign rd_ptr_dbg = rd_ptr;
	 assign count_dbg = count;

    // ----------------------------
    // Write logic
    // ----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            count  <= 0;
        end else if (write_en && !full) begin
            mem[wr_ptr] <= write_data;
            wr_ptr <= wr_ptr + 1;
            count  <= count + 1;
        end
    end

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // ----------------------------
    // Read logic (cyclic)
    // ----------------------------
    always_ff @(posedge clk or posedge read_rst) begin
        if (read_rst)
            rd_ptr <= 0;
        else if (read_en && !empty)
            rd_ptr <= (rd_ptr == count - 1) ? 0 : rd_ptr + 1;
    end

    assign read_data  = mem[rd_ptr];
    assign data_valid = !empty;

endmodule

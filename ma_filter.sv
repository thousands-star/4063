module ma_filter #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 5  // 5-point MA
)(
  input  logic                 clk,
  input  logic                 rst,
  input  logic [WIDTH-1:0]     in_data,
  input  logic                 in_valid,
  output logic [WIDTH-1:0]     out_data,
  output logic                 out_valid
);

  // Shift register to store last 5 samples
  logic [WIDTH-1:0] shift_reg[0:DEPTH-1];
  logic [$clog2(DEPTH+1)-1:0] sample_count;

  // Register to hold computed average
  logic [WIDTH+$clog2(DEPTH):0] sum;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (int i = 0; i < DEPTH; i++)
        shift_reg[i] <= 0;
      sample_count <= 0;
    end else if (in_valid) begin
      // Shift incoming sample into register
      for (int i = DEPTH-1; i > 0; i--)
        shift_reg[i] <= shift_reg[i-1];
      shift_reg[0] <= in_data;

      // Update count
      if (sample_count < DEPTH)
        sample_count <= sample_count + 1;
    end
  end

  // Combinational sum of the 5 elements
  always_comb begin
    sum = 0;
    for (int i = 0; i < DEPTH; i++)
      sum += shift_reg[i];
  end

  // Output logic
  assign out_valid = in_valid;  // Keep it aligned with input stream

  always_comb begin
    if (sample_count < DEPTH)
      out_data = in_data;       // Bypass for first 4 samples
    else
      out_data = sum / DEPTH;   // Use filtered average
  end

endmodule

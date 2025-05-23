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

  // (1) storage
  logic [WIDTH-1:0] shift_reg[0:DEPTH-1];
  logic [$clog2(DEPTH+1)-1:0] sample_count;
  // comb sum of current contents
  logic [WIDTH + $clog2(DEPTH):0] sum_reg;

  // --- collect samples / bump count ---
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      sample_count <= 0;
      for (int i = 0; i < DEPTH; i++)
        shift_reg[i] <= '0;
    end
    else if (in_valid) begin
      // shift
      for (int i = DEPTH-1; i > 0; i--)
        shift_reg[i] <= shift_reg[i-1];
      shift_reg[0] <= in_data;
      // saturate up to DEPTH
      if (sample_count < DEPTH)
        sample_count <= sample_count + 1;
    end
  end

  // --- combinational sum of what's stored right now ---
  always_comb begin
    sum_reg = '0;
    for (int i = 0; i < DEPTH; i++)
      sum_reg += shift_reg[i];
  end

  // --- zero-latency “next” logic for sum & count, then divide ---
  always_comb begin
    // compute what the sum *will* be after we shift in this sample
    logic [WIDTH + $clog2(DEPTH):0] next_sum;
    // compute what the sample_count *will* be
    logic [$clog2(DEPTH+1)-1:0] next_count;

    // drop the oldest, add the new (if valid)
    next_sum  = sum_reg - shift_reg[DEPTH-1]
                + (in_valid ? in_data : '0);

    // bump the count until it saturates at DEPTH
    next_count = in_valid
      ? (sample_count < DEPTH ? sample_count + 1 : DEPTH)
      : sample_count;

    // never divide by zero
    if (next_count != 0)
      out_data = next_sum / next_count;
    else
      out_data = '0;
  end

  assign out_valid = in_valid;

endmodule

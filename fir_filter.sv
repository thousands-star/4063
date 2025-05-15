module fir_filter #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 20
)(
  input  logic                 clk,
  input  logic                 rst,
  input  logic [WIDTH-1:0]     in_data,
  input  logic                 in_valid,
  output logic [WIDTH-1:0]     out_data,
  output logic                 out_valid
);

  // 20-tap low-pass FIR coefficients
  localparam int COEFF_SUM = 250;
  localparam int COEFFS[0:19] = '{
    1, 2, 3, 5, 8, 12, 17, 22, 26, 29,
    29, 26, 22, 17, 12, 8, 5, 3, 2, 1
  };

  // Shift register for input samples
  logic [WIDTH-1:0] shift_reg[0:DEPTH-1];
  logic [$clog2(DEPTH+1)-1:0] sample_count;

  // Accumulator
  logic [WIDTH+8:0] acc;

  // Shift register logic
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (int i = 0; i < DEPTH; i++)
        shift_reg[i] <= 0;
      sample_count <= 0;
    end else if (in_valid) begin
      for (int i = DEPTH-1; i > 0; i--)
        shift_reg[i] <= shift_reg[i-1];
      shift_reg[0] <= in_data;

      if (sample_count < DEPTH)
        sample_count <= sample_count + 1;
    end
  end

  // FIR dot product
  always_comb begin
    acc = 0;
    for (int i = 0; i < DEPTH; i++) begin
      acc += shift_reg[i] * COEFFS[i];
    end
  end

  assign out_valid = in_valid;

  always_comb begin
    if (sample_count < DEPTH)
      out_data = in_data;
    else begin
      logic [WIDTH-1:0] result;
      result = acc / COEFF_SUM;

      // Clamp to [0,255]
      if (result > 8'd255)
        out_data = 8'd255;
      else
        out_data = result;
    end
  end

endmodule

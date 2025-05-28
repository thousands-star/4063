//==================================================================
// fir_filter.sv
//
// 23-tap FIR filter with early “moving-average” behavior:
//   • sample_count==0 → echo the very first input
//   • 0<sample_count<DEPTH → equal-weight moving average of all available samples
//   • sample_count>=DEPTH → full 23-tap weighted FIR
//==================================================================
module fir_filter #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 29
)(
  input  logic                 clk,
  input  logic                 rst,
  input  logic [WIDTH-1:0]     in_data,
  input  logic                 in_valid,
  output logic [WIDTH-1:0]     out_data,
  output logic                 out_valid
);

  //------------------------------------------------------------------------
  // 23-tap symmetric FIR coefficients (sum = 289)
  //------------------------------------------------------------------------
  localparam int COEFF_SUM = 493;
  localparam int COEFFS [0:DEPTH-1] = '{
      1, 3, 6, 9, 12, 15, 17, 19, 21, 23, 25, 26, 27, 28, 29, 
 28, 27, 26, 25, 23, 21, 19, 17, 15, 12, 9, 6, 3, 1
  };

  //------------------------------------------------------------------------
  // shift register + sample counter
  //------------------------------------------------------------------------
  logic [WIDTH-1:0]           shift_reg   [0:DEPTH-1];
  logic [$clog2(DEPTH+1)-1:0] sample_count;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      sample_count <= 0;
      for (int i = 0; i < DEPTH; i++)
        shift_reg[i] <= '0;
    end else if (in_valid) begin
      // shift down
      for (int i = DEPTH-1; i > 0; i--)
        shift_reg[i] <= shift_reg[i-1];
      // capture new sample
      shift_reg[0] <= in_data;
      // count up until full
      if (sample_count < DEPTH)
        sample_count <= sample_count + 1;
    end
  end

  assign out_valid = in_valid;

  //------------------------------------------------------------------------
  // comb: moving-average then full FIR, all loops constant-bound
  //------------------------------------------------------------------------
  always_comb begin
    logic [WIDTH+8:0] sum;
    sum = '0;

    if (sample_count == 0) begin
      // first sample, nothing to average
      out_data = in_data;

    end else if (sample_count < DEPTH) begin
      // partial moving average of all valid samples
      for (int i = 0; i < DEPTH; i++) begin
        if (i < sample_count)
          sum += shift_reg[i];
      end
      out_data = sum / sample_count;

    end else begin
      // full weighted FIR
      for (int i = 0; i < DEPTH; i++)
        sum += shift_reg[i] * COEFFS[i];
      out_data = sum / COEFF_SUM;
    end
  end

endmodule

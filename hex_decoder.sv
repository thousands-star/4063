module hex_decoder (
  input  logic [3:0] bin,
  output logic [6:0] seg  // active-low
);

  always_comb begin
    case (bin)
      4'd0: seg = 7'b100_0000;
      4'd1: seg = 7'b111_1001;
      4'd2: seg = 7'b010_0100;
      4'd3: seg = 7'b011_0000;
      4'd4: seg = 7'b001_1001;
      4'd5: seg = 7'b001_0010;
      4'd6: seg = 7'b000_0010;
      4'd7: seg = 7'b111_1000;
      4'd8: seg = 7'b000_0000;
      4'd9: seg = 7'b001_1000;
      default: seg = 7'b111_1111;  // blank
    endcase
  end

endmodule

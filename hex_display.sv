module hex_display (
  input  logic [7:0] bin,        
  output logic [3:0] hundreds,   
  output logic [3:0] tens,       
  output logic [3:0] ones        
);

  logic [7:0] bcd_temp;
  logic [7:0] rem;

  always_comb begin
    hundreds = bin / 100;
    rem      = bin % 100;
    tens     = rem / 10;
    ones     = rem % 10;
  end

endmodule

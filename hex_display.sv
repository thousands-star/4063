module hex_display (
  input  logic [23:0] bin,          // binary input (max 999999)
  output logic [3:0] digit5,        // hundred-thousands
  output logic [3:0] digit4,        // ten-thousands
  output logic [3:0] digit3,        // thousands
  output logic [3:0] digit2,        // hundreds
  output logic [3:0] digit1,        // tens
  output logic [3:0] digit0         // ones
);

  logic [23:0] temp;

  always_comb begin
    temp = bin;

    digit5 = temp / 100000;
    temp   = temp % 100000;

    digit4 = temp / 10000;
    temp   = temp % 10000;

    digit3 = temp / 1000;
    temp   = temp % 1000;

    digit2 = temp / 100;
    temp   = temp % 100;

    digit1 = temp / 10;
    digit0 = temp % 10;
  end

endmodule

module square_wave_gen (
    input  logic [7:0] in_data,
    output logic [7:0] out_data
);
    
    assign out_data = (in_data >= 8'd128) ? 8'd255 : 8'd0;

endmodule

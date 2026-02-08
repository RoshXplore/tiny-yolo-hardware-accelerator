module leaky_relu #(
    parameter DW = 16  // Input Width 
)(
    input wire clk,
    // We treat inputs as SIGNED because they can be negative!
    input wire signed [DW-1:0] data_in,
    output reg signed [DW-1:0] data_out
);

    always @(posedge clk) begin
        
        if (data_in >= 0) begin
            // Positive? Pass it through unchanged.
            data_out <= data_in;
        end else begin
            // If Negative? Multiply by 0.125 (Divide by 8)
           
            data_out <= data_in >>> 3;
        end
    end

endmodule
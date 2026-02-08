module leaky_relu #(
    parameter DW = 16  // Input Width (matches your Conv Core output)
)(
    input wire clk,
    // We treat inputs as SIGNED because they can be negative!
    input wire signed [DW-1:0] data_in,
    output reg signed [DW-1:0] data_out
);

    always @(posedge clk) begin
        // The Ternary Operator: (Condition) ? True_Value : False_Value
        if (data_in >= 0) begin
            // Positive? Pass it through unchanged.
            data_out <= data_in;
        end else begin
            // Negative? Multiply by 0.125 (Divide by 8)
            // >>> is the Arithmetic Shift. It keeps the negative sign.
            data_out <= data_in >>> 3;
        end
    end

endmodule
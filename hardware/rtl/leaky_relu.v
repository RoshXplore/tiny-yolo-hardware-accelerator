module leaky_relu #(
    parameter DW = 16  // Input Width 
)(
    input wire clk,
   
    input wire signed [DW-1:0] data_in,
    output reg signed [DW-1:0] data_out
);

    always @(posedge clk) begin
        
        if (data_in >= 0) begin
            
            data_out <= data_in;
        end else begin
            // If Negative, Multiply by 0.125 
            data_out <= data_in >>> 3;
        end
    end

endmodule
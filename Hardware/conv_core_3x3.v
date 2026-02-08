module conv_core_3x3 #(
    parameter DW = 8,       // Input Width (8-bit)
    parameter QW = 16,      // Quantized Weight Width 
    parameter ACC_W = 32    // Accumulator Width (Prevent overflow)
)(
    input wire clk,
    input wire rst,
    input wire valid_in,    

    // 1. The 9 Pixels from Line Buffer

    input wire [DW-1:0] p00, p01, p02,
    input wire [DW-1:0] p10, p11, p12,
    input wire [DW-1:0] p20, p21, p22,

    // 2. The 9 Weights (Loaded from Configuration)
    input wire signed [QW-1:0] k00, k01, k02,
    input wire signed [QW-1:0] k10, k11, k12,
    input wire signed [QW-1:0] k20, k21, k22,
    
    // 3. The Bias
    input wire signed [QW-1:0] bias,

    // 4. Output
    output reg signed [ACC_W-1:0] conv_out,
    output reg valid_out
);

   
    // STAGE 1: MULTIPLICATION (9 Parallel Multipliers)
   
    // Result of 8-bit * 16-bit = 24-bit
    reg signed [23:0] mult00, mult01, mult02;
    reg signed [23:0] mult10, mult11, mult12;
    reg signed [23:0] mult20, mult21, mult22;
    reg stage1_valid;

    always @(posedge clk) begin
        
        mult00 <= $signed({1'b0, p00}) * k00;
        mult01 <= $signed({1'b0, p01}) * k01;
        mult02 <= $signed({1'b0, p02}) * k02;

        mult10 <= $signed({1'b0, p10}) * k10;
        mult11 <= $signed({1'b0, p11}) * k11;
        mult12 <= $signed({1'b0, p12}) * k12;

        mult20 <= $signed({1'b0, p20}) * k20;
        mult21 <= $signed({1'b0, p21}) * k21;
        mult22 <= $signed({1'b0, p22}) * k22;
        
        stage1_valid <= valid_in;
    end

  
    // STAGE 2: ADDER TREE (Partial Sums)
   
    // Add rows together to reduce 9 values to 3 values
    reg signed [ACC_W-1:0] sum_row0;
    reg signed [ACC_W-1:0] sum_row1;
    reg signed [ACC_W-1:0] sum_row2;
    reg stage2_valid;

    always @(posedge clk) begin
        sum_row0 <= mult00 + mult01 + mult02;
        sum_row1 <= mult10 + mult11 + mult12;
        sum_row2 <= mult20 + mult21 + mult22;
        
        stage2_valid <= stage1_valid;
    end


    // STAGE 3: FINAL ACCUMULATION + BIAS
  
    always @(posedge clk) begin
        if (rst) begin
            conv_out <= 0;
            valid_out <= 0;
        end else begin
            // Sum the rows and add the bias
            conv_out <= sum_row0 + sum_row1 + sum_row2 + bias;
            valid_out <= stage2_valid;
        end
    end

endmodule
module weight_rom #(
    parameter DW = 16,
    parameter NUM_LAYERS = 3,
    parameter TOTAL_WEIGHTS = 1024 // Size of your weight file
)(
    input wire clk,
    // We address weights linearly for simplicity in this demo
    input wire [15:0] read_addr, 
    
    // Output the full 3x3 kernel (9 weights) at once
    output reg signed [DW-1:0] k00, k01, k02,
    output reg signed [DW-1:0] k10, k11, k12,
    output reg signed [DW-1:0] k20, k21, k22
);

    // 1. The ROM Array
    reg signed [DW-1:0] rom [0:TOTAL_WEIGHTS-1];

    // 2. Load Weights from File (Simulation Only)
    initial begin
        // You MUST create a text file named "weights.hex"
        // Format: One 16-bit hex number per line
        $readmemh("weights.hex", rom);
    end

    // 3. Read Logic
    always @(posedge clk) begin
        // We assume the weights in the file are stored in groups of 9
        // Address 0 -> k00, Address 1 -> k01 ... Address 8 -> k22
        
        // Calculate base address (Optimized for simulation)
        // In real hardware, this multiply is expensive, but fine for test.
        // If read_addr is "Filter 0", we read rom[0]..rom[8]
        
        k00 <= rom[read_addr*9 + 0];
        k01 <= rom[read_addr*9 + 1];
        k02 <= rom[read_addr*9 + 2];
        
        k10 <= rom[read_addr*9 + 3];
        k11 <= rom[read_addr*9 + 4];
        k12 <= rom[read_addr*9 + 5];
        
        k20 <= rom[read_addr*9 + 6];
        k21 <= rom[read_addr*9 + 7];
        k22 <= rom[read_addr*9 + 8];
    end

endmodule
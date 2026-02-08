module weight_rom (
    input wire clk,
    // Output: 4 Filters x 9 Weights x 16 bits
    output reg signed [15:0] k00_0, k01_0, k02_0, k10_0, k11_0, k12_0, k20_0, k21_0, k22_0, // Filter 0
    output reg signed [15:0] k00_1, k01_1, k02_1, k10_1, k11_1, k12_1, k20_1, k21_1, k22_1, // Filter 1
    output reg signed [15:0] k00_2, k01_2, k02_2, k10_2, k11_2, k12_2, k20_2, k21_2, k22_2, // Filter 2
    output reg signed [15:0] k00_3, k01_3, k02_3, k10_3, k11_3, k12_3, k20_3, k21_3, k22_3  // Filter 3
);

    // Storage for 36 weights
    reg signed [15:0] rom [0:35];

    initial begin
        $readmemh("weights.hex", rom);
    end

    always @(posedge clk) begin
        // Filter 0 
        k00_0 <= rom[0]; k01_0 <= rom[1]; k02_0 <= rom[2];
        k10_0 <= rom[3]; k11_0 <= rom[4]; k12_0 <= rom[5];
        k20_0 <= rom[6]; k21_0 <= rom[7]; k22_0 <= rom[8];

        // Filter 1 
        k00_1 <= rom[9];  k01_1 <= rom[10]; k02_1 <= rom[11];
        k10_1 <= rom[12]; k11_1 <= rom[13]; k12_1 <= rom[14];
        k20_1 <= rom[15]; k21_1 <= rom[16]; k22_1 <= rom[17];

        // Filter 2
        k00_2 <= rom[18]; k01_2 <= rom[19]; k02_2 <= rom[20];
        k10_2 <= rom[21]; k11_2 <= rom[22]; k12_2 <= rom[23];
        k20_2 <= rom[24]; k21_2 <= rom[25]; k22_2 <= rom[26];

        // Filter 3 
        k00_3 <= rom[27]; k01_3 <= rom[28]; k02_3 <= rom[29];
        k10_3 <= rom[30]; k11_3 <= rom[31]; k12_3 <= rom[32];
        k20_3 <= rom[33]; k21_3 <= rom[34]; k22_3 <= rom[35];
    end
endmodule
module line_buffer_yolo #(
    parameter IMG_W = 64,   
    parameter DW = 8        
)(
    input wire clk,
    input wire rst,
    input wire pixel_valid,
    input wire [DW-1:0] pixel_in,

    // The 3x3 Window Output
    output reg [DW-1:0] w00, w01, w02, // Top Row
    output reg [DW-1:0] w10, w11, w12, // Mid Row
    output reg [DW-1:0] w20, w21, w22, // Bot Row
    output reg window_valid
);

    // 1. RAM definitions
    reg [DW-1:0] lb0 [0:IMG_W-1]; 
    reg [DW-1:0] lb1 [0:IMG_W-1]; 
    
    reg [$clog2(IMG_W)-1:0] wr_ptr;

    reg [DW-1:0] pixel_d; 
    
    // RAM Read Data
    reg [DW-1:0] lb0_out;
    reg [DW-1:0] lb1_out;

    always @(posedge clk) begin
        if (pixel_valid) begin
            // 1. Capture Input into Delay Register
            pixel_d <= pixel_in;

            // 2. READ Old Data (Synchronous Read)
            lb0_out <= lb0[wr_ptr];
            lb1_out <= lb1[wr_ptr];

            // 3. WRITE New Data 
            
            lb1[wr_ptr] <= lb0[wr_ptr]; 
            lb0[wr_ptr] <= pixel_in;
        end
    end

    // Pointer Management
    always @(posedge clk) begin
        if (rst) 
            wr_ptr <= 0;
        else if (pixel_valid) begin
            if (wr_ptr == IMG_W - 1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1;
        end
    end

    // 3x3 Sliding Window
    always @(posedge clk) begin
        if (pixel_valid) begin
            // Row 2 (Bottom)
            w22 <= pixel_d; 
            w21 <= w22;
            w20 <= w21;

            // Row 1 (Middle)
            w12 <= lb0_out;
            w11 <= w12;
            w10 <= w11;

            // Row 0 (Top)
            w02 <= lb1_out;
            w01 <= w02;
            w00 <= w01;
        end
    end

    // Validity Logic
    reg [9:0] col_count;
    reg [9:0] row_count;

    always @(posedge clk) begin
        if (rst) begin
            col_count <= 0;
            row_count <= 0;
            window_valid <= 0;
        end else if (pixel_valid) begin
            // Update Coordinates
            if (col_count == IMG_W - 1) begin
                col_count <= 0;
                row_count <= row_count + 1;
            end else begin
                col_count <= col_count + 1;
            end

            // Logic for "Valid 3x3"
            
            if (row_count >= 2 && col_count >= 2) 
                window_valid <= 1;
            else 
                window_valid <= 0;
        end else begin
            window_valid <= 0;
        end
    end

endmodule
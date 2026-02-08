`timescale 1ns / 1ps

module max_pool_window #(
    parameter DW = 16,
    parameter IMG_W = 416
)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire signed [DW-1:0] pixel_in,
    
    output reg signed [DW-1:0] pool_out,
    output reg valid_out
);

   
    // 1. INPUT SANITIZATION
    
    wire signed [DW-1:0] pixel_clean;
    assign pixel_clean = (^pixel_in === 1'bx) ? {DW{1'b0}} : pixel_in;

    
    // 2. THE LINE BUFFER
    
    reg signed [DW-1:0] lb [0:IMG_W-1];
    reg [$clog2(IMG_W)-1:0] wr_ptr;
    
    // Clean 'X' from RAM reads
    wire signed [DW-1:0] lb_raw_out = lb[wr_ptr];
    wire signed [DW-1:0] lb_clean_out = (^lb_raw_out === 1'bx) ? {DW{1'b0}} : lb_raw_out;

    integer i;
    initial begin
        wr_ptr = 0;
        for (i = 0; i < IMG_W; i = i + 1) lb[i] = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            for (i = 0; i < IMG_W; i = i + 1) lb[i] <= 0;
        end else if (valid_in) begin
            // Write NEW pixel
            lb[wr_ptr] <= pixel_clean; 
            wr_ptr <= (wr_ptr == IMG_W - 1) ? 0 : wr_ptr + 1;
        end
    end


    // 3. THE WINDOW REGISTERS
   
    reg signed [DW-1:0] w00, w01, w10, w11;

    initial begin
        w00 = 0; w01 = 0; w10 = 0; w11 = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            w00 <= 0; w01 <= 0; w10 <= 0; w11 <= 0;
        end else if (valid_in) begin
            
            // 1. Bottom Row: Immediate from Input (Cycle 1)
            w11 <= pixel_clean; 
            
            // 2. Top Row: Immediate from RAM (Cycle 1)
            
            w01 <= lb_clean_out; 
            
            // Shift Left
            w10 <= w11;
            w00 <= w01;
        end
    end

   
    // 4. MAX LOGIC
    
    reg signed [DW-1:0] max_top, max_bot, max_final;
    always @(*) begin
        max_top = (w00 > w01) ? w00 : w01;
        max_bot = (w10 > w11) ? w10 : w11;
        max_final = (max_top > max_bot) ? max_top : max_bot;
    end

   
    // 5. OUTPUT PIPELINE
   
    reg [9:0] row_cnt, col_cnt;
    reg val_d1;

    initial begin
        pool_out = 0; valid_out = 0;
        val_d1 = 0; 
        row_cnt = 0; col_cnt = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            pool_out <= 0;
            valid_out <= 0;
            val_d1 <= 0; 
            row_cnt <= 0; col_cnt <= 0;
        end else begin
            // Data Path: Input -> w11 -> pool_out (2 Cycles)
            // Valid Path: Input -> val_d1 -> valid_out (2 Cycles)
            pool_out  <= max_final;
            valid_out <= val_d1;

            if (valid_in) begin
                // Update Coords
                if (col_cnt == IMG_W - 1) begin
                    col_cnt <= 0;
                    if (row_cnt == IMG_W - 1) row_cnt <= 0;
                    else row_cnt <= row_cnt + 1;
                end else begin
                    col_cnt <= col_cnt + 1;
                end
                
                // TRIGGER: Odd Row & Odd Col (End of 2x2 Block)
                if (row_cnt[0] == 1 && col_cnt[0] == 1) 
                    val_d1 <= 1;
                else 
                    val_d1 <= 0;
            end else begin
                val_d1 <= 0;
            end
        end
    end
endmodule
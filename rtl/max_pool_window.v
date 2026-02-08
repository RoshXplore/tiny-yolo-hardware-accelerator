`timescale 1ns / 1ps

module max_pool_window #(
    parameter DW = 16,
    parameter IMG_W = 64
)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire signed [DW-1:0] pixel_in,
    
    output reg signed [DW-1:0] pool_out,
    output reg valid_out
);

    wire signed [DW-1:0] pixel_clean;
    assign pixel_clean = (^pixel_in === 1'bx) ? {DW{1'b0}} : pixel_in;

    localparam signed [DW-1:0] MIN_INT = {1'b1, {(DW-1){1'b0}}};

    
    // 1. THE LINE BUFFER (With Valid Flags)
  
    reg signed [DW-1:0] lb [0:IMG_W-1];
    reg [IMG_W-1:0] lb_valid; // 1 = Valid Data, 0 = Empty/Reset
    reg [$clog2(IMG_W)-1:0] wr_ptr;
    
    wire signed [DW-1:0] ram_val = lb[wr_ptr];
    wire is_cell_valid = lb_valid[wr_ptr];
    
    
    wire signed [DW-1:0] lb_out_safe = (is_cell_valid) ? ram_val : MIN_INT;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            lb_valid <= 0; // Clear all valid flags on reset
        end else if (valid_in) begin
            lb[wr_ptr] <= pixel_clean;
            lb_valid[wr_ptr] <= 1'b1; // Mark this specific cell as valid
            
            if (wr_ptr == IMG_W - 1) wr_ptr <= 0;
            else wr_ptr <= wr_ptr + 1;
        end
    end

    
    // 2. THE WINDOW REGISTERS
    
    reg signed [DW-1:0] w00, w01, w10, w11;

    always @(posedge clk) begin
        if (rst) begin
            w00 <= MIN_INT; w01 <= MIN_INT; w10 <= MIN_INT; w11 <= MIN_INT;
        end else if (valid_in) begin
            w11 <= pixel_clean; 
            w01 <= lb_out_safe; 
            w10 <= w11;
            w00 <= w01;
        end
    end

    
    // 3. MAX LOGIC

    reg signed [DW-1:0] max_top, max_bot, max_final;
    always @(*) begin
        max_top = (w00 > w01) ? w00 : w01;
        max_bot = (w10 > w11) ? w10 : w11;
        max_final = (max_top > max_bot) ? max_top : max_bot;
    end

  
    // 4. OUTPUT PIPELINE
  
    reg [9:0] row_cnt, col_cnt;
    reg val_d1;

    always @(posedge clk) begin
        if (rst) begin
            pool_out <= MIN_INT; 
            valid_out <= 0;
            val_d1 <= 0; 
            row_cnt <= 0; col_cnt <= 0;
        end else begin
            pool_out <= max_final;
            valid_out <= val_d1;

            if (valid_in) begin
                if (col_cnt == IMG_W - 1) begin
                    col_cnt <= 0;
                    if (row_cnt == IMG_W - 1) row_cnt <= 0;
                    else row_cnt <= row_cnt + 1;
                end else begin
                    col_cnt <= col_cnt + 1;
                end
                
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
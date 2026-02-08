`timescale 1ns / 1ps

module cnn_top #(
    parameter IMG_W = 64,       
    parameter DW = 16,          
    parameter OUT_MEM_DEPTH = 961 // 31x31 output
)(
    input wire clk,
    input wire rst,
    input wire start,           
    
    output reg processing_done, 
    input wire [9:0] debug_read_addr, 
    output wire [DW-1:0] debug_data_out
);

    
    // 0. SIGNAL DECLARATIONS
    
    wire [7:0] w00, w01, w02, w10, w11, w12, w20, w21, w22;
    wire win_valid, conv_valid, pool_valid;
    wire signed [31:0] conv_out_raw, relu_out, pool_out;
    wire signed [15:0] k00, k01, k02, k10, k11, k12, k20, k21, k22;

   
    // 1. STATE MACHINE (SILICON-GRADE HANDSHAKE)
   
    localparam STATE_IDLE = 2'd0;
    localparam STATE_RUN  = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] current_state, next_state;
    reg [10:0] pixel_counter; 

    // State Register
    always @(posedge clk) begin
        if (rst) current_state <= STATE_IDLE;
        else current_state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        next_state = current_state; 
        
        case (current_state)
            STATE_IDLE: begin
                if (start) next_state = STATE_RUN;
            end

            STATE_RUN: begin
                // Check if we just received the LAST VALID PIXEL
                
                if (pool_valid && pixel_counter == OUT_MEM_DEPTH - 1) 
                    next_state = STATE_DONE;
            end

            STATE_DONE: begin
                // Stay here forever until hardware Reset.
                
                next_state = STATE_DONE;
            end
        endcase
    end

    // Interrupt Logic (Latched)
    always @(posedge clk) begin
        if (rst) 
            processing_done <= 0;
        else if (current_state == STATE_DONE) 
            processing_done <= 1; 
    end

   
    // 2. DATA PIPELINE CONTROL
  
    wire enable_pipeline = (current_state == STATE_RUN);

    reg [7:0] img_mem [0:4095]; 
    reg [12:0] img_read_addr; 
    reg img_valid;
    
    initial $readmemh("image.hex", img_mem); 

    always @(posedge clk) begin
        if (rst) begin
            img_read_addr <= 0;
            img_valid <= 0;
        end else if (enable_pipeline && img_read_addr < 4096) begin
            img_valid <= 1;
            img_read_addr <= img_read_addr + 1;
        end else begin
            img_valid <= 0;
        end
    end
    
    wire [7:0] pixel_stream = img_mem[img_read_addr];

   
    // 3. INSTANTIATE MODULES
    
    
    // Line Buffer (IMG_W=64)
    line_buffer_yolo #( .IMG_W(IMG_W), .DW(8) ) lb_inst (
        .clk(clk), .rst(rst), .pixel_valid(img_valid), .pixel_in(pixel_stream),
        .w00(w00), .w01(w01), .w02(w02), .w10(w10), .w11(w11), .w12(w12), .w20(w20), .w21(w21), .w22(w22),
        .window_valid(win_valid)
    );

    // Weight ROM
    weight_rom #( .DW(16) ) w_rom_inst (
        .clk(clk), .read_addr(16'd0), 
        .k00(k00), .k01(k01), .k02(k02), .k10(k10), .k11(k11), .k12(k12), .k20(k20), .k21(k21), .k22(k22)
    );

    // Conv Core
    conv_core_3x3 core_inst (
        .clk(clk), .rst(rst), .valid_in(win_valid),
        .p00(w00), .p01(w01), .p02(w02), .p10(w10), .p11(w11), .p12(w12), .p20(w20), .p21(w21), .p22(w22),
        .k00(k00), .k01(k01), .k02(k02), .k10(k10), .k11(k11), .k12(k12), .k20(k20), .k21(k21), .k22(k22),
        .bias(16'd0), .conv_out(conv_out_raw), .valid_out(conv_valid)
    );

    // ReLU
    leaky_relu #( .DW(32) ) relu_inst ( .clk(clk), .data_in(conv_out_raw), .data_out(relu_out) );
    
    reg relu_valid; 
    always @(posedge clk) begin
        if (rst) relu_valid <= 0;
        else relu_valid <= conv_valid;
    end

    // Max Pool 
    max_pool_window #( .DW(32), .IMG_W(62) ) pool_inst (
        .clk(clk), .rst(rst), .valid_in(relu_valid), .pixel_in(relu_out), .pool_out(pool_out), .valid_out(pool_valid)
    );

   
    // 4. OUTPUT COUNTER & RAM
    
    
    always @(posedge clk) begin
        if (rst) begin
            pixel_counter <= 0;
        end else if (pool_valid && pixel_counter < OUT_MEM_DEPTH) begin
            pixel_counter <= pixel_counter + 1;
        end
    end

    wire safe_write = pool_valid && (pixel_counter < OUT_MEM_DEPTH);

    output_ram #( .DW(DW), .MEM_DEPTH(OUT_MEM_DEPTH) ) ram_inst (
        .clk(clk),
        .write_en(safe_write),
        .data_in(pool_out[15:0]),
        .read_addr(debug_read_addr),
        .data_out(debug_data_out)
    );

endmodule
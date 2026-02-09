`timescale 1ns / 1ps

module cnn_top #(
    parameter IMG_W = 64,       
    parameter DW = 16,          
    parameter OUT_MEM_DEPTH = 961 
)(
    input wire clk,
    input wire rst,
    input wire start,           
    
    output reg processing_done, 
    input wire [9:0] debug_read_addr, 
    output wire [63:0] debug_data_out 
);

    
    // 0. SIGNAL DECLARATIONS
  
    wire [7:0] w00, w01, w02, w10, w11, w12, w20, w21, w22;
    wire win_valid;

    // Arrays for parallel processing lanes
    wire signed [31:0] conv_out [0:3];
    wire conv_valid [0:3];
    wire signed [31:0] relu_out [0:3];
    
    // 32-bit internal wires to prevent truncation
    wire signed [31:0] pool_out [0:3]; 
    wire pool_valid [0:3];
    
    wire signed [15:0] k[0:3][0:2][0:2];

   
    // 1. STATE MACHINE 
    
    localparam STATE_IDLE = 2'd0;
    localparam STATE_RUN  = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] current_state, next_state;
    reg [10:0] pixel_counter;
    
    always @(posedge clk) begin
        if (rst) current_state <= STATE_IDLE;
        else current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE: if (start) next_state = STATE_RUN;
            STATE_RUN:  if (pool_valid[0] && pixel_counter == OUT_MEM_DEPTH - 1) next_state = STATE_DONE;
            STATE_DONE: next_state = STATE_DONE;
        endcase
    end

    always @(posedge clk) begin
        if (rst) processing_done <= 0;
        else if (current_state == STATE_DONE) processing_done <= 1;
    end


    // 2. DATA INPUT

    wire enable_pipeline = (current_state == STATE_RUN);
    reg [7:0] img_mem [0:4095]; 
    reg [12:0] img_read_addr; 
    reg img_valid;
    initial $readmemh("image.hex", img_mem); 

    always @(posedge clk) begin
        if (rst) begin
            img_read_addr <= 0; img_valid <= 0;
        end else if (enable_pipeline && img_read_addr < 4096) begin
            img_valid <= 1;
            img_read_addr <= img_read_addr + 1;
        end else begin
            img_valid <= 0;
        end
    end
    
    wire [7:0] pixel_stream = img_mem[img_read_addr];

    
    // 3. CORE INSTANTIATION
    
    
    line_buffer_yolo #( .IMG_W(IMG_W), .DW(8) ) lb_inst (
        .clk(clk), .rst(rst), .pixel_valid(img_valid), .pixel_in(pixel_stream),
        .w00(w00), .w01(w01), .w02(w02), .w10(w10), .w11(w11), .w12(w12), .w20(w20), .w21(w21), .w22(w22),
        .window_valid(win_valid)
    );

    weight_rom rom_inst (
        .clk(clk),
        .k00_0(k[0][0][0]), .k01_0(k[0][0][1]), .k02_0(k[0][0][2]), .k10_0(k[0][1][0]), .k11_0(k[0][1][1]), .k12_0(k[0][1][2]), .k20_0(k[0][2][0]), .k21_0(k[0][2][1]), .k22_0(k[0][2][2]),
        .k00_1(k[1][0][0]), .k01_1(k[1][0][1]), .k02_1(k[1][0][2]), .k10_1(k[1][1][0]), .k11_1(k[1][1][1]), .k12_1(k[1][1][2]), .k20_1(k[1][2][0]), .k21_1(k[1][2][1]), .k22_1(k[1][2][2]),
        .k00_2(k[2][0][0]), .k01_2(k[2][0][1]), .k02_2(k[2][0][2]), .k10_2(k[2][1][0]), .k11_2(k[2][1][1]), .k12_2(k[2][1][2]), .k20_2(k[2][2][0]), .k21_2(k[2][2][1]), .k22_2(k[2][2][2]),
        .k00_3(k[3][0][0]), .k01_3(k[3][0][1]), .k02_3(k[3][0][2]), .k10_3(k[3][1][0]), .k11_3(k[3][1][1]), .k12_3(k[3][1][2]), .k20_3(k[3][2][0]), .k21_3(k[3][2][1]), .k22_3(k[3][2][2])
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : LANE
            
            // 1. CONV CORE
            conv_core_3x3 conv (
                .clk(clk), .rst(rst), .valid_in(win_valid),
                .p00(w00), .p01(w01), .p02(w02), .p10(w10), .p11(w11), .p12(w12), .p20(w20), .p21(w21), .p22(w22),
                .k00(k[i][0][0]), .k01(k[i][0][1]), .k02(k[i][0][2]), 
                .k10(k[i][1][0]), .k11(k[i][1][1]), .k12(k[i][1][2]), 
                .k20(k[i][2][0]), .k21(k[i][2][1]), .k22(k[i][2][2]),
                .bias(16'd0), 
                .conv_out(conv_out[i]), .valid_out(conv_valid[i])
            );

            // 2. TIMING ALIGNMENT REGISTER 
				
            reg relu_val_reg; 
            always @(posedge clk) begin
                if (rst) relu_val_reg <= 0;
                else relu_val_reg <= conv_valid[i];
            end

            // 3. RELU 
            leaky_relu #( .DW(32) ) relu ( 
                .clk(clk), .data_in(conv_out[i]), .data_out(relu_out[i]) 
            );

            // 4. MAX POOL
            max_pool_window #( .DW(32), .IMG_W(62) ) pool (
                .clk(clk), .rst(rst), 
                .valid_in(relu_val_reg), 
                .pixel_in(relu_out[i]), 
                .pool_out(pool_out[i]), .valid_out(pool_valid[i])
            );
        end
    endgenerate

    
    // 4. OUTPUT COUNTER & RAM (Wide)
    
    always @(posedge clk) begin
        if (rst) begin
            pixel_counter <= 0;
        end else if (pool_valid[0] && pixel_counter < OUT_MEM_DEPTH) begin
            pixel_counter <= pixel_counter + 1;
        end
    end

    wire safe_write = pool_valid[0] && (pixel_counter < OUT_MEM_DEPTH);
    
    // bottom 16 bits
    wire [63:0] packed_data = {pool_out[3][15:0], pool_out[2][15:0], pool_out[1][15:0], pool_out[0][15:0]};

    output_ram #( .DW(64), .MEM_DEPTH(OUT_MEM_DEPTH) ) ram_inst (
        .clk(clk),
        .write_en(safe_write),
        .data_in(packed_data),
        .read_addr(debug_read_addr),
        .data_out(debug_data_out)
    );
endmodule
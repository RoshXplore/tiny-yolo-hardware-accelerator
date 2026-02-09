`timescale 1ns / 1ps

module tb_cnn();

    // Standard Signals
    reg clk;
    reg rst;
    reg start;
    wire processing_done;
    wire [63:0] debug_data_out;
    reg [9:0] debug_read_addr;

    // Instantiate UUT
    cnn_top #( 
        .IMG_W(64), 
        .DW(16), 
        .OUT_MEM_DEPTH(961) 
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .processing_done(processing_done),
        .debug_read_addr(debug_read_addr),
        .debug_data_out(debug_data_out)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // File Handling
    integer f_out;
    integer i;
    
    // DEBUG
    wire        db_win_valid  = uut.win_valid;
    wire        db_conv_valid = uut.conv_valid[0];
    wire [31:0] db_conv_out   = uut.conv_out[0];
    wire [31:0] db_relu_out   = uut.relu_out[0];
    wire        db_pool_valid = uut.pool_valid[0];
    wire [31:0] db_pool_out   = uut.pool_out[0];
    wire [10:0] db_pixel_cnt  = uut.pixel_counter;
    wire        db_ram_we     = uut.ram_inst.write_en;

    initial begin
        // Initial setup
        clk = 0;
        rst = 1;
        start = 0;
        debug_read_addr = 0;
        
        f_out = $fopen("fpga_output_heatmap.txt", "w");
        if (f_out == 0) begin
            $display("ERROR: Could not open output file!");
            $stop;
        end

        // Reset
        $display("\n--- STARTING DEBUG SIMULATION ---");
        $display("Time | ConvV | ConvOut | ReLUOut | PoolV | PoolOut | PixCnt | RAM_WE");

        #100;
        rst = 0;
        #20;

        // Start
        start = 1;
        #10;
        start = 0;

        // Monitoring Loop
        while (!processing_done) begin
            @(posedge clk);
            if (db_pool_valid || (db_pixel_cnt < 5 && db_pool_valid)) begin
                $display("%t | %b | %d | %d | %b | %d | %d | %b", 
                         $time, db_conv_valid, db_conv_out, db_relu_out, 
                         db_pool_valid, db_pool_out, db_pixel_cnt, db_ram_we);
            end
        end

        #20;
        $display("Inference Complete! Reading Output RAM...");

        for (i = 0; i < 961; i = i + 1) begin
            debug_read_addr = i;
            #10; 
            $fwrite(f_out, "%h\n", debug_data_out);
        end

        $fclose(f_out);
        $display("SUCCESS: Results saved to fpga_output_heatmap.txt");
        $finish;
    end

endmodule
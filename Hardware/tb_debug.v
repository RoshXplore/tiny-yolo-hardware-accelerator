`timescale 1ns / 1ps

module tb_debug();

    // 1. Signals
    reg clk;
    reg rst;
    reg start;
    wire processing_done;docs/.gitignore
    wire [15:0] debug_data_out;
    reg [9:0] debug_read_addr;

    // 2. Instantiate UUT
    // Note: Make sure OUT_MEM_DEPTH is 961
    cnn_top #( .IMG_W(64), .DW(16), .OUT_MEM_DEPTH(961) ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .processing_done(processing_done),
        .debug_read_addr(debug_read_addr),
        .debug_data_out(debug_data_out)
    );

    // 3. Clock
    always #5 clk = ~clk;

    // ============================================================
    // 4. THE X-RAY VISION (Hierarchical Access)
    // ============================================================
    // We create wires that "spy" on internal registers
    
    // Spy on FSM
    wire [1:0] fsm_state = uut.current_state;
    wire [10:0] pixels_collected = uut.pixel_counter;

    // Spy on Line Buffer
    wire lb_valid = uut.lb_inst.window_valid;
    wire [9:0] lb_col = uut.lb_inst.col_count;

    // Spy on Conv Core
    wire conv_valid = uut.core_inst.valid_out;

    // Spy on Max Pool (CRITICAL AREA)
    wire pool_valid = uut.pool_inst.valid_out;
    wire [9:0] pool_col_cnt = uut.pool_inst.col_cnt;
    wire pool_x_tog = uut.pool_inst.x_toggle;
    wire pool_y_tog = uut.pool_inst.y_toggle;

    // ============================================================
    // 5. DEBUG MONITOR
    // ============================================================
    initial begin
        // Setup
        clk = 0; rst = 1; start = 0;
        
        // Reset
        #100; rst = 0; #20;
        
        // Start
        $display("[TIME %0t] Starting Inference...", $time);
        start = 1; #10; start = 0;

        // --- WATCHDOG LOOP ---
        // We check status every 1000ns to see if we are stuck
        while (processing_done == 0) begin
            #1000; 
            
            // Print Status
            $display("[TIME %0t] State: %d | Pixels Collected: %d / 961", 
                     $time, fsm_state, pixels_collected);
            
            $display("    -> Buffer Valid: %b (Col: %d)", lb_valid, lb_col);
            $display("    -> Pool   Valid: %b (Col: %d | X:%b Y:%b)", 
                     pool_valid, pool_col_cnt, pool_x_tog, pool_y_tog);

            // AUTO-KILL if stuck too long (e.g., 500,000 ns)
            if ($time > 500000) begin
                $display("\n[ERROR] SIMULATION TIMED OUT!");
                $display("CRITICAL DEBUG INFO:");
                if (pixels_collected == 0) $display(" -> Pipeline never started (0 pixels). Check Hex files or Reset.");
                else if (pixels_collected < 961) $display(" -> Stuck at %d pixels. Likely Max Pool Width Mismatch.", pixels_collected);
                $stop;
            end
        end

        $display("[SUCCESS] Processing Done Signal Received!");
        $stop;
    end

endmodule
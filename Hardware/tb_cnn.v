`timescale 1ns / 1ps

module tb_cnn();

    // 1. Signals to connect to the Accelerator
    reg clk;
    reg rst;
    reg start;
    
    wire processing_done;       // The interrupt from FPGA
    wire [15:0] debug_data_out; // The result data
    reg [9:0] debug_read_addr;  // The address we want to read

    // 2. Instantiate the Unit Under Test (UUT)
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

    // 3. Clock Generation (100MHz = 10ns period)
    always #5 clk = ~clk;

    // 4. File Handling Variables
    integer f_out;
    integer i;

    // 5. The Main Test Process
    initial begin
        // INITIAL SETUP 
        clk = 0;
        rst = 1;
        start = 0;
        debug_read_addr = 0;
        
        // Open the file to save results
        f_out = $fopen("fpga_output_heatmap.txt", "w");
        if (f_out == 0) begin
            $display("ERROR: Could not open output file!");
            $stop;
        end

        // RESET SEQUENCE
        $display("Applying Reset...");
        #100;       // Wait 100ns
        rst = 0;    // Release Reset
        #20;

        // START PROCESSING 
        $display("Starting CNN Accelerator...");
        start = 1;  // Pulse Start Signal
        #10;
        start = 0;

        // WAIT FOR INTERRUPT 
        $display("Waiting for processing_done signal...");
        wait(processing_done == 1);
        
        // Safety delay to ensure RAM is stable
        #20; 
        $display("Inference Complete! Reading Output RAM...");

        // READ RESULTS 
        // Loop through the 1024 output pixels (32x32)
        for (i = 0; i < 961; i = i + 1) begin
            debug_read_addr = i;
            #10; // Wait 1 clock cycle for RAM to output data
            
            // Write to text file
            // $signed ensures we write negative numbers correctly if needed
            $fwrite(f_out, "%d\n", $signed(debug_data_out));
        end

        // FINISH 
        $fclose(f_out);
    
        $display("SUCCESS: Results saved to fpga_output_heatmap.txt");
   
        $stop; // Stop simulation
    end

endmodule
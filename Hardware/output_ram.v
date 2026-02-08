module output_ram #(
    parameter DW = 16,
    parameter MEM_DEPTH = 1024 // Size of output image (32x32 = 1024)
)(
    input wire clk,
    
    // WRITE PORT
    input wire write_en,           // Connect to pool_valid
    input wire [DW-1:0] data_in,   // Connect to pool_out
    
    // READ PORT
    input wire [9:0] read_addr,
    output reg [DW-1:0] data_out
);

    // 1. The Memory Array
    reg [DW-1:0] ram [0:MEM_DEPTH-1];
    
    // 2. The Auto-Incrementing Write Pointer
    reg [9:0] write_ptr;

    initial write_ptr = 0;

    // 3. Write Logic (The "Catcher")
    always @(posedge clk) begin
        if (write_en) begin
            ram[write_ptr] <= data_in;
            
            // Move pointer to next slot
            if (write_ptr < MEM_DEPTH - 1)
                write_ptr <= write_ptr + 1;
        end
    end

    // 4. Read Logic (The "Inspector")
    always @(posedge clk) begin
        data_out <= ram[read_addr];
    end

endmodule
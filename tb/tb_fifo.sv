`timescale 1ps/1ps

module tb_fifo;
    // Parameters
    parameter DATA_WIDTH = 32;
    parameter FIFO_DEPTH = 16;
    
    // Debug message at start
    initial begin
        $display("\n=== Starting FIFO Testbench ===");
        $display("Parameters: DATA_WIDTH=%0d, FIFO_DEPTH=%0d", DATA_WIDTH, FIFO_DEPTH);
        
        // Setup VCD file
        $dumpfile("tb_fifo.vcd");
        $dumpvars(0, tb_fifo);
    end
    
    // Signals
    reg clk;
    reg rst_n;
    reg fifo_wr_en;
    reg fifo_rd_en;
    reg [DATA_WIDTH-1:0] fifo_wr_data;
    wire [DATA_WIDTH-1:0] fifo_rd_data;
    wire fifo_full;
    wire fifo_empty;
    wire [$clog2(FIFO_DEPTH):0] fifo_count;
    
    // Instantiate FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),
        .din(fifo_wr_data),
        .dout(fifo_rd_data),
        .full(fifo_full),
        .empty(fifo_empty),
        .count(fifo_count)
    );
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Write task with proper handshaking
    task write_fifo(input [31:0] data, output success);
        begin
            // Wait for FIFO to not be full
            wait(!fifo_full);
            @(posedge clk);
            fifo_wr_en = 1;
            fifo_wr_data = data;
            @(posedge clk);
            fifo_wr_en = 0;
            success = 1;
        end
    endtask
    
    // Read task with proper handshaking
    task read_fifo(output [31:0] data, output success);
        begin
            // Wait for FIFO to not be empty
            wait(!fifo_empty);
            @(posedge clk);
            fifo_rd_en = 1;
            @(posedge clk);
            data = fifo_rd_data;
            fifo_rd_en = 0;
            success = 1;
        end
    endtask
    
    // Test stimulus
    initial begin
        integer i;
        reg [31:0] data;
        reg success;

        // Reset
        rst_n = 0; fifo_wr_en = 0; fifo_rd_en = 0; fifo_wr_data = 0;
        #100; rst_n = 1; #20;

        // 1. Write until FIFO full
        $display("=== Test 1: Write until FIFO full ===");
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            write_fifo($urandom, success);
            if (!success) $display("Write failed at i=%0d", i);
            #10;
        end
        #10;
        if (!fifo_full) $display("Error: FIFO should be full!");
        else $display("Test 1 Passed: FIFO is full.");

        // 2. Read FIFO
        $display("=== Test 2: Read FIFO ===");
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            read_fifo(data, success);
            if (!success) $display("Read failed at i=%0d", i);
            #10;
        end
        #10;
        if (!fifo_empty) $display("Error: FIFO should be empty!");
        else $display("Test 2 Passed: FIFO is empty.");

        // 3. Write and read simultaneously
        $display("=== Test 3: Write and read simultaneously ===");
        fork
            begin : wr
                for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                    write_fifo($urandom, success);
                    #10;
                end
            end
            begin : rd
                for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                    read_fifo(data, success);
                    #10;
                end
            end
        join
        $display("Test 3 Passed: Simultaneous write/read completed.");

        $display("=== All tests completed ===");
        #100 $finish;
    end
    
    // Monitor
    initial begin
        $monitor("T=%0t rst_n=%b wr_en=%b rd_en=%b full=%b empty=%b count=%0d wr_data=%h rd_data=%h",
            $time, rst_n, fifo_wr_en, fifo_rd_en, fifo_full, fifo_empty, fifo_count, fifo_wr_data, fifo_rd_data);
    end
endmodule 
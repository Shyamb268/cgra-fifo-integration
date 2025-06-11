module tb_fifo;
    // Parameters
    parameter DATA_WIDTH = 32;
    parameter FIFO_DEPTH = 16;
    
    // Debug message at start
    initial begin
        $display("\n=== Starting FIFO Testbench ===");
        $display("Parameters: DATA_WIDTH=%0d, FIFO_DEPTH=%0d", DATA_WIDTH, FIFO_DEPTH);
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
    wire [4:0] fifo_count;
    
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
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Write data to FIFO
    task write_fifo;
        input [31:0] data;
        output success;
        begin
            if (fifo_full) begin
                $display("Write failed: FIFO is full");
                success = 0;
            end else begin
                fifo_wr_en = 1;
                fifo_wr_data = data;
                @(posedge clk);
                fifo_wr_en = 0;
                success = 1;
                $display("Write successful: data=%h, count=%0d", data, fifo_count);
            end
        end
    endtask
    
    // Read data from FIFO
    task read_fifo;
        output [31:0] data;
        output success;
        begin
            if (fifo_empty) begin
                $display("Read failed: FIFO is empty");
                success = 0;
            end else begin
                fifo_rd_en = 1;
                @(posedge clk);
                data = fifo_rd_data;
                fifo_rd_en = 0;
                success = 1;
                $display("Read successful: data=%h, count=%0d", data, fifo_count);
            end
        end
    endtask
    
    // Initialize testbench
    task initialize_testbench;
        begin
            $display("\nInitializing testbench...");
            rst_n = 0;
            fifo_wr_en = 0;
            fifo_rd_en = 0;
            fifo_wr_data = 0;
            #100;
            rst_n = 1;
            #20;
            $display("Initialization complete. FIFO is empty, count=%0d", fifo_count);
        end
    endtask
    
    // Test stimulus
    initial begin
        // Initialize
        $display("\n=== Test 0: Initialization ===");
        initialize_testbench();
        #20;
        
        // Test 1: Write until full
        $display("\n=== Test 1: Write until full ===");
        repeat (FIFO_DEPTH) begin
            reg success;
            write_fifo($urandom, success);
            if (!success) begin
                $display("Error: Failed to write to FIFO");
                $finish;
            end
            #20;  // Increased delay between writes
        end
        
        if (!fifo_full) begin
            $display("Error: FIFO should be full");
            $finish;
        end
        $display("Test 1 Passed: FIFO is full with count=%0d", fifo_count);
        #50;  // Added delay after test 1
        
        // Test 2: Read until empty
        $display("\n=== Test 2: Read until empty ===");
        repeat (FIFO_DEPTH) begin
            reg [31:0] data;
            reg success;
            read_fifo(data, success);
            if (!success) begin
                $display("Error: Failed to read from FIFO");
                $finish;
            end
            #20;  // Increased delay between reads
        end
        
        if (!fifo_empty) begin
            $display("Error: FIFO should be empty");
            $finish;
        end
        $display("Test 2 Passed: FIFO is empty with count=%0d", fifo_count);
        #50;  // Added delay after test 2
        
        // Test 3: Write and read simultaneously
        $display("\n=== Test 3: Write and read simultaneously ===");
        fork
            begin
                repeat (FIFO_DEPTH/2) begin
                    reg success;
                    write_fifo($urandom, success);
                    if (!success) begin
                        $display("Error: Failed to write to FIFO");
                        $finish;
                    end
                    #20;
                end
            end
            begin
                repeat (FIFO_DEPTH/2) begin
                    reg [31:0] data;
                    reg success;
                    read_fifo(data, success);
                    if (!success) begin
                        $display("Error: Failed to read from FIFO");
                        $finish;
                    end
                    #20;
                end
            end
        join
        $display("Test 3 Passed: Simultaneous read/write completed with count=%0d", fifo_count);
        #50;  // Added delay after test 3
        
        // Test 4: Reset behavior
        $display("\n=== Test 4: Reset behavior ===");
        rst_n = 0;
        #20;
        if (!fifo_empty || fifo_full) begin
            $display("Error: FIFO should be empty after reset");
            $finish;
        end
        rst_n = 1;
        #20;
        $display("Test 4 Passed: Reset behavior verified with count=%0d", fifo_count);
        
        $display("\n=== All FIFO tests completed successfully! ===");
        #100;  // Added final delay
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time=%0t rst_n=%b fifo_wr_en=%b fifo_rd_en=%b fifo_full=%b fifo_empty=%b fifo_wr_data=%0h fifo_rd_data=%0h count=%0d",
                 $time, rst_n, fifo_wr_en, fifo_rd_en, fifo_full, fifo_empty, fifo_wr_data, fifo_rd_data, fifo_count);
    end
endmodule 
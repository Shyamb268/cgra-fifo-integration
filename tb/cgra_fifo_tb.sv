`timescale 1ns/1ps

module cgra_fifo_tb;
    // Parameters
    localparam NUM_INSTANCES = 2;
    localparam DATA_WIDTH = 32;
    localparam FIFO_DEPTH = 16;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // FIFO interface
    logic                     fifo_wr_en;
    logic [DATA_WIDTH-1:0]    fifo_wr_data;
    logic                     fifo_full;
    logic [$clog2(FIFO_DEPTH):0] fifo_count;
    
    // CGRA control interface
    logic [NUM_INSTANCES-1:0] cgra_start;
    logic [NUM_INSTANCES-1:0] cgra_done;
    
    // CGRA data interface - Updated for new interface
    logic [NUM_INSTANCES-1:0] cgra_result_rd_en;
    logic [NUM_INSTANCES-1:0] cgra_result_ready;
    logic [DATA_WIDTH-1:0]    cgra_result_data [NUM_INSTANCES];
    
    // Instantiate the CGRA FIFO wrapper
    cgra_fifo_wrapper #(
        .NUM_INSTANCES(NUM_INSTANCES),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .cgra_start     (cgra_start),
        .cgra_done      (cgra_done),
        .fifo_wr_en     (fifo_wr_en),
        .fifo_wr_data   (fifo_wr_data),
        .fifo_full      (fifo_full),
        .fifo_count     (fifo_count),
        .cgra_result_rd_en (cgra_result_rd_en),
        .cgra_result_ready (cgra_result_ready),
        .cgra_result_data (cgra_result_data)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus with improved debugging
    initial begin
        // Initialize signals
        rst_n = 0;
        fifo_wr_en = 0;
        fifo_wr_data = 0;
        cgra_start = 0;
        cgra_result_rd_en = 0;
        
        // Reset
        $display("=== Starting CGRA FIFO Testbench ===");
        $display("Time=%0t: Applying reset", $time);
        #100;
        rst_n = 1;
        $display("Time=%0t: Reset released", $time);
        #20;
        
        // Test 1: Write data to FIFO
        $display("Time=%0t: Writing %0d data items to FIFO", $time, FIFO_DEPTH/2);
        for (int i = 0; i < FIFO_DEPTH/2; i++) begin
            @(posedge clk);
            // Wait for FIFO to not be full
            wait(!fifo_full);
            fifo_wr_en = 1;
            fifo_wr_data = i + 1000; // Use predictable data
            $display("Time=%0t: Writing data[%0d] = %0d, count=%0d", $time, i, i+1000, fifo_count);
            @(posedge clk);
            fifo_wr_en = 0;
        end
        
        // Test 2: Start CGRA instances
        $display("Time=%0t: Starting CGRA instances", $time);
        @(posedge clk);
        cgra_start = '1;
        @(posedge clk);
        cgra_start = 0;
        
        // Test 3: Wait for completion
        $display("Time=%0t: Waiting for CGRA completion", $time);
        wait(cgra_done == '1);
        $display("Time=%0t: CGRA instances completed", $time);
        
        // Test 4: Read results from CGRA instances
        $display("Time=%0t: Reading results from CGRA instances", $time);
        for (int i = 0; i < NUM_INSTANCES; i++) begin
            @(posedge clk);
            if (cgra_result_ready[i]) begin
                cgra_result_rd_en[i] = 1;
                $display("Time=%0t: Instance %0d result ready: %0d", $time, i, cgra_result_data[i]);
                @(posedge clk);
                cgra_result_rd_en[i] = 0;
            end else begin
                $display("Time=%0t: Instance %0d not ready", $time, i);
            end
        end
        
        // End simulation
        $display("Time=%0t: Test completed", $time);
        #100;
        $finish;
    end
    
    // Enhanced monitoring with all key signals
    initial begin
        $monitor("Time=%0t rst_n=%b fifo_wr_en=%b fifo_wr_data=%h fifo_full=%b fifo_count=%0d cgra_done=%b",
                 $time, rst_n, fifo_wr_en, fifo_wr_data, fifo_full, fifo_count, cgra_done);
    end
    
    // Additional debug monitoring for CGRA result signals
    always @(posedge clk) begin
        for (int i = 0; i < NUM_INSTANCES; i++) begin
            if (cgra_result_rd_en[i] === 1'b1) begin
                $display("Time=%0t: CGRA[%0d] result_rd_en asserted, result_data=%0d", $time, i, cgra_result_data[i]);
            end
            if (cgra_result_ready[i] === 1'b1) begin
                $display("Time=%0t: CGRA[%0d] result_ready asserted", $time, i);
            end
        end
    end
    
    // Monitor for unknown signals
    always @(posedge clk) begin
        for (int i = 0; i < NUM_INSTANCES; i++) begin
            if (cgra_result_rd_en[i] === 1'bx) begin
                $display("Time=%0t: WARNING - CGRA[%0d] result_rd_en is X!", $time, i);
            end
            if (cgra_result_data[i] === 'x) begin
                $display("Time=%0t: WARNING - CGRA[%0d] result_data is X!", $time, i);
            end
            if (cgra_result_ready[i] === 1'bx) begin
                $display("Time=%0t: WARNING - CGRA[%0d] result_ready is X!", $time, i);
            end
        end
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("cgra_fifo_debug.vcd");
        $dumpvars(0, cgra_fifo_tb);
        $display("Waveform dump enabled: cgra_fifo_debug.vcd");
    end

endmodule
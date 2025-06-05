`timescale 1ns/1ps

module cgra_fifo_tb;
    // Parameters
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 4;
    localparam NUM_INSTANCES = 2;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // FIFO interface
    logic                   wr_en;
    logic [DATA_WIDTH-1:0]  wr_data;
    logic                   full;
    
    // CGRA control interface
    logic [NUM_INSTANCES-1:0] cgra_start;
    logic [NUM_INSTANCES-1:0] cgra_done;
    
    // CGRA data interface
    logic [DATA_WIDTH-1:0]    cgra_data;
    logic                     cgra_valid;
    logic                     cgra_ready;
    
    // DUT instance
    cgra_fifo_wrapper #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_INSTANCES(NUM_INSTANCES)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .wr_en      (wr_en),
        .wr_data    (wr_data),
        .full       (full),
        .cgra_start (cgra_start),
        .cgra_done  (cgra_done),
        .cgra_data  (cgra_data),
        .cgra_valid (cgra_valid),
        .cgra_ready (cgra_ready)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 0;
        wr_en = 0;
        wr_data = 0;
        cgra_start = 0;
        cgra_ready = 0;
        
        // Reset
        #20;
        rst_n = 1;
        #10;
        
        // Test case 1: Write data to FIFO
        for (int i = 0; i < 8; i++) begin
            @(posedge clk);
            wr_en = 1;
            wr_data = i + 1;
            #10;
            wr_en = 0;
        end
        
        // Test case 2: Read data from FIFO
        cgra_ready = 1;
        #100;
        
        // Test case 3: Start CGRA instances
        cgra_start[0] = 1;
        #10;
        cgra_start[0] = 0;
        
        cgra_start[1] = 1;
        #10;
        cgra_start[1] = 0;
        
        // Wait for completion
        wait(cgra_done[0] && cgra_done[1]);
        #100;
        
        // End simulation
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time=%0t rst_n=%b wr_en=%b wr_data=%0d full=%b cgra_valid=%b cgra_data=%0d cgra_done=%b",
                 $time, rst_n, wr_en, wr_data, full, cgra_valid, cgra_data, cgra_done);
    end
    
    // Assertions
    property fifo_full_after_reset;
        @(posedge clk) $fell(rst_n) |-> ##1 !full;
    endproperty
    assert property (fifo_full_after_reset) else $error("FIFO should not be full after reset");
    
    property fifo_write_when_not_full;
        @(posedge clk) wr_en && full |-> ##1 $past(wr_data) == wr_data;
    endproperty
    assert property (fifo_write_when_not_full) else $error("FIFO write when full");
    
    property cgra_valid_when_ready;
        @(posedge clk) cgra_ready && !full |-> ##1 cgra_valid;
    endproperty
    assert property (cgra_valid_when_ready) else $error("CGRA valid not set when ready");
    
endmodule 
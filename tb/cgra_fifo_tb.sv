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
    
    // CGRA control interface
    logic [NUM_INSTANCES-1:0] cgra_start;
    logic [NUM_INSTANCES-1:0] cgra_done;
    
    // CGRA data interface
    logic [NUM_INSTANCES-1:0] cgra_rd_en;
    logic [DATA_WIDTH-1:0]    cgra_rd_data [NUM_INSTANCES];
    logic [NUM_INSTANCES-1:0] cgra_rd_ready;
    
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
        .cgra_rd_en     (cgra_rd_en),
        .cgra_rd_data   (cgra_rd_data),
        .cgra_rd_ready  (cgra_rd_ready)
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
        fifo_wr_en = 0;
        fifo_wr_data = 0;
        cgra_start = 0;
        cgra_rd_ready = 0;
        
        // Reset
        #100;
        rst_n = 1;
        #20;
        
        // Write test data to FIFO
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            @(posedge clk);
            fifo_wr_en = 1;
            fifo_wr_data = i;
            @(posedge clk);
            fifo_wr_en = 0;
        end
        
        // Start both CGRA instances
        @(posedge clk);
        cgra_start = '1;
        @(posedge clk);
        cgra_start = 0;
        
        // Wait for both instances to complete
        wait(cgra_done == '1);
        
        // Read results
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            for (int j = 0; j < NUM_INSTANCES; j++) begin
                @(posedge clk);
                cgra_rd_ready[j] = 1;
                @(posedge clk);
                cgra_rd_ready[j] = 0;
            end
        end
        
        // End simulation
        #100;
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time=%0t rst_n=%b fifo_wr_en=%b fifo_wr_data=%h fifo_full=%b cgra_done=%b",
                 $time, rst_n, fifo_wr_en, fifo_wr_data, fifo_full, cgra_done);
    end
    
endmodule 
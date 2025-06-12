`timescale 1ns/1ps

module tb_cgra_fft;
    // Parameters
    localparam NUM_INSTANCES = 2;
    localparam DATA_WIDTH = 32;
    localparam FIFO_DEPTH = 16;
    localparam FFT_SIZE = 256;
    
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
    wire [NUM_INSTANCES-1:0] cgra_rd_ready;
    wire [DATA_WIDTH-1:0]    cgra_result_data [NUM_INSTANCES];
    
    // Waveform dump file
    initial begin
        $dumpfile("cgra_fft_wave.vcd");
        $dumpvars(0, tb_cgra_fft);
    end
    
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
        .cgra_rd_ready  (cgra_rd_ready),
        .cgra_result_data (cgra_result_data)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Generate test input data (sine wave)
    function [DATA_WIDTH-1:0] generate_sine_wave;
        input integer index;
        real angle;
        begin
            angle = 2.0 * 3.14159 * index / FFT_SIZE;
            generate_sine_wave = $rtoi($sin(angle) * (1 << 16));
        end
    endfunction
    
    // Test stimulus
    initial begin
        integer test_passed = 0;
        integer test_failed = 0;
        integer real_part, imag_part, magnitude, expected;
        
        // Initialize signals
        rst_n = 0;
        fifo_wr_en = 0;
        fifo_wr_data = 0;
        cgra_start = 0;
        
        // Reset
        #100;
        rst_n = 1;
        #20;
        
        // Write test data to FIFO (sine wave)
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            fifo_wr_en = 1;
            fifo_wr_data = generate_sine_wave(i);
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
        for (int i = 0; i < FFT_SIZE; i++) begin
            for (int j = 0; j < NUM_INSTANCES; j++) begin
                // Wait for CGRA to signal data is ready
                wait (cgra_rd_ready[j]);
                @(posedge clk);
                
                // Extract real and imaginary parts
                real_part = $signed(cgra_result_data[j][31:16]);
                imag_part = $signed(cgra_result_data[j][15:0]);
                magnitude = (real_part * real_part + imag_part * imag_part) >> 16;
                
                // Verify FFT results
                if (i == 1 || i == FFT_SIZE-1) begin
                    expected = (FFT_SIZE/2) << 16;
                    // Allow for 1% tolerance in fixed-point arithmetic
                    if (magnitude < (expected * 0.99) || magnitude > (expected * 1.01)) begin
                        $display("Error: Invalid FFT result at index %d, instance %d", i, j);
                        $display("Expected magnitude: %h, Got: %h", expected, magnitude);
                        $display("Real: %h, Imag: %h", real_part, imag_part);
                        test_failed++;
                    end else begin
                        test_passed++;
                    end
                end else begin
                    // Other bins should be close to zero (within 1% of full scale)
                    if (magnitude > (1 << 14)) begin  // 1% of full scale (2^16)
                        $display("Error: Non-zero FFT result at index %d, instance %d", i, j);
                        $display("Magnitude: %h, Real: %h, Imag: %h", magnitude, real_part, imag_part);
                        test_failed++;
                    end else begin
                        test_passed++;
                    end
                end
            end
        end
        
        $display("FFT test completed!");
        $display("Test Results: Passed=%0d, Failed=%0d", test_passed, test_failed);
        
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
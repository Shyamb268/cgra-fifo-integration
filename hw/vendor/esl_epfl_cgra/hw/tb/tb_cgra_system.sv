// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module tb_cgra_system;
    // Parameters
    parameter int unsigned DATA_WIDTH = 32;
    parameter int unsigned FFT_SIZE = 256;
    parameter int unsigned FFT_BITS = 8;  // log2(FFT_SIZE)
    parameter time CLK_PERIOD = 10ns;

    // Signals
    logic clk;
    logic rst_n;
    
    // FIFO interface signals
    logic [DATA_WIDTH-1:0] fifo_data_i;
    logic fifo_valid_i;
    logic fifo_ready_o;
    logic [DATA_WIDTH-1:0] fifo_data_o;
    logic fifo_valid_o;
    logic fifo_ready_i;
    
    // CGRA control signals
    logic cgra_done_o;
    logic cgra_error_o;
    
    // Test control
    int test_passed;
    int test_failed;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #(CLK_PERIOD*2);
        rst_n = 1;
    end

    // DUT instantiation
    cgra_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FFT_SIZE(FFT_SIZE),
        .FFT_BITS(FFT_BITS)
    ) dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .fifo_data_i(fifo_data_i),
        .fifo_valid_i(fifo_valid_i),
        .fifo_ready_o(fifo_ready_o),
        .fifo_data_o(fifo_data_o),
        .fifo_valid_o(fifo_valid_o),
        .fifo_ready_i(fifo_ready_i),
        .cgra_done_o(cgra_done_o),
        .cgra_error_o(cgra_error_o)
    );

    // Test stimulus
    initial begin
        // Initialize signals and counters
        fifo_data_i = '0;
        fifo_valid_i = 1'b0;
        fifo_ready_i = 1'b0;
        test_passed = 0;
        test_failed = 0;

        // Wait for reset
        @(posedge rst_n);
        #(CLK_PERIOD);

        // Test 1: Basic FIFO functionality
        $display("Test 1: Basic FIFO functionality");
        test_fifo_basic();
        
        // Test 2: FFT of a sine wave
        $display("Test 2: FFT of a sine wave");
        test_fft_sine();
        
        // Test 3: FFT of a complex exponential
        $display("Test 3: FFT of a complex exponential");
        test_fft_complex();
        
        // Test 4: Error handling
        $display("Test 4: Error handling");
        test_error_handling();

        // Print test results
        $display("Test Results:");
        $display("  Passed: %0d", test_passed);
        $display("  Failed: %0d", test_failed);
        
        // End simulation
        #(CLK_PERIOD*10);
        $finish;
    end

    // Test tasks
    task test_fifo_basic();
        // Write data until FIFO is full
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            fifo_data_i = i;
            fifo_valid_i = 1'b1;
            wait(fifo_ready_o);
        end
        fifo_valid_i = 1'b0;
        
        // Read data until FIFO is empty
        fifo_ready_i = 1'b1;
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            wait(fifo_valid_o);
            if (fifo_data_o != i) begin
                $error("FIFO data mismatch: expected %0d, got %0d", i, fifo_data_o);
                test_failed++;
            end else begin
                test_passed++;
            end
        end
        fifo_ready_i = 1'b0;
    endtask

    task test_fft_sine();
        // Write input data (sine wave)
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            real angle = 2.0 * 3.14159 * i / FFT_SIZE;
            int sample = int'(sin(angle) * (1 << 8));  // Q8.8 format
            fifo_data_i = sample;
            fifo_valid_i = 1'b1;
            wait(fifo_ready_o);
        end
        fifo_valid_i = 1'b0;

        // Write twiddle factors
        for (int i = 0; i < FFT_SIZE/2; i++) begin
            @(posedge clk);
            real angle = -2.0 * 3.14159 * i / FFT_SIZE;
            int cos_val = int'(cos(angle) * (1 << 8));
            int sin_val = int'(sin(angle) * (1 << 8));
            fifo_data_i = {cos_val, sin_val};
            fifo_valid_i = 1'b1;
            wait(fifo_ready_o);
        end
        fifo_valid_i = 1'b0;

        // Read and verify FFT results
        fifo_ready_i = 1'b1;
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            wait(fifo_valid_o);
            // For a sine wave, we expect peaks at k and N-k
            if (i == 1 || i == FFT_SIZE-1) begin
                if (fifo_data_o < (1 << 7)) begin
                    $error("Missing peak at index %0d", i);
                    test_failed++;
                end else begin
                    test_passed++;
                end
            end
        end
        fifo_ready_i = 1'b0;

        // Wait for completion
        wait(cgra_done_o);
    endtask

    task test_fft_complex();
        // Write input data (complex exponential)
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            real angle = 2.0 * 3.14159 * i / FFT_SIZE;
            int real_part = int'(cos(angle) * (1 << 8));
            int imag_part = int'(sin(angle) * (1 << 8));
            fifo_data_i = {real_part, imag_part};
            fifo_valid_i = 1'b1;
            wait(fifo_ready_o);
        end
        fifo_valid_i = 1'b0;

        // Write twiddle factors
        for (int i = 0; i < FFT_SIZE/2; i++) begin
            @(posedge clk);
            real angle = -2.0 * 3.14159 * i / FFT_SIZE;
            int cos_val = int'(cos(angle) * (1 << 8));
            int sin_val = int'(sin(angle) * (1 << 8));
            fifo_data_i = {cos_val, sin_val};
            fifo_valid_i = 1'b1;
            wait(fifo_ready_o);
        end
        fifo_valid_i = 1'b0;

        // Read and verify FFT results
        fifo_ready_i = 1'b1;
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            wait(fifo_valid_o);
            // For a complex exponential, we expect a single peak
            if (i == 1) begin
                if (fifo_data_o < (1 << 7)) begin
                    $error("Missing peak at index %0d", i);
                    test_failed++;
                end else begin
                    test_passed++;
                end
            end
        end
        fifo_ready_i = 1'b0;

        // Wait for completion
        wait(cgra_done_o);
    endtask

    task test_error_handling();
        // Test FIFO overflow
        fifo_valid_i = 1'b1;
        fifo_ready_i = 1'b0;
        repeat (FFT_SIZE + 1) @(posedge clk);
        if (!cgra_error_o) begin
            $error("FIFO overflow not detected");
            test_failed++;
        end else begin
            test_passed++;
        end
        fifo_valid_i = 1'b0;
        
        // Reset error flag
        @(posedge clk);
        if (cgra_error_o) begin
            $error("Error flag not cleared");
            test_failed++;
        end else begin
            test_passed++;
        end
    endtask

    // Assertions
    property p_fifo_handshake;
        @(posedge clk) disable iff (!rst_n)
        fifo_valid_i && !fifo_ready_o |=> fifo_valid_i;
    endproperty
    assert property (p_fifo_handshake) else $error("FIFO handshake violation");

    property p_fft_valid_ready;
        @(posedge clk) disable iff (!rst_n)
        fifo_valid_o |-> fifo_ready_i;
    endproperty
    assert property (p_fft_valid_ready) else $error("FFT output valid but not ready");

    property p_error_cleared;
        @(posedge clk) disable iff (!rst_n)
        cgra_error_o |=> !cgra_error_o;
    endproperty
    assert property (p_error_cleared) else $error("Error flag not cleared");

endmodule 
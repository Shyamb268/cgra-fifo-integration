// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module tb_cgra_fft;
    // Parameters
    parameter int unsigned DATA_WIDTH = 32;
    parameter int unsigned FFT_SIZE = 256;
    parameter int unsigned FFT_BITS = 8;  // log2(FFT_SIZE)
    parameter time CLK_PERIOD = 10ns;

    // Signals
    logic clk;
    logic rst_n;
    logic [DATA_WIDTH-1:0] fifo_data_i;
    logic fifo_valid_i;
    logic fifo_ready_o;
    logic [DATA_WIDTH-1:0] fifo_data_o;
    logic fifo_valid_o;
    logic fifo_ready_i;
    logic cgra_done_o;

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
        .cgra_done_o(cgra_done_o)
    );

    // Test stimulus
    initial begin
        // Initialize signals
        fifo_data_i = '0;
        fifo_valid_i = 1'b0;
        fifo_ready_i = 1'b0;

        // Wait for reset
        @(posedge rst_n);
        #(CLK_PERIOD);

        // Test 1: FFT of a sine wave
        $display("Test 1: FFT of a sine wave");
        
        // Write input data (sine wave)
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            // Generate sine wave sample
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

        // Read FFT results
        fifo_ready_i = 1'b1;
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            wait(fifo_valid_o);
            $display("FFT[%0d] = %h", i, fifo_data_o);
        end
        fifo_ready_i = 1'b0;

        // Wait for completion
        wait(cgra_done_o);
        $display("FFT computation completed");

        // Test 2: FFT of a complex exponential
        $display("Test 2: FFT of a complex exponential");
        
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

        // Write twiddle factors (same as before)
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

        // Read FFT results
        fifo_ready_i = 1'b1;
        for (int i = 0; i < FFT_SIZE; i++) begin
            @(posedge clk);
            wait(fifo_valid_o);
            $display("FFT[%0d] = %h", i, fifo_data_o);
        end
        fifo_ready_i = 1'b0;

        // Wait for completion
        wait(cgra_done_o);
        $display("FFT computation completed");

        // End simulation
        #(CLK_PERIOD*10);
        $display("Simulation completed");
        $finish;
    end

    // Assertions
    property p_fft_valid;
        @(posedge clk) disable iff (!rst_n)
        fifo_valid_o |-> fifo_ready_i;
    endproperty
    assert property (p_fft_valid) else $error("FFT output valid but not ready");

    property p_fft_done;
        @(posedge clk) disable iff (!rst_n)
        cgra_done_o |-> !fifo_valid_o;
    endproperty
    assert property (p_fft_done) else $error("FFT done but output still valid");

endmodule 
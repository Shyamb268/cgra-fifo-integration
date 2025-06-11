// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module tb_cgra_fft;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter FFT_SIZE = 16;
    parameter FFT_BITS = 4;
    parameter CLK_PERIOD = 10;

    // Signals
    reg clk;
    reg rst_n;
    reg [DATA_WIDTH-1:0] fifo_data_i;
    reg fifo_valid_i;
    wire fifo_ready_o;
    wire [DATA_WIDTH-1:0] fifo_data_o;
    wire fifo_valid_o;
    reg fifo_ready_i;
    wire cgra_done_o;

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
        integer i;
        real angle;
        integer sample;
        integer cos_val;
        integer sin_val;
        integer real_part;
        integer imag_part;
        integer magnitude;
        integer expected;

        // Initialize signals
        fifo_data_i = 0;
        fifo_valid_i = 0;
        fifo_ready_i = 0;

        // Wait for reset
        @(posedge rst_n);
        #(CLK_PERIOD);

        // Test 1: FFT of a sine wave
        $display("Test 1: FFT of a sine wave");
        
        // Write input data (sine wave)
        for (i = 0; i < FFT_SIZE; i = i + 1) begin
            @(posedge clk);
            // Generate sine wave sample
            angle = 2.0 * 3.14159 * i / FFT_SIZE;
            sample = $rtoi(sin(angle) * (1 << 8));  // Q8.8 format
            fifo_data_i = sample;
            fifo_valid_i = 1;
            wait(fifo_ready_o);
        end
        fifo_valid_i = 0;

        // Write twiddle factors
        for (i = 0; i < FFT_SIZE/2; i = i + 1) begin
            @(posedge clk);
            angle = -2.0 * 3.14159 * i / FFT_SIZE;
            cos_val = $rtoi(cos(angle) * (1 << 8));
            sin_val = $rtoi(sin(angle) * (1 << 8));
            fifo_data_i = {cos_val, sin_val};
            fifo_valid_i = 1;
            wait(fifo_ready_o);
        end
        fifo_valid_i = 0;

        // Read FFT results
        fifo_ready_i = 1;
        for (i = 0; i < FFT_SIZE; i = i + 1) begin
            @(posedge clk);
            wait(fifo_valid_o);
            // For a sine wave, we expect peaks at k and N-k
            if (i == 1 || i == FFT_SIZE-1) begin
                // Expected peak magnitude is FFT_SIZE/2 * 2^8 (Q8.8 format)
                // For complex FFT, we need to check both real and imaginary parts
                real_part = $signed(fifo_data_o[31:16]);
                imag_part = $signed(fifo_data_o[15:0]);
                magnitude = (real_part * real_part + imag_part * imag_part) >> 8;  // Scale back to Q8.8
                expected = (FFT_SIZE/2) << 8;
                if (magnitude < (expected * 0.9)) begin  // Allow 10% tolerance
                    $display("Invalid FFT result at index %0d, instance %0d", i, 0);
                    $display("Expected magnitude: %h, Got: %h", expected, magnitude);
                    $display("Real: %h, Imag: %h", real_part, imag_part);
                end else begin
                    $display("Peak found at index %0d: magnitude %h", i, magnitude);
                end
            end else begin
                // Other bins should be close to zero
                real_part = $signed(fifo_data_o[31:16]);
                imag_part = $signed(fifo_data_o[15:0]);
                magnitude = (real_part * real_part + imag_part * imag_part) >> 8;
                if (magnitude > (1 << 7)) begin
                    $display("Non-zero value at index %0d: magnitude %h", i, magnitude);
                    $display("Real: %h, Imag: %h", real_part, imag_part);
                end
            end
        end
        fifo_ready_i = 0;

        // Wait for completion
        wait(cgra_done_o);
        $display("FFT computation completed");

        // End simulation
        #(CLK_PERIOD*10);
        $display("Simulation completed");
        $finish;
    end

    // Assertions
    always @(posedge clk) begin
        if (rst_n) begin
            if (fifo_valid_o && !fifo_ready_i)
                $display("Error: FFT output valid but not ready");
            if (cgra_done_o && fifo_valid_o)
                $display("Error: FFT done but output still valid");
        end
    end

endmodule 
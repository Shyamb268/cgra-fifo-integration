// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module tb_cgra_fifo;
    // Parameters
    parameter int unsigned DATA_WIDTH = 32;
    parameter int unsigned DEPTH = 16;
    parameter time CLK_PERIOD = 10ns;

    // Signals
    logic clk;
    logic rst_n;
    logic [DATA_WIDTH-1:0] data_i;
    logic valid_i;
    logic ready_o;
    logic [DATA_WIDTH-1:0] data_o;
    logic valid_o;
    logic ready_i;

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
    fifo_v3 #(
        .FALL_THROUGH(1'b1),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .flush_i(1'b0),
        .testmode_i(1'b0),
        .full_o(),
        .empty_o(),
        .usage_o(),
        .data_i(data_i),
        .push_i(valid_i),
        .data_o(data_o),
        .pop_i(ready_i)
    );

    // Test stimulus
    initial begin
        // Initialize signals
        data_i = '0;
        valid_i = 1'b0;
        ready_i = 1'b0;

        // Wait for reset
        @(posedge rst_n);
        #(CLK_PERIOD);

        // Test 1: Write data until full
        $display("Test 1: Write data until full");
        for (int i = 0; i < DEPTH + 1; i++) begin
            @(posedge clk);
            data_i = i;
            valid_i = 1'b1;
            ready_i = 1'b0;
        end
        valid_i = 1'b0;

        // Test 2: Read data until empty
        $display("Test 2: Read data until empty");
        for (int i = 0; i < DEPTH + 1; i++) begin
            @(posedge clk);
            valid_i = 1'b0;
            ready_i = 1'b1;
        end
        ready_i = 1'b0;

        // Test 3: Simultaneous read and write
        $display("Test 3: Simultaneous read and write");
        for (int i = 0; i < DEPTH; i++) begin
            @(posedge clk);
            data_i = i + 100;
            valid_i = 1'b1;
            ready_i = 1'b1;
        end
        valid_i = 1'b0;
        ready_i = 1'b0;

        // Test 4: Random read/write
        $display("Test 4: Random read/write");
        repeat (100) begin
            @(posedge clk);
            data_i = $urandom();
            valid_i = $urandom();
            ready_i = $urandom();
        end

        // End simulation
        #(CLK_PERIOD*10);
        $display("Simulation completed");
        $finish;
    end

    // Monitor
    always @(posedge clk) begin
        if (valid_i && ready_o) begin
            $display("Write: data=%h", data_i);
        end
        if (valid_o && ready_i) begin
            $display("Read: data=%h", data_o);
        end
    end

    // Assertions
    property p_fifo_full;
        @(posedge clk) disable iff (!rst_n)
        dut.usage_o == DEPTH |-> !ready_o;
    endproperty
    assert property (p_fifo_full) else $error("FIFO full but ready_o not deasserted");

    property p_fifo_empty;
        @(posedge clk) disable iff (!rst_n)
        dut.usage_o == 0 |-> !valid_o;
    endproperty
    assert property (p_fifo_empty) else $error("FIFO empty but valid_o not deasserted");

    property p_data_consistency;
        @(posedge clk) disable iff (!rst_n)
        valid_o && ready_i |-> data_o == $past(data_i, DEPTH);
    endproperty
    assert property (p_data_consistency) else $error("Data inconsistency detected");

endmodule 
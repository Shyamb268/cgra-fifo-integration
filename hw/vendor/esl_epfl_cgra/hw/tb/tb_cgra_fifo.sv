// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module tb_cgra_fifo;
    // Parameters
    parameter int unsigned DATA_WIDTH = 32;
    parameter int unsigned DEPTH = 16;
    parameter time CLK_PERIOD = 10ns;

    // Debug message at start
    initial begin
        $display("\n=== Starting Enhanced CGRA FIFO Testbench ===");
        $display("Parameters: DATA_WIDTH=%0d, DEPTH=%0d, CLK_PERIOD=%0t", DATA_WIDTH, DEPTH, CLK_PERIOD);
    end

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

    // Enhanced Monitor
    always @(posedge clk) begin
        if (valid_i && ready_o) begin
            $display("Time=%0t: Write: data=%h, usage=%0d/%0d", $time, data_i, dut.usage_o, DEPTH);
        end
        if (valid_o && ready_i) begin
            $display("Time=%0t: Read: data=%h, usage=%0d/%0d", $time, data_o, dut.usage_o, DEPTH);
        end
        if (dut.full_o) begin
            $display("Time=%0t: FIFO is FULL, usage=%0d/%0d", $time, dut.usage_o, DEPTH);
        end
        if (dut.empty_o) begin
            $display("Time=%0t: FIFO is EMPTY, usage=%0d/%0d", $time, dut.usage_o, DEPTH);
        end
    end

    // Test stimulus
    initial begin
        // Initialize signals
        $display("\n=== Initializing CGRA FIFO Testbench ===");
        data_i = '0;
        valid_i = 1'b0;
        ready_i = 1'b0;

        // Wait for reset
        @(posedge rst_n);
        #(CLK_PERIOD);
        $display("\nTime=%0t: Reset released", $time);

        // Test: Read after Write
        $display("\n=== Test: Read after Write ===");
        
        // Phase 1: Write 4 data items
        $display("\nPhase 1: Writing 4 data items");
        for (int i = 0; i < 4; i++) begin
            @(posedge clk);
            data_i = 32'h1000 + i;  // Write pattern: 0x1000, 0x1001, 0x1002, 0x1003
            valid_i = 1'b1;
            ready_i = 1'b0;
            $display("Time=%0t: Attempting to write data=0x%h", $time, data_i);
        end
        valid_i = 1'b0;
        #(CLK_PERIOD*2);
        $display("Time=%0t: Write phase completed, current usage=%0d/%0d", $time, dut.usage_o, DEPTH);

        // Phase 2: Read all written data
        $display("\nPhase 2: Reading all written data");
        for (int i = 0; i < 4; i++) begin
            @(posedge clk);
            valid_i = 1'b0;
            ready_i = 1'b1;
            $display("Time=%0t: Attempting to read data, expecting 0x%h", $time, 32'h1000 + i);
        end
        ready_i = 1'b0;
        #(CLK_PERIOD*2);
        $display("Time=%0t: Read phase completed, current usage=%0d/%0d", $time, dut.usage_o, DEPTH);

        // Phase 3: Verify FIFO is empty
        $display("\nPhase 3: Verifying FIFO is empty");
            @(posedge clk);
        if (dut.empty_o) begin
            $display("Time=%0t: FIFO is correctly empty", $time);
        end else begin
            $display("Time=%0t: ERROR - FIFO should be empty but is not", $time);
        end

        // End simulation
        #(CLK_PERIOD*10);
        $display("\n=== Read after Write Test completed! ===");
        $finish;
    end

    // Enhanced Assertions
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

    property p_usage_bounds;
        @(posedge clk) disable iff (!rst_n)
        dut.usage_o <= DEPTH;
    endproperty
    assert property (p_usage_bounds) else $error("FIFO usage exceeds depth");

endmodule 
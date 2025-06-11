`timescale 1ns/1ps

module regression_tests;
    // Import test utilities
    `include "tb_util.svh"
    
    // Test parameters
    localparam NUM_TESTS = 5;
    localparam NUM_INSTANCES = 2;
    localparam DATA_WIDTH = 32;
    localparam FIFO_DEPTH = 16;
    
    // Test results
    reg [NUM_TESTS-1:0] test_results;
    
    // Test 1: Basic FIFO Operations
    task test_fifo_basic;
        reg result;
        reg [DATA_WIDTH-1:0] test_data;
        integer i;
        
        result = 1;
        
        // Write to FIFO
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            test_data = i;
            if (!write_fifo(test_data)) begin
                result = 0;
                i = FIFO_DEPTH; // Exit loop
            end
        end
        
        // Read from FIFO
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            if (!read_fifo(test_data) || test_data != i) begin
                result = 0;
                i = FIFO_DEPTH; // Exit loop
            end
        end
        
        test_results[0] = result;
    endtask
    
    // Test 2: Multiple CGRA Instance Operation
    task test_multi_cgra;
        reg result;
        reg [DATA_WIDTH-1:0] test_data;
        integer i;
        
        result = 1;
        
        // Start all instances
        for (i = 0; i < NUM_INSTANCES; i = i + 1) begin
            if (!start_cgra_instance(i)) begin
                result = 0;
                i = NUM_INSTANCES; // Exit loop
            end
        end
        
        // Wait for completion
        for (i = 0; i < NUM_INSTANCES; i = i + 1) begin
            if (!wait_cgra_done(i)) begin
                result = 0;
                i = NUM_INSTANCES; // Exit loop
            end
        end
        
        test_results[1] = result;
    endtask
    
    // Test 3: FIFO Full/Empty Conditions
    task test_fifo_conditions;
        reg result;
        reg [DATA_WIDTH-1:0] test_data;
        integer i;
        
        result = 1;
        
        // Fill FIFO
        for (i = 0; i < FIFO_DEPTH + 1; i = i + 1) begin
            test_data = i;
            if (i < FIFO_DEPTH) begin
                if (!write_fifo(test_data)) begin
                    result = 0;
                    i = FIFO_DEPTH + 1; // Exit loop
                end
            end else begin
                if (write_fifo(test_data)) begin
                    result = 0;
                    i = FIFO_DEPTH + 1; // Exit loop
                end
            end
        end
        
        // Empty FIFO
        for (i = 0; i < FIFO_DEPTH + 1; i = i + 1) begin
            if (i < FIFO_DEPTH) begin
                if (!read_fifo(test_data)) begin
                    result = 0;
                    i = FIFO_DEPTH + 1; // Exit loop
                end
            end else begin
                if (read_fifo(test_data)) begin
                    result = 0;
                    i = FIFO_DEPTH + 1; // Exit loop
                end
            end
        end
        
        test_results[2] = result;
    endtask
    
    // Test 4: CGRA Data Path
    task test_cgra_datapath;
        reg result;
        reg [DATA_WIDTH-1:0] test_data;
        integer i;
        
        result = 1;
        
        // Write test data
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            test_data = i;
            if (!write_fifo(test_data)) begin
                result = 0;
                i = FIFO_DEPTH; // Exit loop
            end
        end
        
        // Start CGRA and verify results
        for (i = 0; i < NUM_INSTANCES; i = i + 1) begin
            if (!start_cgra_instance(i) || !verify_cgra_output(i)) begin
                result = 0;
                i = NUM_INSTANCES; // Exit loop
            end
        end
        
        test_results[3] = result;
    endtask
    
    // Test 5: Concurrent Operations
    task test_concurrent_ops;
        reg result;
        integer i;
        
        result = 1;
        
        // Start multiple instances
        fork
            start_cgra_instance(0);
            start_cgra_instance(1);
        join
        
        // Verify all instances complete
        for (i = 0; i < NUM_INSTANCES; i = i + 1) begin
            if (!wait_cgra_done(i)) begin
                result = 0;
                i = NUM_INSTANCES; // Exit loop
            end
        end
        
        test_results[4] = result;
    endtask
    
    // Main test sequence
    initial begin
        // Initialize
        initialize_testbench();
        
        // Run tests
        test_fifo_basic();
        test_multi_cgra();
        test_fifo_conditions();
        test_cgra_datapath();
        test_concurrent_ops();
        
        // Report results
        $display("Test Results:");
        for (integer i = 0; i < NUM_TESTS; i = i + 1) begin
            $display("Test %0d: %s", i, test_results[i] ? "PASS" : "FAIL");
        end
        
        // End simulation
        if (test_results == '1) begin
            $display("All tests passed!");
        end else begin
            $display("Some tests failed!");
        end
        $finish;
    end
    
endmodule 
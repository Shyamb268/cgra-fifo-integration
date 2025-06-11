// Test utility functions for FIFO testing

// Write data to FIFO
function write_fifo;
    input [31:0] data;
    begin
        if (fifo_full)
            write_fifo = 0;
        else begin
            fifo_wr_en = 1;
            fifo_wr_data = data;
            @(posedge clk);
            fifo_wr_en = 0;
            write_fifo = 1;
        end
    end
endfunction

// Read data from FIFO
function read_fifo;
    input [31:0] data;
    begin
        if (fifo_empty)
            read_fifo = 0;
        else begin
            fifo_rd_en = 1;
            @(posedge clk);
            data = fifo_rd_data;
            fifo_rd_en = 0;
            read_fifo = 1;
        end
    end
endfunction

// Initialize testbench
task initialize_testbench;
    begin
        // Reset signals
        rst_n = 0;
        fifo_wr_en = 0;
        fifo_rd_en = 0;
        fifo_wr_data = 0;
        
        // Apply reset
        #100;
        rst_n = 1;
        #20;
    end
endtask 
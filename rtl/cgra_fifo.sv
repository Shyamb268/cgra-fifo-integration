`include "fifo_pkg.sv"

module cgra_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16,
    parameter NUM_INSTANCES = 4
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // FIFO interface
    input  logic                     fifo_wr_en,
    input  logic                     fifo_rd_en,
    input  logic [DATA_WIDTH-1:0]    fifo_wr_data,
    output logic [DATA_WIDTH-1:0]    fifo_rd_data,
    output logic                     fifo_full,
    output logic                     fifo_empty,
    output logic [$clog2(FIFO_DEPTH):0] fifo_count,
    
    // CGRA interface
    input  logic [NUM_INSTANCES-1:0] cgra_start,
    output logic [NUM_INSTANCES-1:0] cgra_done,
    input  logic [NUM_INSTANCES-1:0] cgra_rd_en,
    output logic [NUM_INSTANCES-1:0] cgra_rd_ready,
    output logic [DATA_WIDTH-1:0]    cgra_rd_data [NUM_INSTANCES-1:0]
);

    // FIFO instance
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),
        .din(fifo_wr_data),
        .dout(fifo_rd_data),
        .full(fifo_full),
        .empty(fifo_empty),
        .count(fifo_count)
    );
    
    // CGRA instances
    genvar i;
    generate
        for (i = 0; i < NUM_INSTANCES; i = i + 1) begin : cgra_instances
            // CGRA instance - Fixed port connections
            cgra #(
                .DATA_WIDTH(DATA_WIDTH)
            ) cgra_inst (
                .clk(clk),
                .rst_n(rst_n),
                .start(cgra_start[i]),
                .done(cgra_done[i]),
                .data_valid(cgra_rd_en[i]),      // Fixed: rd_en -> data_valid
                .data_ready(cgra_rd_ready[i]),    // Fixed: rd_ready -> data_ready
                .data_in(fifo_rd_data),           // Fixed: rd_data -> data_in, using FIFO output
                .result_data(cgra_rd_data[i])     // Fixed: rd_data -> result_data
            );
        end
    endgenerate

endmodule 
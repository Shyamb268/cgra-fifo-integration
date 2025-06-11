`timescale 1ns/1ps

module cgra_fifo_wrapper #(
    parameter NUM_INSTANCES = 2,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)(
    input  logic                     clk,
    input  logic                     rst_n,
    
    // CGRA control interface
    input  logic [NUM_INSTANCES-1:0] cgra_start,
    output logic [NUM_INSTANCES-1:0] cgra_done,
    
    // FIFO interface
    input  logic                     fifo_wr_en,
    input  logic [DATA_WIDTH-1:0]    fifo_wr_data,
    output logic                     fifo_full,
    
    // CGRA data interface
    output logic [NUM_INSTANCES-1:0] cgra_rd_en,
    input  logic [NUM_INSTANCES-1:0] cgra_rd_ready,
    output logic [DATA_WIDTH-1:0]    cgra_result_data [NUM_INSTANCES]
);

    // FIFO interface signals
    logic                     fifo_rd_en;
    logic [DATA_WIDTH-1:0]    fifo_dout;
    logic                     fifo_empty;
    
    // Instantiate FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .wr_en  (fifo_wr_en),
        .rd_en  (fifo_rd_en),
        .din    (fifo_wr_data),
        .dout   (fifo_dout),
        .full   (fifo_full),
        .empty  (fifo_empty)
    );
    
    // OR all cgra_rd_en signals for FIFO read enable
    assign fifo_rd_en = |cgra_rd_en;

    genvar i;
    generate
        for (i = 0; i < NUM_INSTANCES; i++) begin : gen_cgra
            cgra #(
                .DATA_WIDTH(DATA_WIDTH)
            ) cgra_inst (
                .clk      (clk),
                .rst_n    (rst_n),
                .start    (cgra_start[i]),
                .done     (cgra_done[i]),
                .rd_en    (cgra_rd_en[i]),
                .rd_ready (cgra_rd_ready[i]),
                .rd_data  (fifo_dout),
                .result_data (cgra_result_data[i])
            );
        end
    endgenerate

endmodule 
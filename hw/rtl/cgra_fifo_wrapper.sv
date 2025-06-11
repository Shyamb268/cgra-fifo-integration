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
    
    // FIFO interfaces
    input  logic                     fifo_wr_en,
    input  logic [DATA_WIDTH-1:0]    fifo_wr_data,
    output logic                     fifo_full,
    
    // CGRA data interfaces
    output logic [NUM_INSTANCES-1:0] cgra_rd_en,
    output logic [DATA_WIDTH-1:0]    cgra_rd_data [NUM_INSTANCES],
    input  logic [NUM_INSTANCES-1:0] cgra_rd_ready
);
    
    // FIFO instance
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) input_fifo (
        .clk    (clk),
        .rst_n  (rst_n),
        .wr_en  (fifo_wr_en),
        .rd_en  (|cgra_rd_en),
        .din    (fifo_wr_data),
        .dout   (cgra_rd_data[0]), // Shared data bus
        .full   (fifo_full),
        .empty  ()
    );

    // CGRA instance array
    genvar i;
    generate
        for (i = 0; i < NUM_INSTANCES; i++) begin : cgra_instances
            // CGRA instance
            cgra_top cgra_inst (
                .clk        (clk),
                .rst_n      (rst_n),
                .start      (cgra_start[i]),
                .done       (cgra_done[i]),
                .data_in    (cgra_rd_data[i]),
                .data_valid (cgra_rd_en[i]),
                .ready      (cgra_rd_ready[i])
            );
        end
    endgenerate

endmodule 
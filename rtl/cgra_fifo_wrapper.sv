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
    output logic [$clog2(FIFO_DEPTH):0] fifo_count,
    
    // CGRA data interface
    input  logic [NUM_INSTANCES-1:0] cgra_result_rd_en,  // Read enable for results
    output logic [NUM_INSTANCES-1:0] cgra_result_ready,  // Result ready signal
    output logic [DATA_WIDTH-1:0]    cgra_result_data [NUM_INSTANCES]
);

    // FIFO interface signals
    logic                     fifo_rd_en;
    logic [DATA_WIDTH-1:0]    fifo_dout;
    logic                     fifo_empty;
    
    // CGRA interface signals
    logic [NUM_INSTANCES-1:0] cgra_data_valid;
    logic [NUM_INSTANCES-1:0] cgra_data_ready;
    logic [DATA_WIDTH-1:0]    cgra_data_in [NUM_INSTANCES];
    logic [DATA_WIDTH-1:0]    cgra_result [NUM_INSTANCES];
    
    // Arbitration logic for FIFO reads
    logic [NUM_INSTANCES-1:0] fifo_rd_request;
    logic [NUM_INSTANCES-1:0] fifo_rd_grant;
    
    // Single FIFO instance
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
        .empty  (fifo_empty),
        .count  (fifo_count)
    );
    
    // FIFO read arbitration - priority-based (instance 0 has highest priority)
    always_comb begin
        fifo_rd_en = 0;
        fifo_rd_grant = 0;
        
        // Simple priority arbitration - first instance gets priority
        if (fifo_rd_request[0] && !fifo_empty) begin
            fifo_rd_en = 1;
            fifo_rd_grant[0] = 1;
        end else if (fifo_rd_request[1] && !fifo_empty) begin
            fifo_rd_en = 1;
            fifo_rd_grant[1] = 1;
        end
    end
    
    // FIFO read request logic
    assign fifo_rd_request = cgra_data_ready & ~fifo_empty;

    // CGRA instances
    genvar i;
    generate
        for (i = 0; i < NUM_INSTANCES; i = i + 1) begin : gen_cgra
            // Data flow logic
            assign cgra_data_valid[i] = fifo_rd_grant[i];  // Data is valid when this instance gets FIFO access
            assign cgra_data_in[i] = fifo_dout;            // Data from FIFO to CGRA
            
            cgra #(
                .DATA_WIDTH(DATA_WIDTH)
            ) cgra_inst (
                .clk         (clk),
                .rst_n       (rst_n),
                .start       (cgra_start[i]),
                .done        (cgra_done[i]),
                .data_valid  (cgra_data_valid[i]),
                .data_ready  (cgra_data_ready[i]),
                .data_in     (cgra_data_in[i]),
                .result_data (cgra_result[i])
            );
            
            // Result interface
            assign cgra_result_data[i] = cgra_result[i];
            assign cgra_result_ready[i] = cgra_done[i];  // Result ready when CGRA is done
        end
    endgenerate

endmodule
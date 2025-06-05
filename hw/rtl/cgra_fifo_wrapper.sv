module cgra_fifo_wrapper #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 4,
    parameter int NUM_INSTANCES = 2
)(
    input  logic                   clk,
    input  logic                   rst_n,
    
    // FIFO Interface
    input  logic                   wr_en,
    input  logic [DATA_WIDTH-1:0]  wr_data,
    output logic                   full,
    
    // CGRA Control Interface
    input  logic [NUM_INSTANCES-1:0] cgra_start,
    output logic [NUM_INSTANCES-1:0] cgra_done,
    
    // CGRA Data Interface
    output logic [DATA_WIDTH-1:0]    cgra_data,
    output logic                     cgra_valid,
    input  logic                     cgra_ready
);

    // Internal signals
    logic                   rd_en;
    logic [DATA_WIDTH-1:0]  rd_data;
    logic                   empty;
    
    // FIFO instance
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .wr_en      (wr_en),
        .wr_data    (wr_data),
        .full       (full),
        .rd_en      (rd_en),
        .rd_data    (rd_data),
        .empty      (empty)
    );
    
    // CGRA control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cgra_valid <= 1'b0;
            cgra_data <= '0;
        end else begin
            if (cgra_ready && !empty) begin
                cgra_valid <= 1'b1;
                cgra_data <= rd_data;
                rd_en <= 1'b1;
            end else begin
                cgra_valid <= 1'b0;
                rd_en <= 1'b0;
            end
        end
    end
    
    // Instance control logic
    genvar i;
    generate
        for (i = 0; i < NUM_INSTANCES; i++) begin : gen_inst_ctrl
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    cgra_done[i] <= 1'b0;
                end else begin
                    if (cgra_start[i]) begin
                        cgra_done[i] <= 1'b0;
                    end else if (cgra_ready && empty) begin
                        cgra_done[i] <= 1'b1;
                    end
                end
            end
        end
    endgenerate

endmodule 
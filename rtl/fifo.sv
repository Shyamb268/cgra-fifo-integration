`timescale 1ns/1ps

module fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   wr_en,
    input  logic                   rd_en,
    input  logic [DATA_WIDTH-1:0]  din,
    output logic [DATA_WIDTH-1:0]  dout,
    output logic                   full,
    output logic                   empty,
    output logic [$clog2(DEPTH):0] count
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    logic [$clog2(DEPTH):0]   cnt;
    logic wr_valid, rd_valid;

    // Valid signals for write and read operations
    assign wr_valid = wr_en && !full;
    assign rd_valid = rd_en && !empty;

    // Full and empty conditions
    assign full  = (cnt == DEPTH);
    assign empty = (cnt == 0);
    assign count = cnt;
    assign dout  = mem[rd_ptr];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt    <= 0;
        end else begin
            // Write operation
            if (wr_valid) begin
                mem[wr_ptr] <= din;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
            
            // Read operation
            if (rd_valid) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            end
            
            // Count update logic
            case ({wr_valid, rd_valid})
                2'b10: cnt <= cnt + 1; // Write only
                2'b01: cnt <= cnt - 1; // Read only
                2'b11: cnt <= cnt;     // Simultaneous write and read
                default: cnt <= cnt;   // No operation
            endcase
        end
    end

endmodule

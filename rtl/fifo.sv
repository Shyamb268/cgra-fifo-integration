// Simple parameterized synchronous FIFO
module fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,
    output logic                  full,
    output logic                  empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH:0]   wr_ptr, rd_ptr, count;

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

    // Status flags
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

endmodule


// fifo_if.sv
interface fifo_if #(parameter WIDTH = 32);
    logic             wr_en, rd_en;
    logic [WIDTH-1:0] din, dout;
    logic             full, empty;
endinterface
// fifo.sv
`include "fifo_pkg.sv"

module fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = fifo_pkg::FIFO_DEPTH,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                clk,
    input  logic                rst_n,
    input  logic                wr_en,
    input  logic                rd_en,
    input  logic [WIDTH-1:0]    din,
    output logic [WIDTH-1:0]    dout,
    output logic                full,
    output logic                empty
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH:0] wr_ptr, rd_ptr;

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (wr_en && !full)
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr + (wr_en && !full);
    end

    // Read logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= 0;
        else if (rd_en && !empty)
            rd_ptr <= rd_ptr + 1;
    end

    assign dout  = mem[rd_ptr[ADDR_WIDTH-1:0]];
    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr == rd_ptr);

endmodule

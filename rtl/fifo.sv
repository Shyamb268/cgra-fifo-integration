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
    output logic                  empty,
    output logic [ADDR_WIDTH:0]   count
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [ADDR_WIDTH:0]   count_q;
    logic                 will_be_full;
    logic                 wr_valid, rd_valid;

    // Write and read valid signals
    assign wr_valid = wr_en && !full;
    assign rd_valid = rd_en && !empty;

    // Write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_valid) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_valid) begin
            dout   <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_q <= 0;
        end else begin
            if (wr_valid && !rd_valid) begin
                count_q <= count_q + 1;
            end else if (!wr_valid && rd_valid) begin
                count_q <= count_q - 1;
            end
            // No change for simultaneous read/write or no operation
        end
    end

    // Status flags
    assign will_be_full = (count_q == DEPTH-1) && wr_valid;
    assign full  = (count_q == DEPTH);
    assign empty = (count_q == 0);
    assign count = count_q;

    // Debug statements
    always @(posedge clk) begin
        if (wr_valid) begin
            $display("Time=%0t: Write data=%h, count=%0d", $time, din, count);
        end
        if (rd_valid) begin
            $display("Time=%0t: Read data=%h, count=%0d", $time, dout, count);
        end
        if (full) begin
            $display("Time=%0t: FIFO is full, count=%0d", $time, count);
        end
        if (empty) begin
            $display("Time=%0t: FIFO is empty, count=%0d", $time, count);
        end
    end

endmodule

// fifo_if.sv
interface fifo_if #(parameter WIDTH = 32);
    logic             wr_en, rd_en;
    logic [WIDTH-1:0] din, dout;
    logic             full, empty;
endinterface

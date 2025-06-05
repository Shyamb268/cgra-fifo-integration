interface fifo_if #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 4
);
    logic                   clk;
    logic                   rst_n;
    logic                   wr_en;
    logic                   rd_en;
    logic [DATA_WIDTH-1:0]  wr_data;
    logic [DATA_WIDTH-1:0]  rd_data;
    logic                   full;
    logic                   empty;
    logic                   almost_full;
    logic                   almost_empty;

    // Write port
    modport write (
        input   clk, rst_n, wr_en, wr_data,
        output  full, almost_full
    );

    // Read port
    modport read (
        input   clk, rst_n, rd_en,
        output  rd_data, empty, almost_empty
    );

    // Monitor port
    modport monitor (
        input   clk, rst_n, wr_en, rd_en, wr_data, rd_data,
        input   full, empty, almost_full, almost_empty
    );
endinterface 
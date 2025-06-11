package fifo_pkg;
    // FIFO configuration
    parameter int FIFO_DEPTH = 16;
    parameter int DATA_WIDTH = 32;
    
    // FIFO status
    typedef struct packed {
        logic full;
        logic empty;
        logic [7:0] level;
    } fifo_status_t;
    
    // FIFO interface
    typedef struct packed {
        logic wr_en;
        logic rd_en;
        logic [DATA_WIDTH-1:0] data;
    } fifo_ctrl_t;
    
endpackage 
module cgra #(
    parameter DATA_WIDTH = 32
)(
    input  logic                clk,
    input  logic                rst_n,
    input  logic                start,
    output logic                done,
    input  logic                rd_en,
    output logic                rd_ready,
    input  logic [DATA_WIDTH-1:0] rd_data,
    output logic [DATA_WIDTH-1:0] result_data
);

    // State machine states
    typedef enum logic [1:0] {
        IDLE,
        PROCESSING,
        DONE
    } state_t;
    
    state_t state, next_state;
    
    // Internal registers
    logic [DATA_WIDTH-1:0] result;
    logic [7:0] count;
    logic [DATA_WIDTH-1:0] last_input;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            result <= '0;
            count <= '0;
            last_input <= '0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        result <= '0;
                        count <= '0;
                        last_input <= '0;
                    end
                end
                
                PROCESSING: begin
                    if (count < 8'hFF) begin
                        result <= result + rd_data;
                        last_input <= rd_data;
                        count <= count + 1;
                    end
                end
                
                DONE: begin
                    if (rd_en) begin
                        result <= '0;
                        last_input <= '0;
                    end
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start)
                    next_state = PROCESSING;
            end
            
            PROCESSING: begin
                if (count == 8'hFF)
                    next_state = DONE;
            end
            
            DONE: begin
                if (rd_en)
                    next_state = IDLE;
            end
        endcase
    end
    
    // Output logic
    assign done = (state == DONE);
    assign rd_ready = (state == DONE);
    assign result_data = result;

endmodule 
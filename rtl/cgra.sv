`timescale 1ns/1ps

module cgra #(
    parameter DATA_WIDTH = 32
)(
    input  logic                clk,
    input  logic                rst_n,
    input  logic                start,
    output logic                done,
    input  logic                data_valid,    // Changed from rd_en to data_valid
    output logic                data_ready,    // Changed from rd_ready to data_ready
    input  logic [DATA_WIDTH-1:0] data_in,     // Changed from rd_data to data_in
    output logic [DATA_WIDTH-1:0] result_data
);

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        WAIT_DATA,
        PROCESSING,
        OUTPUT_RESULT,
        DONE
    } state_t;
    
    state_t state, next_state;
    
    // Internal registers
    logic [DATA_WIDTH-1:0] result;
    logic [7:0] data_count;
    logic [DATA_WIDTH-1:0] processed_data [0:7];  // Store last 8 inputs
    logic processing_complete;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            result <= '0;
            data_count <= '0;
            for (int i = 0; i < 8; i = i + 1) begin
                processed_data[i] <= '0;
            end
            processing_complete <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        result <= '0;
                        data_count <= '0;
                        for (int i = 0; i < 8; i = i + 1) begin
                            processed_data[i] <= '0;
                        end
                        processing_complete <= 0;
                    end
                end
                
                WAIT_DATA: begin
                    // Wait for data to be available
                end
                
                PROCESSING: begin
                    if (data_valid && data_ready && data_count < 8) begin
                        // Store input data
                        processed_data[data_count] <= data_in;
                        data_count <= data_count + 1;
                        
                        // Simple processing: accumulate data
                        result <= result + data_in;
                        
                        if (data_count == 7) begin  // Processed 8 items
                            processing_complete <= 1;
                        end
                    end
                end
                
                OUTPUT_RESULT: begin
                    // Result is ready for reading
                end
                
                DONE: begin
                    // Keep result stable until next start
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
                    next_state = WAIT_DATA;
            end
            
            WAIT_DATA: begin
                next_state = PROCESSING;
            end
            
            PROCESSING: begin
                if (processing_complete)
                    next_state = OUTPUT_RESULT;
            end
            
            OUTPUT_RESULT: begin
                next_state = DONE;
            end
            
            DONE: begin
                if (start)
                    next_state = WAIT_DATA;
            end
        endcase
    end
    
    // Output logic
    assign done = (state == DONE);
    assign data_ready = (state == PROCESSING) && !processing_complete;  // Ready to accept data during processing
    assign result_data = (state == OUTPUT_RESULT || state == DONE) ? result : '0;

endmodule 
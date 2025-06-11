// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

module cgra_controller #(
    parameter N_COL = 4,
    parameter N_ROW = 4
) (
    input  wire clk_i,
    input  wire rst_ni,
    input  wire [N_COL-1:0] acc_req_i,
    input  wire imem_gnt_ctrl_i,
    input  wire imem_rvalid_ctrl_i,
    input  wire [31:0] kmem_rdata_i,
    input  wire [N_COL-1:0] ker_id_req_i,
    input  wire [N_COL-1:0] data_stall_i,
    input  wire [N_COL-1:0] rcs_br_req_i,
    input  wire [31:0] rcs_br_add_i_0,
    input  wire [31:0] rcs_br_add_i_1,
    input  wire [31:0] rcs_br_add_i_2,
    input  wire [31:0] rcs_br_add_i_3,
    input  wire [N_COL-1:0] rcs_stall_i,
    input  wire [N_COL-1:0] rcs_exec_end_i,
    output reg [N_COL-1:0] rcs_conf_we_o,
    output reg [N_COL-1:0] rcs_conf_re_o,
    output reg [N_COL-1:0] rcs_pc_e_o,
    output reg [31:0] rcs_pc_o_0,
    output reg [31:0] rcs_pc_o_1,
    output reg [31:0] rcs_pc_o_2,
    output reg [31:0] rcs_pc_o_3,
    output reg [N_COL-1:0] col_e_o,
    output reg [N_COL-1:0] rcs_rst_col_o,
    output reg [N_COL-1:0] rcs_conf_ack_o,
    output wire [31:0] imem_radd_o,
    output reg [N_COL-1:0] rcs_conf_req_o,
    output reg [N_COL-1:0] col_start_o,
    output reg [N_COL-1:0] acc_ack_o,
    output reg [N_COL-1:0] acc_end_o
);

    // State machine states
    localparam GLOB_FSM_IDLE = 2'b00;
    localparam GLOB_FSM_RCS_CONF = 2'b01;
    localparam GLOB_FSM_DONE = 2'b10;

    // State machine registers
    reg [1:0] ctrl_fsm_state, ctrl_fsm_n_state;
    reg [N_COL-1:0] rcs_start_s;
    reg [N_COL-1:0] rcs_conf_ack;
    reg [N_COL-1:0] all_col_conf_end;
    integer i;

    // State machine
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_fsm_state <= GLOB_FSM_IDLE;
        end else begin
            ctrl_fsm_state <= ctrl_fsm_n_state;
        end
    end

    // Next state and output logic
    always @* begin
        ctrl_fsm_n_state = 2'bXX;
        rcs_start_s = 0;
        acc_ack_o = 0;

        case (ctrl_fsm_state)
            GLOB_FSM_IDLE: begin
                if (|acc_req_i) begin
                    ctrl_fsm_n_state = GLOB_FSM_RCS_CONF;
                end else begin
                    ctrl_fsm_n_state = GLOB_FSM_IDLE;
                end
            end

            GLOB_FSM_RCS_CONF: begin
                for (i = 0; i < N_COL; i = i + 1) begin
                    if (acc_req_i[i] && !rcs_conf_ack[i]) begin
                        rcs_start_s[i] = 1'b1;
                    end
                end

                if (&all_col_conf_end) begin
                    ctrl_fsm_n_state = GLOB_FSM_DONE;
                    acc_ack_o = acc_req_i;
                end else begin
                    ctrl_fsm_n_state = GLOB_FSM_RCS_CONF;
                end
            end

            GLOB_FSM_DONE: begin
                ctrl_fsm_n_state = GLOB_FSM_IDLE;
            end

            default: ctrl_fsm_n_state = 2'bXX;
        endcase
    end

    // Column configuration acknowledgment
    always @* begin
        for (i = 0; i < N_COL; i = i + 1) begin
            rcs_conf_ack[i] = rcs_conf_ack_o[i];
            all_col_conf_end[i] = rcs_exec_end_i[i];
        end
    end

    // Output assignments
    always @* begin
        rcs_conf_we_o = rcs_start_s;
        rcs_conf_re_o = rcs_start_s;
        rcs_pc_e_o = rcs_start_s;
        col_e_o = rcs_start_s;
        rcs_rst_col_o = (ctrl_fsm_state == GLOB_FSM_IDLE);
        rcs_conf_req_o = rcs_start_s;
        col_start_o = rcs_start_s;
        acc_end_o = acc_ack_o;
    end

    // Program counter generation
    always @* begin
        for (i = 0; i < N_COL; i = i + 1) begin
            if (rcs_br_req_i[i]) begin
                case(i)
                    0: rcs_pc_o_0 = rcs_br_add_i_0;
                    1: rcs_pc_o_1 = rcs_br_add_i_1;
                    2: rcs_pc_o_2 = rcs_br_add_i_2;
                    3: rcs_pc_o_3 = rcs_br_add_i_3;
                endcase
            end else if (rcs_stall_i[i]) begin
                case(i)
                    0: rcs_pc_o_0 = rcs_pc_o_0;
                    1: rcs_pc_o_1 = rcs_pc_o_1;
                    2: rcs_pc_o_2 = rcs_pc_o_2;
                    3: rcs_pc_o_3 = rcs_pc_o_3;
                endcase
            end else begin
                case(i)
                    0: rcs_pc_o_0 = rcs_pc_o_0 + 1;
                    1: rcs_pc_o_1 = rcs_pc_o_1 + 1;
                    2: rcs_pc_o_2 = rcs_pc_o_2 + 1;
                    3: rcs_pc_o_3 = rcs_pc_o_3 + 1;
                endcase
            end
        end
    end

    // Instruction memory address generation
    assign imem_radd_o = kmem_rdata_i;

endmodule

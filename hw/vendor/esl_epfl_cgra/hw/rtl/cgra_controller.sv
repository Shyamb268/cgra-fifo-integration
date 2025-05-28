// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

module cgra_controller #(
    parameter int unsigned N_COL = 4,
    parameter int unsigned N_ROW = 4
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [N_COL-1:0] acc_req_i,
    input  logic imem_gnt_ctrl_i,
    input  logic imem_rvalid_ctrl_i,
    input  logic [31:0] kmem_rdata_i,
    input  logic [N_COL-1:0] ker_id_req_i,
    input  logic [N_COL-1:0] data_stall_i,
    input  logic [N_COL-1:0] rcs_br_req_i,
    input  logic [31:0] rcs_br_add_i [N_COL-1:0],
    input  logic [N_COL-1:0] rcs_stall_i,
    input  logic [N_COL-1:0] rcs_exec_end_i,
    output logic [N_COL-1:0] rcs_conf_we_o,
    output logic [N_COL-1:0] rcs_conf_re_o,
    output logic [N_COL-1:0] rcs_pc_e_o,
    output logic [31:0] rcs_pc_o [N_COL-1:0],
    output logic [N_COL-1:0] col_e_o,
    output logic [N_COL-1:0] rcs_rst_col_o,
    output logic [N_COL-1:0] rcs_conf_ack_o,
    output logic [31:0] imem_radd_o,
    output logic [N_COL-1:0] rcs_conf_req_o,
    output logic [N_COL-1:0] col_start_o,
    output logic [N_COL-1:0] acc_ack_o,
    output logic [N_COL-1:0] acc_end_o
);

    // State machine states
    localparam GLOB_FSM_IDLE = 2'b00;
    localparam GLOB_FSM_RCS_CONF = 2'b01;
    localparam GLOB_FSM_DONE = 2'b10;

    // State machine registers
    logic [1:0] ctrl_fsm_state, ctrl_fsm_n_state;
    logic [N_COL-1:0] rcs_start_s;
    logic [N_COL-1:0] rcs_conf_ack;
    logic [N_COL-1:0] all_col_conf_end;

    // State machine
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_fsm_state <= GLOB_FSM_IDLE;
        end else begin
            ctrl_fsm_state <= ctrl_fsm_n_state;
        end
    end

    // Next state and output logic
    always_comb begin
        ctrl_fsm_n_state = 2'bXX;
        rcs_start_s = '0;
        acc_ack_o = '0;

        unique case (ctrl_fsm_state)
            GLOB_FSM_IDLE: begin
                if (|acc_req_i) begin
                    ctrl_fsm_n_state = GLOB_FSM_RCS_CONF;
                end else begin
                    ctrl_fsm_n_state = GLOB_FSM_IDLE;
                end
            end

            GLOB_FSM_RCS_CONF: begin
                for (int i = 0; i < N_COL; i++) begin
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
    always_comb begin
        for (int i = 0; i < N_COL; i++) begin
            rcs_conf_ack[i] = rcs_conf_ack_o[i];
            all_col_conf_end[i] = rcs_exec_end_i[i];
        end
    end

    // Output assignments
    assign rcs_conf_we_o = rcs_start_s;
    assign rcs_conf_re_o = rcs_start_s;
    assign rcs_pc_e_o = rcs_start_s;
    assign col_e_o = rcs_start_s;
    assign rcs_rst_col_o = (ctrl_fsm_state == GLOB_FSM_IDLE);
    assign rcs_conf_req_o = rcs_start_s;
    assign col_start_o = rcs_start_s;
    assign acc_end_o = acc_ack_o;

    // Program counter generation
    always_comb begin
        for (int i = 0; i < N_COL; i++) begin
            if (rcs_br_req_i[i]) begin
                rcs_pc_o[i] = rcs_br_add_i[i];
            end else if (rcs_stall_i[i]) begin
                rcs_pc_o[i] = rcs_pc_o[i];
            end else begin
                rcs_pc_o[i] = rcs_pc_o[i] + 1;
            end
        end
    end

    // Instruction memory address generation
    assign imem_radd_o = kmem_rdata_i;

endmodule

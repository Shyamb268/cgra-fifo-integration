// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

module synchronizer
(
  input  wire                               clk_i,
  input  wire                               rst_ni,
  input  wire                               acc_ack_i,
  input  wire     [N_COL-1:0]               acc_end_i,
  input  wire     [KMEM_WIDTH-1:0]          conf_word_i,
  input  wire     [N_COL-1:0]               col_start_i,
  input  wire     [N_COL-1:0]               col_stall_i,
  input  wire     [REG_REQ_WIDTH-1:0]       reg_req_i,
  output wire     [REG_RSP_WIDTH-1:0]       reg_rsp_o,
  output wire     [N_COL-1:0]               acc_req_o,
  output wire     [KER_CONF_N_REG_LOG2-1:0] ker_id_req_o,
  output wire     [DP_WIDTH-1:0]            rd_ptr_o_0,
  output wire     [DP_WIDTH-1:0]            rd_ptr_o_1,
  output wire     [DP_WIDTH-1:0]            wr_ptr_o_0,
  output wire     [DP_WIDTH-1:0]            wr_ptr_o_1,
  output wire     [N_COL-1:0]               col_acc_map_o_0,
  output wire                               evt_o
);

  // State encoding using parameters
  parameter SYNC_FSM_LOOP_REQ  = 2'b00;
  parameter SYNC_FSM_READ_CONF = 2'b01;
  parameter SYNC_FSM_FIND_COL  = 2'b10;
  parameter SYNC_FSM_WAIT_ACK  = 2'b11;
  parameter SYNC_FSM_XXX       = 2'bxx;

  reg [1:0] sync_fsm_state, sync_fsm_n_state;

  reg [KER_CONF_N_REG_LOG2-1:0] ker_id_req_s;
  reg [N_COL-1:0] map_ready [0:N_COL-1];
  reg [N_COL-1:0] col_map_sel [0:N_COL-1];
  reg [N_COL-1:0] col_status_reg;
  reg [N_COL-1:0] acc_req_reg;
  reg [N_COL-1:0] acc_req_mapped;
  reg [KER_CONF_N_REG_LOG2-1:0] conf_w_add_reg;
  reg [N_COL-1:0] ker_col_req_s;
  reg [N_COL-1:0] ker_col_req_reg;
  reg [N_COL-1:0] col_acc_map_reg [0:N_COL-1];
  integer i, k;

  // Generate an interrupt everytime an acceleration ends
  assign evt_o = |acc_end_i;

  assign ker_id_req_o = conf_w_add_reg;
  assign ker_col_req_s = conf_word_i[KER_N_COL_HB:KER_N_COL_LB];

  // Create all the possible mapping solutions
  always @* begin : col_map_sel_process
    col_map_sel[0] = ker_col_req_reg;
    for (i=1; i<N_COL; i=i+1) begin
      col_map_sel[i][0] = col_map_sel[i-1][N_COL-1];
      for (k=1; k<N_COL; k=k+1) begin
        col_map_sel[i][k] = col_map_sel[i-1][k-1];
      end
    end
  end

  // Check which mapping are actually possible
  always @* begin : map_ready_process
    for (i=0; i<N_COL; i=i+1) begin
      map_ready[i] = ~col_status_reg & col_map_sel[i];
    end
  end

  assign acc_req_o     = acc_req_reg;
  assign col_acc_map_o_0 = col_acc_map_reg[0];
  // Add more assignments for col_acc_map_o_1, ... as needed

  // Synchronizer FSM
  always @* begin
    sync_fsm_n_state = SYNC_FSM_XXX;
    acc_req_mapped   = 0;
    case (sync_fsm_state)
      SYNC_FSM_LOOP_REQ:
      begin
        if ((|ker_id_req_s) == 1'b1) begin
          sync_fsm_n_state = SYNC_FSM_READ_CONF;
        end else begin
          sync_fsm_n_state = SYNC_FSM_LOOP_REQ;
        end
      end
      SYNC_FSM_READ_CONF:
      begin
        sync_fsm_n_state = SYNC_FSM_FIND_COL;
      end
      SYNC_FSM_FIND_COL:
      begin
        for (i=0; i<N_COL; i=i+1) begin
          if (map_ready[i] == col_map_sel[i]) begin
            acc_req_mapped   = col_map_sel[i];
            sync_fsm_n_state = SYNC_FSM_WAIT_ACK;
          end
        end
      end
      SYNC_FSM_WAIT_ACK:
      begin
        if(acc_ack_i == 1'b1) begin
          sync_fsm_n_state = SYNC_FSM_LOOP_REQ;
        end else begin
          sync_fsm_n_state = SYNC_FSM_WAIT_ACK;
        end
      end
      default: sync_fsm_n_state = SYNC_FSM_XXX;
    endcase  
  end

  // Synchronizer flip-flops
  always @(posedge clk_i or negedge rst_ni)
  begin
    if(rst_ni == 1'b0) begin
      sync_fsm_state  <= SYNC_FSM_LOOP_REQ;
      conf_w_add_reg  <= 0;
      ker_col_req_reg <= 0;
      acc_req_reg     <= 0;    
    end else begin
      sync_fsm_state <= sync_fsm_n_state;
      if (sync_fsm_n_state == SYNC_FSM_READ_CONF) begin
        conf_w_add_reg <= ker_id_req_s;
      end
      if (sync_fsm_state == SYNC_FSM_READ_CONF) begin
        ker_col_req_reg <= ker_col_req_s;
      end
      if (sync_fsm_n_state == SYNC_FSM_WAIT_ACK && sync_fsm_state == SYNC_FSM_FIND_COL) begin
        acc_req_reg <= acc_req_mapped;
      end else if (acc_ack_i == 1'b1) begin
        acc_req_reg <= 0;
      end
    end
  end

  // Register to know for each column if it is used in a multi-column kernel
  generate
    for (i=0; i<N_COL; i=i+1) begin : col_map_reg_gen
      always @(posedge clk_i or negedge rst_ni)
      begin
        if (rst_ni == 1'b0) begin
          col_acc_map_reg[i] <= 0;
        end else begin
          if (col_start_i[i] == 1'b1) begin
            col_acc_map_reg[i] <= acc_req_reg;
          end
        end
      end
    end
  endgenerate

  // Component(s) mapping
  // peripheral_regs instantiation omitted for compatibility

endmodule

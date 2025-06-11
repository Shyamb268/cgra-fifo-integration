// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

module data_bus_handler
(
  input  wire                           clk_i,
  input  wire                           rst_ni,
  input  wire [N_COL-1:0]               rcs_data_req_i,
  input  wire [N_COL-1:0]               rcs_data_wen_i,
  input  wire [N_COL-1:0]               rcs_data_ind_i,
  input  wire [DP_WIDTH-1:0]            rcs_data_add_i [0:N_COL-1],
  input  wire [DP_WIDTH-1:0]            rcs_data_wdata_i [0:N_COL-1],
  input  wire [RC_CONST_WIDTH-1:0]      rcs_add_inc_i [0:N_COL-1],
  input  wire [DP_WIDTH-1:0]            rd_ptr_i [0:MAX_COL_REQ-1],
  input  wire [DP_WIDTH-1:0]            wr_ptr_i [0:MAX_COL_REQ-1],
  input  wire [N_COL-1:0]               bus_data_gnt_i,
  input  wire [DATA_BUS_DATA_WIDTH-1:0] bus_data_rdata_i [0:N_COL-1],
  input  wire [N_COL-1:0]               bus_r_valid_i,
  input  wire [N_COL-1:0]               col_start_i,
  input  wire [N_COL-1:0]               col_conf_ack_i,
  input  wire [N_COL-1:0]               col_acc_map_i [0:N_COL-1],
  // FIFO interface for input data
  input  wire [DATA_BUS_DATA_WIDTH-1:0] fifo_data_i,
  input  wire                           fifo_valid_i,
  output wire                           fifo_ready_o,
  output wire [DATA_BUS_DATA_WIDTH-1:0] fifo_data_o,
  output wire                           fifo_valid_o,
  input  wire                           fifo_ready_i,
  output wire [N_COL-1:0]               bus_data_req_o,
  output wire [DATA_BUS_ADD_WIDTH-1:0]  bus_data_add_o [0:N_COL-1],
  output wire [N_COL-1:0]               bus_data_wen_o,
  output wire [3:0]                     bus_data_be_o [0:N_COL-1],
  output wire [DATA_BUS_DATA_WIDTH-1:0] bus_data_wdata_o [0:N_COL-1],
  output wire [DP_WIDTH-1:0]            rcs_data_rdata_o [0:N_COL-1],
  output wire [N_COL-1:0]               rcs_data_gnt_o,
  output wire [N_COL-1:0]               rcs_data_rvalid_o,
  output wire [N_COL-1:0]               data_stall_o
);

  parameter AHB_FSM_ADD_PHASE  = 1'b0;
  parameter AHB_FSM_DATA_PHASE = 1'b1;
  // parameter AHB_FSM_XXX        = 'x;
  parameter N_COL_LOG2 = $clog2(N_COL);

  genvar j;

  reg [N_COL-1:0] ahb_fsm_state;
  reg [N_COL-1:0] ahb_fsm_n_state;

  reg [DATA_BUS_ADD_WIDTH-1:0] rd_data_cnt_col [0:N_COL-1];
  reg [DATA_BUS_ADD_WIDTH-1:0] wr_data_cnt_col [0:N_COL-1];
  reg [DATA_BUS_DATA_WIDTH-1:0] bus_rdata_reg [0:N_COL-1];
  reg [DATA_BUS_ADD_WIDTH-1:0] bus_data_add_s [0:N_COL-1];
  reg ahb_add_success [0:N_COL-1];
  reg ahb_data_success [0:N_COL-1];
  reg [N_COL-1:0] data_stall_s;
  reg [N_COL-1:0] data_stall_comb_s;
  // Multi-column kernel: choose correct data pointer
  reg [N_COL_LOG2-1:0] acc_ack_col_accum;
  reg [DATA_BUS_ADD_WIDTH-1:0] rcs_add_inc_sign_ext [0:N_COL-1];

  // Add a simple output FIFO placeholder for FFT results
  reg [DATA_BUS_DATA_WIDTH-1:0] fft_result_data;
  reg fft_result_valid;

  assign data_stall_o     = data_stall_comb_s;
  // Use this version if single-cycle bus access is not possible
  assign bus_data_wdata_o = rcs_data_wdata_i;
  assign bus_data_add_o   = bus_data_add_s;
  assign bus_data_wen_o   = rcs_data_wen_i;
  assign fifo_data_o      = fft_result_data;
  assign fifo_valid_o     = fft_result_valid;

  always_comb begin : inc_sign_extension_logic
    for(integer k=0; k<N_COL; k++) begin
      rcs_add_inc_sign_ext[k] = {{(DATA_BUS_ADD_WIDTH-RC_CONST_WIDTH){rcs_add_inc_i[k][RC_CONST_WIDTH-1]}}, rcs_add_inc_i[k][RC_CONST_WIDTH-1:0]};
    end
  end

  generate
    for(j=0; j<N_COL; j++) begin : data_bus_ctrl_reg_gen

      assign rcs_data_rdata_o[j]  = ahb_data_success[j] == 1'b1 ? bus_data_rdata_i[j] : bus_rdata_reg[j];
      assign data_stall_comb_s[j] = |(col_acc_map_i[j] & data_stall_s);
      assign rcs_data_gnt_o[j]    = bus_data_gnt_i[j];
      assign rcs_data_rvalid_o[j] = bus_r_valid_i[j];

      // AHB FSM state
      always @(posedge clk_i or negedge rst_ni)
      begin
        if (rst_ni == 1'b0) begin
          ahb_fsm_state[j] <= AHB_FSM_ADD_PHASE;
        end else begin
          ahb_fsm_state[j] <= ahb_fsm_n_state[j];
        end
      end

      // Data read counter register for each column
      always @(posedge clk_i, negedge rst_ni)
      begin
        if (rst_ni == 1'b0) begin
          rd_data_cnt_col[j] <= '0;
        end else begin
          if (col_start_i[j] == 1'b1) begin
            rd_data_cnt_col[j] <= rd_ptr_i[acc_ack_col_accum];
          end else if (rcs_data_req_i[j] == 1'b1 && rcs_data_wen_i[j] == 1'b1 && rcs_data_ind_i[j] == 1'b0 && ahb_add_success[j] == 1'b1) begin
            rd_data_cnt_col[j] <= rd_data_cnt_col[j] + rcs_add_inc_sign_ext[j]; //32'h4; // 32b word add increase
          end
        end
      end

      // Data write counter register for each column
      always @(posedge clk_i, negedge rst_ni)
      begin
        if (rst_ni == 1'b0) begin
          wr_data_cnt_col[j]  <= '0;
        end else begin
          if (col_start_i[j] == 1'b1) begin
            wr_data_cnt_col[j] <= wr_ptr_i[acc_ack_col_accum];
          end else if (rcs_data_req_i[j] == 1'b1 && rcs_data_wen_i[j] == 1'b0 && rcs_data_ind_i[j] == 1'b0 && ahb_add_success[j] == 1'b1) begin
            wr_data_cnt_col[j]  <= wr_data_cnt_col[j] + rcs_add_inc_sign_ext[j]; //32'h4; // 32b word add increase
          end
        end
      end

      // Read data flip-flop in case the execution is still stall (multi-column kernel)
      always @(posedge clk_i, negedge rst_ni)
      begin
        if (rst_ni == 1'b0) begin
          bus_rdata_reg[j] <= '0;
        end else begin
          if(ahb_data_success[j] == 1'b1) begin
            bus_rdata_reg[j] <= bus_data_rdata_i[j];
          end
        end
      end

    end
  endgenerate

  always_comb
  begin
    acc_ack_col_accum = '0;

    for (integer k=0; k<N_COL; k++) begin
      // address multiplexer
      bus_data_add_s[k] = '0;

      if (rcs_data_ind_i[k] == 1'b1) begin
        bus_data_add_s[k] = rcs_data_add_i[k];
      end else begin
        if (rcs_data_wen_i[k] == 1'b1) begin
          bus_data_add_s[k] = rd_data_cnt_col[k];
        end else begin
          bus_data_add_s[k] = wr_data_cnt_col[k];
        end
      end

      // Accumulate column that have acknowledge their configuration
      acc_ack_col_accum += col_conf_ack_i[k];
    end
  end

  always_comb
  begin
    for (integer k=0; k<N_COL; k++) begin
      // data bus stall generation
      // If not all request served or the last request has not been finalized wait
      if (rcs_data_req_i[k] == 1'b1 || ahb_fsm_n_state[k] == AHB_FSM_DATA_PHASE) begin
        data_stall_s[k] = 1'b1;
      end else begin
        data_stall_s[k] = 1'b0;
      end
    end
  end

  generate
    for (j=0; j<N_COL; j++) begin : ahb_ctrl_gen
      always_comb
      begin

        ahb_fsm_n_state[j] = 1'bX;

        bus_data_req_o[j]   = 1'b0;
        bus_data_be_o[j]    = 4'b1111;
        ahb_add_success[j]  = 1'b0;
        ahb_data_success[j] = 1'b0;

        case (ahb_fsm_state[j])

          AHB_FSM_ADD_PHASE:
          begin
            // Request pending
            if (rcs_data_req_i[j] == 1'b1) begin
              bus_data_req_o[j] = 1'b1;

              if (bus_data_gnt_i[j] == 1'b1) begin
                if (rcs_data_wen_i[j] == 1'b1) begin
                  ahb_fsm_n_state[j] = AHB_FSM_DATA_PHASE;
                  ahb_add_success[j] = 1'b1;
                end else begin // Single-cycle write
                  ahb_fsm_n_state[j]  = AHB_FSM_ADD_PHASE;
                  ahb_add_success[j]  = 1'b1;
                  ahb_data_success[j] = 1'b1;
                end
              end else begin
                ahb_fsm_n_state[j] = AHB_FSM_ADD_PHASE;
              end
            end else begin
              ahb_fsm_n_state[j] = AHB_FSM_ADD_PHASE;
            end
          end

          AHB_FSM_DATA_PHASE:
          begin
            if (bus_r_valid_i[j] == 1'b1) begin
              ahb_fsm_n_state[j]  = AHB_FSM_ADD_PHASE;
              ahb_data_success[j] = 1'b1;
            end else begin
              ahb_fsm_n_state[j] = AHB_FSM_DATA_PHASE;
            end
          end

          default:
          begin
            ahb_fsm_n_state[j] = AHB_FSM_ADD_PHASE;
          end

        endcase
      end
    end
  endgenerate

  // Modify the data read logic to use FIFO
  always_comb begin
    for (int j=0; j<N_COL; j++) begin
      if (rcs_data_req_i[j] == 1'b1 && rcs_data_wen_i[j] == 1'b0) begin
        // Read from FIFO instead of processor ROM
        rcs_data_rdata_o[j] = fifo_data_i;
        rcs_data_rvalid_o[j] = fifo_valid_i;
        fifo_ready_o = ~data_stall_o[j];
      end else begin
        rcs_data_rdata_o[j] = bus_data_rdata_i[j];
        rcs_data_rvalid_o[j] = bus_r_valid_i[j];
        fifo_ready_o = 1'b0;
      end
    end
  end

  // Use fifo_ready_i for handshake
  // Example: set valid high when result is ready, clear when ready_i is high
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fft_result_data <= 0;
      fft_result_valid <= 0;
    end else begin
      // TODO: Replace this with actual FFT result logic
      // Example: output a dummy value for now
      fft_result_data <= 32'hDEADBEEF;
      fft_result_valid <= 1'b1;
      if (fifo_ready_i) begin
        fft_result_valid <= 1'b0;
      end
    end
  end

endmodule

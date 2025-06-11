// Copyright 2023 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// import cgra_pkg::*;

module cgra_rcs
(
  input  wire [N_COL-1:0] clk_i,
  input  wire [N_COL-1:0] rst_col_i,
  input  wire [N_COL-1:0] rcs_conf_we_i,
  input  wire [N_COL-1:0] rcs_conf_re_i,
  input  wire [RCS_NUM_CREG_LOG2-1:0] rcs_col_pc_i_0,
  input  wire [RCS_NUM_CREG_LOG2-1:0] rcs_col_pc_i_1,
  input  wire [RCS_NUM_CREG_LOG2-1:0] rcs_col_pc_i_2,
  input  wire [RCS_NUM_CREG_LOG2-1:0] rcs_col_pc_i_3,
  input  wire [INSTR_WIDTH-1:0] rcs_conf_words_i_0,
  input  wire [INSTR_WIDTH-1:0] rcs_conf_words_i_1,
  input  wire [INSTR_WIDTH-1:0] rcs_conf_words_i_2,
  input  wire [INSTR_WIDTH-1:0] rcs_conf_words_i_3,
  input  wire [N_COL-1:0] rcs_pc_e_i,
  input  wire [DP_WIDTH-1:0] data_rdata_i_0,
  input  wire [DP_WIDTH-1:0] data_rdata_i_1,
  input  wire [DP_WIDTH-1:0] data_rdata_i_2,
  input  wire [DP_WIDTH-1:0] data_rdata_i_3,
  input  wire [N_COL-1:0] data_gnt_i,
  input  wire [N_COL-1:0] data_rvalid_i,
  input  wire [N_COL-1:0] col_acc_map_i_0,
  input  wire [N_COL-1:0] col_acc_map_i_1,
  input  wire [N_COL-1:0] col_acc_map_i_2,
  input  wire [N_COL-1:0] col_acc_map_i_3,
  output reg  [N_COL-1:0] data_req_o,
  output reg  [N_COL-1:0] data_wen_o,
  output reg  [N_COL-1:0] data_ind_o,
  output reg  [DP_WIDTH-1:0] data_add_o_0,
  output reg  [DP_WIDTH-1:0] data_add_o_1,
  output reg  [DP_WIDTH-1:0] data_add_o_2,
  output reg  [DP_WIDTH-1:0] data_add_o_3,
  output reg  [DP_WIDTH-1:0] data_wdata_o_0,
  output reg  [DP_WIDTH-1:0] data_wdata_o_1,
  output reg  [DP_WIDTH-1:0] data_wdata_o_2,
  output reg  [DP_WIDTH-1:0] data_wdata_o_3,
  output reg  [RC_CONST_WIDTH-1:0] add_inc_o_0,
  output reg  [RC_CONST_WIDTH-1:0] add_inc_o_1,
  output reg  [RC_CONST_WIDTH-1:0] add_inc_o_2,
  output reg  [RC_CONST_WIDTH-1:0] add_inc_o_3,
  output reg  [N_COL-1:0] rcs_br_req_o,
  output reg  [RCS_NUM_CREG_LOG2-1:0] rcs_br_add_o_0,
  output reg  [RCS_NUM_CREG_LOG2-1:0] rcs_br_add_o_1,
  output reg  [RCS_NUM_CREG_LOG2-1:0] rcs_br_add_o_2,
  output reg  [RCS_NUM_CREG_LOG2-1:0] rcs_br_add_o_3,
  output reg  [N_COL-1:0] rcs_stall_o,
  output reg  [N_COL-1:0] exec_end_o
);

  reg [N_COL-1:0] rcs_ex_end [0:N_ROW-1];
  reg [N_COL-1:0] rcs_stall_s [0:N_ROW-1];
  reg [N_COL-1:0] rcs_nop_s [0:N_ROW-1];
  reg [N_COL-1:0] rc_stall_col;
  reg [N_ROW-1:0] rcs_br_req_row_s [0:N_COL-1];
  reg [N_COL-1:0] rcs_br_req_row_merged_s;
  reg [N_COL-1:0] rcs_br_req_col_merged_s [0:N_COL-1];
  reg [N_COL-1:0] rcs_exec_end_col_merged;
  reg [N_COL-1:0] rc_stall_comb;
  reg [N_COL-1:0] rcs_br_req [0:N_ROW-1];
  reg [N_COL-1:0] exec_end_s;
  reg [N_COL-1:0] data_req_s [0:N_ROW-1];
  reg [N_COL-1:0] data_wen_s [0:N_ROW-1];
  reg [N_COL-1:0] data_ind_s [0:N_ROW-1];
  reg [DP_WIDTH-1:0] data_add_s [0:N_ROW-1][0:N_COL-1];
  reg [DP_WIDTH-1:0] data_wdata_s [0:N_ROW-1][0:N_COL-1];
  reg [RC_CONST_WIDTH-1:0] add_inc_s [0:N_ROW-1][0:N_COL-1];
  reg [DP_WIDTH-1:0] rcs_wdata_s [0:N_COL-1];

  reg [DP_WIDTH-1:0] rcs_res [0:N_ROW-1][0:N_COL-1];
  reg [DP_WIDTH-1:0] rcs_res_reg [0:N_ROW-1][0:N_COL-1];
  reg [DP_WIDTH-1:0] rcs_res_reg_temp [0:N_ROW-1][0:N_COL-1];
  reg [ALU_N_FLAG-1:0] rcs_flag [0:N_ROW-1][0:N_COL-1];
  reg [ALU_N_FLAG-1:0] rcs_flag_reg [0:N_ROW-1][0:N_COL-1];
  reg [ALU_N_FLAG-1:0] rcs_flag_reg_temp [0:N_ROW-1][0:N_COL-1];

  reg [RCS_NUM_CREG_LOG2-1:0] rcs_br_add [0:N_ROW-1][0:N_COL-1];

  reg [N_ROW-1:0] data_req_gnt_mask [0:N_COL-1];
  reg [N_ROW-1:0] gnt_demux [0:N_COL-1];
  reg [N_ROW-1:0] data_req_rvalid_mask [0:N_COL-1];
  reg [N_ROW-1:0] rvalid_demux [0:N_COL-1];
  reg [N_ROW-1:0] gnt_mask [0:N_COL-1];
  reg [N_ROW-1:0] rvalid_mask [0:N_COL-1];

  reg [-1:N_COL][DP_WIDTH-1:0] rcs_mesh_res [-1:N_ROW];
  reg [-1:N_COL][ALU_N_FLAG-1:0] rcs_mesh_flag [-1:N_ROW];

  integer i, j, k, l, m, n;
  genvar gen_j_1;

  assign rcs_stall_o = rc_stall_comb;
  assign exec_end_o = exec_end_s;

  assign data_wdata_o_0 = rcs_wdata_s[0];
  assign data_wdata_o_1 = rcs_wdata_s[1];
  assign data_wdata_o_2 = rcs_wdata_s[2];
  assign data_wdata_o_3 = rcs_wdata_s[3];

  always @* begin
    for (l=0; l<N_COL; l=l+1) begin
      // Merge rows branch request
      rcs_br_req_row_merged_s[l] = 0;
      for (k=0; k<N_ROW; k=k+1) begin
        rcs_br_req_row_s[l][k] = rcs_br_req[k][l];
        rcs_br_req_row_merged_s[l] = rcs_br_req_row_merged_s[l] | rcs_br_req[k][l];
      end
      // Capture execution end signal
      rcs_exec_end_col_merged[l] = 0;
      for (k=0; k<N_ROW; k=k+1) begin
        rcs_exec_end_col_merged[l] = rcs_exec_end_col_merged[l] | rcs_ex_end[k][l];
      end
      // RCs stall capture
      rc_stall_col[l] = 0;
      for (k=0; k<N_ROW; k=k+1) begin
        rc_stall_col[l] = rc_stall_col[l] | rcs_stall_s[k][l];
      end
    end
  end

  always @* begin
    for (l=0; l<N_COL; l=l+1) begin
      // Combine the stall for multi-columns kernel
      rc_stall_comb[l] = |(rc_stall_col & col_acc_map_i_0[l]);
      // Branch cols request for multi-cols kernels
      rcs_br_req_col_merged_s[l] = rcs_br_req_row_merged_s & col_acc_map_i_0[l];
    end
  end

  // Only let the execution end signal go through if there is not branch request and check if signal should be propagated to other columns
  always @* begin
    for (l=0; l<N_COL; l=l+1) begin
      exec_end_s[l] = |(rcs_exec_end_col_merged & ~rcs_br_req_o & col_acc_map_i_0[l]);
    end
  end

  // Maintain request high as long as one RC is not served
  always @* begin
    for (l=0; l<N_COL; l=l+1) begin
      data_req_o[l] = |data_req_gnt_mask[l];
    end
  end

  // Select which request to grant
  generate
    for (gen_j_1=0; gen_j_1<N_COL; gen_j_1=gen_j_1+1) begin : gnt_demux_gen
      always @* begin
        gnt_demux[gen_j_1] = 0;
        // for each row
        for (k=0; k<N_ROW; k=k+1) begin
          if (data_req_gnt_mask[gen_j_1][k] == 1'b1 && data_gnt_i[gen_j_1] == 1'b1) begin
            gnt_demux[gen_j_1][k] = 1'b1;
          end
        end
      end
    end
  endgenerate

  // Select which request to forward rvalid (only for read wen=1)
  generate
    for (gen_j_1=0; gen_j_1<N_COL; gen_j_1=gen_j_1+1) begin : rvalid_demux_gen
      always @* begin
        rvalid_demux[gen_j_1] = 0;
        // for each row
        for (k=0; k<N_ROW; k=k+1) begin
          if (data_req_rvalid_mask[gen_j_1][k] == 1'b1 && data_wen_s[k][gen_j_1] == 1'b1 && data_rvalid_i[gen_j_1] == 1'b1) begin
            rvalid_demux[gen_j_1][k] = 1'b1;
          end
        end
      end
    end
  endgenerate

  // Mask data request of an RC once it is granted
  always @* begin
    for (l=0; l<N_COL; l=l+1) begin
      for (m=0; m<N_ROW; m=m+1) begin
        // mask the request once it is granted
        data_req_gnt_mask[l][m] = data_req_s[m][l] & gnt_mask[l][m];
      end
    end
  end

  // Mask data request of an RC once data is read
  always @* begin
    for (l=0; l<N_COL; l=l+1) begin
      for (m=0; m<N_ROW; m=m+1) begin
        // mask the request once data is read
        data_req_rvalid_mask[l][m] = data_req_s[m][l] & rvalid_mask[l][m];
      end
    end
  end

  // Generate gnt mask
  generate
    for (gen_j_1=0; gen_j_1<N_COL; gen_j_1=gen_j_1+1) begin : gnt_mask_gen
      always @(posedge clk_i[gen_j_1]) begin
        if (rst_col_i[gen_j_1] == 1'b1 || rcs_pc_e_i[gen_j_1] == 1'b1) begin // reset at start and every new instruction
          for (k=0; k<N_ROW; k=k+1) begin
            gnt_mask[gen_j_1][k] <= 1'b1;
          end
        end else begin
          for (k=0; k<N_ROW; k=k+1) begin
            if (gnt_demux[gen_j_1][k] == 1'b1) begin
              gnt_mask[gen_j_1][k] <= 1'b0;
            end
          end
        end
      end
    end
  endgenerate

  // Register between RCs
  genvar gen_j_6;
  generate
    for (gen_j_6=0; gen_j_6<N_COL; gen_j_6=gen_j_6+1) begin : rc_col_gen
      always @(posedge clk_i[gen_j_6]) begin
        if (rst_col_i[gen_j_6] == 1'b1) begin
          for (int k=0; k<N_ROW; k=k+1) begin
            rcs_res_reg[k][gen_j_6]  <= 0;
            rcs_flag_reg[k][gen_j_6] <= 0;
            rcs_res_reg_temp[k][gen_j_6]  <= 0;
            rcs_flag_reg_temp[k][gen_j_6] <= 0;
          end
        end else begin
          for (int k=0; k<N_ROW; k=k+1) begin
            if (rcs_pc_e_i[gen_j_6] == 0) begin // PC enable is low
              if (rvalid_demux[gen_j_6][k] == 1'b1) begin // If the data is ready, copy it to a temproary buffer
                rcs_res_reg_temp[k][gen_j_6]  <= data_rdata_i_0[gen_j_6];
                rcs_flag_reg_temp[k][gen_j_6] <= {data_rdata_i_0[gen_j_6][DP_WIDTH-1], ~(|data_rdata_i_0[gen_j_6])};
              end
            end else begin // PC enable is high
              if (data_req_s[k][gen_j_6] == 0) begin
                if (rcs_nop_s[k][gen_j_6] == 0) begin
                  rcs_res_reg[k][gen_j_6]  <= rcs_res[k][gen_j_6];
                  rcs_flag_reg[k][gen_j_6] <= rcs_flag[k][gen_j_6];
                end
              end else begin  // Read data instruction
                if (rcs_nop_s[k][gen_j_6] == 0) begin
                  if (rvalid_demux[gen_j_6][k] == 1'b1) begin // If the data is ready, copy it straight away.
                    rcs_res_reg[k][gen_j_6]  <= data_rdata_i_0[gen_j_6];
                    rcs_flag_reg[k][gen_j_6] <= {data_rdata_i_0[gen_j_6][DP_WIDTH-1], ~(|data_rdata_i_0[gen_j_6])};
                  end else begin  // If the data is not ready, it was ready before, so copy the temp buffer.
                    // This is necessary as some special cases require it.
                    rcs_res_reg[k][gen_j_6]  <= rcs_res_reg_temp[k][gen_j_6];
                    rcs_flag_reg[k][gen_j_6] <= rcs_flag_reg_temp[k][gen_j_6];
                  end
                end
              end
            end
          end
        end
      end
    end
  endgenerate

  generate
    for (gen_j_6=0; gen_j_6<N_COL; gen_j_6=gen_j_6+1) begin : data_req_gen
      always @* begin
        // for each row
        data_add_o_0[gen_j_6] = 0; // default value
        for (k=0; k<N_ROW; k=k+1) begin
          if (data_req_gnt_mask[gen_j_6][k] == 1'b1) begin
            if (data_ind_s[k][gen_j_6] == 1'b1) begin
              // LWI or SWI
              data_add_o_0[gen_j_6] = data_add_s[k][gen_j_6];
            end else begin
              // LWD or SWD
              add_inc_o_0 = add_inc_s[k][gen_j_6];
            end
          end
        end
      end

      always @* begin
        // for each row
        rcs_wdata_s[gen_j_6] = 0; // default value
        for (k=0; k<N_ROW; k=k+1) begin
          if (data_req_gnt_mask[gen_j_6][k] == 1'b1 && data_wen_s[k][gen_j_6] == 0) begin
            rcs_wdata_s[gen_j_6] = data_wdata_s[k][gen_j_6];
          end
        end
      end

      always @* begin
        // for each row
        data_wen_o[gen_j_6] = 0; // default value
        data_ind_o[gen_j_6] = 0; // default value
        for (k=0; k<N_ROW; k=k+1) begin
          if (data_req_gnt_mask[gen_j_6][k] == 1'b1) begin
            data_wen_o[gen_j_6] = data_wen_s[k][gen_j_6];
            data_ind_o[gen_j_6] = data_ind_s[k][gen_j_6];
          end
        end
      end
    end
  endgenerate

  logic [N_COL-1:0] one_hot_encoding_col;
  logic [N_ROW-1:0] one_hot_encoding_row;

  // Branch request
  always @* begin
    for (l=0; l<N_COL; l=l+1) begin
      rcs_br_req_o[l] = 0;
      rcs_br_add_o_0[l] = 0;
      one_hot_encoding_col = {{(N_COL-1){1'b0}}, 1'b1};
      one_hot_encoding_row = {{(N_ROW-1){1'b0}}, 1'b1};

      for (k=0; k<N_COL; k=k+1) begin
        if (rcs_br_req_col_merged_s[l] == one_hot_encoding_col) begin
          for (n=0; n<N_ROW; n=n+1) begin
            if (rcs_br_req_row_s[k][n] == one_hot_encoding_row) begin
              rcs_br_req_o[l]  = 1'b1;
              rcs_br_add_o_0[l] = rcs_br_add[n][k];
            end
          end
        end
      end
    end
  end

  //---------------------------------------------------------------------
  //
  // CGRA torus connection array use to easily connect all cells
  //
  //---------------------------------------------------------------------

  always @* begin
    // RCs data result connections
    for (int k=0; k<N_ROW; k=k+1) begin
      for (int l=0; l<N_COL; l=l+1) begin
        rcs_mesh_res[k][l] = rcs_res_reg[k][l];
      end
    end
    for (int k=0; k<N_ROW; k=k+1) begin
      rcs_mesh_res[k][-1] = rcs_res_reg[k][N_COL-1];
      rcs_mesh_res[k][N_COL] = rcs_res_reg[k][0];
    end
    for (int l=0; l<N_COL; l=l+1) begin
      rcs_mesh_res[-1][l] = rcs_res_reg[N_ROW-1][l];
      rcs_mesh_res[N_ROW][l] = rcs_res_reg[0][l];
    end

    // RCs flag result connections
    for (int k=0; k<N_ROW; k=k+1) begin
      for (int l=0; l<N_COL; l=l+1) begin
        rcs_mesh_flag[k][l] = rcs_flag_reg[k][l];
      end
    end
    for (int k=0; k<N_ROW; k=k+1) begin
      rcs_mesh_flag[k][-1] = rcs_flag_reg[k][N_COL-1];
      rcs_mesh_flag[k][N_COL] = rcs_flag_reg[k][0];
    end
    for (int l=0; l<N_COL; l=l+1) begin
      rcs_mesh_flag[-1][l] = rcs_flag_reg[N_ROW-1][l];
      rcs_mesh_flag[N_ROW][l] = rcs_flag_reg[0][l];
    end
  end

  //---------------------------------------------------------------------
  //
  // Components mapping
  //
  //---------------------------------------------------------------------

  //  Example: 4x4 CGRA
  //  N_ROW x N_COL        col_0          col_1         col_2           col_3
  //
  //  RC1 / row_0      LTRC(0,0) ---- TRC (0,1) ---- TRC (0,2) ---- RTRC(0,3)
  //                       |              |              |              |
  //  RC2 / row_1      LRC (1,0) ---- CRC (1,1) ---- CRC (1,2) ---- RRC (1,3)
  //                       |              |              |              |
  //  RC3 / row_2      LRC (2,0) ---- CRC (2,1) ---- CRC (2,2) ---- RRC (2,3)
  //                       |              |              |              |
  //  RC4 / row_3      LBRC(3,0) ---- BRC (3,1) ---- BRC (3,2) ---- RBRC(3,3)

  genvar gen_j_6;
  generate
    for (i=0; i<N_ROW; i=i+1) begin : rc_row_gen
      for (gen_j_6=0; gen_j_6<N_COL; gen_j_6=gen_j_6+1) begin : rc_col_gen
        reconfigurable_cell rc_i (
          //                               [ROW][COL]
          .clk_i         (            clk_i     [gen_j_6] ),
          .rst_rc_i      (       rst_col_i      [gen_j_6] ),
          .conf_rdata_i  ( rcs_conf_words_i_0[i  ]      ),
          .data_rdata_i  (     data_rdata_i_0     [gen_j_6] ),
          .data_rvalid_i (     rvalid_demux[gen_j_6][i  ] ),
          .conf_we_i     (    rcs_conf_we_i     [gen_j_6] ),
          .conf_re_i     (    rcs_conf_re_i     [gen_j_6] ),
          .global_pc_i   (     rcs_col_pc_i_0     [gen_j_6] ),
          .pc_en_i       (       rcs_pc_e_i     [gen_j_6] ),
          .own_res_i     (     rcs_mesh_res[i  ][gen_j_6] ),
          .left_res_i    (     rcs_mesh_res[i  ][gen_j_6-1] ),
          .right_res_i   (     rcs_mesh_res[i  ][gen_j_6+1] ),
          .top_res_i     (     rcs_mesh_res[i-1][gen_j_6  ] ),
          .bottom_res_i  (     rcs_mesh_res[i+1][gen_j_6  ] ),
          .own_flag_i    (    rcs_mesh_flag[i  ][gen_j_6] ),
          .left_flag_i   (    rcs_mesh_flag[i  ][gen_j_6-1] ),
          .right_flag_i  (    rcs_mesh_flag[i  ][gen_j_6+1] ),
          .top_flag_i    (    rcs_mesh_flag[i-1][gen_j_6  ] ),
          .bottom_flag_i (    rcs_mesh_flag[i+1][gen_j_6  ] ),
          .result_o      (          rcs_res[i  ][gen_j_6] ),
          .flag_o        (         rcs_flag[i  ][gen_j_6] ),
          .br_req_o      (       rcs_br_req[i  ][gen_j_6] ),
          .br_add_o      (       rcs_br_add[i  ][gen_j_6] ),
          .data_req_o    (       data_req_s[i  ][gen_j_6] ),
          .data_wen_o    (       data_wen_s[i  ][gen_j_6] ),
          .data_ind_o    (       data_ind_s[i  ][gen_j_6] ),
          .data_add_o    (       data_add_s[i  ][gen_j_6] ),
          .data_wdata_o  (     data_wdata_s[i  ][gen_j_6] ),
          .add_inc_o     (        add_inc_s[i  ][gen_j_6] ),
          .rc_stall_o    (      rcs_stall_s[i  ][gen_j_6] ),
          .rc_nop_o      (        rcs_nop_s[i  ][gen_j_6] ),
          .exec_end_o    (       rcs_ex_end[i  ][gen_j_6] )
        );
      end
    end
  endgenerate

endmodule

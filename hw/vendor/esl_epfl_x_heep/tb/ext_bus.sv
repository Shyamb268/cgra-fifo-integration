// Copyright 2022 EPFL and Politecnico di Torino.
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// File: ext_bus.sv
// Author: Michele Caon
// Date: 19/05/2023
// Description: external peripheral bus for X-HEEP testbench

module ext_bus #(
    parameter int unsigned EXT_XBAR_NMASTER = 4,
    parameter int unsigned EXT_XBAR_NSLAVE = 4,
    parameter int unsigned EXT_XBAR_NSLAVE_LOG2 = $clog2(EXT_XBAR_NSLAVE),
    parameter int unsigned EXT_XBAR_NMASTER_LOG2 = $clog2(EXT_XBAR_NMASTER)
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  addr_map_rule_t [EXT_XBAR_NSLAVE-1:0] addr_map_i,
    input  logic [EXT_XBAR_NSLAVE_LOG2-1:0] default_idx_i,

    // X-HEEP core interface
    input  obi_req_t  heep_core_instr_req_i,
    output obi_resp_t heep_core_instr_resp_o,
    input  obi_req_t  heep_core_data_req_i,
    output obi_resp_t heep_core_data_resp_o,
    input  obi_req_t  heep_debug_master_req_i,
    output obi_resp_t heep_debug_master_resp_o,
    input  obi_req_t  heep_dma_read_req_i,
    output obi_resp_t heep_dma_read_resp_o,
    input  obi_req_t  heep_dma_write_req_i,
    output obi_resp_t heep_dma_write_resp_o,
    input  obi_req_t  heep_dma_addr_req_i,
    output obi_resp_t heep_dma_addr_resp_o,

    // External master interface
    input  obi_req_t [EXT_XBAR_NMASTER-1:0] ext_master_req_i,
    output obi_resp_t [EXT_XBAR_NMASTER-1:0] ext_master_resp_o,
    output obi_req_t [EXT_XBAR_NMASTER-1:0] heep_slave_req_o,
    input  obi_resp_t [EXT_XBAR_NMASTER-1:0] heep_slave_resp_i,
    output obi_req_t [EXT_XBAR_NSLAVE-1:0] ext_slave_req_o,
    input  obi_resp_t [EXT_XBAR_NSLAVE-1:0] ext_slave_resp_i
);
  import obi_pkg::*;
  import addr_map_rule_pkg::*;
  import core_v_mini_mcu_pkg::*;

  // Address decoder for each master
  logic [EXT_XBAR_NSLAVE_LOG2-1:0] master_idx [EXT_XBAR_NMASTER-1:0];
  logic [EXT_XBAR_NSLAVE-1:0] master_sel [EXT_XBAR_NMASTER-1:0];

  // Generate address decoders for each master
  genvar i;
  generate
    for (i = 0; i < EXT_XBAR_NMASTER; i++) begin : gen_master_decoders
      addr_decode #(
        .NoRules(EXT_XBAR_NSLAVE),
        .NoIndices(EXT_XBAR_NSLAVE),
        .addr_t(logic [31:0]),
        .rule_t(addr_map_rule_t)
      ) i_addr_decode (
        .addr_i(ext_master_req_i[i].addr),
        .addr_map_i(addr_map_i),
        .idx_o(master_idx[i]),
        .dec_valid_o(),
        .dec_error_o(),
        .en_default_idx_i(1'b1),
        .default_idx_i(default_idx_i)
      );

      // Generate select signals
      for (genvar j = 0; j < EXT_XBAR_NSLAVE; j++) begin : gen_sel
        assign master_sel[i][j] = (master_idx[i] == j);
      end
    end
  endgenerate

  // Generate request/response routing for each slave
  genvar j;
  generate
    for (j = 0; j < EXT_XBAR_NSLAVE; j++) begin : gen_slave_ports
      // Combine requests from all masters
      always_comb begin
        ext_slave_req_o[j] = '0;
        for (int i = 0; i < EXT_XBAR_NMASTER; i++) begin
          if (master_sel[i][j]) begin
            ext_slave_req_o[j] = ext_master_req_i[i];
          end
        end
      end

      // Route responses back to masters
      always_comb begin
        for (int i = 0; i < EXT_XBAR_NMASTER; i++) begin
          ext_master_resp_o[i] = master_sel[i][j] ? ext_slave_resp_i[j] : '0;
        end
      end
    end
  endgenerate

  // Connect X-HEEP core interfaces
  assign heep_core_instr_resp_o = heep_core_instr_req_i.gnt ? heep_slave_resp_i[0] : '0;
  assign heep_core_data_resp_o = heep_core_data_req_i.gnt ? heep_slave_resp_i[0] : '0;
  assign heep_debug_master_resp_o = heep_debug_master_req_i.gnt ? heep_slave_resp_i[0] : '0;
  assign heep_dma_read_resp_o = heep_dma_read_req_i.gnt ? heep_slave_resp_i[0] : '0;
  assign heep_dma_write_resp_o = heep_dma_write_req_i.gnt ? heep_slave_resp_i[0] : '0;
  assign heep_dma_addr_resp_o = heep_dma_addr_req_i.gnt ? heep_slave_resp_i[0] : '0;

  // Connect X-HEEP slave requests
  assign heep_slave_req_o[0] = heep_core_instr_req_i;
  assign heep_slave_req_o[1] = heep_core_data_req_i;
  assign heep_slave_req_o[2] = heep_debug_master_req_i;
  assign heep_slave_req_o[3] = heep_dma_read_req_i;

`ifndef SYNTHESIS
  // show writes if requested
  always_ff @(posedge clk_i, negedge rst_ni) begin : verbose_writes
    if ($test$plusargs("verbose") != 0 && heep_core_data_req_i.req && heep_core_data_req_i.we)
      $display("write addr=0x%08x: data=0x%08x", heep_core_data_req_i.addr,
               heep_core_data_req_i.wdata);
  end
`endif

endmodule

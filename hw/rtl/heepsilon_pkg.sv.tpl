// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

package heepsilon_pkg;

  import addr_map_rule_pkg::*;
  import core_v_mini_mcu_pkg::*;

  // One master port per CGRA column
  localparam CGRA_XBAR_NMASTER = ${cgra_num_columns};
  // One slave port to the CGRA context memory
  localparam EXT_XBAR_NSLAVE = ${cgra_num_instances};

  localparam int unsigned LOG_EXT_XBAR_NMASTER = CGRA_XBAR_NMASTER > 1 ? $clog2(
      CGRA_XBAR_NMASTER
  ) : 32'd1;
  localparam int unsigned LOG_EXT_XBAR_NSLAVE = EXT_XBAR_NSLAVE > 1 ? $clog2(
      EXT_XBAR_NSLAVE
  ) : 32'd1;

  //slave mmap and idx
  localparam logic [31:0] CGRA_START_ADDRESS = core_v_mini_mcu_pkg::EXT_SLAVE_START_ADDRESS + 32'h000000;
  localparam logic [31:0] CGRA_SIZE = 32'h100000;
  localparam logic [31:0] CGRA_END_ADDRESS = CGRA_START_ADDRESS + (CGRA_SIZE * ${cgra_num_instances});
  
  // Generate address rules for each CGRA instance
  localparam addr_map_rule_t [EXT_XBAR_NSLAVE-1:0] EXT_XBAR_ADDR_RULES = '{
      '{idx: 32'd0, start_addr: CGRA_START_ADDRESS, end_addr: CGRA_START_ADDRESS + CGRA_SIZE},
      '{idx: 32'd1, start_addr: CGRA_START_ADDRESS + CGRA_SIZE, end_addr: CGRA_START_ADDRESS + (CGRA_SIZE * 2)},
      '{idx: 32'd2, start_addr: CGRA_START_ADDRESS + (CGRA_SIZE * 2), end_addr: CGRA_START_ADDRESS + (CGRA_SIZE * 3)},
      '{idx: 32'd3, start_addr: CGRA_START_ADDRESS + (CGRA_SIZE * 3), end_addr: CGRA_START_ADDRESS + (CGRA_SIZE * 4)}
  };

  //slave encoder
  localparam EXT_SYSTEM_NPERIPHERALS = ${cgra_num_instances};

  // Generate peripheral address rules for each CGRA instance
  localparam logic [31:0] CGRA_PERIPH_START_ADDRESS = core_v_mini_mcu_pkg::EXT_PERIPHERAL_START_ADDRESS + 32'h0000000;
  localparam logic [31:0] CGRA_PERIPH_SIZE = 32'h0001000;
  localparam logic [31:0] CGRA_PERIPH_END_ADDRESS = CGRA_PERIPH_START_ADDRESS + (CGRA_PERIPH_SIZE * ${cgra_num_instances});

  localparam addr_map_rule_t [EXT_SYSTEM_NPERIPHERALS-1:0] EXT_PERIPHERALS_ADDR_RULES = '{
      '{idx: 32'd0, start_addr: CGRA_PERIPH_START_ADDRESS, end_addr: CGRA_PERIPH_START_ADDRESS + CGRA_PERIPH_SIZE},
      '{idx: 32'd1, start_addr: CGRA_PERIPH_START_ADDRESS + CGRA_PERIPH_SIZE, end_addr: CGRA_PERIPH_START_ADDRESS + (CGRA_PERIPH_SIZE * 2)},
      '{idx: 32'd2, start_addr: CGRA_PERIPH_START_ADDRESS + (CGRA_PERIPH_SIZE * 2), end_addr: CGRA_PERIPH_START_ADDRESS + (CGRA_PERIPH_SIZE * 3)},
      '{idx: 32'd3, start_addr: CGRA_PERIPH_START_ADDRESS + (CGRA_PERIPH_SIZE * 3), end_addr: CGRA_PERIPH_START_ADDRESS + (CGRA_PERIPH_SIZE * 4)}
  };

  localparam int unsigned EXT_PERIPHERALS_PORT_SEL_WIDTH = EXT_SYSTEM_NPERIPHERALS > 1 ? $clog2(
      EXT_SYSTEM_NPERIPHERALS
  ) : 32'd1;

endpackage  // heepsilon_pkg

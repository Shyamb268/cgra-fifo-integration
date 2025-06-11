# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Compiler and flags
IVERILOG = iverilog
VVP = vvp
IVERILOG_FLAGS = -g2012 -Wall -I../rtl

# Source files
RTL_DIR = ../rtl
TB_DIR = .
SRC_FILES = \
    $(RTL_DIR)/cgra_top.sv \
    $(RTL_DIR)/data_bus_handler.sv \
    $(RTL_DIR)/fifo.sv \
    $(TB_DIR)/tb_cgra_fifo.sv \
    $(TB_DIR)/tb_cgra_fft.sv \
    $(TB_DIR)/tb_cgra_system.sv

# Add all relevant RTL files for missing modules
RTL_SRCS = \
  /home/manovega02/dataroot/shyamb/PASS/cgra-fifo-integration01/rtl/fifo.sv \
  ../rtl/cgra_top.sv \
  ../rtl/data_bus_handler.sv \
  ../rtl/alu.sv \
  ../rtl/cgra_controller.sv \
  ../rtl/synchronizer.sv \
  ../rtl/cgra_rcs.sv \
  ../rtl/context_memory_decoder.sv \
  ../rtl/cgra_pkg.sv \
  ../rtl/reg_pkg.sv

# Testbench targets
TB_FIFO = tb_cgra_fifo
TB_FFT = tb_cgra_fft
TB_SYSTEM = tb_cgra_system

# Default target
all: compile_fifo compile_fft compile_system

# Compile targets
compile_fifo:
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(TB_FIFO) $(SRC_FILES) -top $(TB_FIFO)

compile_fft:
	$(IVERILOG) $(IVERILOG_FLAGS) -o tb_cgra_fft \
		$(RTL_SRCS) \
		../sim/cgra_clock_gate.sv \
		tb_cgra_fft.sv

compile_system:
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(TB_SYSTEM) $(SRC_FILES) -top $(TB_SYSTEM)

# Run targets
run_fifo: compile_fifo
	$(VVP) $(TB_FIFO)

run_fft: compile_fft
	$(VVP) $(TB_FFT)

run_system: compile_system
	$(VVP) $(TB_SYSTEM)

# Clean target
clean:
	rm -rf $(TB_FIFO) $(TB_FFT) $(TB_SYSTEM)
	rm -rf *.log *.vpd *.fsdb *.key
	rm -rf simv* csrc* *.conf
	rm -rf *.vvp

.PHONY: all compile_fifo compile_fft compile_system run_fifo run_fft run_system clean 
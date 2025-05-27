# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Compiler and flags
VCS = vcs
VCS_FLAGS = -full64 -debug_all -sverilog -timescale=1ns/1ps
VERDI = verdi
VERDI_FLAGS = -sv -nologo

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

# Testbench targets
TB_FIFO = tb_cgra_fifo
TB_FFT = tb_cgra_fft
TB_SYSTEM = tb_cgra_system

# Default target
all: compile_fifo compile_fft compile_system

# Compile targets
compile_fifo:
	$(VCS) $(VCS_FLAGS) -o $(TB_FIFO) $(SRC_FILES) -top $(TB_FIFO)

compile_fft:
	$(VCS) $(VCS_FLAGS) -o $(TB_FFT) $(SRC_FILES) -top $(TB_FFT)

compile_system:
	$(VCS) $(VCS_FLAGS) -o $(TB_SYSTEM) $(SRC_FILES) -top $(TB_SYSTEM)

# Run targets
run_fifo: compile_fifo
	./$(TB_FIFO)

run_fft: compile_fft
	./$(TB_FFT)

run_system: compile_system
	./$(TB_SYSTEM)

# Debug targets
debug_fifo: compile_fifo
	$(VERDI) $(VERDI_FLAGS) -ssf $(TB_FIFO).fsdb &

debug_fft: compile_fft
	$(VERDI) $(VERDI_FLAGS) -ssf $(TB_FFT).fsdb &

debug_system: compile_system
	$(VERDI) $(VERDI_FLAGS) -ssf $(TB_SYSTEM).fsdb &

# Clean target
clean:
	rm -rf $(TB_FIFO) $(TB_FFT) $(TB_SYSTEM)
	rm -rf *.log *.vpd *.fsdb *.key
	rm -rf simv* csrc* *.conf

.PHONY: all compile_fifo compile_fft compile_system run_fifo run_fft run_system debug_fifo debug_fft debug_system clean 
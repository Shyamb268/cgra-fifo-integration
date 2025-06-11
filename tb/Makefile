# Testbench Makefile

# Compiler and simulator
IVERILOG = iverilog
VVP = vvp
IVERILOG_FLAGS = -g2012 -Wall -I../rtl
VVP_FLAGS = -n

# Source files
SRC_DIR = ../rtl
TB_DIR = .
SRC_FILES = $(SRC_DIR)/fifo.sv \
            $(SRC_DIR)/cgra_fifo.sv \
            $(SRC_DIR)/cgra.sv \
            tb_cgra_fft.sv \
            $(SRC_DIR)/cgra_fifo_wrapper.sv
TB_FILES = $(TB_DIR)/tb_util.svh \
           $(TB_DIR)/tb_fifo.sv \
           $(TB_DIR)/tb_cgra_fifo.sv

# Test executables
TB_FIFO_EXE = tb_fifo.vvp
TB_CGRA_FIFO_EXE = tb_cgra_fifo.vvp
TEST_EXE = tb_cgra_fft.vvp

# Default target
all: $(TB_FIFO_EXE) $(TB_CGRA_FIFO_EXE) $(TEST_EXE)

# Clean build artifacts
clean:
	rm -f *.vvp *.vcd $(TEST_EXE) *.log *.vpd *.key

# Compile FIFO testbench
$(TB_FIFO_EXE): $(SRC_FILES) $(TB_FILES)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(SRC_DIR)/fifo.sv $(TB_DIR)/tb_fifo.sv

# Compile CGRA-FIFO testbench
$(TB_CGRA_FIFO_EXE): $(SRC_FILES) $(TB_FILES)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(SRC_DIR)/fifo.sv $(SRC_DIR)/cgra.sv $(SRC_DIR)/cgra_fifo.sv $(TB_DIR)/tb_cgra_fifo.sv

# Compile CGRA FFT testbench
$(TEST_EXE): tb_cgra_fft.sv ../rtl/cgra_fifo_wrapper.sv ../rtl/fifo.sv ../rtl/cgra.sv
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ tb_cgra_fft.sv ../rtl/cgra_fifo_wrapper.sv ../rtl/fifo.sv ../rtl/cgra.sv

# Run FIFO tests
test_fifo: $(TB_FIFO_EXE)
	$(VVP) $(TB_FIFO_EXE)

# Run CGRA-FIFO tests
test_cgra_fifo: $(TB_CGRA_FIFO_EXE)
	$(VVP) $(TB_CGRA_FIFO_EXE)

# Run CGRA FFT test
test_cgra_fft: $(TEST_EXE)
	$(VVP) $(TEST_EXE)

# Run all tests
test: test_fifo test_cgra_fifo test_cgra_fft

.PHONY: all clean test test_fifo test_cgra_fifo test_cgra_fft 
# RTL Makefile

# Compiler and flags
IVERILOG = iverilog
IVERILOG_FLAGS = -g2012 -Wall

# Source files
RTL_SRCS = \
    ../../rtl/fifo.sv \
    ../../rtl/fifo_if.sv \
    ../../rtl/fifo.pkg \
    cgra_fifo_wrapper.sv \
    heepsilon_top.sv

# Default target
all: compile

# Clean build artifacts
clean:
	rm -f *.o
	rm -f *.vcd
	rm -f *.log
	rm -f a.out

# Compile RTL
compile:
	$(IVERILOG) $(IVERILOG_FLAGS) $(RTL_SRCS)

.PHONY: all clean compile 
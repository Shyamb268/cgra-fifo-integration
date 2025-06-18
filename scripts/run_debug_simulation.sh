#!/bin/bash

# CGRA FIFO Debug Simulation Script
# This script compiles and runs the testbench with comprehensive debugging

set -e  # Exit on any error

echo "=== CGRA FIFO Debug Simulation ==="
echo "Starting at: $(date)"
echo

# Set up environment
export SIM_DIR="$(pwd)/sim"
export TB_DIR="$(pwd)/tb"
export RTL_DIR="$(pwd)/rtl"
export LOG_DIR="$(pwd)/tb/logs"

# Create directories if they don't exist
mkdir -p $SIM_DIR
mkdir -p $LOG_DIR

# Clean previous simulation files
echo "Cleaning previous simulation files..."
rm -f $SIM_DIR/*.vcd
rm -f $SIM_DIR/*.log
rm -f $LOG_DIR/*.log

# Compile the design
echo "Compiling design..."
cd $SIM_DIR

# Compile order is important
iverilog -g2012 -I$RTL_DIR \
    $RTL_DIR/fifo.sv \
    $RTL_DIR/cgra.sv \
    $RTL_DIR/cgra_fifo_wrapper.sv \
    $TB_DIR/cgra_fifo_tb.sv \
    -o cgra_fifo_sim

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"

# Run simulation with verbose output
echo "Running simulation..."
./cgra_fifo_sim > $LOG_DIR/simulation.log 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed!"
    echo "Check log file: $LOG_DIR/simulation.log"
    exit 1
fi

echo "Simulation completed successfully!"

# Check for waveform file
if [ -f "cgra_fifo_debug.vcd" ]; then
    echo "Waveform file generated: cgra_fifo_debug.vcd"
    echo "You can view it with: gtkwave cgra_fifo_debug.vcd"
else
    echo "WARNING: No waveform file generated!"
fi

# Display key simulation results
echo
echo "=== Simulation Summary ==="
echo "Log file: $LOG_DIR/simulation.log"
echo "Waveform: $SIM_DIR/cgra_fifo_debug.vcd"

# Check for X signals in the log
echo
echo "=== Checking for X Signals ==="
if grep -q "WARNING.*is X" $LOG_DIR/simulation.log; then
    echo "WARNING: Found X signals in simulation!"
    grep "WARNING.*is X" $LOG_DIR/simulation.log
else
    echo "Good news: No X signals detected!"
fi

# Check for successful completion
if grep -q "Test completed" $LOG_DIR/simulation.log; then
    echo "✓ Test completed successfully"
else
    echo "✗ Test did not complete properly"
fi

echo
echo "=== Debug Information ==="
echo "To view waveforms:"
echo "  cd $SIM_DIR"
echo "  gtkwave cgra_fifo_debug.vcd"
echo
echo "To view detailed logs:"
echo "  less $LOG_DIR/simulation.log"
echo
echo "Simulation finished at: $(date)" 
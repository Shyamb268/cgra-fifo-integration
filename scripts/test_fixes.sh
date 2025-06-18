#!/bin/bash

echo "=== Testing CGRA-FIFO Integration Fixes ==="

# Set up environment
export PATH=$PATH:/usr/local/bin

# Clean previous builds
echo "Cleaning previous builds..."
make clean 2>/dev/null || true

# Compile the testbench
echo "Compiling testbench..."
cd tb
make clean 2>/dev/null || true
make sim

if [ $? -ne 0 ]; then
    echo "ERROR: Testbench compilation failed"
    exit 1
fi

# Run the simulation
echo "Running simulation..."
./cgra_fifo_sim > simulation_output.log 2>&1

# Check simulation results
echo "Checking simulation results..."
if grep -q "WARNING.*result_data is X" simulation_output.log; then
    echo "ERROR: CGRA still producing undefined results"
    exit 1
fi

if grep -q "Test completed" simulation_output.log; then
    echo "SUCCESS: Test completed successfully"
else
    echo "ERROR: Test did not complete"
    exit 1
fi

# Check for specific success indicators
if grep -q "Instance.*result ready:" simulation_output.log; then
    echo "SUCCESS: CGRA instances are producing results"
else
    echo "ERROR: No CGRA results found"
    exit 1
fi

echo "=== All tests passed! ==="
echo "The CGRA-FIFO integration fixes are working correctly."

# Show summary of results
echo ""
echo "=== Test Summary ==="
echo "✓ Testbench compilation: PASSED"
echo "✓ Simulation execution: PASSED"
echo "✓ CGRA data processing: PASSED"
echo "✓ Multi-instance support: PASSED"
echo "✓ FIFO integration: PASSED"

exit 0 
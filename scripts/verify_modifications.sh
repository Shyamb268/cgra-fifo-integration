#!/bin/bash

echo "Starting verification of FIFO and CGRA modifications..."

# 1. Compile RTL
echo "Step 1: Compiling RTL..."
make -C hw/rtl clean
make -C hw/rtl all
if [ $? -ne 0 ]; then
    echo "❌ RTL compilation failed"
    exit 1
fi
echo "✅ RTL compilation successful"

# 2. Run RTL simulation
echo "Step 2: Running RTL simulation..."
make -C tb clean
make -C tb sim
if [ $? -ne 0 ]; then
    echo "❌ RTL simulation failed"
    exit 1
fi
echo "✅ RTL simulation successful"

# 3. Compile software
echo "Step 3: Compiling software..."
make -C sw clean
make -C sw all
if [ $? -ne 0 ]; then
    echo "❌ Software compilation failed"
    exit 1
fi
echo "✅ Software compilation successful"

# 4. Run test applications
echo "Step 4: Running test applications..."

# Run multi-instance test
echo "Running multi-instance test..."
./sw/build/multi_cgra_test
if [ $? -ne 0 ]; then
    echo "❌ Multi-instance test failed"
    exit 1
fi
echo "✅ Multi-instance test successful"

# Run FFT test
echo "Running FFT test..."
./sw/build/fft_fifo_test
if [ $? -ne 0 ]; then
    echo "❌ FFT test failed"
    exit 1
fi
echo "✅ FFT test successful"

# 5. Run regression tests
echo "Step 5: Running regression tests..."
make -C tb regression
if [ $? -ne 0 ]; then
    echo "❌ Regression tests failed"
    exit 1
fi
echo "✅ Regression tests successful"

echo "All verifications completed successfully! ✅" 
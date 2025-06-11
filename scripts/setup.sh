#!/bin/bash

echo "Checking and installing required tools..."

# Check for Icarus Verilog
if ! command -v iverilog &> /dev/null; then
    echo "Installing Icarus Verilog..."
    sudo apt-get update
    sudo apt-get install -y iverilog
fi

# Check for GCC
if ! command -v gcc &> /dev/null; then
    echo "Installing GCC..."
    sudo apt-get update
    sudo apt-get install -y gcc
fi

# Check for Make
if ! command -v make &> /dev/null; then
    echo "Installing Make..."
    sudo apt-get update
    sudo apt-get install -y make
fi

# Make scripts executable
chmod +x scripts/verify_modifications.sh

echo "Setup completed!" 
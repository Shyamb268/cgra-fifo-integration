#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo "Checking for required tools..."

# Check for iverilog
if ! command_exists iverilog; then
    echo "Icarus Verilog (iverilog) not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y iverilog
else
    echo "Icarus Verilog (iverilog) is already installed."
fi

# Check for vvp
if ! command_exists vvp; then
    echo "Icarus Verilog VVP not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y iverilog
else
    echo "Icarus Verilog VVP is already installed."
fi

# Check for make
if ! command_exists make; then
    echo "Make not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y make
else
    echo "Make is already installed."
fi

echo "Setup complete. You can now run 'make' to execute the tests." 
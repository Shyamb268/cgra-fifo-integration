# CGRA with FIFO-based Data Path

This module implements a Coarse-Grained Reconfigurable Array (CGRA) with a FIFO-based data path for streaming applications. The design enables software-driven data streaming to the CGRA through a FIFO interface, making it suitable for real-time signal processing applications like FFT.

## Architecture

### Hardware Components

1. **CGRA Top Module (`cgra_top.sv`)**
   - Main CGRA controller and interface
   - FIFO interface signals for data streaming
   - Configuration and control registers

2. **Data Bus Handler (`data_bus_handler.sv`)**
   - Manages data flow between FIFO and CGRA
   - Handles read/write operations
   - Implements ready/valid handshake protocol

3. **FIFO Interface**
   - Input FIFO for streaming data
   - Output FIFO for results
   - Status registers for monitoring FIFO state

### Software Components

1. **FIFO Driver (`cgra_fifo.h`, `cgra_fifo.c`)**
   - Functions for FIFO operations:
     - `cgra_fifo_write()`: Write data to FIFO
     - `cgra_fifo_ready()`: Check FIFO status
     - `cgra_fifo_wait_ready()`: Wait for FIFO ready

2. **Example Application (`cgra_fft`)**
   - Demonstrates FFT computation using FIFO interface
   - Includes test signal generation
   - Verifies FFT results

## Register Map

### FIFO Interface Registers

| Register Name | Address | Access | Description |
|--------------|---------|---------|-------------|
| FIFO_DATA    | 0x00    | RW      | Write input data to FIFO |
| FIFO_STATUS  | 0x04    | RO      | FIFO status (full, empty, etc.) |

## Usage

### Building and Running the FFT Example

1. Build the application:
```bash
cd sw/applications/cgra_fft
make
```

2. Run the application:
```bash
./cgra_fft
```

### Using the FIFO Interface in Software

```c
#include "cgra_fifo.h"

// Write data to FIFO
int data = 0x1234;
if (cgra_fifo_write(data) != 0) {
    // Handle error
}

// Wait for FIFO to be ready
cgra_fifo_wait_ready();
```

## Verification

### Testbenches

1. **FIFO Testbench (`tb_cgra_fifo.sv`)**
   - Tests basic FIFO functionality
   - Verifies read/write operations
   - Checks handshake protocol

2. **FFT Testbench (`tb_cgra_fft.sv`)**
   - Tests FFT computation
   - Verifies output for different input signals
   - Checks timing and handshake

3. **System Testbench (`tb_cgra_system.sv`)**
   - End-to-end system verification
   - Tests FIFO, FFT, and error handling
   - Verifies system integration

### Running Tests

1. Compile testbenches:
```bash
cd hw/vendor/esl_epfl_cgra/hw/tb
make all
```

2. Run specific tests:
```bash
make run_fifo    # Run FIFO tests
make run_fft     # Run FFT tests
make run_system  # Run system tests
```

3. Debug with waveforms:
```bash
make debug_fifo    # Debug FIFO tests
make debug_fft     # Debug FFT tests
make debug_system  # Debug system tests
```

## Performance Considerations

1. **FIFO Depth**
   - Default depth: 256 entries
   - Configurable through parameters
   - Consider application requirements

2. **Data Width**
   - Default: 32 bits
   - Supports fixed-point arithmetic
   - Q8.8 format for FFT

3. **Timing**
   - Clock frequency: 100MHz (default)
   - FIFO handshake latency: 1 cycle
   - FFT computation: O(N log N) cycles

## Error Handling

1. **FIFO Overflow**
   - Detected by FIFO_STATUS register
   - Software should check status before writing
   - Error flag raised on overflow

2. **Invalid Operations**
   - Write to full FIFO
   - Read from empty FIFO
   - Invalid configuration

## Future Improvements

1. **Features**
   - Configurable FIFO depth
   - Multiple input/output FIFOs
   - Direct memory access (DMA) support

2. **Performance**
   - Pipelined FFT computation
   - Parallel processing support
   - Optimized memory access

## Contributing

1. Follow the coding style guidelines
2. Add tests for new features
3. Update documentation
4. Submit pull requests

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details. 
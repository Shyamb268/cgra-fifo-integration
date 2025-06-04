# CGRA FIFO Architecture

## Overview
This document describes the architecture of the FIFO-based CGRA accelerator and multi-instance support.

## Hardware Architecture

### FIFO Implementation
- Parameterized data width and depth
- SystemVerilog interfaces and modports
- Status monitoring and control signals
- Handshaking protocol

### CGRA Integration
- FIFO wrapper for data path control
- CGRA enable/disable logic
- Handshaking signal management
- Resource arbitration

### Multi-Instance Support
- Instance selection and routing
- Individual instance control
- Resource management
- Interconnect configuration

## Software Architecture

### Driver Layer
- FIFO control functions
- CGRA instance management
- Status monitoring
- Error handling

### Application Layer
- Example applications
- Performance monitoring
- Result verification
- Multi-instance coordination

## Verification
- Testbenches for FIFO functionality
- CGRA-FIFO integration tests
- Multi-instance operation verification
- Performance benchmarking

# CGRA FIFO Integration and Multi-Instance Support

## Overview
This document describes the integration of a FIFO-based data path with the CGRA accelerator and the support for multiple CGRA instances. The implementation includes both hardware and software components.

## Hardware Architecture

### FIFO Implementation
- **FIFO Module**: A synthesizable FIFO implementation using SystemVerilog best practices
  - Parameterized data width and depth
  - Proper interface definitions with modports
  - Status monitoring and control signals

### CGRA Integration
- **FIFO Wrapper**: Integrates FIFO with CGRA
  - Handles data path control
  - Manages CGRA enable/disable logic
  - Provides proper handshaking signals

### Multi-Instance Support
- **CGRA Top Wrapper**: Supports multiple CGRA instances
  - Instance selection and data routing
  - Individual instance control
  - Resource management

## Software Architecture

### Driver Layer
- **FIFO Control**: Functions for FIFO operations
  - Initialization and reset
  - Data read/write
  - Status monitoring
- **CGRA Control**: Functions for CGRA instance management
  - Instance initialization
  - Start/stop control
  - Status monitoring

### Application Layer
- **FFT Example**: Demonstrates FIFO-based data path
  - Input data streaming
  - Parallel processing
  - Result verification

## Register Map

### FIFO Registers
- `CGRA_FIFO_CTRL_REG` (0x10000000): FIFO control
- `CGRA_FIFO_STATUS_REG` (0x10000004): FIFO status
- `CGRA_FIFO_DATA_REG` (0x10000008): FIFO data
- `CGRA_FIFO_DEPTH_REG` (0x1000000C): FIFO depth

### CGRA Instance Registers
- `CGRA_INST_CTRL_REG` (0x10000010): Instance control
- `CGRA_INST_STATUS_REG` (0x10000014): Instance status
- `CGRA_INST_SEL_REG` (0x10000018): Instance selection

## API Reference

### FIFO Functions

#### Initialization
```c
void cgra_fifo_init(void);
void cgra_fifo_reset(void);
```

#### Data Operations
```c
bool cgra_fifo_write(uint32_t data);
bool cgra_fifo_read(uint32_t *data);
```

#### Status Monitoring
```c
bool cgra_fifo_is_full(void);
bool cgra_fifo_is_empty(void);
uint32_t cgra_fifo_get_depth(void);
uint32_t cgra_fifo_get_count(void);
```

### Multi-Instance CGRA Functions

#### Instance Management
```c
void cgra_inst_init(uint8_t inst_id);
void cgra_inst_enable(uint8_t inst_id);
void cgra_inst_disable(uint8_t inst_id);
void cgra_inst_reset(uint8_t inst_id);
```

#### Control Operations
```c
void cgra_inst_start(uint8_t inst_id);
bool cgra_inst_is_done(uint8_t inst_id);
void cgra_inst_select(uint8_t inst_id);
uint8_t cgra_inst_get_active(void);
```

## Performance Considerations

### FIFO Sizing
- Default FIFO depth: 16 entries
- Configurable based on application needs
- Consider latency and throughput requirements

### Multi-Instance Usage
- Parallel processing for independent tasks
- Sequential processing for dependent tasks
- Resource sharing and arbitration

## Verification

### Testbenches
- FIFO functionality verification
- CGRA-FIFO integration testing
- Multi-instance operation testing

### FFT Application
- Demonstrates correct operation
- Shows performance improvements
- Includes result verification

## Future Improvements
1. Dynamic FIFO depth configuration
2. Advanced instance scheduling
3. Power management features
4. Additional application examples 

# Getting Started with CGRA FIFO Integration

## Overview
This guide provides instructions for getting started with the FIFO-based CGRA accelerator and multi-instance support.

## Prerequisites
- HEEPsilon development environment
- CGRA accelerator hardware
- Required software tools

## Installation
1. Clone the repository:
```bash
git clone https://bitbucket.org/shyambandi/cgra-fifo-integration01.git
cd cgra-fifo-integration01
```

2. Build the project:
```bash
make all
```

## Basic Usage
1. Initialize the CGRA with FIFO:
```c
cgra_t cgra;
cgra.base_addr = mmio_region_from_addr((uintptr_t)CGRA_PERIPH_START_ADDRESS);
cgra_wait_ready(&cgra);
```

2. Write data to FIFO:
```c
cgra_fifo_wait_ready(&cgra);
cgra_fifo_write(&cgra, data);
```

3. Configure and start CGRA:
```c
cgra_set_kernel(&cgra, kernel_id);
```

## Example Applications
- FFT application with FIFO
- Matrix multiplication
- Vector operations 

# Porting Applications to FIFO-based CGRA

## Overview
This guide explains how to port applications to use the FIFO-based data path and multi-instance CGRA support.

## Porting Steps

### 1. FIFO Integration
1. Initialize FIFO:
```c
cgra_fifo_init();
```

2. Replace direct memory access with FIFO operations:
```c
// Old code
write_memory(address, data);

// New code
cgra_fifo_wait_ready(&cgra);
cgra_fifo_write(&cgra, data);
```

### 2. Multi-Instance Support
1. Initialize multiple instances:
```c
for (int i = 0; i < NUM_INSTANCES; i++) {
    cgra_inst_init(i);
}
```

2. Configure instances:
```c
cgra_configure_instance(&driver, instance_id, kernel_id);
```

3. Start and manage instances:
```c
cgra_start_instance(&driver, instance_id);
cgra_wait_instance(&driver, instance_id);
```

## Example: FFT Application
```c
// Initialize FIFO and CGRA
cgra_fifo_init();
cgra_inst_init(0);

// Write input data
for (int i = 0; i < FFT_SIZE; i++) {
    cgra_fifo_wait_ready(&cgra);
    cgra_fifo_write(&cgra, input_data[i]);
}

// Start processing
cgra_inst_start(0);
cgra_wait_instance(&driver, 0);
```

## Performance Considerations
1. FIFO Sizing
   - Default depth: 16 entries
   - Adjust based on application needs
   - Consider latency requirements

2. Multi-Instance Usage
   - Parallel processing for independent tasks
   - Sequential processing for dependent tasks
   - Resource sharing and arbitration

## Best Practices
1. Always check FIFO status before writing
2. Use appropriate instance selection
3. Handle errors and timeouts
4. Monitor performance metrics 
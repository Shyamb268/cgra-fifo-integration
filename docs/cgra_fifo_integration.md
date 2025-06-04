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
```c
void cgra_fifo_init(void);
void cgra_fifo_reset(void);
bool cgra_fifo_write(uint32_t data);
bool cgra_fifo_read(uint32_t *data);
bool cgra_fifo_is_full(void);
bool cgra_fifo_is_empty(void);
uint32_t cgra_fifo_get_depth(void);
uint32_t cgra_fifo_get_count(void);
```

### CGRA Instance Functions
```c
void cgra_inst_init(uint8_t inst_id);
void cgra_inst_enable(uint8_t inst_id);
void cgra_inst_disable(uint8_t inst_id);
void cgra_inst_reset(uint8_t inst_id);
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
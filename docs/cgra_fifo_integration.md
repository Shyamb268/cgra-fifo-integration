# CGRA FIFO Integration Guide

## Overview
This guide explains the integration of a FIFO-based data path with the CGRA accelerator, including multi-instance support and example applications.

## Architecture

### FIFO Interface
- Data width: 32 bits
- Address width: 4 bits (16 entries)
- Supports multiple instances
- Handshake protocol with ready/valid signals

### CGRA Integration
- Direct connection between FIFO and CGRA
- Multi-instance support (up to 4 instances)
- Instance-specific configuration
- Synchronized start/stop control

## Software API

### Initialization
```c
int cgra_fifo_init(void);
```
Initializes the FIFO and CGRA instances.

### Configuration
```c
int cgra_fifo_configure(const cgra_fifo_config_t *config);
```
Configures a CGRA instance with specific parameters.

### Data Transfer
```c
int cgra_fifo_write(uint32_t data);
int cgra_fifo_read(uint32_t *data);
```
Write/read data to/from the FIFO.

### Control
```c
int cgra_fifo_start_instance(uint8_t instance_id);
int cgra_fifo_wait_instance(uint8_t instance_id);
```
Start and wait for CGRA instances.

## Example: FFT Application

### Setup
1. Initialize FIFO and CGRA:
```c
cgra_fifo_init();
```

2. Configure instances:
```c
cgra_fifo_config_t config = {
    .instance_id = 0,
    .kernel_id = 0,
    .base_addr = 0x1000
};
cgra_fifo_configure(&config);
```

3. Write input data:
```c
for (int i = 0; i < FFT_SIZE; i++) {
    cgra_fifo_wait_ready();
    cgra_fifo_write(input_data[i]);
}
```

4. Start processing:
```c
cgra_fifo_start_instance(0);
cgra_fifo_wait_instance(0);
```

### Performance Considerations
1. FIFO Sizing
   - Default depth: 16 entries
   - Adjust based on application needs
   - Consider latency requirements

2. Multi-Instance Usage
   - Parallel processing for independent tasks
   - Sequential processing for dependent tasks
   - Resource sharing and arbitration

## Verification
The design includes comprehensive testbenches:
- FIFO basic functionality
- CGRA integration
- Multi-instance operation
- Performance monitoring

## Best Practices
1. Always check FIFO status before writing
2. Use appropriate instance selection
3. Handle errors and timeouts
4. Monitor performance metrics
5. Consider FIFO depth for your application
6. Use multi-instance support for parallel processing

## Troubleshooting
1. FIFO Full/Empty
   - Check FIFO status
   - Adjust timing if needed
   - Consider increasing FIFO depth

2. CGRA Instance Issues
   - Verify instance configuration
   - Check start/stop timing
   - Monitor instance status

3. Performance Issues
   - Profile application
   - Adjust FIFO parameters
   - Optimize instance usage
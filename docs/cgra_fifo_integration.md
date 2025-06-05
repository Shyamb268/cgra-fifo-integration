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
# FIFO and Multi-Instance CGRA Integration

## Overview
This project implements a FIFO-based data path for the CGRA accelerator and supports multiple CGRA instances. The implementation includes RTL modifications, software drivers, and test applications.

## Components

### RTL Components
- `rtl/fifo.sv`: Synthesizable FIFO implementation
- `rtl/fifo_if.sv`: FIFO interface definition
- `rtl/fifo.pkg`: FIFO package with typedefs
- `hw/rtl/cgra_fifo_wrapper.sv`: CGRA FIFO wrapper
- `hw/rtl/heepsilon_top.sv`: Modified HEEpsilon top-level

### Software Components
- `sw/drivers/cgra_fifo_driver.h`: Driver interface
- `sw/drivers/cgra_fifo_driver.c`: Driver implementation
- `sw/apps/multi_cgra_test.c`: Test application
- `sw/apps/fft_fifo_test.c`: FFT application

### Verification
- `tb/cgra_fifo_tb.sv`: Testbench for FIFO and CGRA integration

## Usage

### Driver API
```c
// Initialize driver
int cgra_fifo_init(cgra_fifo_driver_t* driver, uint32_t base_addr, uint32_t num_instances);

// Write data to FIFO
int cgra_fifo_write(cgra_fifo_driver_t* driver, uint32_t data);

// Start CGRA instance
int cgra_start_instance(cgra_fifo_driver_t* driver, uint32_t instance_id);

// Check CGRA instance status
int cgra_is_done(cgra_fifo_driver_t* driver, uint32_t instance_id);

// Read data from CGRA instance
int cgra_read_data(cgra_fifo_driver_t* driver, uint32_t instance_id, uint32_t* data);
```

### Configuration
The number of CGRA instances can be configured in:
- `hw/rtl/heepsilon_top.sv`: NUM_CGRA_INSTANCES parameter
- `hw/rtl/cgra_fifo_wrapper.sv`: NUM_INSTANCES parameter

## Testing
1. Run the testbench:
```bash
make sim
```

2. Run the test application:
```bash
make test
```

3. Run the FFT application:
```bash
make fft_test
```

## Performance
The implementation supports:
- Parallel processing using multiple CGRA instances
- Efficient data transfer through FIFO
- Configurable FIFO depth and data width

## Future Improvements
- Add support for dynamic instance configuration
- Implement error handling and recovery
- Add performance monitoring capabilities 
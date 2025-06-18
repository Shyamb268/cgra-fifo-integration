#ifndef CGRA_FIFO_DRIVER_H
#define CGRA_FIFO_DRIVER_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Maximum number of CGRA instances supported
#define MAX_INSTANCES 4

// CGRA FIFO configuration structure
typedef struct {
    uint8_t instance_id;
    uint32_t kernel_id;
    uint32_t base_addr;
} cgra_fifo_config_t;

// CGRA FIFO driver structure
typedef struct {
    volatile uint32_t* base_addr;  // Base address of the CGRA FIFO
    uint32_t num_instances;        // Number of CGRA instances
} cgra_fifo_driver_t;

// Initialize the CGRA FIFO driver
int cgra_fifo_init(cgra_fifo_driver_t* driver, uint32_t base_addr, uint32_t num_instances);

// Configure a CGRA instance
int cgra_fifo_configure(const cgra_fifo_config_t* config);

// Write data to the FIFO
int cgra_fifo_write(cgra_fifo_driver_t* driver, uint32_t data);

// Wait for FIFO to be ready (not full)
int cgra_fifo_wait_ready(void);

// Start a specific CGRA instance
int cgra_start_instance(cgra_fifo_driver_t* driver, uint32_t instance_id);

// Wait for a specific CGRA instance to complete
int cgra_fifo_wait_instance(uint8_t instance_id);

// Check if a specific CGRA instance is done
int cgra_is_done(cgra_fifo_driver_t* driver, uint32_t instance_id);

// Read data from a specific CGRA instance
int cgra_read_data(cgra_fifo_driver_t* driver, uint32_t instance_id, uint32_t* data);

// Reset FIFO and all CGRA instances
int cgra_fifo_reset(void);

#endif // CGRA_FIFO_DRIVER_H 
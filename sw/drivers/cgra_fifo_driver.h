#ifndef CGRA_FIFO_DRIVER_H
#define CGRA_FIFO_DRIVER_H

#include <stdint.h>
#include "cgra_driver.h"

// FIFO configuration
#define FIFO_DEPTH 16
#define MAX_INSTANCES 4

// FIFO status
typedef struct {
    uint32_t write_count;
    uint32_t read_count;
    uint32_t current_level;
    uint8_t  is_full;
    uint8_t  is_empty;
} cgra_fifo_status_t;

// FIFO instance configuration
typedef struct {
    uint8_t instance_id;
    uint8_t kernel_id;
    uint32_t base_addr;
} cgra_fifo_config_t;

// Initialize FIFO and CGRA instances
int cgra_fifo_init(void);

// Configure FIFO instance
int cgra_fifo_configure(const cgra_fifo_config_t *config);

// Write data to FIFO
int cgra_fifo_write(uint32_t data);

// Read data from FIFO
int cgra_fifo_read(uint32_t *data);

// Get FIFO status
int cgra_fifo_get_status(cgra_fifo_status_t *status);

// Start CGRA instance
int cgra_fifo_start_instance(uint8_t instance_id);

// Wait for CGRA instance to complete
int cgra_fifo_wait_instance(uint8_t instance_id);

// Check if FIFO is ready for write
int cgra_fifo_wait_ready(void);

// Reset FIFO and CGRA instances
int cgra_fifo_reset(void);

#endif // CGRA_FIFO_DRIVER_H 
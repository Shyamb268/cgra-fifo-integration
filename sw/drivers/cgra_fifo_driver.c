#include "cgra_fifo_driver.h"
#include "cgra_regs.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Static variables
static uint32_t fifo_base_addr;
static cgra_fifo_config_t instance_configs[MAX_INSTANCES];
static uint8_t num_instances = 0;

// Register offsets
#define FIFO_DATA_REG    0x00
#define FIFO_STATUS_REG  0x04
#define FIFO_CTRL_REG    0x08
#define CGRA_CTRL_REG    0x0C
#define CGRA_STATUS_REG  0x10

int cgra_fifo_init(void) {
    // Initialize CGRA driver
    if (cgra_init() != 0) {
        return -1;
    }
    
    // Get FIFO base address from CGRA driver
    fifo_base_addr = cgra_get_base_addr() + CGRA_FIFO_OFFSET;
    
    // Reset FIFO
    return cgra_fifo_reset();
}

int cgra_fifo_configure(const cgra_fifo_config_t *config) {
    if (config == NULL || config->instance_id >= MAX_INSTANCES) {
        return -1;
    }
    
    // Store configuration
    memcpy(&instance_configs[config->instance_id], config, sizeof(cgra_fifo_config_t));
    
    // Configure CGRA instance
    cgra_config_t cgra_config = {
        .kernel_id = config->kernel_id,
        .base_addr = config->base_addr
    };
    
    if (cgra_configure(config->instance_id, &cgra_config) != 0) {
        return -1;
    }
    
    if (config->instance_id >= num_instances) {
        num_instances = config->instance_id + 1;
    }
    
    return 0;
}

int cgra_fifo_write(uint32_t data) {
    // Wait for FIFO to be ready
    if (cgra_fifo_wait_ready() != 0) {
        return -1;
    }
    
    // Write data to FIFO
    cgra_write_reg(fifo_base_addr + FIFO_DATA_REG, data);
    
    return 0;
}

int cgra_fifo_read(uint32_t *data) {
    if (data == NULL) {
        return -1;
    }
    
    // Check if FIFO is empty
    uint32_t status = cgra_read_reg(fifo_base_addr + FIFO_STATUS_REG);
    if (status & (1 << 0)) { // Empty bit
        return -1;
    }
    
    // Read data from FIFO
    *data = cgra_read_reg(fifo_base_addr + FIFO_DATA_REG);
    
    return 0;
}

int cgra_fifo_get_status(cgra_fifo_status_t *status) {
    if (status == NULL) {
        return -1;
    }
    
    uint32_t reg_status = cgra_read_reg(fifo_base_addr + FIFO_STATUS_REG);
    
    status->write_count = (reg_status >> 16) & 0xFFFF;
    status->read_count = (reg_status >> 8) & 0xFF;
    status->current_level = (reg_status >> 4) & 0xF;
    status->is_full = (reg_status >> 1) & 0x1;
    status->is_empty = reg_status & 0x1;
    
    return 0;
}

int cgra_fifo_start_instance(uint8_t instance_id) {
    if (instance_id >= num_instances) {
        return -1;
    }
    
    // Start CGRA instance
    return cgra_start(instance_id);
}

int cgra_fifo_wait_instance(uint8_t instance_id) {
    if (instance_id >= num_instances) {
        return -1;
    }
    
    // Wait for CGRA instance to complete
    return cgra_wait(instance_id);
}

int cgra_fifo_wait_ready(void) {
    uint32_t timeout = 1000; // Adjust timeout as needed
    
    while (timeout--) {
        uint32_t status = cgra_read_reg(fifo_base_addr + FIFO_STATUS_REG);
        if (!(status & (1 << 1))) { // Not full
            return 0;
        }
    }
    
    return -1; // Timeout
}

int cgra_fifo_reset(void) {
    // Reset FIFO
    cgra_write_reg(fifo_base_addr + FIFO_CTRL_REG, 1);
    
    // Reset all CGRA instances
    for (uint8_t i = 0; i < num_instances; i++) {
        cgra_reset(i);
    }
    
    num_instances = 0;
    
    return 0;
} 
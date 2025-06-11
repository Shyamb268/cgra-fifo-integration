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
#define REG_FIFO_DATA    0x00
#define REG_FIFO_STATUS  0x04
#define REG_CGRA_CTRL    0x08
#define REG_CGRA_STATUS  0x0C

// Status register bits
#define STATUS_FIFO_FULL   (1 << 0)
#define STATUS_FIFO_EMPTY  (1 << 1)
#define STATUS_CGRA_DONE   (1 << 2)

int cgra_fifo_init(cgra_fifo_driver_t* driver, uint32_t base_addr, uint32_t num_instances) {
    if (!driver || num_instances == 0) {
        return -1;
    }
    
    driver->base_addr = (volatile uint32_t*)base_addr;
    driver->num_instances = num_instances;
    return 0;
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

int cgra_fifo_write(cgra_fifo_driver_t* driver, uint32_t data) {
    if (!driver) {
        return -1;
    }
    
    // Check if FIFO is full
    if (driver->base_addr[REG_FIFO_STATUS] & STATUS_FIFO_FULL) {
        return -1;
    }
    
    // Write data to FIFO
    driver->base_addr[REG_FIFO_DATA] = data;
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

int cgra_start_instance(cgra_fifo_driver_t* driver, uint32_t instance_id) {
    if (!driver || instance_id >= driver->num_instances) {
        return -1;
    }
    
    // Set start bit for the specified instance
    driver->base_addr[REG_CGRA_CTRL] |= (1 << instance_id);
    return 0;
}

int cgra_is_done(cgra_fifo_driver_t* driver, uint32_t instance_id) {
    if (!driver || instance_id >= driver->num_instances) {
        return -1;
    }
    
    // Check done bit for the specified instance
    return (driver->base_addr[REG_CGRA_STATUS] & (1 << instance_id)) ? 1 : 0;
}

int cgra_read_data(cgra_fifo_driver_t* driver, uint32_t instance_id, uint32_t* data) {
    if (!driver || !data || instance_id >= driver->num_instances) {
        return -1;
    }
    
    // Check if data is ready for the specified instance
    if (!(driver->base_addr[REG_CGRA_STATUS] & (1 << (instance_id + 16)))) {
        return -1;
    }
    
    // Read data
    *data = driver->base_addr[REG_FIFO_DATA + instance_id];
    return 0;
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
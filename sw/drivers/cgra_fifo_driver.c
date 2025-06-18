#include "cgra_fifo_driver.h"
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
#define REG_CGRA_RESULT  0x10

// Status register bits
#define STATUS_FIFO_FULL   (1 << 0)
#define STATUS_FIFO_EMPTY  (1 << 1)
#define STATUS_CGRA_DONE   (1 << 2)

// Control register bits
#define CTRL_CGRA_START    (1 << 0)
#define CTRL_CGRA_RESET    (1 << 1)

int cgra_fifo_init(cgra_fifo_driver_t* driver, uint32_t base_addr, uint32_t num_inst) {
    if (!driver || num_inst == 0 || num_inst > MAX_INSTANCES) {
        return -1;
    }
    
    driver->base_addr = (volatile uint32_t*)base_addr;
    driver->num_instances = num_inst;
    fifo_base_addr = base_addr;
    num_instances = num_inst;
    
    // Initialize instance configurations
    for (uint8_t i = 0; i < num_inst; i++) {
        instance_configs[i].instance_id = i;
        instance_configs[i].kernel_id = 0;
        instance_configs[i].base_addr = base_addr + (i * 0x1000);
    }
    
    return 0;
}

int cgra_fifo_configure(const cgra_fifo_config_t *config) {
    if (config == NULL || config->instance_id >= MAX_INSTANCES) {
        return -1;
    }
    
    // Store configuration
    memcpy(&instance_configs[config->instance_id], config, sizeof(cgra_fifo_config_t));
    
    // Configure CGRA instance (simplified - in real implementation this would write to CGRA registers)
    printf("Configured CGRA instance %d with kernel %d at base addr 0x%x\n", 
           config->instance_id, config->kernel_id, config->base_addr);
    
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

int cgra_fifo_wait_ready(void) {
    uint32_t timeout = 1000; // Adjust timeout as needed
    
    while (timeout--) {
        uint32_t status = *(volatile uint32_t*)(fifo_base_addr + REG_FIFO_STATUS);
        if (!(status & STATUS_FIFO_FULL)) { // Not full
            return 0;
        }
    }
    
    return -1; // Timeout
}

int cgra_start_instance(cgra_fifo_driver_t* driver, uint32_t instance_id) {
    if (!driver || instance_id >= driver->num_instances) {
        return -1;
    }
    
    // Set start bit for the specific instance
    uint32_t ctrl_reg = driver->base_addr[REG_CGRA_CTRL];
    ctrl_reg |= (CTRL_CGRA_START << instance_id);
    driver->base_addr[REG_CGRA_CTRL] = ctrl_reg;
    
    return 0;
}

int cgra_is_done(cgra_fifo_driver_t* driver, uint32_t instance_id) {
    if (!driver || instance_id >= driver->num_instances) {
        return 0;
    }
    
    // Check if the specific instance is done
    uint32_t status = driver->base_addr[REG_CGRA_STATUS];
    return (status & (STATUS_CGRA_DONE << instance_id)) ? 1 : 0;
}

int cgra_read_data(cgra_fifo_driver_t* driver, uint32_t instance_id, uint32_t* data) {
    if (!driver || !data || instance_id >= driver->num_instances) {
        return -1;
    }
    
    // Check if result is ready
    if (!cgra_is_done(driver, instance_id)) {
        return -1;
    }
    
    // Read result data (simplified - in real implementation this would read from instance-specific registers)
    *data = driver->base_addr[REG_CGRA_RESULT + instance_id];
    return 0;
}

int cgra_fifo_wait_instance(uint8_t instance_id) {
    if (instance_id >= num_instances) {
        return -1;
    }
    
    // Wait for CGRA instance to complete
    uint32_t timeout = 10000; // Adjust timeout as needed
    while (timeout--) {
        uint32_t status = *(volatile uint32_t*)(fifo_base_addr + REG_CGRA_STATUS);
        if (status & (STATUS_CGRA_DONE << instance_id)) {
            return 0;
        }
    }
    
    return -1; // Timeout
}

int cgra_fifo_reset(void) {
    // Reset FIFO
    *(volatile uint32_t*)(fifo_base_addr + REG_CGRA_CTRL) = CTRL_CGRA_RESET;
    
    // Reset all CGRA instances
    for (uint8_t i = 0; i < num_instances; i++) {
        uint32_t ctrl_reg = *(volatile uint32_t*)(fifo_base_addr + REG_CGRA_CTRL);
        ctrl_reg |= (CTRL_CGRA_RESET << i);
        *(volatile uint32_t*)(fifo_base_addr + REG_CGRA_CTRL) = ctrl_reg;
    }
    
    num_instances = 0;
    
    return 0;
} 
#include "cgra_driver.h"
#include "core_v_mini_mcu.h"
#include "mmio.h"

// Initialize CGRA driver with multiple instances
void cgra_driver_init(cgra_driver_t *driver) {
    driver->num_instances = MAX_CGRA_INSTANCES;
    driver->active_instances = 0;

    // Initialize each instance with its base addresses
    for (int i = 0; i < MAX_CGRA_INSTANCES; i++) {
        driver->instances[i].base_addr = CGRA_START_ADDRESS + (i * CGRA_SIZE);
        driver->instances[i].periph_base_addr = CGRA_PERIPH_START_ADDRESS + (i * CGRA_PERIPH_SIZE);
        driver->instances[i].kernel_id = 0;
        driver->instances[i].is_configured = 0;
        driver->instances[i].is_running = 0;
    }
}

// Configure a specific CGRA instance with a kernel
int cgra_configure_instance(cgra_driver_t *driver, uint8_t instance_id, uint32_t kernel_id) {
    if (instance_id >= driver->num_instances) {
        return -1;  // Invalid instance ID
    }

    uint32_t periph_addr = cgra_get_instance_periph_addr(driver, instance_id);
    
    // Write kernel ID to configuration register
    mmio_write32(periph_addr + CGRA_KERNEL_ID_OFFSET, kernel_id);
    
    // Set configuration bit
    mmio_write32(periph_addr + CGRA_CTRL_OFFSET, CGRA_CTRL_CONF);
    
    // Wait for configuration to complete
    while (!(mmio_read32(periph_addr + CGRA_STATUS_OFFSET) & CGRA_STATUS_CONF_DONE));
    
    driver->instances[instance_id].kernel_id = kernel_id;
    driver->instances[instance_id].is_configured = 1;
    
    return 0;
}

// Start execution on a specific CGRA instance
int cgra_start_instance(cgra_driver_t *driver, uint8_t instance_id) {
    if (instance_id >= driver->num_instances || !driver->instances[instance_id].is_configured) {
        return -1;
    }

    uint32_t periph_addr = cgra_get_instance_periph_addr(driver, instance_id);
    
    // Set start bit
    mmio_write32(periph_addr + CGRA_CTRL_OFFSET, CGRA_CTRL_START);
    
    driver->instances[instance_id].is_running = 1;
    driver->active_instances++;
    
    return 0;
}

// Wait for a specific CGRA instance to complete
int cgra_wait_instance(cgra_driver_t *driver, uint8_t instance_id) {
    if (instance_id >= driver->num_instances || !driver->instances[instance_id].is_running) {
        return -1;
    }

    uint32_t periph_addr = cgra_get_instance_periph_addr(driver, instance_id);
    
    // Wait for execution to complete
    while (!(mmio_read32(periph_addr + CGRA_STATUS_OFFSET) & CGRA_STATUS_DONE));
    
    driver->instances[instance_id].is_running = 0;
    driver->active_instances--;
    
    return 0;
}

// Stop execution on a specific CGRA instance
int cgra_stop_instance(cgra_driver_t *driver, uint8_t instance_id) {
    if (instance_id >= driver->num_instances || !driver->instances[instance_id].is_running) {
        return -1;
    }

    uint32_t periph_addr = cgra_get_instance_periph_addr(driver, instance_id);
    
    // Set stop bit
    mmio_write32(periph_addr + CGRA_CTRL_OFFSET, CGRA_CTRL_STOP);
    
    driver->instances[instance_id].is_running = 0;
    driver->active_instances--;
    
    return 0;
}

// Reset a specific CGRA instance
int cgra_reset_instance(cgra_driver_t *driver, uint8_t instance_id) {
    if (instance_id >= driver->num_instances) {
        return -1;
    }

    uint32_t periph_addr = cgra_get_instance_periph_addr(driver, instance_id);
    
    // Set reset bit
    mmio_write32(periph_addr + CGRA_CTRL_OFFSET, CGRA_CTRL_RESET);
    
    // Wait for reset to complete
    while (mmio_read32(periph_addr + CGRA_STATUS_OFFSET) & CGRA_STATUS_RESET);
    
    driver->instances[instance_id].is_configured = 0;
    driver->instances[instance_id].is_running = 0;
    
    return 0;
}

// Get status of a specific CGRA instance
int cgra_get_status(cgra_driver_t *driver, uint8_t instance_id, uint32_t *status) {
    if (instance_id >= driver->num_instances) {
        return -1;
    }

    uint32_t periph_addr = cgra_get_instance_periph_addr(driver, instance_id);
    *status = mmio_read32(periph_addr + CGRA_STATUS_OFFSET);
    
    return 0;
}

// Write data to a specific CGRA instance
int cgra_write_data(cgra_driver_t *driver, uint8_t instance_id, uint32_t addr, uint32_t data) {
    if (instance_id >= driver->num_instances) {
        return -1;
    }

    uint32_t base_addr = cgra_get_instance_addr(driver, instance_id);
    mmio_write32(base_addr + addr, data);
    
    return 0;
}

// Read data from a specific CGRA instance
int cgra_read_data(cgra_driver_t *driver, uint8_t instance_id, uint32_t addr, uint32_t *data) {
    if (instance_id >= driver->num_instances) {
        return -1;
    }

    uint32_t base_addr = cgra_get_instance_addr(driver, instance_id);
    *data = mmio_read32(base_addr + addr);
    
    return 0;
} 
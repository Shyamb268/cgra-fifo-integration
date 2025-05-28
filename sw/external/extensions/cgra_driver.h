#ifndef CGRA_DRIVER_H
#define CGRA_DRIVER_H

#include <stdint.h>
#include "heepsilon.h"

// Maximum number of CGRA instances supported
#define MAX_CGRA_INSTANCES 4

// CGRA instance configuration structure
typedef struct {
    uint32_t base_addr;           // Base address for this CGRA instance
    uint32_t periph_base_addr;    // Peripheral base address for this instance
    uint32_t kernel_id;           // Current kernel ID for this instance
    uint8_t is_configured;        // Configuration status
    uint8_t is_running;           // Running status
} cgra_instance_t;

// CGRA driver structure
typedef struct {
    cgra_instance_t instances[MAX_CGRA_INSTANCES];
    uint8_t num_instances;
    uint8_t active_instances;
} cgra_driver_t;

// Function declarations
void cgra_driver_init(cgra_driver_t *driver);
int cgra_configure_instance(cgra_driver_t *driver, uint8_t instance_id, uint32_t kernel_id);
int cgra_start_instance(cgra_driver_t *driver, uint8_t instance_id);
int cgra_wait_instance(cgra_driver_t *driver, uint8_t instance_id);
int cgra_stop_instance(cgra_driver_t *driver, uint8_t instance_id);
int cgra_reset_instance(cgra_driver_t *driver, uint8_t instance_id);
int cgra_get_status(cgra_driver_t *driver, uint8_t instance_id, uint32_t *status);
int cgra_write_data(cgra_driver_t *driver, uint8_t instance_id, uint32_t addr, uint32_t data);
int cgra_read_data(cgra_driver_t *driver, uint8_t instance_id, uint32_t addr, uint32_t *data);

// Helper functions
static inline uint32_t cgra_get_instance_addr(cgra_driver_t *driver, uint8_t instance_id) {
    return driver->instances[instance_id].base_addr;
}

static inline uint32_t cgra_get_instance_periph_addr(cgra_driver_t *driver, uint8_t instance_id) {
    return driver->instances[instance_id].periph_base_addr;
}

#endif // CGRA_DRIVER_H 
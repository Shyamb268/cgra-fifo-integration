#include <stdio.h>
#include <stdlib.h>
#include "cgra_fifo_driver.h"

#define NUM_INSTANCES 2
#define TEST_DATA_SIZE 16

int main() {
    cgra_fifo_driver_t driver;
    uint32_t test_data[TEST_DATA_SIZE];
    uint32_t result_data[TEST_DATA_SIZE];
    int i, ret;
    
    // Initialize test data
    for (i = 0; i < TEST_DATA_SIZE; i++) {
        test_data[i] = i;
    }
    
    // Initialize driver
    ret = cgra_fifo_init(&driver, 0x10000000, NUM_INSTANCES);
    if (ret != 0) {
        printf("Failed to initialize driver\n");
        return -1;
    }
    
    // Configure instances
    for (i = 0; i < NUM_INSTANCES; i++) {
        cgra_fifo_config_t config = {
            .instance_id = i,
            .kernel_id = 0,
            .base_addr = 0x1000 * i
        };
        
        if (cgra_fifo_configure(&config) != 0) {
            printf("Failed to configure instance %d\n", i);
            return -1;
        }
    }
    
    // Write test data to FIFO
    for (i = 0; i < TEST_DATA_SIZE; i++) {
        ret = cgra_fifo_write(&driver, test_data[i]);
        if (ret != 0) {
            printf("Failed to write data to FIFO\n");
            return -1;
        }
    }
    
    // Start both CGRA instances
    for (i = 0; i < NUM_INSTANCES; i++) {
        ret = cgra_start_instance(&driver, i);
        if (ret != 0) {
            printf("Failed to start CGRA instance %d\n", i);
            return -1;
        }
    }
    
    // Wait for both instances to complete
    for (i = 0; i < NUM_INSTANCES; i++) {
        while (!cgra_is_done(&driver, i)) {
            // Wait for completion
        }
    }
    
    // Read results from both instances
    for (i = 0; i < TEST_DATA_SIZE; i++) {
        for (int j = 0; j < NUM_INSTANCES; j++) {
            ret = cgra_read_data(&driver, j, &result_data[i]);
            if (ret != 0) {
                printf("Failed to read data from CGRA instance %d\n", j);
                return -1;
            }
            printf("Instance %d result[%d] = %d\n", j, i, result_data[i]);
        }
    }
    
    printf("Test completed successfully\n");
    return 0;
} 
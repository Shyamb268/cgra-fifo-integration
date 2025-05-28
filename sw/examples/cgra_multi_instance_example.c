#include "cgra_driver.h"
#include "core_v_mini_mcu.h"
#include "mmio.h"
#include "stdio.h"

// Example kernel IDs for different operations
#define KERNEL_ID_VECTOR_ADD 0x1
#define KERNEL_ID_MATRIX_MUL 0x2
#define KERNEL_ID_FILTER    0x3

// Example data sizes
#define VECTOR_SIZE 1024
#define MATRIX_SIZE 32

// Example data arrays
uint32_t vector_a[VECTOR_SIZE];
uint32_t vector_b[VECTOR_SIZE];
uint32_t vector_c[VECTOR_SIZE];
uint32_t matrix_a[MATRIX_SIZE][MATRIX_SIZE];
uint32_t matrix_b[MATRIX_SIZE][MATRIX_SIZE];
uint32_t matrix_c[MATRIX_SIZE][MATRIX_SIZE];

// Initialize test data
void init_test_data(void) {
    // Initialize vectors
    for (int i = 0; i < VECTOR_SIZE; i++) {
        vector_a[i] = i;
        vector_b[i] = i * 2;
    }

    // Initialize matrices
    for (int i = 0; i < MATRIX_SIZE; i++) {
        for (int j = 0; j < MATRIX_SIZE; j++) {
            matrix_a[i][j] = i + j;
            matrix_b[i][j] = i * j;
        }
    }
}

// Example of parallel processing using multiple CGRA instances
int main(void) {
    cgra_driver_t cgra_driver;
    int status;

    // Initialize CGRA driver
    cgra_driver_init(&cgra_driver);
    printf("CGRA driver initialized with %d instances\n", cgra_driver.num_instances);

    // Initialize test data
    init_test_data();

    // Configure CGRA instances with different kernels
    status = cgra_configure_instance(&cgra_driver, 0, KERNEL_ID_VECTOR_ADD);
    if (status != 0) {
        printf("Failed to configure CGRA instance 0\n");
        return -1;
    }

    status = cgra_configure_instance(&cgra_driver, 1, KERNEL_ID_MATRIX_MUL);
    if (status != 0) {
        printf("Failed to configure CGRA instance 1\n");
        return -1;
    }

    status = cgra_configure_instance(&cgra_driver, 2, KERNEL_ID_FILTER);
    if (status != 0) {
        printf("Failed to configure CGRA instance 2\n");
        return -1;
    }

    // Load data into CGRA instances
    for (int i = 0; i < VECTOR_SIZE; i++) {
        cgra_write_data(&cgra_driver, 0, i * 4, vector_a[i]);
        cgra_write_data(&cgra_driver, 0, (VECTOR_SIZE + i) * 4, vector_b[i]);
    }

    for (int i = 0; i < MATRIX_SIZE; i++) {
        for (int j = 0; j < MATRIX_SIZE; j++) {
            cgra_write_data(&cgra_driver, 1, (i * MATRIX_SIZE + j) * 4, matrix_a[i][j]);
            cgra_write_data(&cgra_driver, 1, (MATRIX_SIZE * MATRIX_SIZE + i * MATRIX_SIZE + j) * 4, matrix_b[i][j]);
        }
    }

    // Start all configured instances
    for (int i = 0; i < 3; i++) {
        status = cgra_start_instance(&cgra_driver, i);
        if (status != 0) {
            printf("Failed to start CGRA instance %d\n", i);
            return -1;
        }
    }

    printf("Started %d CGRA instances\n", cgra_driver.active_instances);

    // Wait for all instances to complete
    for (int i = 0; i < 3; i++) {
        status = cgra_wait_instance(&cgra_driver, i);
        if (status != 0) {
            printf("Failed to wait for CGRA instance %d\n", i);
            return -1;
        }
    }

    // Read results
    for (int i = 0; i < VECTOR_SIZE; i++) {
        cgra_read_data(&cgra_driver, 0, (2 * VECTOR_SIZE + i) * 4, &vector_c[i]);
    }

    for (int i = 0; i < MATRIX_SIZE; i++) {
        for (int j = 0; j < MATRIX_SIZE; j++) {
            cgra_read_data(&cgra_driver, 1, (2 * MATRIX_SIZE * MATRIX_SIZE + i * MATRIX_SIZE + j) * 4, &matrix_c[i][j]);
        }
    }

    // Verify results
    printf("Verifying results...\n");
    int errors = 0;

    // Verify vector addition
    for (int i = 0; i < VECTOR_SIZE; i++) {
        if (vector_c[i] != vector_a[i] + vector_b[i]) {
            errors++;
        }
    }

    // Verify matrix multiplication
    for (int i = 0; i < MATRIX_SIZE; i++) {
        for (int j = 0; j < MATRIX_SIZE; j++) {
            uint32_t expected = 0;
            for (int k = 0; k < MATRIX_SIZE; k++) {
                expected += matrix_a[i][k] * matrix_b[k][j];
            }
            if (matrix_c[i][j] != expected) {
                errors++;
            }
        }
    }

    if (errors == 0) {
        printf("All operations completed successfully!\n");
    } else {
        printf("Found %d errors in results\n", errors);
    }

    return 0;
} 
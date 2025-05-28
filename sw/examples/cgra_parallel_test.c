#include "cgra_driver.h"
#include "core_v_mini_mcu.h"
#include "mmio.h"
#include "stdio.h"

// Kernel IDs for different operations
#define KERNEL_ID_VECTOR_ADD    0x1
#define KERNEL_ID_VECTOR_MUL    0x2
#define KERNEL_ID_MATRIX_MUL    0x3
#define KERNEL_ID_CONVOLUTION   0x4

// Data sizes
#define VECTOR_SIZE 1024
#define MATRIX_SIZE 32
#define CONV_SIZE 16
#define CONV_KERNEL_SIZE 3

// Data structures
typedef struct {
    uint32_t data[VECTOR_SIZE];
} vector_t;

typedef struct {
    uint32_t data[MATRIX_SIZE][MATRIX_SIZE];
} matrix_t;

typedef struct {
    uint32_t data[CONV_SIZE][CONV_SIZE];
} conv_matrix_t;

// Test data
vector_t vectors[4];  // For parallel vector operations
matrix_t matrices[2]; // For matrix multiplication
conv_matrix_t conv_input;
conv_matrix_t conv_kernel;
conv_matrix_t conv_output;

// Initialize test data
void init_test_data(void) {
    // Initialize vectors for parallel operations
    for (int v = 0; v < 4; v++) {
        for (int i = 0; i < VECTOR_SIZE; i++) {
            vectors[v].data[i] = (v + 1) * i;
        }
    }

    // Initialize matrices for multiplication
    for (int i = 0; i < MATRIX_SIZE; i++) {
        for (int j = 0; j < MATRIX_SIZE; j++) {
            matrices[0].data[i][j] = i + j;
            matrices[1].data[i][j] = i * j;
        }
    }

    // Initialize convolution data
    for (int i = 0; i < CONV_SIZE; i++) {
        for (int j = 0; j < CONV_SIZE; j++) {
            conv_input.data[i][j] = (i + j) % 256;
        }
    }

    // Initialize convolution kernel
    for (int i = 0; i < CONV_KERNEL_SIZE; i++) {
        for (int j = 0; j < CONV_KERNEL_SIZE; j++) {
            conv_kernel.data[i][j] = (i == 1 && j == 1) ? 1 : 0; // Identity kernel
        }
    }
}

// Parallel vector operations using multiple CGRA instances
int parallel_vector_ops(cgra_driver_t *driver) {
    printf("Starting parallel vector operations...\n");
    int status;

    // Configure two instances for vector addition
    status = cgra_configure_instance(driver, 0, KERNEL_ID_VECTOR_ADD);
    if (status != 0) return status;
    status = cgra_configure_instance(driver, 1, KERNEL_ID_VECTOR_ADD);
    if (status != 0) return status;

    // Configure two instances for vector multiplication
    status = cgra_configure_instance(driver, 2, KERNEL_ID_VECTOR_MUL);
    if (status != 0) return status;
    status = cgra_configure_instance(driver, 3, KERNEL_ID_VECTOR_MUL);
    if (status != 0) return status;

    // Load data for parallel operations
    for (int i = 0; i < VECTOR_SIZE; i++) {
        // Load data for first addition pair
        cgra_write_data(driver, 0, i * 4, vectors[0].data[i]);
        cgra_write_data(driver, 0, (VECTOR_SIZE + i) * 4, vectors[1].data[i]);
        
        // Load data for second addition pair
        cgra_write_data(driver, 1, i * 4, vectors[1].data[i]);
        cgra_write_data(driver, 1, (VECTOR_SIZE + i) * 4, vectors[2].data[i]);
        
        // Load data for first multiplication pair
        cgra_write_data(driver, 2, i * 4, vectors[2].data[i]);
        cgra_write_data(driver, 2, (VECTOR_SIZE + i) * 4, vectors[3].data[i]);
        
        // Load data for second multiplication pair
        cgra_write_data(driver, 3, i * 4, vectors[0].data[i]);
        cgra_write_data(driver, 3, (VECTOR_SIZE + i) * 4, vectors[3].data[i]);
    }

    // Start all instances simultaneously
    for (int i = 0; i < 4; i++) {
        status = cgra_start_instance(driver, i);
        if (status != 0) return status;
    }

    printf("Running 4 parallel vector operations...\n");

    // Wait for all instances to complete
    for (int i = 0; i < 4; i++) {
        status = cgra_wait_instance(driver, i);
        if (status != 0) return status;
    }

    printf("Parallel vector operations completed.\n");
    return 0;
}

// Sequential matrix operations using a single CGRA instance
int sequential_matrix_ops(cgra_driver_t *driver) {
    printf("Starting sequential matrix operations...\n");
    int status;

    // Configure instance for matrix multiplication
    status = cgra_configure_instance(driver, 0, KERNEL_ID_MATRIX_MUL);
    if (status != 0) return status;

    // Load matrix data
    for (int i = 0; i < MATRIX_SIZE; i++) {
        for (int j = 0; j < MATRIX_SIZE; j++) {
            cgra_write_data(driver, 0, (i * MATRIX_SIZE + j) * 4, matrices[0].data[i][j]);
            cgra_write_data(driver, 0, (MATRIX_SIZE * MATRIX_SIZE + i * MATRIX_SIZE + j) * 4, 
                           matrices[1].data[i][j]);
        }
    }

    // Start matrix multiplication
    status = cgra_start_instance(driver, 0);
    if (status != 0) return status;

    printf("Running matrix multiplication...\n");
    status = cgra_wait_instance(driver, 0);
    if (status != 0) return status;

    printf("Matrix multiplication completed.\n");
    return 0;
}

// Convolution operation using a dedicated CGRA instance
int convolution_ops(cgra_driver_t *driver) {
    printf("Starting convolution operation...\n");
    int status;

    // Configure instance for convolution
    status = cgra_configure_instance(driver, 1, KERNEL_ID_CONVOLUTION);
    if (status != 0) return status;

    // Load convolution data
    for (int i = 0; i < CONV_SIZE; i++) {
        for (int j = 0; j < CONV_SIZE; j++) {
            cgra_write_data(driver, 1, (i * CONV_SIZE + j) * 4, conv_input.data[i][j]);
        }
    }

    // Load convolution kernel
    for (int i = 0; i < CONV_KERNEL_SIZE; i++) {
        for (int j = 0; j < CONV_KERNEL_SIZE; j++) {
            cgra_write_data(driver, 1, (CONV_SIZE * CONV_SIZE + i * CONV_KERNEL_SIZE + j) * 4,
                           conv_kernel.data[i][j]);
        }
    }

    // Start convolution
    status = cgra_start_instance(driver, 1);
    if (status != 0) return status;

    printf("Running convolution...\n");
    status = cgra_wait_instance(driver, 1);
    if (status != 0) return status;

    printf("Convolution completed.\n");
    return 0;
}

int main(void) {
    cgra_driver_t cgra_driver;
    int status;

    // Initialize CGRA driver
    cgra_driver_init(&cgra_driver);
    printf("CGRA driver initialized with %d instances\n", cgra_driver.num_instances);

    // Initialize test data
    init_test_data();

    // Run parallel vector operations
    status = parallel_vector_ops(&cgra_driver);
    if (status != 0) {
        printf("Error in parallel vector operations\n");
        return -1;
    }

    // Run sequential matrix operations
    status = sequential_matrix_ops(&cgra_driver);
    if (status != 0) {
        printf("Error in sequential matrix operations\n");
        return -1;
    }

    // Run convolution operation
    status = convolution_ops(&cgra_driver);
    if (status != 0) {
        printf("Error in convolution operation\n");
        return -1;
    }

    printf("All operations completed successfully!\n");
    return 0;
} 
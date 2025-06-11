#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "cgra_fifo_driver.h"

#define FFT_SIZE 16
#define NUM_INSTANCES 2

// Complex number structure
typedef struct {
    float real;
    float imag;
} complex_t;

// FFT function declaration
void fft(complex_t* data, int n);

int main() {
    cgra_fifo_driver_t driver;
    complex_t input_data[FFT_SIZE];
    complex_t output_data[FFT_SIZE];
    int i, ret;
    
    // Initialize test data (simple sine wave)
    for (i = 0; i < FFT_SIZE; i++) {
        input_data[i].real = sin(2 * M_PI * i / FFT_SIZE);
        input_data[i].imag = 0;
    }
    
    // Initialize driver
    ret = cgra_fifo_init(&driver, 0x10000000, NUM_INSTANCES);
    if (ret != 0) {
        printf("Failed to initialize driver\n");
        return -1;
    }
    
    // Write input data to FIFO
    for (i = 0; i < FFT_SIZE; i++) {
        // Write real part
        ret = cgra_fifo_write(&driver, *(uint32_t*)&input_data[i].real);
        if (ret != 0) {
            printf("Failed to write real data to FIFO\n");
            return -1;
        }
        
        // Write imaginary part
        ret = cgra_fifo_write(&driver, *(uint32_t*)&input_data[i].imag);
        if (ret != 0) {
            printf("Failed to write imaginary data to FIFO\n");
            return -1;
        }
    }
    
    // Start both CGRA instances for parallel FFT computation
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
    
    // Read FFT results
    for (i = 0; i < FFT_SIZE; i++) {
        uint32_t real_data, imag_data;
        
        // Read real part
        ret = cgra_read_data(&driver, i % NUM_INSTANCES, &real_data);
        if (ret != 0) {
            printf("Failed to read real data from CGRA\n");
            return -1;
        }
        
        // Read imaginary part
        ret = cgra_read_data(&driver, i % NUM_INSTANCES, &imag_data);
        if (ret != 0) {
            printf("Failed to read imaginary data from CGRA\n");
            return -1;
        }
        
        output_data[i].real = *(float*)&real_data;
        output_data[i].imag = *(float*)&imag_data;
        
        printf("FFT[%d] = %f + %fi\n", i, output_data[i].real, output_data[i].imag);
    }
    
    printf("FFT computation completed successfully\n");
    return 0;
} 
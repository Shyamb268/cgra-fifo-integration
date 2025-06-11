#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "cgra_fifo_driver.h"

#define FFT_SIZE 1024
#define NUM_INSTANCES 2
#define FIXED_POINT_SCALE (1 << 16)  // Q16.16 format

// Complex number structure
typedef struct {
    int32_t real;  // Changed to int32_t for Q16.16 format
    int32_t imag;  // Changed to int32_t for Q16.16 format
} complex_t;

// FFT input/output data
complex_t input_data[FFT_SIZE];
complex_t output_data[FFT_SIZE];

// Initialize input data with a test signal
void init_input_data(void) {
    for (int i = 0; i < FFT_SIZE; i++) {
        // Generate a test signal (e.g., sum of two sinusoids)
        float t = (float)i / FFT_SIZE;
        // Scale by 2^16 for Q16.16 format
        input_data[i].real = (int32_t)(roundf((sin(2 * M_PI * 10 * t) + 0.5 * sin(2 * M_PI * 20 * t)) * FIXED_POINT_SCALE));
        input_data[i].imag = 0;
    }
}

// Process FFT using CGRA with FIFO
int process_fft(void) {
    // Initialize FIFO and CGRA
    if (cgra_fifo_init() != 0) {
        printf("Failed to initialize FIFO and CGRA\n");
        return -1;
    }
    
    // Configure CGRA instances
    for (int i = 0; i < NUM_INSTANCES; i++) {
        cgra_fifo_config_t config = {
            .instance_id = i,
            .kernel_id = 0, // FFT kernel ID
            .base_addr = 0x1000 * i // Instance-specific base address
        };
        
        if (cgra_fifo_configure(&config) != 0) {
            printf("Failed to configure instance %d\n", i);
            return -1;
        }
    }
    
    // Write input data to FIFO
    for (int i = 0; i < FFT_SIZE; i++) {
        // Wait for FIFO to be ready
        if (cgra_fifo_wait_ready() != 0) {
            printf("FIFO timeout while writing data\n");
            return -1;
        }
        
        // Write real part
        if (cgra_fifo_write(input_data[i].real) != 0) {
            printf("Failed to write real part\n");
            return -1;
        }
        
        // Write imaginary part
        if (cgra_fifo_write(input_data[i].imag) != 0) {
            printf("Failed to write imaginary part\n");
            return -1;
        }
    }
    
    // Start CGRA instances
    for (int i = 0; i < NUM_INSTANCES; i++) {
        if (cgra_fifo_start_instance(i) != 0) {
            printf("Failed to start instance %d\n", i);
            return -1;
        }
    }
    
    // Wait for completion
    for (int i = 0; i < NUM_INSTANCES; i++) {
        if (cgra_fifo_wait_instance(i) != 0) {
            printf("Instance %d failed to complete\n", i);
            return -1;
        }
    }
    
    // Read output data
    for (int i = 0; i < FFT_SIZE; i++) {
        int32_t real_data, imag_data;
        
        // Read real part
        if (cgra_fifo_read(&real_data) != 0) {
            printf("Failed to read real part\n");
            return -1;
        }
        output_data[i].real = real_data;
        
        // Read imaginary part
        if (cgra_fifo_read(&imag_data) != 0) {
            printf("Failed to read imaginary part\n");
            return -1;
        }
        output_data[i].imag = imag_data;
    }
    
    return 0;
}

// Print FFT results
void print_results(void) {
    printf("FFT Results:\n");
    printf("Index\tReal\t\tImaginary\tMagnitude\n");
    
    for (int i = 0; i < 10; i++) { // Print first 10 results
        // Convert from Q16.16 to float for display
        float real = (float)output_data[i].real / FIXED_POINT_SCALE;
        float imag = (float)output_data[i].imag / FIXED_POINT_SCALE;
        float magnitude = sqrt(real * real + imag * imag);
        printf("%d\t%f\t%f\t%f\n", i, real, imag, magnitude);
    }
}

int main(void) {
    // Initialize input data
    init_input_data();
    
    // Process FFT
    if (process_fft() != 0) {
        printf("FFT processing failed\n");
        return -1;
    }
    
    // Print results
    print_results();
    
    return 0;
} 
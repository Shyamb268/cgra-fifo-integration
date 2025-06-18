#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <complex.h>
#include <stdint.h>
#include "vcd_writer.h"

// FFT size (must be power of 2)
#define FFT_SIZE 256
#define FFT_BITS 8  // log2(FFT_SIZE)

// Complex number type
typedef struct {
    double r;  // Real part
    double i;  // Imaginary part
} fft_complex_t;

// Input and output buffers
fft_complex_t input_data[FFT_SIZE];
fft_complex_t output_data[FFT_SIZE];

// VCD writer
vcd_writer_t* vcd_writer = NULL;

// Generate test input data (sine wave)
void generate_test_data(void) {
    for (int i = 0; i < FFT_SIZE; i++) {
        double angle = 2.0 * M_PI * i / FFT_SIZE;
        input_data[i].r = sin(angle);
        input_data[i].i = 0.0;  // Pure real input
        
        // Write input data to VCD
        if (vcd_writer) {
            vcd_writer_complex(vcd_writer, "input", input_data[i].r, input_data[i].i);
        }
    }
}

// Bit reversal for FFT
uint16_t bit_reversal(uint16_t n, uint8_t num_bits) {
    uint16_t result = 0;
    for (uint8_t i = 0; i < num_bits; i++) {
        result = (result << 1) | (n & 1);
        n >>= 1;
    }
    return result;
}

// Perform bit-reversal permutation
void bit_reverse_permute(fft_complex_t* data) {
    for (uint16_t i = 0; i < FFT_SIZE; i++) {
        uint16_t j = bit_reversal(i, FFT_BITS);
        if (j > i) {
            // Swap elements
            fft_complex_t temp = data[i];
            data[i] = data[j];
            data[j] = temp;
        }
    }
}

// Perform FFT
void perform_fft(fft_complex_t* data) {
    // First, perform bit-reversal permutation
    bit_reverse_permute(data);

    // Then, perform the FFT
    for (int stage = 0; stage < FFT_BITS; stage++) {
        int m = 1 << stage;
        int m2 = m << 1;
        double theta = -M_PI / m;
        double w_r = cos(theta);
        double w_i = sin(theta);

        for (int k = 0; k < FFT_SIZE; k += m2) {
            double wr = 1.0;
            double wi = 0.0;

            for (int j = 0; j < m; j++) {
                int t = k + j;
                int u = t + m;
                
                // Complex multiplication
                double temp_r = wr * data[u].r - wi * data[u].i;
                double temp_i = wr * data[u].i + wi * data[u].r;

                // Complex subtraction
                data[u].r = data[t].r - temp_r;
                data[u].i = data[t].i - temp_i;

                // Complex addition
                data[t].r += temp_r;
                data[t].i += temp_i;

                // Update twiddle factor
                double wr_next = wr * w_r - wi * w_i;
                double wi_next = wr * w_i + wi * w_r;
                wr = wr_next;
                wi = wi_next;
            }
        }
    }
}

// Calculate magnitude of complex number
double complex_magnitude(fft_complex_t c) {
    return sqrt(c.r * c.r + c.i * c.i);
}

// Verify FFT results
void verify_fft_results(fft_complex_t* output) {
    int errors = 0;
    for (int i = 0; i < FFT_SIZE; i++) {
        // Expected result: FFT of a sine wave should have two peaks
        // at frequencies k and N-k in the imaginary part
        double expected_r = 0.0;
        double expected_i = 0.0;
        
        if (i == 1 || i == FFT_SIZE-1) {
            expected_i = FFT_SIZE/2.0;  // Peak in imaginary part
        }
        
        // Allow for some numerical error
        double tolerance = 1e-10;
        if (fabs(output[i].r - expected_r) > tolerance ||
            fabs(output[i].i - expected_i) > tolerance) {
            printf("Error at index %d: expected (%.6f,%.6f), got (%.6f,%.6f)\n",
                   i, expected_r, expected_i, output[i].r, output[i].i);
            errors++;
        }
    }
    printf("FFT verification completed with %d errors\n", errors);
}

// Print FFT results
void print_fft_results(fft_complex_t* data) {
    printf("\nFFT Results:\n");
    printf("Index\tReal\t\tImaginary\tMagnitude\n");
    printf("--------------------------------------------------------\n");
    for (int i = 0; i < FFT_SIZE; i++) {
        double mag = complex_magnitude(data[i]);
        printf("%d\t%.6f\t%.6f\t%.6f\n", i, data[i].r, data[i].i, mag);
        
        // Write output data to VCD
        if (vcd_writer) {
            vcd_writer_complex(vcd_writer, "output", data[i].r, data[i].i);
            vcd_writer_magnitude(vcd_writer, "magnitude", mag);
        }
    }
}

// Save results to CSV file for plotting
void save_results_to_csv(fft_complex_t* data, const char* filename) {
    FILE* fp = fopen(filename, "w");
    if (fp == NULL) {
        printf("Error opening file %s\n", filename);
        return;
    }

    // Write header
    fprintf(fp, "Index,Real,Imaginary,Magnitude\n");

    // Write data
    for (int i = 0; i < FFT_SIZE; i++) {
        double mag = complex_magnitude(data[i]);
        fprintf(fp, "%d,%.6f,%.6f,%.6f\n", i, data[i].r, data[i].i, mag);
    }

    fclose(fp);
    printf("Results saved to %s\n", filename);
}

int main(void) {
    printf("Initializing FFT application...\n");

    // Initialize VCD writer
    vcd_writer = vcd_writer_init("fft_simulation.vcd");
    if (vcd_writer) {
        vcd_writer_header(vcd_writer, "FFT_Simulation");
    }

    // Generate test data
    generate_test_data();

    // Copy input data to output buffer
    memcpy(output_data, input_data, sizeof(input_data));

    // Perform FFT
    printf("Performing FFT...\n");
    perform_fft(output_data);

    // Verify results
    verify_fft_results(output_data);

    // Print results
    print_fft_results(output_data);

    // Save results to CSV for plotting
    save_results_to_csv(output_data, "fft_results.csv");

    // Close VCD writer
    if (vcd_writer) {
        vcd_writer_close(vcd_writer);
        printf("VCD file generated: fft_simulation.vcd\n");
    }

    return EXIT_SUCCESS;
} 
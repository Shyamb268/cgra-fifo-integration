// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include "csr.h"
#include "hart.h"
#include "handler.h"
#include "core_v_mini_mcu.h" 
#include "rv_plic.h"
#include "rv_plic_regs.h"
#include "heepsilon.h"
#include "cgra.h"
#include "cgra_fifo.h"

#define DEBUG

// Use PRINTF instead of printf to remove print by default
#ifdef DEBUG
  #define PRINTF(fmt, ...)    printf(fmt, ## __VA_ARGS__)
#else
  #define PRINTF(...)
#endif

// FFT size (must be power of 2)
#define FFT_SIZE 256
#define FFT_BITS 8  // log2(FFT_SIZE)

// Fixed-point format
#define DECIMAL_BITS 16
#define FIXED_POINT_SCALE (1 << DECIMAL_BITS)

// Global variables
int8_t cgra_intr_flag;

// Complex number type
typedef struct {
    int16_t r;  // Real part
    int16_t i;  // Imaginary part
} fft_complex_t;

// Input and output buffers
fft_complex_t input_data[FFT_SIZE];
fft_complex_t output_data[FFT_SIZE];
int16_t twiddle_factors[FFT_SIZE];  // Real and imaginary parts interleaved

// Interrupt handler
void handler_irq_cgra(uint32_t id) {
    cgra_intr_flag = 1;
}

// Generate test input data (sine wave)
void generate_test_data(void) {
    for (int i = 0; i < FFT_SIZE; i++) {
        float angle = 2.0f * M_PI * i / FFT_SIZE;
        // Scale by 2^16 for Q16.16 format and ensure proper rounding
        input_data[i].r = (int16_t)(roundf(sinf(angle) * FIXED_POINT_SCALE));
        input_data[i].i = 0;  // Pure real input
    }
}

// Compute twiddle factors
void compute_twiddle_factors(void) {
    for (int i = 0; i < FFT_SIZE/2; i++) {
        float angle = -2.0f * M_PI * i / FFT_SIZE;
        // Scale by 2^16 for Q16.16 format and ensure proper rounding
        twiddle_factors[2*i] = (int16_t)(roundf(cosf(angle) * FIXED_POINT_SCALE));     // Real part
        twiddle_factors[2*i+1] = (int16_t)(roundf(sinf(angle) * FIXED_POINT_SCALE));   // Imaginary part
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

// Verify FFT results
void verify_fft_results(fft_complex_t* output) {
    int errors = 0;
    for (int i = 0; i < FFT_SIZE; i++) {
        // Expected result: FFT of a sine wave should have two peaks
        // at frequencies k and N-k
        int16_t expected_r = 0;
        int16_t expected_i = 0;
        
        if (i == 1 || i == FFT_SIZE-1) {
            expected_r = (FFT_SIZE/2) << 16;  // Scale by 2^16 to match testbench
        }
        
        // Allow for some numerical error in fixed-point arithmetic
        int16_t tolerance = FIXED_POINT_SCALE/100;  // 1% tolerance
        if (abs(output[i].r - expected_r) > tolerance ||
            abs(output[i].i - expected_i) > tolerance) {
            PRINTF("Error at index %d: expected (%d,%d), got (%d,%d)\n",
                   i, expected_r, expected_i, output[i].r, output[i].i);
            errors++;
        }
    }
    PRINTF("FFT verification completed with %d errors\n", errors);
}

int main(void) {
    PRINTF("Initializing CGRA FFT application...\n");

    // Generate test data and twiddle factors
    generate_test_data();
    compute_twiddle_factors();

    // Initialize PLIC
    plic_Init();
    plic_irq_set_priority(CGRA_INTR, 1);
    plic_irq_set_enabled(CGRA_INTR, kPlicToggleEnabled);
    plic_assign_external_irq_handler(CGRA_INTR, &handler_irq_cgra);

    // Enable interrupts
    CSR_SET_BITS(CSR_REG_MSTATUS, 0x8);
    const uint32_t mask = 1 << 11;
    CSR_SET_BITS(CSR_REG_MIE, mask);
    cgra_intr_flag = 0;

    // Initialize CGRA
    cgra_t cgra;
    cgra.base_addr = mmio_region_from_addr((uintptr_t)CGRA_PERIPH_START_ADDRESS);

    // Wait for CGRA to be ready
    cgra_wait_ready(&cgra);

    // Write input data to FIFO
    PRINTF("Writing input data to FIFO...\n");
    for (int i = 0; i < FFT_SIZE; i++) {
        // Write real part
        cgra_fifo_wait_ready(&cgra);
        cgra_fifo_write(&cgra, input_data[i].r);
        
        // Write imaginary part
        cgra_fifo_wait_ready(&cgra);
        cgra_fifo_write(&cgra, input_data[i].i);
    }

    // Write twiddle factors to FIFO
    PRINTF("Writing twiddle factors to FIFO...\n");
    for (int i = 0; i < FFT_SIZE; i++) {
        cgra_fifo_wait_ready(&cgra);
        cgra_fifo_write(&cgra, twiddle_factors[i]);
    }

    // Set up CGRA kernel pointers
    PRINTF("Setting up CGRA kernel...\n");
    cgra_set_read_ptr(&cgra, (uint32_t)input_data, 0);
    cgra_set_write_ptr(&cgra, (uint32_t)output_data, 0);

    // Launch CGRA kernel
    PRINTF("Launching CGRA kernel...\n");
    cgra_set_kernel(&cgra, 1);

    // Wait for completion
    cgra_intr_flag = 0;
    while (cgra_intr_flag == 0) {
        wait_for_interrupt();
    }
    PRINTF("CGRA kernel completed\n");

    // Verify results
    verify_fft_results(output_data);

    return EXIT_SUCCESS;
}

#ifndef VCD_WRITER_H
#define VCD_WRITER_H

#include <stdio.h>
#include <stdint.h>

typedef struct {
    FILE* file;
    uint64_t timestamp;
} vcd_writer_t;

// Initialize VCD writer
vcd_writer_t* vcd_writer_init(const char* filename);

// Write VCD header
void vcd_writer_header(vcd_writer_t* writer, const char* module_name);

// Write real value
void vcd_writer_real(vcd_writer_t* writer, const char* name, double value);

// Write complex value
void vcd_writer_complex(vcd_writer_t* writer, const char* name, double real, double imag);

// Write magnitude value
void vcd_writer_magnitude(vcd_writer_t* writer, const char* name, double magnitude);

// Close VCD writer
void vcd_writer_close(vcd_writer_t* writer);

#endif // VCD_WRITER_H 
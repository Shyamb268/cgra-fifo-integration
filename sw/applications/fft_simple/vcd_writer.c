#include "vcd_writer.h"
#include <stdlib.h>
#include <string.h>

vcd_writer_t* vcd_writer_init(const char* filename) {
    vcd_writer_t* writer = (vcd_writer_t*)malloc(sizeof(vcd_writer_t));
    if (!writer) return NULL;

    writer->file = fopen(filename, "w");
    if (!writer->file) {
        free(writer);
        return NULL;
    }

    writer->timestamp = 0;
    return writer;
}

void vcd_writer_header(vcd_writer_t* writer, const char* module_name) {
    if (!writer || !writer->file) return;

    fprintf(writer->file, "$date\n");
    fprintf(writer->file, "    FFT Simulation\n");
    fprintf(writer->file, "$end\n");
    fprintf(writer->file, "$version\n");
    fprintf(writer->file, "    FFT VCD Generator\n");
    fprintf(writer->file, "$end\n");
    fprintf(writer->file, "$timescale 1ps $end\n");
    fprintf(writer->file, "$scope module %s $end\n", module_name);
    
    // Define variables
    fprintf(writer->file, "$var real 64 real_part real $end\n");
    fprintf(writer->file, "$var real 64 imag_part imag $end\n");
    fprintf(writer->file, "$var real 64 magnitude mag $end\n");
    
    fprintf(writer->file, "$upscope $end\n");
    fprintf(writer->file, "$enddefinitions $end\n");
}

void vcd_writer_real(vcd_writer_t* writer, const char* name, double value) {
    if (!writer || !writer->file) return;
    fprintf(writer->file, "#%lu\n", writer->timestamp);
    fprintf(writer->file, "r%.16g real_part\n", value);
    writer->timestamp += 1;
}

void vcd_writer_complex(vcd_writer_t* writer, const char* name, double real, double imag) {
    if (!writer || !writer->file) return;
    fprintf(writer->file, "#%lu\n", writer->timestamp);
    fprintf(writer->file, "r%.16g real_part\n", real);
    fprintf(writer->file, "r%.16g imag_part\n", imag);
    writer->timestamp += 1;
}

void vcd_writer_magnitude(vcd_writer_t* writer, const char* name, double magnitude) {
    if (!writer || !writer->file) return;
    fprintf(writer->file, "#%lu\n", writer->timestamp);
    fprintf(writer->file, "r%.16g magnitude\n", magnitude);
    writer->timestamp += 1;
}

void vcd_writer_close(vcd_writer_t* writer) {
    if (!writer) return;
    if (writer->file) {
        fclose(writer->file);
    }
    free(writer);
} 
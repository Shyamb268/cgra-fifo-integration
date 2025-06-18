# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# This Makefile is used to build the CGRA FFT application.

# Include common Makefile
include ../../common.mk

# Application name
APP = cgra_fft

# Source files
SRCS = main.c fxp.c

# Include paths
INCLUDES += -I$(SW_DIR)/external/drivers/cgra -I.

# Build the application
all: $(APP)

# Clean build artifacts
clean:
	rm -f $(APP) *.o

.PHONY: all clean 
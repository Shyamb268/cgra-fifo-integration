# Root level Makefile for CGRA-FIFO integration project

# Default target
all: test

# Run all tests
test:
	$(MAKE) -C tb test

# Run FIFO tests only
test_fifo:
	$(MAKE) -C tb test_fifo

# Run CGRA-FIFO tests only
test_cgra_fifo:
	$(MAKE) -C tb test_cgra_fifo

# Clean all build artifacts
clean:
	$(MAKE) -C tb clean

.PHONY: all test test_fifo test_cgra_fifo clean 
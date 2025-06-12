# Common Makefile for software applications

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -I./drivers -I./external/drivers/cgra
LDFLAGS = -lm

# Directories
SW_DIR = $(shell pwd)
BUILD_DIR = $(SW_DIR)/build

# Default target
all: $(APP)

# Compile source files
%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Link application
$(APP): $(SRCS:.c=.o)
	$(CC) $^ -o $@ $(LDFLAGS)

# Clean build artifacts
clean:
	rm -f $(APP) *.o

.PHONY: all clean 
# Software Makefile

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -I./drivers -I./external/drivers/cgra
LDFLAGS = -lm

# Directories
BUILD_DIR = build
DRIVER_DIR = drivers
APP_DIR = applications

# Source files
DRIVER_SRCS = $(wildcard $(DRIVER_DIR)/*.c)
APP_SRCS = $(wildcard $(APP_DIR)/*/main.c)

# Object files
DRIVER_OBJS = $(DRIVER_SRCS:%.c=$(BUILD_DIR)/%.o)
APP_OBJS = $(APP_SRCS:%.c=$(BUILD_DIR)/%.o)

# Executables
APPS = $(APP_SRCS:$(APP_DIR)/%/main.c=$(BUILD_DIR)/%)

# Default target
all: $(APPS)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/$(DRIVER_DIR)
	mkdir -p $(BUILD_DIR)/$(APP_DIR)

# Compile driver objects
$(BUILD_DIR)/$(DRIVER_DIR)/%.o: $(DRIVER_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Compile application objects
$(BUILD_DIR)/$(APP_DIR)/%.o: $(APP_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Link applications
$(BUILD_DIR)/%: $(BUILD_DIR)/$(APP_DIR)/%.o $(DRIVER_OBJS)
	$(CC) $^ -o $@ $(LDFLAGS)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean 
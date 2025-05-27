// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>
#include "mmio.h"
#include "cgra.h"
#include "cgra_fifo.h"
#include "cgra_regs.h"

int cgra_fifo_write(const cgra_t *cgra, uint32_t data) {
    // Check if FIFO is ready
    if (!cgra_fifo_ready(cgra)) {
        return -1;
    }
    
    // Write data to FIFO
    mmio_region_write32(cgra->base_addr, (ptrdiff_t)(CGRA_FIFO_DATA_REG_OFFSET), data);
    return 0;
}

int cgra_fifo_ready(const cgra_t *cgra) {
    // Read FIFO status register
    uint32_t status = mmio_region_read32(cgra->base_addr, (ptrdiff_t)(CGRA_FIFO_STATUS_REG_OFFSET));
    // Check if FIFO is not full
    return !(status & CGRA_FIFO_STATUS_FULL_MASK);
}

void cgra_fifo_wait_ready(const cgra_t *cgra) {
    // Wait until FIFO is ready
    while (!cgra_fifo_ready(cgra)) {
        // Busy wait
    }
} 
// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _CGRA_FIFO_H_
#define _CGRA_FIFO_H_

#include <stdint.h>
#include "mmio.h"
#include "cgra.h"

/**
 * Write data to the CGRA FIFO
 * @param cgra Pointer to cgra_t representing the target CGRA peripheral
 * @param data Data to write to the FIFO
 * @return 0 if successful, -1 if FIFO is full
 */
int cgra_fifo_write(const cgra_t *cgra, uint32_t data);

/**
 * Check if the CGRA FIFO is ready to accept data
 * @param cgra Pointer to cgra_t representing the target CGRA peripheral
 * @return 1 if FIFO is ready, 0 if FIFO is full
 */
int cgra_fifo_ready(const cgra_t *cgra);

/**
 * Wait until the CGRA FIFO is ready to accept data
 * @param cgra Pointer to cgra_t representing the target CGRA peripheral
 */
void cgra_fifo_wait_ready(const cgra_t *cgra);

#endif // _CGRA_FIFO_H_ 
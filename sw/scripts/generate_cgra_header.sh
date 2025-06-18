#!/bin/bash

# Configuration values from heepsilon_cfg.hjson
CGRA_NUM_COLUMNS=4
CGRA_NUM_ROWS=4
CGRA_MAX_COLUMNS=4
CGRA_RCS_NUM_INSTR=16
CGRA_CMEM_BK_DEPTH=16
CGRA_KMEM_DEPTH=16
CGRA_KMEM_WIDTH=32
CGRA_CMEM_BK_DEPTH_LOG2=4
CGRA_RCS_NUM_INSTR_LOG2=4

# Generate cgra.h from template
sed -e "s/\${cgra_num_columns}/$CGRA_NUM_COLUMNS/g" \
    -e "s/\${cgra_num_rows}/$CGRA_NUM_ROWS/g" \
    -e "s/\${cgra_max_columns}/$CGRA_MAX_COLUMNS/g" \
    -e "s/\${cgra_rcs_num_instr}/$CGRA_RCS_NUM_INSTR/g" \
    -e "s/\${cgra_cmem_bk_depth}/$CGRA_CMEM_BK_DEPTH/g" \
    -e "s/\${cgra_kmem_depth}/$CGRA_KMEM_DEPTH/g" \
    -e "s/\${cgra_kmem_width}/$CGRA_KMEM_WIDTH/g" \
    -e "s/\${cgra_cmem_bk_depth_log2}/$CGRA_CMEM_BK_DEPTH_LOG2/g" \
    -e "s/\${cgra_rcs_num_instr_log2}/$CGRA_RCS_NUM_INSTR_LOG2/g" \
    sw/external/drivers/cgra/cgra.h.tpl > sw/external/drivers/cgra/cgra.h 
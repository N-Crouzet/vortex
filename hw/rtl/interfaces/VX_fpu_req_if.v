`ifndef VX_FPU_REQ_IF
`define VX_FPU_REQ_IF

`include "VX_define.vh"

`ifndef EXTF_F_ENABLE
    `IGNORE_WARNINGS_BEGIN
`endif

interface VX_fpu_req_if ();

    wire                    valid;    

    wire [`NW_BITS-1:0]     wid;
    wire [`NUM_THREADS-1:0] tmask;
    wire [31:0]             PC;
    wire [`FPU_BITS-1:0]    op_type;
    wire [`FRM_BITS-1:0]    frm;
    wire [`NUM_THREADS-1:0][31:0] rs1_data;
    wire [`NUM_THREADS-1:0][31:0] rs2_data;
    wire [`NUM_THREADS-1:0][31:0] rs3_data;
    wire [`NR_BITS-1:0]     rd;
    wire                    wb;
        
    wire                    ready;

endinterface

`endif
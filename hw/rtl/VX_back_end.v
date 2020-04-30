`include "VX_define.vh"

module VX_back_end    #(
    parameter CORE_ID = 0
) (
    input wire clk, 
    input wire reset, 
    input wire schedule_delay,

    VX_cache_core_rsp_if   dcache_rsp_if,
    VX_cache_core_req_if   dcache_req_if,

    output wire            mem_delay,
    output wire            exec_delay,
    output wire            gpr_stage_delay,
    VX_jal_rsp_if          jal_rsp_if,
    VX_branch_rsp_if       branch_rsp_if,

    VX_frE_to_bckE_req_if  bckE_req_if,
    VX_wb_if               writeback_if,

    VX_warp_ctl_if         warp_ctl_if
);

VX_wb_if writeback_temp_if();
assign writeback_if.wb        = writeback_temp_if.wb;
assign writeback_if.rd        = writeback_temp_if.rd;
assign writeback_if.data      = writeback_temp_if.data;
assign writeback_if.valid     = writeback_temp_if.valid;
assign writeback_if.warp_num  = writeback_temp_if.warp_num;
assign writeback_if.pc        = writeback_temp_if.pc;

// assign VX_writeback_if(writeback_temp_if);

wire                no_slot_mem;
wire                no_slot_exec;

// LSU input + output
VX_lsu_req_if       lsu_req_if();
VX_wb_if   mem_wb_if();

// Exec unit input + output
VX_exec_unit_req_if exec_unit_req_if();
VX_wb_if  inst_exec_wb_if();

// GPU unit input
VX_gpu_inst_req_if  gpu_inst_req_if();

// CSR unit inputs
VX_csr_req_if        csr_req_if();
VX_wb_if             csr_wb_if();
wire                 no_slot_csr;
wire                 stall_gpr_csr;

VX_gpr_stage gpr_stage (
    .clk                 (clk),
    .reset               (reset),
    .schedule_delay      (schedule_delay),
    .writeback_if        (writeback_temp_if),
    .bckE_req_if         (bckE_req_if),
    // New
    .exec_unit_req_if    (exec_unit_req_if),
    .lsu_req_if          (lsu_req_if),
    .gpu_inst_req_if   (gpu_inst_req_if),
    .csr_req_if          (csr_req_if),
    .stall_gpr_csr       (stall_gpr_csr),
    // End new
    .memory_delay        (mem_delay),
    .exec_delay          (exec_delay),
    .gpr_stage_delay     (gpr_stage_delay)
);

VX_lsu_unit lsu_unit (
    .clk            (clk),
    .reset          (reset),
    .lsu_req_if     (lsu_req_if),
    .mem_wb_if      (mem_wb_if),
    .dcache_rsp_if  (dcache_rsp_if),
    .dcache_req_if  (dcache_req_if),
    .delay          (mem_delay),
    .no_slot_mem    (no_slot_mem)
);

VX_exec_unit exec_unit (
    .clk             (clk),
    .reset           (reset),
    .exec_unit_req_if(exec_unit_req_if),
    .inst_exec_wb_if (inst_exec_wb_if),
    .jal_rsp_if      (jal_rsp_if),
    .branch_rsp_if   (branch_rsp_if),
    .delay           (exec_delay),
    .no_slot_exec    (no_slot_exec)
);

VX_gpu_inst gpu_inst (
    .gpu_inst_req_if(gpu_inst_req_if),
    .warp_ctl_if    (warp_ctl_if)
);

VX_csr_pipe #(
    .CORE_ID(CORE_ID)
) csr_pipe (
    .clk         (clk),
    .reset       (reset),
    .no_slot_csr (no_slot_csr),
    .csr_req_if  (csr_req_if),
    .writeback_if(writeback_temp_if),
    .csr_wb_if   (csr_wb_if),
    .stall_gpr_csr(stall_gpr_csr)
);

VX_writeback writeback (
    .clk               (clk),
    .reset             (reset),
    .mem_wb_if         (mem_wb_if),
    .inst_exec_wb_if   (inst_exec_wb_if),
    .csr_wb_if         (csr_wb_if),

    .writeback_if      (writeback_temp_if),
    .no_slot_mem       (no_slot_mem),
    .no_slot_exec      (no_slot_exec),
    .no_slot_csr       (no_slot_csr)
);

endmodule
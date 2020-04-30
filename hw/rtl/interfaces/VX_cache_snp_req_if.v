`ifndef VX_CACHE_SNP_REQ_IF
`define VX_CACHE_SNP_REQ_IF

`include "../cache/VX_cache_config.vh"

interface VX_cache_snp_req_if #(
    parameter DRAM_ADDR_WIDTH = 1
) ();

    wire                        snp_req_valid;
    wire [DRAM_ADDR_WIDTH-1:0]  snp_req_addr;    
    wire                        snp_req_ready;

endinterface

`endif
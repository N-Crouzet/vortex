`ifndef VX_CACHE_CORE_RSP_IF
`define VX_CACHE_CORE_RSP_IF

`include "../cache/VX_cache_config.vh"

interface VX_cache_core_rsp_if #(
    parameter NUM_REQUESTS   = 1,
    parameter WORD_SIZE      = 1,
    parameter CORE_TAG_WIDTH = 1
) ();

    wire [NUM_REQUESTS-1:0]                     core_rsp_valid;
    wire [NUM_REQUESTS-1:0][`WORD_WIDTH-1:0]    core_rsp_data;
    wire [NUM_REQUESTS-1:0][CORE_TAG_WIDTH-1:0] core_rsp_tag;    
    wire                                        core_rsp_ready;      

endinterface

`endif

`include "VX_cache_config.vh"

module VX_cache_core_req_bank_sel #(
    // Size of cache in bytes
    parameter CACHE_SIZE              = 1024, 
    // Size of line inside a bank in bytes
    parameter BANK_LINE_SIZE          = 16, 
    // Number of banks {1, 2, 4, 8,...}
    parameter NUM_BANKS                     = 8, 
    // Size of a word in bytes
    parameter WORD_SIZE               = 4, 
    // Number of Word requests per cycle {1, 2, 4, 8, ...}
    parameter NUM_REQUESTS                  = 2, 
    // Number of cycles to complete stage 1 (read from memory)
    parameter STAGE_1_CYCLES                = 2, 
    // Function ID, {Dcache=0, Icache=1, Sharedmemory=2}
    parameter FUNC_ID                       = 0,

    // Queues feeding into banks Knobs {1, 2, 4, 8, ...}
    // Core Request Queue Size
    parameter REQQ_SIZE                     = 8, 
    // Miss Reserv Queue Knob
    parameter MRVQ_SIZE                     = 8, 
    // Dram Fill Rsp Queue Size
    parameter DFPQ_SIZE                     = 2, 
    // Snoop Req Queue
    parameter SNRQ_SIZE                     = 8, 

    // Queues for writebacks Knobs {1, 2, 4, 8, ...}
    // Core Writeback Queue Size
    parameter CWBQ_SIZE                     = 8, 
    // Dram Writeback Queue Size
    parameter DWBQ_SIZE                     = 4, 
    // Dram Fill Req Queue Size
    parameter DFQQ_SIZE                     = 8, 
    // Lower Level Cache Hit Queue Size
    parameter LLVQ_SIZE                     = 16, 

     // Fill Invalidator Size {Fill invalidator must be active}
     parameter FILL_INVALIDAOR_SIZE          = 16
) (
    input  wire [NUM_REQUESTS-1:0]                   core_req_valid,
    input  wire [NUM_REQUESTS-1:0][31:0]             core_req_addr,
    
    output reg  [NUM_BANKS-1:0][NUM_REQUESTS-1:0]    per_bank_valids
);

    generate
        integer i;
        always @(*) begin
            per_bank_valids = 0;
            for (i = 0; i < NUM_REQUESTS; i = i + 1) begin
                if (NUM_BANKS == 1) begin
                    // If there is only one bank, then only map requests to that bank
                    per_bank_valids[0][i] = core_req_valid[i];
                end else begin
                    per_bank_valids[core_req_addr[i][`BANK_SELECT_ADDR_RNG]][i] = core_req_valid[i];
                end
            end
        end
    endgenerate

endmodule
`include "VX_cache_config.vh"

module VX_cache_dram_req_arb #(
    // Size of cache in bytes
    parameter CACHE_SIZE                    = 1024, 
    // Size of line inside a bank in bytes
    parameter BANK_LINE_SIZE                = 16, 
    // Number of banks {1, 2, 4, 8,...}
    parameter NUM_BANKS                     = 8, 
    // Size of a word in bytes
    parameter WORD_SIZE                     = 4, 
    // Number of Word requests per cycle {1, 2, 4, 8, ...}
    parameter NUM_REQUESTS                  = 2, 
    // Number of cycles to complete stage 1 (read from memory)
    parameter STAGE_1_CYCLES                = 2, 

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
     parameter FILL_INVALIDAOR_SIZE         = 16, 

     // Prefetcher
    parameter PRFQ_SIZE                     = 64,
    parameter PRFQ_STRIDE                   = 2
) (
    input  wire                                 clk,
    input  wire                                 reset,

    // Fill Request    
    input  wire [NUM_BANKS-1:0]                 per_bank_dram_fill_req_valid,
    input  wire [NUM_BANKS-1:0][`DRAM_ADDR_WIDTH-1:0] per_bank_dram_fill_req_addr,
    output wire                                 dfqq_full,
    
    // Writeback Request    
    input  wire [NUM_BANKS-1:0]                 per_bank_dram_wb_req_valid,
    input  wire [NUM_BANKS-1:0][`DRAM_ADDR_WIDTH-1:0] per_bank_dram_wb_req_addr,
    input  wire [NUM_BANKS-1:0][`BANK_LINE_WORDS-1:0][`WORD_WIDTH-1:0] per_bank_dram_wb_req_data,
    output wire [NUM_BANKS-1:0]                 per_bank_dram_wb_queue_pop,
    
    // Merged Request
    output wire                                 dram_req_read,
    output wire                                 dram_req_write,    
    output wire [`DRAM_ADDR_WIDTH-1:0]          dram_req_addr,
    output wire [`BANK_LINE_WIDTH-1:0]          dram_req_data,

    input wire                                  dram_req_ready
);

    wire       pref_pop;
    wire       pref_valid;
    wire[`DRAM_ADDR_WIDTH-1:0] pref_addr;
    
    wire       dwb_valid;
    wire       dfqq_req;

    assign pref_pop = !dwb_valid && !dfqq_req && dram_req_ready && pref_valid;
    
    VX_prefetcher #(
        .PRFQ_SIZE     (PRFQ_SIZE),
        .PRFQ_STRIDE   (PRFQ_STRIDE),
        .BANK_LINE_SIZE(BANK_LINE_SIZE),
        .WORD_SIZE     (WORD_SIZE)
    )  prfqq (
        .clk          (clk),
        .reset        (reset),

        .dram_req     (dram_req_read),
        .dram_req_addr(dram_req_addr),

        .pref_pop     (pref_pop),
        .pref_valid   (pref_valid),
        .pref_addr    (pref_addr)
    );

    wire[`DRAM_ADDR_WIDTH-1:0] dfqq_req_addr;
    
`DEBUG_BEGIN
    wire dfqq_empty;    
`DEBUG_END

    wire dfqq_pop  = !dwb_valid && dfqq_req && dram_req_ready; // If no dwb, and dfqq has valids, then pop
    wire dfqq_push = (|per_bank_dram_fill_req_valid);

    VX_cache_dfq_queue cache_dfq_queue(
        .clk                            (clk),
        .reset                          (reset),
        .dfqq_push                      (dfqq_push),
        .per_bank_dram_fill_req_valid   (per_bank_dram_fill_req_valid),
        .per_bank_dram_fill_req_addr    (per_bank_dram_fill_req_addr),
        .dfqq_pop                       (dfqq_pop),
        .dfqq_req                       (dfqq_req),
        .dfqq_req_addr                  (dfqq_req_addr),
        .dfqq_empty                     (dfqq_empty),
        .dfqq_full                      (dfqq_full)
    );

    wire [`LOG2UP(NUM_BANKS)-1:0] dwb_bank;

    wire [NUM_BANKS-1:0] use_wb_valid = per_bank_dram_wb_req_valid;
    
    VX_generic_priority_encoder #(
        .N(NUM_BANKS)
    ) sel_dwb (
        .valids(use_wb_valid),
        .index (dwb_bank),
        .found (dwb_valid)
    );

    assign per_bank_dram_wb_queue_pop = dram_req_ready ? (use_wb_valid & ((1 << dwb_bank))) : 0;

    wire   dram_req_valid  = dwb_valid || dfqq_req || pref_pop;
    assign dram_req_read   = ((dfqq_req && !dwb_valid) || pref_pop) && dram_req_valid;
    assign dram_req_write  = dwb_valid && dram_req_valid;    
    assign dram_req_addr   = dwb_valid ? per_bank_dram_wb_req_addr[dwb_bank] : (dfqq_req ? dfqq_req_addr : pref_addr);
    assign {dram_req_data} = dwb_valid ? {per_bank_dram_wb_req_data[dwb_bank] }: 0;

endmodule
`include "defines.vh"

// map the address of supervisor to physical ones

module mmu(
    input wire clk,
    input wire rst,
    input wire[`RegBus] addr_i,
    output reg[`RegBus] addr_o,

    input wire[`RegBus] inst_i,
    input wire[`RegBus] index_i,
    input wire[`RegBus] random_i,
    input wire[`RegBus] entrylo0_i,
    input wire[`RegBus] entrylo1_i,
    input wire[`RegBus] pagemask_i,
    input wire[`RegBus] entryhi_i,

    output reg tlb_hit,
    output reg tlb_dirty,

    // for TLBR / TLBP
    output wire[`RegBus] pagemask_o,
    output wire[`RegBus] entryhi_o,
    output wire[`RegBus] entrylo1_o,
    output wire[`RegBus] entrylo0_o,
    output wire[`RegBus] index_o
);

`define TLB_TERM 16

reg[18:0] tlb_vpn2[0:`TLB_TERM-1];
reg       tlb_g[0:`TLB_TERM-1];
reg[15:0] tlb_pagemask[0:`TLB_TERM-1];
reg[19:0] tlb_pfn0[0:`TLB_TERM-1];
reg[19:0] tlb_pfn1[0:`TLB_TERM-1];
reg       tlb_d0[0:`TLB_TERM-1], tlb_d1[0:`TLB_TERM-1], tlb_v0[0:`TLB_TERM-1], tlb_v1[0:`TLB_TERM-1];

wire[4:0] tlbwi_i;
wire[4:0] tlbwr_i;

reg[`RegBus] converted_addr;

reg[4:0] tlb_probe_idx;
reg tlb_probe_match;

assign tlbwi_i = index_i[4:0];
assign tlbwr_i = random_i[4:0];

assign index_o = {tlb_probe_match, 26'h0000000, tlb_probe_idx};
assign pagemask_o = {3'b000, tlb_pagemask[tlbwi_i], 13'h0000 };
assign entryhi_o = {tlb_vpn2[tlbwi_i], 13'h0000};
assign entrylo0_o = {6'b000000, tlb_pfn0[tlbwi_i], 3'b000, tlb_d0[tlbwi_i], tlb_v0[tlbwi_i], tlb_g[tlbwi_i]};
assign entrylo1_o = {6'b000000, tlb_pfn1[tlbwi_i], 3'b000, tlb_d1[tlbwi_i], tlb_v1[tlbwi_i], tlb_g[tlbwi_i]};

`define TLB_PROBE(idx) \
    if ((tlb_vpn2[idx] & {3'b111, ~tlb_pagemask[idx]}) == (entryhi_i[31:13] & {3'b111, ~tlb_pagemask[idx]})) begin \
        tlb_probe_idx <= idx; \
        tlb_probe_match <= 1'b0; \
    end

always @(*) begin
    tlb_probe_idx <= 5'h00;
    tlb_probe_match <= 1'b1;
    if(rst == `RstDisable) begin
        `TLB_PROBE(0)
        `TLB_PROBE(1)
        `TLB_PROBE(2)
        `TLB_PROBE(3)
        `TLB_PROBE(4)
        `TLB_PROBE(5)
        `TLB_PROBE(6)
        `TLB_PROBE(7)
        `TLB_PROBE(8)
        `TLB_PROBE(9)
        `TLB_PROBE(10)
        `TLB_PROBE(11)
        `TLB_PROBE(12)
        `TLB_PROBE(13)
        `TLB_PROBE(14)
        `TLB_PROBE(15)
    end
end

always @(posedge clk) begin
    if(rst == `RstDisable) begin
        if(inst_i[31:6] == `EXE_TLB_PREFIX) begin
            case(inst_i[5:0])
                `EXE_TLBWI: begin
                    tlb_vpn2[tlbwi_i] <= entryhi_i[31:13];
                    tlb_g[tlbwi_i] <= entrylo0_i[0] & entrylo1_i[0];
                    tlb_pagemask[tlbwi_i] <= pagemask_i[28:13];
                    tlb_pfn0[tlbwi_i] <= entrylo0_i[25:6];
                    tlb_d0[tlbwi_i] <= entrylo0_i[2];
                    tlb_v0[tlbwi_i] <= entrylo0_i[1];
                    tlb_pfn1[tlbwi_i] <= entrylo1_i[25:6];
                    tlb_d1[tlbwi_i] <= entrylo1_i[2];
                    tlb_v1[tlbwi_i] <= entrylo1_i[1];
                end
                `EXE_TLBWR: begin
                    tlb_vpn2[tlbwr_i] <= entryhi_i[31:13];
                    tlb_g[tlbwr_i] <= entrylo0_i[0] & entrylo1_i[0];
                    tlb_pagemask[tlbwr_i] <= pagemask_i[28:13];
                    tlb_pfn0[tlbwr_i] <= entrylo0_i[25:6];
                    tlb_d0[tlbwr_i] <= entrylo0_i[2];
                    tlb_v0[tlbwr_i] <= entrylo0_i[1];
                    tlb_pfn1[tlbwr_i] <= entrylo1_i[25:6];
                    tlb_d1[tlbwr_i] <= entrylo1_i[2];
                    tlb_v1[tlbwr_i] <= entrylo1_i[1];
                end
                default: ;
            endcase
        end
    end
end

`define TLB_MATCH(idx) \
    if ((tlb_vpn2[idx] & {3'b111, ~tlb_pagemask[idx]}) == (addr_i[31:13] & {3'b111, ~tlb_pagemask[idx]})) begin \
        if (addr_i[12] == 1'b0 && tlb_v0[idx] == 1'b1) begin \
            tlb_hit <= `True; \
            tlb_dirty <= ~tlb_d0[idx]; \
            converted_addr <= {tlb_pfn0[idx], addr_i[11:0]}; \
        end \
        if (addr_i[12] == 1'b1 && tlb_v1[idx] == 1'b1) begin \
            tlb_hit <= `True; \
            tlb_dirty <= ~tlb_d1[idx]; \
            converted_addr <= {tlb_pfn1[idx], addr_i[11:0]}; \
        end \
    end

always @(*) begin
    if(rst == `RstEnable) begin
        tlb_hit <= `False;
        tlb_dirty <= `True;
        converted_addr <= `ZeroWord;
    end
    else begin
        tlb_hit <= `False;
        tlb_dirty <= `False;
        converted_addr <= `ZeroWord;
        if(addr_i >= 32'h80000000 && addr_i <= 32'hbfffffff) begin
            // kseg0 & kseg1  0x80000000 - 0x9fffffff, 0xa0000000 - 0xbfffffff
            converted_addr <= addr_i; // no TLB translation
            tlb_hit <= `True;
        end else begin
            // need TLB translation
            `TLB_MATCH(0)
            `TLB_MATCH(1)
            `TLB_MATCH(2)
            `TLB_MATCH(3)
            `TLB_MATCH(4)
            `TLB_MATCH(5)
            `TLB_MATCH(6)
            `TLB_MATCH(7)
            `TLB_MATCH(8)
            `TLB_MATCH(9)
            `TLB_MATCH(10)
            `TLB_MATCH(11)
            `TLB_MATCH(12)
            `TLB_MATCH(13)
            `TLB_MATCH(14)
            `TLB_MATCH(15)
        end
    end
end

always @(*) begin
    if(rst == `RstEnable) begin
        addr_o <= `ZeroWord;
    end else begin
        case(converted_addr[31:24])
            8'h80: begin // 0x80000000 - 0x807fffff
                if(converted_addr[23:22] == 2'b00) addr_o <= {4'h0, 6'b000000, converted_addr[21:0]}; // base RAM
                else  addr_o <= {4'h1, 6'b000000, converted_addr[21:0]}; // ext RAM
            end
            8'h00: begin // 0x00000000 - 0x007fffff
                if(converted_addr[23:22] == 2'b00) addr_o <= {4'h0, 6'b000000, converted_addr[21:0]}; // base RAM
                else  addr_o <= {4'h1, 6'b000000, converted_addr[21:0]}; // ext RAM
            end
            8'hb0: begin // 0xb0000000 - 0xb00000ff   bootROM
                if(converted_addr[23:8] == 16'h0000)
                    addr_o <= {4'h5, 20'h00000, converted_addr[7:0]};
            end
            8'hb1: begin  // 0xb1000000 - 0xb100000f  GPIO
                if(converted_addr[23:6] == 18'h0000)
                    addr_o <= {4'h6, 22'h00000, converted_addr[5:0]};
            end
            8'hbf: begin
                if(converted_addr[23:20] == 4'hd)
                    addr_o <= {12'h200, converted_addr[19:0]}; // uart - 0xbfd003f8, 0xbfd003fc
                else
                    addr_o <= `ZeroWord;
            end
            8'hba: begin // 0xba000000 - 0xba0752ff
                if(converted_addr[23:19] == 5'b00000) begin
                    addr_o <= {8'h30, 5'b00000, converted_addr[18:0]}; // graphic ram
                end
            end
            8'hbc: begin // 0xbc000000 - 0xbc7fffff
                if(converted_addr[23] == 1'b0) begin
                    addr_o <= {8'h40, 1'b0, converted_addr[22:0]}; // flash
                end
            end
            default: addr_o <= `ZeroWord;
        endcase
    end
end

endmodule
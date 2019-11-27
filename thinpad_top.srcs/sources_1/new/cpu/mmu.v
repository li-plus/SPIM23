`include "defines.vh"

// map the address of supervisor to physical ones

module mmu(
    input wire clk,
    input wire rst,
    input wire[`RegBus] inst_addr_i,
    output wire[`RegBus] inst_addr_o,
    input wire[`RegBus] data_addr_i,
    output wire[`RegBus] data_addr_o,

    input wire[`RegBus] inst_i,
    input wire[`RegBus] index_i,
    input wire[`RegBus] random_i,
    input wire[`RegBus] entrylo0_i,
    input wire[`RegBus] entrylo1_i,
    input wire[`RegBus] pagemask_i,
    input wire[`RegBus] entryhi_i,

    output reg inst_tlb_hit,
    output reg inst_tlb_dirty,
    output reg data_tlb_hit,
    output reg data_tlb_dirty,

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

reg[`RegBus] converted_inst_addr;
reg[`RegBus] converted_data_addr;

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
        // `TLB_PROBE(16)
        // `TLB_PROBE(17)
        // `TLB_PROBE(18)
        // `TLB_PROBE(19)
        // `TLB_PROBE(20)
        // `TLB_PROBE(21)
        // `TLB_PROBE(22)
        // `TLB_PROBE(23)
        // `TLB_PROBE(24)
        // `TLB_PROBE(25)
        // `TLB_PROBE(26)
        // `TLB_PROBE(27)
        // `TLB_PROBE(28)
        // `TLB_PROBE(29)
        // `TLB_PROBE(30)
        // `TLB_PROBE(31)
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

`define INST_TLB_MATCH(idx) \
    if ((tlb_vpn2[idx] & {3'b111, ~tlb_pagemask[idx]}) == (inst_addr_i[31:13] & {3'b111, ~tlb_pagemask[idx]})) begin \
        if (inst_addr_i[12] == 1'b0 && tlb_v0[idx] == 1'b1) begin \
            inst_tlb_hit <= `True; \
            inst_tlb_dirty <= ~tlb_d0[idx]; \
            converted_inst_addr <= {tlb_pfn0[idx], inst_addr_i[11:0]}; \
        end \
        if (inst_addr_i[12] == 1'b1 && tlb_v1[idx] == 1'b1) begin \
            inst_tlb_hit <= `True; \
            inst_tlb_dirty <= ~tlb_d1[idx]; \
            converted_inst_addr <= {tlb_pfn1[idx], inst_addr_i[11:0]}; \
        end \
    end

`define DATA_TLB_MATCH(idx) \
    if ((tlb_vpn2[idx] & {3'b111, ~tlb_pagemask[idx]}) == (data_addr_i[31:13] & {3'b111, ~tlb_pagemask[idx]})) begin \
        if (data_addr_i[12] == 1'b0 && tlb_v0[idx] == 1'b1) begin \
            data_tlb_hit <= `True; \
            data_tlb_dirty <= ~tlb_d0[idx]; \
            converted_data_addr <= {tlb_pfn0[idx], data_addr_i[11:0]}; \
        end \
        if (data_addr_i[12] == 1'b1 && tlb_v1[idx] == 1'b1) begin \
            data_tlb_hit <= `True; \
            data_tlb_dirty <= ~tlb_d1[idx]; \
            converted_data_addr <= {tlb_pfn1[idx], data_addr_i[11:0]}; \
        end \
    end

always @(*) begin
    if(rst == `RstEnable) begin
        data_tlb_hit <= `False;
        data_tlb_dirty <= `True;
        converted_data_addr <= `ZeroWord;
    end
    else begin
        data_tlb_hit <= `False;
        data_tlb_dirty <= `True;
        converted_data_addr <= `ZeroWord;
        if(data_addr_i >= 32'h80000000 && data_addr_i <= 32'hbfffffff) begin
            // kseg0 & kseg1  0x80000000 - 0x9fffffff, 0xa0000000 - 0xbfffffff
            converted_data_addr <= data_addr_i; // no TLB translation
            data_tlb_hit <= `True;
            data_tlb_dirty <= `False;
        end else begin
            // need TLB translation
            `DATA_TLB_MATCH(0)
            `DATA_TLB_MATCH(1)
            `DATA_TLB_MATCH(2)
            `DATA_TLB_MATCH(3)
            `DATA_TLB_MATCH(4)
            `DATA_TLB_MATCH(5)
            `DATA_TLB_MATCH(6)
            `DATA_TLB_MATCH(7)
            `DATA_TLB_MATCH(8)
            `DATA_TLB_MATCH(9)
            `DATA_TLB_MATCH(10)
            `DATA_TLB_MATCH(11)
            `DATA_TLB_MATCH(12)
            `DATA_TLB_MATCH(13)
            `DATA_TLB_MATCH(14)
            `DATA_TLB_MATCH(15)
            // `DATA_TLB_MATCH(16)
            // `DATA_TLB_MATCH(17)
            // `DATA_TLB_MATCH(18)
            // `DATA_TLB_MATCH(19)
            // `DATA_TLB_MATCH(20)
            // `DATA_TLB_MATCH(21)
            // `DATA_TLB_MATCH(22)
            // `DATA_TLB_MATCH(23)
            // `DATA_TLB_MATCH(24)
            // `DATA_TLB_MATCH(25)
            // `DATA_TLB_MATCH(26)
            // `DATA_TLB_MATCH(27)
            // `DATA_TLB_MATCH(28)
            // `DATA_TLB_MATCH(29)
            // `DATA_TLB_MATCH(30)
            // `DATA_TLB_MATCH(31)
        end
    end
end

always @(*) begin
    if(rst == `RstEnable) begin
        inst_tlb_hit <= `False;
        inst_tlb_dirty <= `True;
        converted_inst_addr <= `ZeroWord;
    end
    else begin
        inst_tlb_hit <= `False;
        inst_tlb_dirty <= `False;
        converted_inst_addr <= `ZeroWord;
        if(inst_addr_i >= 32'h80000000 && inst_addr_i <= 32'hbfffffff) begin
            // kseg0 & kseg1  0x80000000 - 0x9fffffff, 0xa0000000 - 0xbfffffff
            converted_inst_addr <= inst_addr_i; // no TLB translation
            inst_tlb_hit <= `True;
        end else begin
            // need TLB translation
            `INST_TLB_MATCH(0)
            `INST_TLB_MATCH(1)
            `INST_TLB_MATCH(2)
            `INST_TLB_MATCH(3)
            `INST_TLB_MATCH(4)
            `INST_TLB_MATCH(5)
            `INST_TLB_MATCH(6)
            `INST_TLB_MATCH(7)
            `INST_TLB_MATCH(8)
            `INST_TLB_MATCH(9)
            `INST_TLB_MATCH(10)
            `INST_TLB_MATCH(11)
            `INST_TLB_MATCH(12)
            `INST_TLB_MATCH(13)
            `INST_TLB_MATCH(14)
            `INST_TLB_MATCH(15)
            // `INST_TLB_MATCH(16)
            // `INST_TLB_MATCH(17)
            // `INST_TLB_MATCH(18)
            // `INST_TLB_MATCH(19)
            // `INST_TLB_MATCH(20)
            // `INST_TLB_MATCH(21)
            // `INST_TLB_MATCH(22)
            // `INST_TLB_MATCH(23)
            // `INST_TLB_MATCH(24)
            // `INST_TLB_MATCH(25)
            // `INST_TLB_MATCH(26)
            // `INST_TLB_MATCH(27)
            // `INST_TLB_MATCH(28)
            // `INST_TLB_MATCH(29)
            // `INST_TLB_MATCH(30)
            // `INST_TLB_MATCH(31)
        end
    end
end

mmu_helper helper_inst(
    .rst(rst),
    .addr_i(converted_inst_addr),
    .addr_o(inst_addr_o)
);

mmu_helper helper_data(
    .rst(rst),
    .addr_i(converted_data_addr),
    .addr_o(data_addr_o)
);

endmodule

module mmu_helper(
    input wire rst,
    input wire[`RegBus] addr_i,
    output reg[`RegBus] addr_o
);

always @(*) begin
    if(rst == `RstEnable) begin
        addr_o <= `ZeroWord;
    end else begin
        case(addr_i[31:24])
            8'h80: begin // 0x80000000 - 0x807fffff
                if(addr_i[23:22] == 2'b00) addr_o <= {4'h0, 6'b000000, addr_i[21:0]}; // base RAM
                else  addr_o <= {4'h1, 6'b000000, addr_i[21:0]}; // ext RAM
            end
            8'h00: begin // 0x00000000 - 0x007fffff
                if(addr_i[23:22] == 2'b00) addr_o <= {4'h0, 6'b000000, addr_i[21:0]}; // base RAM
                else  addr_o <= {4'h1, 6'b000000, addr_i[21:0]}; // ext RAM
            end
            8'hbf: begin
                if(addr_i[23:20] == 4'hd)
                    addr_o <= {12'h200, addr_i[19:0]}; // uart - 0xbfd003f8, 0xbfd003fc
//                else if(addr_i[23:20] == 4'hc)
//                    addr_o <= {12'h300, addr_i[19:0]}; // rom - 0xbfc
                else
                    addr_o <= `ZeroWord;
            end
            8'hba: begin // 0xba000000 - 0xba0752ff
                if(addr_i[23:19] == 5'b00000) begin
                    addr_o <= {8'h30, 5'b00000, addr_i[18:0]}; // graphic ram
                end
            end
            8'hbc: begin // 0xbc000000 - 0xbc7fffff
                if(addr_i[23] == 1'b0) begin
                    addr_o <= {8'h40, 1'b0, addr_i[22:0]}; // flash
                end
            end
            default: addr_o <= `ZeroWord;
        endcase
    end
end

endmodule
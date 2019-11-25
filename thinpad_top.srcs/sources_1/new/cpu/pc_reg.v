`include "defines.vh"

module pc_reg(
              input wire clk,
              input wire rst,
              input wire[5:0] stall,
              input wire flush,
              input wire[`RegBus] new_pc,
              // for branching
              input wire branch_flag_i,
              input wire[`RegBus] branch_target_address_i,
              output reg[`InstAddrBus] pc,
              input wire tlb_hit,
              input wire[`InstAddrBus] physical_pc,
              output reg[`InstAddrBus] virtual_pc,
              output reg ce,
              output reg[31:0] excepttype_o
);

always @ (*) begin
    if(tlb_hit == `True) begin
        pc <= physical_pc;
        excepttype_o <= `ZeroWord;
    end else begin
        pc <= `ZeroWord;
        excepttype_o <= {18'b0, `True, 13'b0};
    end
end

always @ (posedge clk) begin
    if (ce == `ChipDisable)
        virtual_pc <= `EntryAddr;
    else if(flush == `True)
        virtual_pc <= new_pc;
    else if (stall[0] == `NoStop) begin
        if (branch_flag_i == `Branch) virtual_pc <= branch_target_address_i;
		else virtual_pc <= virtual_pc + 4'h4;
    end
end

always @ (posedge clk) begin
    if (rst == `RstEnable) ce <= `ChipDisable;
	else ce <= `ChipEnable;
end

endmodule

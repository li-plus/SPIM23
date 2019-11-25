`include "defines.vh"

module if_id(input wire clk,
             input wire rst,
             input wire[5:0] stall,
             input wire flush,

             input wire[31:0] if_excepttype,
             output reg[31:0] id_excepttype,

             input wire[`InstAddrBus] if_pc,
             input wire[`InstBus] if_inst,
             output reg[`InstAddrBus] id_pc,
             output reg[`InstBus] id_inst);
    
    always @ (posedge clk) begin
        if (rst == `RstEnable || flush == `True || (stall[1] == `Stop && stall[2] == `NoStop)) begin
            id_pc   <= `ZeroWord;
            id_inst <= `ZeroWord;
            id_excepttype <= `ZeroWord;
            end
	else if (stall[1] == `NoStop) begin
            id_pc   <= if_pc;
            id_excepttype <= if_excepttype;
            id_inst <= (if_excepttype[13] == `True) ? `ZeroWord : if_inst;
        end
    end
    
endmodule

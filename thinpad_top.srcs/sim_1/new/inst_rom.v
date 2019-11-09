`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 11:43:44 PM
// Design Name: 
// Module Name: inst_rom
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module inst_rom(
    input wire ce,
    input wire[`InstAddrBus] addr,
    output reg[`InstBus]     inst
);

reg[`InstBus] inst_mem[0: 131071 - 1];

initial $readmemh ("/home/zx/inst_rom.data", inst_mem);
always @(*) begin
    if(ce == `ChipDisable) begin
        inst <= `ZeroWord;
    end else begin
        inst <= inst_mem[addr[18:2]];
    end
end

endmodule

module min_sopc(
    input wire clk,
    input wire rst
);

wire[`InstAddrBus]  inst_addr;
wire[`InstBus]      inst;
wire                rom_ce;

cpu my_cpu(
    .clk(clk), .rst(rst),
    .rom_addr_o(inst_addr), .rom_data_i(inst),
    .rom_ce_o(rom_ce)
);

inst_rom rom(.ce(rom_ce), .addr(inst_addr), .inst(inst));

endmodule

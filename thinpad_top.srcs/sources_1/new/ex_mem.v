`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 10:49:44 PM
// Design Name: 
// Module Name: ex_mem
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

module ex_mem(
    input wire clk,
    input wire rst,
    input wire[`RegAddrBus] ex_reg_waddr,
    input wire              ex_reg_we,
    input wire[`RegBus]     ex_reg_wdata,
    output reg[`RegAddrBus] mem_reg_waddr,
    output reg              mem_reg_we,
    output reg[`RegBus]    mem_reg_wdata
    );
    
always @(posedge clk) begin
    if(rst == `RstEnable) begin
        mem_reg_waddr <= `ZeroRegAddr;
        mem_reg_we <= `WriteDisable;
        mem_reg_wdata <= `ZeroWord;
    end else begin
        mem_reg_waddr <= ex_reg_waddr;
        mem_reg_we <= ex_reg_we;
        mem_reg_wdata <= ex_reg_wdata;
    end
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 10:32:51 PM
// Design Name: 
// Module Name: id_ex
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Forward data from inst decoder to executor when posedge comes
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module id_ex(
    input wire clk,
    input wire rst,
    input wire[`AluOpBus]       id_alu_op,
    input wire[`AluSelBus]      id_alu_sel,
    input wire[`RegBus]         id_reg1,
    input wire[`RegBus]         id_reg2,
    input wire[`RegAddrBus]     id_reg_waddr,
    input wire                  id_reg_we,
    output reg[`AluOpBus]      ex_alu_op,
    output reg[`AluSelBus]     ex_alu_sel,
    output reg[`RegBus]        ex_reg1,
    output reg[`RegBus]        ex_reg2,
    output reg[`RegAddrBus]    ex_reg_waddr,
    output reg                 ex_reg_we
    );
 
always @(posedge clk) begin
    if(rst == `RstEnable) begin
        ex_alu_op <= `ALU_NOP;
        ex_alu_sel <= `ALU_SEL_NOP;
        ex_reg1 <= `ZeroWord;
        ex_reg2 <= `ZeroWord;
        ex_reg_waddr <= `ZeroRegAddr;
        ex_reg_we <= `WriteDisable;
    end else begin
        ex_alu_op <= id_alu_op;
        ex_alu_sel <= id_alu_sel;
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_reg_waddr <= id_reg_waddr;
        ex_reg_we <= id_reg_we;
    end
end   
 
endmodule

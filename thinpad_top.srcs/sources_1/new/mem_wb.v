`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 10:58:34 PM
// Design Name: 
// Module Name: mem_wb
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

module mem_wb(
    input wire clk,
    input wire rst,
    input wire[`RegAddrBus]     mem_reg_waddr,
    input wire                  mem_reg_we,
    input wire[`RegBus]         mem_reg_wdata,
    output reg[`RegAddrBus]     wb_reg_waddr,
    output reg                  wb_reg_we,
    output reg[`RegBus]         wb_reg_wdata
);

always @(posedge clk) begin
    if(rst == `RstEnable) begin
        wb_reg_waddr <= `ZeroRegAddr;
        wb_reg_we <= `WriteDisable;
        wb_reg_wdata <= `ZeroWord;
    end else begin
        wb_reg_waddr <= mem_reg_waddr;
        wb_reg_we <= mem_reg_we;
        wb_reg_wdata <= mem_reg_wdata;
    end
end

endmodule

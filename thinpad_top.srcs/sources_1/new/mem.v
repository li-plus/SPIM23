`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 10:54:26 PM
// Design Name: 
// Module Name: mem
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

module mem(
    input wire                  rst,
    input wire[`RegAddrBus]     reg_waddr_i,
    input wire                  reg_we_i,
    input wire[`RegBus]         reg_wdata_i,
    output reg[`RegAddrBus]     reg_waddr_o,
    output reg                  reg_we_o,
    output reg[`RegBus]         reg_wdata_o
    );
    
always @(*) begin
    if(rst == `RstEnable) begin
        reg_waddr_o <= `ZeroRegAddr;
        reg_we_o <= `WriteDisable;
        reg_wdata_o <= `ZeroWord;
    end else begin
        reg_waddr_o <= reg_waddr_i;
        reg_we_o <= reg_we_i;
        reg_wdata_o <= reg_wdata_i;
    end
end

endmodule

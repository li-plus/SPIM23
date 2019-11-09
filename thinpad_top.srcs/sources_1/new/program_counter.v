`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 09:19:59 PM
// Design Name: Program counter
// Module Name: pc
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

module program_counter(
    input wire clk,
    input wire rst,
    output reg[`InstAddrBus] pc,
    output reg ce
    );
    
always @(posedge clk) begin
    if(ce == `ChipEnable) begin
        pc <= pc + 4'h4;
    end else begin
        pc <= `ZeroWord;
    end
end

always @(posedge clk) begin
    if(rst == `RstEnable) begin
        ce <= `ChipDisable;
    end else begin
        ce <= `ChipEnable;
    end
end
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 09:37:17 PM
// Design Name: 
// Module Name: register
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

module register(
        input wire clk,
        input wire rst,
        // write port
        input wire we,
        input wire[`RegAddrBus] waddr,
        input wire[`RegBus]     wdata,
        // read port 1
        input wire re1,
        input wire[`RegAddrBus] raddr1,
        output reg[`RegBus]     rdata1,
        // read port 2
        input wire re2,
        input wire[`RegAddrBus] raddr2,
        output reg[`RegBus]      rdata2
    );
    
reg[`RegBus] regs[0:31];

// write register
always @(posedge clk) begin
    if(rst == `RstDisable) begin
        if(we == `WriteEnable && waddr != 5'h0) begin  // ignore write to $0
            regs[waddr] <= wdata;
        end
    end
end

// read register
always @(posedge clk) begin
    if(rst == `RstEnable || raddr1 == 5'h0 || re1 == `ReadDisable) begin
        rdata1 <= `ZeroWord;
    end else if(raddr1 == waddr && we == `WriteEnable) begin
        rdata1 <= wdata;  // shortcut
    end else begin
        rdata1 <= regs[raddr1];
    end
end

// read register 2
always @(posedge clk) begin
    if(rst == `RstEnable || raddr2 == 5'h0 || re2 == `ReadDisable) begin
        rdata2 <= `ZeroWord;
    end else if(raddr2 == waddr && we == `WriteEnable) begin
        rdata2 <= wdata;  // shortcut
    end else begin
        rdata2 <= regs[raddr2];
    end
end
 
endmodule

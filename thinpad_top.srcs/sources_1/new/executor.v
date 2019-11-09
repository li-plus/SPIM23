`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 10:41:50 PM
// Design Name: 
// Module Name: executor
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

module executor(
    input wire rst,
    input wire[`AluOpBus]   alu_op_i,
    input wire[`AluSelBus]  alu_sel_i,
    input wire[`RegBus]     reg1_i,
    input wire[`RegBus]     reg2_i,
    input wire[`RegAddrBus] reg_waddr_i,
    input wire              reg_we_i,
    // execution results
    output reg[`RegAddrBus] reg_waddr_o,
    output reg              reg_we_o,
    output reg[`RegBus]     reg_wdata_o,
    output reg[`RegBus]     logic_out
    );
    
always @(*) begin
    if(rst == `RstEnable) begin
        logic_out <= `ZeroWord;
    end else begin
        case(alu_op_i)
            `ALU_OR: begin
                logic_out <= (reg1_i | reg2_i);
            end
            default: begin
                logic_out <= `ZeroWord;
            end
        endcase
    end
end

always @(*) begin
    reg_we_o <= reg_we_i;
    reg_waddr_o <= reg_waddr_i;
    case(alu_sel_i)
        `ALU_SEL_LOGIC: begin
            reg_wdata_o <= logic_out;
        end
        default: begin
            reg_wdata_o <= `ZeroWord;
        end
    endcase
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 09:50:26 PM
// Design Name: 
// Module Name: inst_decoder
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

module inst_decoder(
    input wire rst,
    // pc and instructions
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus]     inst_i,
    // register io
    input wire[`RegBus]      reg1_data_i,
    input wire[`RegBus]      reg2_data_i,
    output reg               reg1_re_o,
    output reg               reg2_re_o,
    output reg[`RegAddrBus]  reg1_addr_o,
    output reg[`RegAddrBus]  reg2_addr_o,
    output reg               reg_we_o,
    output reg[`RegAddrBus]  reg_waddr_o,
    // to executor
    output reg[`AluOpBus]    alu_op_o,
    output reg[`AluSelBus]   alu_sel_o,
    output reg[`RegBus]      reg1_o,
    output reg[`RegBus]      reg2_o
    );
/**
Reference:
R-Inst  op code |   rs  |   rt  |   rd  | shamt |  funct
         6 bits     5       5       5       5        6
I-Inst  op code |   rs  |   rt  |           imm
                                            16
J-Inst  op code |           addr
                            26
**/
wire[5:0] op_code = inst_i[31:26];
wire[4:0] shamt = inst_i[10:6];
wire[5:0] funct = inst_i[5:0];
wire[4:0] rs = inst_i[25:21];
wire[4:0] rt = inst_i[20:16];
wire[4:0] rd = inst_i[15:11];
wire[15:0] imm = inst_i[15:0];

reg[`RegBus] imm_reg;
reg inst_valid;

always @(*) begin
    if(rst == `RstEnable) begin
        alu_op_o <= `ALU_NOP;
        alu_sel_o <= `ALU_SEL_NOP;
        reg_we_o <= `WriteDisable;
        reg_waddr_o <= `ZeroRegAddr;
        inst_valid <= `InstValid;
        reg1_re_o <= `ReadDisable;
        reg2_re_o <= `ReadDisable;
        reg1_addr_o <= `ZeroRegAddr;
        reg2_addr_o <= `ZeroRegAddr;
        imm_reg <= `ZeroWord;
    end else begin
        alu_op_o <= `ALU_NOP;
        alu_sel_o <= `ALU_SEL_NOP;
        reg_we_o <= `WriteDisable;
        reg_waddr_o <= rd;
        inst_valid <= `InstInvalid;
        reg1_re_o <= `ReadDisable;
        reg2_re_o <= `ReadDisable;
        reg1_addr_o <= rs;
        reg2_addr_o <= rt;
        imm_reg <= `ZeroWord;
        
        case(op_code)
            `OP_ORI: begin
                reg_we_o <= `WriteEnable;
                alu_op_o <= `ALU_OR;
                alu_sel_o <= `ALU_SEL_LOGIC;
                reg1_re_o <= `ReadEnable;
                reg2_re_o <= `ReadDisable;
                imm_reg <= {16'h0, imm};
                reg_waddr_o <= rt;
                inst_valid <= `InstValid;
            end
            default: begin
            end
        endcase
    end
end
 
always @(*) begin
    if(rst == `RstDisable) begin 
        if(reg1_re_o == `ReadEnable) begin
            reg1_o <= reg1_data_i;
        end else begin
            reg1_o <= imm_reg;
        end
    end else begin
        reg1_o <= `ZeroWord;
    end
end

always @(*) begin
    if(rst == `RstDisable) begin 
        if(reg2_re_o == `ReadEnable) begin
            reg2_o <= reg2_data_i;
        end else begin
            reg2_o <= imm_reg;
        end
    end else begin
        reg2_o <= `ZeroWord;
    end
end
 
endmodule

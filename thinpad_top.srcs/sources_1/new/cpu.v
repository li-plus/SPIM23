`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2019 11:05:27 PM
// Design Name: 
// Module Name: cpu
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

module cpu(
    input wire clk,
    input wire rst,
    
    input wire[`RegBus]     rom_data_i,
    output wire[`RegBus]    rom_addr_o,
    output wire             rom_ce_o
);
// interconnections
wire[`InstAddrBus]  pc;
wire[`InstAddrBus]  id_pc_i;
wire[`InstBus]      id_inst_i;

wire[`AluOpBus]     id_alu_op_o;
wire[`AluSelBus]    id_alu_sel_o;
wire[`RegBus]       id_reg1_o;
wire[`RegBus]       id_reg2_o;
wire                id_reg_we_o;
wire[`RegAddrBus]   id_reg_waddr_o;

wire[`AluOpBus]     ex_alu_op_i;
wire[`AluSelBus]    ex_alu_sel_i;
wire[`RegBus]       ex_reg1_i;
wire[`RegBus]       ex_reg2_i;
wire                ex_reg_we_i;
wire[`RegAddrBus]   ex_reg_waddr_i;

wire                ex_reg_we_o;
wire[`RegAddrBus]   ex_reg_waddr_o;
wire[`RegBus]       ex_reg_wdata_o;

wire                mem_reg_we_i;
wire[`RegAddrBus]   mem_reg_waddr_i;
wire[`RegBus]       mem_reg_wdata_i;

wire                mem_reg_we_o;
wire[`RegAddrBus]   mem_reg_waddr_o;
wire[`RegBus]       mem_reg_wdata_o;

wire                wb_reg_we_i;
wire[`RegAddrBus]   wb_reg_waddr_i;
wire[`RegBus]       wb_reg_wdata_i;

wire                reg1_re;
wire                reg2_re;
wire[`RegAddrBus]   reg1_addr;
wire[`RegAddrBus]   reg2_addr;
wire[`RegBus]       reg1_data;
wire[`RegBus]       reg2_data;

assign rom_addr_o = pc;

register reg_heap(.clk(clk), .rst(rst), 
                  .we(wb_reg_we_i), .waddr(wb_reg_waddr_i), .wdata(wb_reg_wdata_i),
                  .re1(reg1_re), .raddr1(reg1_addr), .rdata1(reg1_data),
                  .re2(reg2_re), .raddr2(reg2_addr), .rdata2(reg2_data)
);

// instruction fetch
program_counter pc_main(.clk(clk), .rst(rst), .pc(pc), .ce(rom_ce_o));

inst_fetch if_id(.clk(clk), .rst(rst), .if_pc(pc), 
                 .if_inst(rom_data_i), .id_pc(id_pc_i),
                 .id_inst(id_inst_i));

// instruction decode
inst_decoder decode(.rst(rst), .pc_i(id_pc_i), .inst_i(id_inst_i),
                    .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
                    .reg1_re_o(reg1_re), .reg2_re_o(reg2_re),
                    .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),
                    .reg_we_o(id_reg_we_o), .reg_waddr_o(id_reg_waddr_o),
                    .alu_op_o(id_alu_op_o), .alu_sel_o(id_alu_sel_o),
                    .reg1_o(id_reg1_o), .reg2_o(id_reg2_o)
);

id_ex id_ex_conn(.clk(clk), .rst(rst),
                 .id_alu_op(id_alu_op_o), .id_alu_sel(id_alu_sel_o),
                 .id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
                 .id_reg_waddr(id_reg_waddr_o), .id_reg_we(id_reg_we_o),
                 .ex_alu_op(ex_alu_op_i), .ex_alu_sel(ex_alu_sel_i),
                 .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i),
                 .ex_reg_waddr(ex_reg_waddr_i), .ex_reg_we(ex_reg_we_i)
);

// execution
executor exec(.rst(rst), .alu_op_i(ex_alu_op_i), .alu_sel_i(ex_alu_sel_i),
              .reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i),
              .reg_waddr_i(ex_reg_waddr_i), .reg_we_i(ex_reg_we_i),
              .reg_waddr_o(ex_reg_waddr_o), .reg_we_o(ex_reg_we_o),
              .reg_wdata_o(ex_reg_wdata_o)
);

ex_mem ex_mem_main(.clk(clk), .rst(rst),
                   .ex_reg_waddr(ex_reg_waddr_o), .ex_reg_we(ex_reg_we_o),
                   .ex_reg_wdata(ex_reg_wdata_o),
                   .mem_reg_waddr(mem_reg_waddr_i), .mem_reg_we(mem_reg_we_i),
                   .mem_reg_wdata(mem_reg_wdata_i)
);

// memory and write back
mem memory(.rst(rst), 
           .reg_waddr_i(mem_reg_waddr_i), .reg_we_i(mem_reg_we_i),
           .reg_wdata_i(mem_reg_wdata_i),
           .reg_waddr_o(mem_reg_waddr_o), .reg_we_o(mem_reg_we_o),
           .reg_wdata_o(mem_reg_wdata_o)
);

mem_wb write_back(.clk(clk), .rst(rst),
                  .mem_reg_waddr(mem_reg_waddr_o), .mem_reg_we(mem_reg_we_o),
                  .mem_reg_wdata(mem_reg_wdata_o),
                  .wb_reg_waddr(wb_reg_waddr_i), .wb_reg_we(wb_reg_we_i),
                  .wb_reg_wdata(wb_reg_wdata_i)
);

endmodule

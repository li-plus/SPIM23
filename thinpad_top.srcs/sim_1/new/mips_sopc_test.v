`include "defines.vh"
`timescale 1ns/1ps

module openmips_min_sopc_tb();

  reg     CLOCK_50;
  reg     rst;
  
       
  initial begin
    CLOCK_50 = 1'b0;
    forever #10 CLOCK_50 = ~CLOCK_50;
  end
      
  initial begin
    rst = `RstEnable;
    #195 rst= `RstDisable;
  end
  
  wire[31:0] base_ram_data;
  wire[31:0] base_ram_addr;
  wire[3:0] base_ram_be_n;
  wire base_ram_oe_n;
  wire base_ram_we_n;
  
  wire[31:0] ext_ram_data;
  wire[31:0] ext_ram_addr;
  wire[3:0] ext_ram_be_n;
  wire ext_ram_ce_n;
  wire ext_ram_we_n;
  wire ext_ram_oe_n;
  
  inst_rom rom(
    .ce(~base_ram_oe_n),
    .addr(base_ram_addr),
    .inst(base_ram_data)
  );
  
  data_ram ram(
    .clk(CLOCK_50),
    .ce(~ext_ram_ce_n),
    .we(~ext_ram_we_n),
    .oe(~ext_ram_oe_n),
    .addr(ext_ram_addr),
    .sel(~ext_ram_be_n),
    .data(ext_ram_data)
  );
  
  openmips_min_sopc_wishbone sopc(
      .clk(CLOCK_50),
      .rst(rst),
      
      .base_ram_data(base_ram_data),
      .base_ram_addr(base_ram_addr),
      .base_ram_be_n(base_ram_be_n),
      .base_ram_oe_n(base_ram_oe_n),
      .base_ram_we_n(base_ram_we_n),
      
      .ext_ram_data(ext_ram_data),
      .ext_ram_addr(ext_ram_addr),
      .ext_ram_be_n(ext_ram_be_n),
      .ext_ram_ce_n(ext_ram_ce_n),
      .ext_ram_we_n(ext_ram_we_n),
      .ext_ram_oe_n(ext_ram_oe_n),
      
      .uart_rxd(),
      .uart_txd()
  );

endmodule

`include "defines.vh"
`timescale 1ns/1ps

module openmips_min_sopc_tb();

  reg     CLOCK_50;
  reg     rst;
  
       
  initial begin
    CLOCK_50 = 1'b0;
    forever #20 CLOCK_50 = ~CLOCK_50;
  end
      
  initial begin
    rst = `RstEnable;
    #195 rst= `RstDisable;
    `ifdef USE_CPLD_UART
    //#2000 cpld.pc_send_byte(8'hbe);
    `endif
  end
  
  wire[31:0] base_ram_data;
  wire[31:0] base_ram_addr;
  wire[3:0] base_ram_be_n;
  wire base_ram_oe_n;
  wire base_ram_we_n;
  wire base_ram_ce_n;
  
  wire[31:0] ext_ram_data;
  wire[31:0] ext_ram_addr;
  wire[3:0] ext_ram_be_n;
  wire ext_ram_ce_n;
  wire ext_ram_we_n;
  wire ext_ram_oe_n;
  
//  inst_rom rom(
//    .ce(~base_ram_oe_n),
//    .addr(base_ram_addr),
//    .inst(base_ram_data)
//  );

    data_ram ram(
        .clk(CLOCK_50),
        .ce(~base_ram_ce_n),
        .we(~base_ram_we_n),
        .oe(~base_ram_oe_n),
        .addr(base_ram_addr),
        .sel(~base_ram_be_n),
        .data(base_ram_data)
    );
    
    data_ram ext_ram(
        .clk(CLOCK_50),
        .ce(~ext_ram_ce_n),
        .we(~ext_ram_we_n),
        .oe(~ext_ram_oe_n),
        .addr(ext_ram_addr),
        .sel(~ext_ram_be_n),
        .data(ext_ram_data)
    );
  
//  sram_model ext1(
//              .DataIO(ext_ram_data[15:0]),
//              .Address(ext_ram_addr[19:0]),
//              .OE_n(ext_ram_oe_n),
//              .CE_n(ext_ram_ce_n),
//              .WE_n(ext_ram_we_n),
//              .LB_n(ext_ram_be_n[0]),
//              .UB_n(ext_ram_be_n[1]));
//  sram_model ext2(
//              .DataIO(ext_ram_data[31:16]),
//              .Address(ext_ram_addr[19:0]),
//              .OE_n(ext_ram_oe_n),
//              .CE_n(ext_ram_ce_n),
//              .WE_n(ext_ram_we_n),
//              .LB_n(ext_ram_be_n[2]),
//              .UB_n(ext_ram_be_n[3]));
  
  `ifdef USE_CPLD_UART
  wire uart_rdn;
  wire uart_wrn;
  wire uart_dataready;
  wire uart_tbre;
  wire uart_tsre;
  
  cpld_model cpld(
      .clk_uart(CLOCK_50),
      .uart_rdn(uart_rdn),
      .uart_wrn(uart_wrn),
      .uart_dataready(uart_dataready),
      .uart_tbre(uart_tbre),
      .uart_tsre(uart_tsre),
      .data(base_ram_data[7:0])
  );
  
  `endif
  
  openmips_min_sopc_wishbone sopc(
      .clk(CLOCK_50),
      .rst(rst),
      
      `ifdef USE_CPLD_UART
      .uart_tbre(uart_tbre),
      .uart_tsre(uart_tsre),
      .uart_data_ready(uart_dataready),
      .uart_rdn(uart_rdn),
      .uart_wrn(uart_wrn),
      `endif
      
      .base_ram_data(base_ram_data),
      .base_ram_addr(base_ram_addr),
      .base_ram_be_n(base_ram_be_n),
      .base_ram_oe_n(base_ram_oe_n),
      .base_ram_we_n(base_ram_we_n),
      .base_ram_ce_n(base_ram_ce_n),
      
      .ext_ram_data(ext_ram_data),
      .ext_ram_addr(ext_ram_addr),
      .ext_ram_be_n(ext_ram_be_n),
      .ext_ram_ce_n(ext_ram_ce_n),
      .ext_ram_we_n(ext_ram_we_n),
      .ext_ram_oe_n(ext_ram_oe_n)
  );

endmodule

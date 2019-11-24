`include "defines.vh"
`timescale 1ns/1ps

module openmips_min_sopc_tb();

  reg     clk_20M;
  reg     clk_50M;
  reg     rst;
  
  initial begin
    clk_20M = 1'b0;
    forever #25 clk_20M = ~clk_20M;
  end   

  initial begin
    clk_50M = 1'b0;
    forever #10 clk_50M = ~clk_50M;
  end
      
  initial begin
    rst = `RstEnable;
    #195 rst= `RstDisable;
    `ifdef USE_CPLD_UART
    //#2000 cpld.pc_send_byte(8'hbe);
    `endif
  end
  
  wire[31:0] base_ram_data;
  wire[19:0] base_ram_addr;
  wire[3:0] base_ram_be_n;
  wire base_ram_ce_n;
  wire base_ram_oe_n;
  wire base_ram_we_n;
  
  wire[31:0] ext_ram_data;
  wire[19:0] ext_ram_addr;
  wire[3:0] ext_ram_be_n;
  wire ext_ram_ce_n;
  wire ext_ram_we_n;
  wire ext_ram_oe_n;
  
  wire[2:0] video_red;
  wire[2:0] video_green;
  wire[1:0] video_blue;
  wire video_hsync;
  wire video_vsync;
  wire video_clk;
  wire video_de;

  wire[18:0] gram_addr_o;
  wire[31:0] gram_data_o;
  wire gram_we_n;

  // BaseRAM Model
  // inst_rom rom(
  //   .ce(~base_ram_oe_n),
  //   .addr(base_ram_addr),
  //   .inst(base_ram_data)
  // );
  data_ram ram(
    .clk(clk_50M),
    .ce(~base_ram_ce_n),
    .we(~base_ram_we_n),
    .oe(~base_ram_oe_n),
    .addr(base_ram_addr),
    .sel(~base_ram_be_n),
    .data(base_ram_data)
  );

  // ExtRAM model
  sram_model ext1(/*autoinst*/
            .DataIO(ext_ram_data[15:0]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[0]),
            .UB_n(ext_ram_be_n[1]));
  sram_model ext2(/*autoinst*/
            .DataIO(ext_ram_data[31:16]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[2]),
            .UB_n(ext_ram_be_n[3]));

  

  
  `ifdef USE_CPLD_UART
  wire uart_rdn;
  wire uart_wrn;
  wire uart_dataready;
  wire uart_tbre;
  wire uart_tsre;
  
  cpld_model cpld(
      .clk_uart(clk_50M),
      .uart_rdn(uart_rdn),
      .uart_wrn(uart_wrn),
      .uart_dataready(uart_dataready),
      .uart_tbre(uart_tbre),
      .uart_tsre(uart_tsre),
      .data(base_ram_data[7:0])
  );
  
  `endif
  
  openmips_min_sopc_wishbone sopc(
      .clk(clk_50M),
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
      .base_ram_ce_n(base_ram_ce_n),
      .base_ram_oe_n(base_ram_oe_n),
      .base_ram_we_n(base_ram_we_n),
      
      .ext_ram_data(ext_ram_data),
      .ext_ram_addr(ext_ram_addr),
      .ext_ram_be_n(ext_ram_be_n),
      .ext_ram_ce_n(ext_ram_ce_n),
      .ext_ram_we_n(ext_ram_we_n),
      .ext_ram_oe_n(ext_ram_oe_n),

      .gram_data_o(gram_data_o),
      .gram_addr_o(gram_addr_o),
      .gram_we_n(gram_we_n),

      .pc_o(pc),
      .inst_o(inst)
  );

  wire[18:0] gram_addr_i;
  wire[7:0] gram_data_i;
  assign video_red = gram_data_i[2:0];
  assign video_green = gram_data_i[5:3];
  assign video_blue = gram_data_i[7:6];

  wire[11:0] hdata;
  wire[11:0] vdata;

  vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
      .clk(clk_50M), 
      .hdata(hdata),
      .vdata(vdata),
      .hsync(video_hsync),
      .vsync(video_vsync),
      .data_enable(video_de),
      .addr(gram_addr_i)
  );

  graphic_ram gram(
      // write ports
      .addra(gram_addr_o),
      .clka(clk_50M),
      .dina(gram_data_o),
      .ena(1'b1),
      .wea(!gram_we_n), 
      // read ports
      .addrb(gram_addr_i), 
      .clkb(clk_50M), 
      .doutb(gram_data_i), 
      .enb(1'b1) 
  );

endmodule

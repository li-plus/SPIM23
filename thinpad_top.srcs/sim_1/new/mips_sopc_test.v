`include "defines.vh"
`timescale 1ns/1ps

module openmips_min_sopc_tb();

  reg     clk_20M;
  reg     clk_50M;
  reg     rst;
  
  reg[3:0] touch_btn;
  
  initial begin
    clk_50M = 1'b0;
    forever #20 clk_50M = ~clk_50M;
  end
      
  initial begin
    rst = `RstEnable;
    #195 rst= `RstDisable;
    touch_btn = 4'b0000;
    #1166 touch_btn = 4'b0001;
    #1180 touch_btn = 4'b0000;
    
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

  wire [22:0]flash_a;
  wire [15:0]flash_d;
  wire flash_rp_n;
  wire flash_vpen;
  wire flash_ce_n;
  wire flash_oe_n;
  wire flash_we_n;
  wire flash_byte_n;

//  inst_rom rom(
//    .ce(~base_ram_oe_n),
//    .addr(base_ram_addr),
//    .inst(base_ram_data)
//  );

  data_ram ram(
      .clk(clk_50M),
      .ce(~base_ram_ce_n),
      .we(~base_ram_we_n),
      .oe(~base_ram_oe_n),
      .addr(base_ram_addr),
      .sel(~base_ram_be_n),
      .data(base_ram_data)
  );

  reg[`InstBus] inst_mem[0: `DataMemNum - 1];
  integer i;

  initial begin
    $readmemh ("E:\\program\\cpu\\inst_rom.data", inst_mem);
    for(i = 0; i < `DataMemNum; i = i + 1) begin
      ram.data_mem3[i] <= inst_mem[i][31:24];
      ram.data_mem2[i] <= inst_mem[i][23:16];
      ram.data_mem1[i] <= inst_mem[i][15:8];
      ram.data_mem0[i] <= inst_mem[i][7:0];
    end
  end

  sram_model ext1(
              .DataIO(ext_ram_data[15:0]),
              .Address(ext_ram_addr[19:0]),
              .OE_n(ext_ram_oe_n),
              .CE_n(ext_ram_ce_n),
              .WE_n(ext_ram_we_n),
              .LB_n(ext_ram_be_n[0]),
              .UB_n(ext_ram_be_n[1]));
  sram_model ext2(
              .DataIO(ext_ram_data[31:16]),
              .Address(ext_ram_addr[19:0]),
              .OE_n(ext_ram_oe_n),
              .CE_n(ext_ram_ce_n),
              .WE_n(ext_ram_we_n),
              .LB_n(ext_ram_be_n[2]),
              .UB_n(ext_ram_be_n[3]));

  // load ExtRAM from file
  reg   [31:0] tmp_array[0:1048575];
  integer n_File_ID;
  integer n_Init_Size;
  parameter EXT_RAM_INIT_FILE = "E:\\program\\cpu\\cod19grp51\\thinpad_top.srcs\\sources_1\\new\\demo\\pic.bin";
  initial begin 
    n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open ExtRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size = n_Init_Size / 4;
        $fclose(n_File_ID);
    end
    $display("ExtRAM Init Size(words): %d",n_Init_Size);
    for (i = 0; i < n_Init_Size; i = i + 1) begin
        ext1.mem_array0[i] = tmp_array[i][24+:8];
        ext1.mem_array1[i] = tmp_array[i][16+:8];
        ext2.mem_array0[i] = tmp_array[i][8+:8];
        ext2.mem_array1[i] = tmp_array[i][0+:8];
    end
  end

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

  // Flash model
  parameter FLASH_INIT_FILE = "E:\\program\\cpu\\cod19grp51\\thinpad_top.srcs\\sources_1\\new\\demo\\pic.bin";
  x28fxxxp30 #(.FILENAME_MEM(FLASH_INIT_FILE)) flash(
    .A(flash_a[1+:22]), 
    .DQ(flash_d), 
    .W_N(flash_we_n),    // Write Enable 
    .G_N(flash_oe_n),    // Output Enable
    .E_N(flash_ce_n),    // Chip Enable
    .L_N(1'b0),    // Latch Enable
    .K(1'b0),      // Clock
    .WP_N(flash_vpen),   // Write Protect
    .RP_N(flash_rp_n),   // Reset/Power-Down
    .VDD('d3300), 
    .VDDQ('d3300), 
    .VPP('d1800), 
    .Info(1'b1));

  // user design

  wire[18:0] gram_addr_o;
  wire[7:0] gram_data_o;
  wire gram_we_n;
  
  wire[31:0] gpio_i;
 
  assign gpio_i = {28'h0000000, touch_btn};

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

      .flash_a(flash_a),
      .flash_d(flash_d),
      .flash_rp_n(flash_rp_n),
      .flash_vpen(flash_vpen),
      .flash_ce_n(flash_ce_n),
      .flash_oe_n(flash_oe_n),
      .flash_we_n(flash_we_n),
      .flash_byte_n(flash_byte_n),
      
      .gpio_i(gpio_i)
  );

wire[11:0] hdata;
wire[11:0] vdata;

wire[18:0] gram_addr_i;
wire[7:0] gram_data_i;
assign video_red = gram_data_i[2:0];
assign video_green = gram_data_i[5:3];
assign video_blue = gram_data_i[7:6];
assign video_clk = clk_50M;

vga #(.WIDTH(12), .HSIZE(800), .HFP(856), .HSP(976), .HMAX(1040), 
    .VSIZE(600), .VFP(637), .VSP(643), .VMAX(666), .HSPP(1), .VSPP(1)) vga800x600at75 (
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
    .wea(~gram_we_n),
    // read ports
    .addrb(gram_addr_i), 
    .clkb(clk_50M), 
    .doutb(gram_data_i), 
    .enb(1'b1) 
);

endmodule

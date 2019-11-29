`default_nettype none
`include "defines.vh"

module thinpad_top(
    input wire clk_50M,           //50MHz
    input wire clk_11M0592,       //11.0592MHz

    input wire clock_btn,         //BTN5
    input wire reset_btn,         //BTN6

    input  wire[3:0]  touch_btn,  //BTN1~BTN4
    input  wire[31:0] dip_sw,
    output wire[15:0] leds,
    output wire[7:0]  dpy0,       // display lower bits
    output wire[7:0]  dpy1,       // display higher bits

    //CPLD Serial
    output wire uart_rdn,
    output wire uart_wrn,
    input wire uart_dataready,
    input wire uart_tbre,         // send
    input wire uart_tsre,         // send ok

    //BaseRAM
    inout wire[31:0] base_ram_data,
    output wire[19:0] base_ram_addr,
    output wire[3:0] base_ram_be_n,  // byte enable
    output wire base_ram_ce_n,
    output wire base_ram_oe_n,
    output wire base_ram_we_n,

    //ExtRAM
    inout wire[31:0] ext_ram_data,
    output wire[19:0] ext_ram_addr,
    output wire[3:0] ext_ram_be_n,  // byte enable
    output wire ext_ram_ce_n,
    output wire ext_ram_oe_n,
    output wire ext_ram_we_n,

    // Direct serial
    output wire txd,  // transceiver
    input  wire rxd,  // receiver

    //Flash JS28F640 
    output wire [22:0]flash_a,      //Flash addr
    inout  wire [15:0]flash_d,      //Flash data
    output wire flash_rp_n,         //Flash reset
    output wire flash_vpen,         //Flash write protect
    output wire flash_ce_n,
    output wire flash_oe_n,
    output wire flash_we_n,
    output wire flash_byte_n,       //Flash 8 bit enable

    //USB controller SL811
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB shared bus with dm9k_sd[7:0]
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //Ethernet controller DM9000A
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //VGA output
    output wire[2:0] video_red,
    output wire[2:0] video_green,
    output wire[1:0] video_blue,
    output wire video_hsync,       // horizontal sync
    output wire video_vsync,       // vertical sync
    output wire video_clk,         // pixel clk
    output wire video_de           // horizontal valid
);

wire[18:0] gram_addr_o;
wire[7:0] gram_data_o;
wire gram_we_n;
wire gram_ce_n;

wire clk_60M, clk_main;
wire locked;

pll_example clock_gen 
(
    // Clock out ports
    .clk_out1(clk_60M),
    .clk_out2(clk_main),

    // Status and control signals
    .reset(reset_btn),
    .locked(locked),
    // Clock in ports
    .clk_in1(clk_50M)
);

wire[31:0] gpio_o;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(gpio_o[3:0]));
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(gpio_o[7:4]));
assign leds = gpio_o[23:8];
wire[31:0] gpio_i;
assign gpio_i = {28'h0000000, touch_btn};

openmips_min_sopc_wishbone sopc(
    .clk(clk_main),
    .rst(~locked),
    
    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_be_n(base_ram_be_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    .base_ram_ce_n(base_ram_ce_n),
    
    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_be_n(ext_ram_be_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),
    .ext_ram_ce_n(ext_ram_ce_n),
    
    `ifdef USE_CPLD_UART
    .uart_tbre(uart_tbre),
    .uart_tsre(uart_tsre),
    .uart_data_ready(uart_dataready),
    .uart_rdn(uart_rdn),
    .uart_wrn(uart_wrn),
    `else
    .uart_rxd(rxd),
    .uart_txd(txd),
    `endif
    
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
    
    .usb_a0(sl811_a0),
    .usb_data(dm9k_sd[7:0]),
    .usb_wr_n(sl811_wr_n),
    .usb_rd_n(sl811_rd_n),
    .usb_cs_n(sl811_cs_n),
    .usb_rst_n(sl811_rst_n),
    .usb_dack_n(sl811_dack_n),
    .usb_intrq(sl811_intrq),
    .usb_drq_n(sl811_drq_n),
    
    .gpio_i(gpio_i),
    .gpio_o(gpio_o)
);

wire[11:0] hdata;
wire[11:0] vdata;

wire[18:0] gram_addr_i;
wire[7:0] gram_data_i;
assign video_red = gram_data_i[2:0];
assign video_green = gram_data_i[5:3];
assign video_blue = gram_data_i[7:6];
assign video_clk = clk_main;

vga #(.WIDTH(12), .HSIZE(800), .HFP(856), .HSP(976), .HMAX(1040), 
    .VSIZE(600), .VFP(637), .VSP(643), .VMAX(666), .HSPP(1), .VSPP(1)) vga800x600at75 (
    .clk(clk_main), 
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
    .clka(clk_main),
    .dina(gram_data_o),
    .ena(1'b1),
    .wea(~gram_we_n),
    // read ports
    .addrb(gram_addr_i), 
    .clkb(clk_main), 
    .doutb(gram_data_i), 
    .enb(1'b1) 
);

endmodule

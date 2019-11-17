`default_nettype none

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

wire clk_10M, clk_20M;
wire locked;

pll_example clock_gen 
(
    // Clock out ports
    .clk_out1(clk_10M),
    .clk_out2(clk_20M),

    // Status and control signals
    .reset(reset_btn),
    .locked(locked),
    // Clock in ports
    .clk_in1(clk_50M)
);

wire[31:0] pc;
wire[31:0] inst;

assign leds = base_ram_addr[15:0];
wire[7:0] number;
assign number = inst[31:24];
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0]));
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4]));

openmips_min_sopc_wishbone sopc(
    .clk(clk_20M),
    .rst(reset_btn),
    
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
    
    .uart_rxd(rxd),
    .uart_txd(txd),
    
    .pc_o(pc),
    .inst_o(inst)
);


endmodule

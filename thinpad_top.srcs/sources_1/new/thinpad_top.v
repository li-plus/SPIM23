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
wire[31:0] gram_data_o;
wire gram_we_n;

wire clk_10M, clk_20M;
wire locked;

pll_example clock_gen 
(
    // Clock out ports
    .clk_out1(clk_10M),
    .clk_out2(clk_20M),

    // Status and control signals
    .reset(`False),
    .locked(locked),
    // Clock in ports
    .clk_in1(clk_50M)
);

wire[31:0] pc;
wire[31:0] inst;
wire[7:0] number;
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

    .pc_o(pc),
    .inst_o(inst)
    `ifdef DEBUG
    ,.r1_o({number, 8'hzz, leds[15:1], 1'hz}),
    .uart_int_o(leds[0])
    `endif
);


// vga demo
/*
assign uart_rdn = 1;
assign uart_wrn = 1;

wire[7:0] video_pixel;
assign video_red = video_pixel[2:0];
assign video_green = video_pixel[5:3];
assign video_blue = video_pixel[7:6];
assign video_clk = clk_50M;
wire[18:0] gaddr_r;

wire gram_ce;
reg gram_we = 1'b1;
assign gram_ce = 1'b1;

reg[19:0] addr = 20'b0;
assign base_ram_addr = addr;
reg oe, ce, we;
assign base_ram_ce_n = ce;
assign base_ram_oe_n = oe;
assign base_ram_we_n = we;
assign base_ram_data = 32'hzzzzzzzz;
assign base_ram_be_n = 4'b0000;

reg[31:0] data_in;
reg[1:0] state = 2'h0;

always @ (posedge clk_50M) begin
    oe <= 0;
    ce <= 0;
    we <= 1;
    case (state)
        2'h0: begin
            state <= 2'h1;
            data_in <= base_ram_data;
        end
        2'h1: begin
            state <= 2'h0;
            if (addr < 120000) begin
                addr <= addr + 1;
            end else begin 
                addr <= 0;
            end
        end
    endcase
end

wire[11:0] hdata;
wire[11:0] vdata;

graphic_ram gram(
    // write ports
    .addra(addr),
    .clka(clk_50M), 
    .dina(data_in),
    .ena(gram_ce), 
    .wea(gram_we), 
    // read ports
    .addrb(gaddr_r), 
    .clkb(clk_50M), 
    .doutb(video_pixel), 
    .enb(gram_ce) 
);*/

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
    .clka(clk_20M),
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

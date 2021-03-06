`include "defines.vh"

module openmips_min_sopc_wishbone(
	input wire clk,
	input wire rst,
	
	// baseRAM
    inout wire[31:0] base_ram_data,
    output wire[19:0] base_ram_addr,
    output wire[3:0] base_ram_be_n,
    output wire base_ram_ce_n,
    output wire base_ram_oe_n,
    output wire base_ram_we_n,

    // ExtRAM
    inout wire[31:0] ext_ram_data,
    output wire[19:0] ext_ram_addr,
    output wire[3:0] ext_ram_be_n,
    output wire ext_ram_ce_n,
    output wire ext_ram_oe_n,
    output wire ext_ram_we_n,
    
`ifdef USE_CPLD_UART
    input wire uart_tbre,
    input wire uart_tsre,
    input wire uart_data_ready,
    output wire uart_rdn,
    output wire uart_wrn,
`else
    // Uart
    input wire uart_rxd,
    output wire uart_txd,
`endif
    
    // VGA
    output wire[7:0] gram_data_o,
	output wire[18:0] gram_addr_o,
	output wire gram_we_n,

	// Flash
    output wire [22:0]flash_a,      //Flash addr
    inout  wire [15:0]flash_d,      //Flash data
    output wire flash_rp_n,         //Flash reset
    output wire flash_vpen,         //Flash write protect
    output wire flash_ce_n,
    output wire flash_oe_n,
    output wire flash_we_n,
    output wire flash_byte_n,       //Flash 8 bit enable
    
    // GPIO
    input wire [31:0]   gpio_i,
    output wire [31:0] gpio_o,
    
    
    // USB
    output wire usb_a0,
    inout  wire[7:0] usb_data,
    output wire usb_wr_n,
    output wire usb_rd_n,
    output wire usb_cs_n,
    output wire usb_rst_n,
    output wire usb_dack_n,
    input  wire usb_intrq,
    input  wire usb_drq_n,

    output wire[`InstAddrBus] pc_o,
    output wire[`InstBus] inst_o
);

    wire[7:0] int;
    wire timer_int;
    wire gpio_int;
  
    // master
    wire[31:0] m0_data_i;
    wire[31:0] m0_data_o;
    wire[31:0] m0_addr_i;
    wire[3:0]  m0_sel_i;
    wire       m0_we_i;
    wire       m0_cyc_i;
    wire       m0_stb_i;
    wire       m0_ack_o;

    // slave
    wire[31:0] m1_data_i;
    wire[31:0] m1_data_o;
    wire[31:0] m1_addr_i;
    wire[3:0]  m1_sel_i;
    wire       m1_we_i;
    wire       m1_cyc_i;
    wire       m1_stb_i;
    wire       m1_ack_o;

	wire[31:0] s0_data_i;
	wire[31:0] s0_data_o;
	wire[31:0] s0_addr_o;
	wire[3:0]  s0_sel_o;
	wire       s0_we_o; 
	wire       s0_cyc_o; 
	wire       s0_stb_o;
	wire       s0_ack_i;

	wire[31:0] s1_data_i;
	wire[31:0] s1_data_o;
	wire[31:0] s1_addr_o;
	wire[3:0]  s1_sel_o;
	wire       s1_we_o; 
	wire       s1_cyc_o; 
	wire       s1_stb_o;
	wire       s1_ack_i;
  
	wire[31:0] s2_data_i;
	wire[31:0] s2_data_o;
	wire[31:0] s2_addr_o;
	wire[3:0]  s2_sel_o;
	wire       s2_we_o; 
	wire       s2_cyc_o; 
	wire       s2_stb_o;
	wire       s2_ack_i;
	
	wire[31:0] s3_data_i;
	wire[31:0] s3_data_o;
	wire[31:0] s3_addr_o;
	wire[3:0]  s3_sel_o;
	wire       s3_we_o; 
	wire       s3_cyc_o; 
	wire       s3_stb_o;
	wire       s3_ack_i;
 
	wire[31:0] s4_data_i;
	wire[31:0] s4_data_o;
	wire[31:0] s4_addr_o;
	wire[3:0]  s4_sel_o;
	wire       s4_we_o; 
	wire       s4_cyc_o; 
	wire       s4_stb_o;
	wire       s4_ack_i;
	
    wire[31:0] s5_data_i;
    wire[31:0] s5_addr_o;
    wire       s5_cyc_o; 
    wire       s5_stb_o;
    wire       s5_ack_i;
    
    wire[31:0] s6_data_i;
    wire[31:0] s6_data_o;
    wire[31:0] s6_addr_o;
    wire[3:0]  s6_sel_o;
    wire       s6_we_o; 
    wire       s6_cyc_o; 
    wire       s6_stb_o;
    wire       s6_ack_i;
    
    wire[31:0] s7_data_i;
    wire[31:0] s7_data_o;
    wire[31:0] s7_addr_o;
    wire       s7_we_o; 
    wire       s7_cyc_o;
    wire       s7_stb_o;
    wire       s7_ack_i;

 wire uart_int;
 
 assign int = {2'b00, usb_intrq, uart_int, gpio_int, timer_int};
 // IRQ 2: timer, 3: GPIO, 4: UART, 5: USB
 
 `ifdef USE_CPLD_UART
 wire stall_base_ram;
 wire idle_base_ram;
 `endif
 
 openmips_wishbone openmips0(
    .clk(clk),
    .rst(rst),

    .iwishbone_data_i(m1_data_o),
    .iwishbone_ack_i(m1_ack_o),
    .iwishbone_addr_o(m1_addr_i),
    .iwishbone_data_o(m1_data_i),
    .iwishbone_we_o(m1_we_i),
    .iwishbone_sel_o(m1_sel_i),
    .iwishbone_stb_o(m1_stb_i),
    .iwishbone_cyc_o(m1_cyc_i), 

    .int_i(int),

    .dwishbone_data_i(m0_data_o),
    .dwishbone_ack_i(m0_ack_o),
    .dwishbone_addr_o(m0_addr_i),
    .dwishbone_data_o(m0_data_i),
    .dwishbone_we_o(m0_we_i),
    .dwishbone_sel_o(m0_sel_i),
    .dwishbone_stb_o(m0_stb_i),
    .dwishbone_cyc_o(m0_cyc_i),
    
    `ifdef USE_CPLD_UART
    .stallreq_from_uart(stall_base_ram),
    `endif

    .timer_int_o(timer_int)
);


/******* Peripherals   ********/

// 0 - BaseRAM
sram_controller base_ram_ctrl(
    .wb_clk_i(clk),
    .wb_rst_i(rst),
    
    .wb_dat_i(s0_data_o),
    .wb_adr_i(s0_addr_o),
    .wb_sel_i(s0_sel_o),
    .wb_we_i(s0_we_o),
    .wb_cyc_i(s0_cyc_o),
    .wb_stb_i(s0_stb_o),
    `ifdef USE_CPLD_UART
    .idle(idle_base_ram),
    `endif
    .wb_dat_o(s0_data_i),
    .wb_ack_o(s0_ack_i),
    .SRAM_DQ(base_ram_data),
    .SRAM_ADDR(base_ram_addr),
    .SRAM_BE_N(base_ram_be_n),
    .SRAM_CE_N(base_ram_ce_n),
    .SRAM_OE_N(base_ram_oe_n),
    .SRAM_WE_N(base_ram_we_n)
);

// 1 - ExtRAM
sram_controller ext_ram_ctrl(
    .wb_clk_i(clk),
    .wb_rst_i(rst),
    
    .wb_dat_i(s1_data_o),
    .wb_adr_i(s1_addr_o),
    .wb_sel_i(s1_sel_o),
    .wb_we_i(s1_we_o),
    .wb_cyc_i(s1_cyc_o),
    .wb_stb_i(s1_stb_o),
    .wb_dat_o(s1_data_i),
    .wb_ack_o(s1_ack_i),
    .SRAM_DQ(ext_ram_data),
    .SRAM_ADDR(ext_ram_addr),
    .SRAM_BE_N(ext_ram_be_n),
    .SRAM_CE_N(ext_ram_ce_n),
    .SRAM_OE_N(ext_ram_oe_n),
    .SRAM_WE_N(ext_ram_we_n)
);

wire[31:0] uart_addr;
wire[31:0] uart_data;

`ifdef USE_CPLD_UART
// 2 - CPLD Uart
cpld_uart_controller uart_ctrl(
    .wb_clk_i(clk),
    .wb_rst_i(rst),
    
    .wb_adr_i(uart_addr),
    .wb_dat_i(s2_data_o),
    .wb_dat_o(uart_data),
    .wb_we_i(s2_we_o),
    .wb_stb_i(s2_stb_o), 
    .wb_cyc_i(s2_cyc_o),
    .wb_ack_o(s2_ack_i),
    
    .int_o(uart_int),
    .data_bus(base_ram_data[7:0]),
    .tbre_i(uart_tbre),
    .tsre_i(uart_tsre),
    .data_ready_i(uart_data_ready),
    .wrn_o(uart_wrn),
    .rdn_o(uart_rdn),
    .stall_o(stall_base_ram),
    .idle_i(idle_base_ram)
);
`else
// 2 - Uart
uart_controller uart_ctrl(
    .wb_clk_i(clk),
    .wb_rst_i(rst),
    .wb_adr_i(uart_addr),
    .wb_dat_i(s2_data_o),
    .wb_dat_o(uart_data), 
    .wb_we_i(s2_we_o), 
    .wb_stb_i(s2_stb_o), 
    .wb_cyc_i(s2_cyc_o),
    .wb_ack_o(s2_ack_i),
    .int_o(uart_int),
    
    .uart_rxd(uart_rxd),
    .uart_txd(uart_txd)
);
`endif

uart_wrapper uart_adapter(
    .uart_addr_i(s2_addr_o),
    .uart_addr_o(uart_addr), // MMU addr -> Uart addr
    .uart_data_i(uart_data),
    .uart_data_o(s2_data_i) // Uart data -> CPU data
);

// 3 - VGA
gram_controller gram_ctrl(
    // clk signals
    .wb_clk_i(clk),
    .wb_rst_i(rst),

    // WB slave if
    .wb_dat_i(s3_data_o),
    .wb_dat_o(s3_data_i),
    .wb_adr_i(s3_addr_o),
	.wb_sel_i(s3_sel_o),
    .wb_we_i(s3_we_o),
    .wb_cyc_i(s3_cyc_o),
	.wb_stb_i(s3_stb_o),
	.wb_ack_o(s3_ack_i),

    // GRAM if
    .GRAM_DATA(gram_data_o),
    .GRAM_ADDR(gram_addr_o),
    .GRAM_WE_N(gram_we_n),
//	.GRAM_CE_N(gram_ce_n),
    .idle()
);

// 4 - Flash
flash_controller flash_ctrl(
	.wb_clk_i(clk),
	.wb_rst_i(rst), 

	.wb_dat_i(s4_data_o), 
	.wb_dat_o(s4_data_i), 
	.wb_adr_i(s4_addr_o),
	.wb_sel_i(s4_sel_o),
	.wb_we_i(s4_we_o),
	.wb_cyc_i(s4_cyc_o), 
	.wb_stb_i(s4_stb_o), 
	.wb_ack_o(s4_ack_i),

	.FLASH_DQ(flash_d),
	.FLASH_ADDR(flash_a),
	.FLASH_CE_N(flash_ce_n),
	.FLASH_OE_N(flash_oe_n),
	.FLASH_WE_N(flash_we_n),
	.FLASH_RP_N(flash_rp_n),
	.FLASH_VPEN(flash_vpen),
	.FLASH_BYTE_N(flash_byte_n),

	.idle()
);


// 5 - BootROM
bootrom_controller bootrom(
	.wb_rst_i(rst),
	.wb_dat_o(s5_data_i),
	.wb_adr_i(s5_addr_o),
	.wb_cyc_i(s5_cyc_o), 
	.wb_stb_i(s5_stb_o), 
	.wb_ack_o(s5_ack_i)
);

// 6 - GPIO
gpio_controller gpio_ctrl(
    .wb_clk_i(clk),
    .wb_rst_i(rst), 
    .wb_cyc_i(s6_cyc_o),
    .wb_adr_i(s6_addr_o[7:0]),
    .wb_dat_i(s6_data_o),
    .wb_sel_i(s6_sel_o),
    .wb_we_i(s6_we_o),
    .wb_stb_i(s6_stb_o),
    .wb_dat_o(s6_data_i),
    .wb_ack_o(s6_ack_i),
    .wb_err_o(),
    .wb_inta_o(gpio_int),
    .ext_pad_i(gpio_i),
    .ext_pad_o(gpio_o),
    .ext_padoe_o()
);

// 7 - USB
usb_controller usb_ctrl(
    .wb_clk_i(clk),
    .wb_rst_i(rst),
    
    .wb_dat_i(s7_data_o), 
    .wb_dat_o(s7_data_i), 
    .wb_adr_i(s7_addr_o),
    .wb_we_i(s7_we_o),
    .wb_cyc_i(s7_cyc_o), 
    .wb_stb_i(s7_stb_o), 
    .wb_ack_o(s7_ack_i),

    .usb_a0(usb_a0),
    .usb_data(usb_data),
    .usb_wr_n(usb_wr_n),
    .usb_rd_n(usb_rd_n),
    .usb_cs_n(usb_cs_n),
    .usb_rst_n(usb_rst_n),
    .usb_dack_n(usb_dack_n),
    .usb_drq_n(usb_drq_n)
);

// Wishbone InterConn Matrix

wb_conmax_top wb_conmax_top0(
     	.clk_i(clk),
     	.rst_i(rst),

	    // Master 0 Interface
	    .m0_data_i(m0_data_i),
	    .m0_data_o(m0_data_o),
	    .m0_addr_i(m0_addr_i),
	    .m0_sel_i(m0_sel_i),
	    .m0_we_i(m0_we_i), 
	    .m0_cyc_i(m0_cyc_i), 
	    .m0_stb_i(m0_stb_i),
	    .m0_ack_o(m0_ack_o), 

	    // Master 1 Interface
	    .m1_data_i(m1_data_i),
	    .m1_data_o(m1_data_o),
	    .m1_addr_i(m1_addr_i),
	    .m1_sel_i(m1_sel_i),
	    .m1_we_i(m1_we_i), 
	    .m1_cyc_i(m1_cyc_i), 
	    .m1_stb_i(m1_stb_i),
	    .m1_ack_o(m1_ack_o), 

	    // Master 2 Interface
	    .m2_data_i(`ZeroWord),
	    .m2_data_o(),
	    .m2_addr_i(`ZeroWord),
	    .m2_sel_i(4'b0000),
	    .m2_we_i(1'b0), 
	    .m2_cyc_i(1'b0), 
	    .m2_stb_i(1'b0),
	    .m2_ack_o(), 
	    .m2_err_o(), 
	    .m2_rty_o(),

	    // Master 3 Interface
	    .m3_data_i(`ZeroWord),
	    .m3_data_o(),
	    .m3_addr_i(`ZeroWord),
	    .m3_sel_i(4'b0000),
	    .m3_we_i(1'b0), 
	    .m3_cyc_i(1'b0), 
	    .m3_stb_i(1'b0),
	    .m3_ack_o(), 
	    .m3_err_o(), 
	    .m3_rty_o(),

	    // Master 4 Interface
	    .m4_data_i(`ZeroWord),
	    .m4_data_o(),
	    .m4_addr_i(`ZeroWord),
	    .m4_sel_i(4'b0000),
	    .m4_we_i(1'b0), 
	    .m4_cyc_i(1'b0), 
	    .m4_stb_i(1'b0),
	    .m4_ack_o(), 
	    .m4_err_o(), 
	    .m4_rty_o(),

	    // Master 5 Interface
	    .m5_data_i(`ZeroWord),
	    .m5_data_o(),
	    .m5_addr_i(`ZeroWord),
	    .m5_sel_i(4'b0000),
	    .m5_we_i(1'b0), 
	    .m5_cyc_i(1'b0), 
	    .m5_stb_i(1'b0),
	    .m5_ack_o(), 
	    .m5_err_o(), 
	    .m5_rty_o(),

	    // Master 6 Interface
	    .m6_data_i(`ZeroWord),
	    .m6_data_o(),
	    .m6_addr_i(`ZeroWord),
	    .m6_sel_i(4'b0000),
	    .m6_we_i(1'b0), 
	    .m6_cyc_i(1'b0), 
	    .m6_stb_i(1'b0),
	    .m6_ack_o(), 
	    .m6_err_o(), 
	    .m6_rty_o(),

	    // Master 7 Interface
	    .m7_data_i(`ZeroWord),
	    .m7_data_o(),
	    .m7_addr_i(`ZeroWord),
	    .m7_sel_i(4'b0000),
	    .m7_we_i(1'b0), 
	    .m7_cyc_i(1'b0), 
	    .m7_stb_i(1'b0),
	    .m7_ack_o(), 
	    .m7_err_o(), 
	    .m7_rty_o(),

	    // Slave 0 Interface
	    .s0_data_i(s0_data_i),
	    .s0_data_o(s0_data_o),
	    .s0_addr_o(s0_addr_o),
	    .s0_sel_o(s0_sel_o),
	    .s0_we_o(s0_we_o), 
	    .s0_cyc_o(s0_cyc_o), 
	    .s0_stb_o(s0_stb_o),
	    .s0_ack_i(s0_ack_i), 
	    .s0_err_i(1'b0), 
	    .s0_rty_i(1'b0),

	    // Slave 1 Interface
	    .s1_data_i(s1_data_i),
	    .s1_data_o(s1_data_o),
	    .s1_addr_o(s1_addr_o),
	    .s1_sel_o(s1_sel_o),
	    .s1_we_o(s1_we_o), 
	    .s1_cyc_o(s1_cyc_o), 
	    .s1_stb_o(s1_stb_o),
	    .s1_ack_i(s1_ack_i), 
	    .s1_err_i(1'b0), 
	    .s1_rty_i(1'b0),

	    // Slave 2 Interface
	    .s2_data_i(s2_data_i),
	    .s2_data_o(s2_data_o),
	    .s2_addr_o(s2_addr_o),
	    .s2_sel_o(s2_sel_o),
	    .s2_we_o(s2_we_o), 
	    .s2_cyc_o(s2_cyc_o), 
	    .s2_stb_o(s2_stb_o),
	    .s2_ack_i(s2_ack_i), 
	    .s2_err_i(1'b0), 
	    .s2_rty_i(1'b0),

	    // Slave 3 Interface
	    .s3_data_i(s3_data_i),
	    .s3_data_o(s3_data_o),
	    .s3_addr_o(s3_addr_o),
	    .s3_sel_o(s3_sel_o),
	    .s3_we_o(s3_we_o), 
	    .s3_cyc_o(s3_cyc_o), 
	    .s3_stb_o(s3_stb_o),
	    .s3_ack_i(s3_ack_i),
	    .s3_err_i(1'b0), 
	    .s3_rty_i(1'b0),

	    // Slave 4 Interface
	    .s4_data_i(s4_data_i),
	    .s4_data_o(s4_data_o),
	    .s4_addr_o(s4_addr_o),
	    .s4_sel_o(s4_sel_o),
	    .s4_we_o(s4_we_o), 
	    .s4_cyc_o(s4_cyc_o), 
	    .s4_stb_o(s4_stb_o),
	    .s4_ack_i(s4_ack_i), 
	    .s4_err_i(1'b0), 
	    .s4_rty_i(1'b0),

	    // Slave 5 Interface
	    .s5_data_i(s5_data_i),
	    .s5_data_o(),
	    .s5_addr_o(s5_addr_o),
	    .s5_sel_o(),
	    .s5_we_o(), 
	    .s5_cyc_o(s5_cyc_o), 
	    .s5_stb_o(s5_stb_o),
	    .s5_ack_i(s5_ack_i), 
	    .s5_err_i(1'b0),
	    .s5_rty_i(1'b0),

	    // Slave 6 Interface
	    .s6_data_i(s6_data_i),
	    .s6_data_o(s6_data_o),
	    .s6_addr_o(s6_addr_o),
	    .s6_sel_o(s6_sel_o),
	    .s6_we_o(s6_we_o), 
	    .s6_cyc_o(s6_cyc_o), 
	    .s6_stb_o(s6_stb_o),
	    .s6_ack_i(s6_ack_i), 
	    .s6_err_i(1'b0), 
	    .s6_rty_i(1'b0),

	    // Slave 7 Interface
	    .s7_data_i(s7_data_i),
	    .s7_data_o(s7_data_o),
	    .s7_addr_o(s7_addr_o),
	    .s7_sel_o(),
	    .s7_we_o(s7_we_o), 
	    .s7_cyc_o(s7_cyc_o), 
	    .s7_stb_o(s7_stb_o),
	    .s7_ack_i(s7_ack_i), 
	    .s7_err_i(1'b0), 
	    .s7_rty_i(1'b0),

	    // Slave 8 Interface
	    .s8_data_i(),
	    .s8_data_o(),
	    .s8_addr_o(),
	    .s8_sel_o(),
	    .s8_we_o(), 
	    .s8_cyc_o(), 
	    .s8_stb_o(),
	    .s8_ack_i(1'b0), 
	    .s8_err_i(1'b0), 
	    .s8_rty_i(1'b0),

	    // Slave 9 Interface
	    .s9_data_i(),
	    .s9_data_o(),
	    .s9_addr_o(),
	    .s9_sel_o(),
	    .s9_we_o(), 
	    .s9_cyc_o(), 
	    .s9_stb_o(),
	    .s9_ack_i(1'b0), 
	    .s9_err_i(1'b0), 
	    .s9_rty_i(1'b0),

	    // Slave 10 Interface
	    .s10_data_i(),
	    .s10_data_o(),
	    .s10_addr_o(),
	    .s10_sel_o(),
	    .s10_we_o(), 
	    .s10_cyc_o(), 
	    .s10_stb_o(),
	    .s10_ack_i(1'b0), 
	    .s10_err_i(1'b0), 
	    .s10_rty_i(1'b0),

	    // Slave 11 Interface
	    .s11_data_i(),
	    .s11_data_o(),
	    .s11_addr_o(),
	    .s11_sel_o(),
	    .s11_we_o(), 
	    .s11_cyc_o(), 
	    .s11_stb_o(),
	    .s11_ack_i(1'b0), 
	    .s11_err_i(1'b0), 
	    .s11_rty_i(1'b0),

	    // Slave 12 Interface
	    .s12_data_i(),
	    .s12_data_o(),
	    .s12_addr_o(),
	    .s12_sel_o(),
	    .s12_we_o(), 
	    .s12_cyc_o(), 
	    .s12_stb_o(),
	    .s12_ack_i(1'b0), 
	    .s12_err_i(1'b0), 
	    .s12_rty_i(1'b0),

	    // Slave 13 Interface
	    .s13_data_i(),
	    .s13_data_o(),
	    .s13_addr_o(),
	    .s13_sel_o(),
	    .s13_we_o(), 
	    .s13_cyc_o(), 
	    .s13_stb_o(),
	    .s13_ack_i(1'b0), 
	    .s13_err_i(1'b0), 
	    .s13_rty_i(1'b0),

	    // Slave 14 Interface
	    .s14_data_i(),
	    .s14_data_o(),
	    .s14_addr_o(),
	    .s14_sel_o(),
	    .s14_we_o(), 
	    .s14_cyc_o(), 
	    .s14_stb_o(),
	    .s14_ack_i(1'b0), 
	    .s14_err_i(1'b0), 
	    .s14_rty_i(1'b0),

	    // Slave 15 Interface
	    .s15_data_i(),
	    .s15_data_o(),
	    .s15_addr_o(),
	    .s15_sel_o(),
	    .s15_we_o(), 
	    .s15_cyc_o(), 
	    .s15_stb_o(),
	    .s15_ack_i(1'b0), 
	    .s15_err_i(1'b0), 
	    .s15_rty_i(1'b0)
	);

endmodule
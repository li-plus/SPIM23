// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Copyright (c) 2010 by Lattice Semiconductor Corporation
// --------------------------------------------------------------------
//
// Permission:
//
// Lattice Semiconductor grants permission to use this code for use
// in synthesis for any Lattice programmable logic product. Other
// use of this code, including the selling or duplication of any
// portion is strictly prohibited.
//
// Disclaimer:
//
// This VHDL or Verilog source code is intended as a design reference
// which illustrates how these types of functions can be implemented.
// It is the user's responsibility to verify their design for
// consistency and functionality through the use of formal
// verification methods. Lattice Semiconductor provides no warranty
// regarding the use or functionality of this code.
//
// --------------------------------------------------------------------
//
// Lattice Semiconductor Corporation
// 5555 NE Moore Court
// Hillsboro, OR 97214
// U.S.A
//
// TEL: 1-800-Lattice (USA and Canada)
// 503-268-8001 (other locations)
//
// web: http://www.latticesemi.com/
// email: techsupport@latticesemi.com
//
// --------------------------------------------------------------------
// Code Revision History :
// --------------------------------------------------------------------
// Ver: | Author |Mod. Date |Changes Made:
// V1.0 |        |03/10     |initial version
// --------------------------------------------------------------------

`timescale 1ns /1ns
module wb_nor_flash_tb();

    reg [3:0] wb_addr_i;
    reg [15:0] wb_dat_i;
    reg wb_we_i;
    reg wb_cyc_i;
    reg wb_stb_i;
    reg clk;
    reg rst;
    reg RY_BYn;
    
    wire [15:0] wb_dat_o;
    wire wb_ack_o; 
    wire CEn;  
    wire OEn; 
    wire WEn;
    wire BYTEn;
    wire RESETn; 
    wire [15:0] ADDR;
    
    reg [15:0] dq_buf;
    reg dq_ena;
    wire [15:0] DQ;
    
    assign DQ=dq_ena?dq_buf:16'hz;
    
    reg ready;
       
  wb_nor_flash uut(    
      .clk_i(clk),
      .rst_i(rst),
      .wb_addr_i(wb_addr_i),
      .wb_dat_i(wb_dat_i),
      .wb_dat_o(wb_dat_o),
      .wb_stb_i(wb_stb_i),
      .wb_cyc_i(wb_cyc_i),
      .wb_we_i(wb_we_i),
      .wb_ack_o(wb_ack_o),
      .CEn(CEn),
      .OEn(OEn),
      .WEn(WEn),
      .BYTEn(BYTEn),
      .RESETn(RESETn),
      .RY_BYn(RY_BYn),
      .ADDR(ADDR),
      .DQ(DQ)
);
//PUR     PUR_INST (rst) ;
//GSR 	GSR_INST (rst) ;

    initial begin
            wb_addr_i = 0;
            wb_dat_i = 0;
            wb_we_i = 0;
            wb_cyc_i = 0;
            wb_stb_i = 0;
            dq_ena=0;
            dq_buf=0;
            ready=0;
                        
            clk = 0;
            rst = 1;
            RY_BYn=1;
            #15 rst = 0;
    end

initial begin
	   #10 clk = 1 ;
	forever
	   #10 clk = ~clk ;		
	end
	
always@(OEn)
 if(!OEn) begin
    dq_ena=1;
    dq_buf=16'hec;
 end else begin
    dq_ena=0;
    dq_buf=0;
 end
 
initial begin
     #40 wb_cyc_i = 1;
//-------------------------------------------------------------reset command	  
//----------write 1 to wb_code register 		
	      @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 1;         //write
	       wb_addr_i = 16'h5 ;	//  wb_code register address
	       wb_dat_i = 16'h1;   //  for reset,command code is 1
	       ready=0;
	   #40 wb_stb_i = 1'b0 ;	   
	   
	   //-------------read until rdy_by=1,that indicate the nor flash finish the reset operation. 
	   while(!ready) begin    //read until rdy_by=1
	     @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h4 ;	//  rdy_by register address
	     #60 ready=wb_dat_o[0];
	     wb_stb_i = 1'b0 ;	
	   end 
	   
//-------------------------------------------------------------chip erase command
//----------write 4 to wb_code register 
	    @(posedge clk)
	    #1;
	       wb_stb_i = 1'b1 ;		
	       wb_we_i = 1;
	       wb_addr_i = 16'h5 ;	//  wb_code register address
	       wb_dat_i = 16'h4;   //  for chip erase,command code is 4
	       ready=0;
	   #40 wb_stb_i = 1'b0 ;
	   
	   //-------------read until rdy_by=1,that indicate the nor flash finish the chip erase operation.
	   while(!ready) begin    //read until rdy_by=1
	     @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h4 ;	//rdy_by register address
	     #60 ready=wb_dat_o[0];
	     wb_stb_i = 1'b0 ;	
	   end 
	   
//-------------------------------------------------------------sector erase command
//----------first write the address of the sector which will be erased to the sector_addr register,
//----------second write 3 to wb_code register 
	    @(posedge clk)
	    #1;
	       wb_stb_i = 1'b1 ;		
	       wb_we_i = 1;
	       wb_addr_i = 16'h0 ;	//  sector_addr register address
	       wb_dat_i = 16'haa;   //  the address of the sector which will be erased
	   #40 wb_stb_i = 1'b0 ;
	   @(posedge clk)
	    #1;
	       wb_stb_i = 1'b1 ;		
	       wb_we_i = 1;
	       wb_addr_i = 16'h5 ;	//  sector_addr register address
	       wb_dat_i = 16'h3;   //  for sector erase,command code is 3
	       ready=0;
	   #40 wb_stb_i = 1'b0 ;
	   
	   //-------------read until rdy_by=1,that indicate the nor flash finish the sector erase operation.
	   while(!ready) begin    //read until rdy_by=1
	     @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h4 ;	//rdy_by register address
	     #60 ready=wb_dat_o[0];
	     wb_stb_i = 1'b0 ;	
	   end 	

//-------------------------------------------------------------read manufacturer id command	  
//----------first write 2 to wb_code register,second read rxdata register until rdy_by=1.
	      @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 1;         //write
	       wb_addr_i = 16'h5 ;	//  wb_code register address
	       wb_dat_i = 16'h2;   //  for read id,command code is 2
	       ready=0;
	   #40 wb_stb_i = 1'b0 ;	   
	   
	   //-------------read until rdy_by=1,that indicate the nor flash finish the read id operation. 
	   while(!ready) begin    //read until rdy_by=1
	     @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h4 ;	//  rdy_by register address
	     #60 ready=wb_dat_o[0];
	     wb_stb_i = 1'b0 ;	
	   end 	      
	   //-------------read rxdata register
	   @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h3 ;	//  rxdata register address
	     #60 wb_stb_i = 1'b0 ;
	     
//-------------------------------------------------------------program command
//----------first write program address to the sector_addr and other_addr register,
//----------second write program data to the txdata register,
//----------last write 6 to wb_code register 
	    @(posedge clk)
	    #1;
	       wb_stb_i = 1'b1 ;		
	       wb_we_i = 1;
	       wb_addr_i = 16'h0 ;	//  sector_addr register address
	       wb_dat_i = 16'haa;   //  program address include sector address and other address
	   #40 wb_stb_i = 1'b0 ;
	   @(posedge clk)
	    #1;
	       wb_stb_i = 1'b1 ;		
	       wb_we_i = 1;
	       wb_addr_i = 16'h1 ;	//  other_address register address
	       wb_dat_i = 16'h55;   //  program address include sector address and other address
	   #40 wb_stb_i = 1'b0 ;
	   @(posedge clk)
	    #1;
	       wb_stb_i = 1'b1 ;		
	       wb_we_i = 1;
	       wb_addr_i = 16'h2 ;	//  txdata register address
	       wb_dat_i = 16'h1234;   //  program data
	   #40 wb_stb_i = 1'b0 ;
	   @(posedge clk)
	    #1;
	       wb_stb_i = 1'b1 ;		
	       wb_we_i = 1;
	       wb_addr_i = 16'h5 ;	//  wb_code register address
	       wb_dat_i = 16'h6;   //  for program data,command code is 2
	       ready=0;
	   #40 wb_stb_i = 1'b0 ;
	   
	   //-------------read until rdy_by=1,that indicate the nor flash finish the program data operation.
	   while(!ready) begin    //read until rdy_by=1
	     @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h4 ;	//rdy_by register address
	     #60 ready=wb_dat_o[0];
	     wb_stb_i = 1'b0 ;	
	   end 	
	   
//-------------------------------------------------------------read flash command	  
//----------first write 5 to wb_code register,second read rxdata register until rdy_by=1.
	      @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 1;         //write
	       wb_addr_i = 16'h5 ;	//  wb_code register address
	       wb_dat_i = 16'h5;   //  for read flash,command code is 5
	       ready=0;
	   #40 wb_stb_i = 1'b0 ;	   
	   
	   //-------------read until rdy_by=1,that indicate the nor flash finish the read flash operation. 
	   while(!ready) begin    //read until rdy_by=1
	     @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h4 ;	//  rdy_by register address
	     #60 ready=wb_dat_o[0];
	     wb_stb_i = 1'b0 ;	
	   end 	      
	   //-------------read rxdata register
	   @(posedge clk)
	      #1;
	       wb_stb_i = 1;		
	       wb_we_i = 0;        //read
	       wb_addr_i = 16'h3 ;	//  rxdata register address
	     #60 wb_stb_i = 1'b0 ;	   	     
	   #10;
	   

$stop;
	end


endmodule 

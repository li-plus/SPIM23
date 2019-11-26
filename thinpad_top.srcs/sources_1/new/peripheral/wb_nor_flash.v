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

`timescale 1ns/1ns
//`define WORD_BYTEn 0
module wb_nor_flash(clk_i,rst_i, wb_addr_i,wb_dat_i, wb_dat_o, wb_stb_i, wb_we_i, wb_cyc_i, wb_ack_o,
                    CEn,OEn,WEn,BYTEn,RESETn,RY_BYn,ADDR,DQ);
    parameter secter_addr_width=8;
    parameter other_addr_width=8;
    parameter addr_width=secter_addr_width+other_addr_width;
    
    input          clk_i;
    input          rst_i;
    input   [3:0]  wb_addr_i;
    input   [15:0] wb_dat_i;
    output  [15:0] wb_dat_o;
    input          wb_stb_i;
    input          wb_cyc_i;
    input          wb_we_i;
    output         wb_ack_o;
    output CEn;
    output OEn;
    output WEn;
    output BYTEn;
    output RESETn;
    input RY_BYn;
    output [addr_width-1:0] ADDR;
    inout [15:0] DQ;
    
    parameter WORD_BYTEn=1;  //1 word; 0 byte
    //`ifdef WORD_BYTEn    //1 word; 0 byte
    //  parameter flash_data_width=8; 
    //`else
    //  parameter flash_data_width=16;
    //`endif
    
    parameter tAA=3;   //read
    parameter tAH=3;   //write
    parameter tWPH=2;  //write
    parameter tBUSY=2; //write
    parameter tRB=1;   //write
    
    reg [15:0] wb_dat_o;
    reg wb_ack_o;
    reg CEn;
    reg OEn;
    reg WEn; 
    reg [addr_width-1:0] ADDR;
        
    reg [secter_addr_width-1:0] sector_addr;
    reg [other_addr_width-1:0] other_addr;
    reg [15:0] txdata;
    reg [15:0] rxdata;
    reg rdy_by;
    reg [3:0] wb_code;
    reg [15:0] latch_data;
    reg sector_addr_cs,other_addr_cs,txdata_cs,rxdata_cs,rdy_by_cs,wb_code_cs;
    reg reg_wr,reg_rd;
    reg read_wait;
    
//-------------------------------------------------------//
//----------------- WISHBONE Interface-------------------//
//-------------------------------------------------------//
    
//-------------------------------------------------------wishbone selcet register     
always@(posedge clk_i or posedge rst_i)
   if(rst_i) begin
     sector_addr_cs<=#1 1'b0;
     other_addr_cs<=#1 1'b0;
     txdata_cs<=#1 1'b0;
     rxdata_cs<=#1 1'b0;
     rdy_by_cs<=#1 1'b0;
     wb_code_cs<=#1 1'b0;
   end else begin
     sector_addr_cs<=#1 wb_addr_i==4'h0;
     other_addr_cs<=#1 wb_addr_i==4'h1;
     txdata_cs<=#1 wb_addr_i==4'h2;
     rxdata_cs<=#1 wb_addr_i==4'h3;
     rdy_by_cs<=#1 wb_addr_i==4'h4;
     wb_code_cs<=#1 wb_addr_i==4'h5;
   end
//-------------------------------------------------------wishbone read or write  
always@(posedge clk_i or posedge rst_i)
   if(rst_i) begin          
     reg_wr<=#1 1'b0;
     reg_rd<=#1 1'b0;
   end else begin
     reg_wr<=#1 wb_we_i && wb_stb_i && wb_cyc_i;
     reg_rd<=#1 !wb_we_i && wb_stb_i && wb_cyc_i;
   end
//-------------------------------------------------------latch data from wishbone   
always@(posedge clk_i or posedge rst_i)
   if(rst_i) begin          
     latch_data<=#1 16'h0;
   end else begin
     latch_data<=#1 wb_dat_i;
   end   
//-------------------------------------------------------wishbone write sector_addr register  
always@(posedge clk_i or posedge rst_i)
   if(rst_i) begin          
     sector_addr<=#1 0;
   end 
   else if(reg_wr && sector_addr_cs) begin
     sector_addr<=#1 latch_data[secter_addr_width-1:0];
   end      
//-------------------------------------------------------wishbone write other_addr register  
always@(posedge clk_i or posedge rst_i)
   if(rst_i) begin          
     other_addr<=#1 0;
   end 
   else if(reg_wr && other_addr_cs) begin
     other_addr<=#1 latch_data[other_addr_width-1:0];
   end  
//-------------------------------------------------------wishbone write txdata register  
always@(posedge clk_i or posedge rst_i)
   if(rst_i) begin          
     txdata<=#1 0;
   end 
   else if(reg_wr && txdata_cs) begin
     txdata<=#1 WORD_BYTEn?latch_data:latch_data[7:0];
   end            
//-------------------------------------------------------wishbone write wb_code register  
always@(posedge clk_i or posedge rst_i)
   if(rst_i) begin          
     wb_code<=#1 0;
   end 
   else if(reg_wr && wb_code_cs) begin
     wb_code<=#1 latch_data[3:0];
   end    
//-------------------------------------------------------wishbone read register   
always @(posedge clk_i or posedge rst_i)
     if (rst_i)
       wb_dat_o<= #1 16'h0;
     else if (reg_rd)
       wb_dat_o     <= #1  sector_addr_cs ? sector_addr : 
                           other_addr_cs ? other_addr : 
                           txdata_cs ? txdata : 
                           rxdata_cs ? rxdata: 
                           rdy_by_cs ? rdy_by :
                           wb_code_cs? wb_code:
                                         16'h0;  
//-------------------------------------------------------wishbone ACK                                           
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      wb_ack_o <= 1'b0;
    else if (wb_ack_o)
      wb_ack_o <= 1'b0;
    else if (wb_stb_i && wb_cyc_i && (wb_we_i || read_wait))
      wb_ack_o <= 1'b1;
    end

   always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)						
      read_wait <= 1'b0;
    else if (wb_ack_o)
      read_wait <= 1'b0;
    else if (wb_stb_i && wb_cyc_i && !wb_we_i)
      read_wait <= 1'b1;
    end                                         
//-------------------------------------------------------//
//----------------- NOR Flash Interface-------------------//
//-------------------------------------------------------//     
    reg DQ_ena;
    reg [15:0] DQ_buf;
    reg wb_start;
    reg [4:0] cnt_state;
    reg [4:0] flash_state;
    reg [1:0] cnt_code;
    reg cnt_start,cnt_done;
    reg [addr_width-1:0] inner_addr;
    
    parameter cnt_idle=0,
              cnt_reset=1,
              cnt_id_0=2,
              cnt_id_1=3,
              cnt_id_2=4,
              cnt_id_3=5,
              cnt_sector_erase_0=6,
              cnt_sector_erase_1=7,
              cnt_sector_erase_2=8,
              cnt_sector_erase_3=9,
              cnt_sector_erase_4=10,
              cnt_sector_erase_5=11,
              cnt_chip_erase_0=12,
              cnt_chip_erase_1=13,
              cnt_chip_erase_2=14,
              cnt_chip_erase_3=15,
              cnt_chip_erase_4=16,
              cnt_chip_erase_5=17,
              cnt_read=18,
              cnt_program_0=19,
              cnt_program_1=20,
              cnt_program_2=21,
              cnt_program_3=22,
              cnt_wait_rdy=23;
    
    parameter flash_idle=0,
              flash_read_0=1,
              flash_read_1=2,
              flash_read_2=3,
              flash_read_3=4,
              flash_read_end=5,
              flash_write_0=6,
              flash_write_1=7,
              flash_write_2=8,
              flash_write_3=9,
              flash_write_4=10,
              flash_write_end=11,
              flash_wait_rdy_0=12,
              flash_wait_rdy_1=13,
              flash_wait_rdy_2=14,
              flash_wait_rdy_3=15,
              flash_wait_rdy_end=16;
              
//-------------------------------------------------------RESETn     
assign #1 RESETn=!rst_i;    
//-------------------------------------------------------BYTEn  
assign #1 BYTEn=WORD_BYTEn?1'b1:1'b0;
//-------------------------------------------------------DQ as output     
assign #1 DQ=DQ_ena?(WORD_BYTEn?DQ_buf:{8'hzz,DQ_buf[7:0]}):16'hz;

//-------------------------------------------------------wishboe start
always @(posedge clk_i or posedge rst_i) 
   if(rst_i) 
     wb_start<=#1 1'b0;
   else if(reg_wr && wb_code_cs) 
     wb_start<=#1 1'b1;
   else if(cnt_state==cnt_id_3 || cnt_state==cnt_read || cnt_state==cnt_wait_rdy)
     wb_start<=#1 1'b0;
//-------------------------------------------------------rdy_by
always @(posedge clk_i or posedge rst_i) 
   if(rst_i) 
     rdy_by<=#1 1'b1;     //1 ready; 0 busy;
   else if(reg_wr && wb_code_cs) 
     rdy_by<=#1 1'b0;
   else if(flash_state==flash_read_3 || flash_state==flash_wait_rdy_3)
     rdy_by<=#1 1'b1;
//-------------------------------------------------------control state 
always @(posedge clk_i or posedge rst_i) 
   if(rst_i) begin
     cnt_state<=#1 cnt_idle;
     cnt_code<=#1 0;
     cnt_start<=#1 1'b0;
     inner_addr<=#1 0;
     DQ_buf<=#1 0;
   end
   else begin
     cnt_code<=#1 0;
     cnt_start<=#1 1'b0;
     inner_addr<=#1 0;
     DQ_buf<=#1 0;
     case(cnt_state)
     cnt_idle: begin 
        if(wb_start) begin
          case(wb_code)
            4'h1:begin
              cnt_state<=#1 cnt_reset;              
            end
            4'h2:begin
              cnt_state<=#1 cnt_id_0;              
            end
            4'h3:begin
              cnt_state<=#1 cnt_sector_erase_0;              
            end
            4'h4:begin
              cnt_state<=#1 cnt_chip_erase_0;             
            end
            4'h5:begin
              cnt_state<=#1 cnt_read;              
            end
            4'h6:begin
              cnt_state<=#1 cnt_program_0;             
            end
            default:begin
              cnt_state<=#1 cnt_idle;             
            end
          endcase
        end
        else begin
          cnt_state<=#1 cnt_idle;          
        end
     end
     cnt_reset:begin       //reset command to flash     
        cnt_code<=#1 2;            
        inner_addr<=#1 0;  //command address
        DQ_buf<=#1 16'hf0; //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_wait_rdy;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_reset;
          cnt_start<=#1 1'b1;
        end
     end
     cnt_id_0:begin           //autoselect command 1st cycle
        cnt_code<=#1 2;        
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'haa;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_id_1;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_id_0;
          cnt_start<=#1 1'b1;
        end
     end
     cnt_id_1:begin  //autoselect command 2nd cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h2aa:'h555; //command address
        DQ_buf<=#1 16'h55;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_id_2;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_id_1;
          cnt_start<=#1 1'b1;          
        end
     end
     cnt_id_2:begin  //autoselect command 3rd cycle
        cnt_code<=#1 2;        
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'h90;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_id_3;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_id_2;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_id_3:begin  //autoselect command 4th cycle
        cnt_code<=#1 1;
        inner_addr<=#1 0; //command address
        if(cnt_done) begin
          cnt_state<=#1 cnt_idle;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_id_3;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_sector_erase_0:begin //sector erase command 1st cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'haa;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_sector_erase_1;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_sector_erase_0;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_sector_erase_1:begin //sector erase command 2nd cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h2aa:'h555; //command address
        DQ_buf<=#1 16'h55;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_sector_erase_2;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_sector_erase_1;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_sector_erase_2:begin //sector erase command 3rd cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'h80;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_sector_erase_3;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_sector_erase_2;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_sector_erase_3:begin //sector erase command 4th cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'haa;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_sector_erase_4;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_sector_erase_3;
          cnt_start<=#1 1'b1;
        end 
     end
     cnt_sector_erase_4:begin //sector erase command 5th cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h2aa:'h555; //command address
        DQ_buf<=#1 16'h55;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_sector_erase_5;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_sector_erase_4;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_sector_erase_5:begin //sector erase command 6th cycle
        cnt_code<=#1 2;
        inner_addr<=#1 sector_addr; //command address
        DQ_buf<=#1 16'h30;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_wait_rdy;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_sector_erase_5;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_chip_erase_0:begin //chip erase command 1st cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'haa;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_chip_erase_1;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_chip_erase_0;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_chip_erase_1:begin //chip erase command 2nd cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h2aa:'h555; //command address
        DQ_buf<=#1 16'h55;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_chip_erase_2;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_chip_erase_1;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_chip_erase_2:begin //chip erase command 3rd cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'h80;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_chip_erase_3;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_chip_erase_2;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_chip_erase_3:begin //chip erase command 4th cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'haa;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_chip_erase_4;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_chip_erase_3;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_chip_erase_4:begin //chip erase command 5th cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h2aa:'h555; //command address
        DQ_buf<=#1 16'h55;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_chip_erase_5;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_chip_erase_4;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_chip_erase_5:begin //chip erase command 6th cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'h10;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_wait_rdy;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_chip_erase_5;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_read:begin  //read command 
        cnt_code<=#1 1;
        inner_addr<=#1 {sector_addr,other_addr}; //command address
        if(cnt_done) begin
          cnt_state<=#1 cnt_idle;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_read;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_program_0:begin //program command 1st cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'haa;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_program_1;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_program_0;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_program_1:begin //program command 2nd cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h2aa:'h555; //command address
        DQ_buf<=#1 16'h55;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_program_2;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_program_1;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_program_2:begin //program command 3rd cycle
        cnt_code<=#1 2;
        inner_addr<=#1 WORD_BYTEn?'h555:'haaa; //command address
        DQ_buf<=#1 16'ha0;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_program_3;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_program_2;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_program_3:begin //program command 4th cycle
        cnt_code<=#1 2;
        inner_addr<=#1 {sector_addr,other_addr}; //command address
        DQ_buf<=#1 txdata;  //command data
        if(cnt_done) begin
          cnt_state<=#1 cnt_wait_rdy;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_program_3;
          cnt_start<=#1 1'b1;
        end   
     end
     cnt_wait_rdy:begin
        cnt_code<=#1 3;
        if(cnt_done) begin
          cnt_state<=#1 cnt_idle;
          cnt_start<=#1 1'b0;
        end else begin
          cnt_state<=#1 cnt_wait_rdy;
          cnt_start<=#1 1'b1;
        end   
     end
     default:begin
        cnt_state<=#1 cnt_idle;
     end
     endcase
   end   
//-------------------------------------------------------
reg [3:0]time_tAA_cnt;  
reg [3:0]time_tAH_cnt;  
reg [3:0]time_tWPH_cnt; 
reg [3:0]time_tBUSY_cnt;
reg [3:0]time_tRB_cnt;  

wire time_is_tAA;  
wire time_is_tAH;  
wire time_is_tWPH; 
wire time_is_tBUSY;
wire time_is_tRB;  
   
//-------------------------------------------------------flash state      
always @(posedge clk_i or posedge rst_i) 
   if(rst_i) begin
      CEn<=#1 1'b1;
      OEn<=#1 1'b1;
      WEn<=#1 1'b1;
      ADDR<=#1 0;   
      cnt_done<=#1 1'b0;
      DQ_ena<=#1 1'b0;
      flash_state<=#1 flash_idle;
      rxdata<=#1 0;
   end
   else begin
      CEn<=#1 1'b1;
      OEn<=#1 1'b1;
      WEn<=#1 1'b1;
      ADDR<=#1 ADDR;   
      cnt_done<=#1 1'b0;
      DQ_ena<=#1 1'b0;
      case(flash_state)
      flash_idle:begin
        if(cnt_start) begin
          case(cnt_code)
          'h1:begin
            flash_state<=#1 flash_read_0;
          end                     
          'h2:begin
            flash_state<=#1 flash_write_0;
          end          
          'h3:begin
            flash_state<=#1 flash_wait_rdy_0;
          end
          default:begin
            flash_state<=#1 flash_idle;
          end
          endcase
        end
        else begin
          flash_state<=#1 flash_idle;
        end 
      end
      flash_write_0:begin
        CEn<=#1 1'b0;
        ADDR<=#1 inner_addr;
        flash_state<=#1 flash_write_1; //minimal tAS=0ns
      end
      flash_write_1:begin
        CEn<=#1 1'b0;
        ADDR<=#1 inner_addr;
        WEn<=#1 1'b0;
        DQ_ena<=#1 1'b1;
        if(time_is_tAH) //general tAH greater than tWP;general tAH greater than tDS
          flash_state<=#1 flash_write_2;
        else 
          flash_state<=#1 flash_write_1;
      end
      flash_write_2:begin
        CEn<=#1 1'b0;
        ADDR<=#1 inner_addr;  
        DQ_ena<=#1 1'b1;      
        flash_state<=#1 flash_write_3;  //minimal tDH=0ns     
      end
      flash_write_3:begin
        if(time_is_tWPH) 
          flash_state<=#1 flash_write_4;
        else 
          flash_state<=#1 flash_write_3;
      end
      flash_write_4:begin
         cnt_done<=#1 1'b1;
         flash_state<=#1 flash_write_end;
      end
      flash_write_end:begin
         flash_state<=#1 flash_idle;
      end
      flash_read_0:begin
        CEn<=#1 1'b0;
        ADDR<=#1 inner_addr;
        flash_state<=#1 flash_read_1; //minimal tAS=0ns
      end
      flash_read_1:begin
        CEn<=#1 1'b0;
        OEn<=#1 1'b0;
        ADDR<=#1 inner_addr;
        if(time_is_tAA)   //general tAA is greater than tOE and tCE
          flash_state<=#1 flash_read_2;
        else 
          flash_state<=#1 flash_read_1;
      end
      flash_read_2:begin
        rxdata<=#1 DQ;        
        flash_state<=#1 flash_read_3;
      end
      flash_read_3:begin 
        cnt_done<=#1 1'b1;     
        flash_state<=#1 flash_read_end;
      end
      flash_read_end:begin
        flash_state<=#1 flash_idle;
      end
      flash_wait_rdy_0:begin
        if(time_is_tBUSY)
          flash_state<=#1 flash_wait_rdy_1;
        else
          flash_state<=#1 flash_wait_rdy_0;
      end
      flash_wait_rdy_1:begin
        if(RY_BYn)
          flash_state<=#1 flash_wait_rdy_2;
        else
          flash_state<=#1 flash_wait_rdy_1;
      end
      flash_wait_rdy_2:begin
        if(time_is_tRB)
          flash_state<=#1 flash_wait_rdy_3;
        else
          flash_state<=#1 flash_wait_rdy_2;
      end
      flash_wait_rdy_3:begin
        cnt_done<=#1 1'b1;     
        flash_state<=#1 flash_wait_rdy_end;
      end
      flash_wait_rdy_end:begin
        flash_state<=#1 flash_idle;
      end
      default:begin
        flash_state<=#1 flash_idle;
      end
      endcase
   end
               
//-------------------------------------------------------time_is_tAH      
always @(posedge clk_i or posedge rst_i) 
   if(rst_i)
     time_tAH_cnt<=#1 0;
   else 
     if(time_is_tAH)
       time_tAH_cnt<=#1 0;
     else if(flash_state==flash_write_1)
       time_tAH_cnt<=#1 time_tAH_cnt+1;
       
assign #1 time_is_tAH=time_tAH_cnt==tAH;    
//-------------------------------------------------------time_is_tWPH      
always @(posedge clk_i or posedge rst_i) 
   if(rst_i) 
     time_tWPH_cnt<=#1 0;
   else 
     if(time_is_tWPH)
       time_tWPH_cnt<=#1 0;
     else if(flash_state==flash_write_3)
       time_tWPH_cnt<=#1 time_tWPH_cnt+1;
       
assign #1 time_is_tWPH=time_tWPH_cnt==tWPH;        
//-------------------------------------------------------time_is_tAA      
always @(posedge clk_i or posedge rst_i) 
   if(rst_i)
     time_tAA_cnt<=#1 0;
   else 
     if(time_is_tAA)
       time_tAA_cnt<=#1 0;
     else if(flash_state==flash_read_1)
       time_tAA_cnt<=#1 time_tAA_cnt+1;
       
assign #1 time_is_tAA=time_tAA_cnt==tAA;  
//-------------------------------------------------------time_is_tBUSY      
always @(posedge clk_i or posedge rst_i) 
   if(rst_i) 
     time_tBUSY_cnt<=#1 0;
   else 
     if(time_is_tBUSY)
       time_tBUSY_cnt<=#1 0;
     else if(flash_state==flash_wait_rdy_0)
       time_tBUSY_cnt<=#1 time_tBUSY_cnt+1;
       
assign #1 time_is_tBUSY=time_tBUSY_cnt==tBUSY;   
//-------------------------------------------------------time_is_tBUSY      
always @(posedge clk_i or posedge rst_i) 
   if(rst_i) 
     time_tRB_cnt<=#1 0;
   else 
     if(time_is_tRB)
       time_tRB_cnt<=#1 0;
     else if(flash_state==flash_wait_rdy_2)
       time_tRB_cnt<=#1 time_tRB_cnt+1;
       
assign #1 time_is_tRB=time_tRB_cnt==tRB; 

endmodule     
`include "defines.vh"

module wishbone_bus_if(
	input wire clk,
	input wire rst,
	
	input wire[5:0] stall_i,
	input wire flush_i,
	
	//CPU
	input wire cpu_ce_i,
	input wire[`RegBus] cpu_data_i,
	input wire[`RegBus] cpu_addr_i,
	input wire cpu_we_i,
	input wire[3:0] cpu_sel_i,
	output reg[`RegBus] cpu_data_o,
	
	//Wishbone
	input wire[`RegBus] wishbone_data_i,
	input wire wishbone_ack_i,
	output reg[`RegBus] wishbone_addr_o,
	output reg[`RegBus] wishbone_data_o,
	output reg wishbone_we_o,
	output reg[3:0] wishbone_sel_o,
	output reg wishbone_stb_o,
	output reg wishbone_cyc_o,

	output reg stallreq
);

  reg[1:0] wishbone_state;
  reg[`RegBus] rd_buf;
  
  reg self_stall = `False;

  parameter INST_BUS = `False;

	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
            wishbone_state <= `WB_IDLE;
			wishbone_we_o <= `WriteDisable;
			wishbone_sel_o <= 4'b0000;
			wishbone_stb_o <= 1'b0;
			wishbone_cyc_o <= 1'b0;
			rd_buf <= `ZeroWord;
		end else begin
			case (wishbone_state)
				`WB_IDLE:		begin
					if(cpu_ce_i == `True && flush_i == `False) begin
						wishbone_stb_o <= 1'b1;
						wishbone_cyc_o <= 1'b1;
						wishbone_we_o <= INST_BUS ? `False : cpu_we_i;
						wishbone_sel_o <=  INST_BUS ? 4'b1111: cpu_sel_i;
						wishbone_state <= `WB_BUSY;
						rd_buf <= `ZeroWord;	
					end							
				end
				`WB_BUSY:		begin
					if(wishbone_ack_i == 1'b1) begin
					   if(flush_i == `False) begin
					       if(!INST_BUS) begin
						   		// databus does not support burst
								wishbone_stb_o <= 1'b0;
								wishbone_cyc_o <= 1'b0;
								wishbone_we_o <= `WriteDisable;
								wishbone_sel_o <=  4'b0000;
								wishbone_state <= `WB_IDLE;
								if(cpu_we_i == `WriteDisable) rd_buf <= wishbone_data_i;
								
								if(stall_i != 6'b000000) wishbone_state <= `WB_WAIT_FOR_STALL;
						   end else begin
						   		// inst bus, burst read
								wishbone_stb_o <= 1'b1;
								wishbone_cyc_o <= 1'b1;
								wishbone_we_o <= `WriteDisable;
								wishbone_sel_o <= 4'b1111;
								wishbone_state <= `WB_BUSY;
								rd_buf <= wishbone_data_i;

								if(stall_i != 6'b000000) begin
									wishbone_state <= `WB_WAIT_FOR_STALL;
									wishbone_stb_o <= 1'b0;
									wishbone_cyc_o <= 1'b0;
									wishbone_we_o <= `WriteDisable;
									wishbone_sel_o <=  4'b0000;
								end
						   end
					   end else begin
                            wishbone_stb_o <= 1'b0;
                            wishbone_cyc_o <= 1'b0;
                            wishbone_we_o <= `WriteDisable;
                            wishbone_sel_o <=  4'b0000;
                            wishbone_state <= `WB_IDLE;
                            rd_buf <= `ZeroWord;
					   end
					end else if(flush_i == `True) begin
					   wishbone_state <= `WB_WAIT_FOR_FLUSHING;
                       rd_buf <= `ZeroWord;
					end
				end
				`WB_WAIT_FOR_STALL: begin
				    if(stall_i == 6'b000000 || self_stall) begin
				        if(cpu_ce_i == `True && flush_i == `False) begin
                            wishbone_stb_o <= 1'b1;
                            wishbone_cyc_o <= 1'b1;
                            wishbone_we_o <= INST_BUS ? `False : cpu_we_i;
                            wishbone_sel_o <=  INST_BUS ? 4'b1111: cpu_sel_i;
                            wishbone_state <= `WB_BUSY;
                            rd_buf <= `ZeroWord;    
                        end else begin
                            wishbone_state <= `IDLE;
                        end
				    end
                end
				`WB_WAIT_FOR_FLUSHING: begin
				    if(wishbone_ack_i == 1'b1) begin
				        wishbone_stb_o <= 1'b0;
                        wishbone_cyc_o <= 1'b0;
                        wishbone_we_o <= `WriteDisable;
                        wishbone_sel_o <=  4'b0000;
                        wishbone_state <= `WB_IDLE;
                        rd_buf <= `ZeroWord;
				    end
				end
			endcase
		end
	end
			

	always @ (*) begin
		if(rst == `RstEnable) begin
			stallreq <= `NoStop;
			cpu_data_o <= `ZeroWord;
            wishbone_addr_o <= `ZeroWord;
            wishbone_data_o <= `ZeroWord;
            self_stall <= `False;
		end else begin
			stallreq <= `NoStop;
			if(cpu_ce_i == `True && flush_i == `False) begin
                wishbone_addr_o <= cpu_addr_i;
                wishbone_data_o <= cpu_data_i;
			end else begin
                wishbone_addr_o <= `ZeroWord;
                wishbone_data_o <= `ZeroWord;
			end
			case (wishbone_state)
				`WB_IDLE:		begin
					if(cpu_ce_i == `True && flush_i == `False) begin
						stallreq <= `Stop;
						self_stall <= `True;
						cpu_data_o <= `ZeroWord;				
					end
				end
				`WB_BUSY:		begin
					if(wishbone_ack_i == 1'b1) begin
						stallreq <= `NoStop;
						self_stall <= `False;
						if(wishbone_we_o == `WriteDisable) cpu_data_o <= wishbone_data_i;
                        else cpu_data_o <= `ZeroWord;						
					end else begin
						stallreq <= `Stop;
						self_stall <= `True;
						cpu_data_o <= `ZeroWord;				
					end
				end
				`WB_WAIT_FOR_STALL:		begin
					cpu_data_o <= rd_buf;
                    if(cpu_ce_i == `True && flush_i == `False) begin
                        stallreq <= `Stop;
                        self_stall <= `True;
                    end else begin
                        stallreq <= `NoStop;
                        self_stall <= `False;
                    end
				end
				`WB_WAIT_FOR_FLUSHING: begin
				    stallreq <= `Stop;
				    self_stall <= `False;
				    cpu_data_o <= `ZeroWord;
				end
			endcase
		end
	end

endmodule
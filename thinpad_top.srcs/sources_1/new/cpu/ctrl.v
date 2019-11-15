`include "defines.vh"

module ctrl(input wire rst,
            input wire stallreq_from_id,
            input wire stallreq_from_ex,

            input wire[31:0] excepttype_i,
            input wire[`RegBus] cp0_epc_i,

            output reg[`RegBus] new_pc,
            output reg flush,
            output reg[5:0] stall
);
    
    
	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;
		end else if(excepttype_i != `ZeroWord) begin
		  flush <= 1'b1;
		  stall <= 6'b000000;
			case (excepttype_i) // TODO change this according to concrete error handling loc
				32'h00000001: new_pc <= 32'h00000020; //interrupt
				32'h00000008: new_pc <= 32'h00000040; //syscall
				32'h0000000a: new_pc <= 32'h00000040; //inst_invalid
				32'h0000000d: new_pc <= 32'h00000040; //trap
				32'h0000000c: new_pc <= 32'h00000040; //ov
				32'h0000000e: new_pc <= cp0_epc_i; //eret
				default: ;
			endcase 						
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
			flush <= 1'b0;		
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;	
			flush <= 1'b0;		
		end else begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `ZeroWord;		
		end    //if
	end      //always 
    
endmodule

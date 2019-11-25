`include "defines.vh"

module ctrl(
    input wire rst,
    input wire[`RegBus] ebase_i,
    input wire[31:0] excepttype_i,
    input wire[`RegBus] cp0_epc_i,
    
    input wire stallreq_from_if,
    input wire stallreq_from_id,
    input wire stallreq_from_ex,
    input wire stallreq_from_mem,
    `ifdef USE_CPLD_UART
    input wire stallreq_from_uart,
    `endif
    output reg[`RegBus] new_pc,
    output reg flush,
    output reg[5:0] stall
);
    
    
	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `EntryAddr;
		end else if(excepttype_i != `ZeroWord) begin
		  flush <= 1'b1;
		  stall <= 6'b000000;
			case (excepttype_i)
				`EXCEPT_INT: new_pc <= ebase_i + 32'h180;
				`EXCEPT_ADEL: new_pc <= ebase_i + 32'h180;
				`EXCEPT_ADES: new_pc <= ebase_i + 32'h180;
				`EXCEPT_SYSCALL: new_pc <= ebase_i + 32'h180;
				`EXCEPT_INVALID_INST: new_pc <= ebase_i + 32'h180;
				`EXCEPT_OVERFLOW: new_pc <= ebase_i + 32'h180;
				`EXCEPT_TRAP: new_pc <= ebase_i + 32'h180;
				`EXCEPT_ERET: new_pc <= cp0_epc_i;
				`EXCEPT_TLBL: new_pc <= ebase_i;
				`EXCEPT_TLBS: new_pc <= ebase_i;
				`EXCEPT_MOD: new_pc <= ebase_i;
				default: ;
            endcase
        end else if(stallreq_from_mem == `Stop) begin
            stall <= 6'b011111;
            flush <= 1'b0;
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
			flush <= 1'b0;		
		end else if(stallreq_from_id == `Stop || stallreq_from_if == `Stop) begin
			stall <= 6'b000111;	
			flush <= 1'b0;
        `ifdef USE_CPLD_UART
        end else if(stallreq_from_uart == `Stop) begin
            stall <= 6'b011111;
            flush <= 1'b0;
        `endif
		end else begin
			stall <= 6'b000000;
			flush <= 1'b0;
			new_pc <= `EntryAddr;		
		end
	end
    
endmodule

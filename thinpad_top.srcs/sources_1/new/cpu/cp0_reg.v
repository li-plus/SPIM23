`include "defines.vh"

module cp0_reg(
    input wire clk,
    input wire rst,
    
    input wire we_i,
    input wire[4:0] waddr_i,
    input wire[4:0] raddr_i,
    input wire[`RegBus] data_i,
    
    input wire[31:0] excepttype_i,
    input wire[31:0] bad_address_i,
    input wire[5:0] int_i,
    input wire[`RegBus] current_inst_addr_i,
    input wire is_in_delayslot_i,

	input wire[`RegBus] inst_i,
	input wire[`RegBus] pagemask_i,
	input wire[`RegBus] entryhi_i,
	input wire[`RegBus] entrylo0_i,
	input wire[`RegBus] entrylo1_i,
	input wire[`RegBus] index_i,
    
    output reg[`RegBus] data_o,
    output reg[`RegBus] index_o, // 0
    output reg[`RegBus] random_o, // 1
    output reg[`RegBus] entrylo0_o, //2
    output reg[`RegBus] entrylo1_o, //3
	output reg[`RegBus] context_o, // 4
    output reg[`RegBus] pagemask_o, // 5
	output reg[`RegBus] wired_o, // 6
    output reg[`RegBus] badvaddr_o, // 8
    output reg[`RegBus] count_o,   // 9
    output reg[`RegBus] entryhi_o, // 10
    output reg[`RegBus] compare_o,  // 11
    output reg[`RegBus] status_o, // 12
    output reg[`RegBus] cause_o, // 13
    output reg[`RegBus] epc_o, // 14
    output reg[`RegBus] ebase_o, // 15
    output reg[`RegBus] config_o, // 16
    
    output reg timer_int_o  
);

wire[4:0] next_random = random_o[4:0] - 1;

always @(posedge clk) begin
    if(rst == `RstEnable) begin
		index_o <= {1'bx, 27'h0000000, 4'bxxxx};
        random_o <= {28'h00000000, 4'b1111};
        entrylo0_o <= {2'b00, 30'hx};
        entrylo1_o <= {2'b00, 31'hx};
		context_o <= {28'hx, 4'h0};
		pagemask_o <= `ZeroWord;
		wired_o <= `ZeroWord;
		badvaddr_o <= `ZeroWord;
        count_o <= `ZeroWord;
		entryhi_o <= `ZeroWord;
        compare_o <= `ZeroWord;
        status_o <= 32'b0001_0000000000000000000000000000; // cp0 present
        cause_o <= `ZeroWord;
        epc_o <= `ZeroWord;
        config_o <= 32'b0_001111_000_000_000_000_000_000_0_0_0_0_0_0_0;
		//               mmu_size-1
        timer_int_o <= `InterruptNotAssert;
        ebase_o <= `EntryAddr;
    end else begin
        count_o <= count_o + 1;
		if(next_random < wired_o[3:0])
			random_o[3:0] <= 4'b1111;
		else
		    random_o[3:0] <= next_random;
        cause_o[15:10] <= int_i;
        if(compare_o != `ZeroWord && count_o == compare_o)
            timer_int_o <= `InterruptAssert;
        if(we_i == `WriteEnable) begin
            case(waddr_i)
                `CP0_REG_INDEX: index_o <= {data_i[31], 26'h0000000, data_i[4:0]};
                `CP0_REG_ENTRYLO0: entrylo0_o <= {2'b00, data_i[29:0]};
                `CP0_REG_ENTRYLO1: entrylo1_o <= {2'b00, data_i[29:0]};
				`CP0_REG_CONTEXT:  context_o[31:23] <= data_i[31:23];
                `CP0_REG_PAGEMASK: pagemask_o[28:13] <= data_i[28:13];
				`CP0_REG_WIRED: begin
					wired_o <= {28'h0000000, data_i[3:0]};
					random_o <= {28'h00000000, 4'b1111};
				end
				`CP0_REG_BADVADDR: badvaddr_o <= data_i;
                `CP0_REG_ENTRYHI: entryhi_o <= {data_i[31:13], 5'b00000, data_i[7:0]};
                `CP0_REG_COUNT: count_o <= data_i;
                `CP0_REG_COMPARE: begin
                    compare_o <= data_i;
                    timer_int_o <= `InterruptNotAssert;
                end
                `CP0_REG_STATUS: status_o <= data_i;
                `CP0_REG_EPC: epc_o <= data_i;
                `CP0_REG_CAUSE: begin
                    cause_o[23:22] <= data_i[23:22];
                    cause_o[9:8] <= data_i[9:8];
                end
                `CP0_REG_EBASE: ebase_o <= {2'b10, data_i[29:12], 12'h000};
				default: ;
            endcase
        end

		if(inst_i[31:6] == `EXE_TLB_PREFIX) begin
			case(inst_i[5:0])
				`EXE_TLBP: begin
					index_o <= index_i;
				end
				`EXE_TLBR: begin
					pagemask_o <= pagemask_i;
					entryhi_o <= entryhi_i;
					entrylo0_o <= entrylo0_i;
					entrylo1_o <= entrylo1_i;
				end
			endcase
		end
        
        case(excepttype_i)
                `EXCEPT_INT:		begin
					if(is_in_delayslot_i == `InDelaySlot ) begin
						epc_o <= current_inst_addr_i - 4 ;
						cause_o[31] <= 1'b1;
					end else begin
					  epc_o <= current_inst_addr_i;
					  cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_INT;
					
				end
				`EXCEPT_SYSCALL:		begin
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_SYS;			
				end
				`EXCEPT_INVALID_INST:		begin
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_RI;					
				end
				`EXCEPT_TRAP:		begin
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_TR;
				end
				`EXCEPT_OVERFLOW:		begin // overflow
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_OV;					
				end				
				`EXCEPT_ADEL: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_ADEL;
					if(bad_address_i == 32'h00000000)
						badvaddr_o <= epc_o;
					else
						badvaddr_o <= bad_address_i;
				end
				`EXCEPT_ADES: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
						badvaddr_o <= bad_address_i;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_ADES;
				end
				`EXCEPT_ERET: status_o[1] <= 1'b0;
				`EXCEPT_TLBL: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_TLBL;
					badvaddr_o <= bad_address_i;
					context_o[22:4] <= bad_address_i[31:13];
					entryhi_o <= {bad_address_i[31:13], 13'h0000};
				end
				`EXCEPT_TLBS: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_TLBS;
					badvaddr_o <= bad_address_i;
					context_o[22:4] <= bad_address_i[31:13];
					entryhi_o <= {bad_address_i[31:13], 13'h0000};
				end
				`EXCEPT_MOD: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= `CAUSE_MOD;
					badvaddr_o <= bad_address_i;
					context_o[22:4] <= bad_address_i[31:13];
				end
				default: ;
        endcase
    end
end

// read registers
always @(*) begin
    if(rst == `RstEnable)
        data_o <= `ZeroWord;
    else
        case(raddr_i)
            `CP0_REG_INDEX: data_o <= index_o;
			`CP0_REG_RANDOM: data_o <= random_o;
            `CP0_REG_ENTRYLO0: data_o <= entrylo0_o;
            `CP0_REG_ENTRYLO1: data_o <= entrylo1_o;
			`CP0_REG_CONTEXT: data_o <= context_o;
            `CP0_REG_PAGEMASK: data_o <= pagemask_o;
			`CP0_REG_WIRED: data_o <= wired_o;
            `CP0_REG_BADVADDR: data_o <= badvaddr_o;
			`CP0_REG_COUNT: data_o <= count_o;
            `CP0_REG_ENTRYHI: data_o <= entryhi_o;
            `CP0_REG_COMPARE: data_o <= compare_o;
            `CP0_REG_STATUS: data_o <= status_o;
            `CP0_REG_CAUSE: data_o <= cause_o;
            `CP0_REG_EPC: data_o <= epc_o;
            `CP0_REG_EBASE: data_o <= ebase_o;
			`CP0_REG_CONFIG: data_o <= config_o;
            default: data_o <= `ZeroWord;
        endcase
end

endmodule

`include "defines.vh"

module cp0_forwarder(
    input wire[4:0] cp0_reg_addr_i,
    input wire[4:0] read_addr_i,
    input wire[31:0] cp0_reg_data_i,
    input wire[31:0] old_cp0_reg_data_i,
    output reg[31:0] cp0_reg_data_o,
    output reg need_forward
);

always @(*) begin
    cp0_reg_data_o <=  `ZeroWord;
    need_forward <= `False;
    if(cp0_reg_addr_i == `CP0_REG_WIRED && read_addr_i == `CP0_REG_RANDOM) begin
        cp0_reg_data_o <= {28'h00000000, 4'b1111};
        need_forward <= `True;
    end else if(read_addr_i == cp0_reg_addr_i) begin
        need_forward <= `True;
    end
    case(cp0_reg_addr_i)
        `CP0_REG_INDEX: cp0_reg_data_o <= {cp0_reg_data_i[31], 26'h0000000, cp0_reg_data_i[4:0]};
        `CP0_REG_ENTRYLO0: cp0_reg_data_o <= {2'b00, cp0_reg_data_i[29:0]};
        `CP0_REG_ENTRYLO1: cp0_reg_data_o <= {2'b00, cp0_reg_data_i[29:0]};
        `CP0_REG_CONTEXT:  cp0_reg_data_o <= {cp0_reg_data_i[31:23], old_cp0_reg_data_i[22:0]};
        `CP0_REG_PAGEMASK: cp0_reg_data_o <= {old_cp0_reg_data_i[31:29], cp0_reg_data_i[28:13], old_cp0_reg_data_i[12:0]};
        `CP0_REG_WIRED: cp0_reg_data_o <= {27'h0000000, cp0_reg_data_i[4:0]};
        `CP0_REG_BADVADDR: cp0_reg_data_o <= cp0_reg_data_i;
        `CP0_REG_ENTRYHI: cp0_reg_data_o <= {cp0_reg_data_i[31:13], 5'b00000, cp0_reg_data_i[7:0]};
        `CP0_REG_COUNT: cp0_reg_data_o <= cp0_reg_data_i;
        `CP0_REG_COMPARE: cp0_reg_data_o <= cp0_reg_data_i;
        `CP0_REG_STATUS: cp0_reg_data_o <= cp0_reg_data_i;
        `CP0_REG_EPC: cp0_reg_data_o <= cp0_reg_data_i;
        `CP0_REG_CAUSE: cp0_reg_data_o <= {old_cp0_reg_data_i[31:24], cp0_reg_data_i[23:22], 
        old_cp0_reg_data_i[22:10], cp0_reg_data_i[9:8], old_cp0_reg_data_i[7:0]};
        `CP0_REG_EBASE: cp0_reg_data_o <= {2'b10, cp0_reg_data_i[29:12], 12'h000};
        default: need_forward <= `False;
    endcase 
end

endmodule

`include "defines.vh"

// map the address of supervisor to physical ones

module mmu(
    input wire rst,
    input wire[`RegBus] addr_i,
    output reg[`RegBus] addr_o
);

always@(*) begin
    if(rst == `RstEnable) begin
        addr_o <= `ZeroWord;
    end
    else begin
        case(addr_i[31:24])
            8'h80: begin // 0x80000000 - 0x807fffff
                if(addr_i[23:22] == 2'b00) addr_o <= {4'h0, 6'b000000, addr_i[21:0]}; // base RAM
                else           addr_o <= {4'h1, 6'b000000, addr_i[21:0]}; // ext RAM
            end
            8'hbf: begin
                if(addr_i[23:20] == 4'hd)
                    addr_o <= {12'h200, addr_i[19:0]}; // uart - 0xbfd
//                else if(addr_i[23:20] == 4'hc)
//                    addr_o <= {12'h300, addr_i[19:0]}; // rom - 0xbfc
                else
                    addr_o <= `ZeroWord;
            end
            8'hba: begin
                if(addr_i[23:17] == 7'b0000000) begin
                    addr_o <= {12'h300, addr_i[19:0]}; // graphic ram
                end
            end
            default: addr_o <= `ZeroWord;
        endcase
    end
end

endmodule

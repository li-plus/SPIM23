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
            8'h80: begin // 0x8000000 - 0x807fffff
                if(addr_i[23:22] == 2'b00) addr_o <= {4'h0, 6'b000000, addr_i[21:0]}; // base RAM
                else           addr_o <= {4'h1, 6'b000000, addr_i[21:0]}; // ext RAM
            end
            8'hbf: begin
                addr_o <= {4'h2, addr_i[27:0]}; // uart
            end
            default: addr_o <= `ZeroWord;
        endcase
    end
end

endmodule

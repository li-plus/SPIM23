`include "alu.vh"

module ALU(
        input wire[15:0] a,
        input wire[15:0] b,
        input wire[3:0] op,
        output wire[15:0] f,
        output wire of
    );

reg[16:0] f1;
// sign extension
wire[4:0] a1 = $signed(a);
wire[4:0] b1 = $signed(b);

always @(*) begin
    case(op)
        `ALU_ADD: f1 = a1 + b1;
        `ALU_SUB: f1 = a1 - b1;
        `ALU_AND: f1 = a & b;
        `ALU_OR:  f1 = a | b;
        `ALU_XOR: f1 = a ^ b;
        `ALU_NOT: f1 = ~a;
        `ALU_SLL: f1 = a << b;
        `ALU_SRL: f1 = a >> b;
        `ALU_SRA: f1 = a >>> b;
        `ALU_ROL: f1 = (a >> b) | (a << (16 - b));
        default: f1 = 0;
    endcase
end

assign f = f1[15:0];
assign of = f1[15] ^ f1[16];
endmodule

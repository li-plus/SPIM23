module flash_controller(
// clk signals
input    wb_clk_i,
input    wb_rst_i,

// WB slave if
input[31:0]     wb_dat_i,
output[31:0]    wb_dat_o,
input[31:0]     wb_adr_i,
input[3:0]        wb_sel_i,
input             wb_we_i,
input             wb_cyc_i,
input             wb_stb_i,
output reg        wb_ack_o,

// FLASH if
inout[15:0]     FLASH_DQ,
output[22:0]    FLASH_ADDR,
output            FLASH_CE_N,
output            FLASH_OE_N,
output            FLASH_WE_N,
output          FLASH_RP_N,
output          FLASH_VPEN,
output          FLASH_BYTE_N,

output            idle
);

`define IDLE 4'h0
`define RD1 4'h1
`define RD2 4'h2
`define RD3 4'h3
`define RD4 4'h4
`define RD5 4'h5
`define RD6 4'h6
`define ACK 4'h7
`define OK 4'h8
//`define ACK 3'h5

wire wb_acc = wb_cyc_i & wb_stb_i; // wb access
wire wb_wr = wb_acc & wb_we_i & ~wb_rst_i; // write
wire wb_rd = wb_acc & ~wb_we_i & ~wb_rst_i; // read

reg[3:0] state;

reg[22:0] reg_flash_addr = 0;

assign idle = state == `IDLE;

assign FLASH_CE_N = ~wb_acc;
assign FLASH_OE_N = ~wb_rd;
assign FLASH_WE_N = ~wb_wr;
assign FLASH_ADDR = reg_flash_addr;
assign FLASH_RP_N = 1'b1; // no reset
assign FLASH_VPEN = 1'b1; // do not protect.
assign FLASH_BYTE_N = 1'b1; // 16 bits mode

assign FLASH_DQ = wb_wr ? wb_dat_i[15:0] : 16'hzzzz;

reg[15:0] reg_wb_data_o_hi = 16'h0000;
reg[15:0] reg_wb_data_o_lo = 16'h0000;
assign wb_dat_o = wb_rd ? {reg_wb_data_o_hi, reg_wb_data_o_lo} : 32'h00000000;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
        state <= `IDLE;
        wb_ack_o <= `False;
    end else begin
        case(state)
            `IDLE: begin
                reg_wb_data_o_lo <= 16'h0000;
                reg_wb_data_o_hi <= 16'h0000;
                reg_flash_addr <= wb_adr_i[22:0];
                if(wb_rd) begin
                    state <= `RD1;
                end else if (wb_wr) begin
                    state <= `ACK;
                end
            end
            `RD1: begin
                state <= `RD2;
            end
            `RD2: begin
                state <= `RD3;
            end
            `RD3: begin
                state <= `RD4;
                reg_wb_data_o_lo <= FLASH_DQ;
                reg_flash_addr <= reg_flash_addr + 2;
            end
            `RD4: begin
                state <= `RD5;
            end
            `RD5: begin
                state <= `RD6;
            end
            `RD6: begin
                state <= `ACK;
                reg_wb_data_o_hi <= FLASH_DQ;
            end
            `ACK: begin
                state <= `OK;
                wb_ack_o <= `True;
            end
            `OK: begin
                state <= `IDLE;
                wb_ack_o <= `False;
            end
            default: state <= `IDLE;
        endcase
    end
end

endmodule

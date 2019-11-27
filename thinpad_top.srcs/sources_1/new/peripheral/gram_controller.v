`include "defines.vh"

module gram_controller(
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

    // GRAM if
    output[7:0]     GRAM_DATA,
    output[18:0]    GRAM_ADDR,
    output            GRAM_WE_N,
    output      GRAM_CE_N,

    output            idle
);

`define IDLE 2'h0
`define WE0 2'h1
`define RD0 2'h2
`define OK 2'h3
//`define ACK 3'h5

wire wb_acc = wb_cyc_i & wb_stb_i; // wb access
wire wb_wr = wb_acc & wb_we_i & ~wb_rst_i; // write
wire wb_rd = wb_acc & ~wb_we_i & ~wb_rst_i; // read

reg[1:0] state;
// reg[31:0] gram_out;

assign idle = state == `IDLE;

assign GRAM_CE_N = ~wb_acc;
assign GRAM_WE_N = ~wb_wr;
assign GRAM_ADDR = wb_adr_i[18:0];
assign GRAM_DATA = wb_wr ? wb_dat_i[7:0] : 8'hzz;

// assign wb_dat_o = gram_out;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
        state <= `IDLE;
        // gram_out <= 32'hdeadbeef;
        wb_ack_o <= `False;
    end else begin
        case(state)
            `IDLE: begin
                if(wb_acc) begin
                    wb_ack_o <= `True;
                end else begin
                    wb_ack_o <= `False;
                end
                if(wb_wr) begin
                    state <= `WE0;
                end
            end
            `WE0: begin
                state <= `IDLE;
                wb_ack_o <= `False;
            end
            default: state <= `IDLE;
        endcase
    end
end

endmodule

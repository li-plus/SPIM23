module sram_controller(
    wb_clk_i,
    wb_rst_i,

    wb_dat_i,
    wb_adr_i,
    wb_sel_i,
    wb_we_i,
    wb_cyc_i,
    wb_stb_i,

    // Outputs
    wb_dat_o,
    wb_ack_o,

    // SRAM
    SRAM_DQ,   
    SRAM_ADDR,
    SRAM_BE_N,
    SRAM_CE_N,
    SRAM_OE_N,
    SRAM_WE_N
);

// clk signals
input    wb_clk_i;
input    wb_rst_i;

// WB slave if
input[31:0]     wb_dat_i;
output[31:0]    wb_dat_o;
input[31:0]     wb_adr_i;
input[3:0]        wb_sel_i;
input             wb_we_i;
input             wb_cyc_i;
input             wb_stb_i;
output            wb_ack_o;

// SRAM if
inout[31:0]     SRAM_DQ;
output[19:0]    SRAM_ADDR;
output[3:0]       SRAM_BE_N;
output            SRAM_CE_N;
output            SRAM_OE_N;
output            SRAM_WE_N;

`define IDLE 3'h0
`define WE0 3'h1
`define WE1 3'h2
`define RD0 3'h3
`define RD1 3'h4
`define ACK 3'h5

wire wb_acc = wb_cyc_i & wb_stb_i; // wb access
wire wb_wr = wb_acc & wb_we_i; // write
wire wb_rd = wb_acc & ~wb_we_i; // read

reg[2:0] state;
reg[31:0] sram_out;

assign SRAM_CE_N = ~wb_acc;
assign SRAM_OE_N = ~wb_rd;
assign SRAM_WE_N = ~(state == `WE0 || state == `WE1);
assign SRAM_BE_N = ~wb_sel_i;
assign SRAM_ADDR = wb_adr_i[21:2];

assign SRAM_DQ = (state == `WE0 || state == `WE1) ? wb_dat_i : 32'hzzzzzzzz;

assign wb_dat_o = sram_out;
assign wb_ack_o = (state == `ACK);

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
        state <= `IDLE;
        sram_out <= 32'h00000000;
        end
    else begin
        case(state)
            `IDLE: begin
                if(wb_wr)
                    state <= `WE0;
                else if(wb_rd)
                    state <= `RD0;
            end
            `WE0: state <= `WE1;
            `WE1: state <= `ACK;
            `RD0: state <= `RD1;
            `RD1: begin
                state <= `ACK;
                sram_out <= SRAM_DQ;
            end
            `ACK: state <= `IDLE;
            default: state <= `IDLE;
        endcase
    end
end

endmodule

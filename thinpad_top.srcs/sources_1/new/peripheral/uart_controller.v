`include "defines.vh"

module uart_controller(
    input wire wb_clk_i,
    input wire wb_rst_i,
    
    input wire[31:0] wb_dat_i,
    input wire[31:0] wb_adr_i,
    input wire wb_we_i,
    input wire wb_cyc_i,
    input wire wb_stb_i,
    
    // Outputs
    output wire[31:0] wb_dat_o,
    output reg wb_ack_o,
    
    output wire int_o,
    
    input wire uart_rxd,
    output wire uart_txd
);

wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_busy;
reg ext_uart_start;
reg ext_uart_clear = `False;
reg [7:0] read_buffer;

reg [1:0] state = 2'h0;

assign int_o = ext_uart_ready;

wire wb_acc = wb_cyc_i & wb_stb_i; // wb access
wire wb_wr = wb_acc & wb_we_i & ~wb_rst_i; // write
wire wb_rd = wb_acc & ~wb_we_i & ~wb_rst_i; // read

assign wb_dat_o = (wb_adr_i[2:0] == 3'h0) ? {24'h000000, read_buffer} : {25'h0, ~ext_uart_busy, 5'h00, ext_uart_ready};

async_receiver #(.ClkFrequency(`CLK_FREQ),.Baud(`UART_BAUD))
    ext_uart_r(
        .clk(wb_clk_i),
        .RxD(uart_rxd),
        .RxD_data_ready(ext_uart_ready),
        .RxD_clear(ext_uart_clear),
        .RxD_data(ext_uart_rx)
    );
    
async_transmitter #(.ClkFrequency(`CLK_FREQ),.Baud(`UART_BAUD))
    ext_uart_t(
        .clk(wb_clk_i),
        .TxD(uart_txd),
        .TxD_busy(ext_uart_busy),
        .TxD_start(ext_uart_start),
        .TxD_data(ext_uart_tx)
    );
    
always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
        wb_ack_o <= `False;
        read_buffer <= 8'h00;
        ext_uart_clear <= `False;
        state <= 2'b0;
        end
    else begin
        case(state)
            2'h0: begin
                wb_ack_o <= `False;
                ext_uart_clear <= `False;
                if(wb_adr_i[2:0] == 3'h0) begin
                    if(wb_wr) begin
                        state <= 2'h2;
                        ext_uart_tx <= wb_dat_i[7:0];
                        ext_uart_start <= `True;
                        end
                    else if(wb_rd) begin
                        if(ext_uart_ready) begin
                            read_buffer <= ext_uart_rx;
                            ext_uart_clear <= `True;
                            state <= 2'h1;
                        end else
                            wb_ack_o <= `True;  // return buffer directly
                    end 
                end else if(wb_adr_i[2:0] == 3'h5 && wb_acc) begin
                    wb_ack_o <= `True;  // read status register, return at once
                end
            end
            // read state
            2'h1: begin
                ext_uart_clear <= `False;
                wb_ack_o <= `True;
                state <= 2'h0;
            end
            // write state
            2'h2: begin
                if(ext_uart_busy) begin
                    ext_uart_start <= `False;
                    wb_ack_o <= `True;
                    state <= 2'h0;
                end else wb_ack_o <= `False;
            end
            default: begin
                state <= 2'h0;
                wb_ack_o <= `False;
            end
        endcase
    end
end

endmodule

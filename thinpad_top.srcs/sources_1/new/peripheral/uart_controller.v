module uart_controller(
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
    
    uart_txd,
    uart_rxd,
    
    int_o
);

parameter ClkFrequency = 20000000;
parameter Baud = 9600;

// clk signals
input    wb_clk_i;
input    wb_rst_i;

// WB slave if
input[31:0]       wb_dat_i;
output reg[31:0]  wb_dat_o;
input[31:0]       wb_adr_i;
input[3:0]        wb_sel_i;
input             wb_we_i;
input             wb_cyc_i;
input             wb_stb_i;
output reg        wb_ack_o;

// uart
input wire uart_rxd;
output wire uart_txd;
output wire int_o;

wire wb_acc = wb_cyc_i & wb_stb_i; // wb access

wire [7:0] ext_uart_rx;
wire ext_uart_ready, ext_uart_busy;
reg ext_uart_send_start;

reg [1:0] state;

reg serial_read_status = 1'b0;
reg already_read_status = 1'b0;
reg[7:0] serial_read_data;

assign int_o = serial_read_status ^ already_read_status;

async_receiver #(.ClkFrequency(ClkFrequency),.Baud(Baud))
    ext_uart_r(
        .clk(wb_clk_i),                       
        .RxD(uart_rxd),
        .RxD_data_ready(ext_uart_ready),
        .RxD_clear(ext_uart_ready),
        .RxD_data(ext_uart_rx)
    );
    
async_transmitter #(.ClkFrequency(ClkFrequency),.Baud(Baud))
    ext_uart_t(
        .clk(wb_clk_i),
        .TxD(uart_txd),
        .TxD_busy(ext_uart_busy),
        .TxD_start(ext_uart_send_start),
        .TxD_data(wb_dat_i[7:0])
 );
 
 always @(posedge ext_uart_ready) begin
    if (wb_rst_i) begin
         serial_read_data <= 8'b00000000;
         serial_read_status <= 1'b0;
    end else begin
         serial_read_status <= ~serial_read_status;
         serial_read_data <= ext_uart_rx;
    end
 end
 
 always @(posedge wb_clk_i) begin
    if(wb_rst_i) begin
        state <= 2'b00;
        wb_ack_o <= 1'b0;
        already_read_status <= serial_read_status;
        ext_uart_send_start <= 1'b0;
    end else if(wb_acc) begin
        case(state)
            2'b00: begin
                if(wb_we_i) begin
                    state <= 2'b01;
                    ext_uart_send_start <= 1'b1;
                end else begin
                    wb_ack_o <= 1'b1;
                    already_read_status <= serial_read_status;
                    state <= 2'b11;
                    ext_uart_send_start <= 1'b0;
                end
            end
            2'b01: state <= 2'b10;
            2'b10: begin
                state <= 2'b11;
                wb_ack_o <= 1'b1;
            end
            2'b11: begin
                state <= 2'b00;
                wb_ack_o <= 1'b0;
                ext_uart_send_start <= 1'b0;
            end
        endcase
    end
 end
 
 always @(*) begin
    if(wb_rst_i) begin
        wb_dat_o <= 32'h00000000;
    end
    else begin
        if(wb_adr_i[3:0] == 4'hc) begin
            wb_dat_o <= { 30'b0, already_read_status^serial_read_status, ~ext_uart_busy };
        end else if(wb_adr_i[3:0] == 4'h8) begin
            wb_dat_o <= { 24'b0, serial_read_data };
        end
    end
 end
 

endmodule
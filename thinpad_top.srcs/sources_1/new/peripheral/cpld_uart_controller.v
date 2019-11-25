module cpld_uart_controller(
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
    
    inout wire[7:0] data_bus,
    input wire tbre_i,
    input wire tsre_i,
    input wire data_ready_i,
    output reg rdn_o,
    output reg wrn_o,
    output wire int_o,
    input wire idle_i,
    output reg stall_o
);

assign int_o = data_ready_i; // interrupt when input data is ready

wire wb_acc = wb_cyc_i & wb_stb_i; // wb access
wire wb_wr = wb_acc & wb_we_i & ~wb_rst_i; // write
wire wb_rd = wb_acc & ~wb_we_i & ~wb_rst_i; // read


reg[2:0] state;
reg[7:0] read_buffer;
reg      bus_enable;
assign data_bus = (wb_wr & bus_enable)? {24'h0, wb_dat_i[7:0]} : 32'hzzzzzzzz;

assign wb_dat_o = (wb_adr_i[2:0] == 3'h0) ? {24'h000000, read_buffer} : {25'h0, state == 3'h0, 5'h00, data_ready_i};

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
        state <= 3'h0;
        rdn_o <= 1'b1;
        wrn_o <= 1'b1;
        wb_ack_o <= `False;
        read_buffer <= 8'h00;
        stall_o <= `False;
        bus_enable <= `False;
        end
    else begin
        case(state)
            3'h0: begin
                bus_enable <= `False;
                wrn_o <= 1'b1;
                rdn_o <= 1'b1;
                wb_ack_o <= `False;
                if(wb_adr_i[2:0] == 3'h0 && wb_acc) begin
                    stall_o <= `True;  // send stall request
                    state <= 3'h1;
                end else if(wb_adr_i[2:0] == 3'h5 && wb_acc) begin
                    wb_ack_o <= `True;  // read status register, return at once
                end
            end 
            3'h1: begin
                bus_enable <= `False;
                // wait for base ram to be stalled
                rdn_o <= 1'b1;
                wrn_o <= 1'b1;
                if(idle_i == `True) begin
                    bus_enable <= `True;
                    if(wb_wr) begin
                        state <= 3'h3;
                        wrn_o <= 1'b1;
                        end
                    else if(wb_rd) begin
                        state <= 3'h2;
                        rdn_o <= 1'b0;
                        end 
                end
            end
            // read states
            3'h2: begin
                wb_ack_o <= `True;
                state <= 3'h7;
                rdn_o <= 1'b1;
                stall_o <= `False;
                read_buffer <= data_bus;
            end
            // write states
            3'h3: begin
                wrn_o <= 1'b0;
                state <= 3'h5;
            end
            3'h5: begin
                wrn_o <= 1'b1;
                stall_o <= `False;
                bus_enable <= `False;
                if(tbre_i == 1'b1) begin
                    state <= 3'h6;
                end
            end
            3'h6: begin
                if(tsre_i == 1'b1) begin
                    state <= 3'h7;
                    wb_ack_o <= `True;
                end
            end
            3'h7: begin
                bus_enable <= `False;
                rdn_o <= 1'b1;
                wrn_o <= 1'b1;
                state <= 3'h0;
                wb_ack_o <= `False;
                stall_o <= `False;
            end
            default: state <= 3'h0;
        endcase
    end
end

endmodule

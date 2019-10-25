`timescale 1ns / 1ps

module uart_controller(
        input wire clk,
        input wire rst,
        // uart ports
        input wire[7:0] data_bus_i,
        output reg[7:0] data_bus_o,
        input wire tbre_i,
        input wire tsre_i,
        input wire data_ready_i,
        output wire rdn_o,
        output wire wrn_o,
        // module ports
        input wire ce,
        input wire we,
        input wire[7:0] write_data_i,
        output wire[7:0] read_data_o,
        output wire uart_finish
    );
    
reg[2:0] state;
reg rdn, wrn;
reg [7:0] read_data;
assign rdn_o = rdn;
assign wrn_o = wrn;
assign read_data_o = read_data;
assign uart_finish = state == 3'b111;

always @(posedge clk, posedge rst) begin
    if (rst == 1'b1) begin
        state <= 3'b000;
        rdn <= 1'b1;
        wrn <= 1'b1;
        read_data <= 8'hzz;
        data_bus_o <= 8'hzz;
    end
    else begin
        case (state)
            // initial state
            3'b000: begin
                rdn <= 1'b1;
                wrn <= 1'b1;
                read_data <= 8'hzz;
                data_bus_o <= 8'hzz;
                if (ce) begin
                    if (we)
                        state <= 3'b011;
                    else
                        state <= 3'b001;
                end
            end
            // read states
            3'b001: begin
                rdn <= 1'b0;
                if (data_ready_i == 1'b1)
                    state <= 3'b010;
            end
            3'b010: begin
                read_data <= data_bus_i;
                state <= 3'b111;
            end
            // write states
            3'b011: begin
                data_bus_o <= write_data_i;
                wrn <= 1'b0;
                state <= 3'b100;
            end
            3'b100: begin
                wrn <= 1'b1;
                state <= 3'b101;
                end
            3'b101: begin
                if (tbre_i == 1'b1 && tsre_i == 1'b1)
                    state <= 3'b111;
            end
            // final state
            3'b111: begin
                rdn <= 1'b1;
                wrn <= 1'b1;
            end
            default: begin
                rdn <= 1'b1;
                wrn <= 1'b1;
                read_data <= 8'hzz;
                data_bus_o <= 8'hzz;
                state <= 1'b000;
            end
        endcase
    end
end
endmodule

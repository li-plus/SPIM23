`timescale 1ns / 1ps

module uart_controller(
        input wire clk,
        input wire rst,
        // uart ports
        input wire[7:0] data_bus_i,
        output wire[7:0] data_bus_o,
        input wire tbre_i,
        input wire tsre_i,
        input wire data_ready_i,
        output wire rdn_o,
        output wire wrn_o,
        // module ports
        input wire ce,
        input wire we,
        input wire[7:0] data_i,  // data to write to bus
        output wire[7:0] data_o, // data read from bus
        output wire uart_finish
    );
    
reg[2:0] state;
reg rdn = 1'b1, wrn = 1'b1;
reg [7:0] read_buffer;
reg [7:0] write_buffer;
assign rdn_o = rdn;
assign wrn_o = wrn;
assign uart_finish = state == 3'h7;
assign data_bus_o = we ? {24'h0, write_buffer} : 32'hzzzzzzzz;
assign data_o = read_buffer;

always @(posedge clk, posedge rst) begin
    if (rst == 1'b1) begin
        state <= 3'h0;
        rdn <= 1'b1;
        wrn <= 1'b1;
        read_buffer <= 8'h00;
        write_buffer <= 8'h00;
    end
    else begin
        case (state)
            // initial state
            3'h0: begin
                rdn <= 1'b1;
                wrn <= 1'b1;
                if (ce) begin
                    if (we)
                        state <= 3'h3;
                    else
                        state <= 3'h1;
                end
            end
            // read states
            3'h1: begin
                if (data_ready_i == 1'b1) begin
                    state <= 3'h2;
                    rdn <= 1'b0;
                end
            end
            3'h2: begin
                read_buffer <= data_bus_i;
                state <= 3'h7;
            end
            // write states
            3'h3: begin
                write_buffer <= data_i;
                wrn <= 1'b1;
                state <= 3'h4;
            end
            3'h4: begin
                wrn <= 1'b0;
                state <= 3'h5;
            end
            3'h5: begin
                wrn <= 1'b1;
                if (tbre_i == 1'b1)
                    state <= 3'h6;
            end
            3'h6: begin
                if (tsre_i == 1'b1)
                    state <= 3'h7;
            end
            3'h7: begin
                rdn <= 1'b1;
                wrn <= 1'b1;
            end
            default: begin
                rdn <= 1'b1;
                wrn <= 1'b1;
                state <= 3'h0;
            end
        endcase
    end
end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2019 02:21:52 AM
// Design Name: 
// Module Name: uart_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_wrapper(
    input wire[7:0] uart_data_i,
    output wire[31:0] uart_data_o,
    input wire[31:0] uart_addr_i,
    output wire[2:0] uart_addr_o
);

assign uart_addr_o = (uart_addr_i[15:0] == 16'h03f8 ? 3'h0 : (uart_addr_i[15:0] == 16'h03fc ? 3'h5 : uart_addr_i[2:0]));
assign uart_data_o = uart_addr_i[15:0] == 16'h03fc ? 
                     {30'h0, uart_data_i[0], uart_data_i[5]} : {24'h000000, uart_data_i};

endmodule

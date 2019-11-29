`include "defines.vh"

module usb_controller(
        // clk signals
        input wire wb_clk_i,
        input wire wb_rst_i,
        
        // WB slave if
        input   wire[31:0]  wb_dat_i,
        output  wire[31:0]  wb_dat_o,
        input   wire[31:0]  wb_adr_i,
        input   wire        wb_we_i,
        input   wire        wb_cyc_i,
        input   wire        wb_stb_i,
        output  reg         wb_ack_o,

        // usb if
        output wire usb_a0,
        inout  wire[7:0] usb_data,
        output reg usb_wr_n,
        output reg usb_rd_n,
        output reg usb_cs_n,
        output wire usb_rst_n,
        output wire usb_dack_n,
        input  wire usb_drq_n
    );
    
    assign usb_rst_n = `True;
    assign usb_dack_n = `True;  // disable DMA ack in host mode

    reg[3:0] state;
    reg write_usb;
    reg[31:0] data_read;

    assign usb_data = write_usb ? wb_dat_i[7:0] : 8'hzz;
    assign usb_a0 = wb_adr_i[2];
    assign wb_dat_o = data_read;

    wire wb_acc = wb_cyc_i & wb_stb_i; // wb access
    wire wb_wr = wb_acc & wb_we_i & ~wb_rst_i; // write
    wire wb_rd = wb_acc & ~wb_we_i & ~wb_rst_i; // read
    
    `define USB_INIT 4'h0
    `define USB_RD_0 4'h1
    `define USB_RD_1 4'h2
    `define USB_RD_2 4'h3
    `define USB_RD_3 4'h4
    `define USB_WR_0 4'h5
    `define USB_WR_1 4'h6
    `define USB_WR_2 4'h7
    `define USB_WR_3 4'h8
    `define USB_CS_INACTIVE_0 4'h9
    `define USB_CS_INACTIVE_1 4'ha
    `define USB_CS_INACTIVE_2 4'hb
    `define USB_CS_INACTIVE_3 4'hc

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i) begin
            //state <= `USB_INIT;
            write_usb <= `False;
            data_read <= `ZeroWord;
            usb_cs_n <= 1'b1;
            usb_wr_n <= 1'b1;
            usb_rd_n <= 1'b1;
            wb_ack_o <= `False;
            state <= `USB_INIT;
        end else begin
            case(state)
                `USB_INIT: begin
                    usb_cs_n <= 1'b1;
                    usb_wr_n <= 1'b1;
                    usb_rd_n <= 1'b1;
                    wb_ack_o <= `False;
                    write_usb <= `False;
                    if(wb_rd) begin
                        usb_cs_n <= 1'b0;
                        usb_rd_n <= 1'b0;
                        state <= `USB_RD_0;
                    end else if(wb_wr) begin
                        usb_cs_n <= 1'b0;
                        usb_wr_n <= 1'b0;
                        state <= `USB_WR_0;
                        write_usb <= `True;
                    end
                end
                `USB_RD_0: state <= `USB_RD_1;
                `USB_RD_1: state <= `USB_RD_2;
                `USB_RD_2: state <= `USB_RD_3;
                `USB_RD_3: begin
                    usb_cs_n <= 1'b1;
                    usb_rd_n <= 1'b1;
                    data_read <= {24'h000000, usb_data};
                    state <= `USB_CS_INACTIVE_0;
                end
                `USB_WR_0: state <= `USB_WR_1;
                `USB_WR_1: state <= `USB_WR_2;
                `USB_WR_2: state <= `USB_WR_3;
                `USB_WR_3: begin
                    usb_cs_n <= 1'b1;
                    usb_wr_n <= 1'b1;
                    state <= `USB_CS_INACTIVE_0;
                end
                `USB_CS_INACTIVE_0: state <= `USB_CS_INACTIVE_1;
                `USB_CS_INACTIVE_1: state <= `USB_CS_INACTIVE_2;
                `USB_CS_INACTIVE_2: state <= `USB_CS_INACTIVE_3;
                `USB_CS_INACTIVE_3: begin
                    write_usb <= `False;
                    wb_ack_o <= `True;
                    state <= `USB_INIT;
                end
                default: state <= `USB_INIT;
            endcase
        end 
    end
endmodule

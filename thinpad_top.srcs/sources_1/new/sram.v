`timescale 1ns / 1ps


module SramController(
        input wire clk,
        input wire[19:0] addr,
        output wire ce,
        output wire oe,
        output wire we,
        input wire is_write,
        input wire enable
    );

reg m_oe = 1;
assign oe = m_oe;
reg m_we = 1;
assign we = m_we;
reg m_ce = 1;
assign ce = m_ce;
reg[1:0] m_state = 0;

always @(posedge clk) begin
    if (enable) begin
        m_ce <= 0;
        if (is_write) begin
            m_oe <= 1;
            case(m_state)
                2'b00: begin
                    m_we <= 1;
                    m_state <= 2'b01;
                end
                2'b01: begin
                    m_we <= 0;
                    m_state <= 2'b10;
                end
                2'b10: begin
                    m_we <= 1;
                    m_state <= 2'b11;
                end
                2'b11: begin
                    m_state <= 2'b00;
                end
            endcase
        end else begin
            m_oe <= 0;
            m_we <= 1;
        end
    end else begin
        m_ce <= 1;
    end
end
endmodule

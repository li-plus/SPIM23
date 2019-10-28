`timescale 1ns / 1ps


module SramController(
        input wire clk,
        input wire rst,
        input wire[19:0] addr,
        output wire ce,
        output wire oe,
        output wire we,
        input wire is_write,
        output wire is_finish
    );

reg m_oe = 1;
assign oe = m_oe;
reg m_we = 1;
assign we = m_we;
reg m_ce = 1;
assign ce = m_ce;
reg[2:0] m_state = 0;
assign is_finish = (m_state == 3'h7);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        m_ce <= 1;
        m_we <= 1;
        m_oe <= 1;
        m_state <= 0;
    end else begin
        m_ce <= 0;
        case (m_state)
            // initial state
            3'h0: begin
                if (is_write) begin
                    m_we <= 1;
                    m_oe <= 1;
                    m_state <= 3'h1;
                end else begin
                    m_we <= 1;
                    m_oe <= 0;
                    m_state <= 3'h4;
                end
            end
            // writing states
            3'h1: begin
                m_we <= 0;
                m_state <= 3'h2;
            end
            3'h2: begin
                m_we <= 1;
                m_state <= 3'h7;
            end
            // reading states
            3'h4: begin
                m_we <= 1;
                m_oe <= 0;
                m_state <= 3'h5;
            end
            3'h5: begin
                m_we <= 1;
                m_oe <= 0;
                m_state <= 3'h7;
            end
            // final state
            3'h7: ;
            default: begin
                m_state <= 3'h0;
            end
        endcase
    end
end
endmodule

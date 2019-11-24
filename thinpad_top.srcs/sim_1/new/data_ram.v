`include "defines.vh"

module data_ram(input wire clk,
                input wire ce,
                input wire oe,
                input wire we,
                input wire[19:0] addr,
                input wire[3:0] sel,
                inout wire[31:0] data);
    
    reg[`ByteWidth] data_mem0[0:`DataMemNum-1];
    reg[`ByteWidth] data_mem1[0:`DataMemNum-1];
    reg[`ByteWidth] data_mem2[0:`DataMemNum-1];
    reg[`ByteWidth] data_mem3[0:`DataMemNum-1];
    
    reg[`InstBus] inst_mem[0: `DataMemNum - 1];
    integer i = 0;
    initial begin
        $readmemh ("E:\\program\\cpu\\inst_rom.data", inst_mem);
        for(i = 0; i < `DataMemNum; i = i + 1) begin
            data_mem3[i] <= inst_mem[i][31:24];
            data_mem2[i] <= inst_mem[i][23:16];
            data_mem1[i] <= inst_mem[i][15:8];
            data_mem0[i] <= inst_mem[i][7:0];
        end
    end

    always @ (posedge clk) begin
        if (ce == `ChipEnable && we == `WriteEnable) begin
            if (sel[3] == 1'b1) data_mem3[addr] <= data[31:24];
            if (sel[2] == 1'b1) data_mem2[addr] <= data[23:16];
            if (sel[1] == 1'b1) data_mem1[addr] <= data[15:8];
            if (sel[0] == 1'b1) data_mem0[addr] <= data[7:0];
        end
    end
    
    assign data = (ce == `ChipEnable && oe == `ReadEnable) ? {data_mem3[addr],
                data_mem2[addr],
                data_mem1[addr],
                data_mem0[addr]} : 32'hzzzzzzzz;

endmodule

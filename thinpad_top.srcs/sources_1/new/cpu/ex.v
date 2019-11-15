`include "defines.vh"

module ex(input wire rst,

          input wire[`AluOpBus] aluop_i,
          input wire[`AluSelBus] alusel_i,
          input wire[`RegBus] reg1_i,
          input wire[`RegBus] reg2_i,
          input wire[`RegAddrBus] wd_i,
          input wire wreg_i,
          input wire[`RegBus] inst_i,
          input wire[31:0] excepttype_i,
          input wire[`RegBus] current_inst_address_i,
          
          input wire[`RegBus] hi_i,
          input wire[`RegBus] lo_i,
          
          input wire[`RegBus] wb_hi_i,
          input wire[`RegBus] wb_lo_i,
          input wire wb_whilo_i,
          
          input wire[`RegBus] mem_hi_i,
          input wire[`RegBus] mem_lo_i,
          input wire mem_whilo_i,
          
          input wire[`DoubleRegBus] hilo_temp_i,
          input wire[1:0] cnt_i,
          
          input wire[`DoubleRegBus] div_result_i,
          input wire div_ready_i,
          
          input wire[`RegBus] link_address_i,
          input wire is_in_delayslot_i,
          
          output reg[`RegAddrBus] wd_o,
          output reg wreg_o,
          output reg[`RegBus] wdata_o,
          
          output reg[`RegBus] hi_o,
          output reg[`RegBus] lo_o,
          output reg whilo_o,
          
          output reg[`DoubleRegBus] hilo_temp_o,
          output reg[1:0] cnt_o,
          
          output reg[`RegBus] div_opdata1_o,
          output reg[`RegBus] div_opdata2_o,
          output reg div_start_o,
          output reg signed_div_o,
          
          output wire[`AluOpBus] aluop_o,
          output wire[`RegBus] mem_addr_o,
          output wire[`RegBus] reg2_o,
	  
	  output wire[31:0] excepttype_o,
          output wire is_in_delayslot_o,
          output wire[`RegBus] current_inst_address_o,

          output reg stallreq,
          
          // cp0 utils
          input wire mem_cp0_reg_we,
          input wire[4:0] mem_cp0_reg_waddr,
          input wire[`RegBus] mem_cp0_reg_data,
          
          input wire wb_cp0_reg_we,
          input wire[4:0] wb_cp0_reg_waddr,
          input wire[`RegBus] wb_cp0_reg_data,
          
          input wire[`RegBus] cp0_reg_data_i,
          output reg[4:0] cp0_reg_raddr_o,
          output reg cp0_reg_we_o,
          output reg[4:0] cp0_reg_waddr_o,
          output reg[`RegBus] cp0_reg_data_o
);
    
    reg[`RegBus] logicres;
    reg[`RegBus] shiftres;
    reg[`RegBus] moveres;
    reg[`RegBus] arithmeticres;
    reg[`DoubleRegBus] mulres;
    reg[`RegBus] HI;
    reg[`RegBus] LO;
    wire[`RegBus] reg2_i_mux;
    wire[`RegBus] reg1_i_not;
    wire[`RegBus] result_sum;
    wire ov_sum;
    wire reg1_eq_reg2;
    wire reg1_lt_reg2;
    wire[`RegBus] opdata1_mult;
    wire[`RegBus] opdata2_mult;
    wire[`DoubleRegBus] hilo_temp;
    reg[`DoubleRegBus] hilo_temp1;
    reg stallreq_for_madd_msub;
    reg stallreq_for_div;
    reg trap_assert;
    reg ov_assert;
    
    assign aluop_o = aluop_i;
    
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
    
    assign reg2_o = reg2_i;

    assign excepttype_o = {excepttype_i[31:12], ov_assert, trap_assert, excepttype_i[9:8], 8'h0};

    assign is_in_delayslot_o = is_in_delayslot_i;
    assign current_inst_address_o = current_inst_address_i;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            logicres <= `ZeroWord;
        end
        else begin
            case (aluop_i)
                `ALU_OR_OP: logicres  <= reg1_i | reg2_i;
                `ALU_AND_OP: logicres <= reg1_i & reg2_i;
                `ALU_NOR_OP: logicres <= ~(reg1_i |reg2_i);
                `ALU_XOR_OP: logicres <= reg1_i ^ reg2_i;
                default: logicres     <= `ZeroWord;
            endcase
        end
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            shiftres <= `ZeroWord;
        end
        else begin
            case (aluop_i)
                `ALU_SLL_OP:  shiftres <= reg2_i << reg1_i[4:0];
                `ALU_SRL_OP:  shiftres <= reg2_i >> reg1_i[4:0];
                `ALU_SRA_OP:  shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]}))
                | reg2_i >> reg1_i[4:0];
                default:  shiftres <= `ZeroWord;
            endcase
        end
    end
    
    assign reg2_i_mux = (aluop_i == `ALU_SUB_OP || aluop_i == `ALU_SUBU_OP ||
                         aluop_i == `ALU_SLT_OP || aluop_i == `ALU_TLT_OP || aluop_i == `ALU_TLTI_OP || 
                         aluop_i == `ALU_TGE_OP || aluop_i == `ALU_TGEI_OP) ? (~reg2_i) + 1 : reg2_i;
    
    assign result_sum = reg1_i + reg2_i_mux;
    
    assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
    ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));
    
    assign reg1_lt_reg2 = (aluop_i == `ALU_SLT_OP || aluop_i == `ALU_TLT_OP || aluop_i == `ALU_TLTI_OP || 
                           aluop_i == `ALU_TGE_OP || aluop_i == `ALU_TGEI_OP) ?
    ((reg1_i[31] && !reg2_i[31]) ||
    (!reg1_i[31] && !reg2_i[31] && result_sum[31])||
    (reg1_i[31] && reg2_i[31] && result_sum[31]))
    :	(reg1_i < reg2_i);
    
    assign reg1_i_not = ~reg1_i;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
        end
        else begin
            case (aluop_i)
                `ALU_SLT_OP, `ALU_SLTU_OP:                               arithmeticres <= reg1_lt_reg2;
                `ALU_ADD_OP, `ALU_ADDU_OP, `ALU_ADDI_OP, `ALU_ADDIU_OP:  arithmeticres <= result_sum;
                `ALU_SUB_OP, `ALU_SUBU_OP:                               arithmeticres <= result_sum;
                `ALU_CLZ_OP:
                arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 :
                reg1_i[28] ? 3 : reg1_i[27] ? 4 : reg1_i[26] ? 5 :
                reg1_i[25] ? 6 : reg1_i[24] ? 7 : reg1_i[23] ? 8 :
                reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 :
                reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 :
                reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
                reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 :
                reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 :
                reg1_i[4] ? 27 : reg1_i[3] ? 28 : reg1_i[2] ? 29 :
                reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32 ;
                `ALU_CLO_OP:
                arithmeticres <= (reg1_i_not[31] ? 0 : reg1_i_not[30] ? 1 : reg1_i_not[29] ? 2 :
                reg1_i_not[28] ? 3 : reg1_i_not[27] ? 4 : reg1_i_not[26] ? 5 :
                reg1_i_not[25] ? 6 : reg1_i_not[24] ? 7 : reg1_i_not[23] ? 8 :
                reg1_i_not[22] ? 9 : reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
                reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 : reg1_i_not[17] ? 14 :
                reg1_i_not[16] ? 15 : reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 :
                reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 : reg1_i_not[11] ? 20 :
                reg1_i_not[10] ? 21 : reg1_i_not[9] ? 22 : reg1_i_not[8] ? 23 :
                reg1_i_not[7] ? 24 : reg1_i_not[6] ? 25 : reg1_i_not[5] ? 26 :
                reg1_i_not[4] ? 27 : reg1_i_not[3] ? 28 : reg1_i_not[2] ? 29 :
                reg1_i_not[1] ? 30 : reg1_i_not[0] ? 31 : 32) ;
                default: arithmeticres <= `ZeroWord;
            endcase
        end
    end

    always @(*) begin
        if(rst == `RstEnable) begin
            trap_assert <= `TrapNotAssert;
        end
        else begin
            trap_assert <= `TrapNotAssert;
            case(aluop_i)
            `ALU_TEQ_OP, `ALU_TEQI_OP: if(reg1_i == reg2_i) trap_assert <= `TrapAssert;
            `ALU_TGE_OP, `ALU_TGEI_OP, `ALU_TGEIU_OP, `ALU_TGEU_OP: if(~reg1_lt_reg2) trap_assert <= `TrapAssert;
            `ALU_TLT_OP, `ALU_TLTI_OP, `ALU_TLTIU_OP, `ALU_TLTU_OP: if(reg1_lt_reg2) trap_assert <= `TrapAssert;
            `ALU_TNE_OP, `ALU_TNEI_OP: if(reg1_i != reg2_i) trap_assert <= `TrapAssert;
            default: ;
            endcase
        end
    end
    
    
    assign opdata1_mult = (((aluop_i == `ALU_MUL_OP) || (aluop_i == `ALU_MULT_OP) ||
    (aluop_i == `ALU_MADD_OP) || (aluop_i == `ALU_MSUB_OP))
    && (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
    
    assign opdata2_mult = (((aluop_i == `ALU_MUL_OP) || (aluop_i == `ALU_MULT_OP) ||
    (aluop_i == `ALU_MADD_OP) || (aluop_i == `ALU_MSUB_OP))
    && (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;
    
    assign hilo_temp = opdata1_mult * opdata2_mult;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            mulres <= {`ZeroWord,`ZeroWord};
        end
        else if ((aluop_i == `ALU_MULT_OP) || (aluop_i == `ALU_MUL_OP) ||
            (aluop_i == `ALU_MADD_OP) || (aluop_i == `ALU_MSUB_OP))begin
            if (reg1_i[31] ^ reg2_i[31] == 1'b1)
                mulres <= ~hilo_temp + 1;
            else
                mulres <= hilo_temp;
            end
        else
            mulres <= hilo_temp;
    end
    
    
    always @ (*) begin
        if (rst == `RstEnable) {HI,LO} <= {`ZeroWord,`ZeroWord};
        else if (mem_whilo_i == `WriteEnable) {HI,LO} <= {mem_hi_i,mem_lo_i};
        else if (wb_whilo_i == `WriteEnable) {HI,LO} <= {wb_hi_i,wb_lo_i};
        else {HI,LO} <= {hi_i,lo_i};
    end
    
    always @ (*) begin
        stallreq = stallreq_for_madd_msub || stallreq_for_div;
    end
    
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            hilo_temp_o            <= {`ZeroWord,`ZeroWord};
            cnt_o                  <= 2'b00;
            stallreq_for_madd_msub <= `NoStop;
        end
        else begin
            
            case (aluop_i)
                `ALU_MADD_OP, `ALU_MADDU_OP:  begin
                    if (cnt_i == 2'b00) begin
                        hilo_temp_o            <= mulres;
                        cnt_o                  <= 2'b01;
                        stallreq_for_madd_msub <= `Stop;
                        hilo_temp1             <= {`ZeroWord,`ZeroWord};
                    end
                    else if (cnt_i == 2'b01) begin
                        hilo_temp_o            <= {`ZeroWord,`ZeroWord};
                        cnt_o                  <= 2'b10;
                        hilo_temp1             <= hilo_temp_i + {HI,LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                `ALU_MSUB_OP, `ALU_MSUBU_OP:  begin
                    if (cnt_i == 2'b00) begin
                        hilo_temp_o            <= ~mulres + 1 ;
                        cnt_o                  <= 2'b01;
                        stallreq_for_madd_msub <= `Stop;
                    end
                    else if (cnt_i == 2'b01)begin
                        hilo_temp_o            <= {`ZeroWord,`ZeroWord};
                        cnt_o                  <= 2'b10;
                        hilo_temp1             <= hilo_temp_i + {HI,LO};
                        stallreq_for_madd_msub <= `NoStop;
                    end
                end
                default:	begin
                    hilo_temp_o            <= {`ZeroWord,`ZeroWord};
                    cnt_o                  <= 2'b00;
                    stallreq_for_madd_msub <= `NoStop;
                end
            endcase
        end
    end
    
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o    <= `ZeroWord;
            div_opdata2_o    <= `ZeroWord;
            div_start_o      <= `DivStop;
            signed_div_o     <= 1'b0;
        end
        else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o    <= `ZeroWord;
            div_opdata2_o    <= `ZeroWord;
            div_start_o      <= `DivStop;
            signed_div_o     <= 1'b0;
            case (aluop_i)
                `ALU_DIV_OP:  begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o    <= reg1_i;
                        div_opdata2_o    <= reg2_i;
                        div_start_o      <= `DivStart;
                        signed_div_o     <= 1'b1;
                        stallreq_for_div <= `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o    <= reg1_i;
                        div_opdata2_o    <= reg2_i;
                        div_start_o      <= `DivStop;
                        signed_div_o     <= 1'b1;
                        stallreq_for_div <= `NoStop;
                    end
                    else begin
                        div_opdata1_o    <= `ZeroWord;
                        div_opdata2_o    <= `ZeroWord;
                        div_start_o      <= `DivStop;
                        signed_div_o     <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                end
                `ALU_DIVU_OP:  begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o    <= reg1_i;
                        div_opdata2_o    <= reg2_i;
                        div_start_o      <= `DivStart;
                        signed_div_o     <= 1'b0;
                        stallreq_for_div <= `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o    <= reg1_i;
                        div_opdata2_o    <= reg2_i;
                        div_start_o      <= `DivStop;
                        signed_div_o     <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                    else begin
                        div_opdata1_o    <= `ZeroWord;
                        div_opdata2_o    <= `ZeroWord;
                        div_start_o      <= `DivStop;
                        signed_div_o     <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end
                end
                default: ;
            endcase
        end
    end
    
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end
        else begin
            moveres <= `ZeroWord;
            case (aluop_i)
                `ALU_MFHI_OP: moveres <= HI;
                `ALU_MFLO_OP: moveres <= LO;
                `ALU_MOVZ_OP: moveres <= reg1_i;
                `ALU_MOVN_OP: moveres <= reg1_i;
                `ALU_MFC0_OP: begin
                    cp0_reg_raddr_o <= inst_i[15:11];
                    moveres <= cp0_reg_data_i;
                    // RAW data conflict
                    if(mem_cp0_reg_we == `WriteEnable && mem_cp0_reg_waddr == inst_i[15:11])
                        moveres <= mem_cp0_reg_data;
                    else if (wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_waddr == inst_i[15:11])
                        moveres <= wb_cp0_reg_data;
                end
                default: ;
            endcase
        end
    end
    
    always @ (*) begin
        wd_o <= wd_i;
        
        if (((aluop_i == `ALU_ADD_OP) || (aluop_i == `ALU_ADDI_OP) ||
            (aluop_i == `ALU_SUB_OP)) && (ov_sum == 1'b1)) begin
            wreg_o <= `WriteDisable;
            ov_assert <= `True;   // overflow occurred
        end
        else begin
            wreg_o <= wreg_i;
            ov_assert <= `False;
        end
        
        case (alusel_i)
            `ALU_SEL_LOGIC: wdata_o       <= logicres;
            `ALU_SEL_SHIFT: wdata_o       <= shiftres;
            `ALU_SEL_MOVE: wdata_o        <= moveres;
            `ALU_SEL_ARITHMETIC: wdata_o  <= arithmeticres;
            `ALU_SEL_MUL: wdata_o         <= mulres[31:0];
            `ALU_SEL_JUMP_BRANCH: wdata_o <= link_address_i;
            default: wdata_o              <= `ZeroWord;
        endcase
    end
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            whilo_o      <= `WriteDisable;
            {hi_o, lo_o} <= {`ZeroWord, `ZeroWord};
        end
        else if ((aluop_i == `ALU_MULT_OP) || (aluop_i == `ALU_MULTU_OP)) begin
            whilo_o      <= `WriteEnable;
            {hi_o, lo_o} <= mulres;
            end
        else if ((aluop_i == `ALU_MADD_OP) || (aluop_i == `ALU_MADDU_OP)) begin
            whilo_o      <= `WriteEnable;
            {hi_o, lo_o} <= hilo_temp1;
            end
        else if ((aluop_i == `ALU_MSUB_OP) || (aluop_i == `ALU_MSUBU_OP)) begin
            whilo_o      <= `WriteEnable;
            {hi_o, lo_o} <= hilo_temp1;
            end
        else if ((aluop_i == `ALU_DIV_OP) || (aluop_i == `ALU_DIVU_OP)) begin
            whilo_o      <= `WriteEnable;
            {hi_o, lo_o} <= div_result_i;
            end
        else if (aluop_i == `ALU_MTHI_OP) begin
            whilo_o      <= `WriteEnable;
            {hi_o, lo_o} <= {reg1_i, LO};
        end
            else if (aluop_i == `ALU_MTLO_OP) begin
            whilo_o      <= `WriteEnable;
            {hi_o, lo_o} <= {HI, reg1_i};
            end
        else begin
            whilo_o      <= `WriteDisable;
            {hi_o, lo_o} <= {`ZeroWord, `ZeroWord};
        end
    end
    
    always @ (*) begin
        if(rst == `RstEnable) begin
            cp0_reg_waddr_o <= 5'b00000;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_data_o <= `ZeroWord;
        end else if(aluop_i == `ALU_MTC0_OP) begin
            cp0_reg_waddr_o <= inst_i[15:11];
            cp0_reg_we_o <= `WriteEnable;
            cp0_reg_data_o <= reg1_i;
      end else begin
            cp0_reg_waddr_o <= 5'b00000;
            cp0_reg_we_o <= `WriteDisable;
            cp0_reg_data_o <= `ZeroWord;
        end                
    end
    
endmodule

`include "defines.vh"

module id(input wire rst,
          input wire[`InstAddrBus] pc_i,
          input wire[`InstBus] inst_i,
          
          input wire[`AluOpBus] ex_aluop_i,
          input wire ex_wreg_i,
          input wire[`RegBus] ex_wdata_i,
          input wire[`RegAddrBus] ex_wd_i,
          
          input wire mem_wreg_i,
          input wire[`RegBus] mem_wdata_i,
          input wire[`RegAddrBus] mem_wd_i,
          
          input wire[`RegBus] reg1_data_i,
          input wire[`RegBus] reg2_data_i,
          
          input wire is_in_delayslot_i,
          input wire[31:0] excepttype_i,
          
          output reg reg1_read_o,
          output reg reg2_read_o,
          output reg[`RegAddrBus] reg1_addr_o,
          output reg[`RegAddrBus] reg2_addr_o,
          
          output reg[`AluOpBus] aluop_o,
          output reg[`AluSelBus] alusel_o,
          output reg[`RegBus] reg1_o,
          output reg[`RegBus] reg2_o,
          output reg[`RegAddrBus] wd_o,
          output reg wreg_o,
          output wire[`RegBus] inst_o,
          
          output reg next_inst_in_delayslot_o,
          output reg branch_flag_o,
          output reg[`RegBus] branch_target_address_o,
          output reg[`RegBus] link_addr_o,
          output reg is_in_delayslot_o,
          
          output wire[31:0] excepttype_o,
          output wire[`RegBus] current_inst_address_o,
	  
	  output wire stallreq
);
    
    /**
     Reference:
     R-Inst  op code |   rs  |   rt  |   rd  | shamt |  funct
     6 bits     5       5       5       5        6
     I-Inst  op code |   rs  |   rt  |           imm
     16
     J-Inst  op code |           addr
     26
     **/
    
    
    wire[5:0] op_code  = inst_i[31:26];
    wire[4:0] shamt    = inst_i[10:6];
    wire[5:0] funct    = inst_i[5:0];
    wire[4:0] rs       = inst_i[25:21];
    wire[4:0] rt       = inst_i[20:16];
    wire[4:0] rd       = inst_i[15:11];
    wire[15:0] imm_inst = inst_i[15:0];
    reg[`RegBus]	imm;
    reg instvalid;
    wire[`RegBus] pc_plus_8;
    wire[`RegBus] pc_plus_4;
    wire[`RegBus] imm_sll2_signedext;
    
    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;
    reg excepttype_is_syscall;
    reg excepttype_is_eret;
    
    assign pc_plus_8          = pc_i + 8;
    assign pc_plus_4          = pc_i + 4;
    assign imm_sll2_signedext = {{14{inst_i[15]}}, imm_inst, 2'b00 };
    assign stallreq           = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    assign pre_inst_is_load = ((ex_aluop_i == `ALU_LB_OP) ||
    (ex_aluop_i == `ALU_LBU_OP)||
    (ex_aluop_i == `ALU_LH_OP) ||
    (ex_aluop_i == `ALU_LHU_OP)||
    (ex_aluop_i == `ALU_LW_OP) ||
    (ex_aluop_i == `ALU_LWR_OP)||
    (ex_aluop_i == `ALU_LWL_OP)||
    (ex_aluop_i == `ALU_LL_OP) ||
    (ex_aluop_i == `ALU_SC_OP)) ? `True : `False;
    
    assign inst_o = inst_i;
    // Pass exceptions occured in if on
    assign excepttype_o = {excepttype_i[31:13], excepttype_is_eret, excepttype_i[11:10], instvalid, excepttype_is_syscall, excepttype_i[7:0]};
    assign current_inst_address_o = pc_i;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o                  <= `ALU_NOP_OP;
            alusel_o                 <= `ALU_SEL_NOP;
            wd_o                     <= `NOPRegAddr;
            wreg_o                   <= `WriteDisable;
            instvalid                <= `InstValid;
            reg1_read_o              <= `ReadDisable;
            reg2_read_o              <= `ReadDisable;
            reg1_addr_o              <= `NOPRegAddr;
            reg2_addr_o              <= `NOPRegAddr;
            imm                      <= `ZeroWord;
            link_addr_o              <= `ZeroWord;
            branch_target_address_o  <= `ZeroWord;
            branch_flag_o            <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
	    excepttype_is_syscall    <= `False;
	    excepttype_is_eret       <= `False;	
        end
        else begin
            aluop_o                  <= `ALU_NOP_OP;
            alusel_o                 <= `ALU_SEL_NOP;
            wd_o                     <= rd;
            wreg_o                   <= `WriteDisable;
            instvalid                <= `InstInvalid;
            reg1_read_o              <= `ReadDisable;
            reg2_read_o              <= `ReadDisable;
            reg1_addr_o              <= rs;
            reg2_addr_o              <= rt;
            imm                      <= `ZeroWord;
            link_addr_o              <= `ZeroWord;
            branch_target_address_o  <= `ZeroWord;
            branch_flag_o            <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
            excepttype_is_syscall    <= `False;
            excepttype_is_eret       <= `False;
            case (op_code)
                `EXE_SPECIAL_INST: begin
                    case (shamt)
                        5'b00000: begin
                            case (funct)
                                `EXE_OR:	begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_OR_OP;
                                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_AND:	begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_AND_OP;
                                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_XOR:	begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_XOR_OP;
                                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_NOR:	begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_NOR_OP;
                                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SLLV: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SLL_OP;
                                    alusel_o  <= `ALU_SEL_SHIFT; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SRLV: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SRL_OP;
                                    alusel_o  <= `ALU_SEL_SHIFT; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SRAV: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SRA_OP;
                                    alusel_o  <= `ALU_SEL_SHIFT; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MFHI: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_MFHI_OP;
                                    alusel_o  <= `ALU_SEL_MOVE; reg1_read_o  <= `ReadDisable;	reg2_read_o  <= `ReadDisable;
                                    if(rs == `NOPRegAddr && rt == `NOPRegAddr)
										instvalid <= `InstValid;
                                end
                                `EXE_MFLO: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_MFLO_OP;
                                    alusel_o  <= `ALU_SEL_MOVE; reg1_read_o  <= `ReadDisable;	reg2_read_o  <= `ReadDisable;
                                    if(rs == `NOPRegAddr && rt == `NOPRegAddr)
										instvalid <= `InstValid;
                                end
                                `EXE_MTHI: begin
                                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_MTHI_OP;
                                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadDisable;
									if(rt == `NOPRegAddr && rd == `NOPRegAddr)
										instvalid <= `InstValid;
                                end
                                `EXE_MTLO: begin
                                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_MTLO_OP;
                                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadDisable;
									if(rt == `NOPRegAddr && rd == `NOPRegAddr)
										instvalid <= `InstValid;
                                end
                                `EXE_MOVN: begin
                                    aluop_o   <= `ALU_MOVN_OP;
                                    alusel_o  <= `ALU_SEL_MOVE; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                    if (reg2_o != `ZeroWord) begin
                                        wreg_o <= `WriteEnable;
                                    end
                                    else begin
                                        wreg_o <= `WriteDisable;
                                    end
                                end
                                `EXE_MOVZ: begin
                                    aluop_o   <= `ALU_MOVZ_OP;
                                    alusel_o  <= `ALU_SEL_MOVE; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                    if (reg2_o == `ZeroWord) begin
                                        wreg_o <= `WriteEnable;
                                    end
                                    else begin
                                        wreg_o <= `WriteDisable;
                                    end
                                end
                                `EXE_SLT: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SLT_OP;
                                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SLTU: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SLTU_OP;
                                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SYNC: begin
                                    wreg_o    <= `WriteDisable; aluop_o    <= `ALU_NOP_OP;
                                    alusel_o  <= `ALU_SEL_NOP; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_ADD: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_ADD_OP;
                                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_ADDU: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_ADDU_OP;
                                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SUB: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SUB_OP;
                                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SUBU: begin
                                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SUBU_OP;
                                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MULT: begin
                                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_MULT_OP;
                                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                                end
                                `EXE_MULTU: begin
                                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_MULTU_OP;
                                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                                end
                                `EXE_DIV: begin
                                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_DIV_OP;
                                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                                end
                                `EXE_DIVU: begin
                                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_DIVU_OP;
                                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                                end
                                `EXE_JR: begin
                                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_JR_OP;
                                    alusel_o    <= `ALU_SEL_JUMP_BRANCH; reg1_read_o    <= `ReadEnable;	reg2_read_o    <= `ReadDisable;
                                    link_addr_o <= `ZeroWord;
                                    
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o           <= `Branch;
                                    
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    if(rt == `NOPRegAddr && rd == `NOPRegAddr)
										instvalid <= `InstValid;
                                end
                                `EXE_JALR: begin
                                    wreg_o      <= `WriteEnable; aluop_o      <= `ALU_JALR_OP;
                                    alusel_o    <= `ALU_SEL_JUMP_BRANCH; reg1_read_o    <= `ReadEnable;	reg2_read_o    <= `ReadDisable;
                                    wd_o        <= rd;
                                    link_addr_o <= pc_plus_8;
                                    
                                    branch_target_address_o <= reg1_o;
                                    branch_flag_o           <= `Branch;
                                    
                                    next_inst_in_delayslot_o <= `InDelaySlot;
                                    if(rt == `NOPRegAddr)
										instvalid <= `InstValid;
                                end
                                default: ;
                            endcase
                        end
                        default: ;
                    endcase
                    case (funct)
                        `EXE_TEQ: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TEQ_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadEnable;  // TODO
                            instvalid <= `InstValid;
                        end
                        `EXE_TGE: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TGE_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        `EXE_TGEU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TGEU_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        `EXE_TLT: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TLT_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        `EXE_TLTU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TLTU_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        `EXE_TNE: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TNE_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadEnable;
                            instvalid <= `InstValid;
                        end
                        `EXE_SYSCALL: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_SYSCALL_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadDisable; reg2_read_o <= `ReadDisable;
                            instvalid <= `InstValid; excepttype_is_syscall<= `True;
                        end
                        default: ;
                    endcase
                    if (inst_i[25:21] == 11'b00000000000) begin
                        if (funct == `EXE_SLL) begin
                            wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SLL_OP;
                            alusel_o  <= `ALU_SEL_SHIFT; reg1_read_o  <= 1'b0;    reg2_read_o  <= 1'b1;
                            imm[4:0]  <= inst_i[10:6]; wd_o  <= rd;
                            instvalid <= `InstValid;
                        end
                        else if (funct == `EXE_SRL) begin
                            wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SRL_OP;
                            alusel_o  <= `ALU_SEL_SHIFT; reg1_read_o  <= 1'b0;    reg2_read_o  <= 1'b1;
                            imm[4:0]  <= inst_i[10:6]; wd_o  <= rd;
                            instvalid <= `InstValid;
                        end
                        else if (funct == `EXE_SRA) begin
                            wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SRA_OP;
                            alusel_o  <= `ALU_SEL_SHIFT; reg1_read_o  <= 1'b0;    reg2_read_o  <= 1'b1;
                            imm[4:0]  <= inst_i[10:6]; wd_o  <= rd;
                            instvalid <= `InstValid;
                        end
                    end
                end
                `EXE_ORI: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_OR_OP;
                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {16'h0, imm_inst}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_ANDI: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_AND_OP;
                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {16'h0, imm_inst}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_XORI: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_XOR_OP;
                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {16'h0, imm_inst}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_LUI: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_OR_OP;
                    alusel_o  <= `ALU_SEL_LOGIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {imm_inst, 16'h0}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_SLTI: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SLT_OP;
                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}}, imm_inst}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_SLTIU: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_SLTU_OP;
                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}}, imm_inst}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_PREF: begin
                    wreg_o    <= `WriteDisable; aluop_o    <= `ALU_NOP_OP;
                    alusel_o  <= `ALU_SEL_NOP; reg1_read_o  <= `ReadDisable; reg2_read_o  <= `ReadDisable;
                    instvalid <= `InstValid;
                end
                `EXE_ADDI: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_ADDI_OP;
                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}}, imm_inst}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_ADDIU: begin
                    wreg_o    <= `WriteEnable; aluop_o    <= `ALU_ADDIU_OP;
                    alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                    imm       <= {{16{inst_i[15]}}, imm_inst}; wd_o       <= rt;
                    instvalid <= `InstValid;
                end
                `EXE_J: begin
                    wreg_o                   <= `WriteDisable; aluop_o                   <= `ALU_J_OP;
                    alusel_o                 <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadDisable;	reg2_read_o  <= `ReadDisable;
                    link_addr_o              <= `ZeroWord;
                    branch_target_address_o  <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                    branch_flag_o            <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    instvalid                <= `InstValid;
                end
                `EXE_JAL: begin
                    wreg_o                   <= `WriteEnable; aluop_o                   <= `ALU_JAL_OP;
                    alusel_o                 <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadDisable;	reg2_read_o  <= `ReadDisable;
                    wd_o                     <= 5'b11111;
                    link_addr_o              <= pc_plus_8 ;
                    branch_target_address_o  <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                    branch_flag_o            <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    instvalid                <= `InstValid;
                end
                `EXE_BEQ: begin
                    wreg_o    <= `WriteDisable; aluop_o    <= `ALU_BEQ_OP;
                    alusel_o  <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                    instvalid <= `InstValid;
                    if (reg1_o == reg2_o) begin
                        branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o            <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_BGTZ: begin
                    wreg_o    <= `WriteDisable; aluop_o    <= `ALU_BGTZ_OP;
                    alusel_o  <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    if(rt == `NOPRegAddr)
						instvalid <= `InstValid;
                    if (reg1_o[31] == 1'b0 && reg1_o != `ZeroWord) begin
                        branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o            <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_BLEZ: begin
                    wreg_o    <= `WriteDisable; aluop_o    <= `ALU_BLEZ_OP;
                    alusel_o  <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    if(rt == `NOPRegAddr)
						instvalid <= `InstValid;
                    if (reg1_o[31] == 1'b1 || reg1_o == `ZeroWord) begin
                        branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o            <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_BNE: begin
                    wreg_o    <= `WriteDisable; aluop_o    <= `ALU_BLEZ_OP;
                    alusel_o  <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                    instvalid <= `InstValid;
                    if (reg1_o != reg2_o) begin
                        branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                        branch_flag_o            <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                end
                `EXE_LB: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LB_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_LBU: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LBU_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_LH: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LH_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_LHU: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LHU_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_LW: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LW_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_LL: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LL_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadDisable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_LWL: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LWL_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadEnable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_LWR: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_LWR_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o  <= `ReadEnable; reg2_read_o  <= `ReadEnable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                end
                `EXE_SB: begin
                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_SB_OP;
                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                    alusel_o    <= `ALU_SEL_LOAD_STORE;
                end
                `EXE_SH: begin
                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_SH_OP;
                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                    alusel_o    <= `ALU_SEL_LOAD_STORE;
                end
                `EXE_SW: begin
                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_SW_OP;
                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                    alusel_o    <= `ALU_SEL_LOAD_STORE;
                end
                `EXE_SWL: begin
                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_SWL_OP;
                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                    alusel_o    <= `ALU_SEL_LOAD_STORE;
                end
                `EXE_SWR: begin
                    wreg_o      <= `WriteDisable; aluop_o      <= `ALU_SWR_OP;
                    reg1_read_o <= `ReadEnable;	reg2_read_o <= `ReadEnable; instvalid <= `InstValid;
                    alusel_o    <= `ALU_SEL_LOAD_STORE;
                end
                `EXE_SC: begin
                    wreg_o   <= `WriteEnable; aluop_o   <= `ALU_SC_OP;
                    alusel_o <= `ALU_SEL_LOAD_STORE; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadEnable;
                    wd_o     <= rt; instvalid     <= `InstValid;
                    alusel_o <= `ALU_SEL_LOAD_STORE;
                end
                `EXE_REGIMM_INST: begin
                    case (rt)
                        `EXE_BGEZ:	begin
                            wreg_o    <= `WriteDisable; aluop_o    <= `ALU_BGEZ_OP;
                            alusel_o  <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                            instvalid <= `InstValid;
                            if (reg1_o[31] == 1'b0) begin
                                branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o            <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        end
                        `EXE_BGEZAL: begin
                            wreg_o      <= `WriteEnable; aluop_o      <= `ALU_BGEZAL_OP;
                            alusel_o    <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                            link_addr_o <= pc_plus_8;
                            wd_o        <= 5'b11111; instvalid        <= `InstValid;
                            if (reg1_o[31] == 1'b0) begin
                                branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o            <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        end
                        `EXE_BLTZ: begin
                            wreg_o    <= `WriteDisable; aluop_o    <= `ALU_BGEZAL_OP;
                            alusel_o  <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                            instvalid <= `InstValid;
                            if (reg1_o[31] == 1'b1) begin
                                branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o            <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        end
                        `EXE_BLTZAL: begin
                            wreg_o      <= `WriteEnable; aluop_o      <= `ALU_BGEZAL_OP;
                            alusel_o    <= `ALU_SEL_JUMP_BRANCH; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                            link_addr_o <= pc_plus_8;
                            wd_o        <= 5'b11111; instvalid        <= `InstValid;
                            if (reg1_o[31] == 1'b1) begin
                                branch_target_address_o  <= pc_plus_4 + imm_sll2_signedext;
                                branch_flag_o            <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        end
                        `EXE_TEQI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TEQI_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadDisable;
                            instvalid <= `InstValid; imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TGEI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TGEI_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadDisable;
                            instvalid <= `InstValid; imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TGEIU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TGEIU_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadDisable;
                            instvalid <= `InstValid; imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TLTI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TLTI_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadDisable;
                            instvalid <= `InstValid; imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TLTIU: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TLTIU_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadDisable;
                            instvalid <= `InstValid; imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        `EXE_TNEI: begin
                            wreg_o <= `WriteDisable; aluop_o <= `ALU_TNEI_OP;
                            alusel_o <= `ALU_SEL_NOP; reg1_read_o <= `ReadEnable; reg2_read_o <= `ReadDisable;
                            instvalid <= `InstValid; imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                        end
                        default: ;
                    endcase
                end
                `EXE_SPECIAL2_INST: begin
                    case (funct)
                        `EXE_CLZ: begin
                            wreg_o    <= `WriteEnable; aluop_o    <= `ALU_CLZ_OP;
                            alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                            instvalid <= `InstValid;
                        end
                        `EXE_CLO: begin
                            wreg_o    <= `WriteEnable; aluop_o    <= `ALU_CLO_OP;
                            alusel_o  <= `ALU_SEL_ARITHMETIC; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadDisable;
                            instvalid <= `InstValid;
                        end
                        `EXE_MUL: begin
                            wreg_o    <= `WriteEnable; aluop_o    <= `ALU_MUL_OP;
                            alusel_o  <= `ALU_SEL_MUL; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                            if(shamt == `NOPRegAddr)
								instvalid <= `InstValid;
                        end
                        `EXE_MADD: begin
                            wreg_o    <= `WriteDisable; aluop_o    <= `ALU_MADD_OP;
                            alusel_o  <= `ALU_SEL_MUL; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                            if(shamt == `NOPRegAddr && rd == `NOPRegAddr)
								instvalid <= `InstValid;
                        end
                        `EXE_MADDU: begin
                            wreg_o    <= `WriteDisable; aluop_o    <= `ALU_MADDU_OP;
                            alusel_o  <= `ALU_SEL_MUL; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                            if(shamt == `NOPRegAddr && rd == `NOPRegAddr)
								instvalid <= `InstValid;
                        end
                        `EXE_MSUB: begin
                            wreg_o    <= `WriteDisable; aluop_o    <= `ALU_MSUB_OP;
                            alusel_o  <= `ALU_SEL_MUL; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                            if(shamt == `NOPRegAddr && rd == `NOPRegAddr)
								instvalid <= `InstValid;
                        end
                        `EXE_MSUBU: begin
                            wreg_o    <= `WriteDisable; aluop_o    <= `ALU_MSUBU_OP;
                            alusel_o  <= `ALU_SEL_MUL; reg1_read_o  <= `ReadEnable;	reg2_read_o  <= `ReadEnable;
                            if(shamt == `NOPRegAddr && rd == `NOPRegAddr)
								instvalid <= `InstValid;
                        end
                        default:	begin
                        end
                    endcase //EXE_SPECIAL_INST2 case
                end
                `EXE_COP0_INST: begin
                    if(inst_i[25:6] == 20'b1_00000000_00000000_000) begin
                        case(funct)
                            `EXE_ERET: begin
                                wreg_o <= `WriteDisable; aluop_o <= `ALU_ERET_OP; alusel_o <= `ALU_SEL_NOP;
                                reg1_read_o <= `ReadDisable; reg2_read_o <= `ReadDisable; instvalid <= `InstValid;
                                excepttype_is_eret <= `True;
                            end
                            `EXE_TLBWI: begin
                                instvalid <= `InstValid;
                            end
                            `EXE_TLBWR: begin
                                instvalid <= `InstValid;
                            end
                            `EXE_TLBP: begin
                                instvalid <= `InstValid;
                            end
                            `EXE_TLBR: begin
                                instvalid <= `InstValid;
                            end
                        endcase
                    end
                    case(rs)
                        `EXE_CP0_MF: begin
                            if(inst_i[10:3] == 8'b00000000) begin
                                aluop_o <= `ALU_MFC0_OP;
                                alusel_o <= `ALU_SEL_MOVE;
                                wd_o <= rt;
                                wreg_o <= `WriteEnable;
                                instvalid <= `InstValid;
                                reg1_read_o <= `ReadDisable;
                                reg2_read_o <= `ReadDisable;
                            end
                        end
                        `EXE_CP0_MT: begin
                            if(inst_i[10:3] == 8'b00000000) begin
                                aluop_o <= `ALU_MTC0_OP;
                                alusel_o <= `ALU_SEL_NOP;
                                wreg_o <= `WriteDisable;
                                instvalid <= `InstValid;
                                reg1_read_o <= `ReadEnable;
                                reg1_addr_o <= rt;
                                reg2_read_o <= `ReadDisable;
                            end
                        end
                        default: ;
                    endcase
                end
                default: ;
            endcase //case op_code
	end
end
                    
                    
always @ (*) begin
	stallreq_for_reg1_loadrelate <= `NoStop;
	if (rst == `RstEnable) begin
		reg1_o <= `ZeroWord;
	end
	else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1 ) begin
		stallreq_for_reg1_loadrelate <= `Stop;
	end
	else if (reg1_read_o == 1'b1 && ex_wreg_i == 1'b1 && ex_wd_i == reg1_addr_o) begin
		reg1_o <= ex_wdata_i;
	end
	else if (reg1_read_o == 1'b1 && mem_wreg_i == 1'b1 && mem_wd_i == reg1_addr_o) begin
		reg1_o <= mem_wdata_i;
	end
	else if (reg1_read_o == 1'b1) begin
		reg1_o <= reg1_data_i;
	end
	else if (reg1_read_o == 1'b0) begin
		reg1_o <= imm;
	end
	else begin
		reg1_o <= `ZeroWord;
	end
end

always @ (*) begin
	stallreq_for_reg2_loadrelate <= `NoStop;
	if (rst == `RstEnable)
		reg2_o <= `ZeroWord;
	else if (pre_inst_is_load == `True && ex_wd_i == reg2_addr_o && reg2_read_o == `ReadEnable)
		stallreq_for_reg2_loadrelate <= `Stop;
	else if (reg2_read_o == 1'b1 && ex_wreg_i == 1'b1 && ex_wd_i == reg2_addr_o)
		reg2_o <= ex_wdata_i;
	else if (reg2_read_o == 1'b1 && mem_wreg_i == 1'b1 && mem_wd_i == reg2_addr_o)
		reg2_o <= mem_wdata_i;
	else if (reg2_read_o == 1'b1)
		reg2_o <= reg2_data_i;
	else if (reg2_read_o == 1'b0)
		reg2_o <= imm;
	else
		reg2_o <= `ZeroWord;
end

always @ (*) begin
	if (rst == `RstEnable)
		is_in_delayslot_o <= `NotInDelaySlot;
	else
		is_in_delayslot_o <= is_in_delayslot_i;
end

endmodule

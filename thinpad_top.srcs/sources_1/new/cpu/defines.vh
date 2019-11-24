`define DEBUG
//`define USE_CPLD_UART
// disable CPLD UART to avoid bus sharing
`define CLK_FREQ 50000000
`define UART_BAUD 115200
// configuration for directly connected UART

`define True 1'b1
`define False 1'b0
`define RstEnable 1'b1
`define RstDisable 1'b0
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Stop 1'b1
`define NoStop 1'b0
`define InDelaySlot 1'b1
`define NotInDelaySlot 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 1'b1
`define TrapNotAssert 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0

`define EntryAddr 32'h80000000

`define ZeroWord 32'h00000000
`define ZeroAddr `ZeroWord

`define AluOpBus 7:0
`define AluSelBus 2:0

`define EXE_AND  6'b100100
`define EXE_OR   6'b100101
`define EXE_XOR 6'b100110
`define EXE_NOR 6'b100111
`define EXE_ANDI 6'b001100
`define EXE_ORI  6'b001101
`define EXE_XORI 6'b001110
`define EXE_LUI 6'b001111

`define EXE_SLL  6'b000000
`define EXE_SLLV  6'b000100
`define EXE_SRL  6'b000010
`define EXE_SRLV  6'b000110
`define EXE_SRA  6'b000011
`define EXE_SRAV  6'b000111
`define EXE_SYNC  6'b001111
`define EXE_PREF  6'b110011

`define EXE_MOVZ  6'b001010
`define EXE_MOVN  6'b001011
`define EXE_MFHI  6'b010000
`define EXE_MTHI  6'b010001
`define EXE_MFLO  6'b010010
`define EXE_MTLO  6'b010011

`define EXE_SLT  6'b101010
`define EXE_SLTU  6'b101011
`define EXE_SLTI  6'b001010
`define EXE_SLTIU  6'b001011   
`define EXE_ADD  6'b100000
`define EXE_ADDU  6'b100001
`define EXE_SUB  6'b100010
`define EXE_SUBU  6'b100011
`define EXE_ADDI  6'b001000
`define EXE_ADDIU  6'b001001
`define EXE_CLZ  6'b100000
`define EXE_CLO  6'b100001

`define EXE_MULT  6'b011000
`define EXE_MULTU  6'b011001
`define EXE_MUL  6'b000010
`define EXE_MADD  6'b000000
`define EXE_MADDU  6'b000001
`define EXE_MSUB  6'b000100
`define EXE_MSUBU  6'b000101

`define EXE_DIV  6'b011010
`define EXE_DIVU  6'b011011

`define EXE_J  6'b000010
`define EXE_JAL  6'b000011
`define EXE_JALR  6'b001001
`define EXE_JR  6'b001000
`define EXE_BEQ  6'b000100
`define EXE_BGEZ  5'b00001
`define EXE_BGEZAL  5'b10001
`define EXE_BGTZ  6'b000111
`define EXE_BLEZ  6'b000110
`define EXE_BLTZ  5'b00000
`define EXE_BLTZAL  5'b10000
`define EXE_BNE  6'b000101

`define EXE_LB  6'b100000
`define EXE_LBU  6'b100100
`define EXE_LH  6'b100001
`define EXE_LHU  6'b100101
`define EXE_LL  6'b110000
`define EXE_LW  6'b100011
`define EXE_LWL  6'b100010
`define EXE_LWR  6'b100110
`define EXE_SB  6'b101000
`define EXE_SC  6'b111000
`define EXE_SH  6'b101001
`define EXE_SW  6'b101011
`define EXE_SWL  6'b101010
`define EXE_SWR  6'b101110


`define EXE_NOP 6'b000000
`define SSNOP 32'b00000000000000000000000001000000

`define EXE_SPECIAL_INST 6'b000000
`define EXE_REGIMM_INST 6'b000001
`define EXE_SPECIAL2_INST 6'b011100
`define EXE_COP0_INST 6'b010000

// cp0 ops
`define EXE_CP0_MT 5'b00100
`define EXE_CP0_MF 5'b00000

// exception
`define EXE_SYSCALL 6'b001100
   
`define EXE_TEQ 6'b110100
`define EXE_TEQI 5'b01100
`define EXE_TGE 6'b110000
`define EXE_TGEI 5'b01000
`define EXE_TGEIU 5'b01001
`define EXE_TGEU 6'b110001
`define EXE_TLT 6'b110010
`define EXE_TLTI 5'b01010
`define EXE_TLTIU 5'b01011
`define EXE_TLTU 6'b110011
`define EXE_TNE 6'b110110
`define EXE_TNEI 5'b01110
   
`define EXE_ERET 32'b01000010000000000000000000011000

// ALU ops
`define ALU_AND_OP   8'b00100100
`define ALU_OR_OP    8'b00100101
`define ALU_XOR_OP  8'b00100110
`define ALU_NOR_OP  8'b00100111
`define ALU_ANDI_OP  8'b01011001
`define ALU_ORI_OP  8'b01011010
`define ALU_XORI_OP  8'b01011011
`define ALU_LUI_OP  8'b01011100   

`define ALU_SLL_OP  8'b01111100
`define ALU_SLLV_OP  8'b00000100
`define ALU_SRL_OP  8'b00000010
`define ALU_SRLV_OP  8'b00000110
`define ALU_SRA_OP  8'b00000011
`define ALU_SRAV_OP  8'b00000111

`define ALU_MOVZ_OP  8'b00001010
`define ALU_MOVN_OP  8'b00001011
`define ALU_MFHI_OP  8'b00010000
`define ALU_MTHI_OP  8'b00010001
`define ALU_MFLO_OP  8'b00010010
`define ALU_MTLO_OP  8'b00010011

`define ALU_SLT_OP  8'b00101010
`define ALU_SLTU_OP  8'b00101011
`define ALU_SLTI_OP  8'b01010111
`define ALU_SLTIU_OP  8'b01011000   
`define ALU_ADD_OP  8'b00100000
`define ALU_ADDU_OP  8'b00100001
`define ALU_SUB_OP  8'b00100010
`define ALU_SUBU_OP  8'b00100011
`define ALU_ADDI_OP  8'b01010101
`define ALU_ADDIU_OP  8'b01010110
`define ALU_CLZ_OP  8'b10110000
`define ALU_CLO_OP  8'b10110001

`define ALU_MULT_OP  8'b00011000
`define ALU_MULTU_OP  8'b00011001
`define ALU_MUL_OP  8'b10101001
`define ALU_MADD_OP  8'b10100110
`define ALU_MADDU_OP  8'b10101000
`define ALU_MSUB_OP  8'b10101010
`define ALU_MSUBU_OP  8'b10101011

`define ALU_DIV_OP  8'b00011010
`define ALU_DIVU_OP  8'b00011011

`define ALU_J_OP  8'b01001111
`define ALU_JAL_OP  8'b01010000
`define ALU_JALR_OP  8'b00001001
`define ALU_JR_OP  8'b00001000
`define ALU_BEQ_OP  8'b01010001
`define ALU_BGEZ_OP  8'b01000001
`define ALU_BGEZAL_OP  8'b01001011
`define ALU_BGTZ_OP  8'b01010100
`define ALU_BLEZ_OP  8'b01010011
`define ALU_BLTZ_OP  8'b01000000
`define ALU_BLTZAL_OP  8'b01001010
`define ALU_BNE_OP  8'b01010010

`define ALU_LB_OP  8'b11100000
`define ALU_LBU_OP  8'b11100100
`define ALU_LH_OP  8'b11100001
`define ALU_LHU_OP  8'b11100101
`define ALU_LL_OP  8'b11110000
`define ALU_LW_OP  8'b11100011
`define ALU_LWL_OP  8'b11100010
`define ALU_LWR_OP  8'b11100110
`define ALU_PREF_OP  8'b11110011
`define ALU_SB_OP  8'b11101000
`define ALU_SC_OP  8'b11111000
`define ALU_SH_OP  8'b11101001
`define ALU_SW_OP  8'b11101011
`define ALU_SWL_OP  8'b11101010
`define ALU_SWR_OP  8'b11101110
`define ALU_SYNC_OP  8'b00001111

`define ALU_MFC0_OP 8'b01011101
`define ALU_MTC0_OP 8'b01100000

`define ALU_SYSCALL_OP 8'b00001100

`define ALU_TEQ_OP 8'b00110100
`define ALU_TEQI_OP 8'b01001000
`define ALU_TGE_OP 8'b00110000
`define ALU_TGEI_OP 8'b01000100
`define ALU_TGEIU_OP 8'b01000101
`define ALU_TGEU_OP 8'b00110001
`define ALU_TLT_OP 8'b00110010
`define ALU_TLTI_OP 8'b01000110
`define ALU_TLTIU_OP 8'b01000111
`define ALU_TLTU_OP 8'b00110011
`define ALU_TNE_OP 8'b00110110
`define ALU_TNEI_OP 8'b01001001
   
`define ALU_ERET_OP 8'b01101011

`define ALU_NOP_OP    8'b00000000

//AluSel
`define ALU_SEL_NOP 3'b000
`define ALU_SEL_LOGIC 3'b001
`define ALU_SEL_SHIFT 3'b010
`define ALU_SEL_MOVE 3'b011	
`define ALU_SEL_ARITHMETIC 3'b100	
`define ALU_SEL_MUL 3'b101
`define ALU_SEL_JUMP_BRANCH 3'b110
`define ALU_SEL_LOAD_STORE 3'b111


//ָ ROM for test
`define InstAddrBus 31:0
`define InstBus 31:0
`define InstMemNum 131071
`define InstMemNumLog2 17

// Data RAM
`define DataAddrBus 31:0
`define DataBus 31:0
`define DataMemNum 1048576
`define DataMemNumLog2 20
`define ByteWidth 7:0

// Registers
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32
`define DoubleRegWidth 64
`define DoubleRegBus 63:0
`define RegNum 32
`define NOPRegAddr 5'b00000

// Div
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0

// CoProcessor 0 entries
`define CP0_REG_INDEX 5'b00000
`define CP0_REG_RANDOM 5'b00001
`define CP0_REG_ENTRYLO0 5'b00010
`define CP0_REG_ENTRYLO1 5'b00011
`define CP0_REG_CONTEXT 5'b00100
`define CP0_REG_PAGEMASK 5'b00101
`define CP0_REG_WIRED 5'b00110
`define CP0_REG_BADVADDR 5'b01000
`define CP0_REG_COUNT    5'b01001
`define CP0_REG_ENTRYHI  5'b01010
`define CP0_REG_COMPARE    5'b01011
`define CP0_REG_STATUS    5'b01100
`define CP0_REG_CAUSE    5'b01101
`define CP0_REG_EPC    5'b01110
`define CP0_REG_EBASE    5'b01111  // when TLB enables, PrId becomes EBase
`define CP0_REG_CONFIG    5'b10000

// FSM of wishbone
`define WB_IDLE 2'b00
`define WB_BUSY 2'b01
`define WB_WAIT_FOR_FLUSHING 2'b10
`define WB_WAIT_FOR_STALL 2'b11
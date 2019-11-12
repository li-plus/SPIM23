/* Common definitions */
`define True            1'b1
`define False           1'b0
`define RstEnable       1'b1
`define RstDisable      1'b0
`define WriteEnable     1'b1
`define WriteDisable    1'b0
`define ReadEnable      1'b1
`define ReadDisable     1'b0
`define ChipEnable      1'b1
`define ChipDisable     1'b0

`define ZeroWord        32'h00000000

`define InstValid       1'b0
`define InstInvalid     1'b1
/* Operation codes */
`define OP_NOP          6'b000000
`define OP_ANDI         6'b001100
`define OP_ORI          6'b001101
`define OP_XORI         6'b001110
`define OP_LUI          6'b001111
`define OP_PREF    6'b110011

`define OP_FUNC_SLL     6'b000000
`define OP_FUNC_SRL     6'b000010
`define OP_FUNC_SRA     6'b000011
`define OP_FUNC_SLLV    6'b000100
`define OP_FUNC_SRLV    6'b000110
`define OP_FUNC_SRAV    6'b000111
`define OP_FUNC_SYNC    6'b001111
`define OP_FUNC_AND     6'b100100
`define OP_FUNC_OR      6'b100101
`define OP_FUNC_XOR     6'b100110
`define OP_FUNC_NOR     6'b100111

/* ALU Selections */
`define ALU_SEL_NOP     3'b000

`define ALU_SEL_LOGIC   3'b001
`define ALU_SEL_SHIFT   3'b010
/* ALU Operation codes */
`define ALU_NOP         8'b00000000

`define ALU_AND         8'b00100100
`define ALU_OR          8'b00100101
`define ALU_XOR         8'b00100110
`define ALU_NOR         8'b00100111

`define ALU_ANDI        8'b01011001
`define ALU_ORI         8'b01011010
`define ALU_XORI        8'b01011011
`define ALU_LUI         8'b01011100

`define ALU_SLL         8'b01111100
`define ALU_SLLV        8'b00000100
`define ALU_SRL         8'b00000010
`define ALU_SRLV        8'b00000110
`define ALU_SRA         8'b00000011
`define ALU_SRAV        8'b00000111


`define InstAddrBus     31:0
`define InstBus         31:0

`define AluOpBus        7:0
`define AluSelBus       2:0

`define RegAddrBus      4:0
`define RegBus          31:0
`define RegWidth        32
`define DoubleRegBus    63:0
`define DoubleRegWidth  64
`define ZeroRegAddr      5'b00000

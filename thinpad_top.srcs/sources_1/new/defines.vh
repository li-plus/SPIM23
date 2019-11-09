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
`define OP_ORI          6'b001101

/* ALU Selections */
`define ALU_SEL_LOGIC   3'b001
`define ALU_SEL_NOP     3'b000
/* ALU Operation codes */
`define ALU_OR          8'b00100101
`define ALU_NOP         8'b00000000


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

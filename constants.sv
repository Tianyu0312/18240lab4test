/*
 * File: constants.v
 * Created: 4/5/1998
 * Modules contained: none
 * 
 * Changelog:
 * 4/16/2001: Removed additions from last semester for this term (verBurg)
 * 4/16/2001: Added the "addsp" instruction. (verBurg)
 * 3 October 2009: Fixed spacing (mcbender)
 * 13 October 2009: Removed tabs (mcbender)
 * 18 October 2009: Changed some names to caps (mcbender)
 * 23 October 2009: Changed all parameters to    and renamed params.v to defs.v
 * 31 October 2009: Renamed to constants.v
 * 13 Oct 2010: Updated always to always_comb and always_ff.Renamed to.sv(abeera) 
 * 17 Oct 2010: Updated to use enums instead of   's (iclanton)
 * 24 Oct 2010: Added controlPts struct (abeera)
 * 9  Nov 2010: Slightly modified variable names (abeera)
 * 15 Apr 2014: This is now the only file that needs the `define synthesis (mrrosen)
 */

// Comment this line when simulating, uncomment when synthesizing.
//`define synthesis

// Uncomment this line for a vga debug dispay (Not guaranteed to be bug free)
//`define vga_display

`ifndef sv_CONSTANTS
`define sv_CONSTANTS

typedef enum logic[3:0]{ // ALU operation select
   F_A           = 4'b0000,
   F_A_PLUS_1    = 4'b0001,
   F_A_PLUS_B    = 4'b0010,
   F_A_PLUS_B_1  = 4'b0011,
   F_A_MINUS_B_1 = 4'b0100,
   F_A_MINUS_B   = 4'b0101,
   F_A_MINUS_1   = 4'b0110,
   F_B           = 4'b0111,
   F_A_NOT       = 4'b1000,
   F_A_AND_B     = 4'b1001,
   F_A_OR_B      = 4'b1010,
   F_A_XOR_B     = 4'b1011,
   F_A_SHL       = 4'b1100,
   F_A_ROL       = 4'b1101,
   F_A_LSHR      = 4'b1110,
   F_A_ASHR      = 4'b1111,
   F_UNDEF       = 4'bxxxx
   } alu_op_t; // ALU operation select

typedef enum logic [1:0]{ // ALU input mux select
   MUX_REG       = 2'b00,
   MUX_SP        = 2'b01,
   MUX_PC        = 2'b10,
   MUX_MDR       = 2'b11,
   MUX_UNDEF     = 2'bxx
} alu_mux_t; // ALU input mux select

typedef enum logic [2:0]{ // destination select
   DEST_REG      = 3'b000,
   DEST_SP       = 3'b001,
   DEST_PC       = 3'b010,
   DEST_MDR      = 3'b011,
   DEST_MAR      = 3'b100,
   DEST_IR       = 3'b101,
   DEST_NONE     = 3'b111,
   DEST_UNDEF    = 3'bxxx
} dest_sel_t; // destination select

typedef enum logic{ // Read memory operation
   MEM_RD        = 1'b0,
   NO_RD         = 1'b1
} rd_cond_code_t; // Read memory operation

typedef enum logic{ // Write memory operation
   MEM_WR        = 1'b0,
   NO_WR         = 1'b1
} wr_cond_code_t; // Write memory operation

typedef enum logic{ // Condition code
   LOAD_CC       = 1'b0,
   NO_LOAD       = 1'b1
} cond_code_t; // Condition code

typedef enum logic [9:0] {
//new operation ADD32:
   ADD32 = 10'b00_1100_0100,
   CHECKCC = 10'b00_1100_0101,
   ADD32_C = 10'b00_1100_0110,
   ADD32_N = 10'b00_1100_0111,

// Microcode operations (i.e., FSM states)
   FETCH  = 10'b00_0000_0000,
   FETCH1 = 10'b00_0000_0001,
   FETCH2 = 10'b00_0000_0010,
   DECODE = 10'b00_0000_0100,
   STOP   = 10'b00_1100_0000,
   STOP1  = 10'b00_1100_0001,

// Load operations: MOV, LDA, LDR, LDI
   MOV    = 10'b00_1110_1000,
   LDA    = 10'b00_0001_0000,
   LDA1   = 10'b00_0001_0001,
   LDA2   = 10'b00_0001_0010,
   LDA3   = 10'b00_0001_0011,
   LDA4   = 10'b00_0001_0100,
   LDR    = 10'b00_0010_0000,
   LDR1   = 10'b00_0010_0001,
   LDR2   = 10'b00_0010_0010,
   LDI    = 10'b00_0011_0000,
   LDI1   = 10'b00_0011_0001,
   LDI2   = 10'b00_0011_0010,

// Store operations: STA, STR
   STA    = 10'b00_0001_1000,
   STA1   = 10'b00_0001_1001,
   STA2   = 10'b00_0001_1010,
   STA3   = 10'b00_0001_1011,
   STA4   = 10'b00_0001_1100,
   STR    = 10'b00_0010_1000,
   STR1   = 10'b00_0010_1001,
   STR2   = 10'b00_0010_1010,

// Branch operations: BRA, BRN, BRZ, BRC, BRV
   BRA    = 10'b00_1010_0000,
   BRA1   = 10'b00_1010_0001,
   BRA2   = 10'b00_1010_0010,
   BRN    = 10'b00_1011_0000,
   BRN1   = 10'b00_1011_0001,
   BRN2   = 10'b00_1011_0010,
   BRN3   = 10'b00_1011_0011,
   BRZ    = 10'b00_1010_1000,
   BRZ1   = 10'b00_1010_1001,
   BRZ2   = 10'b00_1010_1010,
   BRZ3   = 10'b00_1010_1011,
   BRC    = 10'b01_0010_0000,
   BRC1   = 10'b01_0010_0001,
   BRC2   = 10'b01_0010_0010,
   BRC3   = 10'b01_0010_0011,
   BRV    = 10'b00_1011_1000,
   BRV1   = 10'b00_1011_1001,
   BRV2   = 10'b00_1011_1010,
   BRV3   = 10'b00_1011_1011,

// Arithmetic operations: ADD, SUB, INCR, DECR, NEG
   ADD    = 10'b00_0011_1000,
   SUB    = 10'b00_0100_0000,
   INCR   = 10'b00_0101_0000,
   DECR   = 10'b00_0101_1000,
   NEG    = 10'b00_0100_1000,
   NEG1   = 10'b00_0100_1001,
 
// Logical operations: AND, NOT, OR, XOR
   AND    = 10'b00_0110_1000,
   NOT    = 10'b00_0110_0000,
   OR     = 10'b00_0111_0000,
   XOR    = 10'b00_0111_1000,

// Comparison operations: CMI, CMR
   CMI    = 10'b01_0001_0000,
   CMI1   = 10'b01_0001_0001,
   CMI2   = 10'b01_0001_0010,
   CMR    = 10'b01_0001_1000,

// Shift operations: ASHR, LSHL, LSHR, ROL
   ASHR   = 10'b00_1001_1000,
   LSHL   = 10'b00_1000_0000,
   LSHR   = 10'b00_1001_0000,
   ROL    = 10'b00_1000_1000,

// Stack operations: JSR, LDSF, LDSP, POP, PUSH, RTN, STSF, STSP, ADDSP
   JSR    = 10'b00_1101_1000,
   JSR1   = 10'b00_1101_1001,
   JSR2   = 10'b00_1101_1010,
   JSR3   = 10'b00_1101_1011,
   JSR4   = 10'b00_1101_1100,
   JSR5   = 10'b00_1101_1101,
   LDSF   = 10'b01_0000_0000,
   LDSF1  = 10'b01_0000_0001,
   LDSF2  = 10'b01_0000_0010,
   LDSF3  = 10'b01_0000_0011,
   LDSF4  = 10'b01_0000_0100,
   LDSP   = 10'b00_1111_0000,
   POP    = 10'b00_1101_0000,
   POP1   = 10'b00_1101_0001,
   POP2   = 10'b00_1101_0010,
   PUSH   = 10'b00_1100_1000,
   PUSH1  = 10'b00_1100_1001,
   PUSH2  = 10'b00_1100_1010,
   RTN    = 10'b00_1110_0000,
   RTN1   = 10'b00_1110_0001,
   RTN2   = 10'b00_1110_0010,
   STSF   = 10'b01_0000_1000,
   STSF1  = 10'b01_0000_1001,
   STSF2  = 10'b01_0000_1010,
   STSF3  = 10'b01_0000_1011,
   STSF4  = 10'b01_0000_1100,
   STSP   = 10'b00_1111_1000,
   ADDSP  = 10'b00_0011_1100,
   ADDSP1 = 10'b00_0011_1101,
   ADDSP2 = 10'b00_0011_1110,

   UNDEF  = 10'bxx_xxxx_xxxx


} opcode_t;

typedef struct packed 
{
   alu_op_t alu_op;
   alu_mux_t srcA;
   alu_mux_t srcB;
   dest_sel_t dest;
   cond_code_t lcc_L;
   rd_cond_code_t re_L;
   wr_cond_code_t we_L;
} controlPts;

`endif


/*
 * File: controlpath.v
 * Created: 4/5/1998
 * Modules contained: controlpath
 *
 * The condition codes are ordered as ZCNV
 * 
 * Changelog:
 * 9 June 1999 : Added stack pointer 
 * 4/16/2001: Reverted to base code (verBurg)
 * 4/16/2001: Added the "addsp" instruction. (verBurg)
 * 11/26/06: Removed old Altera-specific code that Xilinx tool had trouble with (P. Milder)
 * 07 Oct 2009: Cleaned up coding style somewhat and made minor changes (mcbender)
 * 08 Oct 2009: Fixed minor errors (mcbender)
 * 12 Oct 2009: Minor naming changes for consistency with modules.v (mcbender)
 * 13 Oct 2009: Removed tabs and fixed spacing (mcbender)
 * 18 Oct 2009: Changed some constant names (mcbender)
 * 23 Oct 2009: Renamed from paths.v to controlpath.v, moved datapath to datapath.v
 * 13 Oct 2010: Updated always to always_comb and always_ff. Removed #1 before finish,
 *              as timing controls not allowed in always_comb. Renamed to .sv. (abeera)    
 * 17 Oct 2010: Updated to use enums instead of define's (iclanton)
 * 24 Oct 2010: Updated to use struct (abeera)
 * 9  Nov 2010: Slightly modified variable names (abeera)
 * 13 Nov 2010: Modified to use static instead of dynamic casting (abeera)
 * 23 Apr 2012: Modified to have two stop states, the first decrements PC, per ISA (leifan)
 */

`include "constants.sv"

/*
 * module controlpath
 *
 * This is the FSM for the p18240.  Any modifications to the ISA 
 * or even the base implementation will most likely affect this module.
 * (Hint, hint.)
 */
module controlpath (
   input [3:0]       CCin,
   input [15:0]      IRIn,
   output controlPts out,
   output opcode_t currState,
   output opcode_t nextState,
   output logic ADD32sel,
   input             clock,
   input             reset_L);
  
   always_ff @(posedge clock or negedge reset_L)
     if (~reset_L)
       currState <= FETCH;
     else
       currState <= nextState;

   // order of control points: 
   // {ALU fn, AmuxSel, BmuxSel, DestDecode, CCLoad, RE, WE}

   always_comb begin
      ADD32sel = 1'b0;
      case (currState)
        //4 new states for ADD32:
        //1. Add lower 16 bits (two registers REG+1);
        ADD32: begin
           out = {F_A_PLUS_B, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           ADD32sel = 1'b1;
           nextState = CHECKCC;
        end
        
         //2. Check the C flag. If C, go to carry state, otherwise go to no carry state.
        CHECKCC: begin
           out = {4'bxxxx,2'bxx,2'bxx,DEST_NONE,NO_LOAD, NO_RD, NO_WR};
           if (CCin[2] == 1'b1) 
             nextState = ADD32_C;
           else 
             nextState = ADD32_N;
        end
        
        //3. Carry state. Add upper 16 bits. (two registers REG);
        ADD32_C: begin
           out = {F_A_PLUS_B_1, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR}; //A+B+1?!
           nextState = FETCH;
        end
        
        //4. No carry state. Add upper 16 bits. (two registers REG);
        ADD32_N: begin
           out = {F_A_PLUS_B, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR}; //A+B+1?!
           nextState = FETCH;
        end

        FETCH: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH1;
         end
        FETCH1: begin
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = FETCH2;
         end
        FETCH2: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_IR, NO_LOAD, NO_RD, NO_WR};
           nextState = DECODE;
        end
        DECODE: begin
           out = {4'bxxxx, 2'bxx, 2'bxx, DEST_NONE, NO_LOAD, NO_RD, NO_WR};
           nextState = opcode_t'(IRIn[15:6]);
         //  $cast(nextState, IRIn[15:6]);
        end
        LDI: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = LDI1;
        end
        LDI1: begin
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = LDI2;
        end
        LDI2: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        ADD: begin
           out = {F_A_PLUS_B, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        SUB: begin
           out = {F_A_MINUS_B, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        INCR: begin
           out = {F_A_PLUS_1, MUX_REG, 2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        DECR: begin
           out = {F_A_MINUS_1, MUX_REG, 2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        LDR: begin
         out = {F_B, 2'bxx, MUX_REG, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = LDR1;
        end
        LDR1: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = LDR2;
        end
        LDR2: begin
           out = {F_A, MUX_MDR,2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRA: begin
           out = {F_A, MUX_PC,2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = BRA1;
        end
        BRA1: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = BRA2;
        end
        BRA2: begin
           out = {F_A, MUX_MDR,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRN: begin
           out = {F_A, MUX_PC,2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           if (CCin[1]) 
             nextState = BRN2;
           else 
             nextState = BRN1;
        end
        BRN1: begin
           out = {F_A_PLUS_1, MUX_PC,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRN2: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = BRN3;
        end
        BRN3: begin
           out = {F_A, MUX_MDR,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRZ: begin
           out = {F_A, MUX_PC,2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           if (CCin[3]) 
             nextState = BRZ2;
           else 
             nextState = BRZ1;
        end
        BRZ1: begin
           out = {F_A_PLUS_1, MUX_PC,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRZ2: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = BRZ3;
        end
        BRZ3: begin
           out = {F_A, MUX_MDR,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end       
        STOP: begin
           out = {F_A_MINUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = STOP1;
        end
        STOP1: begin
           out = {8'bxx, DEST_NONE, NO_LOAD, NO_RD, NO_WR}; // same as above
           nextState = STOP1; // This is to avoid a latch
`ifndef synthesis
           $display("STOP occurred at time %d", $time);
            $finish;
`endif
        end
        BRC: begin
           out = {F_A, MUX_PC,2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           if (CCin[2]) 
             nextState = BRC2;
           else 
             nextState = BRC1;
        end
        BRC1: begin
           out = {F_A_PLUS_1, MUX_PC,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRC2: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = BRC3;
        end
        BRC3: begin
           out = {F_A, MUX_MDR,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRV: begin
           out = {F_A, MUX_PC,2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           if (CCin[0]) 
             nextState = BRV2;
           else 
             nextState = BRV1;
        end
        BRV1: begin
           out = {F_A_PLUS_1, MUX_PC,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        BRV2: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = BRV3;
        end
        BRV3: begin
           out = {F_A, MUX_MDR,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end 
        // logical functions:
        AND: begin
           out = {F_A_AND_B, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        NOT: begin
           out = {F_A_NOT, MUX_REG,2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        OR: begin
           out = {F_A_OR_B, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        XOR: begin
           out = {F_A_XOR_B, MUX_REG, MUX_REG, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        // illogical func--er, Comparison functions:
        CMI: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = CMI1;
        end
        CMI1: begin
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = CMI2;
        end
        CMI2: begin
           out = {F_A_MINUS_B, MUX_REG, MUX_MDR, DEST_NONE, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        CMR: begin
           out = {F_A_MINUS_B, MUX_REG, MUX_REG, DEST_NONE, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        // Shift functions:
        ASHR: begin
           out = {F_A_ASHR, MUX_REG,2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        LSHL: begin
           out = {F_A_SHL, MUX_REG,2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        LSHR: begin
           out = {F_A_LSHR, MUX_REG,2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        ROL: begin
           out = {F_A_ROL, MUX_REG,2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        // Data movement functions:
        MOV: begin
           out = {F_B, 2'bxx, MUX_REG, DEST_REG, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        LDA: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = LDA1;
        end
        LDA1: begin
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = LDA2;
        end
        LDA2: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = LDA3;
        end
        LDA3: begin
           out = {4'bxxxx, 2'bxx, 2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = LDA4;
        end
        LDA4: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_REG, LOAD_CC, NO_RD, NO_WR};
           nextState = FETCH;
        end
        STA: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = STA1;
        end
        STA1: begin
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = STA2;
        end
        STA2: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = STA3;
        end
        STA3: begin
           out = {F_B, 2'bxx, MUX_REG, DEST_MDR, NO_LOAD, NO_RD, NO_WR};
           nextState = STA4;
        end
        STA4: begin
           out = {4'bxxxx, 2'bxx, 2'bxx, DEST_NONE, NO_LOAD, NO_RD, MEM_WR};
           nextState = FETCH;
        end
        STR: begin
           out = {F_A, MUX_REG,2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = STR1;
        end
        STR1: begin
           out = {F_B, 2'bxx, MUX_REG, DEST_MDR, NO_LOAD, NO_RD, NO_WR};
           nextState = STR2;
        end
        STR2: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, NO_RD, MEM_WR};
           nextState = FETCH;
        end
        // Stack based ops:
        JSR: begin
           out = {F_A_MINUS_1, MUX_SP,2'bxx, DEST_SP, NO_LOAD, NO_RD, NO_WR};
           nextState = JSR1;
        end
        JSR1: begin
           out = {F_A, MUX_SP,2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = JSR2;
        end
        JSR2: begin
           out = {F_A_PLUS_1, MUX_PC,2'bxx, DEST_MDR, NO_LOAD, NO_RD, NO_WR};
           nextState = JSR3;
        end
        JSR3: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, MEM_WR};
           nextState = JSR4;
        end
        JSR4: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = JSR5;
        end
        JSR5: begin
           out = {F_A, MUX_MDR,2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        LDSF: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = LDSF1;
        end
        LDSF1: begin
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = LDSF2;
        end
        LDSF2: begin
           out = {F_A_PLUS_B, MUX_MDR, MUX_SP, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = LDSF3;
        end
        LDSF3: begin
           out = {4'bxxxx, 2'bxx,2'bxx, DEST_NONE, NO_LOAD, MEM_RD, NO_WR};
           nextState = LDSF4;
        end
        LDSF4: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_REG, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        LDSP: begin
           out = {F_A, MUX_REG, 2'bxx, DEST_SP, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        POP: begin
           out = {F_A, MUX_SP, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = POP1;
        end
        POP1: begin
           out = {F_A_PLUS_1, MUX_SP, 2'bxx, DEST_SP, NO_LOAD, MEM_RD, NO_WR};
           nextState = POP2;
        end
        POP2: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_REG, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        PUSH: begin
           out = {F_A_MINUS_1, MUX_SP, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = PUSH1;
        end
        PUSH1: begin
           out = {F_A, MUX_REG, 2'bxx, DEST_MDR, NO_LOAD, NO_RD, NO_WR};
           nextState = PUSH2;
        end
        PUSH2: begin
           out = {F_A_MINUS_1, MUX_SP, 2'bxx, DEST_SP, NO_LOAD, NO_RD, MEM_WR};
           nextState = FETCH;
        end
        RTN: begin
           out = {F_A, MUX_SP, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = RTN1;
        end
        RTN1: begin
           out = {F_A_PLUS_1, MUX_SP, 2'bxx, DEST_SP, NO_LOAD, MEM_RD, NO_WR};
           nextState = RTN2;
        end
        RTN2: begin
           out = {F_A, MUX_MDR, 2'bxx, DEST_PC, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        STSF: begin
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = STSF1;
        end
        STSF1: begin
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = STSF2;
        end
        STSF2: begin
           out = {F_A_PLUS_B, MUX_MDR, MUX_SP, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = STSF3;
        end
        STSF3: begin
           out = {F_A, MUX_REG, 2'bxx, DEST_MDR, NO_LOAD, NO_RD, NO_WR};
           nextState = STSF4;
        end
        STSF4: begin
           out = {4'bxxxx, 2'bxx, 2'bxx, DEST_NONE, NO_LOAD, NO_RD, MEM_WR};
           nextState = FETCH;
        end
        ADDSP: begin
           // get IMM value by putting PC on MAR:
           out = {F_A, MUX_PC, 2'bxx, DEST_MAR, NO_LOAD, NO_RD, NO_WR};
           nextState = ADDSP1;
        end
        ADDSP1: begin
           // add one to PC and store back, read memory from PC:
           out = {F_A_PLUS_1, MUX_PC, 2'bxx, DEST_PC, NO_LOAD, MEM_RD, NO_WR};
           nextState = ADDSP2;
        end
        ADDSP2: begin
           // add MDR with SP and store into SP:
           out = {F_A_PLUS_B, MUX_MDR, MUX_SP, DEST_SP, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        STSP: begin
           out = {F_A, MUX_SP, 2'bxx, DEST_REG, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        NEG: begin
           out = {F_A_NOT, MUX_REG, 2'bxx, DEST_REG, NO_LOAD, NO_RD, NO_WR};
           nextState = NEG1;
        end
        NEG1: begin
           out = {F_A_PLUS_1, MUX_REG, 2'bxx, DEST_REG, NO_LOAD, NO_RD, NO_WR};
           nextState = FETCH;
        end
        default: begin
           out = 14'bx;
           nextState = FETCH;
        end
     endcase
   end

endmodule

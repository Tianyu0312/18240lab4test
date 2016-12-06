/*
 * File: memory.sv
 * Created: 14 Nov 2014
 * Modules contained: memory
 */
 
 /*
 * module: memory
 *
 *  This is a full sized memory for the p18240 and initialized with
 *  a memory.hex file.
 *
 */
module memory_simulation
  (input  logic          clock, enable,
   input  wr_cond_code_t we_L,
   input  rd_cond_code_t re_L,
   inout  [15:0]   data,
   input  logic  [15:0]   address);
   
  logic [15:0] mem [16'hffff:16'h0000];
  
  assign data = (enable & (re_L == MEM_RD)) ? mem[address] : 16'bz;
    
  always @(posedge clock)
    if (enable & (we_L == MEM_WR))
      mem[address] <= data;
      
  initial $readmemh("memory.hex", mem);

endmodule : memory_simulation

 
 /* 
 * module: memory_16bit 
 *
 * This is our data memory, with combinational read and synchronous write.
 * Each memory word is 16 bits, and there is a 16 bit address space.
 * Note: This is a simulation model only. Memories are not synthesizable.
 */
 
 `include "constants.sv"
 
module memorySystem (
   inout  [15:0]   data,
   input logic [15:0]   address,
   input wr_cond_code_t we_L,
   input rd_cond_code_t re_L,
   input logic          clock); 

`ifdef synthesis
   logic pmem_en, dmem_en, smem_en;
   
   // Memory Map: Program memory from $0000 to $00FF
   memory256x16_program pmem(.clock(clock), 
                             .enable(pmem_en), 
                             .we_L(we_L), 
                             .re_L(re_L), 
                             .data(data), 
                             .address(address[7:0]));
   //             Data memory from $0100 to $01FF
   memory256x16         dmem(.clock(clock), 
                             .enable(dmem_en), 
                             .we_L(we_L), 
                             .re_L(re_L), 
                             .data(data), 
                             .address(address[7:0]));
   //             Stack memory from $FF00 to $FFFF
   memory256x16         smem(.clock(clock), 
                             .enable(smem_en), 
                             .we_L(we_L), 
                             .re_L(re_L), 
                             .data(data), 
                             .address(address[7:0]));
   
   // Address decoders to enable individual memory modules
   assign pmem_en = (address[15:8] == 8'h00);
   assign dmem_en = (address[15:8] == 8'h01);
   assign smem_en = (address[15:8] == 8'hFF);
   
`else
  // full sized memory for simulation, initialized with memory.hex
  memory_simulation  mem(
                        .clock(clock), 
                        .enable(1'b1), 
                        .we_L(we_L), 
                        .re_L(re_L), 
                        .data(data), 
                        .address(address));
`endif

endmodule : memorySystem

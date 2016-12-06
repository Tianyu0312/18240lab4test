`define hex_to_chars(arg, index)\
{4'h1, arg[index+15:index+12]}, {4'h1, arg[index+11:index+8]}, {4'h1, arg[index+7:index+4]}, {4'h1, arg[index+3:index]}

`ifdef synthesis
`include "cram.v"
`include "vram.v"
`endif

/*
 * File: library.v
 * Created: 11/13/1997
 * Modules contained: display_controller, vga_controller, color_LUT, fake_character_memory, character_rom, delay_cycles
 */

/*
 * module: display_controller
 *
 * Generates all of the display logic for the p18240 display
 *
 */
module display_controller(
    // Basic signals
    input logic clock, reset_L,
    // Memory signals
    inout  [15:0]   data,
    input logic [15:0]   address,
    input wr_cond_code_t we_L,
    input rd_cond_code_t re_L,
    // Display data signals
    input logic [127:0] regView,
    input logic [15:0] memAddr, memData, pc, ir, sp,
    input logic [3:0] condCodes,
    // VGA signals
    input logic CLOCK_50, disp_sel, debug_sel,
    output logic [23:0] VGA_RGB,
    output logic HS, VS, blank);

    // ===============  LOGIC DECLARATIONS  ==================
    logic generate_HS, generate_VS, generate_blank, generate_pip, display_pip,
        is_WR, vmem_m_en, cmem_m_en, decode_is_on, decode_debug_is_on;
    logic [3:0]  pixel_color;
    logic [5:0]  char_pixel_addr, color_addr;
    logic [8:0]  fake_cram_addr, decode_curr_addr;
    logic [9:0]  row, col, mod_row, mod_col, decode_row, decode_col;
    logic [15:0] v_mem_output, c_mem_output, decode_char, decode_pixel,
        cram_addr, fake_data, vram_addr;
    logic [63:0] pixelmap, debug_pixelmap;
    logic [23:0] disp_char_rgb, disp_debug_rgb, disp_pixel_rgb, pixel_rgb,
        debug_rgb, char_rgb, char_color, debug_rgb_in, debug_rgb_out;

    // =================  GENERATE STAGE  ====================

    vga_controller vga(CLOCK_50, reset_L, generate_HS, generate_VS, generate_blank, row, col);

    // PIP logic, when we are in debug and in the lower left, put the whole
    // range of row/col in the lower left. (subtract half and multiply by 2)
    assign generate_pip = (row >= 240 && col >= 320 && ~debug_sel);
    assign mod_row = generate_pip ? ((row-240) << 1) : row;
    assign mod_col = generate_pip ? ((col-320) << 1) : col;

    // Memory logic
    assign is_WR = (we_L == MEM_WR);
    // Video memory is just pixels (4 bits per pixel) in row major order.
    assign vram_addr = (((mod_row[9:1]) << 6) + (mod_row[9:1] << 4) + mod_col[9:3]);
    assign vmem_m_en = (address >= 16'h8000 && address < 16'hCB00);

    // Char memory is a 20x15 grid of characters (16 bits per char) in row major order.
    assign cram_addr = (mod_row[9:5] << 4) + (mod_row[9:5] << 2) + mod_col[9:5];
    assign cmem_m_en = (address[15:9] == 7'b1101_000);

    delay_cycles #(2, 10) row_delay(mod_row, CLOCK_50, reset_L, decode_row);
    delay_cycles #(2, 10) col_delay(mod_col, CLOCK_50, reset_L, decode_col);
    delay_cycles #(3, 1) hs_delay(generate_HS, CLOCK_50, reset_L, HS);
    delay_cycles #(3, 1) vs_delay(generate_VS, CLOCK_50, reset_L, VS);
    delay_cycles #(3, 1) blank_delay(generate_blank, CLOCK_50, reset_L, blank);
    delay_cycles #(3, 1) pip_delay(generate_pip, CLOCK_50, reset_L, display_pip);

    // ===================  FETCH STAGE  =====================

    // Bram created by quartus megafunction wizard.
`ifdef synthesis
    vram v(address[14:0], vram_addr[14:0], CLOCK_50, data, /* No d2 input */,
           (is_WR && vmem_m_en), 1'b0, /* No d1 output */, v_mem_output);
    cram c(address[8:0], cram_addr[8:0], CLOCK_50, data, /* No d2 input */,
           (is_WR && cmem_m_en), 1'b0, /* No d1 output */, c_mem_output);
`endif
   
    delay_cycles #(1, 16) char_delay(c_mem_output, CLOCK_50, reset_L, decode_char);
    delay_cycles #(1, 16) pixel_delay(v_mem_output, CLOCK_50, reset_L, decode_pixel);

    // ==================  DECODE STAGE  =====================

    fake_char_memory fmem(regView, memAddr, memData, pc, ir, sp,
                          condCodes, fake_cram_addr, fake_data);
    character_rom cr1(pixelmap, decode_char[7:0]);
    character_rom cr2(debug_pixelmap, fake_data);
    color_LUT cl(pixel_color, pixel_rgb);
    /* COLOR LUT outputs pixel_RGB from the 4 relevant bits of decode_pixel */

    assign fake_cram_addr = {decode_row[9:5], 4'b0} + {decode_row[9:5], 2'b0} + decode_col[9:5];

    assign color_addr = (decode_col[2:1] << 2);
    assign pixel_color = decode_pixel[color_addr + 3 -: 4];

    assign char_pixel_addr = {decode_row[4:2], decode_col[4:2]};

    assign decode_debug_is_on = debug_pixelmap[char_pixel_addr];
    assign decode_is_on = pixelmap[char_pixel_addr];

//    assign hex_pixelmap =  {9'b0, in[3:2],   2'b0, in[7:6],
//                            2'b0, in[1:0],   2'b0, in[5:4],
//                           18'b0, in[11:10], 2'b0, in[15:14],
//                            2'b0, in[9:8],   2'b0, in[13:12], 9'b0}

    // Expand 6 bit color into 24 bit color
    assign char_color = {{4{decode_char[13]}}, {4{decode_char[12]}}, {4{decode_char[11]}},
                         {4{decode_char[10]}}, {4{decode_char[9]}}, {4{decode_char[8]}}};

    assign char_rgb = decode_is_on ? char_color : 24'h0;
    //Debug text is always white
    assign debug_rgb = decode_debug_is_on ? 24'hFFFFFF : 24'h0;

    delay_cycles #(1, 24) crgb_delay(char_rgb, CLOCK_50, reset_L, disp_char_rgb);
    delay_cycles #(1, 24) drgb_delay(debug_rgb, CLOCK_50, reset_L, disp_debug_rgb);
    delay_cycles #(1, 24) prgb_delay(pixel_rgb, CLOCK_50, reset_L, disp_pixel_rgb);

    // ==================  DISPLAY STAGE  ====================

    assign debug_rgb_in = disp_sel ? disp_pixel_rgb : disp_char_rgb;
    assign debug_rgb_out = display_pip ? debug_rgb_in : disp_debug_rgb;
    assign VGA_RGB = debug_sel ? debug_rgb_in : debug_rgb_out;

    // =====================   END   =========================

endmodule: display_controller

/*
 * module: vga_controller
 *
 * Standard 18-240 VGA controller.
 * outputs VS, HS, blank, row, col.
 *
 */
module vga_controller
    (input logic CLOCK_50, reset_L,
    output logic HS, VS, blank,
    output logic [9:0] row, col);

    logic cb, rb, HS_L, VS_L;
    logic [11:0] c_row, c_col;

    assign col = (c_col-11'd288) >> 1;
    assign row = c_row - 11'd31;
    assign blank = rb || cb;

    //(12, 1600)
    counter #(12, 1600) ccc(CLOCK_50, reset_L, 1, 0, c_col);
    //(12, 521)
    counter #(12, 521) ccr(CLOCK_50, reset_L, c_col == 1599, 0, c_row);
    //orig params (12, 0, 192)
    range_check #(12, 0, 192) rchs(c_col, HS);
    //orig params (12, 0, 2)
    range_check #(12, 0, 2) rcvs(c_row, VS);
    //orig params (12, 288, 1568)
    range_check #(12, 288, 1568) rcbc(c_col, cb);
    //orig params 12, 31, 511)
    range_check #(12, 31, 511) rcbr(c_row, rb);

endmodule: vga_controller

/*
 * module: color_LUT
 *
 * A lookup table for pixel color in vram mode.
 * Each pixel has 4 bits for color, to give 16 possible color options.
 *
 */
module color_LUT(
    input logic [3:0] color_code,
    output logic [23:0] rgb_out);

    always_comb begin
        case(color_code)
            4'h0:  rgb_out = 24'h000000;
            4'h1:  rgb_out = 24'h7F0000;
            4'h2:  rgb_out = 24'hFF0000;
            4'h3:  rgb_out = 24'hFF00FF;
            4'h4:  rgb_out = 24'h007F7F;
            4'h5:  rgb_out = 24'h007F00;
            4'h6:  rgb_out = 24'h00FF00;
            4'h7:  rgb_out = 24'h00FFFF;
            4'h8:  rgb_out = 24'h00007F;
            4'h9:  rgb_out = 24'h7F007F;
            4'hA: rgb_out = 24'h0000FF;
            4'hB: rgb_out = 24'hC0C0C0;
            4'hC: rgb_out = 24'h7F7F7F;
            4'hD: rgb_out = 24'h7F7F00;
            4'hE: rgb_out = 24'hFFFF00;
            4'hF: rgb_out = 24'hFFFFFF;
        endcase
    end

endmodule: color_LUT

/*
 * module: fake_char_memory
 *
 * A fake memory for debug purposes. It has the same abstraction layer
 * as a cram (address in, color + ascii out), but the values are either
 * all hardcoded or dependent on proccessor state. It has asych read and
 * does not support writing.
 *
 */
module fake_char_memory(
    input logic [127:0] regView,
    input logic [15:0] memAddr, memData, pc, ir, sp,
    input logic [3:0] condCodes,
    input logic [9:0] address,
    output logic [15:0] data);

    logic [0:299][7:0] char_mem;

    generate
        genvar i;
        for (i=0; i < 4; i++)  begin: M1
            assign char_mem[i*20:((i+1)*20)-1] = {
              "R", (8'h30 + {i[1:0], 1'b0}), ":0x", `hex_to_chars(regView, {i[1:0], 5'd0}),
            "  R", (8'h31 + {i[1:0], 1'b0}), ":0x", `hex_to_chars(regView, {i[1:0], 5'd16})};
        end
    endgenerate
    assign char_mem[80:99]  = "                    ";
    assign char_mem[100:119] = {"MA:0x", `hex_to_chars(memAddr, 0), "  MD:0x", `hex_to_chars(memData, 0)};
    assign char_mem[120:139] = {"PC:0x", `hex_to_chars(pc, 0), "           "};
    assign char_mem[140:159] = {"IR:0x", `hex_to_chars(ir, 0), "           "};
    assign char_mem[160:179] = {"SP:0x", `hex_to_chars(sp, 0), "           "};
    assign char_mem[180:199] = {"CC:0b", {8'h30+condCodes[3], 8'h30+condCodes[2], 8'h30+condCodes[1], 8'h30+condCodes[0]}, "           "};
    assign char_mem[200:219] = "                    ";
    assign char_mem[220:239] = "                    ";
    assign char_mem[240:259] = "P18240              ";
    assign char_mem[260:279] = "Debug               ";
    assign char_mem[280:299] = "Display             ";
   
    assign data = {8'hFF, char_mem[address]};

endmodule: fake_char_memory

/*
 * module: character_rom
 *
 * The ROM lookup table for ascii number to bitmap. The bitmap is read
 * out left to right, top to bottom across the 64 pixels. (8x8)
 *
 */
module character_rom
  (output  logic  [63:0]  data,
   input   logic  [7:0]   address);

  logic [63:0] mem [8'hFF :8'h00];

  assign data = mem[address];

  initial $readmemh("char_rom.hex", mem);

endmodule: character_rom

/*
 * module: delay_cycles
 *
 * Delays a signal by a number of cycles, used to keep VGA signals
 * in sync across the pipeline.
 *
 */
module delay_cycles #(parameter NUM_CYCLES = 3, WIDTH = 1)(
    input logic [WIDTH-1:0] in,
    input logic clock, reset_L,
    output logic [WIDTH-1:0] out);

    logic [WIDTH-1:0] middle [NUM_CYCLES-2:0];

    generate
        genvar i;
        if(NUM_CYCLES == 1) begin
            register #(WIDTH) first(out, in, 1'b0, clock, reset_L);
        end
        else begin
            for (i=0; i < NUM_CYCLES; i++)  begin: M2
                if(i == 0)
                    register #(WIDTH) first(middle[0], in, 1'b0, clock, reset_L);
                else if(i == NUM_CYCLES - 1)
                    register #(WIDTH) mid(out, middle[i-1], 1'b0, clock, reset_L);
                else
                    register #(WIDTH) last(middle[i], middle[i-1], 1'b0, clock, reset_L);
            end
        end
    endgenerate

endmodule: delay_cycles

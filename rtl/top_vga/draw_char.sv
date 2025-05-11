//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Draw char
 Author:        Wojciech Miskowicz
 Description:   Draws a char contained in font_rom. It can be upscaled using PRESCALER parameter.
 FIELD_SIZE defines the width of the field for each character.
 */
//////////////////////////////////////////////////////////////////////////////

module draw_char #(
  parameter PRESCALER = 1,
  parameter OFFSET_X = 0,
  parameter OFFSET_Y = 0,
  parameter FIELD_SIZE = 8 * PRESCALER
)(
  input wire clk,
  input wire rst,

  input logic [11:0] char_code,
  input logic [11:0] char_xpos,
  input logic [11:0] char_ypos,

  input logic [11:0] num_color,

  vga_if.in in,
  vga_if.out out
);

localparam bit [255:0] PIXEL_MASK = 1 << (PRESCALER * 8);
localparam MASK_LEN = $clog2(8*PRESCALER);

logic [10:0] char_hcount, scale_hcount;
logic [10:0] char_vcount, scale_vcount;
logic [10:0] vcount_reg;
logic [3:0] char_line;

logic [(PRESCALER*8)-1:0] char_pixels;
logic in_char_field;
logic [11:0] actual_char_xpos;
logic [11:0] actual_char_ypos;

assign actual_char_xpos = char_xpos + OFFSET_X;
assign actual_char_ypos = char_ypos + OFFSET_Y;

assign char_line = char_vcount[3:0];

assign char_vcount = scale_vcount - actual_char_ypos;
assign char_hcount = in.hcount - actual_char_xpos;

assign in_char_field = (in.hcount >= actual_char_xpos) &&
  (in.hcount < (actual_char_xpos + FIELD_SIZE)) &&
  (in.vcount >= actual_char_ypos) &&
  (in.vcount < (actual_char_ypos + (16 * PRESCALER)));

always_ff @(posedge clk) begin
  if (rst) begin
    scale_vcount <= 11'h0;
    scale_hcount <= 11'h0;
    vcount_reg   <= 11'h0;
  end
  else if (PRESCALER != 1) begin
    vcount_reg   <= in.vcount;
    if (in.vcount == 0)
      scale_vcount <= 11'h0;
    else if(vcount_reg != in.vcount && in.vcount % PRESCALER == 0) begin
      scale_vcount <= scale_vcount + 1;
    end
    scale_hcount <= (in.hcount % PRESCALER == 0) ? scale_hcount + 1 : scale_hcount;
  end
  else begin
    vcount_reg   <= in.vcount;
    scale_vcount <= in.vcount;
    scale_hcount <= in.hcount;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    out.vcount <= '0;
    out.vblnk  <= '0;
    out.vsync  <= '0;
    out.hcount <= '0;
    out.hsync  <= '0;
    out.hblnk  <= '0;
    out.rgb    <= '0;
  end
  else begin
    out.vcount <= in.vcount;
    out.vsync  <= in.vsync;
    out.vblnk  <= in.vblnk;
    out.hcount <= in.hcount;
    out.hsync  <= in.hsync;
    out.hblnk  <= in.hblnk;
    if (in_char_field && char_pixels & (PIXEL_MASK >> char_hcount[MASK_LEN-1:0])) begin
      out.rgb <= num_color;
    end
    else begin
      out.rgb <= in.rgb;
    end
  end
end

font_rom #(
  .PRESCALER(PRESCALER)
) u_font_rom (
  .clk             (clk),
  .addr            ({char_code[6:0], char_line[3:0]}),
  .char_line_pixels(char_pixels)
);

endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Draw background objects
 Author:        Wojciech Miskowicz
 Description:   Draws images in the background display.
 */
//////////////////////////////////////////////////////////////////////////////

module draw_back_objects (
  input  logic clk,
  input  logic rst,
  vga_if.in in,
  vga_if.out out
);

import vga_pkg::*;

vga_if image1_vga();
vga_if image2_vga();
vga_if image3_vga();

draw_image #(
  .RECT_WIDTH (64),
  .RECT_HEIGHT(64),
  .PATH       ("../../rtl/top_vga/data/bg_anim1_64.data")
)
u_draw_image1 (
  .clk       (clk),
  .in        (in),
  .out       (image1_vga.out),
  .rect_x_pos(12'd150),
  .rect_y_pos(12'd150),
  .rst       (rst)
);

draw_image #(
  .RECT_WIDTH (64),
  .RECT_HEIGHT(64),
  .PATH       ("../../rtl/top_vga/data/bg_anim2_64.data")
)
u_draw_image2 (
  .clk       (clk),
  .in        (image1_vga.in),
  .out       (image2_vga.out),
  .rect_x_pos(12'd850),
  .rect_y_pos(12'd450),
  .rst       (rst)
);

draw_image #(
  .RECT_WIDTH (64),
  .RECT_HEIGHT(64),
  .PATH       ("../../rtl/top_vga/data/bg_anim3_64.data")
)
u_draw_image3 (
  .clk       (clk),
  .in        (image2_vga.in),
  .out       (out),
  .rect_x_pos(12'd350),
  .rect_y_pos(12'd550),
  .rst       (rst)
);

endmodule

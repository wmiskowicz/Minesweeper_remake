`timescale 1 ns / 1 ps

module draw_back_objects (
  input  logic clk,
  input  logic rst,
  input  logic [11:0] rect_x_pos,
  input  logic [11:0] rect_y_pos,
  vga_if.in in,
  vga_if.out out
);

import vga_pkg::*;

vga_if image1_vga();
vga_if image2_vga();

draw_image #(
  .RECT_WIDTH (64),
  .RECT_HEIGHT(64),
  .PATH       ("../../rtl/top_vga/data/bomb.data")
)
u_draw_bomb1 (
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
  .PATH       ("../../rtl/top_vga/data/flag.data")
)
u_draw_flag1 (
  .clk       (clk),
  .in        (image1_vga.in),
  .out       (out),
  .rect_x_pos(12'd850),
  .rect_y_pos(12'd450),
  .rst       (rst)
);


endmodule

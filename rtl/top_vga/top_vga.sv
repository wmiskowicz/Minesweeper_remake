/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2023  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 * Wojciech Miskowicz
 * Description:
 * The project top module.
 */

 `timescale 1 ns / 1 ps

 module top_vga (
    input  logic        clk,
    input  logic        rst,
    output logic        vs,
    output logic        hs,
    output logic  [3:0] r,
    output logic  [3:0] g,
    output logic  [3:0] b,

    input logic  [11:0] mouse_xpos,  
    input logic  [11:0] mouse_ypos
 );
 
 /**
  * Local variables and signals
  */

 vga_if tim_bg_vga();
 vga_if background_vga();
 vga_if back_obj_vga();
 vga_if mouse_vga();
 vga_if output_vga();

 
 
 /**
  * Signals assignments
  */
 assign vs      = output_vga.vsync;
 assign hs      = output_vga.hsync;
 assign {r,g,b} = output_vga.rgb;
 
 /**
  * Submodules instances
  */

 vga_timing u_vga_timing (
    .clk,
    .rst,
    .out(tim_bg_vga.out)
);

draw_bg u_draw_bg (
    .clk,
    .rst,
    .in(tim_bg_vga.in),
    .out(background_vga.out)
);

draw_back_objects u_draw_back_objects (
  .clk       (clk),
  .rst       (rst),
  .in        (background_vga.in),
  .out       (back_obj_vga.out)
);

 draw_mouse u_draw_mouse(
    .clk,
    .rst,
    .in(back_obj_vga.in),
    .out(mouse_vga.out),
    .mouse_xpos(mouse_xpos),
    .mouse_ypos(mouse_ypos)
 );

 vga_out u_vga_out (
   .clk(clk),
   .rst(rst),
   .in (mouse_vga.in),
   .out(output_vga.out)
 );

 endmodule

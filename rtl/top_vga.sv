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
     output wire   [3:0] an,
     output wire   [6:0] sseg,

     inout ps2_clk,
     inout ps2_data 
 );
 
 /**
  * Local variables and signals
  */

 vga_if tim_bg_vga();
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
    .out(mouse_vga.out)
);


 top_mouse u_top_mouse(
    .clk,
    .rst,
    .in(mouse_vga.in),
    .out(output_vga.out),
    .mouse_xpos(),
    .mouse_ypos(),
    .ps2_clk,
    .ps2_data,
    .right(),
    .left()
 );
 
 disp_hex_mux u_disp(
    .clk(clk), 
    .reset(rst),
    .hex3(), 
    .hex2(), 
    .hex1(), 
    .hex0(),
    .an(an), 
    .sseg(sseg)
);


 endmodule
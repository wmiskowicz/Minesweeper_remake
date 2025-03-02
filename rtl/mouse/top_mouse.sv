//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   top_mouse
 Author:        Wojciech Miskowicz
 Last modified: 2023-06-25
 Description:  Top module for mouse signals
 */
//////////////////////////////////////////////////////////////////////////////

 `timescale 1 ns / 1 ps

 module top_mouse (
     input  wire clk100MHz,
     input  wire clk40MHz,
     input  wire rst,
     inout  ps2_clk,
     inout  ps2_data,
     output logic right,
     output logic left,
     output logic [11:0] mouse_xpos,
     output logic [11:0] mouse_ypos
 );
 
 wire [11:0] xpos_in;
 wire [11:0] ypos_in;

 MouseCtl u_MouseCtl(
    .clk(clk100MHz),
    .rst,
    .xpos(xpos_in),
    .ypos(ypos_in),
    .ps2_clk,
    .ps2_data,
    .zpos(),
    .left(left),
    .middle(),
    .right(right),
    .new_event(),
    .value(12'd100),
    .setx(0),
    .sety(0),
    .setmax_x(0),
    .setmax_y(0)
 );



 cross_buffer u_cross_buffer (
   .clk40MHz     (clk40MHz),
   .clk100MHz    (clk100MHz),
   .rst     (rst),
   .xpos_in (xpos_in),
   .ypos_in (ypos_in),
   .xpos_out(mouse_xpos),
   .ypos_out(mouse_ypos)
 );

 endmodule
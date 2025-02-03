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
     input  logic clk,
     input  wire [2:0] btnS,
     input  wire tim_stop, 
     input  logic rst,
     output logic vs,
     output logic hs,
     output logic [3:0] r,
     output logic [3:0] g,
     output logic [3:0] b,
     output wire [3:0] an,
     output wire [6:0] sseg,

     inout ps2_clk,
     inout ps2_data 
 );

 
 
 /**
  * Local variables and signals
  */



 /**
 * VGA interfaces
 */
 vga_if tim_bg_if();

 
 
 /**
  * Signals assignments
  */
 
 
 /**
  * Submodules instances
  */
 top_mouse u_top_mouse(
    .clk,
    .rst,
    .in(),
    .out(),
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
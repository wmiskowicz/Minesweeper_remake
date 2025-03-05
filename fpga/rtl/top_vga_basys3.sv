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
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

`timescale 1 ns / 1 ps

module top_vga_basys3 (
    input  wire       clk,
    input  wire       btnD,
    input  wire       btnL,
    input  wire       btnC,
    input  wire       btnR,

    inout  wire       PS2Clk,
    inout  wire       PS2Data,

    output wire       led,

    output wire       Vsync,
    output wire       Hsync,
    output wire [3:0] vgaRed,    
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,

    output wire [6:0] seg,
    output wire [3:0] an
);


/**
 * Local variables and signals
 */

wire [11:0] mouse_xpos;
wire [11:0] mouse_ypos;
wire mouse_right;
wire mouse_left;

wire clk100MHz;
wire clk74MHz;
wire clk40MHz;
wire locked;
logic rst;
logic [1:0] level;

(* KEEP = "TRUE" *)
(* ASYNC_REG = "TRUE" *)

/**
 * Signals assignments
 */
assign rst = btnD;
assign led = locked;
assign level = {btnR || btnC, btnL || btnR};


/**
 * FPGA submodules placement
 */

 clk_wiz_1 clk0_wiz(
  .clk      (clk),
  .reset    (rst),
  .locked   (locked),
  .clk100MHz(clk100MHz),
  .clk74MHz (clk74MHz),
  .clk40MHz (clk40MHz)
);

top_vga u_top_vga (
    .clk          (clk74MHz),
    .rst          (rst),
    .r            (vgaRed),
    .g            (vgaGreen),
    .b            (vgaBlue),
    .hs           (Hsync),
    .vs           (Vsync),

    .mouse_xpos   (mouse_xpos),
    .mouse_ypos   (mouse_ypos)
);

top_mouse u_top_mouse (
  .clk100MHz  (clk100MHz),
  .clk40MHz   (clk40MHz),
  .clk74MHz   (clk74MHz),
  .rst       (rst),
  .ps2_clk   (PS2Clk),
  .ps2_data  (PS2Data),

  .left      (),
  .right     (),
  .mouse_xpos(mouse_xpos),
  .mouse_ypos(mouse_ypos)
);

sseg_disp u_disp(
  .clk    (clk40MHz), 
  .reset  (rst),
  .hex3   (), 
  .hex2   (), 
  .hex1   (), 
  .hex0   (),
  .an     (an), 
  .sseg   (seg)
);

main_fsm u_main_fsm (
  .clk       (clk40MHz),
  .rst       (rst),
  .level     (level),
  .game_lost (1'b0),
  .game_won  (1'b0),
  .retry     (1'b0),
  .timer_stop(1'b0)
);


endmodule

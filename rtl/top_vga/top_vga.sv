//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Top VGA
 Author:        Wojciech Miskowicz
 Description:   Top module containing all VGA display logic.
 */
//////////////////////////////////////////////////////////////////////////////

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
  input logic  [11:0] mouse_ypos,

  input logic  [2:0]  main_state,

  input wire game_lost,
  input wire game_won,
  input wire back_to_menu,
  input wire retry, 


  wishbone_if.master game_settings_wb,
  wishbone_if.master game_board_wb
);

// ----- Signal intefaces -----
vga_if tim_bg_vga();
vga_if del1_vga();
vga_if background_vga();
vga_if back_obj_vga();
vga_if board_vga();
vga_if writings_vga();
vga_if mouse_vga();
vga_if output_vga();


// ----- Signal assignments -----
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

delay_vga u_delay_vga (
  .clk(clk),
  .rst(rst),
  .in (tim_bg_vga.in),
  .out(del1_vga.out)
);

draw_bg u_draw_bg (
  .clk,
  .rst,
  .in(del1_vga.in),
  .out(background_vga.out)
);

draw_back_objects u_draw_back_objects (
  .clk (clk),
  .rst (rst),
  .in  (background_vga.in),
  .out (back_obj_vga.out)
);

draw_board u_draw_board (
  .clk          (clk),
  .rst          (rst),
  .back_to_menu (back_to_menu),
  .retry        (retry),

  .main_state(main_state),
  .in        (back_obj_vga.in),
  .out       (board_vga.out),

  .game_settings_wb(game_settings_wb),
  .game_board_wb(game_board_wb)
);

writings u_writings (
  .clk      (clk),
  .rst      (rst),

  .main_state(main_state),
  .game_lost(game_lost),
  .game_won (game_won),

  .in       (board_vga.in),
  .out      (writings_vga.out)
);

draw_mouse u_draw_mouse(
  .clk,
  .rst,
  .in(writings_vga.in),
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

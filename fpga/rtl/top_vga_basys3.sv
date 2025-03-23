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
wire [2:0] main_state;

wire [11:0] mouse_xpos;
wire [11:0] mouse_ypos;

wire clk100MHz;
wire clk74MHz;
wire clk40MHz;
wire locked;
logic rst;
logic [1:0] level;

wire planting_complete;
wire left;
wire right;
wire game_set_wb;
wire game_board_wb;

(* KEEP = "TRUE" *)
(* ASYNC_REG = "TRUE" *)

/**
 * Signals assignments
 */
assign rst = btnD;
assign led = locked;
assign level = {btnR || btnC, btnL || btnR};


wishbone_if planter_set_wb_if();
wishbone_if planter_board_wb_if();

wishbone_if defuser_set_wb_if();
wishbone_if defuser_board_wb_if();

wishbone_if vga_board_wb_if();
wishbone_if vga_set_wb_if();


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
    .mouse_ypos   (mouse_ypos),
    .main_state   (main_state),

    .game_settings_wb(vga_set_wb_if.master),
    .game_board_wb   (vga_board_wb_if.master)

);

top_mouse u_top_mouse (
  .clk100MHz  (clk100MHz),
  .clk40MHz   (clk40MHz),
  .clk74MHz   (clk74MHz),
  .rst       (rst),
  .ps2_clk   (PS2Clk),
  .ps2_data  (PS2Data),

  .left      (left),
  .right     (right),
  .mouse_xpos(mouse_xpos),
  .mouse_ypos(mouse_ypos)
);

top_memory u_top_memory (
  .clk100MHz(clk100MHz),
  .clk40MHz (clk40MHz),
  .clk74MHz (clk74MHz),
  .rst      (rst),

  .read_wb  (vga_board_wb_if.slave),
  .write1_wb(planter_board_wb_if.master),
  .write2_wb(defuser_board_wb_if.master)
);

defuser u_defuser (
  .clk              (clk),
  .rst              (rst),

  .planting_complete(planting_complete),

  .mouse_xpos       (mouse_xpos),
  .mouse_ypos       (mouse_ypos),

  .left             (left),
  .right            (right),

  .game_board_wb    (defuser_board_wb_if.master),
  .game_set_wb      (defuser_set_wb_if.master)
);


mine_planter u_mine_planter (
  .clk          (clk),
  .rst          (rst),

  .main_state   (main_state),
  .planting_complete(planting_complete),
  .game_board_wb(planter_board_wb_if.master),
  .game_set_wb  (planter_set_wb_if.master)
);


sseg_disp u_disp(
  .clk    (clk40MHz), 
  .reset  (rst),
  .hex3   ('0), 
  .hex2   ('0), 
  .hex1   ('0), 
  .hex0   ('0),
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
  .timer_stop(1'b0),

  .state_out(main_state),

  .game_set_wb1(planter_set_wb_if.slave),
  .game_set_wb2(defuser_set_wb_if.slave),
  .game_set_wb3(vga_set_wb_if.slave)
);


endmodule

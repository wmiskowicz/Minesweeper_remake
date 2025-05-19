//////////////////////////////////////////////////////////////////////////////
 /*
  Module name:   Minesweeper Top
  Author:        Wojciech Miskowicz
  Description:   Top module for Minesweeper project for Xilinx Basys3 FPGA. 
  */
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module top_basys3 (
  input  wire       clk,
  input  wire       btnD,
  input  wire       btnL,
  input  wire       btnC,
  input  wire       btnR,

  inout  wire       PS2Clk,
  inout  wire       PS2Data,

  output logic [3:0] led,

  output wire       Vsync,
  output wire       Hsync,
  output wire [3:0] vgaRed,
  output wire [3:0] vgaGreen,
  output wire [3:0] vgaBlue,

  output wire [6:0] seg,
  output wire [3:0] an
);


// ----- Local variables -----
wire clk100MHz;
wire clk74MHz;
wire locked;

logic rst;
logic [1:0] level;

wire [2:0]  main_state;

wire [11:0] mouse_xpos;
wire [11:0] mouse_ypos;

wire left;
wire right;

wire game_lost;
wire game_won;

wire planting_complete;

(* KEEP = "TRUE" *)
(* ASYNC_REG = "TRUE" *)


// ----- Signal assignments -----
assign rst = btnD;
assign level = {btnR || btnC, btnL || btnR};

assign led[0] = locked;
assign led[1] = 0;
assign led[2] = 1;
assign led[3] = 0;


// ----- Signal intefaces -----
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
  .reset    (1'b0),
  .locked   (locked),
  .clk100MHz(clk100MHz),
  .clk74MHz (clk74MHz),
  .clk40MHz ()
);


sseg_disp u_disp(
  .clk    (clk74MHz),
  .reset  (rst),
  .hex3   (0),
  .hex2   (0),
  .hex1   (0),
  .hex0   (0),
  .an     (an),
  .sseg   (seg)
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
  .clk74MHz (clk74MHz),
  .rst      (rst),

  .read_wb  (vga_board_wb_if.slave),
  .write1_wb(planter_board_wb_if.slave),
  .write2_wb(defuser_board_wb_if.slave)
);

defuser u_defuser (
  .clk              (clk74MHz),
  .rst              (rst),

  .planting_complete(planting_complete),
  .main_state       (main_state),

  .mouse_xpos       (mouse_xpos),
  .mouse_ypos       (mouse_ypos),

  .left             (left),
  .right            (right),

  .game_lost        (game_lost),
  .game_won         (game_won),

  .game_board_wb    (defuser_board_wb_if.master),
  .game_set_wb      (defuser_set_wb_if.master)
);


mine_planter u_mine_planter (
  .clk          (clk74MHz),
  .rst          (rst),

  .main_state   (main_state),
  .planting_complete(planting_complete),
  .game_board_wb(planter_board_wb_if.master),
  .game_set_wb  (planter_set_wb_if.master)
);



main_fsm u_main_fsm (
  .clk       (clk74MHz),
  .rst       (rst),
  .level     (level),

  .game_lost (game_lost),
  .game_won  (game_won),
  .retry     (1'b0),
  .timer_stop(1'b0),

  .state_out(main_state),

  .game_set_wb1(planter_set_wb_if.slave),
  .game_set_wb2(defuser_set_wb_if.slave),
  .game_set_wb3(vga_set_wb_if.slave)
);


endmodule

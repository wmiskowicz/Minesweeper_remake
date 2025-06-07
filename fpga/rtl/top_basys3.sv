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
  input  wire       btnU,
  input  wire       btnL,
  input  wire       btnC,
  input  wire       btnR,
  input  wire       sw,

  inout  wire       PS2Clk,
  inout  wire       PS2Data,

  output logic [3:0] led,

  output wire       Vsync,
  output wire       Hsync,
  output wire [3:0] vgaRed,
  output wire [3:0] vgaGreen,
  output wire [3:0] vgaBlue,

  output logic [6:0] seg,
  output logic [3:0] an,
  output logic       dp
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

wire start, timer_stop;
wire retry;
wire  [7:0] sec_to_count;
logic [7:0] seconds_out;
logic       time_elapsed;

(* KEEP = "TRUE" *)
(* ASYNC_REG = "TRUE" *)


// ----- Signal assignments -----
assign rst = btnD;
assign level = {btnR || btnC, btnL || btnR};

assign timer_stop = sw;
assign retry = btnU;

assign led[0] = locked;
assign led[1] = time_elapsed;
assign led[2] = 0;
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

clk_wiz_0 clk0_wiz(
  .clk_in    (clk),
  .locked    (locked),
  .clk_100MHz(clk100MHz),
  .clk_74MHz (clk74MHz)
);


sseg_disp u_disp(
  .clk    (clk74MHz),
  .reset  (rst),
  .dp_in  (4'b1111), // active low

  .hex3   (seconds_out[7:4]),
  .hex2   (seconds_out[3:0]),
  .hex1   (0),
  .hex0   (0),

  .an     (an),
  .sseg   (seg),
  .dp     (dp)
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
  .retry     (retry),

  .timer_stop   (timer_stop),
  .seconds_left (seconds_out),
  .time_elapsed (time_elapsed),

  .state_out    (main_state),

  .game_set_wb1 (planter_set_wb_if.slave),
  .game_set_wb2 (defuser_set_wb_if.slave),
  .game_set_wb3 (vga_set_wb_if.slave)
);


endmodule

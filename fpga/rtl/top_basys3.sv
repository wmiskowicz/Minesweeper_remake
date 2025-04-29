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


/**
 * Local variables and signals
 */

wire clk100MHz;
wire clk74MHz;
wire locked;
logic rst;
logic [1:0] level;

wire [3:0] mouse_board_ind_x;
wire [3:0] mouse_board_ind_y;

(* KEEP = "TRUE" *)
(* ASYNC_REG = "TRUE" *)

/**
 * Signals assignments
 */
assign rst = btnD;
assign led[0] = locked;
assign led[1] = 0;
assign led[2] = 1;
assign led[3] = 0;
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
  .reset    (1'b0),
  .locked   (locked),
  .clk100MHz(clk100MHz),
  .clk74MHz (clk74MHz),
  .clk40MHz ()
);


sseg_disp u_disp(
  .clk    (clk74MHz),
  .reset  (rst),
  .hex3   (mouse_board_ind_x),
  .hex2   (mouse_board_ind_y),
  .hex1   (0),
  .hex0   (0),
  .an     (an),
  .sseg   (seg)
);

top_memory_logic u_top_memory_logic (
  .clk100MHz        (clk100MHz),
  .clk74MHz         (clk74MHz),
  .rst              (rst),

  .level            (level),

  .PS2Clk           (PS2Clk),
  .PS2Data          (PS2Data),

  .Vsync            (Vsync),
  .Hsync            (Hsync),
  .vgaBlue          (vgaBlue),
  .vgaGreen         (vgaGreen),
  .vgaRed           (vgaRed),


  .mouse_board_ind_x(mouse_board_ind_x),
  .mouse_board_ind_y(mouse_board_ind_y)

);


endmodule

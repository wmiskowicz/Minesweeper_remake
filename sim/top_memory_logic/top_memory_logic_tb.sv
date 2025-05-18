`timescale 1 ns / 1 ps
`include "../../rtl/memory/wishbone_defs.svh"

import vga_pkg::*;
import logger_pkg::*;
import game_pkg::*;

module top_memory_logic_tb;


  /**
   *  Local parameters
   */

  localparam CLK_PERIOD = 10ns;     // 100 MHz


  /**
   * Local variables and signals
   */

  logic clk, rst;
  wire vs, hs;
  wire [3:0] r, g, b;
  logic [1:0] level;
  logic planting_complete;

  logic [3:0] mouse_board_ind_x;
  logic [3:0] mouse_board_ind_y;

  logic mouse_xpos_valid;
  logic mouse_ypos_valid;  

  /**
   * Clock generation
   */

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end


  /**
   * Submodules instances
   */

   top_memory_logic dut (
    .clk100MHz        (clk),
    .clk74MHz         (clk),
    .rst              (rst),
  
    .level            (level),
  
    .PS2Clk           (),
    .PS2Data          (),
  
    .Vsync            (vs),
    .Hsync            (hs),
    .vgaBlue          (b),
    .vgaGreen         (g),
    .vgaRed           (r)  
  );

  tiff_writer #(
    .XDIM(HOR_TOTAL_TIME),
    .YDIM(VER_TOTAL_TIME),
    .FILE_DIR("../../results")
  ) u_tiff_writer (
    .clk(clk),
    .r({r,r}), // fabricate an 8-bit value
    .g({g,g}), // fabricate an 8-bit value
    .b({b,b}), // fabricate an 8-bit value
    .go(vs)
  );

 initial begin
  void'(logger::init());
  $display("Check if board is propagated properly");
  level = 0;
  dut.u_top_mouse.left_in = 0;
  dut.u_top_mouse.right_in = 0;
  InitReset();
  level = 1;
  WaitClocks(15);

  dut.u_top_mouse.left_in = 1;
  WaitClocks(20);
  dut.u_top_mouse.left_in = 0;
  WaitClocks(200);

  dut.u_top_mouse.left_in = 1;
  WaitClocks(20);
  dut.u_top_mouse.left_in = 0;
  WaitClocks(200);

  dut.u_top_mouse.right_in = 1;
  WaitClocks(20);
  dut.u_top_mouse.right_in = 0;
  WaitClocks(200);

  dut.u_top_mouse.left_in = 1;
  WaitClocks(20);
  dut.u_top_mouse.left_in = 0;
  WaitClocks(200);

  wait (vs == 1'b0);
  @(negedge vs) $display("Info: negedge VS at %t",$time);
  @(negedge vs) $display("Info: negedge VS at %t",$time);

  $finish();
 end

  task automatic WaitClocks(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk);
  endtask

  task automatic InitReset();
    rst = 1;
    WaitClocks(10);
    rst = 0;
    WaitClocks(10);
  endtask

endmodule

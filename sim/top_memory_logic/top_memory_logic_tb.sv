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
    .clk40MHz         (clk),
    .clk74MHz         (clk),
    .rst              (rst),
  
    .level            (level),
  
    .PS2Clk           (),
    .PS2Data          (),
  
    .Vsync            (vs),
    .Hsync            (hs),
    .vgaBlue          (b),
    .vgaGreen         (g),
    .vgaRed           (r),
  
    .planting_complete(planting_complete),
  
    .mouse_board_ind_x(mouse_board_ind_x),
    .mouse_board_ind_y(mouse_board_ind_y),
    .mouse_xpos_valid (mouse_xpos_valid),
    .mouse_ypos_valid (mouse_ypos_valid)
  
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
  InitReset();
  level = 1;
  WaitClocks(15);
  `check_eq(dut.u_mine_planter.row_col_num, E_ROW_COLUMN_NUMBER);
 wait(dut.u_top_vga.u_draw_board.auto_read_state == 2'd1); //AUTO_READ
 wait(dut.u_top_vga.u_draw_board.auto_read_state == 2'd0); // WAIT
  for (int i = 0; i < 16; i++)
    for (int j = 0; j < 16; j++) begin
      $display($sformatf("i = %d, j=%d",i, j));
      `check_eq(dut.u_mine_planter.mine_map[i][j], dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
      `check_eq(dut.u_top_vga.u_draw_board.game_board_mem[i][j].mine, dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
      `check_eq(dut.u_defuser.game_board_mem[i][j].mine, dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
    end

    WaitClocks(5000);
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

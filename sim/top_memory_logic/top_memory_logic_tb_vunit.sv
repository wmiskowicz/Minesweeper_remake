/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2023  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * Testbench for top_fpga.
 * Thanks to the tiff_writer module, an expected image
 * produced by the project is exported to a tif file.
 * Since the vs signal is connected to the go input of
 * the tiff_writer, the first (top-left) pixel of the tif
 * will not correspond to the vga project (0,0) pixel.
 * The active image (not blanked space) in the tif file
 * will be shifted down by the number of lines equal to
 * the difference between VER_SYNC_START and VER_TOTAL_TIME.
 */

`timescale 1 ns / 1 ps
`include "vunit_defines.svh"
`include "../../rtl/memory/wishbone_defs.svh"

import vga_pkg::*;
import logger_pkg::*;
import game_pkg::*;

module top_memory_logic_tb_vunit;


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

  `TEST_SUITE begin

  // TEST SUITE SETUP (Runs ONCE before all test cases)
  `TEST_SUITE_SETUP begin
    level = 0;
    InitReset();
  end

  // TEST CASE 1
  `TEST_CASE("TC001") begin
    $display("Generate vga image.");
    level = 2;
    
    wait (vs == 1'b0);

    @(negedge vs) $display("Info: negedge VS at %t",$time);
    @(negedge vs) $display("Info: negedge VS at %t",$time);

    // End the simulation.
    $display("Simulation is over, check the waveforms.");
    $finish;
  end

  // TEST CASE 2
  `TEST_CASE("TC002") begin
    $display("Check if settings network works properly.");
    level = 1;
    WaitClocks(2);
    `CHECK_EQUAL(dut.u_main_fsm.game_setup_mem[ROW_COLUMN_NUMBER_REG_NUM], E_ROW_COLUMN_NUMBER);
    `CHECK_EQUAL(dut.u_main_fsm.game_setup_mem[MINE_NUM_REG_NUM], E_MINE_NUM);
    `CHECK_EQUAL(dut.u_main_fsm.game_setup_mem[TIMER_SECONDS_REG_NUM], E_TIMER_SECONDS);
    `CHECK_EQUAL(dut.u_main_fsm.game_setup_mem[FIELD_SIZE_REG_NUM], E_FIELD_SIZE);
    `CHECK_EQUAL(dut.u_main_fsm.game_setup_mem[BOARD_SIZE_REG_NUM], E_BOARD_SIZE);
    `CHECK_EQUAL(dut.u_main_fsm.game_setup_mem[BOARD_XPOS_REG_NUM], E_BOARD_XPOS);
    `CHECK_EQUAL(dut.u_main_fsm.game_setup_mem[BOARD_YPOS_REG_NUM], E_BOARD_YPOS);

    WaitClocks(200);
    `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM], E_ROW_COLUMN_NUMBER);
    `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_setup_cashe[MINE_NUM_REG_NUM], E_MINE_NUM);
    `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_setup_cashe[TIMER_SECONDS_REG_NUM], E_TIMER_SECONDS);
    `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_setup_cashe[FIELD_SIZE_REG_NUM], E_FIELD_SIZE);
    `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_setup_cashe[BOARD_SIZE_REG_NUM], E_BOARD_SIZE);
    `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_setup_cashe[BOARD_XPOS_REG_NUM], E_BOARD_XPOS);
    `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_setup_cashe[BOARD_YPOS_REG_NUM], E_BOARD_YPOS);

    WaitClocks(5000);
    `CHECK_EQUAL(planting_complete, 1'b1);
    `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM], E_ROW_COLUMN_NUMBER);
    `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[MINE_NUM_REG_NUM], E_MINE_NUM);
    `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[TIMER_SECONDS_REG_NUM], E_TIMER_SECONDS);
    `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[FIELD_SIZE_REG_NUM], E_FIELD_SIZE);
    `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[BOARD_SIZE_REG_NUM], E_BOARD_SIZE);
    `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[BOARD_XPOS_REG_NUM], E_BOARD_XPOS);
    `CHECK_EQUAL(dut.u_defuser.game_setup_cashe[BOARD_YPOS_REG_NUM], E_BOARD_YPOS);
  end

  `TEST_CASE("TC003") begin
    $display("Check if board is propagated properly");
    level = 1;
    WaitClocks(15);
    `CHECK_EQUAL(dut.u_mine_planter.row_col_num, E_ROW_COLUMN_NUMBER);

    wait(dut.u_top_vga.u_draw_board.auto_read_state == 2'd1); //AUTO_READ
    wait(dut.u_top_vga.u_draw_board.auto_read_state == 2'd0); // WAIT 
    for (int i = 0; i < 16; i++)
      for (int j = 0; j < 16; j++) begin
        `CHECK_EQUAL(dut.u_mine_planter.mine_map[i][j], dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine, $sformatf("i = %d, j=%d",i, j));
        `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_board_mem[i][j].mine, dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine, $sformatf("i = %d, j=%d",i, j));
      end
  end

  `TEST_CASE("TC004") begin
    $display("Check mouse signals");
    level = 1;
    WaitClocks(15);

  end


  end



  /**
   * Main test
   */

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

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
import vga_pkg::*;
import logger_pkg::*;
import game_pkg::*;

module top_basys3_tb;


  /**
   *  Local parameters
   */

  localparam CLK_PERIOD = 10ns;     // 100 MHz


  /**
   * Local variables and signals
   */

  logic clk, rst;
  wire pclk;
  wire vs, hs;
  wire [3:0] r, g, b;


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

  top_basys3 dut (
    .clk(clk),
    .btnD(rst),

    .PS2Clk(),
    .PS2Data(),

    .btnL('0),
    .btnC('1),
    .btnR('0),

    .Vsync(vs),
    .Hsync(hs),
    .vgaRed(r),
    .vgaGreen(g),
    .vgaBlue(b),

    .an(),
    .seg(),

    .led()
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


  /**
   * Main test
   */

  integer mine_ctr;

  initial begin
    void'(logger::init());
    mine_ctr = 0;
    InitReset();

    $display("If simulation ends before the testbench");
    $display("completes, use the menu option to run all.");
    $display("Prepare to wait a long time...");

    
    WaitClocks(100_000);
    `check_eq(dut.u_top_vga.main_state, PLAY);
    `check_eq(dut.u_main_fsm.game_setup_mem[MINE_NUM_REG_NUM], M_MINE_NUM);

    for (int i = 0; i < 16; i++)
      for (int j = 0; j < 16; j++)  begin
        $display($sformatf("Check for i=%d, j=%d", i, j));
        `check_eq(dut.u_mine_planter.mine_map[i][j], dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
      end

    for (int i = 0; i < 16; i++)
      for (int j = 0; j < 16; j++)  begin
        $display($sformatf("Check for i=%d, j=%d", i, j));
        `check_eq(dut.u_top_vga.u_draw_board.game_board_mem[i][j], dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j]);
        if(dut.u_top_vga.u_draw_board.game_board_mem[i][j].mine) mine_ctr++;
      end
    `check_eq(mine_ctr, M_MINE_NUM);

    
    wait (vs == 1'b0);

    @(negedge vs) $display("Info: negedge VS at %t",$time);
    @(negedge vs) $display("Info: negedge VS at %t",$time);

    // End the simulation.
    $display("Simulation is over, check the waveforms.");
    $finish;
  end

  task automatic WaitClocks(input int num_of_clock_cycles);
    repeat (num_of_clock_cycles) @(posedge clk);
  endtask

  task automatic InitReset();
    rst = 1;
    WaitClocks(7000);
    rst = 0;
    WaitClocks(100);
  endtask

endmodule

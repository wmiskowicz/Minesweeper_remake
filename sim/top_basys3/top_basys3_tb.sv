//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   top_basys3_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for top module.
 */
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps


`include "../../rtl/memory/wishbone_defs.svh"
`include "../../XVunit/internals/verilog/xvunit_defines.svh"


module top_basys3_tb;

import logger_pkg::*;
import game_pkg::*;


// ----- Local parameters -----
localparam CLK_PERIOD = 10ns;
localparam INTERNAL_CLK_PERIOD = 13ns;


// ----- Local variables -----
logic clk;
logic clk74MHz;
logic rst;

logic [4:0] led;
wire PS2Clk;
wire PS2Data;

wire [2:0] main_state;
wire locked;

assign main_state = led[4:2];
assign locked = led[0];

initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
  clk74MHz = 1'b0;
  forever #(INTERNAL_CLK_PERIOD/2) clk74MHz = ~clk74MHz;
end

top_basys3 dut (
  .clk      (clk),
  .btnD     (rst),
  .PS2Clk   (PS2Clk),
  .PS2Data  (PS2Data),

  .led      (led),
  .Vsync    (Vsync),
  .Hsync    (Hsync),
  .vgaRed   (vgaRed),
  .vgaGreen (vgaGreen),
  .vgaBlue  (vgaBlue),
  .seg      (seg),
  .an       (an),
  .dp       (dp)
);


`TEST_SUITE_BEGIN

    `TEST_SUITE_SETUP begin
      $display("Setting up test suite");
    end

    `TEST_CASE_SETUP begin
      Reset();
      @(posedge locked); // Wait for PLL to lock
    end

    `TEST_CASE("TC000") begin
      $display("Verify reset state");
      MouseLeftClick();
      `CHECK_EQUAL(main_state, MENU);
    end

    `TEST_CASE("BUG1") begin
      int mine_ctr;
      WaitClk74(1000);
      MouseLeftClick();
      `CHECK_EQUAL(main_state, MENU);

      // Go to PLAY
      SelectLevel(2);
      WaitClk74(10);
      `CHECK_EQUAL(main_state, PLAY);
      WaitClk74(10_000);
      `CHECK_EQUAL(dut.planting_complete, 1'b1);
      for (int i = 0; i < 16; i++)
        for (int j = 0; j < 16; j++) begin
          if (dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine) begin
            mine_ctr++;
            $display("mine at %d, %d", i, j);
          end
          `CHECK_EQUAL(dut.u_mine_planter.mine_map[i][j], dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
          `CHECK_EQUAL(dut.u_defuser.game_board_mem[i][j].mine, dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
        end
      mine_ctr = 0;

      // Retry
      PressRetry();
      WaitClk74(10_000);
      `CHECK_EQUAL(dut.planting_complete, 1'b1);

      // Try defusing
      SetMouseInd(M_BOARD_XPOS+100, M_BOARD_YPOS+100);
      MouseLeftClick();
      WaitClk74(20_000);

      `CHECK_EQUAL(dut.game_won, 1'b0);
      $display("AFTER_RESET:");
      for (int i = 0; i < 16; i++)
        for (int j = 0; j < 16; j++) begin
          if (dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine) begin
            mine_ctr++;
            $display("mine at %d, %d", i, j);
          end
          `CHECK_EQUAL(dut.u_mine_planter.mine_map[i][j], dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
          `CHECK_EQUAL(dut.u_defuser.game_board_mem[i][j].mine, dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
          `CHECK_EQUAL(dut.u_top_vga.u_draw_board.game_board_mem[i][j].mine, dut.u_top_memory.u_wishbone_board_mem.board_mem[i][j].mine);
        end

      `CHECK_EQUAL(mine_ctr, M_MINE_NUM);
      end

    
`TEST_SUITE_END


task automatic WaitUntilState(input logic[2:0] current_state, input logic[2:0] target_state);
  while (current_state != target_state) begin
    WaitClk100(1);
  end
endtask

task automatic WaitClk100(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic WaitClk74(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic Reset();
  rst = 1;
  WaitClk100(10);
  rst = 0;
endtask

task automatic MouseLeftClick();
  force dut.left = 1'b1;
  WaitClk74(10);
  release dut.left;
  WaitClk74(10);
endtask

task automatic MouseRightClick();
  force dut.right = 1'b1;
  WaitClk74(10);
  release dut.right;
  WaitClk74(10);
endtask

task SelectLevel(input logic [1:0] level);
  dut.level = level;
endtask


task SetMouseInd(
  input logic [11:0] xpos,
  input logic [11:0] ypos
);
  force dut.mouse_xpos = xpos;
  force dut.mouse_ypos = ypos;
endtask

task PressRetry();
  SetMouseInd(dut.u_defuser.game_setup_cashe[BOARD_XPOS_REG_NUM] + 15'd32 + 10,
   dut.u_defuser.game_setup_cashe[BOARD_YPOS_REG_NUM] - 15'd32 + 10);
   MouseLeftClick();
endtask


endmodule

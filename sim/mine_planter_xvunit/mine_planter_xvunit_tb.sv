//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Mine planter testbench
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for mine planter module.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../../rtl/memory/wishbone_defs.svh"
`include "../../rtl/z_game_setup/mine_planter.svh"
`include "../../XVunit/internals/verilog/xvunit_defines.svh"


module mine_planter_xvunit_tb;

import logger_pkg::*;
import game_pkg::*;

// ----- Local parameters -----
localparam CLK_PERIOD = 14ns;

// ----- Local variables -----
logic clk;
logic rst;

logic [2:0] main_state;
logic retry;
wire planting_complete;



// ----- Signal interfaces -----
wishbone_if game_set_wb();
wishbone_if game_board_wb();


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end



mine_planter dut (
  .clk          (clk),
  .rst          (rst),

  .main_state       (main_state),
  .retry            (retry),
  .planting_complete(planting_complete),

  .game_board_wb(game_board_wb.master),
  .game_set_wb  (game_set_wb.master)
);

always @(posedge clk) begin
  if(game_board_wb.stb_o) game_board_wb.ack_i <= 1'b1;
  else game_board_wb.ack_i <= 1'b0;
end

    
`TEST_SUITE_BEGIN_X 

    `TEST_SUITE_SETUP begin
      $display("Setting up test suite");
      void'(logger::init());
    end

    `TEST_CASE_SETUP begin
      game_board_wb.stall_i = 1'b0;
      game_set_wb.stall_i = 1'b0;
      main_state = MENU;
      retry = 1'b0;

      InitReset();
    end

    `TEST_CASE("TC000") begin
      $display("Verify reset state");
      `CHECK_EQUAL(dut.planter_state, PLANTER_IDLE, "Reset state check failed");
      `CHECK_EQUAL(dut.planting_complete, 1'b0, "Planting complete should be 0 after reset");
    end
    
    `TEST_CASE("TC001") begin  
      $display("Verify that planter transitions from IDLE to READ_SETTINGS when main_state = PLAY");
      main_state = PLAY;
      WaitClocks(2);

      `CHECK_EQUAL(game_set_wb.stb_o, 1'b1, "Settings read should start");
      `CHECK_EQUAL(game_set_wb.we_o, 1'b0, "Should be read operation");

      // Simulate settings read responses
      `CHECK_EQUAL(dut.planter_state, PLANTER_READ_SETTINGS);
      game_set_wb.ack_i = 1'b1;
      game_set_wb.dat_i = M_ROW_COLUMN_NUMBER;
      WaitClocks(1);
      game_set_wb.ack_i = 1'b0;

      WaitClocks(3);
      `CHECK_EQUAL(game_set_wb.stb_o, 1'b1, "Second settings read should start");
      `CHECK_EQUAL(game_set_wb.adr_o, 2, "Should read from address 2");

      game_set_wb.ack_i = 1'b1;
      game_set_wb.dat_i = M_MINE_NUM;
      WaitClocks(1);
      game_set_wb.ack_i = 1'b0;

      wait(dut.mines_left == 0);
    end

    `TEST_CASE("TC002") begin
      $display("Verify transitions");

      main_state = PLAY;
      WaitClocks(2);
      game_set_wb.ack_i = 1'b1;
      game_set_wb.dat_i = M_ROW_COLUMN_NUMBER;
      WaitClocks(1);
      game_set_wb.ack_i = 1'b0;
      WaitClocks(3);
      game_set_wb.ack_i = 1'b1;
      game_set_wb.dat_i = M_MINE_NUM;
      WaitClocks(1);
      game_set_wb.ack_i = 1'b0;

      WaitClocks(1);
      `CHECK_EQUAL(dut.planter_state, PLANTER_PLANT);
      wait(dut.mines_left == 0);
      WaitClocks(100);
      `CHECK_EQUAL(dut.planter_state, PLANTER_WRITE_BOARD, "Should transition to WRITE_BOARD after planting");

      // Verify board write operations
      while (dut.planter_state == PLANTER_WRITE_BOARD) begin
        if (game_board_wb.stb_o && game_board_wb.we_o) begin
          game_board_wb.ack_i = 1'b1;
          WaitClocks(1);
          game_board_wb.ack_i = 1'b0;
        end
        WaitClocks(1);
      end

      WaitClocks(50);
      `CHECK_EQUAL(dut.planter_state, PLANTER_DONE,
        "Should transition to DONE after board write");
      `CHECK_EQUAL(planting_complete, 1'b1, "Planting complete flag not set");
    end

    `TEST_CASE("TC003") begin
      $display("Verify that planter transitions from DONE to IDLE when retry input is being asserted.");

      main_state = PLAY;
      dut.planter_state = PLANTER_DONE;
      WaitClocks(5);
      retry = 1'b1;
      WaitClocks(1);
      retry = 1'b0;

      `CHECK_EQUAL(dut.planter_state, PLANTER_IDLE, "Should return to IDLE on game over");

      WaitClocks(1);
      `CHECK_EQUAL(dut.planter_state, PLANTER_READ_SETTINGS);
    end
    
`TEST_SUITE_END_X

task automatic WaitClocks(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks(10);
  rst = 0;
endtask

endmodule

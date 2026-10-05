//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Testbench for the main FSM.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../../rtl/memory/wishbone_defs.svh"
`include "../../XVunit/internals/verilog/xvunit_defines.svh"
module main_fsm_xvunit_tb;

import game_pkg::*;


// ----- Local parameters -----
localparam CLK_PERIOD = 10ns;
localparam BANNER_CYCLES_TEST = 100;

localparam NUMBER_OF_REGISTERS = 9;

localparam ROW_COLUMN_NUMBER_ADDR = 8'h00;
localparam MINE_NUM_ADDR          = 8'h02;
localparam TIMER_SECONDS_ADDR     = 8'h04;
localparam FIELD_SIZE_ADDR        = 8'h08;
localparam BOARD_SIZE_ADDR        = 8'h0A;
localparam BOARD_XPOS_ADDR        = 8'h0C;
localparam BOARD_YPOS_ADDR        = 8'h0E;
localparam GAMES_WON_ADDR         = 8'h10;
localparam GAMES_LOST_ADDR        = 8'h12;

localparam ROW_COLUMN_NUMBER_REG_NUM = 0;
localparam MINE_NUM_REG_NUM          = 1;
localparam TIMER_SECONDS_REG_NUM     = 2;
localparam FIELD_SIZE_REG_NUM        = 3;
localparam BOARD_SIZE_REG_NUM        = 4;
localparam BOARD_XPOS_REG_NUM        = 5;
localparam BOARD_YPOS_REG_NUM        = 6;
localparam GAMES_WON_REG_NUM         = 7;
localparam GAMES_LOST_REG_NUM        = 8;

// ----- Local variables -----
logic clk;
logic rst;

reg [1:0] level;
reg pause;
reg game_won;
reg game_lost;
reg retry;
wire seconds_left;
wire time_elapsed;

logic left;
logic right;
logic back_to_menu;
logic [2:0] main_state;


// ----- Signal interfaces -----
wishbone_if game_set1_if();
wishbone_if game_set2_if();
wishbone_if game_set3_if();



main_fsm #(
  .BANNER_DISP_CYC(BANNER_CYCLES_TEST)
) 
dut (
  .clk       (clk),
  .rst       (rst),
  .level     (level),

  .left      (left),
  .right     (right),

  .game_lost   (game_lost),
  .game_won    (game_won),
  .back_to_menu(back_to_menu),
  .retry       (retry),

  .timer_stop   (pause),
  .seconds_left (seconds_left),
  .time_elapsed (time_elapsed),

  .state_out    (main_state),

  .game_set_wb1 (game_set1_if.slave),
  .game_set_wb2 (game_set2_if.slave),
  .game_set_wb3 (game_set3_if.slave)
);

initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

`TEST_SUITE_BEGIN 

    `TEST_SUITE_SETUP begin
      $display("Setting up test suite");
    end

    `TEST_CASE_SETUP begin
      left = 1'b0;
      right = 1'b0;
      retry = 1'b0;
      pause = 1'b0;
      game_won = 1'b0;
      game_lost = 1'b0;
      back_to_menu = 1'b0;

      game_set1_if.stall_i = 1'b0;
      game_set2_if.stall_i = 1'b0;
      game_set3_if.stall_i = 1'b0;

      Reset();
    end

    `TEST_CASE("TC000") begin
      $display("Verify reset state");
      `CHECK_EQUAL(main_state, BANNER, "Reset state should be MENU");
      `CHECK_EQUAL(dut.game_setup_mem[MINE_NUM_REG_NUM], 0, "Mine count should be 0 after reset");
      `CHECK_EQUAL(dut.game_setup_mem[GAMES_WON_REG_NUM], 0, "Games won should be 0 after reset");
    end

    `TEST_CASE("TC001") begin
      $display("Verify that main_fsm transitions from BANNER to MENU after left or right mouse click");
      $display("or after BANNER_CYCLES_TEST clock BANNER_CYCLES_TEST");
      
      WaitClocks(40);
      `CHECK_EQUAL(main_state, BANNER);
      MouseLeftClick();
      `CHECK_EQUAL(main_state, MENU);

      Reset();

      WaitClocks(40);
      `CHECK_EQUAL(main_state, BANNER);
      MouseRightClick();
      `CHECK_EQUAL(main_state, MENU);   
      
      Reset();
      `CHECK_EQUAL(main_state, BANNER);
      WaitClocks(BANNER_CYCLES_TEST);
      `CHECK_EQUAL(main_state, MENU);
    end

    `TEST_CASE("TC002") begin
      $display("Verify that main_fsm transitions from MENU to PLAY when level input is greater than 0");
      $display("Verify that main_fsm populates settings register with EASY, MEDIUM and HARD data when level");
      $display("input is equal respectively to 1, 2 or 3");
      
      MouseLeftClick();
      level = 2'd1;
      WaitClocks(2);
      level = 0;

      `CHECK_EQUAL(main_state, PLAY);
      `CHECK_EQUAL(dut.game_setup_mem[MINE_NUM_REG_NUM], E_MINE_NUM);
      `CHECK_EQUAL(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], E_TIMER_SECONDS);
      Reset();

      MouseLeftClick();
      level = 2'd2;
      WaitClocks(2);
      level = 0;

      `CHECK_EQUAL(main_state, PLAY);
      `CHECK_EQUAL(dut.game_setup_mem[MINE_NUM_REG_NUM], M_MINE_NUM);
      `CHECK_EQUAL(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], M_TIMER_SECONDS);
      Reset();

      MouseLeftClick();
      level = 2'd3;
      WaitClocks(2);
      level = 0;

      `CHECK_EQUAL(main_state, PLAY);
      `CHECK_EQUAL(dut.game_setup_mem[MINE_NUM_REG_NUM], H_MINE_NUM);
      `CHECK_EQUAL(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], H_TIMER_SECONDS);
    end

    `TEST_CASE("TC003") begin
      $display("Verify that main_fsm transitions from MENU to PAUSE when pause input is asserted.");
      
      MouseLeftClick();
      level = 2'd3;
      WaitClocks(2);
      level = 0;


      pause = 1'b1;
      WaitClocks(2);
      `CHECK_EQUAL(main_state, PAUSE);
      WaitClocks(100);
      pause = 1'b0;
      WaitClocks(2);
      `CHECK_EQUAL(main_state, PLAY);
    end

    `TEST_CASE("TC004") begin
      $display("Verify that main_fsm transitions from PLAY to GAME_OVER when game_won or game_lost inputs are being asserted.");
      $display("Verify that main_fsm transitions from PLAY to MENU when back_to_menu input is asserted.");

      MouseLeftClick();
      level = 2'd3;
      WaitClocks(2);
      level = 0;
      WaitClocks(100);

      game_won = 1'b1;
      WaitClocks(1);
      game_won = 1'b0;
      WaitClocks(5);
      `CHECK_EQUAL(main_state, GAME_OVER);
      `CHECK_EQUAL(dut.game_setup_mem[GAMES_WON_REG_NUM], 1);

      back_to_menu = 1'b1;
      WaitClocks(1);
      back_to_menu = 1'b0;
      WaitClocks(1);

      `CHECK_EQUAL(main_state, MENU);
      level = 2'd3;
      WaitClocks(2);
      level = 0;
      WaitClocks(100);

      game_lost = 1'b1;
      WaitClocks(1);
      game_lost = 1'b0;
      WaitClocks(5);
      `CHECK_EQUAL(main_state, GAME_OVER);
      `CHECK_EQUAL(dut.game_setup_mem[GAMES_LOST_REG_NUM], 1);
      `CHECK_EQUAL(dut.game_setup_mem[MINE_NUM_REG_NUM], H_MINE_NUM);
    end

    `TEST_CASE("TC005") begin
      $display("Verify that main_fsm transitions from MENU to PAUSE when pause input is asserted.");
      
      MouseLeftClick();
      level = 2'd3;
      WaitClocks(2);
      level = 0;
      WaitClocks(10);

      game_lost = 1'b1;
      WaitClocks(1);
      game_lost = 1'b0;
      WaitClocks(10);

      `CHECK_EQUAL(main_state, GAME_OVER);
      retry = 1'b1;
      WaitClocks(2);
      retry = 1'b0;
      WaitClocks(2);
      `CHECK_EQUAL(main_state, PLAY);
    end
    
`TEST_SUITE_END


task automatic WaitClocks(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic Reset();
  rst = 1'b1;
  WaitClocks(10);
  rst = 1'b0;
  WaitClocks(10);
endtask

task automatic MouseLeftClick();
  left = 1'b1;
  WaitClocks(10);
  left = 1'b0;
  WaitClocks(10);
endtask

task automatic MouseRightClick();
  right = 1'b1;
  WaitClocks(10);
  right = 1'b0;
  WaitClocks(10);
endtask

endmodule

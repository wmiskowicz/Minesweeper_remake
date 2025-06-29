//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Testbench for the main FSM.
 */
//////////////////////////////////////////////////////////////////////////////

module main_fsm_tb;

import logger_pkg::*;
import game_pkg::*;


// ----- Local parameters -----
localparam CLK_PERIOD = 10ns;

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
reg timer_stop;
reg game_won;
reg game_lost;
reg retry;

logic [2:0] state;


// ----- Signal interfaces -----
wishbone_if game_set1_if();
wishbone_if game_set2_if();
wishbone_if game_set3_if();



main_fsm #(
  .BANNER_DISP_US(10)
)dut (
  .clk(clk),
  .rst(rst),

  .level      (level),
  .timer_stop (timer_stop),
  .game_won   (game_won),
  .game_lost  (game_lost),
  .retry      (retry),

  .game_set_wb1 (game_set1_if.slave),
  .game_set_wb2 (game_set2_if.slave),
  .game_set_wb3 (game_set3_if.slave),
  .state_out    (state)
);

initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

// initial begin
//   void'(logger::init());
//   game_set1_if.stall_i = 1'b0;
//   game_set2_if.stall_i = 1'b0;
//   game_set3_if.stall_i = 1'b0;
//   InitReset();
  
//   `log_info("Starting main_fsm testbench");
  
//   // Test 1: Verify reset state
//   `check_eq(state, MENU, "Reset state should be MENU");
//   `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], 0, "Mine count should be 0 after reset");
//   `check_eq(dut.game_setup_mem[GAMES_WON_REG_NUM], 0, "Games won should be 0 after reset");
  
//   // Test 2: Level selection and game setup
//   level = 2; // Medium level
//   WaitClocks(2);
//   level = 0;
  
//   `check_eq(state, PLAY, "Should transition to PLAY state");
//   `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], M_MINE_NUM, 
//            "Medium level mine count not set");
//   `check_eq(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], M_TIMER_SECONDS,
//            "Medium level timer not set");
  
//   // Test 3: Wishbone read operations
//   game_set1_if.cyc_o = 1'b1;
//   game_set1_if.stb_o = 1'b1;
//   game_set1_if.adr_o = TIMER_SECONDS_ADDR;
//   game_set1_if.we_o = 1'b0;
//   WaitClocks(2);
  
//   `check_eq(game_set1_if.dat_i, M_TIMER_SECONDS, 
//            "Incorrect timer value read via Wishbone");
  
//   // Test 4: Game pause/resume
//   timer_stop = 1'b1;
//   WaitClocks(2);
//   `check_eq(state, PAUSE, "Should pause when timer_stop=1");
  
//   timer_stop = 1'b0;
//   WaitClocks(2);
//   `check_eq(state, PLAY, "Should resume when timer_stop=0");
  
//   // Test 5: Game win scenario
//   game_won = 1'b1;
//   WaitClocks(4);
//   game_won = 1'b0;
  
//   `check_eq(state, GAME_OVER, "Should transition to GAME_OVER on win");
//   `check_eq(dut.game_setup_mem[GAMES_WON_REG_NUM], 1, 
//            "Games won counter not incremented");
  
//   // Test 6: Retry functionality
//   retry = 1'b1;
//   WaitClocks(2);
//   retry = 1'b0;
  
//   `check_eq(state, MENU);
//   `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], 0,
//            "Game setup should be cleared on return to menu");
  
//   // Test 7: Game loss scenario
//   level = 2; // Medium level again
//   WaitClocks(2);
//   level = 0;
//   game_lost = 1'b1;
//   WaitClocks(4);
//   game_lost = 1'b0;
  
//   `check_eq(state, GAME_OVER, "Should transition to GAME_OVER on loss");
//   `check_eq(dut.game_setup_mem[GAMES_LOST_REG_NUM], 1);
  
//   // Test 8: All level configurations
//   retry = 1'b1;
//   WaitClocks(2);
  
//   level = 1; 
//   WaitClocks(2);
//   level = 0;
//   `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], E_MINE_NUM, 
//            "Easy level mine count not set");
  
//   retry = 1'b1;
//   WaitClocks(2);
  
//   level = 3;
//   WaitClocks(2);
//   level = 0;
//   `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], H_MINE_NUM);
  
//   // Test 9: Reset during game
//   retry = 1'b1;
//   WaitClocks(2);
//   level = 2;
//   WaitClocks(2);
//   rst = 1'b1;
//   WaitClocks(1);
//   rst = 1'b0;
  
//   `check_eq(state, MENU, "Reset should return to MENU");
//   `check_eq(dut.game_setup_mem[GAMES_WON_REG_NUM], 0,
//            "Reset should clear game stats");
  
//   `log_info("All main_fsm tests completed successfully");
//   $finish();
// end

initial begin
  void'(logger::init());
  game_set1_if.stall_i = 1'b0;
  game_set2_if.stall_i = 1'b0;
  game_set3_if.stall_i = 1'b0;
  InitReset();
  `check_eq(state, BANNER);
  WaitClocks(1000);
  `check_eq(state, MENU);
  WaitClocks(200);
  InitReset();
  WaitClocks(5);
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

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   main_fsm_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Testbench for the main FSM. 
 */
//////////////////////////////////////////////////////////////////////////////

module main_fsm_tb;
  reg clk;
  reg rst;
  reg [1:0] level;
  reg timer_stop;
  reg game_won;
  reg game_lost;
  reg retry;

  import logger_pkg::*;
  import game_pkg::*;

  localparam CLK_PERIOD = 11;     // 40 MHz


  main_fsm dut (
    .clk(clk),
    .rst(rst),
    .level(level),
    .timer_stop(timer_stop),
    .game_won(game_won),
    .game_lost(game_lost),
    .retry(retry)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  initial begin
    void'(logger::init());
    InitReset();
    level = 0;
    timer_stop = 0;
    game_won = 0;
    game_lost = 0;
    retry = 0;

    level = 2;
    WaitClocks(2);
    level = 0;
    `check_eq(dut.game_setup_mem.mine_number, M_MINE_NUM);
    `check_eq(dut.game_setup_mem.timer_seconds, M_TIMER_SECONDS);
    game_won = 1;
    WaitClocks(2);

    `check_eq(dut.state, GAME_OVER);
    `check_eq(dut.game_setup_mem.games_won, 1);
    retry = 1;
    WaitClocks(2);

    retry = 0;
    `check_eq(dut.state, MENU);
    `check_eq(dut.game_setup_mem.mine_number, 0);
    `check_eq(dut.game_setup_mem.timer_seconds, 0);
    
    rst = 1'b1;
    WaitClocks(1);
    rst = 1'b0;
    WaitClocks(1);
    `check_eq(dut.game_setup_mem.mine_number, 0);
    `check_eq(dut.game_setup_mem.timer_seconds, 0);
    `check_eq(dut.game_setup_mem.games_won, 0);

    WaitClocks(100);
    $finish;
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
  
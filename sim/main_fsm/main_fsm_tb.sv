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

  logic [2:0] state;

  wishbone_if game_set_if();

  import logger_pkg::*;
  import game_pkg::*;

  localparam CLK_PERIOD = 25ns;     // 40 MHz

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


  main_fsm dut (
    .clk(clk),
    .rst(rst),

    .level(level),
    .timer_stop(timer_stop),
    .game_won(game_won),
    .game_lost(game_lost),
    .retry(retry),

    .game_settings(game_set_if.slave),
    .state_out(state)
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
    `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], 0);
    `check_eq(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], 0);
    `check_eq(dut.game_setup_mem[GAMES_LOST_REG_NUM], 0);

    WaitClocks(2);
    level = 0;
    `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], M_MINE_NUM);
    `check_eq(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], M_TIMER_SECONDS);

    WaitClocks(20);
    game_set_if.cyc_o = 1'b1;
    game_set_if.stb_o = 1'b1;
    game_set_if.adr_o = TIMER_SECONDS_ADDR;
    game_set_if.we_o  = 1'b0;
    WaitClocks(2);
    `check_eq(game_set_if.dat_i, M_TIMER_SECONDS);

    game_won = 1;
    WaitClocks(2);

    `check_eq(dut.state, GAME_OVER);
    `check_eq(dut.game_setup_mem[GAMES_WON_REG_NUM], 1);
    retry = 1;
    WaitClocks(2);

    retry = 0;
    `check_eq(dut.state, MENU);
    `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], 0);
    `check_eq(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], 0);
    
    rst = 1'b1;
    WaitClocks(1);
    rst = 1'b0;
    WaitClocks(1);
    `check_eq(dut.game_setup_mem[MINE_NUM_REG_NUM], 0);
    `check_eq(dut.game_setup_mem[TIMER_SECONDS_REG_NUM], 0);
    `check_eq(dut.game_setup_mem[GAMES_WON_REG_NUM], 0);




    WaitClocks(50);
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
  
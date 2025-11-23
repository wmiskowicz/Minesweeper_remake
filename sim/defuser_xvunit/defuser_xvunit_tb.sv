//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   defuser_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for module defuser.
 */
//////////////////////////////////////////////////////////////////////////////

`include "../../rtl/memory/wishbone_defs.svh"
`include "../../rtl/z_game_setup/defuser.svh"
`include "../../XVunit/internals/verilog/xvunit_defines.svh"


module defuser_xvunit_tb;

import logger_pkg::*;
import game_pkg::*;


// ----- Local parameters -----
localparam CLK_PERIOD = 11ns;


// ----- Local variables -----
logic clk;
logic rst;

logic planting_complete;
logic [11:0] mouse_xpos;
logic [11:0] mouse_ypos;
logic left;
logic right;

wire game_lost;
logic retry;
logic [1:0] level;
wire back_to_menu;
logic pause;
logic [2:0] main_state;


// ----- Signal interfaces -----
wishbone_if defuser_game_set_wb();
wishbone_if defuser_game_board_wb();

wishbone_if game_set_wb2();
wishbone_if game_set_wb3();


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

defuser dut (
  .clk              (clk),
  .rst              (rst),
  .retry            (retry),
  .back_to_menu     (back_to_menu),
  .pause            (pause),
  .planting_complete(planting_complete),
  .main_state       (main_state),

  .mouse_xpos       (mouse_xpos),
  .mouse_ypos       (mouse_ypos),

  .game_lost        (game_lost),
  .game_won         (),

  .left             (left),
  .right            (right),

  .game_set_wb      (defuser_game_set_wb.master),
  .game_board_wb    (defuser_game_board_wb.master)
);


wishbone_board_mem #(
  .BOARD_SIZE(16)
)
u_wishbone_board_mem (
  .clk  (clk),
  .rst  (rst),
  .slave(defuser_game_board_wb.slave)
);


main_fsm u_main_fsm (
  .clk         (clk),
  .rst         (rst),

  .back_to_menu(back_to_menu),
  .level       (level),
  .left        (left),
  .right       (right),
  .retry       (retry),
  .state_out   (main_state),
  .timer_stop  ('0),


  .game_won    (1'b0),
  .game_lost   (game_lost),
  .seconds_left(),
  .time_elapsed(),

  .game_set_wb1(defuser_game_set_wb.slave),
  .game_set_wb2(game_set_wb2.slave),
  .game_set_wb3(game_set_wb3.slave)
);


`TEST_SUITE_BEGIN_X 

    `TEST_SUITE_SETUP begin
      $display("Setting up test suite");
    end

    `TEST_CASE_SETUP begin
      planting_complete = 1'b0;
      mouse_xpos = 12'd0;
      mouse_ypos = 12'd0;
      left = 1'b0;
      right = 1'b0;
      retry = 1'b0;
      pause = 1'b0;
      level = 2'd2; // constant medium level

      defuser_game_set_wb.stall_i = 1'b0;
      defuser_game_board_wb.stall_i = 1'b0;
      game_set_wb2.stall_i = 1'b0;
      game_set_wb3.stall_i = 1'b0;
      Reset();
    end

    `TEST_CASE("TC000") begin
      $display("Verify reset state");
      `CHECK_EQUAL(dut.defuser_state, DEF_IDLE);
      `CHECK_EQUAL(dut.auto_write_state, AW_WAIT);
      `CHECK_EQUAL(dut.auto_read_state, AR_IDLE);
      `CHECK_EQUAL(dut.board_ready, 1'b0);
    end

    `TEST_CASE("TC001") begin
      $display("Verify that defuser transitions from IDLE to READ_BOARD when main_state");
      $display("main_state is equal to PLAY and planting_complete input is asserted");

      `CHECK_EQUAL(dut.defuser_state, DEF_IDLE);
      MouseLeftClick();
      WaitClocks(10);
      `CHECK_EQUAL(main_state, PLAY);

      planting_complete = 1'b1;
      WaitClocks(2);
      `CHECK_EQUAL(dut.defuser_state, DEF_READ_BOARD);
    end

    
    `TEST_CASE("TC002") begin
      $display("Verify that data in wishbone memory is populated");
      $display("to internal settings and game_board memory.");

      u_wishbone_board_mem.board_mem[0][0].mine = 1'b1;
      u_wishbone_board_mem.board_mem[3][3].mine = 1'b1;
      u_wishbone_board_mem.board_mem[5][5].mine = 1'b1;

      // Put into READ_BOARD_STATE
      MouseLeftClick();
      WaitClocks(10);
      planting_complete = 1'b1;
      WaitClocks(2);
      wait(dut.board_ready == 1'b1);

      `CHECK_EQUAL(dut.game_board_mem[0][0].mine, 1'b1);
      `CHECK_EQUAL(dut.game_board_mem[3][3].mine, 1'b1);
      `CHECK_EQUAL(dut.game_board_mem[5][5].mine, 1'b1);
      `CHECK_EQUAL(dut.game_board_mem[4][4].mine, 1'b0);
      `CHECK_EQUAL(dut.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM], M_ROW_COLUMN_NUMBER);
      `CHECK_EQUAL(dut.game_setup_cashe[BOARD_XPOS_REG_NUM], M_BOARD_XPOS);

    end


`TEST_SUITE_END_X

initial begin
  void'(logger::init());
  
  // Initialize all signals
  planting_complete = 1'b0;
  mouse_xpos = 12'd0;
  mouse_ypos = 12'd0;
  left = 1'b0;
  right = 1'b0;
  retry = 1'b0;
  level = 2'd2; // Medium level
  
  // Initialize wishbone interfaces
  defuser_game_set_wb.stall_i = 1'b0;
  defuser_game_board_wb.stall_i = 1'b0;
  game_set_wb2.stall_i = 1'b0;
  game_set_wb3.stall_i = 1'b0;
  
  Reset();
  
  
  // Initialize test mines
  u_wishbone_board_mem.board_mem[0][0].mine = 1'b1;
  u_wishbone_board_mem.board_mem[5][5].mine = 1'b1;

  
  // Test 2: Settings cache loading
  planting_complete = 1'b1;
  WaitClocks(1);
  planting_complete = 1'b0;
  
  `check_eq(dut.auto_read_state, AR_READ_SETTINGS, "Should be reading settings");

  MouseLeftClick();


  wait(dut.defuser_state == DEF_WAIT_FOR_MOUSE);
  WaitClocks(50);
  mouse_xpos = M_BOARD_XPOS + 1;
  mouse_ypos = M_BOARD_YPOS + 1;
  MouseLeftClick();

  WaitClocks(100);
  `check_eq(game_lost, 1'b1);
  `check_eq(main_state, GAME_OVER);

  retry = 1'b1;
  level = 2'd1;
  mouse_xpos = E_BOARD_XPOS + 1;
  mouse_ypos = E_BOARD_YPOS + 1;
  WaitClocks(1);
  retry = 1'b0;
  WaitClocks(200); 
  planting_complete = 1'b1;
  WaitClocks(1);
  planting_complete = 1'b0;


  wait(dut.defuser_state == DEF_WAIT_FOR_MOUSE);
  // for (int i = 0; i < 16; i++)
  //   for (int j = 0; j < 16; j++)
  //     if (!(i == 0 && j == 0 || i == 1 && j == 1))
  //       dut.game_board_mem[i][j].defused = 1'b1;

  WaitClocks(10);
  mouse_xpos = E_BOARD_XPOS + 1;
  mouse_ypos = E_BOARD_YPOS + 1;
  MouseRightClick();
  WaitClocks(500);
  `check_eq(dut.game_won, 1'b0);
  mouse_xpos = E_BOARD_XPOS + (E_FIELD_SIZE * 5) + 1;
  mouse_ypos = E_BOARD_YPOS + (E_FIELD_SIZE * 5) + 1;
  WaitClocks(10);
  MouseRightClick();
  WaitClocks(500);
  wait(dut.defuser_state == DEF_WAIT_FOR_MOUSE);
  mouse_xpos = E_BOARD_XPOS + (E_FIELD_SIZE * 2) + 1;
  mouse_ypos = E_BOARD_YPOS + (E_FIELD_SIZE * 2) + 1;
  MouseLeftClick();
  WaitClocks(500);

  
  `check_eq(dut.game_won, 1'b1);


  $finish();
end

task automatic WaitUntilState(input logic[2:0] current_state, input logic[2:0] target_state);
  while (current_state != target_state) begin
    WaitClocks(1);
  end
endtask

task automatic WaitClocks(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic Reset();
  rst = 1;
  WaitClocks(10);
  rst = 0;
endtask

task automatic MouseLeftClick();
  begin
    left = 1'b1;
    WaitClocks(10);
    left = 1'b0;
    WaitClocks(10);
  end
endtask

task automatic MouseRightClick();
  begin
    right = 1'b1;
    WaitClocks(10);
    right = 1'b0;
    WaitClocks(10);
  end
endtask

endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   defuser_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for module defuser.
 */
//////////////////////////////////////////////////////////////////////////////

`include "../../rtl/memory/wishbone_defs.svh"
`include "../../rtl/z_game_setup/defuser.svh"

module defuser_tb;

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
  
  InitReset();
  
  `log_info("Starting defuser module testbench");
  
  // Test 1: Verify reset state
  `check_eq(dut.defuser_state, DEF_IDLE, "Reset state should be DEF_IDLE");
  `check_eq(dut.board_ready, 1'b0, "Board should not be ready after reset");
  
  // Initialize test mines
  u_wishbone_board_mem.board_mem[0][0].mine = 1'b1;
  u_wishbone_board_mem.board_mem[5][5].mine = 1'b1;

  
  // Test 2: Settings cache loading
  planting_complete = 1'b1;
  WaitClocks(1);
  planting_complete = 1'b0;
  
  `check_eq(dut.auto_read_state, AR_READ_SETTINGS, "Should be reading settings");

  click_left_mouse();


  wait(dut.defuser_state == DEF_WAIT_FOR_MOUSE);
  WaitClocks(50);
  mouse_xpos = M_BOARD_XPOS + 1;
  mouse_ypos = M_BOARD_YPOS + 1;
  click_left_mouse();

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
  mouse_xpos = E_BOARD_XPOS + (E_FIELD_SIZE * 2) + 1;
  mouse_ypos = E_BOARD_YPOS + (E_FIELD_SIZE * 2) + 1;
  click_left_mouse();
  wait(dut.defuser_state == DEF_WAIT_FOR_MOUSE);
  // for (int i = 0; i < 16; i++)
  //   for (int j = 0; j < 16; j++)
  //     if (!(i == 0 && j == 0 || i == 1 && j == 1))
  //       dut.game_board_mem[i][j].defused = 1'b1;

  WaitClocks(10);
  mouse_xpos = E_BOARD_XPOS + 1;
  mouse_ypos = E_BOARD_YPOS + 1;
  click_right_mouse();
  WaitClocks(500);
  `check_eq(dut.game_won, 1'b0);
  mouse_xpos = E_BOARD_XPOS + (E_FIELD_SIZE * 5) + 1;
  mouse_ypos = E_BOARD_YPOS + (E_FIELD_SIZE * 5) + 1;
  WaitClocks(10);
  click_right_mouse();
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

task automatic InitReset();
  rst = 1;
  WaitClocks(10);
  rst = 0;
endtask

task automatic click_left_mouse();
  begin
    left = 1'b1;
    WaitClocks(10);
    left = 1'b0;
    WaitClocks(10);
  end
endtask

task automatic click_right_mouse();
  begin
    right = 1'b1;
    WaitClocks(10);
    right = 1'b0;
    WaitClocks(10);
  end
endtask

endmodule

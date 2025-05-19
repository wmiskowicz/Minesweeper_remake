//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Mine planter testbench
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for mine planter module.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../../rtl/memory/wishbone_defs.svh"
`include "../../rtl/z_game_setup/mine_planter.svh"

module mine_planter_tb;

import logger_pkg::*;
import game_pkg::*;

// ----- Local parameters -----
localparam CLK_PERIOD = 14ns;

// ----- Local variables -----
logic clk;
logic rst;

logic [2:0] main_state;
wire planting_complete;

int write_count;


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
  .planting_complete(planting_complete),

  .game_board_wb(game_board_wb.master),
  .game_set_wb  (game_set_wb.master)
);

always @(posedge clk) begin
  if(game_board_wb.stb_o) game_board_wb.ack_i <= 1'b1;
  else game_board_wb.ack_i <= 1'b0;
end

initial begin
  void'(logger::init());
  game_board_wb.stall_i = 1'b0;
  game_set_wb.stall_i = 1'b0;
  write_count = 0;

  InitReset();

  `log_info("Starting mine_planter testbench");

  // Test 1: Verify reset state
  `check_eq(dut.planter_state, PLANTER_IDLE, "Reset state check failed");
  `check_eq(dut.planting_complete, 1'b0, "Planting complete should be 0 after reset");

  // Test 2: Basic state transition test
  main_state = PLAY;
  WaitClocks(2);

  `check_eq(game_set_wb.stb_o, 1'b1, "Settings read should start");
  `check_eq(game_set_wb.we_o, 1'b0, "Should be read operation");

  // Simulate settings read responses
  game_set_wb.ack_i = 1'b1;
  game_set_wb.dat_i = M_ROW_COLUMN_NUMBER;
  WaitClocks(1);
  game_set_wb.ack_i = 1'b0;

  WaitClocks(3);
  `check_eq(game_set_wb.stb_o, 1'b1, "Second settings read should start");
  `check_eq(game_set_wb.adr_o, 2, "Should read from address 2");

  game_set_wb.ack_i = 1'b1;
  game_set_wb.dat_i = M_MINE_NUM;
  WaitClocks(1);
  game_set_wb.ack_i = 1'b0;

  wait(dut.mines_left == 0);

  // Test 3: Mine planting phase
  WaitClocks(100);
  `check_eq(dut.planter_state, PLANTER_WRITE_BOARD,
    "Should transition to WRITE_BOARD after planting");

  // Verify board write operations
  while (dut.planter_state == PLANTER_WRITE_BOARD) begin
    if (game_board_wb.stb_o && game_board_wb.we_o) begin
      write_count++;
      game_board_wb.ack_i = 1'b1;
      WaitClocks(1);
      game_board_wb.ack_i = 1'b0;
    end
    WaitClocks(1);
  end

  WaitClocks(50);
  `check_eq(dut.planter_state, PLANTER_DONE,
    "Should transition to DONE after board write");
  `check_eq(planting_complete, 1'b1, "Planting complete flag not set");

  // Test 4: Return to IDLE on game over
  main_state = GAME_OVER;
  WaitClocks(5);
  `check_eq(dut.planter_state, PLANTER_IDLE,
    "Should return to IDLE on game over");

  `log_info("All tests completed successfully");
  $finish();
end

task automatic WaitClocks(input int num_of_clock_cycles);
  repeat (num_of_clock_cycles) @(posedge clk);
endtask

task automatic InitReset();
  rst = 1;
  WaitClocks(10);
  rst = 0;
endtask

endmodule

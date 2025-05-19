//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   vga_out_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for module vga_out.
 */
//////////////////////////////////////////////////////////////////////////////

`include "../../rtl/memory/wishbone_defs.svh"
`include "../../rtl/z_game_setup/defuser.svh"

module defuser_tb;

import logger_pkg::*;
import game_pkg::*;


// ----- Local parameters -----
localparam SETTINGS_REG_NUM = 7;
localparam CLK_PERIOD = 11ns;


// ----- Local variables -----
logic clk;
logic rst;

logic planting_complete;
logic [11:0] mouse_xpos;
logic [11:0] mouse_ypos;
logic left;
logic right;

logic [2:0] main_state;

reg [15:0] settings_mem [0:SETTINGS_REG_NUM-1];
field_t  board_mem    [15:0][15:0];


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

  .planting_complete(planting_complete),
  .main_state       (main_state),

  .mouse_xpos       (mouse_xpos),
  .mouse_ypos       (mouse_ypos),

  .game_lost        (),
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

  .level       (2),
  .retry       ('0),
  .state_out   (main_state),
  .timer_stop  ('0),


  .game_won    (1'b0),
  .game_lost   (1'b0),

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
  u_wishbone_board_mem.board_mem[1][1].mine = 1'b1;
  u_wishbone_board_mem.board_mem[1][2].mine = 1'b1;
  u_wishbone_board_mem.board_mem[1][3].mine = 1'b1;
  u_wishbone_board_mem.board_mem[5][5].mine = 1'b1;
  
  // Test 2: Settings cache loading
  planting_complete = 1'b1;
  WaitClocks(1);
  planting_complete = 1'b0;
  
  `check_eq(dut.auto_read_state, AR_READ_SETTINGS, "Should be reading settings");
  // // wait(dut.game_read_en == 1'b1);

  // // `check_eq(dut.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM], M_ROW_COLUMN_NUMBER, 
  // //          "Row/column number not cached correctly");
  // // `check_eq(dut.game_setup_cashe[MINE_NUM_REG_NUM], M_MINE_NUM,
  // //          "Mine number not cached correctly");
  
  // // Test 3: Board reading state
  // // `check_eq(dut.game_burst_read, 1'b1, "Board read burst should be active");
  
  // // Test 4: Board ready state
  // WaitUntilState(dut.auto_read_state, AR_DONE);
  // `check_eq(dut.board_ready, 1'b1, "Board should be ready after reading");
  
  // // Test 5: Mine indication calculation
  // WaitUntilState(dut.defuser_state, DEF_WRITE_MINE_IND);
  // WaitClocks(50); // Allow time for mine indication calculation
  
  // // Verify mine indications
  // `check_eq(u_wishbone_board_mem.board_mem[0][0].mine_ind, 0, "Empty corner should have 0 mines");
  // `check_eq(u_wishbone_board_mem.board_mem[0][1].mine_ind, 1, "Adjacent to one mine");
  // `check_eq(u_wishbone_board_mem.board_mem[0][2].mine_ind, 2, "Adjacent to two mines");
  // `check_eq(u_wishbone_board_mem.board_mem[0][3].mine_ind, 1, "Adjacent to one mine");
  // `check_eq(u_wishbone_board_mem.board_mem[2][2].mine_ind, 3, "Adjacent to three mines");
  
  // // Test 6: Left click on safe field
  // WaitUntilState(dut.defuser_state, DEF_WAIT_FOR_MOUSE);
  // mouse_xpos = M_BOARD_XPOS + M_FIELD_SIZE/2;
  // mouse_ypos = M_BOARD_YPOS + M_FIELD_SIZE/2;
  // left = 1'b1;
  // WaitClocks(2);
  // left = 1'b0;
  
  // `check_eq(u_wishbone_board_mem.board_mem[0][0].defused, 1'b1, "Field should be defused");
  // `check_eq(dut.game_lost, 1'b0, "Game should not be lost on safe field");
  
  // // Test 7: Left click on mine
  // mouse_xpos = M_BOARD_XPOS + M_FIELD_SIZE + M_FIELD_SIZE/2; // Position over [1][1] mine
  // left = 1'b1;
  // WaitClocks(2);
  // left = 1'b0;
  
  // `check_eq(dut.game_lost, 1'b1, "Game should be lost when clicking mine");
  // `check_eq(dut.defuser_state, DEF_IDLE, "Should return to IDLE after loss");
  
  // // Reset and test right click (flagging)
  // rst = 1'b1;
  // WaitClocks(1);
  // rst = 1'b0;
  // planting_complete = 1'b1;
  // WaitUntilState(dut.defuser_state, DEF_WAIT_FOR_MOUSE);
  
  // // Test 8: Right click flagging
  // mouse_xpos = M_BOARD_XPOS + M_FIELD_SIZE + M_FIELD_SIZE/2; // Position over [1][1] mine
  // right = 1'b1;
  // WaitClocks(2);
  // right = 1'b0;
  
  // `check_eq(u_wishbone_board_mem.board_mem[1][1].flag, 1'b1, "Field should be flagged");
  
  // // Test 9: Win condition
  // // Defuse all non-mine fields
  // for (int i = 0; i < M_ROW_COLUMN_NUMBER; i++) begin
  //   for (int j = 0; j < M_ROW_COLUMN_NUMBER; j++) begin
  //     if (!u_wishbone_board_mem.board_mem[i][j].mine) begin
  //       mouse_xpos = M_BOARD_XPOS + j*M_FIELD_SIZE + M_FIELD_SIZE/2;
  //       mouse_ypos = M_BOARD_YPOS + i*M_FIELD_SIZE + M_FIELD_SIZE/2;
  //       left = 1'b1;
  //       WaitClocks(1);
  //       left = 1'b0;
  //       WaitClocks(1);
  //     end
  //   end
  // end
  
  // // Flag all mines
  // for (int i = 0; i < M_ROW_COLUMN_NUMBER; i++) begin
  //   for (int j = 0; j < M_ROW_COLUMN_NUMBER; j++) begin
  //     if (u_wishbone_board_mem.board_mem[i][j].mine) begin
  //       mouse_xpos = M_BOARD_XPOS + j*M_FIELD_SIZE + M_FIELD_SIZE/2;
  //       mouse_ypos = M_BOARD_YPOS + i*M_FIELD_SIZE + M_FIELD_SIZE/2;
  //       right = 1'b1;
  //       WaitClocks(1);
  //       right = 1'b0;
  //       WaitClocks(1);
  //     end
  //   end
  // end
  
  // `check_eq(dut.game_won, 1'b1, "Game should be won when all safe fields defused and mines flagged");
  
  // `log_info("All defuser tests completed successfully");
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

endmodule

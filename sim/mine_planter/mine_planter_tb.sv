//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Mine planter testbench
 Author:        Wojciech Miskowicz
 Description:   Implements a testbench for mine planter module.
 */
//////////////////////////////////////////////////////////////////////////////
`include "../../rtl/memory/wishbone_defs.svh"
module mine_planter_tb;

  import logger_pkg::*;
  import game_pkg::*;

  logic clk;
  logic rst;
  logic planting_complete;


  logic [2:0] main_state;


  wishbone_if game_set_wb();
  wishbone_if game_board_wb();
  
  localparam CLK_PERIOD = 25ns;

  enum logic [2:0] {
    IDLE,
    READ_SETTINGS,
    PLANT,
    WRITE_BOARD,
    DONE
  } planter_state;

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
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));
    main_state = PLAY;
    WaitClocks(2);
    `check_eq(game_set_wb.stb_o, 1'b1);
    game_set_wb.ack_i = 1'b1;
    game_set_wb.dat_i = M_ROW_COLUMN_NUMBER;
    WaitClocks(1);
    game_set_wb.ack_i = 1'b0;
    WaitClocks(3);
    `check_eq(game_set_wb.stb_o, 1'b1);
    `check_eq(game_set_wb.adr_o, 2);
    game_set_wb.ack_i = 1'b1;
    game_set_wb.dat_i = M_MINE_NUM;
    WaitClocks(1);
    game_set_wb.ack_i = 1'b0;
    WaitClocks(3);
    `check_eq(dut.planter_state, PLANT);
    WaitClocks(100);
    `check_eq(dut.planter_state, WRITE_BOARD);
    
    WaitClocks(1300);
    `check_eq(dut.planter_state, DONE);

    #50 $finish;
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
  
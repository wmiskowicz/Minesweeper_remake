`include "../../rtl/memory/wishbone_defs.svh"
module defuser_tb;

  import logger_pkg::*;
  import game_pkg::*;

  localparam SETTINGS_REG_NUM = 9;
  localparam CLK_PERIOD = 25ns;

  logic clk;
  logic rst;
  logic planting_complete;
  logic [11:0] mouse_xpos;
  logic [11:0] mouse_ypos;
  logic left;
  logic right;

  logic mouse_xpos_valid;
  logic mouse_ypos_valid;

  logic [2:0] mouse_board_ind_x;
  logic [2:0] mouse_board_ind_y;

  wishbone_if defuser_game_set_wb();
  wishbone_if defuser_game_board_wb();

  reg [15:0] settings_mem [0:SETTINGS_REG_NUM-1];
  field_t  board_mem    [15:0][15:0];

  enum logic [2:0] {
    IDLE,
    READ_SETTINGS,
    READ_BOARD,
    DONE
  } defuser_state;

  enum logic [1:0] {
    WAIT,
    AUTO_WRITE
  } auto_write_state;

  wire [1:0] level;
  logic [2:0] main_state;
  wire timer_stop;
  wire game_won;
  wire game_lost;
  wire retry;
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

    .mouse_board_ind_x(mouse_board_ind_x),
    .mouse_board_ind_y(mouse_board_ind_y),

    .mouse_xpos_valid(mouse_xpos_valid),
    .mouse_ypos_valid(mouse_ypos_valid),

    .left             (left),
    .right            (right),

    .game_set_wb      (defuser_game_set_wb.master),
    .game_board_wb    (defuser_game_board_wb.master)
  );



  main_fsm u_main_fsm (
    .clk         (clk),
    .rst         (rst),

    .level       (2),
    .retry       ('0),
    .state_out   (main_state),
    .timer_stop  ('0),


    .game_won    (game_won),
    .game_lost   (game_lost),

    .game_set_wb1(defuser_game_set_wb.slave),
    .game_set_wb2(game_set_wb2.slave),
    .game_set_wb3(game_set_wb3.slave)
  );

  initial begin
    void'(logger::init());
    planting_complete = 1'b0;
    mouse_xpos = 12'd0;
    mouse_ypos = 12'd0;
    left = 1'b0;
    right = 1'b0;
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));
    planting_complete = 1'b1;
    WaitClocks(150);
    // `check_eq(dut.board_ready, 1'b1);

    `check_eq(dut.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM], M_ROW_COLUMN_NUMBER);
    `check_eq(dut.game_setup_cashe[MINE_NUM_REG_NUM],          M_MINE_NUM);
    `check_eq(dut.game_setup_cashe[TIMER_SECONDS_REG_NUM],     M_TIMER_SECONDS);
    `check_eq(dut.game_setup_cashe[FIELD_SIZE_REG_NUM],        M_FIELD_SIZE);
    `check_eq(dut.game_setup_cashe[BOARD_SIZE_REG_NUM],        M_BOARD_SIZE);
    `check_eq(dut.game_setup_cashe[BOARD_XPOS_REG_NUM],        M_BOARD_XPOS);
    `check_eq(dut.game_setup_cashe[BOARD_YPOS_REG_NUM],        M_BOARD_YPOS);

    mouse_xpos = M_BOARD_XPOS + 2;
    mouse_ypos = M_BOARD_YPOS + 2;
    left = 1'b1;
    WaitClocks(1);
    `check_eq(mouse_xpos_valid, 1);
    `check_eq(mouse_ypos_valid, 1);
    `check_eq(mouse_board_ind_x, 0);
    `check_eq(mouse_board_ind_y, 0);
    WaitClocks(2);
    mouse_xpos = mouse_xpos + M_FIELD_SIZE + 3;
    WaitClocks(1);
    `check_eq(mouse_board_ind_x, 1);

    left = 1'b0;

    WaitClocks(1000);
    // `check_eq(dut.game_won, 1'b1);
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

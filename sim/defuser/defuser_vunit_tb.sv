`include "../../rtl/memory/wishbone_defs.svh"
`include "vunit_defines.svh"

module defuser_tb_vunit;

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

  logic [2:0] main_state;

  wire mouse_xpos_valid;
  wire mouse_ypos_valid;

  wire [3:0] mouse_board_ind_x;
  wire [3:0] mouse_board_ind_y;


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

  assign settings_mem[ROW_COLUMN_NUMBER_REG_NUM] = M_ROW_COLUMN_NUMBER;
  assign settings_mem[MINE_NUM_REG_NUM] = M_MINE_NUM;
  assign settings_mem[TIMER_SECONDS_REG_NUM] = M_TIMER_SECONDS;
  assign settings_mem[FIELD_SIZE_REG_NUM] = M_FIELD_SIZE;
  assign settings_mem[BOARD_SIZE_REG_NUM] = M_BOARD_SIZE;
  assign settings_mem[BOARD_XPOS_REG_NUM] = M_BOARD_XPOS;
  assign settings_mem[BOARD_YPOS_REG_NUM] = M_BOARD_YPOS;

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

  always @(posedge clk) begin
    defuser_game_set_wb.ack_i <= 1'b0;
    defuser_game_set_wb.dat_i <= 16'h0000;
    defuser_game_board_wb.ack_i <= 1'b0;
    defuser_game_board_wb.dat_i <= 16'h0000;

    if(defuser_game_set_wb.stb_o && defuser_game_set_wb.cyc_o && !defuser_game_set_wb.we_o) begin
      defuser_game_set_wb.ack_i <= 1'b1;
      defuser_game_set_wb.dat_i <= settings_mem[defuser_game_set_wb.adr_o[7:0]];
    end

    if(defuser_game_board_wb.stb_o && defuser_game_board_wb.cyc_o && !defuser_game_board_wb.we_o) begin
      defuser_game_board_wb.ack_i <= 1'b1;
      defuser_game_board_wb.dat_i <= {8'h00, board_mem[defuser_game_board_wb.adr_o[7:4]][defuser_game_board_wb.adr_o[3:0]]};
    end
    else if ((defuser_game_board_wb.stb_o && defuser_game_board_wb.cyc_o && defuser_game_board_wb.we_o)) begin
      defuser_game_board_wb.ack_i <= 1'b1;
      board_mem[defuser_game_board_wb.adr_o[7:4]][defuser_game_board_wb.adr_o[3:0]] <= defuser_game_board_wb.dat_o[7:0];
    end
  end

  
  `TEST_SUITE begin

  // TEST SUITE SETUP (Runs ONCE before all test cases)
  `TEST_SUITE_SETUP begin
    InitReset();
  end

  // TEST CASE 1
  `TEST_CASE("TC001") begin
    $display("Test auto settings read process.");
    mouse_xpos = '0;
    mouse_ypos = '0;
    main_state = PLAY;
    WaitClocks(400);
    `CHECK_EQUAL(dut.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM], M_ROW_COLUMN_NUMBER);
    `CHECK_EQUAL(dut.game_setup_cashe[MINE_NUM_REG_NUM],          M_MINE_NUM);
    `CHECK_EQUAL(dut.game_setup_cashe[TIMER_SECONDS_REG_NUM],     M_TIMER_SECONDS);
    `CHECK_EQUAL(dut.game_setup_cashe[FIELD_SIZE_REG_NUM],        M_FIELD_SIZE);
    `CHECK_EQUAL(dut.game_setup_cashe[BOARD_SIZE_REG_NUM],        M_BOARD_SIZE);
    `CHECK_EQUAL(dut.game_setup_cashe[BOARD_XPOS_REG_NUM],        M_BOARD_XPOS);
    `CHECK_EQUAL(dut.game_setup_cashe[BOARD_YPOS_REG_NUM],        M_BOARD_YPOS);



  end

  // TEST CASE 2
  `TEST_CASE("TC002") begin
    $display("Check mouse logic.");
    mouse_xpos = '0;
    mouse_ypos = '0;
    main_state = PLAY;
    WaitClocks(100);
    mouse_xpos = M_BOARD_XPOS + 1;
    mouse_ypos = M_BOARD_YPOS + 1;
    WaitClocks(1);
    `CHECK_EQUAL(mouse_xpos_valid, 1'b1);
    `CHECK_EQUAL(mouse_ypos_valid, 1'b1);
    `CHECK_EQUAL(mouse_board_ind_x, 0);
    `CHECK_EQUAL(mouse_board_ind_y, 0);

  end

  `TEST_CASE("TC005") begin
  $display("[TEST] TC005 - Another test case");
  end

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

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

  wishbone_if defuser_game_set_wb();
  wishbone_if defuser_game_board_wb();

  reg [15:0] settings_mem [0:SETTINGS_REG_NUM-1];
  reg [7:0]  board_mem     [15:0][15:0];

  enum logic [2:0] {
    IDLE,
    READ_SETTINGS,
    READ_BOARD,
    DEFUSE
  } defuser_state;

  initial begin

    settings_mem[ROW_COLUMN_NUMBER_REG_NUM] = M_ROW_COLUMN_NUMBER;
    settings_mem[MINE_NUM_REG_NUM]          = M_MINE_NUM;
    settings_mem[TIMER_SECONDS_REG_NUM]     = M_TIMER_SECONDS;
    settings_mem[FIELD_SIZE_REG_NUM]        = M_FIELD_SIZE;
    settings_mem[BOARD_SIZE_REG_NUM]        = M_BOARD_SIZE;
    settings_mem[BOARD_XPOS_REG_NUM]        = M_BOARD_XPOS;
    settings_mem[BOARD_YPOS_REG_NUM]        = M_BOARD_YPOS;

    for (int i = 0; i < 16; i++)
      for (int j = 0; j < 16; j++)
        board_mem[i][j] = i*16 + j;
  end

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  defuser dut (
    .clk              (clk),
    .rst              (rst),
    .planting_complete(planting_complete),
    .mouse_xpos       (mouse_xpos),
    .mouse_ypos       (mouse_ypos),
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
      defuser_game_set_wb.dat_i <= settings_mem[defuser_game_set_wb.adr_o[7:1]];
    end

    if(defuser_game_board_wb.stb_o && defuser_game_board_wb.cyc_o && !defuser_game_board_wb.we_o) begin
      defuser_game_board_wb.ack_i <= 1'b1;
      defuser_game_board_wb.dat_i <= {8'h00, board_mem[defuser_game_board_wb.adr_o[7:4]][defuser_game_board_wb.adr_o[3:0]]};
    end
  end

  initial begin
    void'(logger::init());
    defuser_game_set_wb.stall_i = 1'b0;
    defuser_game_board_wb.stall_i = 1'b0;
    planting_complete = 1'b0;
    mouse_xpos = 12'd0;
    mouse_ypos = 12'd0;
    left = 1'b0;
    right = 1'b0;
    InitReset();
    `log_info($sformatf("Starting test at, %t", $time));
    WaitClocks(50);
    planting_complete = 1'b1;
    WaitClocks(400);
    `check_eq(dut.defuser_state, IDLE);

    for (int i = 0; i < SETTINGS_REG_NUM; i++)
      `check_eq(dut.game_setup_cashe[i], settings_mem[i]);
    for (int i = 0; i < 16; i++)
      for (int j = 0; j < 16; j++)
        `check_eq(dut.game_board_mem[i][j], board_mem[i][j]);

    mouse_xpos = 12'd5;
    mouse_ypos = 12'd5;
    left = 1'b1;
    WaitClocks(2);
    left = 1'b0;
    WaitClocks(10);
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

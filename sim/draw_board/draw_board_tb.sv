
`timescale 1 ns / 1 ps
import vga_pkg::*;
import logger_pkg::*;
import game_pkg::*;

module draw_board_tb;


  /**
   *  Local parameters
   */

  localparam CLK_PERIOD = 11;     // 40 MHz


  /**
   * Local variables and signals
   */

  wishbone_if game_set_if();
  wishbone_if game_board_if();

  vga_if in_vga();
  vga_if out_vga();

  logic [2:0] main_state;
  logic in;
  logic out;
  logic game_settings_wb;
  logic game_board_wb;
  logic clk, rst;

  wire vs, hs;
  wire [3:0] r, g, b;

  enum logic [2 :0] {
    IDLE,
    READ_SETTINGS,
    DRAW
  } state;


  /**
   * Clock generation
   */

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  assign {r,g,b} = out_vga.rgb;
  assign vs      = out_vga.vsync;
  assign in_vga.rgb = 12'h777;

  /**
   * Submodules instances
   */
  tiff_writer #(
    .XDIM(HOR_TOTAL_TIME),
    .YDIM(VER_TOTAL_TIME),
    .FILE_DIR("../../results")
  ) u_tiff_writer (
    .clk(clk),
    .r({r,r}), // fabricate an 8-bit value
    .g({g,g}), // fabricate an 8-bit value
    .b({b,b}), // fabricate an 8-bit value
    .go(vs)
  );

  vga_timing u_vga_timing (
    .clk(clk),  
    .rst(rst),

    .out(in_vga.out)
  );

  draw_board dut (
    .clk             (clk),
    .rst             (rst),

    .main_state      (PLAY),

    .game_board_wb   (game_board_if.master),
    .game_settings_wb(game_set_if.master),

    .in              (in_vga.in),
    .out             (out_vga.out)
  );

  wire [1:0] level;
  wire timer_stop;
  wire game_won;
  wire game_lost;
  wire retry;
  wire [2:0] state_out;
  wire game_settings;

  main_fsm u_main_fsm (
    .clk          (clk),
    .rst          (rst),

    .game_lost    ('0),
    .game_won     ('0),
    .level        (2),
    .retry        ('0),
    .state_out    (),
    .timer_stop   ('0),

    .game_set_wb1(game_set_if.slave),
    .game_set_wb2(game_set_if.slave),
    .game_set_wb3(game_set_if.slave)

  );

  initial begin
    void'(logger::init());
    main_state = 0;
    InitReset();
    for (int i=0; i < dut.SETTINGS_REG_NUM; i++) u_main_fsm.game_setup_mem[i] <= 16'd1 * i;
    dut.game_board_mem[2][2].defused = 1;
    WaitClocks(2);
    main_state = 3'h2;
    `check_eq(main_state, 2)
    WaitClocks(1);
    `check_eq(dut.board_state, 3'h1);

    WaitClocks(100);
    `check_neq(dut.settings_read_ctr, 0)
    for (int i=0; i < 9; i++) begin
      `log_info($sformatf("Testing for i=%d", i));
      // `check_eq(u_main_fsm.game_setup_mem[i], dut.game_setup_cashe[i]);
    end

    dut.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM] = M_ROW_COLUMN_NUMBER;
    dut.game_setup_cashe[MINE_NUM_REG_NUM] = M_MINE_NUM;
    dut.game_setup_cashe[TIMER_SECONDS_REG_NUM] = M_TIMER_SECONDS;
    dut.game_setup_cashe[FIELD_SIZE_REG_NUM] = M_FIELD_SIZE;
    dut.game_setup_cashe[BOARD_SIZE_REG_NUM] = M_BOARD_SIZE;
    dut.game_setup_cashe[BOARD_XPOS_REG_NUM] = M_BOARD_XPOS;
    dut.game_setup_cashe[BOARD_YPOS_REG_NUM] = M_BOARD_YPOS;
    dut.game_board_mem[0][1].mine = 1'b1;
    dut.game_board_mem[1][0].mine = 1'b1;
    dut.game_board_mem[2][2].mine = 1'b1;
    dut.game_board_mem[1][1].defused = 1'b1;
    dut.game_board_mem[1][1].mine_ind = 1;


    wait (vs == 1'b0);
    @(negedge vs) $display("Info: negedge VS at %t",$time);
    @(negedge vs) $display("Info: negedge VS at %t",$time);
    $finish();
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

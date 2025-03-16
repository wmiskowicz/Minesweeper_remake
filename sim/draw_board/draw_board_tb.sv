
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


  /**
   * Submodules instances
   */



  draw_board dut (
    .clk             (clk),
    .rst             (rst),

    .main_state      (main_state),

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

    .game_settings(game_set_if.slave)

  );

  initial begin
    void'(logger::init());
    main_state = 0;
    InitReset();
    for (int i=0; i < dut.SETTINGS_REG_NUM; i++) u_main_fsm.game_setup_mem[i] <= 16'd1 * i;
    WaitClocks(2);
    main_state = 3'h2;
    `check_eq(main_state, 2)
    WaitClocks(1);
    `check_eq(dut.state, 3'h1);

    WaitClocks(100);
    `check_neq(dut.settings_read_ctr, 0)
    for (int i=0; i < 9; i++) begin
      `log_info($sformatf("Testing for i=%d", i));
      `check_eq(u_main_fsm.game_setup_mem[i], dut.game_setup_cashe[i]);
    end

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

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   top_vga_tb.sv
 Author:        prof. Eric Crabilla
 Modified:      Wojciech Miskowicz, 
                Piotr Kaczmarczyk
 Description:   Generates an image created by top_vga logic using tiff_writer.
 */
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
import vga_pkg::*;
import game_pkg::*;
import logger_pkg::*;

module top_vga_tb;


// ----- Local parameters -----
localparam CLK_PERIOD = 11;


// ----- Local variables -----
logic clk;
logic rst;

wire vs, hs;
wire [3:0] r, g, b;
logic [2:0] main_state;

// ----- Signal interfaces -----
wishbone_if game_set_if();
wishbone_if game_board_if();


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

main_fsm u_main_fsm (
  .clk          (clk),
  .rst          (rst),

  .game_lost    (1'b0),
  .game_won     (1'b0),
  .level        (2'd2),
  .retry        (1'b0),
  .state_out    (),
  .timer_stop   (1'b0),

  .game_set_wb1(game_set_if.slave),
  .game_set_wb2(game_set_if.slave),
  .game_set_wb3(game_set_if.slave)
);


top_vga dut (
  .b       (b),
  .clk     (clk),
  .g       (g),
  .hs      (hs),
  .r       (r),
  .rst     (rst),
  .vs      (vs),

  .mouse_xpos('0),
  .mouse_ypos('0),

  .game_lost    (0),
  .game_won     (0),
  .retry        (0),

  .main_state       (main_state),
  .game_settings_wb (game_set_if.master),
  .game_board_wb    (game_board_if)
);

tiff_writer #(
  .XDIM     (HOR_TOTAL_TIME),
  .YDIM     (VER_TOTAL_TIME),
  .FILE_DIR ("../../results")
) u_tiff_writer (
  .clk (clk),
  .r   ({r,r}), // fabricate an 8-bit value
  .g   ({g,g}), // fabricate an 8-bit value
  .b   ({b,b}), // fabricate an 8-bit value
  .go  (vs)
);

initial begin
  void'(logger::init());
  InitReset();

  `log_info("Starting top_vga testbench");
  `log_info("Generating image...");
  WaitClocks(30);
  main_state = PLAY;
  WaitClocks(1000);
  dut.u_draw_board.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM]  = H_ROW_COLUMN_NUMBER;
  dut.u_draw_board.game_setup_cashe[MINE_NUM_REG_NUM]           = H_MINE_NUM;
  dut.u_draw_board.game_setup_cashe[TIMER_SECONDS_REG_NUM]      = H_TIMER_SECONDS;
  dut.u_draw_board.game_setup_cashe[FIELD_SIZE_REG_NUM]         = H_FIELD_SIZE;
  dut.u_draw_board.game_setup_cashe[BOARD_SIZE_REG_NUM]         = H_BOARD_SIZE;
  dut.u_draw_board.game_setup_cashe[BOARD_XPOS_REG_NUM]         = H_BOARD_XPOS;
  dut.u_draw_board.game_setup_cashe[BOARD_YPOS_REG_NUM]         = H_BOARD_YPOS;


  dut.u_draw_board.game_board_mem[0][0].flag = 1'b1;
  dut.u_draw_board.game_board_mem[9][9].flag = 1'b1;


  wait (vs == 1'b0);
  @(negedge vs) `log_info($sformatf("Info: negedge VS at %t", $time));
  @(negedge vs) `log_info($sformatf("Info: negedge VS at %t", $time));

  // End the simulation.
  `log_info("Simulation is over, check the waveforms.");
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

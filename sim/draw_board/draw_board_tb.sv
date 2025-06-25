//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   draw_board_tb.sv
 Author:        Wojciech Miskowicz
 Description:   Generates an image using tiff_writer. 
                Similar to top_vga_tb but can customise board state and is a lot faster.
 */
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

import vga_pkg::*;
import logger_pkg::*;
import game_pkg::*;

module draw_board_tb;


// ----- Local parameters -----
localparam CLK_PERIOD = 11ns;


// ----- Local variables -----
logic clk;
logic rst;

int frame_ctr;

wire vs, hs;
wire [3:0] r, g, b;


// ----- Signal interfaces -----
wishbone_if game_set_if();
wishbone_if game_board_if();

vga_if in_vga();
vga_if out_vga();


// ----- Signal assignments -----
assign {r,g,b} = out_vga.rgb;
assign vs      = out_vga.vsync;



initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end


always_ff @(posedge clk) begin
  if (rst)
    frame_ctr <= 0;
  else if(out_vga.hcount == HCOUNT_MAX && out_vga.vcount == VCOUNT_MAX)
    frame_ctr <= frame_ctr + 1;
end


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

initial begin
  void'(logger::init());
  InitReset();

  WaitClocks(500);
  dut.game_setup_cashe[ROW_COLUMN_NUMBER_REG_NUM] = H_ROW_COLUMN_NUMBER;
  dut.game_setup_cashe[MINE_NUM_REG_NUM] = H_MINE_NUM;
  dut.game_setup_cashe[TIMER_SECONDS_REG_NUM] = H_TIMER_SECONDS;
  dut.game_setup_cashe[FIELD_SIZE_REG_NUM] = H_FIELD_SIZE;
  dut.game_setup_cashe[BOARD_SIZE_REG_NUM] = H_BOARD_SIZE;
  dut.game_setup_cashe[BOARD_XPOS_REG_NUM] = H_BOARD_XPOS;
  dut.game_setup_cashe[BOARD_YPOS_REG_NUM] = H_BOARD_YPOS;

  dut.game_board_mem[0][1].flag = 1'b1;
  dut.game_board_mem[1][0].mine = 1'b1;
  dut.game_board_mem[2][2].mine = 1'b1;
  dut.game_board_mem[1][2].mine = 1'b1;
  dut.game_board_mem[1][1].defused = 1'b1;
  dut.game_board_mem[1][1].mine_ind = 3;
  dut.game_board_mem[1][4].mine_ind = 1;
  dut.game_board_mem[1][4].defused = 1;
  dut.game_board_mem[1][3].defused = 1'b1;
  dut.game_board_mem[1][3].mine = 1'b1;



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

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


// ----- Signal interfaces -----
wishbone_if game_set_if();
wishbone_if game_board_if();


initial begin
  clk = 1'b0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end


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

  .main_state       (PLAY),
  .game_settings_wb (game_set_if),
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

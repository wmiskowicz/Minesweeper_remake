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

`include "../../XVunit/internals/verilog/xvunit_defines.svh"


import vga_pkg::*;
import game_pkg::*;

module top_vga_xvunit_tb;


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
  .back_to_menu (0),

  .main_state       (main_state),
  .game_settings_wb (game_set_if),
  .game_board_wb    (game_board_if)
);

tiff_writer #(
  .XDIM     (HOR_TOTAL_TIME),
  .YDIM     (VER_TOTAL_TIME),
  .FILE_DIR ("C:/Users/wojte/Documents/Saper_new/results")
) u_tiff_writer (
  .clk (clk),
  .r   ({r,r}), // fabricate an 8-bit value
  .g   ({g,g}), // fabricate an 8-bit value
  .b   ({b,b}), // fabricate an 8-bit value
  .go  (vs)
);

`TEST_SUITE_BEGIN 

    `TEST_SUITE_SETUP begin
      $display("Setting up test suite");
    end

    `TEST_CASE_SETUP begin

      InitReset();
    end

    `TEST_CASE("DRAW_IMAGE") begin
      $display("Verify reset state");
      $display("Starting top_vga testbench");
      $display("Generating image...");
      WaitClocks(30);
      main_state = PLAY;

    
      wait (vs == 1'b0);
      @(negedge vs) $display($sformatf("Info: negedge VS at %t", $time));
      @(negedge vs) $display($sformatf("Info: negedge VS at %t", $time));
      
      $display("Image generated");
      $finish();
    end

`TEST_SUITE_END


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

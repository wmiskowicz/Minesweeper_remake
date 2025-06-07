//////////////////////////////////////////////////////////////////////////////
 /*
  Module name:   top_timer
  Author:        Wojciech Miskowicz
  Description:   Top module for timer logic.
  */
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module top_timer (
  input   wire  clk,
  input   wire  rst,

  input   wire  left, right,
  input   wire  start, stop,
  input   wire  retry,


  input   wire  [7:0] sec_to_count,
  output  logic [7:0] seconds_left,

  output  logic left_st, right_st,
  output  logic time_elapsed
);

assign left_st = stop ? '0 : left;
assign right_st = stop ? '0 : right;

wire [7:0] second_ctr;


time_controller u_time_controller(
  .clk,
  .rst,

  .start,
  .stop,
  .retry,
  
  .time_elapsed,
  .sec_to_count,
  .second_ctr
);

bin2bcd u_bin2bcd(
  .bin(second_ctr),
  .bcd(seconds_left)
);

endmodule

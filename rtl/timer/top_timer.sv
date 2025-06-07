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

  input   wire  start, stop,
  input   wire  retry,


  input   wire  [7:0] sec_to_count,
  output  logic [7:0] seconds_left,

  output  logic time_elapsed
);

// ----- Local variables -----
wire [7:0] second_ctr;


time_controller u_time_controller(
  .clk   (clk),
  .rst   (rst),

  .start (start),
  .stop  (stop),
  .retry (retry),
  
  .time_elapsed (time_elapsed),
  .sec_to_count (sec_to_count),
  .second_ctr   (second_ctr)
);

bin2bcd u_bin2bcd(
  .bin(second_ctr),
  .bcd(seconds_left)
);

endmodule

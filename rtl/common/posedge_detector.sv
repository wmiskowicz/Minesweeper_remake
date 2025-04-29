`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   posedge detector
 Author:        Wojciech Miskowicz
 Description:   Detects rising edge on in_signal and returns 1'b1 of 1 clock cycle duration.
 */
//////////////////////////////////////////////////////////////////////////////


module posedge_detector(
  input  wire clk, 
  input  wire rst,

  input  wire  in_signal,
  output logic out_pulse
);

reg signal_delayed;

always_ff @(posedge clk) signal_delayed <= in_signal;

assign out_pulse = rst ? 1'b0 : in_signal && ~signal_delayed;

endmodule

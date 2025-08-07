//////////////////////////////////////////////////////////////////////////////
/*
  Module name:   top_mouse
  Author:        Wojciech Miskowicz
  Description:   Top module for mouse peripherial. The output mouse signals
                 are clocked using 74MHz clock. 'left' and 'right' signals
                 are of 1 clock cycle width.
*/
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module top_mouse (
  input  wire clk100MHz,
  input  wire clk74MHz,
  input  wire rst,

  inout  ps2_clk,
  inout  ps2_data,

  output logic right,
  output logic left,
  output logic [11:0] mouse_xpos,
  output logic [11:0] mouse_ypos
);

// ----- Local variables -----
wire [11:0] xpos_in;
wire [11:0] ypos_in;

wire new_event;
wire xpos_empty, ypos_empty;

logic wr_en;
logic rd_en;
logic full;
logic empty;

logic [17:0] data_out;

logic left_in, right_in;
logic left_sync, right_sync;

// ----- Signal assignments -----
assign right_sync = rd_en ? 1'b0 : data_out[0];
assign left_sync  = rd_en ? 1'b0 : data_out[1];


always_ff @(posedge clk100MHz) wr_en <= !full && (left_in || right_in);
always_ff @(posedge clk74MHz)  rd_en <= !empty;


posedge_detector posedge_detector_0 (
  .clk        (clk74MHz),
  .rst        (rst),
  .in_signal  (left_sync),
  .out_pulse  (left)
);

posedge_detector posedge_detector_3 (
  .clk        (clk74MHz),
  .rst        (rst),
  .in_signal  (right_sync),
  .out_pulse  (right)
);

MouseCtl u_MouseCtl(
  .clk    (clk100MHz),
  .rst    (rst),
  .xpos   (xpos_in),
  .ypos   (ypos_in),
  .zpos   (),


  .ps2_clk  (ps2_clk),
  .ps2_data (ps2_data),

  .left     (left_in),
  .middle   (),
  .right    (right_in),

  .new_event(new_event),
  .value    (12'd100),

  .setx     ('0),
  .sety     ('0),
  .setmax_x ('0),
  .setmax_y ('0)
);


fifo_generator_1 fifo_0 (
  .wr_clk (clk100MHz),
  .rd_clk (clk74MHz),
  .rst    (rst),

  .wr_en  (new_event),
  .rd_en  (rd_en),

  .din    ({16'b0, left_in, right_in}),
  .dout   (data_out),

  .full   (full),
  .empty  (empty),

  .wr_rst_busy(),
  .rd_rst_busy()
);

fifo_generator_1 fifo_1 (
  .wr_clk (clk100MHz),
  .rd_clk (clk74MHz),
  .rst    (rst),

  .wr_en  (new_event),
  .rd_en  (!xpos_empty),

  .din    ({6'b0, xpos_in}),
  .dout   (mouse_xpos),

  .full   (),
  .empty  (xpos_empty),

  .wr_rst_busy(),
  .rd_rst_busy()
);

fifo_generator_1 fifo_2 (
  .wr_clk (clk100MHz),
  .rd_clk (clk74MHz),
  .rst    (rst),

  .wr_en  (new_event),
  .rd_en  (!ypos_empty),

  .din    ({6'b0, ypos_in}),
  .dout   (mouse_ypos),

  .full   (),
  .empty  (ypos_empty),

  .wr_rst_busy(),
  .rd_rst_busy()
);


endmodule

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
logic [11:0] xpos_in;
logic [11:0] ypos_in;

logic wr_en;
logic rd_en;
logic full;
logic empty;

logic [17:0] xpos_out;
logic [17:0] ypos_out;
logic [17:0] data_out;

logic left_in, right_in;
logic left_q, right_q;
logic left_sync, right_sync;
logic left_sync_pulse, right_sync_pulse;
logic wr_en_pulse;

logic wr_en_xpos, wr_en_ypos;
logic rd_en_xpos, rd_en_ypos;
logic empty_xpos, empty_ypos;
logic full_xpos, full_ypos;

// ----- Signal assignments -----
assign right_sync = rd_en ? 1'b0 : data_out[0];
assign left_sync  = rd_en ? 1'b0 : data_out[1];

assign left  = left_sync_pulse;
assign right = right_sync_pulse;

assign mouse_xpos = rd_en_xpos ? xpos_out[11:0] : mouse_xpos;
assign mouse_ypos = rd_en_ypos ? ypos_out[11:0] : mouse_ypos;


// ----- Module logic -----
always_ff @(posedge clk100MHz) wr_en <= !full && (left_in || right_in);
always_ff @(posedge clk74MHz)  rd_en <= !empty;

always_ff @(posedge clk100MHz) wr_en_xpos <= !full_xpos;
always_ff @(posedge clk74MHz)  rd_en_xpos <= !empty_xpos;

always_ff @(posedge clk100MHz) wr_en_ypos <= !full_ypos;
always_ff @(posedge clk74MHz)  rd_en_ypos <= !empty_ypos;

always_ff @(posedge clk100MHz) begin
  left_q  <= left_in;
  right_q <= right_in;
end



posedge_detector posedge_detector_0 (
  .clk        (clk74MHz),
  .rst        (rst),
  .in_signal  (left_sync),
  .out_pulse  (left_sync_pulse)
);

posedge_detector posedge_detector_3 (
  .clk        (clk74MHz),
  .rst        (rst),
  .in_signal  (right_sync),
  .out_pulse  (right_sync_pulse)
);

posedge_detector posedge_detector_4 (
  .clk        (clk100MHz),
  .rst        (rst),
  .in_signal  (wr_en),
  .out_pulse  (wr_en_pulse)
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

  .new_event(),
  .value    (12'd100),

  .setx     ('0),
  .sety     ('0),
  .setmax_x ('0),
  .setmax_y ('0)
);

fifo_generator_1 fifo_xpos (
  .wr_clk (clk100MHz),
  .rd_clk (clk74MHz),
  .rst    (rst),

  .wr_en  (wr_en_xpos),
  .rd_en  (rd_en_xpos),

  .din    ({6'h0, xpos_in}),
  .dout   (xpos_out),

  .full   (full_xpos),
  .empty  (empty_xpos),

  .wr_rst_busy(),
  .rd_rst_busy()
);

fifo_generator_1 fifo_ypos (
  .wr_clk (clk100MHz),
  .rd_clk (clk74MHz),
  .rst    (rst),

  .wr_en  (wr_en_ypos),
  .rd_en  (rd_en_ypos),

  .din    ({6'h0, ypos_in}),
  .dout   (ypos_out),

  .full   (full_ypos),
  .empty  (empty_ypos),

  .wr_rst_busy(),
  .rd_rst_busy()
);


fifo_generator_1 fifo_buttons (
  .wr_clk (clk100MHz),
  .rd_clk (clk74MHz),
  .rst    (rst),

  .wr_en  (wr_en_pulse),
  .rd_en  (rd_en),

  .din    ({16'b0, left_q, right_q}),
  .dout   (data_out),

  .full   (full),
  .empty  (empty),

  .wr_rst_busy(),
  .rd_rst_busy()
);


endmodule

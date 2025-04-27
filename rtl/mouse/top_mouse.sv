//////////////////////////////////////////////////////////////////////////////
 /*
  Module name:   top_mouse
  Author:        Wojciech Miskowicz
  Description:   Top module for mouse peripherial.
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

wire [11:0] xpos_in;
wire [11:0] ypos_in;

logic wr_en;
logic rd_en;
logic full;
logic empty;

logic left_in, right_in;
logic left_sync, right_sync;
logic left_prev, right_prev;

always_ff @(posedge clk74MHz) begin
  left_prev  <= left_sync;
  right_prev <= right_sync;
end

assign left = !left_prev && left_sync;
assign right = !right_prev && right_sync;

always_ff @(posedge clk100MHz) wr_en <= !full && (left_in || right_in);
always_ff @(posedge clk74MHz)  rd_en <= !empty;

MouseCtl u_MouseCtl(
  .clk(clk100MHz),
  .rst,
  .xpos(xpos_in),
  .ypos(ypos_in),
  .ps2_clk,
  .ps2_data,
  .zpos(),
  .left(left_in),
  .middle(),
  .right(right_in),
  .new_event(),
  .value(12'd100),
  .setx('0),
  .sety('0),
  .setmax_x('0),
  .setmax_y('0)
);

cross_buffer u_cross_buffer (
  .slow_clk  (clk74MHz),
  .clk100MHz (clk100MHz),
  .rst       (rst),

  .xpos_in   (xpos_in),
  .ypos_in   (ypos_in),
  .left_in   (0),
  .right_in  (0),

  .left_out  (),
  .right_out (),
  .xpos_out  (mouse_xpos),
  .ypos_out  (mouse_ypos)
);

fifo_generator_0 fifo_xpos (
  .wr_clk(clk100MHz),
  .rd_clk(clk74MHz),
  .rst(rst),

  .wr_en(wr_en),
  .rd_en(rd_en),

  .din({left_in, right_in}),
  .dout({left_sync, right_sync}),

  .full(full),
  .empty(empty)
);


endmodule

//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Draw background
 Author:        Wojciech Miskowicz
 Description:   Draws display background. 
 */
//////////////////////////////////////////////////////////////////////////////


`timescale 1 ns / 1 ps

module draw_bg (
  input  logic clk,
  input  logic rst,
  vga_if.in in,
  vga_if.out out
);

import vga_pkg::*;
import color_pkg::*;

// ----- Local parameters -----
localparam int SQUARE_SIZE = 8;
localparam int INTERVAL_X  = 45;
localparam int INTERVAL_Y  = 55;
localparam int MODULO      = 7;

// ----- Local variables -----
logic [10:0] rect_hcount, rect_vcount;
logic [7:0]  x_rect_ctr, y_rect_ctr;

// ----- Signal assignments -----
always_ff @(posedge clk) begin
  if (rst) begin
    rect_hcount <= 11'd0;
    rect_vcount <= 11'd0;
    x_rect_ctr  <= 8'd0;
    y_rect_ctr  <= 8'd0;
  end
  else begin
    rect_hcount <= (in.hcount % INTERVAL_X);
    rect_vcount <= (in.vcount % INTERVAL_Y);

    if (rect_hcount == SQUARE_SIZE)
      x_rect_ctr <= (x_rect_ctr + 8'd1) % MODULO;
    else if (in.hcount == 0)
      x_rect_ctr <= 8'd0;

    if (rect_vcount == SQUARE_SIZE && rect_hcount == SQUARE_SIZE)
      y_rect_ctr <= (y_rect_ctr + 8'd1) % MODULO;
    else if (in.vcount == 0)
      y_rect_ctr <= 8'd0;

  end
end


always_ff @(posedge clk) begin : background_ff_blk
  if (rst) begin
    out.vcount  <= '0;
    out.vsync   <= '0;
    out.vblnk   <= '0;
    out.hcount  <= '0;
    out.hsync   <= '0;
    out.hblnk   <= '0;
    out.rgb     <= '0;
  end
  else begin
    out.vcount <= in.vcount;
    out.vsync  <= in.vsync;
    out.vblnk  <= in.vblnk;
    out.hcount <= in.hcount;
    out.hsync  <= in.hsync;
    out.hblnk  <= in.hblnk;
    
    if (in.vblnk || in.hblnk) begin
      out.rgb <= 12'h0;
    end
    else begin
      if ((rect_hcount < SQUARE_SIZE) &&
          (rect_vcount < SQUARE_SIZE) &&
          (
          (x_rect_ctr == 8'd1 && y_rect_ctr == 8'd3) ||
          (x_rect_ctr == 8'd5 && y_rect_ctr == 8'd2) ||
          (x_rect_ctr == 8'd2 && y_rect_ctr == 8'd6) ||
          (x_rect_ctr == 8'd4 && y_rect_ctr == 8'd1) ||
          (x_rect_ctr == 8'd0 && y_rect_ctr == 8'd5) ||
          (x_rect_ctr == 8'd6 && y_rect_ctr == 8'd4) ||
          (x_rect_ctr == 8'd3 && y_rect_ctr == 8'd7)
          )
          )
      begin
        out.rgb <= BACKGROUND_SQUARE;
      end
      else begin
        out.rgb <= BACKGROUND;
      end
    end
  end
end

endmodule

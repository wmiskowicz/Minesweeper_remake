//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Draw image
 Author:        Wojciech Miskowicz
 Description:   Draws an image at specific coordinates with optional scaling.
 */
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module draw_image #(
  parameter RECT_WIDTH    = 64,
  parameter RECT_HEIGHT   = 64,
  parameter PATH          = "../../rtl/top_vga/data/bomb.data",
  parameter PRESCALER     = 1,
  parameter OFFSET_X      = 0
)(
  input  logic clk,
  input  logic rst,
  input  logic [11:0] rect_x_pos,
  input  logic [11:0] rect_y_pos,
  vga_if.in in,
  vga_if.out out
);

import vga_pkg::*;
import color_pkg::*;

// ----- Local parameters -----
localparam X_ADDR_WIDTH = $clog2(RECT_WIDTH);
localparam Y_ADDR_WIDTH = $clog2(RECT_HEIGHT);
localparam ADDR_WIDTH = X_ADDR_WIDTH + Y_ADDR_WIDTH;

localparam SCALED_WIDTH = RECT_WIDTH * PRESCALER;
localparam SCALED_HEIGHT = RECT_HEIGHT * PRESCALER;


// ----- Signal intefaces -----
vga_if vga_q();

// ----- Local variables -----
logic [11:0] rect_hcount, rect_vcount;
logic [11:0] scaled_rect_hcount, scaled_rect_vcount;
logic in_image_region;

logic [ADDR_WIDTH-1:0] address;
logic [11:0] rom_rgb;
logic [11:0] offset_rect_xpos;


delay_vga u_delay(
  .clk(clk),
  .rst(rst),
  .in(in),
  .out(vga_q.out)
);

image_rom #(
  .PATH       (PATH),
  .MEM_SIZE   (RECT_HEIGHT * RECT_WIDTH),
  .ADDR_WIDTH (ADDR_WIDTH)
)
u_image_rom (
  .address(address),
  .clk    (clk),
  .rgb    (rom_rgb)
);

// Apply the offset to the X position
assign offset_rect_xpos = rect_x_pos + OFFSET_X;

always_comb begin
  rect_hcount = in.hcount - offset_rect_xpos;
  rect_vcount = in.vcount - rect_y_pos;
  
  scaled_rect_hcount = rect_hcount / PRESCALER;
  scaled_rect_vcount = rect_vcount / PRESCALER;
  
  in_image_region = (vga_q.hcount >= offset_rect_xpos) &&
                    (vga_q.hcount <  offset_rect_xpos + SCALED_WIDTH) &&
                    (vga_q.vcount >= rect_y_pos) &&
                    (vga_q.vcount <  rect_y_pos + SCALED_HEIGHT);
end

always_ff @(posedge clk) begin
  if (rst) begin
    out.vcount  <= '0;
    out.vsync   <= '0;
    out.vblnk   <= '0;
    out.hcount  <= '0;
    out.hsync   <= '0;
    out.hblnk   <= '0;
    out.rgb     <= '0;
    address     <= '0;
  end else begin
    out.vcount <= vga_q.vcount;
    out.vsync  <= vga_q.vsync;
    out.vblnk  <= vga_q.vblnk;
    out.hcount <= vga_q.hcount;
    out.hsync  <= vga_q.hsync;
    out.hblnk  <= vga_q.hblnk;
    
    address <= {scaled_rect_vcount[Y_ADDR_WIDTH-1:0], scaled_rect_hcount[X_ADDR_WIDTH-1:0]};

    if (vga_q.hblnk || vga_q.vblnk)
      out.rgb <= '0;
    else if (in_image_region)
      out.rgb <= rom_rgb == BLUE_SCREEN ? vga_q.rgb : rom_rgb;
    else
      out.rgb <= vga_q.rgb;
  end
end

endmodule
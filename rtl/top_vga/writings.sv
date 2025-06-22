//////////////////////////////////////////////////////////////////////////////
/*
 Module name:   Top VGA
 Author:        Wojciech Miskowicz
 Description:   Top module containing all VGA display logic.
 */
//////////////////////////////////////////////////////////////////////////////

 `timescale 1 ns / 1 ps

 module writings (
  input  logic clk,
  input  logic rst,

  input wire [2:0] main_state,

  vga_if.in  in,
  vga_if.out out

 );

 import vga_pkg::*;
 import game_pkg::*;


// ----- Signal intefaces -----
vga_if banner_vga();

// ----- Local variables -----
logic [11:0] rgb_q;

draw_image #(
  .RECT_WIDTH (128),
  .RECT_HEIGHT(128),
  .PATH       ("../../rtl/top_vga/data/banner_128.data")
)
u_draw_image1 (
  .clk       (clk),
  .in        (in),
  .out       (banner_vga.out),
  .rect_x_pos(12'(X_CENTER - 32)),
  .rect_y_pos(12'(Y_CENTER - 32)),
  .rst       (rst)
);

always_ff @(posedge clk) begin
  rgb_q <= in.rgb;

  if (1) begin
    out.rgb <= banner_vga.rgb;
  end else begin
    out.rgb <= rgb_q;
  end

  out.hcount <= banner_vga.hcount;
  out.vcount <= banner_vga.vcount;
  out.hsync  <= banner_vga.hsync;
  out.vsync  <= banner_vga.vsync;
  out.hblnk  <= banner_vga.hblnk;
  out.vblnk  <= banner_vga.vblnk;
end
  
 endmodule